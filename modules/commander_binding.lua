-- Módulo de binding principal de EZOTools.
-- Bindings.xml llama a EZOTools.ToggleCommandPanel() para abrir/cerrar el panel.
-- IMPORTANTE: si el panel ya está abierto, el mismo keybind actúa como SELECT
-- para que los usuarios de teclado puedan activar entradas aunque su tecla
-- coincida con la tecla SELECT por defecto de ESO.

local EZO = _G.EZOTools
if type(EZO) ~= "table" then
    EZO = {}
    _G.EZOTools = EZO
end

local function ObtenerEZO()
    local ezo = _G.EZOTools
    if type(ezo) == "table" then return ezo end
    return nil
end

-- Devuelve el diálogo principal de comandos si está disponible
local function ObtenerDialogoPrincipal(ezo)
    if not ezo then return nil end
    if ezo.GamepadDialog and type(ezo.GamepadDialog.Open) == "function" then
        return ezo.GamepadDialog
    end
    if _G.EZOTools_GamepadDialog and type(_G.EZOTools_GamepadDialog.Open) == "function" then
        return _G.EZOTools_GamepadDialog
    end
    return nil
end

local function ObtenerDialogoUtilidades(ezo)
    if not ezo then return nil end
    if ezo.GamepadUtilityDialog and type(ezo.GamepadUtilityDialog.Open) == "function" then
        return ezo.GamepadUtilityDialog
    end
    return nil
end

local function ObtenerDialogoUtilidadesRecientes(ezo)
    if not ezo then return nil end
    if ezo.GamepadUtilityRecentDialog and type(ezo.GamepadUtilityRecentDialog.Open) == "function" then
        return ezo.GamepadUtilityRecentDialog
    end
    return nil
end

-- Devuelve el diálogo de ajustes si está disponible
local function ObtenerDialogoAjustes(ezo)
    if not ezo then return nil end
    if ezo.GamepadSettingsDialog and type(ezo.GamepadSettingsDialog.Open) == "function" then
        return ezo.GamepadSettingsDialog
    end
    return nil
end

local function AvisarNoDisponible(ezo)
    if ezo and ezo.Print then
        ezo.Print(GetString(EZO_MSG_CMD_PANEL_MISSING))
    else
        d(GetString(EZO_MSG_CMD_PANEL_MISSING))
    end
end

-- Keybind principal: abre el panel o, si ya está abierto, ejecuta la selección actual
function EZO.ToggleCommandPanel()
    local ezo = ObtenerEZO()
    if not ezo then AvisarNoDisponible(nil); return end

    -- Si el diálogo de ajustes está abierto, activar la selección actual
    local sdlg = ObtenerDialogoAjustes(ezo)
    if sdlg and type(sdlg.IsShowing) == "function" and sdlg.IsShowing() then
        if type(sdlg.ActivateSelected) == "function" then
            local ok, hecho = pcall(function() return sdlg.ActivateSelected() end)
            if ok and hecho then return end
        end
        return
    end

    local dlg = ObtenerDialogoPrincipal(ezo)
    if not dlg then AvisarNoDisponible(ezo); return end

    local udlg = ObtenerDialogoUtilidades(ezo)
    if udlg and type(udlg.IsShowing) == "function" and udlg.IsShowing() then
        if type(udlg.Close) == "function" then
            pcall(function() udlg.Close() end)
        end
    end
    local rdlg = ObtenerDialogoUtilidadesRecientes(ezo)
    if rdlg and type(rdlg.IsShowing) == "function" and rdlg.IsShowing() then
        if type(rdlg.Close) == "function" then
            pcall(function() rdlg.Close() end)
        end
    end

    -- Si el panel ya está abierto, activar la selección actual (no cerrar)
    if type(dlg.IsShowing) == "function" and dlg.IsShowing() then
        if type(dlg.ActivateSelected) == "function" then
            local ok, hecho = pcall(function() return dlg.ActivateSelected() end)
            if ok and hecho then return end
        end
        return
    end

    -- Panel cerrado: abrirlo
    pcall(function() dlg.Open() end)
end

function EZO.ToggleUtilityPanel()
    local ezo = ObtenerEZO()
    if not ezo then AvisarNoDisponible(nil); return end

    local sdlg = ObtenerDialogoAjustes(ezo)
    if sdlg and type(sdlg.IsShowing) == "function" and sdlg.IsShowing() then
        if type(sdlg.ActivateSelected) == "function" then
            local ok, hecho = pcall(function() return sdlg.ActivateSelected() end)
            if ok and hecho then return end
        end
        return
    end

    local rdlg = ObtenerDialogoUtilidadesRecientes(ezo)
    if rdlg and type(rdlg.IsShowing) == "function" and rdlg.IsShowing() then
        if type(rdlg.ActivateSelected) == "function" then
            local ok, hecho = pcall(function() return rdlg.ActivateSelected() end)
            if ok and hecho then return end
        end
        return
    end

    local dlg = ObtenerDialogoUtilidades(ezo)
    if not dlg then AvisarNoDisponible(ezo); return end

    if type(dlg.IsShowing) == "function" and dlg.IsShowing() then
        if type(dlg.ActivateSelected) == "function" then
            local ok, hecho = pcall(function() return dlg.ActivateSelected() end)
            if ok and hecho then return end
        end
        return
    end

    local mdlg = ObtenerDialogoPrincipal(ezo)
    if mdlg and type(mdlg.IsShowing) == "function" and mdlg.IsShowing() then
        if type(mdlg.Close) == "function" then
            pcall(function() mdlg.Close() end)
        end
    end

    pcall(function() dlg.Open() end)
end

-- Keybind de ejecución dedicado (para cuando el panel ya está abierto)
function EZO.ExecuteCommandPanelSelection()
    local ezo = ObtenerEZO()
    if not ezo then AvisarNoDisponible(nil); return end

    -- Si el diálogo de ajustes está abierto, activar selección allí
    local sdlg = ObtenerDialogoAjustes(ezo)
    if sdlg and type(sdlg.IsShowing) == "function" and sdlg.IsShowing() then
        if type(sdlg.ActivateSelected) == "function" then
            pcall(function() return sdlg.ActivateSelected() end)
        end
        return
    end

    local rdlg = ObtenerDialogoUtilidadesRecientes(ezo)
    if rdlg and type(rdlg.IsShowing) == "function" and rdlg.IsShowing() then
        if type(rdlg.ActivateSelected) == "function" then
            pcall(function() return rdlg.ActivateSelected() end)
        end
        return
    end

    local udlg = ObtenerDialogoUtilidades(ezo)
    if udlg and type(udlg.IsShowing) == "function" and udlg.IsShowing() then
        if type(udlg.ActivateSelected) == "function" then
            pcall(function() return udlg.ActivateSelected() end)
        end
        return
    end

    local dlg = ObtenerDialogoPrincipal(ezo)
    if not dlg then AvisarNoDisponible(ezo); return end

    -- Solo ejecutar si el panel está abierto
    if type(dlg.IsShowing) == "function" and dlg.IsShowing() then
        if type(dlg.ActivateSelected) == "function" then
            pcall(function() dlg.ActivateSelected() end)
        end
    end
end
