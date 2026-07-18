-- Gestion comun de apertura/seleccion de menus laterales.
-- No construye entradas ni registra dialogos: solo aplica la politica estable
-- de keybinds para HOLD X/HOLD Y y futuros menus equivalentes.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.SideMenuManager = EZO.SideMenuManager or {}
local Manager = EZO.SideMenuManager

local menus = {}
local children = {}
local activationOrder = {}

local function ObtenerEZO()
    local ezo = _G.EZOTools
    if type(ezo) == "table" then return ezo end
    return nil
end

local function ResolverDialogo(config)
    if type(config) ~= "table" then return nil end

    local dialogKey = config.dialogKey
    if type(dialogKey) == "string" and dialogKey ~= "" then
        local ezo = ObtenerEZO()
        local dialog = ezo and ezo[dialogKey] or nil
        if type(dialog) == "table" and type(dialog.Open) == "function" then
            return dialog
        end
    end

    local legacyGlobal = config.legacyGlobal
    if type(legacyGlobal) == "string" and legacyGlobal ~= "" then
        local dialog = _G[legacyGlobal]
        if type(dialog) == "table" and type(dialog.Open) == "function" then
            return dialog
        end
    end

    local dialog = config.dialog
    if type(dialog) == "function" then
        local ok, resolved = pcall(dialog)
        if ok then return resolved end
        return nil
    end
    if type(dialog) == "table" then
        return dialog
    end
    return nil
end

local function AvisarNoDisponible(config)
    local ezo = ObtenerEZO()
    local stringId = type(config) == "table" and config.missingStringId or nil
    if ezo and type(ezo.Print) == "function" and stringId then
        ezo.Print(GetString(stringId))
    end
end

local function EstaDialogoVisible(dialogo)
    return dialogo
        and type(dialogo.IsShowing) == "function"
        and dialogo.IsShowing()
end

local function ActivarDialogoSiVisible(dialogo)
    if not EstaDialogoVisible(dialogo) then
        return false
    end
    if type(dialogo.ActivateSelected) == "function" then
        local ok, hecho = pcall(function() return dialogo.ActivateSelected() end)
        if ok and hecho then
            return true
        end
    end
    return true
end

local function CerrarDialogoSiVisible(dialogo)
    if not EstaDialogoVisible(dialogo) then
        return
    end
    if type(dialogo.Close) == "function" then
        pcall(function() dialogo.Close() end)
    end
end

local function ObtenerConfig(id)
    return menus[id] or children[id]
end

local function ObtenerDialogo(id)
    return ResolverDialogo(ObtenerConfig(id))
end

local function ActivarPrimeroVisible(ids)
    if type(ids) ~= "table" then return false end
    for _, id in ipairs(ids) do
        if ActivarDialogoSiVisible(ObtenerDialogo(id)) then
            return true
        end
    end
    return false
end

local function EstaAlgunoVisible(ids)
    if type(ids) ~= "table" then return false end
    for _, id in ipairs(ids) do
        if EstaDialogoVisible(ObtenerDialogo(id)) then
            return true
        end
    end
    return false
end

local function CerrarLista(ids)
    if type(ids) ~= "table" then return end
    for _, id in ipairs(ids) do
        CerrarDialogoSiVisible(ObtenerDialogo(id))
    end
end

local function CopiarLista(origen)
    local copia = {}
    if type(origen) ~= "table" then
        return copia
    end
    for _, valor in ipairs(origen) do
        copia[#copia + 1] = valor
    end
    return copia
end

local function NormalizarConfig(id, config, tipo)
    return {
        id = id,
        type = tipo,
        dialog = config.dialog,
        dialogKey = config.dialogKey,
        legacyGlobal = config.legacyGlobal,
        parent = config.parent,
        prioritizes = CopiarLista(config.prioritizes),
        closes = CopiarLista(config.closes),
        missingStringId = config.missingStringId,
    }
end

function Manager.RegisterMenu(id, config)
    if type(id) ~= "string" or id == "" or type(config) ~= "table" then
        return
    end
    menus[id] = NormalizarConfig(id, config, "menu")
end

function Manager.RegisterChild(id, config)
    if type(id) ~= "string" or id == "" or type(config) ~= "table" then
        return
    end
    children[id] = NormalizarConfig(id, config, "child")
end

function Manager.SetActivationOrder(order)
    activationOrder = CopiarLista(order)
end

function Manager.GetMenuConfig(id)
    return menus[id]
end

function Manager.GetChildConfig(id)
    return children[id]
end

function Manager.IsDialogVisible(id)
    return EstaDialogoVisible(ObtenerDialogo(id))
end

function Manager.HasInteractiveDialogOpen()
    if EstaAlgunoVisible(activationOrder) then
        return true
    end

    for id in pairs(children) do
        if Manager.IsDialogVisible(id) then return true end
    end
    for id in pairs(menus) do
        if Manager.IsDialogVisible(id) then return true end
    end
    return false
end

function Manager.ActivateVisibleSelection()
    if ActivarPrimeroVisible(activationOrder) then
        return true
    end

    for id in pairs(children) do
        if ActivarDialogoSiVisible(ObtenerDialogo(id)) then return true end
    end
    for id in pairs(menus) do
        if ActivarDialogoSiVisible(ObtenerDialogo(id)) then return true end
    end
    return false
end

function Manager.Toggle(id)
    local config = menus[id]
    if type(config) ~= "table" then
        AvisarNoDisponible({ missingStringId = EZO_MSG_CMD_PANEL_MISSING })
        return
    end

    if ActivarPrimeroVisible(config.prioritizes) then
        return
    end

    local dialog = ResolverDialogo(config)
    if not dialog then
        AvisarNoDisponible(config)
        return
    end

    if EstaDialogoVisible(dialog) then
        Manager.ActivateVisibleSelection()
        return
    end

    CerrarLista(config.closes)

    if type(dialog.Open) == "function" then
        pcall(function() dialog.Open() end)
    else
        AvisarNoDisponible(config)
    end
end

-- Registro declarativo de menus laterales propios de EZOTools.
-- Para anadir un nuevo menu lateral:
-- 1. crear su dialogo con SideMenuCore;
-- 2. registrarlo aqui como menu;
-- 3. anadirlo a closes/prioritizes segun corresponda;
-- 4. exponer un wrapper de keybind que llame a Manager.Toggle(id).
local MENU_DEFINITIONS = {
    {
        id = "command",
        dialogKey = "GamepadDialog",
        legacyGlobal = "EZOTools_GamepadDialog",
        prioritizes = { "settings", "trialTravel", "groupActivities" },
        closes = { "utility", "utilityRecent" },
        missingStringId = EZO_MSG_CMD_PANEL_MISSING,
    },
    {
        id = "utility",
        dialogKey = "GamepadUtilityDialog",
        prioritizes = { "settings", "utilityRecent" },
        closes = { "command", "groupActivities", "trialTravel" },
        missingStringId = EZO_MSG_UTILITY_PANEL_MISSING,
    },
    {
        id = "groupActivities",
        dialogKey = "RaidLeaderActivitiesDialog",
        prioritizes = { "trialTravel" },
        closes = { "command", "settings", "utility", "utilityRecent" },
        missingStringId = EZO_MSG_GROUP_ACTIVITIES_PANEL_MISSING,
    },
}

local CHILD_DEFINITIONS = {
    {
        id = "settings",
        dialogKey = "GamepadSettingsDialog",
        parent = "command",
    },
    {
        id = "utilityRecent",
        dialogKey = "GamepadUtilityRecentDialog",
        parent = "utility",
    },
    {
        id = "trialTravel",
        dialogKey = "RaidLeaderTrialsDialog",
        parent = "groupActivities",
    },
}

for _, def in ipairs(MENU_DEFINITIONS) do
    Manager.RegisterMenu(def.id, def)
end

for _, def in ipairs(CHILD_DEFINITIONS) do
    Manager.RegisterChild(def.id, def)
end

Manager.SetActivationOrder({
    "settings",
    "trialTravel",
    "groupActivities",
    "utilityRecent",
    "utility",
    "command",
})
