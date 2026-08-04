-- Módulo de panel de opciones LAM de EZOTools.
-- Construye el panel principal de LibAddonMenu unificando las secciones registradas
-- por los demás módulos más los sliders de mantenimiento propios.

EZOTools_Menu = EZOTools_Menu or {}
local MENU = EZOTools_Menu

local ADDON_NAME   = "EZOTools"
local DISPLAY_NAME = "E|cB040FFZ|rOTools"
local PANEL_ID     = "EZOTools_Panel"
-- VERSION viene de core.lua via EZOTools.ADDON_VERSION

-- Garantiza que los valores por defecto de mantenimiento existen en sv
-- AsegurarDefectos disponible como EZOTools_AsegurarDefectos (shared_utils.lua)
local AsegurarDefectos = EZOTools_AsegurarDefectos

-- Construye la lista completa de opciones: secciones registradas + mantenimiento
local function ConstruirOpciones()
    local opciones = {}

    -- Opciones registradas por otros módulos (overlay, general, etc.)
    if EZOTools_LAM and EZOTools_LAM.GetSortedOptions then
        opciones = EZOTools_LAM.GetSortedOptions() or {}
    end

    -- Sección de mantenimiento (umbrales de reparación y recarga)
    opciones[#opciones + 1] = EZOTools_LAM.CreateInfoHeader(
        GetString(EZO_OPTION_MAINTENANCE),
        GetString(EZO_OPTION_MAINTENANCE_NOTE)
    )

    opciones[#opciones + 1] = {
        type    = "slider",
        name    = GetString(EZO_OPTION_REPAIR_THRESHOLD),
        tooltip = GetString(EZO_OPTION_REPAIR_THRESHOLD_TOOLTIP),
        min     = 1, max = 100, step = 1,
        getFunc = function() return tonumber(EZOTools.sv.general.repairThreshold) or 25 end,
        setFunc = function(v)
            EZOTools.sv.general.repairThreshold = tonumber(v)
            if EZOTools_Overlay and EZOTools_Overlay.RefreshDot then EZOTools_Overlay.RefreshDot() end
        end,
        default = 25,
    }

    opciones[#opciones + 1] = {
        type    = "slider",
        name    = GetString(EZO_OPTION_RECHARGE_THRESHOLD),
        tooltip = GetString(EZO_OPTION_RECHARGE_THRESHOLD_TOOLTIP),
        min     = 1, max = 100, step = 1,
        getFunc = function() return tonumber(EZOTools.sv.general.rechargeThreshold) or 25 end,
        setFunc = function(v)
            EZOTools.sv.general.rechargeThreshold = tonumber(v)
            if EZOTools_Overlay and EZOTools_Overlay.RefreshDot then EZOTools_Overlay.RefreshDot() end
        end,
        default = 25,
    }

    opciones[#opciones + 1] = EZOTools_LAM.CreateInfoHeader(
        GetString(EZO_OPTION_STOCK_ALERTS),
        GetString(EZO_OPTION_LOW_STOCK_ALERTS_NOTE)
    )

    opciones[#opciones + 1] = {
        type    = "checkbox",
        name    = GetString(EZO_OPTION_REPAIR_KIT_ALERT_ENABLE),
        tooltip = GetString(EZO_OPTION_REPAIR_KIT_ALERT_ENABLE_TOOLTIP),
        getFunc = function() return EZOTools.sv.general.repairKitAlertEnabled ~= false end,
        setFunc = function(v)
            EZOTools.sv.general.repairKitAlertEnabled = v
            if EZOTools_Overlay and EZOTools_Overlay.Refresh then EZOTools_Overlay.Refresh() end
            if EZOTools_LAM and EZOTools_LAM.RequestSettingsRefresh then
                EZOTools_LAM.RequestSettingsRefresh()
            end
        end,
        default = true,
    }

    opciones[#opciones + 1] = {
        type    = "slider",
        name    = GetString(EZO_OPTION_REPAIR_KIT_ALERT_THRESHOLD),
        tooltip = GetString(EZO_OPTION_REPAIR_KIT_ALERT_THRESHOLD_TOOLTIP),
        min     = 0, max = 200, step = 1,
        getFunc = function() return tonumber(EZOTools.sv.general.repairKitAlertThreshold) or 25 end,
        setFunc = function(v)
            EZOTools.sv.general.repairKitAlertThreshold = tonumber(v)
            if EZOTools_Overlay and EZOTools_Overlay.Refresh then EZOTools_Overlay.Refresh() end
        end,
        default = 25,
        disabled = function() return EZOTools.sv.general.repairKitAlertEnabled == false end,
    }

    opciones[#opciones + 1] = {
        type    = "checkbox",
        name    = GetString(EZO_OPTION_SOUL_GEM_ALERT_ENABLE),
        tooltip = GetString(EZO_OPTION_SOUL_GEM_ALERT_ENABLE_TOOLTIP),
        getFunc = function() return EZOTools.sv.general.soulGemAlertEnabled ~= false end,
        setFunc = function(v)
            EZOTools.sv.general.soulGemAlertEnabled = v
            if EZOTools_Overlay and EZOTools_Overlay.Refresh then EZOTools_Overlay.Refresh() end
            if EZOTools_LAM and EZOTools_LAM.RequestSettingsRefresh then
                EZOTools_LAM.RequestSettingsRefresh()
            end
        end,
        default = true,
    }

    opciones[#opciones + 1] = {
        type    = "slider",
        name    = GetString(EZO_OPTION_SOUL_GEM_ALERT_THRESHOLD),
        tooltip = GetString(EZO_OPTION_SOUL_GEM_ALERT_THRESHOLD_TOOLTIP),
        min     = 0, max = 200, step = 1,
        getFunc = function() return tonumber(EZOTools.sv.general.soulGemAlertThreshold) or 25 end,
        setFunc = function(v)
            EZOTools.sv.general.soulGemAlertThreshold = tonumber(v)
            if EZOTools_Overlay and EZOTools_Overlay.Refresh then EZOTools_Overlay.Refresh() end
        end,
        default = 25,
        disabled = function() return EZOTools.sv.general.soulGemAlertEnabled == false end,
    }

    opciones[#opciones + 1] = EZOTools_LAM.CreateInfoHeader(
        GetString(EZO_OPTION_DEBUG),
        GetString(EZO_OPTION_DEBUG_MODE_TOOLTIP)
    )

    opciones[#opciones + 1] = {
        type = "checkbox",
        name = GetString(EZO_OPTION_DEBUG_MODE),
        tooltip = GetString(EZO_OPTION_DEBUG_MODE_TOOLTIP),
        getFunc = function()
            return EZOTools and type(EZOTools.IsDebugModeEnabled) == "function" and EZOTools.IsDebugModeEnabled() == true
        end,
        setFunc = function(v)
            if EZOTools and type(EZOTools.SetDebugModeEnabled) == "function" then
                EZOTools.SetDebugModeEnabled(v)
            end
            if EZOTools_LAM and EZOTools_LAM.RequestSettingsRefresh then
                EZOTools_LAM.RequestSettingsRefresh()
            end
        end,
        default = false,
    }

    return opciones
end

function MENU.Init()
    local LAM = LibAddonMenu2
    if not LAM then return end

    AsegurarDefectos()

    local panelData = {
        type              = "panel",
        name              = ADDON_NAME,
        displayName       = DISPLAY_NAME,
        author            = "@Zuriplayer",
        version           = EZOTools.ADDON_VERSION,
        ezoStage          = "beta",
        -- LAM muestra un icono en la cabecera del panel que abre esta URL
        -- con el diálogo oficial del juego.
        feedback          = EZOTools.CONTACT_DISCORD,
        registerForRefresh  = true,
        registerForDefaults = true,
    }

    if EZOCore and type(EZOCore.RegisterSettingsPanel) == "function" then
        local registered = EZOCore:RegisterSettingsPanel(ADDON_NAME, PANEL_ID, panelData, ConstruirOpciones)
        if registered then
            EZOTools.ezoSettingsRegistered = true
            return
        end
    end

    local options = ConstruirOpciones()
    local panel = LAM:RegisterAddonPanel(PANEL_ID, panelData)
    -- Guardamos la referencia al panel para poder abrirlo programáticamente
    EZOTools._lamPanel  = panel
    _G.EZOTools_Panel   = panel

    LAM:RegisterOptionControls(PANEL_ID, options)
end

function MENU.Open()
    if EZOTools.ezoSettingsRegistered
        and EZOCore
        and type(EZOCore.OpenSettingsPanel) == "function"
        and type(EZOCore.OpenSettings) == "function"
        and EZOCore:OpenSettingsPanel(ADDON_NAME)
    then
        return EZOCore.OpenSettings()
    end

    local LAM = LibAddonMenu2
    if not (LAM and type(LAM.OpenToPanel) == "function") then
        return false
    end

    LAM:OpenToPanel(EZOTools._lamPanel or _G.EZOTools_Panel or PANEL_ID)
    return true
end
