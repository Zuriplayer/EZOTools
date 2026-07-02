-- Wrappers de keybind para los menus laterales.
-- La politica comun de abrir/seleccionar/cerrar otros menus vive en side_menu_manager.lua.

local EZO = _G.EZOTools
if type(EZO) ~= "table" then
    EZO = {}
    _G.EZOTools = EZO
end

local function ObtenerManager()
    local ezo = _G.EZOTools
    if type(ezo) == "table" and ezo.SideMenuManager then
        return ezo.SideMenuManager
    end
    return nil
end

local function AvisarNoDisponible(stringId)
    local ezo = _G.EZOTools
    if ezo and type(ezo.Print) == "function" then
        ezo.Print(GetString(stringId))
    end
end

-- Versión única en shared_utils.lua
local EsModoGamepadPreferido = EZOTools_EsModoGamepadPreferido

local function EstaJugadorEnCombate()
    if type(IsUnitInCombat) ~= "function" then
        return false
    end
    local ok, enCombate = pcall(IsUnitInCombat, "player")
    return ok and enCombate == true
end

local function DebeBloquearUtilidadesEnCombate()
    return EsModoGamepadPreferido() and EstaJugadorEnCombate()
end

function EZO.HasInteractiveDialogOpen()
    local manager = ObtenerManager()
    return manager and type(manager.HasInteractiveDialogOpen) == "function" and manager.HasInteractiveDialogOpen() == true
end

function EZO.ActivateVisibleDialogSelection()
    local manager = ObtenerManager()
    if manager and type(manager.ActivateVisibleSelection) == "function" then
        return manager.ActivateVisibleSelection()
    end
    return false
end

function EZO.ToggleCommandPanel()
    local manager = ObtenerManager()
    if not (manager and type(manager.Toggle) == "function") then
        AvisarNoDisponible(EZO_MSG_CMD_PANEL_MISSING)
        return
    end
    return manager.Toggle("command")
end

function EZO.ToggleUtilityPanel()
    if DebeBloquearUtilidadesEnCombate() then
        return false
    end
    local manager = ObtenerManager()
    if not (manager and type(manager.Toggle) == "function") then
        AvisarNoDisponible(EZO_MSG_UTILITY_PANEL_MISSING)
        return
    end
    return manager.Toggle("utility")
end

-- Keybind de ejecucion dedicado para cuando un dialogo lateral ya esta abierto.
function EZO.ExecuteCommandPanelSelection()
    return EZO.ActivateVisibleDialogSelection()
end
