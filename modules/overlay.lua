-- Módulo de overlay visual de EZOTools.
-- Gestiona la ventana flotante (logo + texto) que sirve como punto de acceso al menú.
-- El aviso de "Tabardo de Hermandad" ha sido eliminado (obsoleto desde Update 49:
-- el juego permite mostrar el escudo de hermandad sin llevar tabardo equipado,
-- por lo que la detección por BAG_WORN ya no es fiable).

EZOTools_Overlay = EZOTools_Overlay or {}
local MOD = EZOTools_Overlay
local EZO = EZOTools

-- Controles de la ventana (se crean en EnsureControls la primera vez)
local overlayWin, overlayTex, overlayLabel, overlayGuildLabel, overlayMaintDot, overlayChargeDot, overlayFoodDot, overlayPetDot, overlayCompanionDot, overlayAssistantDot
local overlaySideSlotsLeft, overlaySideSlotsRight = {}, {}
local overlaySideWidgetsLeft, overlaySideWidgetsRight = {}, {}
local overlaySideWidgetTexturesLeft, overlaySideWidgetTexturesRight = {}, {}
local overlaySideWidgetData = { left = {}, right = {} }
local overlaySideWidgetRegistry = { left = {}, right = {} }
local overlayLayoutPreviewEnabled = false
local overlayWidgetTooltipWin, overlayWidgetTooltipBackdrop, overlayWidgetTooltipLabel
local overlayAllyTooltipActive = false
local overlaySideWidgetTooltipActive = false
local overlayFoodDebugState = nil
local overlayFoodPulseLastRefreshMs = 0
local overlayAllyTooltipLastRefreshMs = 0
local overlayFoodPulseState = nil
local overlayFoodConfirmDialogRegistered = false
local overlayFoodBackpackCache = {}
local overlayFoodPendingItem = nil
local ObtenerInfoBuffComida
local ConstruirTooltipComida
local BuscarConsumibleRecordadoComida
local BuscarConsumibleComidaPorReferencia
local AbrirMenuHistorialAliado
local TOOLTIP_ICON_WIDTH = 360
local TOOLTIP_ICON_HEIGHT = 120
local FOOD_PENDING_WINDOW_MS = 4000

local DEFAULT_OVERLAY_TEXTURES = {
    "/AddOns/EZOTools/media/ezotools_logo.dds",
    "/AddOns/EZOTools/Media/ezotools_logo.dds",
    "EZOTools/media/ezotools_logo.dds",
    "EZOTools/Media/ezotools_logo.dds",
}

local GUILD_OVERLAY_TEXTURES = {
    ["children of lamae"] = {
        "/AddOns/EZOTools/media/guild_overlays/children_of_lamae.dds",
        "EZOTools/media/guild_overlays/children_of_lamae.dds",
    },
    ["fuego"] = {
        "/AddOns/EZOTools/media/guild_overlays/fuego.dds",
        "EZOTools/media/guild_overlays/fuego.dds",
    },
    ["hojablanca"] = {
        "/AddOns/EZOTools/media/guild_overlays/hojablanca.dds",
        "EZOTools/media/guild_overlays/hojablanca.dds",
    },
    ["liga latina"] = {
        "/AddOns/EZOTools/media/guild_overlays/liga_latina.dds",
        "EZOTools/media/guild_overlays/liga_latina.dds",
    },
    ["ad-minions"] = {
        "/AddOns/EZOTools/media/guild_overlays/minion.dds",
        "EZOTools/media/guild_overlays/minion.dds",
    },
    ["sombras de lorkhan"] = {
        "/AddOns/EZOTools/media/guild_overlays/sombra.dds",
        "EZOTools/media/guild_overlays/sombra.dds",
    },
}

-- Estado de combate (se actualiza vía evento)
local enCombate = false

-- Caché del guildId representado para detectar cambios sin evento dedicado.
-- ZOS no expone un evento para SetRepresentedGuildId(), así que usamos poll.
local cachedRepresentedGuildId = nil


-- Slots laterales preparados para futuras alertas/estados. Se calculan contra un radio
-- seguro del logo en vez de depender de la transparencia exacta del DDS.
local SIDE_SLOT_COUNT    = 4
local SIDE_SLOT_BASE     = 22
local SIDE_SLOT_MIN      = 18
local SIDE_SLOT_GAP      = 6
local SIDE_SLOT_MARGIN   = 12
local SIDE_SLOT_RADIUS_X = 0.50
local SIDE_SLOT_RADIUS_Y = 0.78
local SIDE_SLOT_Y        = { -0.50, -0.16, 0.16, 0.50 }
local SIDE_WIDGET_ASSIGNMENTS = {
    foodBuff        = { side = "right", index = 1 },
    repairEquipped  = { side = "left", index = 1 },
    repairKits      = { side = "left", index = 2 },
    rechargeWeapons = { side = "left", index = 3 },
    soulGems        = { side = "left", index = 4 },
}
-- Tamaños base para calcular escala
local BASE_TEX         = 128   -- píxeles base de la textura del logo
local BASE_FONT_PC     = 20    -- tamaño de fuente base en modo teclado/ratón
local BASE_FONT_GP     = 32    -- tamaño de fuente base en modo gamepad
local GUILD_FONT_RATIO = 0.75  -- la fuente de guild es el 75% del tamaño del nombre del jugador
local PLAYER_TEXT_SCALE_MIN = 0.6
local PLAYER_TEXT_SCALE_MAX = 1.0
local ALLY_ICON_INACTIVE_ALPHA = 0.45
local ALLY_ICON_BASE_SIZE = 30
local ALLY_ICON_SCALE_WEIGHT_DOWN = 0.22
local ALLY_ICON_SCALE_WEIGHT_UP = 0.60
local ALLY_SWITCH_INITIAL_DELAY_MS = 1500
local ALLY_SWITCH_RETRY_DELAY_MS = 500
local ALLY_SWITCH_MAX_RETRIES = 6
local allySwitchPending = false
local OVERLAY_TOP_PADDING = 4
local OVERLAY_ROW_GAP_SMALL = 4
local OVERLAY_ROW_GAP_NORMAL = 6
local OVERLAY_BOTTOM_PADDING = 18
local FOOD_ALERT_SECONDS = 15 * 60
local FOOD_PULSE_REFRESH_MS = 120
local ALLY_TOOLTIP_REFRESH_MS = 80

local TieneAsistenteActivo
local OcultarMascotaActiva
local OcultarCompanionActivo
local OcultarAsistenteActivo
local ObtenerMascotaActivaId
local ObtenerAssistantActivoId
local ObtenerCompanionActivoCollectibleId
local ObtenerTooltipIconoAliado
local InvocarMascotaRecordada
local InvocarCompanionRecordado
local InvocarAsistenteRecordada
local RefrescarDot
local ProgramarRefrescoDots

-- Genera la cadena de fuente ESO a partir de un tamaño en píxeles
local function CadenaFuente(px)
    px = math.max(10, math.floor(px))
    return string.format("$(BOLD_FONT)|%d|soft-shadow-thin", px)
end

local function ObtenerColorOverlay(configValue, fallback)
    if type(configValue) == "table" then
        local r = tonumber(configValue[1])
        local g = tonumber(configValue[2])
        local b = tonumber(configValue[3])
        local a = tonumber(configValue[4])
        if r and g and b then
            return r, g, b, a or 1
        end
    end
    return fallback[1], fallback[2], fallback[3], fallback[4]
end

local function EstanActivosLosTooltipsContextuales()
    return not (EZO and EZO.sv and EZO.sv.overlay and EZO.sv.overlay.contextualIconTooltips == false)
end

-- Devuelve true si la escena actual es el HUD (en juego, sin menús)
local function EsEscenaHUD()
    return SCENE_MANAGER:IsShowing("hud") or SCENE_MANAGER:IsShowing("hudui")
end

-- Devuelve la ventana del overlay (o GuiRoot si no existe) para anclar otros controles
function MOD.GetAnchor()
    return overlayWin or GuiRoot
end

-- Aplica la posición guardada (o centra si no hay posición guardada)
local function AplicarPosicion()
    if not overlayWin then return end
    overlayWin:ClearAnchors()
    if EZO.sv.overlay.x and EZO.sv.overlay.y then
        overlayWin:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, EZO.sv.overlay.x, EZO.sv.overlay.y)
    else
        overlayWin:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    end
end

-- Aplica el estado de bloqueo/movimiento del overlay.
-- IMPORTANTE: aunque esté bloqueado, mantenemos el ratón activo en el HUD
-- para que el clic derecho pueda abrir el menú contextual.
local function AplicarEstadoBloqueo()
    if not overlayWin then return end
    local bloqueado = EZO.sv.overlay.locked
    local enHUD     = EsEscenaHUD()
    overlayWin:SetMovable(enHUD and not bloqueado)
    overlayWin:SetMouseEnabled(enHUD)
end

-- Actualiza la etiqueta de guild en el overlay con el valor actual de GetRepresentedGuildId().
-- Se llama desde Refresh() y desde el poll periódico.
-- Devuelve el nombre de la guild representada actualmente, o nil si no hay ninguna.
-- Devuelve el nombre de la guild del tabardo equipado, o nil si no hay tabardo.
-- Prioridad 1: si el jugador lleva tabardo equipado, mostramos la guild del tabardo.
local function ObtenerGuildTabardo()
    -- IsPlayerWearingGuildTabard() es la API más directa (API 101049)
    if type(IsPlayerWearingGuildTabard) == "function" then
        if not IsPlayerWearingGuildTabard() then return nil end
    end
    -- Verificar la ranura de tabardo en BAG_WORN para obtener el guildId asociado
    local SLOT_TABARD = EQUIP_SLOT_TABARD or 10
    if type(GetItemType) == "function" then
        local itemType = GetItemType(BAG_WORN, SLOT_TABARD)
        if itemType ~= ITEMTYPE_TABARD then return nil end
    end
    -- Obtener el nombre de la guild a través del link del item
    if type(GetItemLink) == "function" and type(GetItemLinkGuildName) == "function" then
        local link = GetItemLink(BAG_WORN, SLOT_TABARD, LINK_STYLE_DEFAULT)
        if link and link ~= "" then
            local guildName = GetItemLinkGuildName(link)
            if guildName and guildName ~= "" then return guildName end
        end
    end
    -- Fallback: buscar en las guilds del jugador cuál tiene tabardo equipado
    -- usando IsPlayerWearingGuildTabard + iteración de guilds
    if type(GetNumGuilds) == "function" and type(GetGuildId) == "function" then
        local numGuilds = GetNumGuilds()
        for i = 1, numGuilds do
            local guildId = GetGuildId(i)
            -- No hay API directa para saber qué guild es el tabardo equipado
            -- IsPlayerWearingGuildTabard() solo devuelve bool, sin guildId
            -- Si llegamos aquí, confirmamos que hay tabardo pero no podemos
            -- obtener el nombre de la guild — devolvemos indicador genérico
        end
    end
    return "" -- tabardo equipado pero guild desconocida (fallback)
end

-- Devuelve el nombre de la guild del selector C (Guild Nameplate, U49), o nil.
-- GetRepresentedGuildId() es la API oficial que corresponde al selector Guild Nameplate.
local function ObtenerGuildRepresentada()
    if type(GetRepresentedGuildId) ~= "function" then return nil end
    local guildId = GetRepresentedGuildId()
    if not guildId or guildId == 0 then return nil end
    if type(GetGuildName) ~= "function" then return nil end
    return GetGuildName(guildId)
end

local function NormalizarClaveGuild(nombre)
    if type(nombre) ~= "string" then return nil end
    nombre = zo_strtrim(nombre)
    if nombre == "" then return nil end
    nombre = zo_strlower(nombre)
    nombre = nombre:gsub("%s+", " ")
    return nombre
end

local function ObtenerRutasLogoGuildRepresentada()
    if not (EZO.sv and EZO.sv.overlay and EZO.sv.overlay.guildCustomImageEnabled == true) then
        return nil
    end
    if ObtenerGuildTabardo() ~= nil then
        return nil
    end
    local nombreGuild = ObtenerGuildRepresentada()
    local claveGuild = NormalizarClaveGuild(nombreGuild)
    if not claveGuild then return nil end
    return GUILD_OVERLAY_TEXTURES[claveGuild]
end

local function AplicarTexturaConFallback(ctrl, rutasPreferidas, rutasFallback)
    if not ctrl then return false end

    local function IntentarRutas(rutas)
        if type(rutas) ~= "table" then return false end
        local ultimaRuta = nil
        for _, ruta in ipairs(rutas) do
            ultimaRuta = ruta
            ctrl:SetTexture(ruta)
            if ctrl:IsTextureLoaded() then
                return true
            end
        end
        if ultimaRuta then
            -- Algunas texturas del addon tardan en confirmar carga al cambiar
            -- en caliente. Dejamos la última ruta preferida aplicada para que
            -- el siguiente refresco pueda verla ya cargada.
            ctrl:SetTexture(ultimaRuta)
            return true
        end
        return false
    end

    if IntentarRutas(rutasPreferidas) then
        return true
    end

    return IntentarRutas(rutasFallback)
end

local function RefrescarTexturaLogoCentral()
    if not overlayTex then return end
    AplicarTexturaConFallback(overlayTex, ObtenerRutasLogoGuildRepresentada(), DEFAULT_OVERLAY_TEXTURES)
end

-- Actualiza la etiqueta de guild en el overlay.
-- Lógica de prioridad:
--   1. Tabardo equipado → nombre de la guild del tabardo (amarillo discreto)
--   2. Guild representada en selector C → nombre en gris discreto
--   3. Ninguna → "Sin hermandad" / "No guild" en rojo
local function RefrescarEtiquetaGuild()
    if not overlayGuildLabel then return end
    RefrescarTexturaLogoCentral()

    -- Prioridad 1: tabardo equipado
    local nombreTabardo = ObtenerGuildTabardo()
    if nombreTabardo ~= nil then
        -- Hay tabardo equipado
        if nombreTabardo ~= "" then
            overlayGuildLabel:SetText(nombreTabardo)
        else
            -- Tabardo equipado pero guild no identificable — mostramos indicador
            overlayGuildLabel:SetText(GetString(EZO_OVERLAY_TABARD))
        end
        overlayGuildLabel:SetColor(0.9, 0.8, 0.4, 1)  -- amarillo suave (tabardo)
        return
    end

    -- Prioridad 2: guild representada (selector C, Guild Nameplate U49)
    local nombreGuild = ObtenerGuildRepresentada()
    if nombreGuild then
        overlayGuildLabel:SetText(nombreGuild)
        local r, g, b, a = ObtenerColorOverlay(
            EZO.sv and EZO.sv.overlay and EZO.sv.overlay.guildLabelColor,
            { 0.7, 0.7, 0.7, 1 }
        )
        overlayGuildLabel:SetColor(r, g, b, a)
        return
    end

    -- Sin guild de ningún tipo
    overlayGuildLabel:SetText(GetString(EZO_OVERLAY_NO_GUILD))
    overlayGuildLabel:SetColor(1, 0.2, 0.2, 1)  -- rojo de advertencia
end

-- Devuelve el texto a mostrar en el overlay (usa el string localizado si está vacío)
local function ObtenerTextoOverlay()
    local t = EZO.sv and EZO.sv.overlay and EZO.sv.overlay.text
    -- Si el texto está vacío, usar el nombre de cuenta del jugador como fallback
    if t == nil or (type(t) == "string" and t:match("^%s*$")) then
        return GetDisplayName() or GetString(EZO_MSG_INIT)
    end
    return tostring(t)
end

local function ObtenerSlotsLaterales(side)
    return (side == "left") and overlaySideSlotsLeft or overlaySideSlotsRight
end

local function ObtenerWidgetsLaterales(side)
    return (side == "left") and overlaySideWidgetsLeft or overlaySideWidgetsRight
end

local function ObtenerTexturasWidgetLaterales(side)
    return (side == "left") and overlaySideWidgetTexturesLeft or overlaySideWidgetTexturesRight
end

local function ObtenerDatosWidgetLaterales(side)
    return overlaySideWidgetData[side]
end

local function ObtenerNombreLadoWidget(side)
    if side == "left" then
        return GetString(EZO_SIDE_WIDGET_LEFT)
    end
    return GetString(EZO_SIDE_WIDGET_RIGHT)
end

local function OcultarTooltipWidget()
    if type(ClearTooltip) == "function" and InformationTooltip then
        ClearTooltip(InformationTooltip)
    end
    if overlayWidgetTooltipWin then
        overlayWidgetTooltipWin:SetHidden(true)
    end
    overlayAllyTooltipActive = false
    overlaySideWidgetTooltipActive = false
end

local function AsegurarTooltipWidget()
    if overlayWidgetTooltipWin then return end

    overlayWidgetTooltipWin = WINDOW_MANAGER:CreateTopLevelWindow("EZOToolsOverlayWidgetTooltip")
    overlayWidgetTooltipWin:SetDimensions(TOOLTIP_ICON_WIDTH, TOOLTIP_ICON_HEIGHT)
    overlayWidgetTooltipWin:SetMouseEnabled(false)
    overlayWidgetTooltipWin:SetMovable(false)
    overlayWidgetTooltipWin:SetClampedToScreen(true)
    overlayWidgetTooltipWin:SetDrawLayer(DL_OVERLAY)
    overlayWidgetTooltipWin:SetDrawTier(DT_HIGH)
    overlayWidgetTooltipWin:SetHidden(true)

    overlayWidgetTooltipBackdrop = WINDOW_MANAGER:CreateControl("$(parent)Backdrop", overlayWidgetTooltipWin, CT_BACKDROP)
    overlayWidgetTooltipBackdrop:SetAnchorFill()
    overlayWidgetTooltipBackdrop:SetCenterColor(0.04, 0.04, 0.04, 0.92)
    overlayWidgetTooltipBackdrop:SetEdgeColor(0.85, 0.78, 0.42, 0.95)
    overlayWidgetTooltipBackdrop:SetEdgeTexture(nil, 1, 1, 2)
    overlayWidgetTooltipBackdrop:SetInsets(0, 0, 0, 0)

    overlayWidgetTooltipLabel = WINDOW_MANAGER:CreateControl("$(parent)Label", overlayWidgetTooltipWin, CT_LABEL)
    overlayWidgetTooltipLabel:SetAnchor(TOPLEFT, overlayWidgetTooltipWin, TOPLEFT, 10, 8)
    overlayWidgetTooltipLabel:SetDimensions(TOOLTIP_ICON_WIDTH - 20, TOOLTIP_ICON_HEIGHT - 16)
    overlayWidgetTooltipLabel:SetFont(CadenaFuente(16))
    overlayWidgetTooltipLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    overlayWidgetTooltipLabel:SetVerticalAlignment(TEXT_ALIGN_TOP)
    overlayWidgetTooltipLabel:SetColor(1, 1, 1, 1)
end

local function AplicarTamanoFijoTooltipIconos()
    if not (overlayWidgetTooltipWin and overlayWidgetTooltipLabel) then return end
    overlayWidgetTooltipWin:SetDimensions(TOOLTIP_ICON_WIDTH, TOOLTIP_ICON_HEIGHT)
    overlayWidgetTooltipLabel:SetDimensions(TOOLTIP_ICON_WIDTH - 20, TOOLTIP_ICON_HEIGHT - 16)
end

local function ConstruirTooltipPreviewWidget(side, index)
    for key, slotInfo in pairs(SIDE_WIDGET_ASSIGNMENTS) do
        if slotInfo and slotInfo.side == side and slotInfo.index == index then
            if key == "foodBuff" then
                return GetString(EZO_SIDE_WIDGET_FOOD_PREVIEW_TOOLTIP)
            end
            if key == "repairEquipped" then
                return GetString(EZO_SIDE_WIDGET_REPAIR_EQUIPPED_PREVIEW_TOOLTIP)
            end
            if key == "repairKits" then
                return GetString(EZO_SIDE_WIDGET_REPAIR_KITS_PREVIEW_TOOLTIP)
            end
            if key == "rechargeWeapons" then
                return GetString(EZO_SIDE_WIDGET_RECHARGE_WEAPONS_PREVIEW_TOOLTIP)
            end
            if key == "soulGems" then
                return GetString(EZO_SIDE_WIDGET_SOUL_GEMS_PREVIEW_TOOLTIP)
            end
        end
    end

    return zo_strformat(
        GetString(EZO_SIDE_WIDGET_PREVIEW_TOOLTIP),
        ObtenerNombreLadoWidget(side),
        tostring(index))
end

local function FormatearTiempoRestanteCorto(segundos)
    segundos = math.max(0, math.floor(tonumber(segundos) or 0))
    local horas = math.floor(segundos / 3600)
    local minutos = math.floor((segundos % 3600) / 60)
    local secs = segundos % 60
    if horas > 0 then
        return zo_strformat(GetString(EZO_TIME_REMAINING_HM), tostring(horas), tostring(minutos))
    end
    if minutos > 0 then
        return zo_strformat(GetString(EZO_TIME_REMAINING_MS), tostring(minutos), tostring(secs))
    end
    return zo_strformat(GetString(EZO_TIME_REMAINING_S), tostring(secs))
end

local function CalcularPulsoAlfa(periodoSeg, minAlpha, maxAlpha)
    if type(GetFrameTimeSeconds) ~= "function" then
        return maxAlpha
    end
    local periodo = math.max(0.1, tonumber(periodoSeg) or 1)
    local minimo = tonumber(minAlpha) or 0.6
    local maximo = tonumber(maxAlpha) or 1.0
    local fase = (GetFrameTimeSeconds() % periodo) / periodo
    local onda = (math.sin(fase * math.pi * 2 - math.pi / 2) + 1) * 0.5
    return minimo + (maximo - minimo) * onda
end

local function ObtenerEstadoVisualComida(foodInfo)
    local estado = {
        color = { 1.0, 0.30, 0.30, 0.95 },
        alpha = 1,
        tooltip = GetString(EZO_SIDE_WIDGET_FOOD_NONE_TOOLTIP),
        pulse = nil,
    }

    if not (type(foodInfo) == "table" and foodInfo.active) then
        estado.alpha = CalcularPulsoAlfa(0.85, 0.35, 1.0)
        estado.pulse = {
            color = estado.color,
            period = 0.85,
            minAlpha = 0.35,
            maxAlpha = 1.0,
        }
        return estado
    end

    local remainingSeconds = tonumber(foodInfo.remainingSeconds)
    if remainingSeconds ~= nil then
        if remainingSeconds > FOOD_ALERT_SECONDS then
            estado.color = { 0.35, 0.85, 0.35, 0.95 }
            estado.alpha = 1
        else
            estado.color = { 1.0, 0.62, 0.10, 1.0 }
            estado.alpha = CalcularPulsoAlfa(0.7, 0.45, 1.0)
            estado.pulse = {
                color = estado.color,
                period = 0.7,
                minAlpha = 0.45,
                maxAlpha = 1.0,
            }
        end
        estado.tooltip = zo_strformat(
            GetString(EZO_SIDE_WIDGET_FOOD_ACTIVE_TOOLTIP),
            tostring(foodInfo.name or ""),
            FormatearTiempoRestanteCorto(remainingSeconds)
        )
        return estado
    end

    estado.color = { 0.35, 0.85, 0.35, 0.95 }
    estado.alpha = 1
    estado.tooltip = zo_strformat(
        GetString(EZO_SIDE_WIDGET_FOOD_ACTIVE_NO_TIME_TOOLTIP),
        tostring(foodInfo.name or "")
    )
    return estado
end

local function NecesitaPulsoComida()
    return type(overlayFoodPulseState) == "table"
end

local function CalcularSegundosRestantesBuff(endTime)
    if type(endTime) ~= "number" then return nil end
    local candidatos = {}
    local maxRazonable = 7 * 24 * 60 * 60

    if type(GetFrameTimeSeconds) == "function" then
        local diff = endTime - GetFrameTimeSeconds()
        if diff >= 0 and diff <= maxRazonable then
            table.insert(candidatos, diff)
        end
    end
    if type(GetFrameTimeMilliseconds) == "function" then
        local diff = (endTime - GetFrameTimeMilliseconds()) / 1000
        if diff >= 0 and diff <= maxRazonable then
            table.insert(candidatos, diff)
        end
    end
    if type(GetGameTimeMilliseconds) == "function" then
        local diff = (endTime - GetGameTimeMilliseconds()) / 1000
        if diff >= 0 and diff <= maxRazonable then
            table.insert(candidatos, diff)
        end
    end

    if #candidatos == 0 then return nil end
    table.sort(candidatos, function(a, b) return a < b end)
    return candidatos[1]
end

ObtenerInfoBuffComida = function()
    if overlayFoodDebugState == "green" then
        return {
            active = true,
            name = GetString(EZO_DEBUG_FOOD_NAME),
            remainingSeconds = 20 * 60,
        }
    end
    if overlayFoodDebugState == "yellow" then
        return {
            active = true,
            name = GetString(EZO_DEBUG_FOOD_NAME),
            remainingSeconds = 4 * 60 + 30,
        }
    end
    if overlayFoodDebugState == "red" then
        return { active = false }
    end

    if type(GetNumBuffs) ~= "function" or type(GetUnitBuffInfo) ~= "function" then
        return { active = false }
    end

    local num = GetNumBuffs("player")
    local mejor = nil
    for i = 1, num do
        local buffName, _, endTime, _, _, _, _, _, _, _, _, canClickOff = GetUnitBuffInfo("player", i)
        if endTime and endTime > 0 and canClickOff == true then
            local candidato = {
                active = true,
                name = buffName,
                remainingSeconds = CalcularSegundosRestantesBuff(endTime),
            }
            if not mejor then
                mejor = candidato
            elseif type(candidato.remainingSeconds) == "number" and type(mejor.remainingSeconds) == "number" and candidato.remainingSeconds > mejor.remainingSeconds then
                mejor = candidato
            elseif mejor.remainingSeconds == nil and candidato.remainingSeconds ~= nil then
                mejor = candidato
            end
        end
    end

    return mejor or { active = false }
end

local function ObtenerTooltipWidget(side, index, data)
    if not EstanActivosLosTooltipsContextuales() then
        return nil
    end
    if type(data) ~= "table" then
        if overlayLayoutPreviewEnabled then
            local foodSlot = SIDE_WIDGET_ASSIGNMENTS.foodBuff
            if foodSlot and foodSlot.side == side and foodSlot.index == index and type(ConstruirTooltipComida) == "function" then
                local foodInfo = ObtenerInfoBuffComida()
                local foodRecordadoBag, _, foodRecordadoNombre, _, foodRecordadoQuality = BuscarConsumibleRecordadoComida()
                local foodRecordadoDisponible = foodRecordadoBag ~= nil
                local foodLegendaria = type(ITEM_QUALITY_LEGENDARY) == "number" and foodRecordadoQuality == ITEM_QUALITY_LEGENDARY
                return ConstruirTooltipComida(foodInfo, foodRecordadoNombre, foodRecordadoDisponible, foodLegendaria)
            end
            return ConstruirTooltipPreviewWidget(side, index)
        end
        return nil
    end
    if type(data.tooltipText) == "string" and data.tooltipText ~= "" then
        return data.tooltipText
    end
    if type(data.tooltipStringId) == "number" then
        local baseText = GetString(data.tooltipStringId)
        if type(data.tooltipArgs) == "table" and #data.tooltipArgs > 0 then
            return zo_strformat(baseText, unpack(data.tooltipArgs))
        end
        return baseText
    end
    if overlayLayoutPreviewEnabled then
        return ConstruirTooltipPreviewWidget(side, index)
    end
    return nil
end

local function NormalizarTextoTooltip(texto)
    if type(texto) ~= "string" then
        return texto
    end
    return texto:gsub("|n", "\n")
end

local function MostrarTooltipWidget(ctrl, side, index, data)
    local texto = ObtenerTooltipWidget(side, index, data)
    if not texto or texto == "" then
        OcultarTooltipWidget()
        return
    end

    if type(InitializeTooltip) == "function" and type(SetTooltipText) == "function" and InformationTooltip then
        if side == "left" then
            InitializeTooltip(InformationTooltip, ctrl, RIGHT, -8, -4)
        else
            InitializeTooltip(InformationTooltip, ctrl, LEFT, 8, -4)
        end
        SetTooltipText(InformationTooltip, NormalizarTextoTooltip(texto))
        overlaySideWidgetTooltipActive = true
        return
    end

    AsegurarTooltipWidget()
    AplicarTamanoFijoTooltipIconos()
    overlayWidgetTooltipLabel:SetText(NormalizarTextoTooltip(texto))
    overlayWidgetTooltipWin:ClearAnchors()
    if side == "left" then
        overlayWidgetTooltipWin:SetAnchor(TOPRIGHT, ctrl, TOPLEFT, -8, -4)
    else
        overlayWidgetTooltipWin:SetAnchor(TOPLEFT, ctrl, TOPRIGHT, 8, -4)
    end
    overlayWidgetTooltipWin:SetHidden(false)
    overlaySideWidgetTooltipActive = true
end

local function MostrarTooltipTextoSobreControl(ctrl, texto)
    if not EstanActivosLosTooltipsContextuales() then
        OcultarTooltipWidget()
        return
    end
    if not ctrl or type(texto) ~= "string" or texto == "" then
        OcultarTooltipWidget()
        return
    end

    if type(InitializeTooltip) == "function" and type(SetTooltipText) == "function" and InformationTooltip then
        InitializeTooltip(InformationTooltip, ctrl, BOTTOM, 0, -8, TOP)
        SetTooltipText(InformationTooltip, NormalizarTextoTooltip(texto))
        overlayAllyTooltipActive = true
        overlaySideWidgetTooltipActive = false
        return
    end

    AsegurarTooltipWidget()
    AplicarTamanoFijoTooltipIconos()
    overlayWidgetTooltipLabel:SetText(NormalizarTextoTooltip(texto))
    overlayWidgetTooltipWin:ClearAnchors()
    overlayWidgetTooltipWin:SetAnchor(BOTTOM, ctrl, TOP, 0, -8)
    overlayWidgetTooltipWin:SetHidden(false)
    overlayAllyTooltipActive = true
    overlaySideWidgetTooltipActive = false
end

local function ObtenerNombreCollectible(collectibleId, fallback)
    if collectibleId and collectibleId ~= 0 and type(GetCollectibleName) == "function" then
        local nombre = GetCollectibleName(collectibleId)
        if type(nombre) == "string" and nombre ~= "" then
            return nombre
        end
    end
    return fallback
end

local function ObtenerDescripcionCollectible(collectibleId)
    if collectibleId and collectibleId ~= 0 and type(GetCollectibleDescription) == "function" then
        local descripcion = GetCollectibleDescription(collectibleId)
        if type(descripcion) == "string" and descripcion ~= "" then
            return descripcion
        end
    end
    return nil
end

local function EsConsumibleDeComidaOBebida(bagId, slotIndex)
    if type(GetItemType) ~= "function" then return false end
    local itemType = GetItemType(bagId, slotIndex)
    if itemType ~= ITEMTYPE_FOOD and itemType ~= ITEMTYPE_DRINK then
        return false
    end
    if type(IsItemUsable) == "function" and not IsItemUsable(bagId, slotIndex) then
        return false
    end
    return true
end

local function ObtenerNombreItem(bagId, slotIndex, itemLink)
    if type(GetItemLinkName) == "function" and type(itemLink) == "string" and itemLink ~= "" then
        local nombreLink = GetItemLinkName(itemLink)
        if type(nombreLink) == "string" and nombreLink ~= "" then
            return nombreLink
        end
    end
    if type(GetItemName) == "function" then
        local nombreItem = GetItemName(bagId, slotIndex)
        if type(nombreItem) == "string" and nombreItem ~= "" then
            return nombreItem
        end
    end
    return nil
end

local function GuardarComidaRecordada(itemLink, itemName)
    if not (EZO and EZO.sv and EZO.sv.overlay) then return end
    EZO.sv.overlay.lastFoodItemLink = tostring(itemLink or "")
    EZO.sv.overlay.lastFoodItemName = tostring(itemName or "")
end

local function ObtenerMomentoActualMs()
    if type(GetGameTimeMilliseconds) == "function" then
        return GetGameTimeMilliseconds()
    end
    if type(GetFrameTimeMilliseconds) == "function" then
        return GetFrameTimeMilliseconds()
    end
    return nil
end

local function GuardarComidaEnHistorial(itemLink, itemName)
    if not (EZO and EZO.sv and EZO.sv.overlay) then return end
    local link = tostring(itemLink or "")
    local name = tostring(itemName or "")
    if link == "" and name == "" then
        return
    end

    local history = EZO.sv.overlay.recentFoodItems
    if type(history) ~= "table" then
        history = {}
        EZO.sv.overlay.recentFoodItems = history
    end

    local newHistory = {
        {
            itemLink = link,
            itemName = name,
        }
    }

    for _, entry in ipairs(history) do
        if type(entry) == "table" then
            local entryLink = tostring(entry.itemLink or "")
            local entryName = tostring(entry.itemName or "")
            local sameLink = (link ~= "" and entryLink == link)
            local sameName = (link == "" and name ~= "" and entryName == name)
            if not sameLink and not sameName then
                newHistory[#newHistory + 1] = {
                    itemLink = entryLink,
                    itemName = entryName,
                }
            end
        end
        if #newHistory >= 5 then
            break
        end
    end

    EZO.sv.overlay.recentFoodItems = newHistory
end

local function ObtenerDescripcionUsoItem(itemLink)
    if type(GetItemLinkOnUseAbilityInfo) ~= "function" then
        return nil
    end
    local hasAbility, abilityHeader, abilityDescription = GetItemLinkOnUseAbilityInfo(itemLink)
    if not hasAbility then
        return nil
    end
    if type(abilityDescription) == "string" and abilityDescription ~= "" then
        return abilityDescription
    end
    if type(abilityHeader) == "string" and abilityHeader ~= "" then
        return abilityHeader
    end
    return nil
end

local function ObtenerCabeceraUsoItem(itemLink)
    if type(GetItemLinkOnUseAbilityInfo) ~= "function" then
        return nil
    end
    local hasAbility, abilityHeader = GetItemLinkOnUseAbilityInfo(itemLink)
    if not hasAbility then
        return nil
    end
    if type(abilityHeader) == "string" and abilityHeader ~= "" then
        return abilityHeader
    end
    return nil
end

local function LeerEstadoConsumibleComidaMochila(slotIndex)
    if type(slotIndex) ~= "number" then
        return nil
    end
    if not EsConsumibleDeComidaOBebida(BAG_BACKPACK, slotIndex) then
        return nil
    end

    local itemLink = ""
    if type(GetItemLink) == "function" then
        itemLink = tostring(GetItemLink(BAG_BACKPACK, slotIndex, LINK_STYLE_DEFAULT) or "")
    end
    local itemName = ObtenerNombreItem(BAG_BACKPACK, slotIndex, itemLink)
    local stackSize = 0
    if type(GetSlotStackSize) == "function" then
        local currentStackSize = GetSlotStackSize(BAG_BACKPACK, slotIndex)
        stackSize = tonumber(currentStackSize) or 0
    end

    return {
        itemLink = itemLink,
        itemName = tostring(itemName or ""),
        stackSize = stackSize,
    }
end

local function ActualizarCacheConsumibleComidaMochila(slotIndex)
    if type(slotIndex) ~= "number" then
        return
    end
    overlayFoodBackpackCache[slotIndex] = LeerEstadoConsumibleComidaMochila(slotIndex)
end

local function SincronizarCacheConsumiblesComidaMochila()
    overlayFoodBackpackCache = {}
    if type(GetBagSize) ~= "function" then
        return
    end
    local bagSize = GetBagSize(BAG_BACKPACK)
    if type(bagSize) ~= "number" or bagSize <= 0 then
        return
    end
    for slotIndex = 0, bagSize - 1 do
        ActualizarCacheConsumibleComidaMochila(slotIndex)
    end
end

local function RegistrarConsumoComidaPendiente(previousEntry, stackCountChange)
    if type(previousEntry) ~= "table" then
        return
    end
    local delta = tonumber(stackCountChange) or 0
    if delta >= 0 then
        return
    end

    local itemLink = tostring(previousEntry.itemLink or "")
    local itemName = tostring(previousEntry.itemName or "")
    if itemLink == "" and itemName == "" then
        return
    end

    overlayFoodPendingItem = {
        itemLink = itemLink,
        itemName = itemName,
        timestampMs = ObtenerMomentoActualMs(),
    }

    -- Consumir una comida/bebida desde la mochila suele bajar exactamente una unidad.
    -- Guardamos la referencia en ese momento para no depender del orden entre mochila y buff.
    if delta == -1 then
        GuardarComidaRecordada(itemLink, itemName)
        GuardarComidaEnHistorial(itemLink, itemName)
    end
end

local function IntentarRecordarComidaPendiente()
    if type(overlayFoodPendingItem) ~= "table" then
        return false
    end

    local foodInfo = ObtenerInfoBuffComida()
    if not (type(foodInfo) == "table" and foodInfo.active) then
        return false
    end

    local nowMs = ObtenerMomentoActualMs()
    local pendingMs = tonumber(overlayFoodPendingItem.timestampMs)
    if nowMs and pendingMs and (nowMs - pendingMs) > FOOD_PENDING_WINDOW_MS then
        overlayFoodPendingItem = nil
        return false
    end

    local itemLink = tostring(overlayFoodPendingItem.itemLink or "")
    local itemName = tostring(overlayFoodPendingItem.itemName or "")
    if itemLink == "" and itemName == "" then
        overlayFoodPendingItem = nil
        return false
    end

    GuardarComidaRecordada(itemLink, itemName)
    GuardarComidaEnHistorial(itemLink, itemName)
    overlayFoodPendingItem = nil
    return true
end

local function ObtenerCalidadItem(bagId, slotIndex, itemLink)
    if type(GetItemQuality) == "function" then
        local quality = GetItemQuality(bagId, slotIndex)
        if type(quality) == "number" then
            return quality
        end
    end
    if type(GetItemLinkQuality) == "function" and type(itemLink) == "string" and itemLink ~= "" then
        local quality = GetItemLinkQuality(itemLink)
        if type(quality) == "number" then
            return quality
        end
    end
    return nil
end

BuscarConsumibleComidaPorReferencia = function(targetLink, targetName)
    if type(GetBagSize) ~= "function" then return nil end

    targetLink = tostring(targetLink or "")
    targetName = tostring(targetName or "")
    if targetLink == "" and targetName == "" then
        return nil
    end

    local bagSize = GetBagSize(BAG_BACKPACK)
    if type(bagSize) ~= "number" or bagSize <= 0 then return nil end

    local fallbackBag, fallbackSlot, fallbackName = nil, nil, nil
    for slotIndex = 0, bagSize - 1 do
        if EsConsumibleDeComidaOBebida(BAG_BACKPACK, slotIndex) then
            local itemLink = ""
            if type(GetItemLink) == "function" then
                itemLink = tostring(GetItemLink(BAG_BACKPACK, slotIndex, LINK_STYLE_DEFAULT) or "")
            end
            local itemName = ObtenerNombreItem(BAG_BACKPACK, slotIndex, itemLink)
            if targetLink ~= "" and itemLink == targetLink then
                return BAG_BACKPACK, slotIndex, itemName or targetName, itemLink, ObtenerCalidadItem(BAG_BACKPACK, slotIndex, itemLink), ObtenerDescripcionUsoItem(itemLink)
            end
            if not fallbackBag and targetName ~= "" and type(itemName) == "string" and itemName == targetName then
                fallbackBag, fallbackSlot, fallbackName = BAG_BACKPACK, slotIndex, itemName
            end
        end
    end

    if fallbackBag then
        local itemLink = ""
        if type(GetItemLink) == "function" then
            itemLink = tostring(GetItemLink(fallbackBag, fallbackSlot, LINK_STYLE_DEFAULT) or "")
        end
        return fallbackBag, fallbackSlot, fallbackName, itemLink, ObtenerCalidadItem(fallbackBag, fallbackSlot, itemLink), ObtenerDescripcionUsoItem(itemLink)
    end
    return nil
end

BuscarConsumibleRecordadoComida = function()
    local targetLink = tostring(EZO and EZO.sv and EZO.sv.overlay and EZO.sv.overlay.lastFoodItemLink or "")
    local targetName = tostring(EZO and EZO.sv and EZO.sv.overlay and EZO.sv.overlay.lastFoodItemName or "")
    return BuscarConsumibleComidaPorReferencia(targetLink, targetName)
end

ConstruirTooltipComida = function(foodInfo, foodRecordadoNombre, foodRecordadoDisponible, foodLegendaria)
    local foodState = ObtenerEstadoVisualComida(foodInfo)
    local tooltip = foodState.tooltip
    local remainingSeconds = type(foodInfo) == "table" and tonumber(foodInfo.remainingSeconds) or nil

    if type(foodInfo) == "table" and foodInfo.active and remainingSeconds ~= nil and remainingSeconds <= FOOD_ALERT_SECONDS and foodRecordadoDisponible then
        if foodLegendaria then
            return zo_strformat(
                GetString(EZO_SIDE_WIDGET_FOOD_ALERT_REUSE_LEGENDARY_TOOLTIP),
                tostring(foodInfo.name or "")
            )
        end
        return zo_strformat(
            GetString(EZO_SIDE_WIDGET_FOOD_ALERT_REUSE_TOOLTIP),
            tostring(foodInfo.name or "")
        )
    end

    if not (type(foodInfo) == "table" and foodInfo.active) and foodRecordadoDisponible then
        local nombre = tostring(foodRecordadoNombre or EZO.sv.overlay.lastFoodItemName or "")
        if foodLegendaria then
            return zo_strformat(
                GetString(EZO_SIDE_WIDGET_FOOD_RECALL_LEGENDARY_TOOLTIP),
                nombre
            )
        end
        return zo_strformat(
            GetString(EZO_SIDE_WIDGET_FOOD_RECALL_TOOLTIP),
            nombre
        )
    end

    if type(foodInfo) == "table" and foodInfo.active and foodRecordadoDisponible and remainingSeconds ~= nil then
        local tiempo = FormatearTiempoRestanteCorto(remainingSeconds)
        if foodLegendaria then
            return zo_strformat(
                GetString(EZO_SIDE_WIDGET_FOOD_ACTIVE_REUSE_LEGENDARY_TOOLTIP),
                tostring(foodInfo.name or ""),
                tiempo
            )
        end
        return zo_strformat(
            GetString(EZO_SIDE_WIDGET_FOOD_ACTIVE_REUSE_TOOLTIP),
            tostring(foodInfo.name or ""),
            tiempo
        )
    end

    return tooltip
end

local function RecordarComidaActiva()
    local foodInfo = ObtenerInfoBuffComida()
    if not (type(foodInfo) == "table" and foodInfo.active and type(foodInfo.name) == "string" and foodInfo.name ~= "") then
        return false
    end
    if IntentarRecordarComidaPendiente() then
        return true
    end
    if type(GetBagSize) ~= "function" then return false end

    local bagSize = GetBagSize(BAG_BACKPACK)
    if type(bagSize) ~= "number" or bagSize <= 0 then return false end

    for slotIndex = 0, bagSize - 1 do
        if EsConsumibleDeComidaOBebida(BAG_BACKPACK, slotIndex) then
            local itemLink = ""
            if type(GetItemLink) == "function" then
                itemLink = tostring(GetItemLink(BAG_BACKPACK, slotIndex, LINK_STYLE_DEFAULT) or "")
            end
            local itemName = ObtenerNombreItem(BAG_BACKPACK, slotIndex, itemLink)
            local abilityHeader = ObtenerCabeceraUsoItem(itemLink)
            local coincideNombre = type(itemName) == "string" and itemName == foodInfo.name
            local coincideCabecera = type(abilityHeader) == "string" and abilityHeader == foodInfo.name
            if coincideNombre or coincideCabecera then
                GuardarComidaRecordada(itemLink, itemName)
                GuardarComidaEnHistorial(itemLink, itemName)
                return true
            end
        end
    end
    return false
end

local function ConsumirComidaEnSlot(bagId, slotIndex, itemName, itemLink)
    if not bagId or slotIndex == nil then
        return false
    end
    GuardarComidaRecordada(itemLink, itemName)
    GuardarComidaEnHistorial(itemLink, itemName)

    if type(CallSecureProtected) == "function" then
        local okSecure, _ = pcall(CallSecureProtected, "UseItem", bagId, slotIndex)
        if okSecure then
            return true
        end
    end

    if type(UseItem) ~= "function" then
        return false
    end

    local ok, res = pcall(UseItem, bagId, slotIndex)
    if ok and res ~= false then
        return true
    end
    return false
end

local function ConsumirComidaRecordada()
    local bagId, slotIndex, itemName, itemLink = BuscarConsumibleRecordadoComida()
    return ConsumirComidaEnSlot(bagId, slotIndex, itemName, itemLink)
end

local function VerificarConsumoComidaDebug(foodInfoAntes)
    if type(zo_callLater) ~= "function" then
        return
    end

    zo_callLater(function()
        local foodInfoDespues = ObtenerInfoBuffComida()
        local antesActivo = type(foodInfoAntes) == "table" and foodInfoAntes.active == true
        local despuesActivo = type(foodInfoDespues) == "table" and foodInfoDespues.active == true
        local antesNombre = antesActivo and tostring(foodInfoAntes.name or "") or ""
        local despuesNombre = despuesActivo and tostring(foodInfoDespues.name or "") or ""
        local antesSeg = antesActivo and tonumber(foodInfoAntes.remainingSeconds) or nil
        local despuesSeg = despuesActivo and tonumber(foodInfoDespues.remainingSeconds) or nil

        local consumido = false
        if not antesActivo and despuesActivo then
            consumido = true
        elseif antesActivo and despuesActivo then
            if antesNombre ~= "" and despuesNombre ~= "" and antesNombre ~= despuesNombre then
                consumido = true
            elseif type(antesSeg) == "number" and type(despuesSeg) == "number" and despuesSeg > (antesSeg + 30) then
                consumido = true
            end
        end

        if not consumido and EZO and type(EZO.Print) == "function" then
            EZO.Print(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_FAILED))
        end
    end, 1500)
end

local function AsegurarDialogoConfirmacionComida()
    if overlayFoodConfirmDialogRegistered then
        return
    end

    ZO_Dialogs_RegisterCustomDialog("EZOTOOLS_CONFIRM_FOOD_REUSE", {
        title = {
            text = function(dialog)
                local data = dialog.data or {}
                return data.title or GetString(EZO_SIDE_WIDGET_FOOD_CONFIRM_TITLE)
            end,
        },
        mainText = {
            text = function(dialog)
                local data = dialog.data or {}
                return data.text or ""
            end,
        },
        buttons = {
            {
                control = ZO_Dialogs_CreateButtonControl,
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    local data = dialog.data or {}
                    if type(data.onConfirm) == "function" then
                        data.onConfirm()
                    end
                end,
            },
            {
                control = ZO_Dialogs_CreateButtonControl,
                text = SI_DIALOG_CANCEL,
            },
        },
    })

    overlayFoodConfirmDialogRegistered = true
end

local function PedirConfirmacionComidaLegendaria(itemName, effectDescription, remainingSeconds, onConfirm)
    if type(onConfirm) ~= "function" then
        return false
    end

    AsegurarDialogoConfirmacionComida()

    local descripcion = tostring(effectDescription or "")
    local texto
    local tiempoRestante = tonumber(remainingSeconds)
    local incluirTiempo = tiempoRestante ~= nil and tiempoRestante > FOOD_ALERT_SECONDS
    if descripcion ~= "" and incluirTiempo then
        texto = zo_strformat(
            GetString(EZO_SIDE_WIDGET_FOOD_CONFIRM_TEXT_WITH_EFFECT_AND_TIME),
            tostring(itemName or ""),
            descripcion,
            FormatearTiempoRestanteCorto(tiempoRestante)
        )
    elseif descripcion ~= "" then
        texto = zo_strformat(
            GetString(EZO_SIDE_WIDGET_FOOD_CONFIRM_TEXT_WITH_EFFECT),
            tostring(itemName or ""),
            descripcion
        )
    elseif incluirTiempo then
        texto = zo_strformat(
            GetString(EZO_SIDE_WIDGET_FOOD_CONFIRM_TEXT_WITH_TIME),
            tostring(itemName or ""),
            FormatearTiempoRestanteCorto(tiempoRestante)
        )
    else
        texto = zo_strformat(
            GetString(EZO_SIDE_WIDGET_FOOD_CONFIRM_TEXT),
            tostring(itemName or "")
        )
    end

    if type(ZO_Dialogs_ShowDialog) == "function" then
        ZO_Dialogs_ShowDialog("EZOTOOLS_CONFIRM_FOOD_REUSE", {
            title = GetString(EZO_SIDE_WIDGET_FOOD_CONFIRM_TITLE),
            text = NormalizarTextoTooltip(texto),
            onConfirm = onConfirm,
        })
        return true
    end

    return false
end

local function ReusarComidaRecordadaConSeguridad()
    local foodInfoAntes = ObtenerInfoBuffComida()
    local bagId, slotIndex, itemName, itemLink, quality, effectDescription = BuscarConsumibleRecordadoComida()
    if not bagId or slotIndex == nil then
        if EZO and type(EZO.Print) == "function" then
            EZO.Print(GetString(EZO_MSG_DEBUG_FOOD_NO_RECORDED))
        end
        return false
    end

    local qualityLegendary = (type(ITEM_QUALITY_LEGENDARY) == "number") and ITEM_QUALITY_LEGENDARY or nil
    if qualityLegendary and quality == qualityLegendary then
        local remainingSeconds = type(foodInfoAntes) == "table" and tonumber(foodInfoAntes.remainingSeconds) or nil
        return PedirConfirmacionComidaLegendaria(itemName, effectDescription, remainingSeconds, function()
            if EZO and type(EZO.Print) == "function" then
                EZO.Print(zo_strformat(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_ATTEMPT), tostring(itemName or "")))
            end
            if ConsumirComidaRecordada() then
                VerificarConsumoComidaDebug(foodInfoAntes)
            elseif EZO and type(EZO.Print) == "function" then
                EZO.Print(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_FAILED))
            end
        end)
    end

    if EZO and type(EZO.Print) == "function" then
        EZO.Print(zo_strformat(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_ATTEMPT), tostring(itemName or "")))
    end
    local ok = ConsumirComidaRecordada()
    if ok then
        VerificarConsumoComidaDebug(foodInfoAntes)
    elseif EZO and type(EZO.Print) == "function" then
        EZO.Print(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_FAILED))
    end
    return ok
end

local function ConsumirComidaHistorialConSeguridad(itemLink, itemName)
    local foodInfoAntes = ObtenerInfoBuffComida()
    local bagId, slotIndex, resolvedName, resolvedLink, quality, effectDescription = BuscarConsumibleComidaPorReferencia(itemLink, itemName)
    if not bagId or slotIndex == nil then
        if EZO and type(EZO.Print) == "function" then
            EZO.Print(GetString(EZO_MSG_DEBUG_FOOD_NO_RECORDED))
        end
        return false
    end

    local finalName = tostring(resolvedName or itemName or "")
    local qualityLegendary = (type(ITEM_QUALITY_LEGENDARY) == "number") and ITEM_QUALITY_LEGENDARY or nil
    if qualityLegendary and quality == qualityLegendary then
        return PedirConfirmacionComidaLegendaria(finalName, effectDescription, nil, function()
            if EZO and type(EZO.Print) == "function" then
                EZO.Print(zo_strformat(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_ATTEMPT), finalName))
            end
            if ConsumirComidaEnSlot(bagId, slotIndex, finalName, resolvedLink) then
                VerificarConsumoComidaDebug(foodInfoAntes)
            elseif EZO and type(EZO.Print) == "function" then
                EZO.Print(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_FAILED))
            end
        end)
    end

    if EZO and type(EZO.Print) == "function" then
        EZO.Print(zo_strformat(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_ATTEMPT), finalName))
    end
    local ok = ConsumirComidaEnSlot(bagId, slotIndex, finalName, resolvedLink)
    if ok then
        VerificarConsumoComidaDebug(foodInfoAntes)
    elseif EZO and type(EZO.Print) == "function" then
        EZO.Print(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_FAILED))
    end
    return ok
end

local function AnadirEntradaMenuReciente(label, onSelect, tooltipText, enabled, onEnter, onExit)
    if type(label) ~= "string" or label == "" then
        return false
    end

    local index = nil
    if type(AddCustomMenuItem) == "function" then
        index = AddCustomMenuItem(label, onSelect, MENU_ADD_OPTION_LABEL, nil, nil, nil, nil, nil, nil, onEnter, onExit, enabled ~= false)
    elseif type(AddMenuItem) == "function" then
        index = AddMenuItem(label, onSelect)
    else
        return false
    end

    if type(index) == "number" and type(AddCustomMenuTooltip) == "function" and type(tooltipText) == "string" and tooltipText ~= "" then
        AddCustomMenuTooltip(NormalizarTextoTooltip(tooltipText), index)
    end

    return true
end

local function MostrarTooltipItemSobreControl(ctrl, itemLink)
    if type(itemLink) ~= "string" or itemLink == "" then
        return
    end
    if not (ctrl and ItemTooltip and type(InitializeTooltip) == "function" and ItemTooltip.SetLink) then
        return
    end

    local guiRootWidth = GuiRoot and select(1, GuiRoot:GetDimensions()) or 0
    local centerX = ctrl:GetCenter()
    if type(centerX) == "number" and guiRootWidth > 0 and centerX > (guiRootWidth / 2) then
        InitializeTooltip(ItemTooltip, ctrl, TOPRIGHT, -12, 0, TOPLEFT)
    else
        InitializeTooltip(ItemTooltip, ctrl, TOPLEFT, 12, 0, TOPRIGHT)
    end
    ItemTooltip:SetLink(itemLink)
end

local function MostrarTooltipCollectibleSobreControl(ctrl, collectibleId, fallbackName)
    if not ctrl then
        return
    end
    local nombre = tostring(ObtenerNombreCollectible(collectibleId, fallbackName) or "")
    local descripcion = ObtenerDescripcionCollectible(collectibleId)
    local texto = nombre
    if nombre ~= "" and type(descripcion) == "string" and descripcion ~= "" then
        texto = string.format("%s|n%s", nombre, descripcion)
    end
    if texto ~= "" then
        MostrarTooltipTextoSobreControl(ctrl, texto)
    end
end

local function AbrirMenuRecientes(anchor, entries, emptyLabel)
    if ClearMenu then
        ClearMenu()
    end

    local entriesAdded = 0
    if type(entries) == "table" then
        for _, entry in ipairs(entries) do
            if type(entry) == "table" and AnadirEntradaMenuReciente(
                tostring(entry.label or ""),
                entry.onSelect,
                entry.tooltipText,
                entry.enabled,
                entry.onEnter,
                entry.onExit
            ) then
                entriesAdded = entriesAdded + 1
            end
        end
    end

    if entriesAdded == 0 then
        AnadirEntradaMenuReciente(tostring(emptyLabel or ""), function() return true end, nil, false)
    end

    if ShowMenu then
        ShowMenu(anchor)
    end
end

local function ObtenerTooltipEntradaComidaHistorial(itemLink, itemName)
    local _, _, resolvedName, _, _, effectDescription = BuscarConsumibleComidaPorReferencia(itemLink, itemName)
    local tooltipParts = {}
    local finalName = tostring(resolvedName or itemName or "")
    if finalName ~= "" then
        tooltipParts[#tooltipParts + 1] = finalName
    end
    if type(effectDescription) == "string" and effectDescription ~= "" then
        tooltipParts[#tooltipParts + 1] = effectDescription
    end
    return table.concat(tooltipParts, "|n")
end

local function AbrirMenuHistorialComida(anchor)
    local history = EZO and EZO.sv and EZO.sv.overlay and EZO.sv.overlay.recentFoodItems or nil
    local entries = {}
    if type(history) == "table" then
        for _, entry in ipairs(history) do
            if type(entry) == "table" then
                local itemLink = tostring(entry.itemLink or "")
                local itemName = tostring(entry.itemName or "")
                local _, _, resolvedName = BuscarConsumibleComidaPorReferencia(itemLink, itemName)
                local label = tostring(resolvedName or itemName or "")
                if label ~= "" then
                    local itemLinkTooltip = itemLink
                    entries[#entries + 1] = {
                        label = label,
                        onEnter = function(control)
                            MostrarTooltipItemSobreControl(control, itemLinkTooltip)
                        end,
                        onExit = function()
                            if type(ClearTooltip) == "function" and ItemTooltip then
                                ClearTooltip(ItemTooltip)
                            end
                        end,
                        onSelect = function()
                            ConsumirComidaHistorialConSeguridad(itemLink, itemName)
                        end,
                    }
                end
            end
        end
    end

    AbrirMenuRecientes(anchor, entries, GetString(EZO_SIDE_WIDGET_FOOD_HISTORY_EMPTY))
end

local ALLY_ICON_MENU_CONFIG = {
    pet = {
        rememberedKey = "lastPetCollectibleId",
        historyKey = "recentPetCollectibles",
        fallbackNameId = EZO_DOT_PET_FALLBACK_NAME,
        historyEmptyId = EZO_DOT_PET_HISTORY_EMPTY,
    },
    companion = {
        rememberedKey = "lastCompanionCollectibleId",
        historyKey = "recentCompanionCollectibles",
        fallbackNameId = EZO_DOT_COMPANION_FALLBACK_NAME,
        historyEmptyId = EZO_DOT_COMPANION_HISTORY_EMPTY,
    },
    assistant = {
        rememberedKey = "lastAssistantCollectibleId",
        historyKey = "recentAssistantCollectibles",
        fallbackNameId = EZO_DOT_ASSISTANT_FALLBACK_NAME,
        historyEmptyId = EZO_DOT_ASSISTANT_HISTORY_EMPTY,
    },
}

local function ObtenerConfiguracionAliado(tipo)
    return ALLY_ICON_MENU_CONFIG[tipo]
end

local function EjecutarAccionWidget(side, index, data, button)
    if type(data) ~= "table" then return end

    local handler = nil
    if button == MOUSE_BUTTON_INDEX_RIGHT then
        handler = data.secondaryHandler
    else
        handler = data.primaryHandler
    end
    if type(handler) == "function" then
        local ok, handled = pcall(handler, {
            source = "MOUSE",
            anchor = overlayWin,
            widgetSide = side,
            widgetIndex = index,
            button = button,
        })
        if ok and handled ~= false then return end
    end

    local actionId = data.actionId
    if button == MOUSE_BUTTON_INDEX_RIGHT and type(data.secondaryActionId) == "string" and data.secondaryActionId ~= "" then
        actionId = data.secondaryActionId
    end
    if type(actionId) ~= "string" or actionId == "" then
        return
    end
    if not (EZOTools_ActionExec and type(EZOTools_ActionExec.Execute) == "function") then
        return
    end
    EZOTools_ActionExec.Execute(actionId, {
        source = "MOUSE",
        anchor = overlayWin,
        widgetSide = side,
        widgetIndex = index,
        button = button,
    })
end

local function ConstruirWidgetLateralData(config)
    if type(config) ~= "table" then return nil end
    return {
        slotKey = config.slotKey,
        visible = config.visible ~= false,
        texture = config.texture,
        color = config.color,
        alpha = config.alpha or 1,
        tooltipText = config.tooltipText,
        tooltipStringId = config.tooltipStringId,
        tooltipArgs = config.tooltipArgs,
        actionId = config.actionId,
        secondaryActionId = config.secondaryActionId,
        gamepadActionId = config.gamepadActionId,
        primaryHandler = config.primaryHandler,
        secondaryHandler = config.secondaryHandler,
    }
end

local function ObtenerPreviewWidgetData(side, index)
    local previewTexture = "/esoui/art/buttons/large_leftarrow_up.dds"
    local previewColors = {
        left = {
            { 0.95, 0.85, 0.35, 0.95 },
            { 0.75, 0.86, 0.40, 0.95 },
            { 0.45, 0.80, 0.95, 0.95 },
            { 0.90, 0.55, 0.85, 0.95 },
        },
        right = {
            { 0.95, 0.70, 0.30, 0.95 },
            { 0.70, 0.70, 0.95, 0.95 },
            { 0.92, 0.92, 0.92, 0.95 },
            { 0.95, 0.35, 0.35, 0.95 },
        },
    }

    local assignedPreview = {
        repairEquipped = {
            texture = "/esoui/art/hud/broken_armor.dds",
            color = { 1.0, 0.30, 0.30, 0.95 },
        },
        repairKits = {
            texture = "/esoui/art/icons/quest_crate_001.dds",
            color = { 1.0, 0.32, 0.22, 0.95 },
        },
        rechargeWeapons = {
            texture = "/esoui/art/hud/broken_weapon.dds",
            color = { 1.0, 0.30, 0.30, 0.95 },
        },
        soulGems = {
            texture = "/esoui/art/icons/soulgem_006_filled.dds",
            color = { 1.0, 0.45, 0.15, 0.95 },
        },
        foodBuff = {
            texture = "/esoui/art/inventory/inventory_tabIcon_Craftbag_provisioning_up.dds",
            color = { 0.35, 0.85, 0.35, 0.95 },
        },
    }

    for key, slotInfo in pairs(SIDE_WIDGET_ASSIGNMENTS) do
        if slotInfo and slotInfo.side == side and slotInfo.index == index and assignedPreview[key] then
            return {
                visible = true,
                texture = assignedPreview[key].texture,
                color = assignedPreview[key].color,
                alpha = 0.95,
            }
        end
    end

    return {
        visible = true,
        texture = previewTexture,
        color = previewColors[side][index],
        alpha = 0.95,
    }
end

local function ObtenerRenderDataWidget(side, index)
    local data = ObtenerDatosWidgetLaterales(side)[index]
    if type(data) == "table" and data.visible ~= false and type(data.texture) == "string" and data.texture ~= "" then
        return data
    end
    if overlayLayoutPreviewEnabled then
        return ObtenerPreviewWidgetData(side, index)
    end
    return nil
end

local AplicarWidgetsLaterales

local function ReconstruirRegistroWidgetsLaterales()
    overlaySideWidgetRegistry.left = {}
    overlaySideWidgetRegistry.right = {}
    for _, side in ipairs({ "left", "right" }) do
        local dataList = ObtenerDatosWidgetLaterales(side)
        local registry = overlaySideWidgetRegistry[side]
        for i = 1, SIDE_SLOT_COUNT do
            local data = dataList[i]
            if type(data) == "table" and data.visible ~= false then
                registry[i] = data.slotKey or true
            else
                registry[i] = false
            end
        end
    end
end
local function AsignarWidgetLateralInterno(slotInfo, data)
    if not slotInfo or not slotInfo.side or not slotInfo.index then return end
    local lista = ObtenerDatosWidgetLaterales(slotInfo.side)
    if not lista then return end
    lista[slotInfo.index] = data
end

local function RefrescarWidgetsLateralesEstado()
    local repairKitThreshold = type(EZOTools.GetRepairKitStockThreshold) == "function" and EZOTools.GetRepairKitStockThreshold() or nil
    local repairKitCount = type(EZOTools.GetRepairKitCount) == "function" and EZOTools.GetRepairKitCount() or nil
    local lowRepairKits = type(EZOTools.HasLowRepairKitStock) == "function" and EZOTools.HasLowRepairKitStock() or false
    local soulGemThreshold = type(EZOTools.GetSoulGemStockThreshold) == "function" and EZOTools.GetSoulGemStockThreshold() or nil
    local soulGemCount = type(EZOTools.GetFilledSoulGemCount) == "function" and EZOTools.GetFilledSoulGemCount() or nil
    local lowSoulGems = type(EZOTools.HasLowSoulGemStock) == "function" and EZOTools.HasLowSoulGemStock() or false
    local repairThreshold = (EZO.sv and EZO.sv.general and tonumber(EZO.sv.general.repairThreshold)) or 40
    local rechargeThreshold = (EZO.sv and EZO.sv.general and tonumber(EZO.sv.general.rechargeThreshold)) or 50
    local canRepairEquipped = type(EZOTools.CanRepairEquipped) == "function" and EZOTools.CanRepairEquipped() or false
    local canRechargeWeapons = type(EZOTools.CanRechargeWeapons) == "function" and EZOTools.CanRechargeWeapons() or false
    local foodInfo = ObtenerInfoBuffComida()
    RecordarComidaActiva()
    local foodState = ObtenerEstadoVisualComida(foodInfo)
    overlayFoodPulseState = foodState.pulse
    local foodPrimaryHandler = nil
    local foodSecondaryHandler = nil
    local foodContextualTooltip = foodState.tooltip
    local foodRecordadoBag, _, foodRecordadoNombre, _, foodRecordadoQuality = BuscarConsumibleRecordadoComida()
    local foodRecordadoDisponible = foodRecordadoBag ~= nil
    local foodLegendaria = type(ITEM_QUALITY_LEGENDARY) == "number" and foodRecordadoQuality == ITEM_QUALITY_LEGENDARY

    if foodRecordadoDisponible then
        foodPrimaryHandler = function()
            return ReusarComidaRecordadaConSeguridad()
        end
        foodSecondaryHandler = function()
            return false
        end
    end

    foodContextualTooltip = ConstruirTooltipComida(
        foodInfo,
        foodRecordadoNombre,
        foodRecordadoDisponible,
        foodLegendaria
    )

    AsignarWidgetLateralInterno(SIDE_WIDGET_ASSIGNMENTS.foodBuff, ConstruirWidgetLateralData({
        slotKey = "food_buff",
        visible = true,
        texture = "/esoui/art/inventory/inventory_tabIcon_Craftbag_provisioning_up.dds",
        color = foodState.color,
        alpha = foodState.alpha,
        tooltipText = foodContextualTooltip,
        primaryHandler = foodPrimaryHandler,
        secondaryHandler = foodSecondaryHandler,
    }))

    if lowRepairKits and type(repairKitCount) == "number" and type(repairKitThreshold) == "number" then
        AsignarWidgetLateralInterno(SIDE_WIDGET_ASSIGNMENTS.repairKits, ConstruirWidgetLateralData({
            slotKey = "repair_kits",
            visible = true,
            texture = "/esoui/art/icons/quest_crate_001.dds",
            color = { 1.0, 0.32, 0.22, 0.95 },
            alpha = 1,
            tooltipStringId = EZO_SIDE_WIDGET_REPAIR_KITS_TOOLTIP,
            tooltipArgs = { tostring(repairKitCount), tostring(repairKitThreshold) },
            actionId = "OPEN_ADDON_SETTINGS",
            gamepadActionId = "OPEN_ADDON_SETTINGS",
        }))
    else
        AsignarWidgetLateralInterno(SIDE_WIDGET_ASSIGNMENTS.repairKits, nil)
    end

    if lowSoulGems and type(soulGemCount) == "number" and type(soulGemThreshold) == "number" then
        AsignarWidgetLateralInterno(SIDE_WIDGET_ASSIGNMENTS.soulGems, ConstruirWidgetLateralData({
            slotKey = "soul_gems",
            visible = true,
            texture = "/esoui/art/icons/soulgem_006_filled.dds",
            color = { 1.0, 0.45, 0.15, 0.95 },
            alpha = 1,
            tooltipStringId = EZO_SIDE_WIDGET_SOUL_GEMS_TOOLTIP,
            tooltipArgs = { tostring(soulGemCount), tostring(soulGemThreshold) },
            actionId = "OPEN_ADDON_SETTINGS",
            gamepadActionId = "OPEN_ADDON_SETTINGS",
        }))
    else
        AsignarWidgetLateralInterno(SIDE_WIDGET_ASSIGNMENTS.soulGems, nil)
    end

    if canRepairEquipped then
        AsignarWidgetLateralInterno(SIDE_WIDGET_ASSIGNMENTS.repairEquipped, ConstruirWidgetLateralData({
            slotKey = "repair_equipped",
            visible = true,
            texture = "/esoui/art/hud/broken_armor.dds",
            color = { 1.0, 0.30, 0.30, 0.95 },
            alpha = 1,
            tooltipStringId = EZO_SIDE_WIDGET_REPAIR_EQUIPPED_TOOLTIP,
            tooltipArgs = { tostring(repairThreshold) },
            actionId = "REPAIR_EQUIPPED",
            secondaryActionId = "OPEN_ADDON_SETTINGS",
            gamepadActionId = "REPAIR_EQUIPPED",
        }))
    else
        AsignarWidgetLateralInterno(SIDE_WIDGET_ASSIGNMENTS.repairEquipped, nil)
    end

    if canRechargeWeapons then
        AsignarWidgetLateralInterno(SIDE_WIDGET_ASSIGNMENTS.rechargeWeapons, ConstruirWidgetLateralData({
            slotKey = "recharge_weapons",
            visible = true,
            texture = "/esoui/art/hud/broken_weapon.dds",
            color = { 1.0, 0.30, 0.30, 0.95 },
            alpha = 1,
            tooltipStringId = EZO_SIDE_WIDGET_RECHARGE_WEAPONS_TOOLTIP,
            tooltipArgs = { tostring(rechargeThreshold) },
            actionId = "RECHARGE_WEAPONS",
            secondaryActionId = "OPEN_ADDON_SETTINGS",
            gamepadActionId = "RECHARGE_WEAPONS",
        }))
    else
        AsignarWidgetLateralInterno(SIDE_WIDGET_ASSIGNMENTS.rechargeWeapons, nil)
    end

    AplicarWidgetsLaterales()
end

local function AplicarPreviewSlotsLaterales()
    for _, side in ipairs({ "left", "right" }) do
        local lista = ObtenerSlotsLaterales(side)
        for i = 1, SIDE_SLOT_COUNT do
            local ctrl = lista[i]
            if ctrl then
                ctrl:SetHidden(true)
            end
        end
    end
end

AplicarWidgetsLaterales = function()
    ReconstruirRegistroWidgetsLaterales()
    for _, side in ipairs({ "left", "right" }) do
        local widgets = ObtenerWidgetsLaterales(side)
        local textures = ObtenerTexturasWidgetLaterales(side)
        for i = 1, SIDE_SLOT_COUNT do
            local host = widgets[i]
            local tex = textures[i]
            local data = ObtenerRenderDataWidget(side, i)
            if host and tex then
                if data then
                    local color = data.color or { 1, 1, 1, 1 }
                    tex:SetTexture(data.texture)
                    tex:SetColor(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
                    tex:SetAlpha(data.alpha or 1)
                    host:SetHidden(false)
                    tex:SetHidden(false)
                else
                    host:SetHidden(true)
                    tex:SetHidden(true)
                end
            end
        end
    end
end

local function AsegurarSlotsLaterales()
    local nombres = {
        left  = "EZOToolsSideSlotLeft",
        right = "EZOToolsSideSlotRight",
    }
    for side, prefijo in pairs(nombres) do
        local lista = ObtenerSlotsLaterales(side)
        for i = 1, SIDE_SLOT_COUNT do
            if not lista[i] then
                local ctrl = WINDOW_MANAGER:CreateControl(prefijo .. i, overlayWin, CT_TEXTURE)
                ctrl:SetDimensions(SIDE_SLOT_BASE, SIDE_SLOT_BASE)
                ctrl:SetHidden(true)
                lista[i] = ctrl
            end
        end
    end
end

local function AsegurarWidgetsLaterales()
    local nombres = {
        left  = "EZOToolsSideWidgetLeft",
        right = "EZOToolsSideWidgetRight",
    }
    for side, prefijo in pairs(nombres) do
        local widgets = ObtenerWidgetsLaterales(side)
        local textures = ObtenerTexturasWidgetLaterales(side)
        for i = 1, SIDE_SLOT_COUNT do
            if not widgets[i] then
                local host = WINDOW_MANAGER:CreateControl(prefijo .. i, overlayWin, CT_CONTROL)
                host:SetDimensions(SIDE_SLOT_BASE, SIDE_SLOT_BASE)
                host:SetHidden(true)
                host:SetMouseEnabled(true)
                host:SetDrawLayer(DL_CONTROLS)
                host:SetDrawTier(DT_HIGH)
                local widgetSide = side
                local widgetIndex = i
                host:SetHandler("OnMouseEnter", function(ctrl)
                    MostrarTooltipWidget(ctrl, widgetSide, widgetIndex, ObtenerRenderDataWidget(widgetSide, widgetIndex))
                end)
                host:SetHandler("OnMouseExit", function()
                    OcultarTooltipWidget()
                end)
                host:SetHandler("OnMouseUp", function(_, button, upInside)
                    if not upInside then return end
                    local data = ObtenerRenderDataWidget(widgetSide, widgetIndex)
                    if button == MOUSE_BUTTON_INDEX_RIGHT then
                        if type(data) == "table" and data.slotKey == "food_buff" then
                            AbrirMenuHistorialComida(host)
                        elseif type(data) == "table" and type(data.secondaryHandler) == "function" then
                            EjecutarAccionWidget(widgetSide, widgetIndex, data, button)
                        elseif type(data) == "table" and type(data.secondaryActionId) == "string" and data.secondaryActionId ~= "" then
                            EjecutarAccionWidget(widgetSide, widgetIndex, data, button)
                        elseif EZOTools_ContextMenu and EZOTools_ContextMenu.OpenMouse then
                            EZOTools_ContextMenu.OpenMouse(overlayWin)
                        end
                        return
                    end
                    if button == MOUSE_BUTTON_INDEX_LEFT then
                        EjecutarAccionWidget(widgetSide, widgetIndex, data, button)
                    end
                end)

                local tex = WINDOW_MANAGER:CreateControl("$(parent)Tex", host, CT_TEXTURE)
                tex:SetAnchorFill()
                tex:SetMouseEnabled(false)
                tex:SetHidden(true)

                widgets[i] = host
                textures[i] = tex
            end
        end
    end
end

local function AplicarLayoutSlotsLaterales(texPx)
    AsegurarSlotsLaterales()
    AsegurarWidgetsLaterales()

    local s          = tonumber(EZO.sv.overlay.scale) or 1
    local slotSize   = math.max(SIDE_SLOT_MIN, math.floor(SIDE_SLOT_BASE * s + 0.5))
    local slotGap    = math.max(4, math.floor(SIDE_SLOT_GAP * s + 0.5))
    local radiusX    = math.max(slotSize, math.floor(texPx * SIDE_SLOT_RADIUS_X + 0.5))
    local radiusY    = math.max(slotSize, math.floor(texPx * SIDE_SLOT_RADIUS_Y + 0.5))
    local halfSlot   = math.floor(slotSize * 0.5 + 0.5)
    local maxExtent  = math.floor(texPx * 0.5 + 0.5)
    local lados = {
        { side = "left",  sign = -1 },
        { side = "right", sign =  1 },
    }

    for idx, yRatio in ipairs(SIDE_SLOT_Y) do
        local yOffset = math.floor(radiusY * yRatio + 0.5)
        local yNorm   = math.min(0.98, math.abs(yOffset) / math.max(1, radiusY))
        local curveX  = math.floor(math.sqrt(math.max(0, 1 - yNorm * yNorm)) * radiusX + 0.5)
        local xOffset = curveX + slotGap + halfSlot
        maxExtent = math.max(maxExtent, xOffset + halfSlot)

        for _, lado in ipairs(lados) do
            local lista = ObtenerSlotsLaterales(lado.side)
            local ctrl = lista[idx]
            if ctrl then
                ctrl:SetDimensions(slotSize, slotSize)
                ctrl:ClearAnchors()
                ctrl:SetAnchor(CENTER, overlayTex, CENTER, lado.sign * xOffset, yOffset)
            end
            local widgets = ObtenerWidgetsLaterales(lado.side)
            local host = widgets[idx]
            if host then
                host:SetDimensions(slotSize, slotSize)
                host:ClearAnchors()
                host:SetAnchor(CENTER, overlayTex, CENTER, lado.sign * xOffset, yOffset)
            end
        end
    end

    AplicarPreviewSlotsLaterales()
    AplicarWidgetsLaterales()
    return maxExtent, slotSize
end

local function AplicarPulsoWidgetComida()
    if type(overlayFoodPulseState) ~= "table" then return end

    local slotInfo = SIDE_WIDGET_ASSIGNMENTS.foodBuff
    if not slotInfo then return end

    local textures = ObtenerTexturasWidgetLaterales(slotInfo.side)
    local tex = textures and textures[slotInfo.index] or nil
    if not tex or tex:IsHidden() then return end

    local color = overlayFoodPulseState.color or { 1, 1, 1, 1 }
    local alpha = CalcularPulsoAlfa(
        overlayFoodPulseState.period,
        overlayFoodPulseState.minAlpha,
        overlayFoodPulseState.maxAlpha
    )

    tex:SetColor(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
    tex:SetAlpha(alpha)

    local dataList = ObtenerDatosWidgetLaterales(slotInfo.side)
    local data = dataList and dataList[slotInfo.index] or nil
    if type(data) == "table" then
        data.color = color
        data.alpha = alpha
    end
end

function MOD.GetSideSlot(side, index)
    local lista = ObtenerSlotsLaterales(side)
    return lista and lista[index] or nil
end

function MOD.GetSideSlotCount()
    return SIDE_SLOT_COUNT
end

function MOD.GetSideWidget(side, index)
    local lista = ObtenerWidgetsLaterales(side)
    return lista and lista[index] or nil
end

function MOD.GetSideWidgetSlotState(side, index)
    local lista = overlaySideWidgetRegistry[side]
    if not lista or type(index) ~= "number" then return nil end
    return lista[index]
end

function MOD.GetSideWidgetRegistry()
    local snapshot = { left = {}, right = {} }
    for _, side in ipairs({ "left", "right" }) do
        for i = 1, SIDE_SLOT_COUNT do
            snapshot[side][i] = overlaySideWidgetRegistry[side][i] or false
        end
    end
    return snapshot
end

function MOD.FindFreeSideWidgetSlot(side)
    local lista = overlaySideWidgetRegistry[side]
    if not lista then return nil end
    for i = 1, SIDE_SLOT_COUNT do
        if not lista[i] then
            return i
        end
    end
    return nil
end

function MOD.SetSideWidgetData(side, index, data)
    local lista = ObtenerDatosWidgetLaterales(side)
    if not lista or type(index) ~= "number" or index < 1 or index > SIDE_SLOT_COUNT then return end
    if type(data) ~= "table" then
        lista[index] = nil
    else
        lista[index] = {
            visible = data.visible,
            texture = data.texture,
            color = data.color,
            alpha = data.alpha,
            tooltipText = data.tooltipText,
            tooltipStringId = data.tooltipStringId,
            tooltipArgs = data.tooltipArgs,
            actionId = data.actionId,
            gamepadActionId = data.gamepadActionId,
            secondaryActionId = data.secondaryActionId,
            slotKey = data.slotKey,
        }
    end
    MOD.Refresh()
end

function MOD.ClearSideWidgetData(side, index)
    local lista = ObtenerDatosWidgetLaterales(side)
    if not lista then return end
    lista[index] = nil
    MOD.Refresh()
end

function MOD.ClearAllSideWidgetData()
    overlaySideWidgetData.left = {}
    overlaySideWidgetData.right = {}
    MOD.Refresh()
end

function MOD.ToggleLayoutPreview()
    overlayLayoutPreviewEnabled = not overlayLayoutPreviewEnabled
    if not overlayLayoutPreviewEnabled then
        OcultarTooltipWidget()
    end
    MOD.Refresh()
    return overlayLayoutPreviewEnabled
end
function MOD.IsLayoutPreviewEnabled()
    return overlayLayoutPreviewEnabled
end

function MOD.SetFoodDebugState(state)
    state = zo_strlower(tostring(state or ""))
    if state == "" or state == "auto" or state == "off" then
        overlayFoodDebugState = nil
    elseif state == "green" or state == "yellow" or state == "red" then
        overlayFoodDebugState = state
    else
        return false
    end
    MOD.Refresh()
    return true
end
-- Aplica la escala visual al logo y la etiqueta de texto
local function AplicarEscalaVisual()
    if not overlayTex or not overlayLabel then return end
    local s      = tonumber(EZO.sv.overlay.scale) or 1
    local texPx  = math.max(64, math.floor(BASE_TEX * s + 0.5))
    overlayTex:SetDimensions(texPx, texPx)

    local esGP   = (EZO.sv.overlay.simulateGamepad or IsInGamepadPreferredMode())
    local basePx = esGP and BASE_FONT_GP or BASE_FONT_PC
    local playerScale = tonumber(EZO.sv.overlay.playerTextScale) or 1
    playerScale = zo_clamp(playerScale, PLAYER_TEXT_SCALE_MIN, PLAYER_TEXT_SCALE_MAX)
    local playerPx = math.floor(basePx * s * playerScale + 0.5)
    overlayLabel:SetFont(CadenaFuente(playerPx))
    overlayLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    local guildPx = math.floor(basePx * GUILD_FONT_RATIO * s + 0.5)
    if overlayGuildLabel then
        overlayGuildLabel:SetFont(CadenaFuente(guildPx))
        overlayGuildLabel:ClearAnchors()
        overlayGuildLabel:SetAnchor(TOP, overlayWin, TOP, 0, OVERLAY_TOP_PADDING)
        overlayGuildLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    end

    overlayTex:ClearAnchors()
    overlayTex:SetAnchor(
        TOP,
        overlayGuildLabel or overlayWin,
        overlayGuildLabel and BOTTOM or TOP,
        0,
        math.floor(OVERLAY_ROW_GAP_SMALL * s + 0.5)
    )

    overlayLabel:ClearAnchors()
    overlayLabel:SetAnchor(TOP, overlayTex, BOTTOM, 0, math.floor(OVERLAY_ROW_GAP_NORMAL * s + 0.5))

    local sideExtent, sideSlotSize = AplicarLayoutSlotsLaterales(texPx)

    -- Tres iconos centrados bajo overlayLabel (@ZuriPlayer), distribuidos uniformemente.
    -- Sep = distancia centro-a-centro entre iconos adyacentes.
    local allyScale
    if s < 1 then
        allyScale = 1 - ((1 - s) * ALLY_ICON_SCALE_WEIGHT_DOWN)
    else
        allyScale = 1 + ((s - 1) * ALLY_ICON_SCALE_WEIGHT_UP)
    end
    local dotSize = math.max(18, math.floor(ALLY_ICON_BASE_SIZE * allyScale + 0.5))
    if overlayLabel then
        local sep     = math.max(20, math.floor(28 * s + 0.5))
        local offsetY = math.floor(6 * s + 0.5)
        local dots = {
            { ctrl = overlayPetDot,       x = -sep },
            { ctrl = overlayCompanionDot, x =  0 },
            { ctrl = overlayAssistantDot, x =  sep },
        }
        for _, d in ipairs(dots) do
            if d.ctrl then
                d.ctrl:SetDimensions(dotSize, dotSize)
                d.ctrl:ClearAnchors()
                d.ctrl:SetAnchor(TOP, overlayLabel, BOTTOM, d.x, offsetY)
            end
        end
    end

    if overlayWin then
        local margin   = math.max(16, math.floor(SIDE_SLOT_MARGIN * s + 0.5))
        local halfW    = math.max(math.floor(texPx * 0.5 + 0.5), sideExtent) + margin
        local totalH   =
            OVERLAY_TOP_PADDING +
            guildPx +
            math.floor(OVERLAY_ROW_GAP_SMALL * s + 0.5) +
            texPx +
            math.floor(OVERLAY_ROW_GAP_NORMAL * s + 0.5) +
            playerPx +
            math.floor(OVERLAY_ROW_GAP_NORMAL * s + 0.5) +
            math.max(dotSize, sideSlotSize) +
            math.floor(OVERLAY_BOTTOM_PADDING * s + 0.5)
        overlayWin:SetDimensions(math.max(256, halfW * 2), math.max(256, totalH))
    end
end

-- Crea los controles de la ventana si aún no existen
local function AsegurarControles()
    if overlayWin then return end

    overlayWin = WINDOW_MANAGER:CreateTopLevelWindow("EZOToolsOverlayWin")
    overlayWin:SetClampedToScreen(true)
    overlayWin:SetDimensions(256, 256)
    overlayWin:SetTopmost(false)
    overlayWin:SetDrawLayer(DL_BACKGROUND)
    overlayWin:SetDrawTier(DT_LOW)
    AplicarPosicion()
    AplicarEstadoBloqueo()

    -- Textura del logo
    overlayTex = WINDOW_MANAGER:CreateControl("$(parent)Tex", overlayWin, CT_TEXTURE)
    overlayTex:SetAnchor(CENTER, overlayWin, CENTER, 0, 10)
    RefrescarTexturaLogoCentral()

    -- Etiqueta de texto bajo el logo
    overlayLabel = WINDOW_MANAGER:CreateControl("$(parent)Label", overlayWin, CT_LABEL)
    overlayLabel:SetFont(CadenaFuente(BASE_FONT_PC))
    overlayLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    do
        local r, g, b, a = ObtenerColorOverlay(
            EZO.sv and EZO.sv.overlay and EZO.sv.overlay.playerTextColor,
            { 1, 1, 1, 1 }
        )
        overlayLabel:SetColor(r, g, b, a)
    end

    -- Etiqueta de guild encima del logo
    overlayGuildLabel = WINDOW_MANAGER:CreateControl("$(parent)Guild", overlayWin, CT_LABEL)
    overlayGuildLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    -- Color gris claro discreto; rojo cuando no hay guild seleccionada
    overlayGuildLabel:SetColor(0.7, 0.7, 0.7, 1)

    -- Crea un icono sencillo a partir de una lista de texturas; queda oculto por defecto.
    local function CrearIcono(nombre, texturas)
        local ctrl = WINDOW_MANAGER:CreateControl(nombre, overlayWin, CT_TEXTURE)
        ctrl:SetDimensions(28, 28)
        ctrl:SetMouseEnabled(false)
        for _, ruta in ipairs(texturas) do
            ctrl:SetTexture(ruta)
            if ctrl:IsTextureLoaded() then break end
        end
        ctrl:SetColor(1, 0.15, 0.15, 1)  -- rojo advertencia
        ctrl:SetHidden(true)
        return ctrl
    end

    local function EjecutarClickIconoAliado(estaActivoFn, ocultarFn, invocarFn, msgOcultarId, msgInvocarId)
        local activo = estaActivoFn()
        if EZO and type(EZO.Print) == "function" then
            EZO.Print(GetString(activo and msgOcultarId or msgInvocarId))
        end

        local ok = false
        if activo then
            ok = ocultarFn()
        else
            ok = invocarFn()
        end
        if ok then
            ProgramarRefrescoDots()
        end
        return ok
    end

    -- Icono reparación armadura
    -- inventory_tabicon_armor_up.dds: tab de armadura del inventario (verificado en wiki.esoui.com)
    overlayMaintDot = CrearIcono("EZOTools_MaintDot", {
        "/esoui/art/inventory/inventory_tabicon_armor_up.dds",
        "/esoui/art/icons/achievements_indexicon_crafting_up.dds",
    })

    -- Icono comida/bebida
    -- crafting/provisioning_indexicon_food: icono específico de provisioning comida
    -- (verificado en AdvancedFilters y fuente oficial esoui/esoui)
    overlayFoodDot = CrearIcono("EZOTools_FoodDot", {
        "/esoui/art/crafting/provisioning_indexicon_food_up.dds",
        "/esoui/art/crafting/provisioning_tabicon_food_up.dds",
        "/esoui/art/inventory/inventory_tabIcon_Craftbag_provisioning_up.dds",
    })

    -- Icono recarga armas (soul gems)
    -- crafting/enchantment_tabicon_potency_up.dds: icono de encantamiento/gemas
    -- (verificado en AdvancedFilters, fuente oficial esoui/esoui)
    overlayChargeDot = CrearIcono("EZOTools_ChargeDot", {
        "/esoui/art/crafting/enchantment_tabicon_potency_up.dds",
        "/esoui/art/inventory/inventory_tabicon_weapons_up.dds",
    })

    -- Icono mascota: preferimos iconos de categoría del juego, sin tinte, para mantener
    -- un estilo más coherente con el resto de avisos del overlay.
    overlayPetDot = CrearIcono("EZOToolsPetDot2", {
        "/esoui/art/treeicons/collections_indexicon_noncombatpets_up.dds",
        "/esoui/art/treeicons/store_indexicon_vanitypets_up.dds",
        "/esoui/art/icons/pet_009.dds",
    })
    overlayPetDot:SetColor(1, 1, 1, 1)
    overlayPetDot:SetAnchor(TOP, overlayLabel, BOTTOM, -56, 6)

    -- Icono del compañero activo.
    overlayCompanionDot = CrearIcono("EZOToolsCompDot2", {
        "/esoui/art/treeicons/collections_indexicon_companions_up.dds",
        "/esoui/art/hud/loothistory_bonusdropsourceicon_companion.dds",
    })
    overlayCompanionDot:SetColor(1, 1, 1, 1)
    overlayCompanionDot:SetAnchor(TOP, overlayLabel, BOTTOM, 0, 6)

    -- Icono del asistente activo (banquero, mercader, desguazador, etc.).
    overlayAssistantDot = CrearIcono("EZOToolsAssistDot2", {
        "/esoui/art/treeicons/gamepad/gp_collection_indexicon_assistants.dds",
        "/esoui/art/treeicons/store_indexicon_assistants_up.dds",
    })
    overlayAssistantDot:SetColor(1, 1, 1, 1)
    overlayAssistantDot:SetAnchor(TOP, overlayLabel, BOTTOM, 56, 6)

    -- Guardar posición al terminar de mover
    overlayWin:SetHandler("OnMoveStop", function()
        EZO.sv.overlay.x = math.floor(overlayWin:GetLeft() + 0.5)
        EZO.sv.overlay.y = math.floor(overlayWin:GetTop() + 0.5)
    end)

    AsegurarTooltipWidget()

    local function ObtenerDefinicionesIconosAliados()
        return {
            {
                tipo = "pet",
                ctrl = overlayPetDot,
                activoFn = function() return ObtenerMascotaActivaId() ~= 0 end,
                ocultarFn = OcultarMascotaActiva,
                invocarFn = InvocarMascotaRecordada,
                msgOcultarId = EZO_MSG_HIDE_PET,
                msgInvocarId = EZO_MSG_SUMMON_PET,
            },
            {
                tipo = "companion",
                ctrl = overlayCompanionDot,
                activoFn = function() return ObtenerCompanionActivoCollectibleId() ~= 0 end,
                ocultarFn = OcultarCompanionActivo,
                invocarFn = InvocarCompanionRecordado,
                msgOcultarId = EZO_MSG_HIDE_COMPANION,
                msgInvocarId = EZO_MSG_SUMMON_COMPANION,
            },
            {
                tipo = "assistant",
                ctrl = overlayAssistantDot,
                activoFn = function() return ObtenerAssistantActivoId() ~= 0 end,
                ocultarFn = OcultarAsistenteActivo,
                invocarFn = InvocarAsistenteRecordada,
                msgOcultarId = EZO_MSG_HIDE_ASSISTANT,
                msgInvocarId = EZO_MSG_SUMMON_ASSISTANT,
            },
        }
    end

    local function RefrescarTooltipAliados(forzar)
        if not EstanActivosLosTooltipsContextuales() then
            if overlayAllyTooltipActive then
                OcultarTooltipWidget()
            end
            return
        end
        if not (overlayWin and not overlayWin:IsHidden() and type(MouseIsOver) == "function") then
            if overlayAllyTooltipActive then
                OcultarTooltipWidget()
            end
            return
        end

        if overlaySideWidgetTooltipActive then
            return
        end

        if not forzar and type(GetFrameTimeMilliseconds) == "function" then
            local nowMs = GetFrameTimeMilliseconds()
            if (nowMs - overlayAllyTooltipLastRefreshMs) < ALLY_TOOLTIP_REFRESH_MS then
                return
            end
            overlayAllyTooltipLastRefreshMs = nowMs
        end

        for _, icono in ipairs(ObtenerDefinicionesIconosAliados()) do
            if icono.ctrl and not icono.ctrl:IsHidden() and MouseIsOver(icono.ctrl) then
                MostrarTooltipTextoSobreControl(icono.ctrl, ObtenerTooltipIconoAliado(icono.tipo, icono.activoFn()))
                return
            end
        end

        if overlayAllyTooltipActive then
            OcultarTooltipWidget()
        end
    end

    overlayWin:SetHandler("OnMouseMove", function()
        RefrescarTooltipAliados(true)
    end)
    overlayWin:SetHandler("OnUpdate", function()
        RefrescarTooltipAliados()
        if not (overlayWin and not overlayWin:IsHidden()) then
            return
        end
        if not NecesitaPulsoComida() then
            return
        end
        if type(GetFrameTimeMilliseconds) ~= "function" then
            return
        end
        local nowMs = GetFrameTimeMilliseconds()
        if (nowMs - overlayFoodPulseLastRefreshMs) < FOOD_PULSE_REFRESH_MS then
            return
        end
        overlayFoodPulseLastRefreshMs = nowMs
        AplicarPulsoWidgetComida()
    end)

    overlayWin:SetHandler("OnMouseUp", function(_, button, upInside)
        if upInside and type(MouseIsOver) == "function" then
            for _, icono in ipairs(ObtenerDefinicionesIconosAliados()) do
                if icono.ctrl and not icono.ctrl:IsHidden() and MouseIsOver(icono.ctrl) then
                    if button == MOUSE_BUTTON_INDEX_LEFT then
                        EjecutarClickIconoAliado(
                            icono.activoFn,
                            icono.ocultarFn,
                            icono.invocarFn,
                            icono.msgOcultarId,
                            icono.msgInvocarId
                        )
                    elseif button == MOUSE_BUTTON_INDEX_RIGHT then
                        AbrirMenuHistorialAliado(icono.ctrl, icono.tipo)
                    end
                    return
                end
            end
        end
        if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
            if EZOTools_ContextMenu and EZOTools_ContextMenu.OpenMouse then
                EZOTools_ContextMenu.OpenMouse(overlayWin)
            end
        end
    end)
end

-- Actualiza la visibilidad del overlay según las opciones activas
local function ActualizarVisibilidad()
    local oculto = (not EZO.sv.overlay.enabled)
        or (EZO.sv.overlay.hideInCombat and enCombate)
    if EZO.sv.overlay.hideInMenus and not EsEscenaHUD() then
        oculto = true
    end
    overlayWin:SetHidden(oculto)
    if oculto then
        OcultarTooltipWidget()
    end
end

-- API pública: bloquear/desbloquear posición
function MOD.SetLocked(v)
    EZO.sv.overlay.locked = v and true or false
    AplicarEstadoBloqueo()
end

-- API pública: reiniciar posición al centro
function MOD.ResetPosition()
    EZO.sv.overlay.x = nil
    EZO.sv.overlay.y = nil
    AplicarPosicion()
end

-- Devuelve true si el jugador tiene buff de comida o bebida activo.
-- Verificado en juego con datos reales:
--   comida larga duración → abil=0, canClickOff=true  (ej: All Primary Stat Recovery)
--   comida evento/especial → abil=5, canClickOff=true  (ej: Eye Scream Halloween)
--   buffs pasivos permanentes → canClickOff=false siempre (ej: Boon: The Thief)
-- Regla: canClickOff=true + endTime>0 es exclusivo de comida/bebida.
local function TieneBuffComida()
    return ObtenerInfoBuffComida().active == true
end

-- Mascota vanity activa (sin requisito de grupo para pruebas)
local function TieneMascotaEnGrupo()
    -- TODO: restaurar "if GetGroupSize() <= 1 then return false end" tras pruebas
    local petId = GetActiveCollectibleByType(
        COLLECTIBLE_CATEGORY_TYPE_VANITY_PET,
        GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    return petId ~= nil and petId ~= 0
end

ObtenerMascotaActivaId = function()
    if type(GetActiveCollectibleByType) ~= "function" then
        return 0
    end
    return GetActiveCollectibleByType(
        COLLECTIBLE_CATEGORY_TYPE_VANITY_PET,
        GAMEPLAY_ACTOR_CATEGORY_PLAYER) or 0
end

ObtenerAssistantActivoId = function()
    if type(GetActiveCollectibleByType) ~= "function" then
        return 0
    end
    return GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_ASSISTANT) or 0
end

ObtenerCompanionActivoCollectibleId = function()
    if not (HasActiveCompanion and HasActiveCompanion()) then
        return 0
    end
    if type(GetActiveCompanionDefId) ~= "function"
        or type(GetCompanionCollectibleId) ~= "function" then
        return 0
    end
    local companionId = GetActiveCompanionDefId()
    if not companionId or companionId == 0 then
        return 0
    end
    return GetCompanionCollectibleId(companionId) or 0
end

local function GuardarCollectibleRecordado(clave, collectibleId)
    if not (EZO and EZO.sv and EZO.sv.overlay) then return end
    collectibleId = tonumber(collectibleId) or 0
    if collectibleId > 0 then
        EZO.sv.overlay[clave] = collectibleId
    end
end

local function GuardarCollectibleEnHistorial(clave, collectibleId)
    if not (EZO and EZO.sv and EZO.sv.overlay) then return end
    collectibleId = tonumber(collectibleId) or 0
    if collectibleId <= 0 then
        return
    end

    local history = EZO.sv.overlay[clave]
    if type(history) ~= "table" then
        history = {}
        EZO.sv.overlay[clave] = history
    end

    local newHistory = { collectibleId }
    for _, entryId in ipairs(history) do
        local value = tonumber(entryId) or 0
        if value > 0 and value ~= collectibleId then
            newHistory[#newHistory + 1] = value
        end
        if #newHistory >= 5 then
            break
        end
    end

    EZO.sv.overlay[clave] = newHistory
end

local function ObtenerHistorialCollectibles(clave)
    if not (EZO and EZO.sv and EZO.sv.overlay) then
        return {}
    end
    local history = EZO.sv.overlay[clave]
    if type(history) ~= "table" then
        return {}
    end
    return history
end

local function ObtenerCollectibleRecordado(clave)
    if not (EZO and EZO.sv and EZO.sv.overlay) then return 0 end
    local collectibleId = tonumber(EZO.sv.overlay[clave]) or 0
    if collectibleId < 0 then return 0 end
    return collectibleId
end

local function InvocarCollectibleRecordado(clave)
    if type(UseCollectible) ~= "function" then
        return false
    end
    local collectibleId = ObtenerCollectibleRecordado(clave)
    if collectibleId == 0 then
        return false
    end
    UseCollectible(collectibleId)
    return true
end

local function InvocarCollectiblePorId(collectibleId)
    if type(UseCollectible) ~= "function" then
        return false
    end
    collectibleId = tonumber(collectibleId) or 0
    if collectibleId == 0 then
        return false
    end
    UseCollectible(collectibleId)
    return true
end

local function ProgramarInvocacionCollectible(clave, retrasoMs)
    if type(UseCollectible) ~= "function" then
        return false
    end
    local collectibleId = ObtenerCollectibleRecordado(clave)
    if collectibleId == 0 then
        return false
    end
    local delay = math.max(0, tonumber(retrasoMs) or 0)
    if delay > 0 and type(zo_callLater) == "function" then
        zo_callLater(function()
            UseCollectible(collectibleId)
        end, delay)
    else
        UseCollectible(collectibleId)
    end
    return true
end

local function ProgramarInvocacionCollectiblePorId(collectibleId, retrasoMs)
    if type(UseCollectible) ~= "function" then
        return false
    end
    collectibleId = tonumber(collectibleId) or 0
    if collectibleId == 0 then
        return false
    end
    local delay = math.max(0, tonumber(retrasoMs) or 0)
    if delay > 0 and type(zo_callLater) == "function" then
        zo_callLater(function()
            UseCollectible(collectibleId)
        end, delay)
    else
        UseCollectible(collectibleId)
    end
    return true
end

local function ProgramarCambioEntreAliados(claveDestino, sigueActivoFn, ocultarActivoFn, collectibleIdDestino)
    if allySwitchPending then
        return false
    end
    if type(ocultarActivoFn) ~= "function" or type(sigueActivoFn) ~= "function" then
        return false
    end
    if not ocultarActivoFn() then
        return false
    end
    allySwitchPending = true

    local function IntentarInvocarRestante(intentos)
        if sigueActivoFn() then
            if intentos > 0 and type(zo_callLater) == "function" then
                zo_callLater(function()
                    IntentarInvocarRestante(intentos - 1)
                end, ALLY_SWITCH_RETRY_DELAY_MS)
            else
                allySwitchPending = false
            end
            return
        end
        if collectibleIdDestino and collectibleIdDestino ~= 0 then
            ProgramarInvocacionCollectiblePorId(collectibleIdDestino, 100)
        else
            ProgramarInvocacionCollectible(claveDestino, 100)
        end
        allySwitchPending = false
    end

    if type(zo_callLater) == "function" then
        zo_callLater(function()
            IntentarInvocarRestante(ALLY_SWITCH_MAX_RETRIES)
        end, ALLY_SWITCH_INITIAL_DELAY_MS)
    else
        IntentarInvocarRestante(0)
    end
    return true
end

local function AplicarEstadoVisualIconoAliado(ctrl, activo, collectibleId)
    if not ctrl then return end

    if collectibleId and collectibleId ~= 0 and type(GetCollectibleIcon) == "function" then
        local icon = GetCollectibleIcon(collectibleId)
        if type(icon) == "string" and icon ~= "" then
            ctrl:SetTexture(icon)
        end
    end

    local alpha = activo and 1 or ALLY_ICON_INACTIVE_ALPHA
    ctrl:SetColor(1, 1, 1, alpha)
    ctrl:SetAlpha(alpha)
end

local function RefrescarEstadoIconoAliado(ctrl, activeId, rememberedKey)
    if activeId ~= 0 then
        GuardarCollectibleRecordado(rememberedKey, activeId)
        local tipo = nil
        for allyType, cfg in pairs(ALLY_ICON_MENU_CONFIG or {}) do
            if cfg.rememberedKey == rememberedKey then
                tipo = allyType
                break
            end
        end
        local config = tipo and ObtenerConfiguracionAliado(tipo) or nil
        if config then
            GuardarCollectibleEnHistorial(config.historyKey, activeId)
        end
    end
    local collectibleId = (activeId ~= 0) and activeId or ObtenerCollectibleRecordado(rememberedKey)
    if not ctrl then
        return
    end
    local visible = collectibleId ~= 0
    ctrl:SetHidden(not visible)
    if visible then
        AplicarEstadoVisualIconoAliado(ctrl, activeId ~= 0, collectibleId)
    end
end

local function InvocarAliadoDesdeHistorial(tipo, collectibleId)
    local config = ObtenerConfiguracionAliado(tipo)
    if not config then
        return false
    end

    collectibleId = tonumber(collectibleId) or 0
    if collectibleId == 0 then
        return false
    end

    GuardarCollectibleRecordado(config.rememberedKey, collectibleId)
    GuardarCollectibleEnHistorial(config.historyKey, collectibleId)

    if tipo == "pet" then
        return InvocarCollectiblePorId(collectibleId)
    end
    if tipo == "companion" then
        if ObtenerAssistantActivoId() ~= 0 then
            return ProgramarCambioEntreAliados(
                config.rememberedKey,
                function() return ObtenerAssistantActivoId() ~= 0 end,
                OcultarAsistenteActivo,
                collectibleId
            )
        end
        return InvocarCollectiblePorId(collectibleId)
    end
    if tipo == "assistant" then
        if ObtenerCompanionActivoCollectibleId() ~= 0 then
            return ProgramarCambioEntreAliados(
                config.rememberedKey,
                function() return ObtenerCompanionActivoCollectibleId() ~= 0 end,
                OcultarCompanionActivo,
                collectibleId
            )
        end
        return InvocarCollectiblePorId(collectibleId)
    end
    return false
end

AbrirMenuHistorialAliado = function(anchor, tipo)
    local config = ObtenerConfiguracionAliado(tipo)
    if not config then
        return
    end

    local entries = {}
    for _, collectibleId in ipairs(ObtenerHistorialCollectibles(config.historyKey)) do
        local finalId = tonumber(collectibleId) or 0
        if finalId > 0 then
            local label = tostring(ObtenerNombreCollectible(finalId, GetString(config.fallbackNameId)) or "")
            if label ~= "" then
                entries[#entries + 1] = {
                    label = label,
                    onEnter = function(control)
                        MostrarTooltipCollectibleSobreControl(control, finalId, GetString(config.fallbackNameId))
                    end,
                    onExit = function()
                        if type(ClearTooltip) == "function" and (InformationTooltip or overlayWidgetTooltipWin) then
                            OcultarTooltipWidget()
                        end
                    end,
                    onSelect = function()
                        InvocarAliadoDesdeHistorial(tipo, finalId)
                    end,
                }
            end
        end
    end

    AbrirMenuRecientes(anchor, entries, GetString(config.historyEmptyId))
end

ObtenerTooltipIconoAliado = function(tipo, activo)
    local collectibleId = 0
    local fallbackName = nil

    if tipo == "pet" then
        collectibleId = activo and ObtenerMascotaActivaId() or ObtenerCollectibleRecordado("lastPetCollectibleId")
        fallbackName = GetString(EZO_DOT_PET_FALLBACK_NAME)
    elseif tipo == "companion" then
        collectibleId = activo and ObtenerCompanionActivoCollectibleId() or ObtenerCollectibleRecordado("lastCompanionCollectibleId")
        fallbackName = GetString(EZO_DOT_COMPANION_FALLBACK_NAME)
    elseif tipo == "assistant" then
        collectibleId = activo and ObtenerAssistantActivoId() or ObtenerCollectibleRecordado("lastAssistantCollectibleId")
        fallbackName = GetString(EZO_DOT_ASSISTANT_FALLBACK_NAME)
    end

    local nombre = ObtenerNombreCollectible(collectibleId, fallbackName)
    if tipo == "pet" then
        return zo_strformat(GetString(activo and EZO_DOT_PET_ACTIVE_TOOLTIP or EZO_DOT_PET_INACTIVE_TOOLTIP), nombre)
    end
    if tipo == "companion" then
        return zo_strformat(GetString(activo and EZO_DOT_COMPANION_ACTIVE_TOOLTIP or EZO_DOT_COMPANION_INACTIVE_TOOLTIP), nombre)
    end
    if tipo == "assistant" then
        return zo_strformat(GetString(activo and EZO_DOT_ASSISTANT_ACTIVE_TOOLTIP or EZO_DOT_ASSISTANT_INACTIVE_TOOLTIP), nombre)
    end
    return nil
end

OcultarMascotaActiva = function()
    if type(GetActiveCollectibleByType) ~= "function" or type(UseCollectible) ~= "function" then
        return false
    end
    local petId = ObtenerMascotaActivaId()
    if not petId or petId == 0 then
        return false
    end
    UseCollectible(petId)
    return true
end

TieneAsistenteActivo = function()
    local assistId = ObtenerAssistantActivoId()
    return assistId ~= nil and assistId ~= 0
end

-- Devuelve si hay un compañero activo.
local function TieneCompanionActivo()
    return HasActiveCompanion and HasActiveCompanion() or false
end

OcultarCompanionActivo = function()
    if HasActiveCompanion and HasActiveCompanion() then
        if type(UseCollectible) == "function" then
            local collectibleId = ObtenerCompanionActivoCollectibleId()
            if collectibleId ~= 0 then
                UseCollectible(collectibleId)
                return true
            end
        end
        if type(DismissCompanion) == "function" then
            DismissCompanion()
            return true
        end
        return false
    end
    return false
end

OcultarAsistenteActivo = function()
    if type(GetActiveCollectibleByType) ~= "function" or type(UseCollectible) ~= "function" then
        return false
    end
    local assistId = ObtenerAssistantActivoId()
    if not assistId or assistId == 0 then
        return false
    end
    UseCollectible(assistId)
    return true
end

InvocarMascotaRecordada = function()
    return InvocarCollectibleRecordado("lastPetCollectibleId")
end

InvocarCompanionRecordado = function()
    if ObtenerAssistantActivoId() ~= 0 then
        return ProgramarCambioEntreAliados(
            "lastCompanionCollectibleId",
            function() return ObtenerAssistantActivoId() ~= 0 end,
            OcultarAsistenteActivo
        )
    end
    return InvocarCollectibleRecordado("lastCompanionCollectibleId")
end

InvocarAsistenteRecordada = function()
    if ObtenerCompanionActivoCollectibleId() ~= 0 then
        return ProgramarCambioEntreAliados(
            "lastAssistantCollectibleId",
            function() return ObtenerCompanionActivoCollectibleId() ~= 0 end,
            OcultarCompanionActivo
        )
    end
    return InvocarCollectibleRecordado("lastAssistantCollectibleId")
end

RefrescarDot = function()
    if overlayMaintDot then overlayMaintDot:SetHidden(true) end
    if overlayChargeDot then overlayChargeDot:SetHidden(true) end
    if overlayFoodDot then overlayFoodDot:SetHidden(true) end

    local petId = ObtenerMascotaActivaId()
    RefrescarEstadoIconoAliado(overlayPetDot, petId, "lastPetCollectibleId")

    local companionCollectibleId = ObtenerCompanionActivoCollectibleId()
    RefrescarEstadoIconoAliado(overlayCompanionDot, companionCollectibleId, "lastCompanionCollectibleId")

    local assistId = ObtenerAssistantActivoId()
    RefrescarEstadoIconoAliado(overlayAssistantDot, assistId, "lastAssistantCollectibleId")

    RefrescarWidgetsLateralesEstado()
end

ProgramarRefrescoDots = function()
    RefrescarDot()
    if type(zo_callLater) == "function" then
        zo_callLater(function()
            RefrescarDot()
        end, 500)
        zo_callLater(function()
            RefrescarDot()
        end, 1500)
    end
end

-- API pública: refresco completo del overlay (posición, apariencia, visibilidad)
function MOD.Refresh()
    AsegurarControles()
    AplicarPosicion()
    AplicarEstadoBloqueo()
    local a = 1
    overlayWin:SetAlpha(a)
    overlayTex:SetAlpha(a)
    overlayLabel:SetAlpha(a)
    overlayLabel:SetText(ObtenerTextoOverlay())
    do
        local r, g, b, alpha = ObtenerColorOverlay(
            EZO.sv and EZO.sv.overlay and EZO.sv.overlay.playerTextColor,
            { 1, 1, 1, 1 }
        )
        overlayLabel:SetColor(r, g, b, alpha)
    end
    RefrescarTexturaLogoCentral()
    RefrescarEtiquetaGuild()
    AplicarEscalaVisual()
    RefrescarDot()
    ActualizarVisibilidad()
end

-- API pública: mostrar/ocultar overlay
function MOD.Toggle()
    EZO.sv.overlay.enabled = not EZO.sv.overlay.enabled
    MOD.Refresh()
end

-- Refresca solo el dot de mantenimiento — llamado con delay tras activar jugador

-- API pública: permite refrescar el dot desde fuera del módulo (EZOTools.lua)
function MOD.RefreshDot()
    RefrescarDot()
end

-- Inicialización: crea controles, registra eventos
function MOD.Init()
    AsegurarControles()
    MOD.Refresh()
    SincronizarCacheConsumiblesComidaMochila()

    -- Refrescar fuente al cambiar modo gamepad/teclado
    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Font",
        EVENT_GAMEPAD_PREFERRED_MODE_CHANGED,
        function() AplicarEscalaVisual() end)

    -- Actualizar visibilidad al entrar/salir de combate
    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Combat",
        EVENT_PLAYER_COMBAT_STATE,
        function(_, estado)
            enCombate = estado
            if overlayWin then
                ActualizarVisibilidad()
                -- Al salir de combate refrescar el dot: puede que ahora haya que reparar/recargar
                RefrescarDot()
            end
        end)

    -- Actualizar bloqueo y visibilidad al cambiar de escena
    SCENE_MANAGER:RegisterCallback("SceneStateChanged", function()
        AplicarEstadoBloqueo()
        ActualizarVisibilidad()
    end)

    -- Refresco inicial de guild al cargar datos
    -- Mascota vanity y companion: refresco reactivo
    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Pet",
        EVENT_COLLECTIBLE_USE_RESULT,
        function()
            ProgramarRefrescoDots()
        end)

    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Companion",
        EVENT_ACTIVE_COMPANION_STATE_CHANGED,
        function()
            ProgramarRefrescoDots()
        end)

    -- Cambio de tamaño de grupo: afecta al icono de mascota
    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Group",
        EVENT_GROUP_MEMBER_LEFT,
        function()
            RefrescarDot()
        end)
    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_GroupJoin",
        EVENT_GROUP_MEMBER_JOINED,
        function()
            RefrescarDot()
        end)

    -- Buff comida/bebida: refresco reactivo al ganar o perder cualquier efecto
    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Food",
        EVENT_EFFECT_CHANGED,
        function(_, changeType, _, _, unitTag, _, _, _, _, _, abilityType)
            if unitTag == "player" and abilityType == ABILITY_TYPE_NONCOMBATBONUS then
                if changeType == EFFECT_RESULT_GAINED or changeType == EFFECT_RESULT_UPDATED or changeType == EFFECT_RESULT_FULL_REFRESH then
                    RecordarComidaActiva()
                end
                RefrescarDot()
            end
        end)

    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Guild",
        EVENT_GUILD_DATA_LOADED,
        function()
            cachedRepresentedGuildId = nil  -- forzar refresco
            if EZO and type(EZO.ApplyAutoFriendHousesSelection) == "function" then
                EZO.ApplyAutoFriendHousesSelection()
            end
            if overlayWin then RefrescarEtiquetaGuild() end
        end)

    -- Detectar equipar/desequipar tabardo en tiempo real.
    -- EVENT_INVENTORY_SINGLE_SLOT_UPDATE: tabardo → guild label, equipo → dot mantenimiento
    local SLOT_TABARD_EVENT = EQUIP_SLOT_TABARD or 10
    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Tabard",
        EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
        function(_, bag, slot, _, _, _, stackCountChange)
            if bag == BAG_WORN then
                -- Tabardo: refrescar guild
                if slot == SLOT_TABARD_EVENT then
                    RefrescarEtiquetaGuild()
                end
                -- Cualquier cambio en equipo equipado: refrescar dot mantenimiento
                RefrescarDot()
            elseif bag == BAG_BACKPACK then
                local previousEntry = overlayFoodBackpackCache[slot]
                RegistrarConsumoComidaPendiente(previousEntry, stackCountChange)
                ActualizarCacheConsumibleComidaMochila(slot)
                -- Equipar/desequipar desde mochila también puede cambiar el estado
                RefrescarDot()
            end
        end)

    -- Timer unificado cada 5s: cubre todos los estados que no tienen evento propio.
    -- - Durabilidad armadura en combate
    -- - Cambios de guild representada (selector C)
    -- - Estado general de iconos como red de seguridad
    local function TickEstado()
        if overlayWin and not overlayWin:IsHidden() then
            -- Iconos de mantenimiento
            RefrescarDot()
            -- Guild representada (no hay evento para SetRepresentedGuildId)
            if type(GetRepresentedGuildId) == "function" then
                local guildId = GetRepresentedGuildId()
                if guildId ~= cachedRepresentedGuildId then
                    cachedRepresentedGuildId = guildId
                    RefrescarEtiquetaGuild()
                end
            end
        end
        zo_callLater(TickEstado, 5000)
    end
    zo_callLater(TickEstado, 3000)  -- primer tick a los 3s
end

-- ============================================================
-- Secciones para el panel LAM (se registran si LAM está cargado)
-- ============================================================
if EZOTools_LAM and EZOTools_LAM.RegisterSection then

    -- Sección: opciones generales
    EZOTools_LAM.RegisterSection("general", 1, function()
        local EZO = EZOTools
        return {
            { type = "header", name = GetString(EZO_OPTION_GENERAL) },
            {
                type         = "dropdown",
                name         = GetString(EZO_OPTION_LANGUAGE),
                choices      = { "English", "Español" },
                choicesValues = { "en", "es" },
                getFunc      = function() return EZO.sv.general.language end,
                setFunc      = function(v)
                    EZO.sv.general.language = v
                    if EZO_Lang and EZO_Lang.Apply then EZO_Lang.Apply(v) end
                    EZOTools_Overlay.Refresh()
                end,
                width   = "half",
                tooltip = GetString(EZO_OPTION_LANGUAGE_TOOLTIP),
            },
        }
    end)

    -- Sección: opciones del overlay
    EZOTools_LAM.RegisterSection("overlay", 10, function()
        local EZO = EZOTools
        return {
            { type = "header", name = GetString(EZO_OPTION_OVERLAY) },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_OVERLAY_ENABLE),
                getFunc = function() return EZO.sv.overlay.enabled end,
                setFunc = function(v) EZO.sv.overlay.enabled = v; EZOTools_Overlay.Refresh() end,
                default = true,
            },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_OVERLAY_LOCK),
                getFunc = function() return EZO.sv.overlay.locked end,
                setFunc = function(v) EZOTools_Overlay.SetLocked(v); EZOTools_Overlay.Refresh() end,
                default = false,
            },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_OVERLAY_SIMULATE_GAMEPAD),
                getFunc = function() return EZO.sv.overlay.simulateGamepad end,
                setFunc = function(v) EZO.sv.overlay.simulateGamepad = v; EZOTools_Overlay.Refresh() end,
                default = false,
            },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_OVERLAY_HIDE_COMBAT),
                getFunc = function() return EZO.sv.overlay.hideInCombat end,
                setFunc = function(v) EZO.sv.overlay.hideInCombat = v; EZOTools_Overlay.Refresh() end,
                default = false,
            },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_OVERLAY_HIDE_MENUS),
                getFunc = function() return EZO.sv.overlay.hideInMenus end,
                setFunc = function(v) EZO.sv.overlay.hideInMenus = v; EZOTools_Overlay.Refresh() end,
                default = false,
            },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_OVERLAY_CONTEXTUAL_TOOLTIPS),
                tooltip = GetString(EZO_OPTION_OVERLAY_CONTEXTUAL_TOOLTIPS_TOOLTIP),
                getFunc = function() return EZO.sv.overlay.contextualIconTooltips ~= false end,
                setFunc = function(v)
                    EZO.sv.overlay.contextualIconTooltips = v and true or false
                    EZOTools_Overlay.Refresh()
                end,
                default = true,
            },
            {
                type     = "slider",
                name     = GetString(EZO_OPTION_OVERLAY_SCALE),
                min      = 0.5, max = 2.0, step = 0.1,
                getFunc  = function() return EZO.sv.overlay.scale end,
                setFunc  = function(v) EZO.sv.overlay.scale = v; EZOTools_Overlay.Refresh() end,
                decimals = 2,
            },
            {
                type    = "colorpicker",
                name    = GetString(EZO_OPTION_OVERLAY_PLAYER_TEXT_COLOR),
                getFunc = function()
                    return ObtenerColorOverlay(EZO.sv.overlay.playerTextColor, { 1, 1, 1, 1 })
                end,
                setFunc = function(r, g, b, a)
                    EZO.sv.overlay.playerTextColor = { r, g, b, a or 1 }
                    EZOTools_Overlay.Refresh()
                end,
                default = { 1, 1, 1, 1 },
            },
            {
                type     = "slider",
                name     = GetString(EZO_OPTION_OVERLAY_PLAYER_TEXT_SIZE),
                min      = PLAYER_TEXT_SCALE_MIN, max = PLAYER_TEXT_SCALE_MAX, step = 0.05,
                getFunc  = function() return tonumber(EZO.sv.overlay.playerTextScale) or 1 end,
                setFunc  = function(v)
                    EZO.sv.overlay.playerTextScale = zo_clamp(tonumber(v) or 1, PLAYER_TEXT_SCALE_MIN, PLAYER_TEXT_SCALE_MAX)
                    EZOTools_Overlay.Refresh()
                end,
                default  = 1,
                decimals = 2,
            },
            {
                type       = "editbox",
                name       = GetString(EZO_OPTION_OVERLAY_TEXT),
                getFunc    = function() return ObtenerTextoOverlay() end,
                setFunc    = function(v)
                    if v == nil or (type(v) == "string" and v:match("^%s*$")) then
                        EZO.sv.overlay.text = nil
                    else
                        EZO.sv.overlay.text = v
                    end
                    EZOTools_Overlay.Refresh()
                end,
                isMultiline = false,
            },
            {
                type  = "button",
                name  = GetString(EZO_OPTION_OVERLAY_RESET_POS),
                func  = function() EZOTools_Overlay.ResetPosition(); EZOTools_Overlay.Refresh() end,
                width = "full",
            },
        }
    end)

    EZOTools_LAM.RegisterSection("guild_overlay", 15, function()
        local EZO = EZOTools
        return {
            { type = "header", name = GetString(EZO_OPTION_GUILD_OVERLAY) },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE),
                tooltip = GetString(EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE_TOOLTIP),
                getFunc = function() return EZO.sv.overlay.guildCustomImageEnabled == true end,
                setFunc = function(v)
                    EZO.sv.overlay.guildCustomImageEnabled = v
                    EZOTools_Overlay.Refresh()
                end,
                default = true,
            },
            {
                type    = "colorpicker",
                name    = GetString(EZO_OPTION_GUILD_LABEL_COLOR),
                tooltip = GetString(EZO_OPTION_GUILD_LABEL_COLOR_TOOLTIP),
                getFunc = function()
                    return ObtenerColorOverlay(EZO.sv.overlay.guildLabelColor, { 0.7, 0.7, 0.7, 1 })
                end,
                setFunc = function(r, g, b, a)
                    EZO.sv.overlay.guildLabelColor = { r, g, b, a or 1 }
                    EZOTools_Overlay.Refresh()
                end,
                default = { 0.7, 0.7, 0.7, 1 },
            },
        }
    end)

    EZOTools_LAM.RegisterSection("friend_houses", 20, function()
        local EZO = EZOTools
        return {
            { type = "header", name = GetString(EZO_OPTION_FRIENDS) },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_FRIENDS_AUTO_ASSIGN),
                tooltip = GetString(EZO_OPTION_FRIENDS_AUTO_ASSIGN_TOOLTIP),
                getFunc = function() return EZO.sv.friends.autoAssignFriendHouses == true end,
                setFunc = function(v)
                    EZO.sv.friends.autoAssignFriendHouses = v
                    if v and EZO.ApplyAutoFriendHousesSelection then
                        EZO.ApplyAutoFriendHousesSelection()
                    end
                end,
                default = true,
                disabled = function()
                    local choices = {}
                    if EZO.GetEligibleAutoFriendGuildChoices then
                        choices = EZO.GetEligibleAutoFriendGuildChoices()
                    end
                    return #choices == 0
                end,
            },
            {
                type         = "dropdown",
                name         = GetString(EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD),
                tooltip      = GetString(EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD_TOOLTIP),
                choices      = (function()
                    if EZO.GetEligibleAutoFriendGuildChoices then
                        local choices = EZO.GetEligibleAutoFriendGuildChoices()
                        return choices
                    end
                    return {}
                end)(),
                choicesValues = (function()
                    if EZO.GetEligibleAutoFriendGuildChoices then
                        local _, values = EZO.GetEligibleAutoFriendGuildChoices()
                        return values
                    end
                    return {}
                end)(),
                getFunc      = function() return EZO.sv.friends.autoAssignFriendGuildKey or "" end,
                setFunc      = function(v)
                    EZO.sv.friends.autoAssignFriendGuildKey = tostring(v or "")
                    if EZO.sv.friends.autoAssignFriendHouses == true and EZO.ApplyAutoFriendHousesSelection then
                        EZO.ApplyAutoFriendHousesSelection()
                    end
                end,
                default      = "",
                disabled     = function()
                    local choices = {}
                    if EZO.GetEligibleAutoFriendGuildChoices then
                        choices = EZO.GetEligibleAutoFriendGuildChoices()
                    end
                    return EZO.sv.friends.autoAssignFriendHouses ~= true or #choices == 0
                end,
            },
            {
                type  = "button",
                name  = GetString(EZO_OPTION_FRIENDS_SAVE_SELECTED),
                tooltip = GetString(EZO_OPTION_FRIENDS_SAVE_SELECTED_TOOLTIP),
                func  = function()
                    if EZO.SaveCurrentFriendHousesForSelectedGuild then
                        EZO.SaveCurrentFriendHousesForSelectedGuild()
                    end
                end,
                width = "full",
                disabled = function()
                    return not (EZO.sv and EZO.sv.friends and EZO.sv.friends.autoAssignFriendGuildKey and EZO.sv.friends.autoAssignFriendGuildKey ~= "")
                end,
            },
            {
                type        = "editbox",
                name        = GetString(EZO_OPTION_FRIENDS_CRAFTING),
                getFunc     = function() return EZO.sv.friends.craftingHall end,
                setFunc     = function(v) EZO.sv.friends.craftingHall = v end,
                isMultiline = false,
            },
            {
                type        = "editbox",
                name        = GetString(EZO_OPTION_FRIENDS_SECONDARY),
                getFunc     = function() return EZO.sv.friends.secondaryHall end,
                setFunc     = function(v) EZO.sv.friends.secondaryHall = v end,
                isMultiline = false,
            },
        }
    end)
end
