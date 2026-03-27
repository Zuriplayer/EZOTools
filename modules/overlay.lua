-- Módulo de overlay visual de EZOTools.
-- Gestiona la ventana flotante (logo + texto) que sirve como punto de acceso al menú.
-- El aviso de "Tabardo de Hermandad" ha sido eliminado (obsoleto desde Update 49:
-- el juego permite mostrar el escudo de hermandad sin llevar tabardo equipado,
-- por lo que la detección por BAG_WORN ya no es fiable).

EZOTools_Overlay = EZOTools_Overlay or {}
local MOD = EZOTools_Overlay
local EZO = EZOTools

-- Controles de la ventana (se crean en EnsureControls la primera vez)
local overlayWin, overlayTex, overlayLabel, overlayGuildLabel, overlayMaintDot, overlayChargeDot, overlayFoodDot, overlayPetDot, overlayCompanionDot
local overlaySideSlotsLeft, overlaySideSlotsRight = {}, {}
local overlaySideWidgetsLeft, overlaySideWidgetsRight = {}, {}
local overlaySideWidgetTexturesLeft, overlaySideWidgetTexturesRight = {}, {}
local overlaySideWidgetData = { left = {}, right = {} }
local overlayLayoutPreviewEnabled = false
local overlayWidgetTooltipWin, overlayWidgetTooltipBackdrop, overlayWidgetTooltipLabel

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
-- Tamaños base para calcular escala
local BASE_TEX         = 128   -- píxeles base de la textura del logo
local BASE_FONT_PC     = 20    -- tamaño de fuente base en modo teclado/ratón
local BASE_FONT_GP     = 32    -- tamaño de fuente base en modo gamepad
local GUILD_FONT_RATIO = 0.75  -- la fuente de guild es el 75% del tamaño del nombre del jugador

-- Genera la cadena de fuente ESO a partir de un tamaño en píxeles
local function CadenaFuente(px)
    px = math.max(10, math.floor(px))
    return string.format("$(BOLD_FONT)|%d|soft-shadow-thin", px)
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

-- Actualiza la etiqueta de guild en el overlay.
-- Lógica de prioridad:
--   1. Tabardo equipado → nombre de la guild del tabardo (amarillo discreto)
--   2. Guild representada en selector C → nombre en gris discreto
--   3. Ninguna → "Sin hermandad" / "No guild" en rojo
local function RefrescarEtiquetaGuild()
    if not overlayGuildLabel then return end

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
        overlayGuildLabel:SetColor(0.7, 0.7, 0.7, 1)  -- gris discreto
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
    if overlayWidgetTooltipWin then
        overlayWidgetTooltipWin:SetHidden(true)
    end
end

local function AsegurarTooltipWidget()
    if overlayWidgetTooltipWin then return end

    overlayWidgetTooltipWin = WINDOW_MANAGER:CreateTopLevelWindow("EZOToolsOverlayWidgetTooltip")
    overlayWidgetTooltipWin:SetDimensions(240, 64)
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
    overlayWidgetTooltipLabel:SetDimensions(220, 48)
    overlayWidgetTooltipLabel:SetFont(CadenaFuente(16))
    overlayWidgetTooltipLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    overlayWidgetTooltipLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    overlayWidgetTooltipLabel:SetColor(1, 1, 1, 1)
end

local function ConstruirTooltipPreviewWidget(side, index)
    return zo_strformat(
        GetString(EZO_SIDE_WIDGET_PREVIEW_TOOLTIP),
        ObtenerNombreLadoWidget(side),
        tostring(index))
end

local function ObtenerTooltipWidget(side, index, data)
    if type(data) ~= "table" then
        if overlayLayoutPreviewEnabled then
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

local function MostrarTooltipWidget(ctrl, side, index, data)
    local texto = ObtenerTooltipWidget(side, index, data)
    if not texto or texto == "" then
        OcultarTooltipWidget()
        return
    end

    AsegurarTooltipWidget()
    overlayWidgetTooltipLabel:SetText(texto)
    overlayWidgetTooltipWin:ClearAnchors()
    if side == "left" then
        overlayWidgetTooltipWin:SetAnchor(TOPRIGHT, ctrl, TOPLEFT, -8, -4)
    else
        overlayWidgetTooltipWin:SetAnchor(TOPLEFT, ctrl, TOPRIGHT, 8, -4)
    end
    overlayWidgetTooltipWin:SetHidden(false)
end

local function EjecutarAccionWidget(side, index, data)
    if type(data) ~= "table" or type(data.actionId) ~= "string" or data.actionId == "" then
        return
    end
    if not (EZOTools_ActionExec and type(EZOTools_ActionExec.Execute) == "function") then
        return
    end
    EZOTools_ActionExec.Execute(data.actionId, {
        source = "MOUSE",
        anchor = overlayWin,
        widgetSide = side,
        widgetIndex = index,
    })
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

local function AplicarWidgetsLaterales()
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
                    if button == MOUSE_BUTTON_INDEX_RIGHT then
                        if EZOTools_ContextMenu and EZOTools_ContextMenu.OpenMouse then
                            EZOTools_ContextMenu.OpenMouse(overlayWin)
                        end
                        return
                    end
                    if button == MOUSE_BUTTON_INDEX_LEFT then
                        EjecutarAccionWidget(widgetSide, widgetIndex, ObtenerRenderDataWidget(widgetSide, widgetIndex))
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
-- Aplica la escala visual al logo y la etiqueta de texto
local function AplicarEscalaVisual()
    if not overlayTex or not overlayLabel then return end
    local s      = tonumber(EZO.sv.overlay.scale) or 1
    local texPx  = math.max(64, math.floor(BASE_TEX * s + 0.5))
    overlayTex:SetDimensions(texPx, texPx)

    local esGP   = (EZO.sv.overlay.simulateGamepad or IsInGamepadPreferredMode())
    local basePx = esGP and BASE_FONT_GP or BASE_FONT_PC
    overlayLabel:SetFont(CadenaFuente(basePx * s))
    overlayLabel:ClearAnchors()
    overlayLabel:SetAnchor(TOP, overlayTex, BOTTOM, 0, math.floor(6 * s + 0.5))
    overlayLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    local guildPx = math.floor(basePx * GUILD_FONT_RATIO * s + 0.5)
    if overlayGuildLabel then
        overlayGuildLabel:SetFont(CadenaFuente(guildPx))
        overlayGuildLabel:ClearAnchors()
        -- Ancla: borde inferior de la guild = borde superior del logo con pequeño margen
        overlayGuildLabel:SetAnchor(BOTTOM, overlayTex, TOP, 0, -math.floor(4 * s + 0.5))
        overlayGuildLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    end

    local sideExtent, sideSlotSize = AplicarLayoutSlotsLaterales(texPx)

    -- Tres iconos centrados bajo overlayLabel (@ZuriPlayer), distribuidos uniformemente.
    -- Sep = distancia centro-a-centro entre iconos adyacentes.
    local dotSize = math.max(18, math.floor(24 * s + 0.5))
    if overlayLabel then
        local sep     = math.max(20, math.floor(28 * s + 0.5))
        local offsetY = math.floor(6 * s + 0.5)
        -- 5 iconos centrados bajo el label, separación uniforme
        -- Pet | Repair | Food | Charge | Companion
        local dots = {
            { ctrl = overlayPetDot,       x = -2 * sep },
            { ctrl = overlayMaintDot,     x = -sep     },
            { ctrl = overlayFoodDot,      x = 0        },
            { ctrl = overlayChargeDot,    x =  sep     },
            { ctrl = overlayCompanionDot, x =  2 * sep },
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
        local totalH   = texPx + guildPx + math.floor(basePx * s + 0.5) + math.max(dotSize, sideSlotSize) + math.floor(84 * s + 0.5)
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

    -- Probar rutas del logo en orden hasta que IsTextureLoaded() confirme que cargó.
    -- La ruta correcta varía según instalación (mayúsculas/minúsculas en "media").
    local rutasLogo = {
        "/AddOns/EZOTools/media/ezotools_logo.dds",
        "/AddOns/EZOTools/Media/ezotools_logo.dds",
        "EZOTools/media/ezotools_logo.dds",
        "EZOTools/Media/ezotools_logo.dds",
    }
    for _, ruta in ipairs(rutasLogo) do
        overlayTex:SetTexture(ruta)
        if overlayTex:IsTextureLoaded() then break end
    end

    -- Etiqueta de texto bajo el logo
    overlayLabel = WINDOW_MANAGER:CreateControl("$(parent)Label", overlayWin, CT_LABEL)
    overlayLabel:SetFont(CadenaFuente(BASE_FONT_PC))
    overlayLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    overlayLabel:SetColor(1, 1, 1, 1)

    -- Etiqueta de guild encima del logo
    overlayGuildLabel = WINDOW_MANAGER:CreateControl("$(parent)Guild", overlayWin, CT_LABEL)
    overlayGuildLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    -- Color gris claro discreto; rojo cuando no hay guild seleccionada
    overlayGuildLabel:SetColor(0.7, 0.7, 0.7, 1)

    -- Helper: asigna textura desde lista, color rojo advertencia, oculto por defecto
    local function CrearIcono(nombre, texturas)
        local ctrl = WINDOW_MANAGER:CreateControl(nombre, overlayWin, CT_TEXTURE)
        ctrl:SetDimensions(28, 28)
        for _, ruta in ipairs(texturas) do
            ctrl:SetTexture(ruta)
            if ctrl:IsTextureLoaded() then break end
        end
        ctrl:SetColor(1, 0.15, 0.15, 1)  -- rojo advertencia
        ctrl:SetHidden(true)
        return ctrl
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

    -- Icono mascota: pet_009=perro blanco, pet_027=zorro fennec (verificados en foro ESO oficial)
    overlayPetDot = CrearIcono("EZOToolsPetDot2", {
        "/esoui/art/icons/pet_009.dds",
        "/esoui/art/icons/pet_027.dds",
        "/esoui/art/icons/pet_001.dds",
    })
    overlayPetDot:SetColor(0.2, 1, 0.2, 1)  -- verde
    overlayPetDot:SetAnchor(TOP, overlayLabel, BOTTOM, -56, 6)

    -- Icono companion/asistente: icono de rol healer de LFG (silueta humana con bastón)
    -- LFG_icon_healer verificado en sharedtextures.lua del repo oficial esoui/esoui
    overlayCompanionDot = CrearIcono("EZOToolsCompDot2", {
        "/esoui/art/lfg/lfg_icon_healer.dds",
        "/esoui/art/lfg/lfg_icon_tank.dds",
        "/esoui/art/lfg/lfg_icon_dps.dds",
    })
    overlayCompanionDot:SetAnchor(TOP, overlayLabel, BOTTOM, 56, 6)

    -- Guardar posición al terminar de mover
    overlayWin:SetHandler("OnMoveStop", function()
        EZO.sv.overlay.x = math.floor(overlayWin:GetLeft() + 0.5)
        EZO.sv.overlay.y = math.floor(overlayWin:GetTop() + 0.5)
    end)

    AsegurarTooltipWidget()

    -- Clic derecho abre el menú contextual
    overlayWin:SetHandler("OnMouseUp", function(_, button, upInside)
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
    if not GetNumBuffs then return false end
    local num = GetNumBuffs("player")
    for i = 1, num do
        local _, _, endTime, _, _, _, _, _, _, _, _, canClickOff = GetUnitBuffInfo("player", i)
        if endTime and endTime > 0 and canClickOff == true then
            return true
        end
    end
    return false
end

-- Mascota vanity activa (sin requisito de grupo para pruebas)
local function TieneMascotaEnGrupo()
    -- TODO: restaurar "if GetGroupSize() <= 1 then return false end" tras pruebas
    local petId = GetActiveCollectibleByType(
        COLLECTIBLE_CATEGORY_TYPE_VANITY_PET,
        GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    return petId ~= nil and petId ~= 0
end

-- Companion (NPC seguidor) O asistente activo
local function TieneCompanion()
    -- Companion tipo Bastian, Mirri, etc.
    if HasActiveCompanion and HasActiveCompanion() then return true end
    -- Asistente (banker, merchant, fence...) — collectible de categoría ASSISTANT
    local assistId = GetActiveCollectibleByType(
        COLLECTIBLE_CATEGORY_TYPE_ASSISTANT,
        GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    return assistId ~= nil and assistId ~= 0
end

local function RefrescarDot()
    -- Icono reparación armadura
    if overlayMaintDot then
        overlayMaintDot:SetHidden(not (EZOTools.CanRepairEquipped and EZOTools.CanRepairEquipped()))
    end
    -- Icono recarga armas
    if overlayChargeDot then
        overlayChargeDot:SetHidden(not (EZOTools.CanRechargeWeapons and EZOTools.CanRechargeWeapons()))
    end
    -- Icono comida: visible cuando NO hay buff de comida/bebida activo
    if overlayFoodDot then
        overlayFoodDot:SetHidden(TieneBuffComida())
    end
    -- Icono mascota: visible si vanity pet activa (en grupo en producción)
    if overlayPetDot then
        overlayPetDot:SetHidden(not TieneMascotaEnGrupo())
    end
    -- Icono companion/asistente: visible si companion o asistente activo
    if overlayCompanionDot then
        overlayCompanionDot:SetHidden(not TieneCompanion())
    end
end

-- API pública: refresco completo del overlay (posición, apariencia, visibilidad)
function MOD.Refresh()
    AsegurarControles()
    AplicarPosicion()
    AplicarEstadoBloqueo()
    local a = tonumber(EZO.sv.overlay.alpha) or 1
    overlayWin:SetAlpha(a)
    overlayTex:SetAlpha(a)
    overlayLabel:SetAlpha(a)
    overlayLabel:SetText(ObtenerTextoOverlay())
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
            if overlayPetDot then
                overlayPetDot:SetHidden(not TieneMascotaEnGrupo())
            end
            -- El asistente también es un collectible
            if overlayCompanionDot then
                overlayCompanionDot:SetHidden(not TieneCompanion())
            end
        end)

    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Companion",
        EVENT_ACTIVE_COMPANION_STATE_CHANGED,
        function()
            if overlayCompanionDot then
                overlayCompanionDot:SetHidden(not TieneCompanion())
            end
        end)

    -- Cambio de tamaño de grupo: afecta al icono de mascota
    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Group",
        EVENT_GROUP_MEMBER_LEFT,
        function()
            if overlayPetDot then
                overlayPetDot:SetHidden(not TieneMascotaEnGrupo())
            end
        end)
    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_GroupJoin",
        EVENT_GROUP_MEMBER_JOINED,
        function()
            if overlayPetDot then
                overlayPetDot:SetHidden(not TieneMascotaEnGrupo())
            end
        end)

    -- Buff comida/bebida: refresco reactivo al ganar o perder cualquier efecto
    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Food",
        EVENT_EFFECT_CHANGED,
        function(_, changeType, _, _, unitTag, _, _, _, _, _, abilityType)
            if unitTag == "player" and abilityType == ABILITY_TYPE_NONCOMBATBONUS then
                if overlayFoodDot then
                    overlayFoodDot:SetHidden(TieneBuffComida())
                end
            end
        end)

    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Guild",
        EVENT_GUILD_DATA_LOADED,
        function()
            cachedRepresentedGuildId = nil  -- forzar refresco
            if overlayWin then RefrescarEtiquetaGuild() end
        end)

    -- Detectar equipar/desequipar tabardo en tiempo real.
    -- EVENT_INVENTORY_SINGLE_SLOT_UPDATE: tabardo → guild label, equipo → dot mantenimiento
    local SLOT_TABARD_EVENT = EQUIP_SLOT_TABARD or 10
    EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Tabard",
        EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
        function(_, bag, slot)
            if bag == BAG_WORN then
                -- Tabardo: refrescar guild
                if slot == SLOT_TABARD_EVENT then
                    RefrescarEtiquetaGuild()
                end
                -- Cualquier cambio en equipo equipado: refrescar dot mantenimiento
                RefrescarDot()
            elseif bag == BAG_BACKPACK then
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
                default = true,
            },
            {
                type     = "slider",
                name     = GetString(EZO_OPTION_OVERLAY_ALPHA),
                min      = 0.0, max = 1.0, step = 0.05,
                getFunc  = function() return EZO.sv.overlay.alpha end,
                setFunc  = function(v) EZO.sv.overlay.alpha = v; EZOTools_Overlay.Refresh() end,
                decimals = 2,
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
            -- Casas de amigos (agrupadas aquí por proximidad a la config del overlay)
            { type = "header", name = GetString(EZO_OPTION_FRIENDS) },
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




