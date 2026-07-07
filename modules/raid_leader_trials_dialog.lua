-- Submenu de viajes a trials en veterano para HOLD X / equivalente teclado.
-- La logica de busqueda y viaje vive en raid_leader_tools.lua.
local EZO = _G.EZOTools or {}
_G.EZOTools = EZO

local Core = EZO.SideMenuCore
EZO.RaidLeaderTrialsDialog = EZO.RaidLeaderTrialsDialog or {}
local Dialog = EZO.RaidLeaderTrialsDialog

local NOMBRE_DIALOGO = "EZO_RAID_LEADER_TRIALS_DIALOG"
Dialog.DIALOG_NAME = NOMBRE_DIALOGO

local ConstruirSubtituloDialogo = EZOTools_ConstruirSubtituloDialogo

local function ReabrirDialogoPrincipal()
    local main = (EZO and EZO.RaidLeaderActivitiesDialog)
        or (EZO and EZO.GamepadDialog)
    if main and type(main.Open) == "function" then
        if zo_callLater then
            zo_callLater(function() pcall(function() main.Open() end) end, 150)
        else
            pcall(function() main.Open() end)
        end
    end
end

local function ResolverTexto(valor)
    if type(valor) == "function" then
        local ok, texto = pcall(valor)
        if ok then return tostring(texto) end
        return "Item"
    end
    return tostring(valor or "Item")
end

local function ConstruirEntradas()
    local entradas = {}
    local tools = EZO and EZO.RaidLeaderTools
    if tools and type(tools.BuildTrialTravelEntries) == "function" then
        local ok, travelEntries = pcall(tools.BuildTrialTravelEntries)
        if ok and type(travelEntries) == "table" then
            for _, entry in ipairs(travelEntries) do
                entradas[#entradas + 1] = entry
            end
        end
    end

    entradas[#entradas + 1] = {
        text = GetString(EZO_SETTINGS_BACK),
        callback = function()
            Dialog.Close()
            ReabrirDialogoPrincipal()
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
        titleText = function() return GetString(EZO_MENU_TRIAL_TRAVEL_TITLE) end,
        mainText = ConstruirSubtituloDialogo,
        buildEntries = ConstruirEntradas,
        dynamicText = true,
        trackActiveDialog = true,
        onNegative = function(_, _, closeCurrent)
            closeCurrent()
            ReabrirDialogoPrincipal()
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

    local tools = EZO and EZO.RaidLeaderTools
    local entries = {}
    if tools and type(tools.BuildTrialTravelEntries) == "function" then
        local ok, travelEntries = pcall(tools.BuildTrialTravelEntries)
        if ok and type(travelEntries) == "table" then
            entries = travelEntries
        end
    end

    for _, entry in ipairs(entries) do
        AddMenuItem(ResolverTexto(entry.text), function()
            local ok, keepOpen = pcall(entry.callback or function() end)
            if not ok or keepOpen ~= true then
                if HideMenu then HideMenu() end
                if EZO then EZO._contextMenuOpen = false end
            end
        end)
    end

    if AddMenuSeparator then AddMenuSeparator() end

    AddMenuItem(GetString(EZO_SETTINGS_BACK), function()
        if EZO and EZO.RaidLeaderActivitiesDialog
            and type(EZO.RaidLeaderActivitiesDialog.OpenMouse) == "function" then
            if zo_callLater then
                zo_callLater(function() EZO.RaidLeaderActivitiesDialog.OpenMouse(anchor) end, 10)
            else
                EZO.RaidLeaderActivitiesDialog.OpenMouse(anchor)
            end
        elseif _G.EZOTools_ContextMenu and type(_G.EZOTools_ContextMenu.OpenMouse) == "function" then
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
