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

local function ObtenerDialogosActuables(ezo)
    return {
        ObtenerDialogoAjustes(ezo),
        ObtenerDialogoUtilidadesRecientes(ezo),
        ObtenerDialogoUtilidades(ezo),
        ObtenerDialogoPrincipal(ezo),
    }
end

function EZO.HasInteractiveDialogOpen()
    local ezo = ObtenerEZO()
    if not ezo then return false end
    for _, dialogo in ipairs(ObtenerDialogosActuables(ezo)) do
        if EstaDialogoVisible(dialogo) then
            return true
        end
    end
    return false
end

function EZO.ActivateVisibleDialogSelection()
    local ezo = ObtenerEZO()
    if not ezo then return false end
    for _, dialogo in ipairs(ObtenerDialogosActuables(ezo)) do
        if ActivarDialogoSiVisible(dialogo) then
            return true
        end
    end
    return false
end

-- Keybind principal: abre el panel o, si ya está abierto, ejecuta la selección actual
function EZO.ToggleCommandPanel()
    local ezo = ObtenerEZO()
    if not ezo then AvisarNoDisponible(nil); return end

    local sdlg = ObtenerDialogoAjustes(ezo)
    if EstaDialogoVisible(sdlg) and EZO.ActivateVisibleDialogSelection() then
        return
    end

    local dlg = ObtenerDialogoPrincipal(ezo)
    if not dlg then AvisarNoDisponible(ezo); return end

    local udlg = ObtenerDialogoUtilidades(ezo)
    if EstaDialogoVisible(udlg) then
        if type(udlg.Close) == "function" then
            pcall(function() udlg.Close() end)
        end
    end
    local rdlg = ObtenerDialogoUtilidadesRecientes(ezo)
    if EstaDialogoVisible(rdlg) then
        if type(rdlg.Close) == "function" then
            pcall(function() rdlg.Close() end)
        end
    end

    -- Si el panel ya está abierto, activar la selección actual (no cerrar)
    if EstaDialogoVisible(dlg) then
        if EZO.ActivateVisibleDialogSelection() then return end
        return
    end

    -- Panel cerrado: abrirlo
    pcall(function() dlg.Open() end)
end

function EZO.ToggleUtilityPanel()
    local ezo = ObtenerEZO()
    if not ezo then AvisarNoDisponible(nil); return end

    local sdlg = ObtenerDialogoAjustes(ezo)
    if EstaDialogoVisible(sdlg) and EZO.ActivateVisibleDialogSelection() then
        return
    end

    local rdlg = ObtenerDialogoUtilidadesRecientes(ezo)
    if EstaDialogoVisible(rdlg) and EZO.ActivateVisibleDialogSelection() then
        return
    end

    local dlg = ObtenerDialogoUtilidades(ezo)
    if not dlg then AvisarNoDisponible(ezo); return end

    if EstaDialogoVisible(dlg) then
        if EZO.ActivateVisibleDialogSelection() then return end
        return
    end

    local mdlg = ObtenerDialogoPrincipal(ezo)
    if EstaDialogoVisible(mdlg) then
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

    local dlg = ObtenerDialogoPrincipal(ezo)
    if not dlg then AvisarNoDisponible(ezo); return end

    EZO.ActivateVisibleDialogSelection()
end
