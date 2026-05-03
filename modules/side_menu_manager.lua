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

local function DialogoPrincipal()
    local ezo = ObtenerEZO()
    if not ezo then return nil end
    if ezo.GamepadDialog and type(ezo.GamepadDialog.Open) == "function" then
        return ezo.GamepadDialog
    end
    if _G.EZOTools_GamepadDialog and type(_G.EZOTools_GamepadDialog.Open) == "function" then
        return _G.EZOTools_GamepadDialog
    end
    return nil
end

local function DialogoUtilidades()
    local ezo = ObtenerEZO()
    if ezo and ezo.GamepadUtilityDialog and type(ezo.GamepadUtilityDialog.Open) == "function" then
        return ezo.GamepadUtilityDialog
    end
    return nil
end

local function DialogoUtilidadesRecientes()
    local ezo = ObtenerEZO()
    if ezo and ezo.GamepadUtilityRecentDialog and type(ezo.GamepadUtilityRecentDialog.Open) == "function" then
        return ezo.GamepadUtilityRecentDialog
    end
    return nil
end

local function DialogoAjustes()
    local ezo = ObtenerEZO()
    if ezo and ezo.GamepadSettingsDialog and type(ezo.GamepadSettingsDialog.Open) == "function" then
        return ezo.GamepadSettingsDialog
    end
    return nil
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
        dialog = DialogoPrincipal,
        prioritizes = { "settings" },
        closes = { "utility", "utilityRecent" },
        missingStringId = EZO_MSG_CMD_PANEL_MISSING,
    },
    {
        id = "utility",
        dialog = DialogoUtilidades,
        prioritizes = { "settings", "utilityRecent" },
        closes = { "command" },
        missingStringId = EZO_MSG_UTILITY_PANEL_MISSING,
    },
}

local CHILD_DEFINITIONS = {
    {
        id = "settings",
        dialog = DialogoAjustes,
        parent = "command",
    },
    {
        id = "utilityRecent",
        dialog = DialogoUtilidadesRecientes,
        parent = "utility",
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
    "utilityRecent",
    "utility",
    "command",
})
