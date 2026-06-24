-- Módulo de overlay visual de EZOTools.
-- Gestiona la ventana flotante (logo + texto) que sirve como punto de acceso al menú.
-- El aviso de "Tabardo de gremio" ha sido eliminado (obsoleto desde Update 49:
-- el juego permite mostrar el escudo de gremio sin llevar tabardo equipado,
-- por lo que la detección por BAG_WORN ya no es fiable).

EZOTools_Overlay = EZOTools_Overlay or {}
local MOD = EZOTools_Overlay
local EZO = EZOTools
local WIDGETS = EZOTools_OverlayWidgets
local QUICK = EZOTools_QuickUtility
local ALLIES = EZOTools_QuickUtilityAllies
local FOOD = EZOTools_QuickUtilityFood
local PREVIEW = EZOTools_QuickUtilityPreview
local RECENT_MENU = EZOTools_QuickUtilityRecentMenu

-- Controles de la ventana (se crean en EnsureControls la primera vez)
local overlayWin, overlayTex, overlayLabel, overlayGuildLabel, overlayMaintDot, overlayChargeDot, overlayFoodDot, overlayMountDot, overlayPetDot, overlayCompanionDot, overlayAssistantDot
local overlaySideSlotsLeft, overlaySideSlotsRight = {}, {}
local overlaySideWidgetsLeft, overlaySideWidgetsRight = {}, {}
local overlaySideWidgetTexturesLeft, overlaySideWidgetTexturesRight = {}, {}
local overlayWidgetTooltipWin, overlayWidgetTooltipBackdrop, overlayWidgetTooltipLabel
local overlaySceneFragment
local overlayAllyTooltipActive = false
local overlaySideWidgetTooltipActive = false
local overlayFoodPulseLastRefreshMs = 0
local overlayAllyTooltipLastRefreshMs = 0
local overlayFoodPulseState = nil
local AbrirMenuHistorialAliado
local EstaMontado
local TOOLTIP_ICON_WIDTH = 360
local TOOLTIP_ICON_HEIGHT = 120

-- Estado de combate (se actualiza vía evento)
local enCombate = false

-- Caché del guildId representado para detectar cambios sin evento dedicado.
-- ZOS no expone un evento para SetRepresentedGuildId(), así que usamos poll.
local cachedRepresentedGuildId = nil


-- Slots laterales preparados para futuras alertas/estados. Se calculan contra un radio
-- seguro del logo en vez de depender de la transparencia exacta del DDS.
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
local OVERLAY_TOP_PADDING = 4
local OVERLAY_ROW_GAP_SMALL = 4
local OVERLAY_ROW_GAP_NORMAL = 6
local OVERLAY_BOTTOM_PADDING = 18
local FOOD_PULSE_REFRESH_MS = 120
local ALLY_TOOLTIP_REFRESH_MS = 80

local OcultarMascotaActiva
local OcultarCompanionActivo
local OcultarAsistenteActivo
local ObtenerMascotaActivaId
local ObtenerAssistantActivoId
local ObtenerCompanionActivoCollectibleId
local ObtenerTooltipIconoAliado
local ObtenerMonturaActivaId
local InvocarMonturaRecordada
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
    if not (SCENE_MANAGER and type(SCENE_MANAGER.IsShowing) == "function") then
        return false
    end
    return SCENE_MANAGER:IsShowing("hud") or SCENE_MANAGER:IsShowing("hudui")
end

local function RegistrarFragmentoHUD(control, fragmentoActual)
    if fragmentoActual or not control then
        return fragmentoActual
    end
    if not (_G.ZO_SimpleSceneFragment and _G.HUD_SCENE and _G.HUD_UI_SCENE) then
        return nil
    end

    local fragmento = ZO_SimpleSceneFragment:New(control)
    HUD_SCENE:AddFragment(fragmento)
    HUD_UI_SCENE:AddFragment(fragmento)
    return fragmento
end

local function RegistrarFragmentosHUD()
    overlaySceneFragment = RegistrarFragmentoHUD(overlayWin, overlaySceneFragment)
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

local function AplicarTexturaConFallback(ctrl, rutasPrimarias, rutasFallback)
    if not ctrl then return false end

    local function IntentarRutas(rutas)
        if type(rutas) ~= "table" then return false end
        local ultimaRuta = nil
        for _, ruta in ipairs(rutas) do
            if type(ruta) == "string" and ruta ~= "" then
                ultimaRuta = ruta
                ctrl:SetTexture(ruta)
                if ctrl:IsTextureLoaded() then
                    return true
                end
            end
        end
        if ultimaRuta then
            -- Comportamiento original del addon:
            -- dejamos la ultima ruta candidata aplicada para que el cliente
            -- pueda resolver la textura de forma diferida si la confirma en
            -- el siguiente refresco.
            ctrl:SetTexture(ultimaRuta)
            return true
        end
        return false
    end

    if IntentarRutas(rutasPrimarias) then
        return true
    end

    return IntentarRutas(rutasFallback)
end

local function RefrescarTexturaLogoCentral()
    if not overlayTex then return end
    local guildOverlay = EZOTools_GuildOverlay
    if not (guildOverlay and type(guildOverlay.GetCentralTexturePaths) == "function") then
        return
    end
    local rutasPrimarias, rutasFallback = guildOverlay.GetCentralTexturePaths()
    AplicarTexturaConFallback(overlayTex, rutasPrimarias, rutasFallback)
end

-- Actualiza la etiqueta de guild en el overlay.
-- Lógica de prioridad:
--   1. Tabardo equipado → nombre de la guild del tabardo (amarillo discreto)
--   2. Guild representada en selector C → nombre en color configurable
--   3. Ninguna → "Sin gremio" / "No guild" en color neutro
local function RefrescarEtiquetaGuild()
    if not overlayGuildLabel then return end
    RefrescarTexturaLogoCentral()

    -- Prioridad 1: tabardo equipado
    local guildOverlay = EZOTools_GuildOverlay
    local nombreTabardo = guildOverlay and guildOverlay.GetTabardGuildName and guildOverlay.GetTabardGuildName() or nil
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
    local nombreGuild = guildOverlay and guildOverlay.GetRepresentedGuildName and guildOverlay.GetRepresentedGuildName() or nil
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
    if EZO and EZO.sv and EZO.sv.overlay and EZO.sv.overlay.hideNoGuildLabel == true then
        overlayGuildLabel:SetText("")
        return
    end
    overlayGuildLabel:SetText(GetString(EZO_OVERLAY_NO_GUILD))
    local r, g, b, a = ObtenerColorOverlay(
        EZO.sv and EZO.sv.overlay and EZO.sv.overlay.guildLabelColor,
        { 0.7, 0.7, 0.7, 1 }
    )
    overlayGuildLabel:SetColor(r, g, b, a)
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
    return WIDGETS and WIDGETS.GetDataList(side)
end

local function ObtenerNombreLadoWidget(side)
    return WIDGETS and WIDGETS.GetSideName(side) or tostring(side or "")
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

    overlayWidgetTooltipWin = WINDOW_MANAGER:CreateControl("EZOToolsOverlayWidgetTooltip", overlayWin or GuiRoot, CT_CONTROL)
    overlayWidgetTooltipWin:SetDimensions(TOOLTIP_ICON_WIDTH, TOOLTIP_ICON_HEIGHT)
    overlayWidgetTooltipWin:SetMouseEnabled(false)
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
    if WIDGETS and type(WIDGETS.GetPreviewTooltip) == "function" then
        return WIDGETS.GetPreviewTooltip(side, index)
    end
    return zo_strformat(GetString(EZO_SIDE_WIDGET_PREVIEW_TOOLTIP), ObtenerNombreLadoWidget(side), tostring(index))
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

local function NecesitaPulsoComida()
    return type(overlayFoodPulseState) == "table"
end

local function ObtenerTooltipWidget(side, index, data)
    if not EstanActivosLosTooltipsContextuales() then
        return nil
    end
    if type(data) ~= "table" then
        if WIDGETS and WIDGETS.IsLayoutPreviewEnabled() then
            local foodSlot = WIDGETS.GetAssignment("foodBuff")
            if foodSlot and foodSlot.side == side and foodSlot.index == index and FOOD and type(FOOD.BuildLayoutPreviewTooltip) == "function" then
                return FOOD.BuildLayoutPreviewTooltip()
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
            baseText = zo_strformat(baseText, unpack(data.tooltipArgs))
        end
        return baseText
    end
    if WIDGETS and WIDGETS.IsLayoutPreviewEnabled() then
        return ConstruirTooltipPreviewWidget(side, index)
    end
    return nil
end

local function NormalizarTextoTooltip(texto)
    if type(texto) ~= "string" then
        return texto
    end
    texto = texto:gsub("|n", "\n")
    texto = texto:gsub("([%.%!%?])n([%u])", "%1\n%2")
    return texto
end
MOD.NormalizeTooltipText = NormalizarTextoTooltip

local function MostrarTooltipWidget(ctrl, side, index, data)
    if not EsEscenaHUD() then
        OcultarTooltipWidget()
        return
    end
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
    RegistrarFragmentosHUD()
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
    if not EsEscenaHUD() then
        OcultarTooltipWidget()
        return
    end
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
    RegistrarFragmentosHUD()
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

local function InicializarTooltipEstandarSobreControl(tooltip, ctrl)
    if not (ctrl and tooltip and type(InitializeTooltip) == "function") then
        return false
    end

    local guiRootWidth = GuiRoot and select(1, GuiRoot:GetDimensions()) or 0
    local centerX = ctrl:GetCenter()
    if type(centerX) == "number" and guiRootWidth > 0 and centerX > (guiRootWidth / 2) then
        InitializeTooltip(tooltip, ctrl, TOPRIGHT, -12, 0, TOPLEFT)
    else
        InitializeTooltip(tooltip, ctrl, TOPLEFT, 12, 0, TOPRIGHT)
    end
    return true
end

local function MostrarTooltipItemSobreControl(ctrl, itemLink)
    if type(itemLink) ~= "string" or itemLink == "" then
        return
    end
    if not (ItemTooltip and ItemTooltip.SetLink) then
        return
    end
    if not InicializarTooltipEstandarSobreControl(ItemTooltip, ctrl) then
        return
    end
    ItemTooltip:SetLink(itemLink)
end

local function MostrarTooltipCollectibleSobreControl(ctrl, collectibleId, fallbackName)
    if not ctrl then
        return
    end
    if collectibleId and collectibleId ~= 0
        and ItemTooltip
        and type(ItemTooltip.SetCollectible) == "function"
        and InicializarTooltipEstandarSobreControl(ItemTooltip, ctrl) then
        ItemTooltip:SetCollectible(collectibleId)
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
    if RECENT_MENU and type(RECENT_MENU.Open) == "function" then
        RECENT_MENU.Open(anchor, entries, emptyLabel)
    end
end

local function AbrirMenuHistorialComida(anchor)
    if not (RECENT_MENU and type(RECENT_MENU.OpenFood) == "function") then
        return
    end
    RECENT_MENU.OpenFood(anchor, QUICK, {
        ShowItem = MostrarTooltipItemSobreControl,
        ClearItem = function()
            if type(ClearTooltip) == "function" and ItemTooltip then
                ClearTooltip(ItemTooltip)
            end
        end,
    })
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

local function ObtenerRenderDataWidget(side, index)
    if WIDGETS and type(WIDGETS.GetRenderData) == "function" then
        return WIDGETS.GetRenderData(side, index)
    end
    return nil
end

local AplicarWidgetsLaterales

local function AsignarWidgetLateralInterno(slotInfo, data)
    if WIDGETS and type(WIDGETS.Assign) == "function" then
        WIDGETS.Assign(slotInfo, data)
    end
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
    local foodWidgetData = FOOD and type(FOOD.BuildWidgetData) == "function" and FOOD.BuildWidgetData() or nil
    overlayFoodPulseState = foodWidgetData and foodWidgetData.pulse or nil

    AsignarWidgetLateralInterno(WIDGETS.GetAssignment("foodBuff"), WIDGETS.BuildData({
        slotKey = foodWidgetData and foodWidgetData.slotKey or "food_buff",
        visible = true,
        texture = foodWidgetData and foodWidgetData.texture or "/esoui/art/inventory/inventory_tabIcon_Craftbag_provisioning_up.dds",
        color = foodWidgetData and foodWidgetData.color or { 1.0, 0.30, 0.30, 0.95 },
        alpha = foodWidgetData and foodWidgetData.alpha or 1,
        tooltipText = foodWidgetData and foodWidgetData.tooltipText or GetString(EZO_SIDE_WIDGET_FOOD_NONE_TOOLTIP),
        primaryHandler = foodWidgetData and foodWidgetData.primaryHandler or nil,
        secondaryHandler = foodWidgetData and foodWidgetData.secondaryHandler or nil,
    }))

    if lowRepairKits and type(repairKitCount) == "number" and type(repairKitThreshold) == "number" then
        AsignarWidgetLateralInterno(WIDGETS.GetAssignment("repairKits"), WIDGETS.BuildData({
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
        AsignarWidgetLateralInterno(WIDGETS.GetAssignment("repairKits"), nil)
    end

    if lowSoulGems and type(soulGemCount) == "number" and type(soulGemThreshold) == "number" then
        AsignarWidgetLateralInterno(WIDGETS.GetAssignment("soulGems"), WIDGETS.BuildData({
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
        AsignarWidgetLateralInterno(WIDGETS.GetAssignment("soulGems"), nil)
    end

    if canRepairEquipped then
        AsignarWidgetLateralInterno(WIDGETS.GetAssignment("repairEquipped"), WIDGETS.BuildData({
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
        AsignarWidgetLateralInterno(WIDGETS.GetAssignment("repairEquipped"), nil)
    end

    if canRechargeWeapons then
        AsignarWidgetLateralInterno(WIDGETS.GetAssignment("rechargeWeapons"), WIDGETS.BuildData({
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
        AsignarWidgetLateralInterno(WIDGETS.GetAssignment("rechargeWeapons"), nil)
    end

    AplicarWidgetsLaterales()
end

local function AplicarPreviewSlotsLaterales()
    for _, side in ipairs({ "left", "right" }) do
        local lista = ObtenerSlotsLaterales(side)
        for i = 1, WIDGETS.GetSlotCount() do
            local ctrl = lista[i]
            if ctrl then
                ctrl:SetHidden(true)
            end
        end
    end
end

AplicarWidgetsLaterales = function()
    if not EsEscenaHUD() then
        for _, side in ipairs({ "left", "right" }) do
            local widgets = ObtenerWidgetsLaterales(side)
            local textures = ObtenerTexturasWidgetLaterales(side)
            for i = 1, WIDGETS.GetSlotCount() do
                if widgets[i] then widgets[i]:SetHidden(true) end
                if textures[i] then textures[i]:SetHidden(true) end
            end
        end
        OcultarTooltipWidget()
        return
    end

    WIDGETS.RebuildRegistry()
    for _, side in ipairs({ "left", "right" }) do
        local widgets = ObtenerWidgetsLaterales(side)
        local textures = ObtenerTexturasWidgetLaterales(side)
        for i = 1, WIDGETS.GetSlotCount() do
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

local function DesactivarLayoutPreview()
    if not (WIDGETS
        and type(WIDGETS.IsLayoutPreviewEnabled) == "function"
        and type(WIDGETS.DisableLayoutPreview) == "function") then
        return false
    end
    if not WIDGETS.IsLayoutPreviewEnabled() then
        return false
    end

    WIDGETS.DisableLayoutPreview()
    OcultarTooltipWidget()
    if overlayWin then
        AplicarPreviewSlotsLaterales()
        AplicarWidgetsLaterales()
    end
    return true
end

local function AsegurarSlotsLaterales()
    local nombres = {
        left  = "EZOToolsSideSlotLeft",
        right = "EZOToolsSideSlotRight",
    }
    for side, prefijo in pairs(nombres) do
        local lista = ObtenerSlotsLaterales(side)
        for i = 1, WIDGETS.GetSlotCount() do
            if not lista[i] then
                local ctrl = WINDOW_MANAGER:CreateControl(prefijo .. i, overlayWin, CT_TEXTURE)
                ctrl:SetDimensions(WIDGETS.GetSlotBase(), WIDGETS.GetSlotBase())
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
        for i = 1, WIDGETS.GetSlotCount() do
            if not widgets[i] then
                local host = WINDOW_MANAGER:CreateControl(prefijo .. i, overlayWin, CT_CONTROL)
                host:SetDimensions(WIDGETS.GetSlotBase(), WIDGETS.GetSlotBase())
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
    local slotSize   = math.max(WIDGETS.GetSlotMin(), math.floor(WIDGETS.GetSlotBase() * s + 0.5))
    local slotGap    = math.max(4, math.floor(WIDGETS.GetSlotGap() * s + 0.5))
    local radiusX    = math.max(slotSize, math.floor(texPx * WIDGETS.GetRadiusX() + 0.5))
    local radiusY    = math.max(slotSize, math.floor(texPx * WIDGETS.GetRadiusY() + 0.5))
    local halfSlot   = math.floor(slotSize * 0.5 + 0.5)
    local maxExtent  = math.floor(texPx * 0.5 + 0.5)
    local lados = {
        { side = "left",  sign = -1 },
        { side = "right", sign =  1 },
    }

    for idx, yRatio in ipairs(WIDGETS.GetYRatios()) do
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

    local slotInfo = WIDGETS.GetAssignment("foodBuff")
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
    return WIDGETS.GetSlotCount()
end

function MOD.GetSideWidget(side, index)
    local lista = ObtenerWidgetsLaterales(side)
    return lista and lista[index] or nil
end

function MOD.GetSideWidgetSlotState(side, index)
    local lista = WIDGETS.GetRegistryList(side)
    if not lista or type(index) ~= "number" then return nil end
    return lista[index]
end

function MOD.GetSideWidgetRegistry()
    return WIDGETS.GetRegistrySnapshot()
end

function MOD.FindFreeSideWidgetSlot(side)
    return WIDGETS.FindFreeSlot(side)
end

function MOD.SetSideWidgetData(side, index, data)
    if WIDGETS.SetData(side, index, data) then
        MOD.Refresh()
    end
end

function MOD.ClearSideWidgetData(side, index)
    if WIDGETS.ClearData(side, index) then
        MOD.Refresh()
    end
end

function MOD.ClearAllSideWidgetData()
    WIDGETS.ClearAllData()
    MOD.Refresh()
end

function MOD.ToggleLayoutPreview()
    local enabled = WIDGETS.ToggleLayoutPreview()
    if not enabled then
        OcultarTooltipWidget()
    end
    MOD.Refresh()
    return enabled
end
function MOD.IsLayoutPreviewEnabled()
    return WIDGETS.IsLayoutPreviewEnabled()
end

function MOD.SetFoodDebugState(state)
    if not (FOOD and type(FOOD.SetDebugState) == "function") then
        return false
    end
    if not FOOD.SetDebugState(state) then
        return false
    end
    if not (EZO and EZO.sv) then
        return true
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

    -- Cuatro iconos centrados bajo overlayLabel (@ZuriPlayer), distribuidos uniformemente.
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
            { ctrl = overlayMountDot,     x = math.floor(-1.5 * sep + 0.5) },
            { ctrl = overlayPetDot,       x = math.floor(-0.5 * sep + 0.5) },
            { ctrl = overlayCompanionDot, x = math.floor(0.5 * sep + 0.5) },
            { ctrl = overlayAssistantDot, x = math.floor(1.5 * sep + 0.5) },
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
        local margin   = math.max(16, math.floor(WIDGETS.GetSlotMargin() * s + 0.5))
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
    RegistrarFragmentosHUD()
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
    overlayMountDot = CrearIcono("EZOToolsMountDot2", {
        "/esoui/art/treeicons/collections_indexicon_mounts_up.dds",
        "/esoui/art/treeicons/gamepad/gp_collection_indexicon_mounts.dds",
        "/esoui/art/treeicons/store_indexicon_mounts_up.dds",
    })
    overlayMountDot:SetColor(1, 1, 1, 1)
    overlayMountDot:SetAnchor(TOP, overlayLabel, BOTTOM, -84, 6)

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
    RegistrarFragmentosHUD()

    local function ObtenerDefinicionesIconosAliados()
        return {
            {
                tipo = "mount",
                ctrl = overlayMountDot,
                activoFn = function() return EstaMontado() and ObtenerMonturaActivaId() ~= 0 end,
                clickFn = function()
                    if EZO and type(EZO.Print) == "function" then
                        EZO.Print(GetString(EZO_MSG_USE_MOUNT))
                    end
                    local ok = InvocarMonturaRecordada()
                    if ok then
                        ProgramarRefrescoDots()
                    end
                    return ok
                end,
            },
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
                        if type(icono.clickFn) == "function" then
                            icono.clickFn()
                        else
                            EjecutarClickIconoAliado(
                                icono.activoFn,
                                icono.ocultarFn,
                                icono.invocarFn,
                                icono.msgOcultarId,
                                icono.msgInvocarId
                            )
                        end
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
    local enHUD = EsEscenaHUD()
    local oculto = (not EZO.sv.overlay.enabled)
        or (EZO.sv.overlay.hideInCombat and enCombate)
    if not enHUD then
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
    return FOOD and type(FOOD.HasFoodBuff) == "function" and FOOD.HasFoodBuff() == true
end

ObtenerMascotaActivaId = function()
    return ALLIES and type(ALLIES.GetActiveId) == "function" and ALLIES.GetActiveId("pet") or 0
end

ObtenerMonturaActivaId = function()
    return ALLIES and type(ALLIES.GetActiveId) == "function" and ALLIES.GetActiveId("mount") or 0
end

ObtenerAssistantActivoId = function()
    return ALLIES and type(ALLIES.GetActiveId) == "function" and ALLIES.GetActiveId("assistant") or 0
end

ObtenerCompanionActivoCollectibleId = function()
    return ALLIES and type(ALLIES.GetActiveId) == "function" and ALLIES.GetActiveId("companion") or 0
end

EstaMontado = function()
    return ALLIES and type(ALLIES.IsMounted) == "function" and ALLIES.IsMounted() or false
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
    if ctrl == overlayMountDot then
        alpha = 1
    end
    ctrl:SetColor(1, 1, 1, alpha)
    ctrl:SetAlpha(alpha)
end

local function RefrescarEstadoIconoAliado(ctrl, activeId, tipo)
    if activeId ~= 0 then
        if ALLIES and type(ALLIES.SetRemembered) == "function" then
            ALLIES.SetRemembered(tipo, activeId)
        end
        if ALLIES and type(ALLIES.AddToHistory) == "function" then
            ALLIES.AddToHistory(tipo, activeId)
        end
    end
    local rememberedId = ALLIES and type(ALLIES.GetRemembered) == "function" and ALLIES.GetRemembered(tipo) or 0
    local collectibleId = (activeId ~= 0) and activeId or rememberedId
    if not ctrl then
        return
    end
    -- Mantener visibles los iconos inferiores incluso sin elemento recordado para
    -- poder mostrar la ayuda contextual de primer uso en ratón y gamepad.
    local visible = true
    ctrl:SetHidden(not visible)
    if visible then
        AplicarEstadoVisualIconoAliado(ctrl, activeId ~= 0, collectibleId)
    end
end

AbrirMenuHistorialAliado = function(anchor, tipo)
    if not (ALLIES and type(ALLIES.IsSupportedKind) == "function" and ALLIES.IsSupportedKind(tipo)) then
        return
    end

    local entries = {}
    local recentEntries = QUICK and type(QUICK.BuildRecentEntries) == "function" and QUICK.BuildRecentEntries(tipo) or {}
    local showRecentHoverPreview = type(ALLIES.ShouldShowRecentHoverPreview) == "function"
        and ALLIES.ShouldShowRecentHoverPreview(tipo)
    local fallbackName = type(ALLIES.GetFallbackName) == "function" and ALLIES.GetFallbackName(tipo) or ""
    for _, entry in ipairs(recentEntries) do
        local onEnter = nil
        local onExit = nil
        if showRecentHoverPreview and entry.empty ~= true then
            local finalId = tonumber(entry.previewCollectibleId) or 0
            onEnter = function(control)
                MostrarTooltipCollectibleSobreControl(control, finalId, fallbackName)
            end
            onExit = function()
                if type(ClearTooltip) == "function" and ItemTooltip then
                    ClearTooltip(ItemTooltip)
                end
                OcultarTooltipWidget()
            end
        end
        entries[#entries + 1] = {
            label = tostring(entry.text or ""),
            enabled = entry.empty ~= true,
            onEnter = onEnter,
            onExit = onExit,
            onSelect = function()
                if type(entry.callback) == "function" then
                    entry.callback()
                end
            end,
        }
    end

    AbrirMenuRecientes(anchor, entries, "")
end

ObtenerTooltipIconoAliado = function(tipo, activo)
    return ALLIES and type(ALLIES.BuildIconTooltip) == "function" and ALLIES.BuildIconTooltip(tipo, activo) or nil
end

OcultarMascotaActiva = function()
    return ALLIES and type(ALLIES.HideActive) == "function" and ALLIES.HideActive("pet") or false
end

OcultarCompanionActivo = function()
    return ALLIES and type(ALLIES.HideActive) == "function" and ALLIES.HideActive("companion") or false
end

OcultarAsistenteActivo = function()
    return ALLIES and type(ALLIES.HideActive) == "function" and ALLIES.HideActive("assistant") or false
end

InvocarMascotaRecordada = function()
    return ALLIES and type(ALLIES.InvokeRemembered) == "function" and ALLIES.InvokeRemembered("pet") or false
end

InvocarMonturaRecordada = function()
    return ALLIES and type(ALLIES.InvokeRemembered) == "function" and ALLIES.InvokeRemembered("mount") or false
end

InvocarCompanionRecordado = function()
    return ALLIES and type(ALLIES.InvokeRemembered) == "function" and ALLIES.InvokeRemembered("companion") or false
end

InvocarAsistenteRecordada = function()
    return ALLIES and type(ALLIES.InvokeRemembered) == "function" and ALLIES.InvokeRemembered("assistant") or false
end

RefrescarDot = function()
    if overlayMaintDot then overlayMaintDot:SetHidden(true) end
    if overlayChargeDot then overlayChargeDot:SetHidden(true) end
    if overlayFoodDot then overlayFoodDot:SetHidden(true) end
    if not EsEscenaHUD() then
        if overlayMountDot then overlayMountDot:SetHidden(true) end
        if overlayPetDot then overlayPetDot:SetHidden(true) end
        if overlayCompanionDot then overlayCompanionDot:SetHidden(true) end
        if overlayAssistantDot then overlayAssistantDot:SetHidden(true) end
        AplicarWidgetsLaterales()
        OcultarTooltipWidget()
        return
    end

    local mountCollectibleId = ObtenerMonturaActivaId()
    if mountCollectibleId ~= 0 then
        if ALLIES and type(ALLIES.SetRemembered) == "function" then
            ALLIES.SetRemembered("mount", mountCollectibleId)
        end
        if ALLIES and type(ALLIES.AddToHistory) == "function" then
            ALLIES.AddToHistory("mount", mountCollectibleId)
        end
    end
    local visibleMountId = EstaMontado() and mountCollectibleId or 0
    RefrescarEstadoIconoAliado(overlayMountDot, visibleMountId, "mount")

    local petId = ObtenerMascotaActivaId()
    RefrescarEstadoIconoAliado(overlayPetDot, petId, "pet")

    local companionCollectibleId = ObtenerCompanionActivoCollectibleId()
    RefrescarEstadoIconoAliado(overlayCompanionDot, companionCollectibleId, "companion")

    local assistId = ObtenerAssistantActivoId()
    RefrescarEstadoIconoAliado(overlayAssistantDot, assistId, "assistant")

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
    if not EsEscenaHUD() then
        ActualizarVisibilidad()
        return
    end
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

function MOD.ShowQuickUtilityPreview(control, entryData)
    if not EsEscenaHUD() then
        MOD.HideQuickUtilityPreview()
        return false
    end
    if not (PREVIEW and type(PREVIEW.Show) == "function") then
        return false
    end
    return PREVIEW.Show(control, entryData, {
        ShowItem = MostrarTooltipItemSobreControl,
        ShowCollectible = MostrarTooltipCollectibleSobreControl,
    })
end

function MOD.HideQuickUtilityPreview()
    if type(ClearTooltip) == "function" then
        if ItemTooltip then
            ClearTooltip(ItemTooltip)
        end
        if InformationTooltip then
            ClearTooltip(InformationTooltip)
        end
    end
    OcultarTooltipWidget()
end

-- Inicialización: crea controles, registra eventos
function MOD.Init()
    AsegurarControles()
    DesactivarLayoutPreview()
    MOD.Refresh()
    if FOOD and type(FOOD.SyncBackpackCache) == "function" then
        FOOD.SyncBackpackCache()
    end

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

    if _G.EVENT_PLAYER_DEACTIVATED then
        EVENT_MANAGER:RegisterForEvent("EZOTools_Overlay_Deactivated",
            EVENT_PLAYER_DEACTIVATED,
            function()
                DesactivarLayoutPreview()
            end)
    end

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
                    if FOOD and type(FOOD.RecordActiveFood) == "function" then
                        FOOD.RecordActiveFood()
                    end
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
                if FOOD and type(FOOD.HandleInventorySlotUpdate) == "function" then
                    FOOD.HandleInventorySlotUpdate(slot, stackCountChange)
                end
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
        end
        -- Guild representada (no hay evento para SetRepresentedGuildId).
        -- La autoasignacion de casas no debe depender de que el overlay este visible.
        if type(GetRepresentedGuildId) == "function" then
            local guildId = GetRepresentedGuildId()
            if guildId ~= cachedRepresentedGuildId then
                cachedRepresentedGuildId = guildId
                if EZO and type(EZO.ApplyAutoFriendHousesSelection) == "function" then
                    EZO.ApplyAutoFriendHousesSelection()
                end
                if overlayWin then
                    RefrescarEtiquetaGuild()
                end
            end
        end
        zo_callLater(TickEstado, 5000)
    end
    zo_callLater(TickEstado, 3000)  -- primer tick a los 3s
end
