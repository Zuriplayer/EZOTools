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

    -- Ajustes completos del addon via LibAddonMenu
    X.Register("OPEN_ADDON_SETTINGS", function()
        if type(IsUnitInCombat) == "function" and IsUnitInCombat("player") then
            if EZO and EZO.Print then EZO.Print(GetString(EZO_MSG_CANT_OPEN_COMBAT)) end
            return false
        end

        local esGamepad = false
        if type(IsInGamepadPreferredMode) == "function" then
            esGamepad = IsInGamepadPreferredMode() == true
        elseif type(IsInGamepadMode) == "function" then
            esGamepad = IsInGamepadMode() == true
        end

        if _G.SCENE_MANAGER and type(_G.SCENE_MANAGER.Show) == "function" then
            if esGamepad then
                _G.SCENE_MANAGER:Show("gamepad_options_root")
            else
                if _G.SCENE_MANAGER:GetScene("gameMenuInGame") ~= nil then
                    _G.SCENE_MANAGER:Show("gameMenuInGame")
                else
                    _G.SCENE_MANAGER:Show("options")
                end
            end
        end

        local function abrirPanelLAM()
            local LAM = _G.LibAddonMenu2
            if not (LAM and type(LAM.OpenToPanel) == "function") then return false end
            local panel = (EZO and EZO._lamPanel) or _G.EZOTools_Panel
            if panel ~= nil then
                LAM:OpenToPanel(panel)
                return true
            end
            LAM:OpenToPanel("EZOTools_Panel")
            return true
        end

        if type(zo_callLater) == "function" then
            zo_callLater(function() pcall(abrirPanelLAM) end, 100)
            return true
        end
        return pcall(abrirPanelLAM)
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
