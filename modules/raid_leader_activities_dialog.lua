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
    Dialog.Close()
    local trialDialog = EZO and EZO.RaidLeaderTrialsDialog
    if trialDialog and type(trialDialog.Open) == "function" then
        if zo_callLater then
            zo_callLater(function() pcall(function() trialDialog.Open() end) end, 150)
        else
            pcall(function() trialDialog.Open() end)
        end
    end
end

local function ConstruirEntradas()
    local entradas = {}

    if EZO and EZO.RaidLeaderTrialsDialog and type(EZO.RaidLeaderTrialsDialog.Open) == "function" then
        entradas[#entradas + 1] = {
            text = GetString(EZO_MENU_TRIAL_TRAVEL),
            callback = AbrirViajeTrials,
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
        callback = function() Dialog.Close() end,
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
