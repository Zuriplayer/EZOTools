-- Módulo de ejecución de acciones de EZOTools.
-- Centraliza la lógica ejecutable independientemente del origen (ratón, gamepad, keybind).
-- Otros módulos disparan acciones por ID de string; este módulo las ejecuta.

EZOTools_ActionExec = EZOTools_ActionExec or {}
local X = EZOTools_ActionExec
local EZO = EZOTools

X.registry = X.registry or {}

local function LlamadaSegura(fn, ...)
    if type(fn) ~= "function" then return false, "no es función" end
    return pcall(fn, ...)
end

-- Registra una acción con su ID y función asociada
function X.Register(actionId, fn)
    if type(actionId) ~= "string" or actionId == "" then return end
    if type(fn) ~= "function" then return end
    X.registry[actionId] = fn
end

-- Ejecuta una acción por ID. Devuelve true si la acción señala que debe mantenerse el menú abierto.
function X.Execute(actionId, ctx)
    local fn = X.registry[actionId]
    if type(fn) ~= "function" then
        return false
    end
    local ok, resOrErr = LlamadaSegura(fn, ctx)
    if not ok then
        if EZO and EZO.Print then
            EZO.Print(zo_strformat(GetString(EZO_MSG_ACTION_FAILED), tostring(actionId)))
        end
        return false
    end
    return resOrErr == true
end

-- Registra las acciones del núcleo del addon
function X.RegisterCore()

    -- Ajustes rápidos (submenú, sin cambio de escena)
    X.Register("OPEN_SETTINGS", function(ctx)
        local settingsDialog = EZO and EZO.GamepadSettingsDialog
        if type(settingsDialog) ~= "table" then return false end

        if ctx and ctx.source == "MOUSE" and type(settingsDialog.OpenMouse) == "function" then
            return settingsDialog.OpenMouse(ctx.anchor)
        end
        if type(settingsDialog.OpenGamepad) == "function" then
            return settingsDialog.OpenGamepad()
        end
        if type(settingsDialog.Open) == "function" then
            return settingsDialog.Open()
        end
        return false
    end)

    -- Actividades de grupo/trial/dungeon (submenú)
    X.Register("OPEN_GROUP_ACTIVITIES", function(ctx)
        local activitiesDialog = EZO and EZO.RaidLeaderActivitiesDialog
        if type(activitiesDialog) ~= "table" then return false end

        if ctx and ctx.source == "MOUSE" and type(activitiesDialog.OpenMouse) == "function" then
            return activitiesDialog.OpenMouse(ctx.anchor)
        end
        if type(activitiesDialog.OpenGamepad) == "function" then
            return activitiesDialog.OpenGamepad()
        end
        if type(activitiesDialog.Open) == "function" then
            return activitiesDialog.Open()
        end
        return false
    end)

    -- Viajes a trials en veterano (submenú hijo)
    X.Register("OPEN_TRIAL_TRAVEL", function(ctx)
        local trialDialog = EZO and EZO.RaidLeaderTrialsDialog
        if type(trialDialog) ~= "table" then return false end

        if ctx and ctx.source == "MOUSE" and type(trialDialog.OpenMouse) == "function" then
            return trialDialog.OpenMouse(ctx.anchor)
        end
        if type(trialDialog.OpenGamepad) == "function" then
            return trialDialog.OpenGamepad()
        end
        if type(trialDialog.Open) == "function" then
            return trialDialog.Open()
        end
        return false
    end)

    -- Ajustes completos del addon via LibAddonMenu
    X.Register("OPEN_ADDON_SETTINGS", function()
        if type(IsUnitInCombat) == "function" and IsUnitInCombat("player") then
            if EZO and EZO.Print then EZO.Print(GetString(EZO_MSG_CANT_OPEN_COMBAT)) end
            return false
        end

        local function abrirPanelConfiguracion()
            if EZOTools_Menu and type(EZOTools_Menu.Open) == "function" then
                return EZOTools_Menu.Open()
            end
            return false
        end

        if type(zo_callLater) == "function" then
            zo_callLater(function() pcall(abrirPanelConfiguracion) end, 100)
            return true
        end
        return pcall(abrirPanelConfiguracion)
    end)

    -- Viajes a casas
    X.Register("JUMP_PRIMARY_HOUSE", function()
        if EZO and type(EZO.JumpPrimaryHouse) == "function" then
            return EZO.JumpPrimaryHouse()
        end
        return false
    end)

    X.Register("JUMP_CRAFTING_HOUSE", function()
        if EZO and type(EZO.JumpCraftingHall) == "function" then
            return EZO.JumpCraftingHall()
        end
        return false
    end)

    X.Register("JUMP_SECONDARY_HOUSE", function()
        if EZO and type(EZO.JumpSecondaryHall) == "function" then
            return EZO.JumpSecondaryHall()
        end
        return false
    end)

    -- Acciones de grupo e instancia
    X.Register("JUMP_TO_LEADER", function()
        if EZO and type(EZO.JumpToLeader) == "function" then
            return EZO.JumpToLeader()
        end
        return false
    end)

    X.Register("LEAVE_GROUP", function()
        if EZO and type(EZO.LeaveGroup) == "function" then
            return EZO.LeaveGroup()
        end
        return false
    end)

    X.Register("LEAVE_INSTANCE", function()
        if EZO and type(EZO.LeaveInstance) == "function" then
            return EZO.LeaveInstance()
        end
        return false
    end)

    X.Register("LEAVE_GROUP_AND_INSTANCE", function()
        if EZO and type(EZO.LeaveGroupAndInstance) == "function" then
            return EZO.LeaveGroupAndInstance()
        end
        return false
    end)

    X.Register("TOGGLE_DUNGEON_DIFFICULTY", function()
        if EZO and type(EZO.ToggleDungeonDifficulty) == "function" then
            return EZO.ToggleDungeonDifficulty()
        end
        return false
    end)

    X.Register("REPAIR_EQUIPPED", function()
        if EZO and type(EZO.RepairEquipped) == "function" then
            EZO.RepairEquipped()
        end
        return false
    end)

    X.Register("RECHARGE_WEAPONS", function()
        if EZO and type(EZO.RechargeWeapons) == "function" then
            EZO.RechargeWeapons()
        end
        return false
    end)
end

-- Auto-registrar acciones al cargar el módulo
pcall(function() X.RegisterCore() end)
