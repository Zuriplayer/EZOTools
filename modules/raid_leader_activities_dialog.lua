-- Menu de actividades de grupo/trial/dungeon para HOLD X y keybind dedicado.
-- Agrupa submenus de dominio sin mezclar la logica en overlay.lua ni actions.lua.
local EZO = _G.EZOTools or {}
_G.EZOTools = EZO

local Core = EZO.SideMenuCore
EZO.RaidLeaderActivitiesDialog = EZO.RaidLeaderActivitiesDialog or {}
local Dialog = EZO.RaidLeaderActivitiesDialog

local NOMBRE_DIALOGO = "EZO_RAID_LEADER_ACTIVITIES_DIALOG"
Dialog.DIALOG_NAME = NOMBRE_DIALOGO

local ConstruirSubtituloDialogo = EZOTools_ConstruirSubtituloDialogo

local function EmitirDiagnosticoAperturaTrial(stage, detail)
    if not (EZO and EZO.Debug and type(EZO.Debug.EmitReport) == "function") then
        return
    end

    local trialDialog = EZO and EZO.RaidLeaderTrialsDialog
    local lines = {
        "=== EZOTools group activities ===",
        "stage=" .. tostring(stage or ""),
        "detail=" .. tostring(detail or ""),
        "activities.isShowing=" .. tostring(type(Dialog.IsShowing) == "function" and Dialog.IsShowing() or ""),
        "trialDialog.exists=" .. tostring(type(trialDialog) == "table"),
        "trialDialog.openFunction=" .. tostring(type(trialDialog) == "table" and type(trialDialog.Open) == "function"),
        "================================",
    }
    EZO.Debug.EmitReport(GetString(EZO_DEBUG_GROUP_ACTIVITIES_TITLE), lines, { force = true })
end

local function EmitirDiagnosticoAccionLateral(stage, actionKey, result)
    if not (EZO and type(EZO.IsDebugModeEnabled) == "function" and EZO.IsDebugModeEnabled()) then
        return
    end
    if not (EZO.Debug and type(EZO.Debug.EmitReport) == "function") then
        return
    end
    EZO.Debug.EmitReport(GetString(EZO_DEBUG_GROUP_ACTIVITIES_TITLE), {
        "=== EZOTools side menu raid action ===",
        "stage=" .. tostring(stage or ""),
        "action=" .. tostring(actionKey or ""),
        "result=" .. tostring(result or ""),
        "activities.isShowing=" .. tostring(type(Dialog.IsShowing) == "function" and Dialog.IsShowing() or ""),
        "================================",
    })
end

local function AbrirDialogoPrincipal()
    local main = EZO and EZO.GamepadDialog
    if main and type(main.Open) == "function" then
        if zo_callLater then
            zo_callLater(function() pcall(function() main.Open() end) end, 150)
        else
            pcall(function() main.Open() end)
        end
    end
end

local function AbrirViajeTrials()
    local trialDialog = EZO and EZO.RaidLeaderTrialsDialog
    if trialDialog and type(trialDialog.Open) == "function" then
        EmitirDiagnosticoAperturaTrial("open-request", "trial dialog available")
        if zo_callLater then
            zo_callLater(function()
                local ok, err = pcall(function() trialDialog.Open() end)
                EmitirDiagnosticoAperturaTrial("open-called", ok and "ok" or tostring(err or "error"))
            end, 150)
        else
            local ok, err = pcall(function() trialDialog.Open() end)
            EmitirDiagnosticoAperturaTrial("open-called", ok and "ok" or tostring(err or "error"))
        end
    else
        EmitirDiagnosticoAperturaTrial("open-missing", "trial dialog unavailable")
    end
    return false
end

local function ResolverTexto(valor)
    if type(valor) == "function" then
        local ok, texto = pcall(valor)
        if ok then return tostring(texto) end
        return "Item"
    end
    return tostring(valor or "Item")
end

local function ReportarErrorCallback(err)
    local mensaje = zo_strformat(GetString(EZO_MSG_MENU_CALLBACK_FAILED), tostring(err or "error"))
    if EZO and type(EZO.DebugPrint) == "function" then
        EZO.DebugPrint(mensaje)
    elseif EZO and type(EZO.Print) == "function" then
        EZO.Print(mensaje)
    elseif type(d) == "function" then
        d(mensaje)
    end
end

local function EjecutarCallbackSeguro(cb)
    if type(cb) ~= "function" then
        return false
    end
    local ok, result = pcall(cb)
    if not ok then
        ReportarErrorCallback(result)
        return false
    end
    return result
end

local function PuedeMostrarCambioDificultad()
    return EZO
        and type(EZO.CanShowDungeonDifficultyOption) == "function"
        and EZO.CanShowDungeonDifficultyOption()
        and type(EZO.GetDungeonDifficultyMenuText) == "function"
        and type(EZO.ToggleDungeonDifficulty) == "function"
end

local function CambiarDificultadInstancia()
    if EZO and type(EZO.ToggleDungeonDifficulty) == "function" then
        return EZO.ToggleDungeonDifficulty()
    end
    return false
end

local function PuedeAbandonarGrupo()
    return EZO and type(EZO.CanLeaveGroup) == "function" and EZO.CanLeaveGroup()
end

local function PuedeSalirInstancia()
    return EZO and type(EZO.CanLeaveInstance) == "function" and EZO.CanLeaveInstance()
end

local function PuedeAbandonarGrupoEInstancia()
    return EZO
        and type(EZO.CanLeaveGroupAndInstance) == "function"
        and EZO.CanLeaveGroupAndInstance()
end

local function EsLiderDeGrupo()
    return EZO
        and EZO.RaidLeaderTools
        and type(EZO.RaidLeaderTools.IsPlayerGroupLeader) == "function"
        and EZO.RaidLeaderTools.IsPlayerGroupLeader()
end

local function PuedeResetearInstancia()
    return EsLiderDeGrupo()
        and EZO.RaidLeaderReset
        and type(EZO.RaidLeaderReset.CanStart) == "function"
        and EZO.RaidLeaderReset.CanStart()
        and type(EZO.RaidLeaderReset.Start) == "function"
end

local function PuedeDisbandearGrupo()
    return EsLiderDeGrupo()
        and EZO.RaidLeaderTools
        and type(EZO.RaidLeaderTools.CanDisbandGroup) == "function"
        and EZO.RaidLeaderTools.CanDisbandGroup()
        and type(EZO.RaidLeaderTools.DisbandGroup) == "function"
end

local function ConstruirEntradas()
    local entradas = {}

    if PuedeDisbandearGrupo() then
        entradas[#entradas + 1] = {
            text = GetString(EZO_MENU_DISBAND_GROUP),
            callback = function()
                return EZO.RaidLeaderTools.DisbandGroup()
            end,
            key = "disbandGroup",
        }
    end

    if PuedeResetearInstancia() then
        entradas[#entradas + 1] = {
            text = GetString(EZO_MENU_INSTANCE_RESET),
            callback = function()
                return EZO.RaidLeaderReset.Start()
            end,
            key = "instanceReset",
        }
    end

    if PuedeMostrarCambioDificultad() then
        entradas[#entradas + 1] = {
            text = EZO.GetDungeonDifficultyMenuText,
            callback = CambiarDificultadInstancia,
        }
    end

    if EZO and EZO.RaidLeaderTrialsDialog and type(EZO.RaidLeaderTrialsDialog.Open) == "function" then
        entradas[#entradas + 1] = {
            text = GetString(EZO_MENU_TRIAL_TRAVEL),
            callback = AbrirViajeTrials,
            key = "trialTravel",
        }
    end

    if PuedeAbandonarGrupo() and type(EZO.LeaveGroup) == "function" then
        entradas[#entradas + 1] = {
            text = GetString(EZO_MENU_LEAVE_GROUP),
            callback = EZO.LeaveGroup,
        }
    end

    if PuedeSalirInstancia() and type(EZO.LeaveInstance) == "function" then
        entradas[#entradas + 1] = {
            text = GetString(EZO_MENU_LEAVE_INSTANCE),
            callback = EZO.LeaveInstance,
        }
    end

    if PuedeAbandonarGrupoEInstancia() and type(EZO.LeaveGroupAndInstance) == "function" then
        entradas[#entradas + 1] = {
            text = GetString(EZO_MENU_LEAVE_GROUP_INSTANCE),
            callback = EZO.LeaveGroupAndInstance,
        }
    end

    entradas[#entradas + 1] = {
        text = GetString(EZO_SETTINGS_BACK),
        callback = function()
            Dialog.Close()
            AbrirDialogoPrincipal()
        end,
    }
    entradas[#entradas + 1] = {
        text = GetString(EZO_SETTINGS_CLOSE),
        callback = function()
            Dialog.Close()
        end,
    }

    return entradas
end

if Core and type(Core.CreateDialog) == "function" then
    Core.CreateDialog({
        namespace = Dialog,
        dialogName = NOMBRE_DIALOGO,
        titleText = function() return GetString(EZO_MENU_GROUP_ACTIVITIES_TITLE) end,
        mainText = ConstruirSubtituloDialogo,
        buildEntries = ConstruirEntradas,
        dynamicText = true,
        trackActiveDialog = true,
        prepareCallback = function(entry, cb, _, closeCurrent)
            if entry and entry.key == "trialTravel" and type(cb) == "function" then
                return function()
                    EmitirDiagnosticoAperturaTrial("prepare", "closing group activities before trial travel")
                    closeCurrent()
                    if zo_callLater then
                        zo_callLater(function() pcall(cb) end, 200)
                    else
                        pcall(cb)
                    end
                end
            end
            if entry and (entry.key == "instanceReset" or entry.key == "disbandGroup")
                and type(cb) == "function" then
                return function()
                    EmitirDiagnosticoAccionLateral("selected", entry.key, "closing-parent")
                    closeCurrent()
                    local function Run()
                        EmitirDiagnosticoAccionLateral("dispatching", entry.key, "started")
                        local result = EjecutarCallbackSeguro(cb)
                        EmitirDiagnosticoAccionLateral("dispatched", entry.key, tostring(result))
                    end
                    if zo_callLater then
                        zo_callLater(Run, 50)
                    else
                        Run()
                    end
                end
            end
            return cb
        end,
        onNegative = function(_, _, closeCurrent)
            closeCurrent()
            AbrirDialogoPrincipal()
        end,
    })
end

local AbrirDialogoGamepad = Dialog.Open

function Dialog.OpenGamepad()
    if type(AbrirDialogoGamepad) == "function" then
        AbrirDialogoGamepad()
    end
    return false
end

function Dialog.Open()
    return Dialog.OpenGamepad()
end

function Dialog.OpenMouse(anchor)
    if type(AddMenuItem) ~= "function" or type(ShowMenu) ~= "function" then
        return Dialog.OpenGamepad()
    end

    anchor = anchor
        or (_G.EZOTools_ContextMenu and _G.EZOTools_ContextMenu._lastAnchor)
        or GuiRoot

    if ClearMenu then ClearMenu() end

    if PuedeDisbandearGrupo() then
        AddMenuItem(GetString(EZO_MENU_DISBAND_GROUP), function()
            if HideMenu then HideMenu() end
            if EZO then EZO._contextMenuOpen = false end
            local function Run()
                EjecutarCallbackSeguro(function() EZO.RaidLeaderTools.DisbandGroup() end)
            end
            if zo_callLater then
                zo_callLater(Run, 50)
            else
                Run()
            end
            return false
        end)
    end

    if PuedeResetearInstancia() then
        AddMenuItem(GetString(EZO_MENU_INSTANCE_RESET), function()
            if HideMenu then HideMenu() end
            if EZO then EZO._contextMenuOpen = false end
            local function Run()
                EjecutarCallbackSeguro(function() EZO.RaidLeaderReset.Start() end)
            end
            if zo_callLater then
                zo_callLater(Run, 50)
            else
                Run()
            end
            return false
        end)
    end

    if PuedeMostrarCambioDificultad() then
        AddMenuItem(ResolverTexto(EZO.GetDungeonDifficultyMenuText), function()
            local ok = pcall(CambiarDificultadInstancia)
            if not ok then return false end
            if HideMenu then HideMenu() end
            if EZO then EZO._contextMenuOpen = false end
            return false
        end)
    end

    if EZO and EZO.RaidLeaderTrialsDialog and type(EZO.RaidLeaderTrialsDialog.OpenMouse) == "function" then
        AddMenuItem(GetString(EZO_MENU_TRIAL_TRAVEL), function()
            if zo_callLater then
                zo_callLater(function()
                    EZO.RaidLeaderTrialsDialog.OpenMouse(anchor, "groupActivities")
                end, 10)
            else
                EZO.RaidLeaderTrialsDialog.OpenMouse(anchor, "groupActivities")
            end
            return true
        end)
    end

    if PuedeAbandonarGrupo() and type(EZO.LeaveGroup) == "function" then
        AddMenuItem(GetString(EZO_MENU_LEAVE_GROUP), function()
            EjecutarCallbackSeguro(EZO.LeaveGroup)
            if HideMenu then HideMenu() end
            if EZO then EZO._contextMenuOpen = false end
            return false
        end)
    end

    if PuedeSalirInstancia() and type(EZO.LeaveInstance) == "function" then
        AddMenuItem(GetString(EZO_MENU_LEAVE_INSTANCE), function()
            EjecutarCallbackSeguro(EZO.LeaveInstance)
            if HideMenu then HideMenu() end
            if EZO then EZO._contextMenuOpen = false end
            return false
        end)
    end

    if PuedeAbandonarGrupoEInstancia() and type(EZO.LeaveGroupAndInstance) == "function" then
        AddMenuItem(GetString(EZO_MENU_LEAVE_GROUP_INSTANCE), function()
            EjecutarCallbackSeguro(EZO.LeaveGroupAndInstance)
            if HideMenu then HideMenu() end
            if EZO then EZO._contextMenuOpen = false end
            return false
        end)
    end

    if AddMenuSeparator then AddMenuSeparator() end

    AddMenuItem(GetString(EZO_SETTINGS_BACK), function()
        if _G.EZOTools_ContextMenu and type(_G.EZOTools_ContextMenu.OpenMouse) == "function" then
            if zo_callLater then
                zo_callLater(function() _G.EZOTools_ContextMenu.OpenMouse(anchor) end, 10)
            else
                _G.EZOTools_ContextMenu.OpenMouse(anchor)
            end
        end
    end)

    AddMenuItem(GetString(EZO_SETTINGS_CLOSE), function()
        if HideMenu then HideMenu() end
        if EZO then EZO._contextMenuOpen = false end
    end)

    ShowMenu(anchor)
    if EZO then EZO._contextMenuOpen = true end
    return true
end
