-- Módulo de panel de opciones LAM de EZOTools.
-- Construye el panel principal de LibAddonMenu unificando las secciones registradas
-- por los demás módulos más los sliders de mantenimiento propios.

EZOTools_Menu = EZOTools_Menu or {}
local MENU = EZOTools_Menu

local ADDON_NAME   = "EZOTools"
local DISPLAY_NAME = "E|cB040FFZ|rOTools"
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
    opciones[#opciones + 1] = { type = "header", name = GetString(EZO_OPTION_MAINTENANCE) }

    opciones[#opciones + 1] = {
        type    = "slider",
        name    = GetString(EZO_OPTION_REPAIR_THRESHOLD),
        tooltip = GetString(EZO_OPTION_REPAIR_THRESHOLD_TOOLTIP),
        min     = 1, max = 100, step = 1,
        getFunc = function() return tonumber(EZOTools.sv.general.repairThreshold) or 40 end,
        setFunc = function(v)
            EZOTools.sv.general.repairThreshold = tonumber(v)
            if EZOTools_Overlay and EZOTools_Overlay.RefreshDot then EZOTools_Overlay.RefreshDot() end
        end,
        default = 40,
    }

    opciones[#opciones + 1] = {
        type    = "slider",
        name    = GetString(EZO_OPTION_RECHARGE_THRESHOLD),
        tooltip = GetString(EZO_OPTION_RECHARGE_THRESHOLD_TOOLTIP),
        min     = 1, max = 100, step = 1,
        getFunc = function() return tonumber(EZOTools.sv.general.rechargeThreshold) or 50 end,
        setFunc = function(v)
            EZOTools.sv.general.rechargeThreshold = tonumber(v)
            if EZOTools_Overlay and EZOTools_Overlay.RefreshDot then EZOTools_Overlay.RefreshDot() end
        end,
        default = 50,
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
        registerForRefresh  = true,
        registerForDefaults = true,
    }

    local panel = LAM:RegisterAddonPanel("EZOTools_Panel", panelData)
    -- Guardamos la referencia al panel para poder abrirlo programáticamente
    EZOTools._lamPanel  = panel
    _G.EZOTools_Panel   = panel

    LAM:RegisterOptionControls("EZOTools_Panel", ConstruirOpciones())
end
