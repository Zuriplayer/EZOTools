-- Gestion de comida/bebida para HOLD Y.
-- Mantiene fuera de overlay.lua la deteccion, persistencia, historial y consumo.
EZOTools_QuickUtilityFood = EZOTools_QuickUtilityFood or {}

local MOD = EZOTools_QuickUtilityFood
local EZO = EZOTools

local FOOD_ALERT_SECONDS = 15 * 60
local FOOD_PENDING_WINDOW_MS = 2000
local FOOD_MIN_EFFECT_DURATION_SECONDS = 60
local FOOD_HISTORY_LIMIT = 5
local foodDebugState = nil
local foodConfirmDialogRegistered = false
local foodBackpackCache = {}
local foodPendingItem = nil
local lastFoodEffectCandidate = nil

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

-- Versiones únicas en shared_utils.lua
local CalcularPulsoAlfa = EZOTools_CalcularPulsoAlfa
local NormalizarTextoTooltip = EZOTools_NormalizarTextoTooltip
local NormalizarTextoEtiqueta = EZOTools_NormalizarTextoEtiqueta

local function ObtenerFoodSV()
    local overlaySV = EZO and EZO.sv and EZO.sv.overlay or nil
    if type(overlaySV) ~= "table" then
        return nil
    end
    overlaySV.lastFoodItemLink = tostring(overlaySV.lastFoodItemLink or "")
    overlaySV.lastFoodItemName = tostring(overlaySV.lastFoodItemName or "")
    overlaySV.lastFoodBuffAbilityId = math.floor(tonumber(overlaySV.lastFoodBuffAbilityId) or 0)
    if overlaySV.lastFoodBuffAbilityId < 0 then
        overlaySV.lastFoodBuffAbilityId = 0
    end
    if type(overlaySV.knownFoodBuffAbilityIds) ~= "table" then
        overlaySV.knownFoodBuffAbilityIds = {}
    end
    if type(overlaySV.recentFoodItems) ~= "table" then
        overlaySV.recentFoodItems = {}
    end
    return overlaySV
end

local function GuardarComidaRecordada(itemLink, itemName)
    local overlaySV = ObtenerFoodSV()
    if not overlaySV then return end
    overlaySV.lastFoodItemLink = tostring(itemLink or "")
    overlaySV.lastFoodItemName = tostring(itemName or "")
end

local function GuardarComidaEnHistorial(itemLink, itemName)
    local overlaySV = ObtenerFoodSV()
    if not overlaySV then return end
    local link = tostring(itemLink or "")
    local name = tostring(itemName or "")
    if link == "" and name == "" then
        return
    end

    local history = overlaySV.recentFoodItems
    if type(history) ~= "table" then
        history = {}
        overlaySV.recentFoodItems = history
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
        if #newHistory >= FOOD_HISTORY_LIMIT then
            break
        end
    end

    overlaySV.recentFoodItems = newHistory
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

local function NormalizarAbilityId(abilityId)
    local normalized = math.floor(tonumber(abilityId) or 0)
    if normalized <= 0 then
        return nil
    end
    return normalized
end

local function EsFoodBuffAbilityIdConocido(abilityId)
    local normalized = NormalizarAbilityId(abilityId)
    if not normalized then
        return false
    end
    local overlaySV = ObtenerFoodSV()
    if not overlaySV then
        return false
    end
    if overlaySV.lastFoodBuffAbilityId == normalized then
        return true
    end
    return overlaySV.knownFoodBuffAbilityIds[tostring(normalized)] == true
end

local function RegistrarFoodBuffAbilityId(abilityId, updateLast)
    local normalized = NormalizarAbilityId(abilityId)
    local overlaySV = ObtenerFoodSV()
    if not normalized or not overlaySV then
        return false
    end
    if updateLast ~= false then
        overlaySV.lastFoodBuffAbilityId = normalized
    end
    overlaySV.knownFoodBuffAbilityIds[tostring(normalized)] = true
    return true
end

local function RegistrarAbilityIdDeItemLink(itemLink)
    itemLink = tostring(itemLink or "")
    if itemLink == "" or type(GetItemLinkOnUseAbilityId) ~= "function" then
        return false
    end
    return RegistrarFoodBuffAbilityId(GetItemLinkOnUseAbilityId(itemLink), false)
end

local function RegistrarAbilityIdsDeComidaRecordada()
    local overlaySV = ObtenerFoodSV()
    if not overlaySV then
        return
    end
    for _, entry in ipairs(overlaySV.recentFoodItems) do
        if type(entry) == "table" then
            RegistrarAbilityIdDeItemLink(entry.itemLink)
        end
    end
    RegistrarAbilityIdDeItemLink(overlaySV.lastFoodItemLink)
end

function MOD.GetBuffInfo()
    if foodDebugState == "green" then
        return {
            active = true,
            name = GetString(EZO_DEBUG_FOOD_NAME),
            remainingSeconds = 20 * 60,
        }
    end
    if foodDebugState == "yellow" then
        return {
            active = true,
            name = GetString(EZO_DEBUG_FOOD_NAME),
            remainingSeconds = 4 * 60 + 30,
        }
    end
    if foodDebugState == "red" then
        return { active = false }
    end

    if type(GetNumBuffs) ~= "function" or type(GetUnitBuffInfo) ~= "function" then
        return { active = false }
    end

    -- ESO usa este abilityId nativo para describir el consumible. El emparejado
    -- por eventos de inventario queda como respaldo si el buff activo difiere.
    RegistrarAbilityIdsDeComidaRecordada()

    local num = GetNumBuffs("player")
    local mejor = nil
    for i = 1, num do
        local buffName, _, endTime, buffSlot, _, _, _, _, _, _, abilityId = GetUnitBuffInfo("player", i)
        if (tonumber(buffSlot) or 0) > 0
            and tostring(buffName or "") ~= ""
            and EsFoodBuffAbilityIdConocido(abilityId) then
            local candidato = {
                active = true,
                name = buffName,
                remainingSeconds = CalcularSegundosRestantesBuff(endTime),
                abilityId = NormalizarAbilityId(abilityId),
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

function MOD.BuildVisualState(foodInfo)
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

function MOD.FindFoodByReference(targetLink, targetName)
    targetLink = tostring(targetLink or "")
    targetName = tostring(targetName or "")
    if targetLink == "" and targetName == "" then
        return nil
    end

    -- La caché de mochila (mantenida por HandleInventorySlotUpdate y
    -- SyncBackpackCache) ya sabe qué huecos tienen comida/bebida: iterarla
    -- evita releer toda la mochila con la API en cada refresco del widget.
    local fallbackSlot, fallbackEntry = nil, nil
    for slotIndex, entry in pairs(foodBackpackCache) do
        if type(entry) == "table" then
            local itemLink = tostring(entry.itemLink or "")
            local itemName = tostring(entry.itemName or "")
            if targetLink ~= "" and itemLink == targetLink then
                return BAG_BACKPACK, slotIndex, (itemName ~= "" and itemName) or targetName, itemLink,
                    ObtenerCalidadItem(BAG_BACKPACK, slotIndex, itemLink), ObtenerDescripcionUsoItem(itemLink)
            end
            if not fallbackSlot and targetName ~= "" and itemName == targetName then
                fallbackSlot, fallbackEntry = slotIndex, entry
            end
        end
    end

    if fallbackSlot then
        local itemLink = tostring(fallbackEntry.itemLink or "")
        return BAG_BACKPACK, fallbackSlot, tostring(fallbackEntry.itemName or ""), itemLink,
            ObtenerCalidadItem(BAG_BACKPACK, fallbackSlot, itemLink), ObtenerDescripcionUsoItem(itemLink)
    end
    return nil
end

function MOD.FindRecordedFood()
    local overlaySV = ObtenerFoodSV()
    local targetLink = tostring(overlaySV and overlaySV.lastFoodItemLink or "")
    local targetName = tostring(overlaySV and overlaySV.lastFoodItemName or "")
    return MOD.FindFoodByReference(targetLink, targetName)
end

function MOD.BuildTooltip(foodInfo, foodRecordadoNombre, foodRecordadoDisponible, foodLegendaria)
    local foodState = MOD.BuildVisualState(foodInfo)
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
        local overlaySV = ObtenerFoodSV()
        local nombre = tostring(foodRecordadoNombre or (overlaySV and overlaySV.lastFoodItemName) or "")
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
    foodBackpackCache[slotIndex] = LeerEstadoConsumibleComidaMochila(slotIndex)
end

function MOD.SyncBackpackCache()
    foodBackpackCache = {}
    foodPendingItem = nil
    lastFoodEffectCandidate = nil
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
    if delta ~= -1 then
        return
    end

    local itemLink = tostring(previousEntry.itemLink or "")
    local itemName = tostring(previousEntry.itemName or "")
    if itemLink == "" and itemName == "" then
        return
    end

    foodPendingItem = {
        itemLink = itemLink,
        itemName = itemName,
        timestampMs = ObtenerMomentoActualMs(),
    }
end

local function EsCambioEfectoActivo(changeType)
    return changeType == EFFECT_RESULT_GAINED
        or changeType == EFFECT_RESULT_UPDATED
        or changeType == EFFECT_RESULT_FULL_REFRESH
end

local function CrearCandidatoEfecto(changeType, effectName, beginTime, endTime, abilityId)
    local normalized = NormalizarAbilityId(abilityId)
    local duration = (tonumber(endTime) or 0) - (tonumber(beginTime) or 0)
    if not normalized or not EsCambioEfectoActivo(changeType) or duration < FOOD_MIN_EFFECT_DURATION_SECONDS then
        return nil
    end
    return {
        abilityId = normalized,
        effectName = tostring(effectName or ""),
        timestampMs = ObtenerMomentoActualMs(),
    }
end

local function IntentarAprenderFoodBuffPendiente(candidate)
    if type(foodPendingItem) ~= "table" or type(candidate) ~= "table" then
        return false
    end
    local nowMs = ObtenerMomentoActualMs()
    local pendingMs = tonumber(foodPendingItem.timestampMs)
    local candidateMs = tonumber(candidate.timestampMs)
    if nowMs and pendingMs and (nowMs - pendingMs) > FOOD_PENDING_WINDOW_MS then
        foodPendingItem = nil
        return false
    end
    if pendingMs and candidateMs and math.abs(candidateMs - pendingMs) > FOOD_PENDING_WINDOW_MS then
        return false
    end

    local itemLink = tostring(foodPendingItem.itemLink or "")
    local itemName = tostring(foodPendingItem.itemName or "")
    if itemLink == "" and itemName == "" then
        foodPendingItem = nil
        return false
    end

    if not RegistrarFoodBuffAbilityId(candidate.abilityId) then
        return false
    end
    GuardarComidaRecordada(itemLink, itemName)
    GuardarComidaEnHistorial(itemLink, itemName)
    foodPendingItem = nil
    lastFoodEffectCandidate = nil
    return true
end

function MOD.HandleInventorySlotUpdate(slotIndex, stackCountChange)
    local previousEntry = foodBackpackCache[slotIndex]
    RegistrarConsumoComidaPendiente(previousEntry, stackCountChange)
    if type(foodPendingItem) == "table" and type(lastFoodEffectCandidate) == "table" then
        IntentarAprenderFoodBuffPendiente(lastFoodEffectCandidate)
    end
    ActualizarCacheConsumibleComidaMochila(slotIndex)
end

function MOD.HandleEffectChanged(changeType, effectName, unitTag, beginTime, endTime, abilityId)
    if unitTag ~= "player" then
        return false
    end

    local knownAbility = EsFoodBuffAbilityIdConocido(abilityId)
    local candidate = CrearCandidatoEfecto(changeType, effectName, beginTime, endTime, abilityId)
    if candidate then
        lastFoodEffectCandidate = candidate
        if IntentarAprenderFoodBuffPendiente(candidate) then
            return true
        end
    end
    return knownAbility
end

local function ConsumirComidaEnSlot(bagId, slotIndex, itemName, itemLink)
    if not bagId or slotIndex == nil then
        return false
    end

    if type(IsItemUsable) == "function" then
        local usable, usableOnlyFromActionSlot = IsItemUsable(bagId, slotIndex)
        if not usable or usableOnlyFromActionSlot then
            return false
        end
    end

    if type(CanInteractWithItem) == "function" and not CanInteractWithItem(bagId, slotIndex) then
        return false
    end

    GuardarComidaRecordada(itemLink, itemName)
    GuardarComidaEnHistorial(itemLink, itemName)

    if type(IsProtectedFunction) == "function" and IsProtectedFunction("UseItem") then
        if type(CallSecureProtected) ~= "function" then
            return false
        end
        local okSecure, secureResult = pcall(CallSecureProtected, "UseItem", bagId, slotIndex)
        return okSecure and secureResult == true
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
    local bagId, slotIndex, itemName, itemLink = MOD.FindRecordedFood()
    return ConsumirComidaEnSlot(bagId, slotIndex, itemName, itemLink)
end

local function EmitirDebugComida(message)
    if not (EZO and type(EZO.IsDebugModeEnabled) == "function" and EZO.IsDebugModeEnabled()) then
        return false
    end
    if type(EZO.DebugPrint) == "function" then
        return EZO.DebugPrint(tostring(message or ""))
    end
    return false
end

local function VerificarConsumoComidaDebug(foodInfoAntes)
    if not (EZO and type(EZO.IsDebugModeEnabled) == "function" and EZO.IsDebugModeEnabled()) then
        return
    end
    if type(zo_callLater) ~= "function" then
        return
    end

    zo_callLater(function()
        local foodInfoDespues = MOD.GetBuffInfo()
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

        if not consumido then
            EmitirDebugComida(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_FAILED))
        end
    end, 1500)
end

local function AsegurarDialogoConfirmacionComida()
    if foodConfirmDialogRegistered then
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

    foodConfirmDialogRegistered = true
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

local function DebeConfirmarComidaLegendaria(options)
    return not (type(options) == "table" and options.skipLegendaryConfirm == true)
end

function MOD.ReuseRecordedFood(options)
    local foodInfoAntes = MOD.GetBuffInfo()
    local bagId, slotIndex, itemName, _itemLink, quality, effectDescription = MOD.FindRecordedFood()
    if not bagId or slotIndex == nil then
        EmitirDebugComida(GetString(EZO_MSG_DEBUG_FOOD_NO_RECORDED))
        return false
    end

    local qualityLegendary = (type(ITEM_QUALITY_LEGENDARY) == "number") and ITEM_QUALITY_LEGENDARY or nil
    if qualityLegendary and quality == qualityLegendary and DebeConfirmarComidaLegendaria(options) then
        local remainingSeconds = type(foodInfoAntes) == "table" and tonumber(foodInfoAntes.remainingSeconds) or nil
        return PedirConfirmacionComidaLegendaria(itemName, effectDescription, remainingSeconds, function()
            EmitirDebugComida(zo_strformat(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_ATTEMPT), tostring(itemName or "")))
            if ConsumirComidaRecordada() then
                VerificarConsumoComidaDebug(foodInfoAntes)
            else
                EmitirDebugComida(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_FAILED))
            end
        end)
    end

    EmitirDebugComida(zo_strformat(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_ATTEMPT), tostring(itemName or "")))
    local ok = ConsumirComidaRecordada()
    if ok then
        VerificarConsumoComidaDebug(foodInfoAntes)
    else
        EmitirDebugComida(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_FAILED))
    end
    return ok
end

function MOD.ConsumeHistoryFood(itemLink, itemName, options)
    local foodInfoAntes = MOD.GetBuffInfo()
    local bagId, slotIndex, resolvedName, resolvedLink, quality, effectDescription = MOD.FindFoodByReference(itemLink, itemName)
    if not bagId or slotIndex == nil then
        EmitirDebugComida(GetString(EZO_MSG_DEBUG_FOOD_NO_RECORDED))
        return false
    end

    local finalName = tostring(resolvedName or itemName or "")
    local qualityLegendary = (type(ITEM_QUALITY_LEGENDARY) == "number") and ITEM_QUALITY_LEGENDARY or nil
    if qualityLegendary and quality == qualityLegendary and DebeConfirmarComidaLegendaria(options) then
        return PedirConfirmacionComidaLegendaria(finalName, effectDescription, nil, function()
            EmitirDebugComida(zo_strformat(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_ATTEMPT), finalName))
            if ConsumirComidaEnSlot(bagId, slotIndex, finalName, resolvedLink) then
                VerificarConsumoComidaDebug(foodInfoAntes)
            else
                EmitirDebugComida(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_FAILED))
            end
        end)
    end

    EmitirDebugComida(zo_strformat(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_ATTEMPT), finalName))
    local ok = ConsumirComidaEnSlot(bagId, slotIndex, finalName, resolvedLink)
    if ok then
        VerificarConsumoComidaDebug(foodInfoAntes)
    else
        EmitirDebugComida(GetString(EZO_MSG_DEBUG_FOOD_CONSUME_FAILED))
    end
    return ok
end

function MOD.BuildRecentEntries(options)
    local entries = {}
    local overlaySV = ObtenerFoodSV()
    local history = overlaySV and overlaySV.recentFoodItems or nil
    if type(history) == "table" then
        for _, entry in ipairs(history) do
            if type(entry) == "table" then
                local itemLink = tostring(entry.itemLink or "")
                local itemName = tostring(entry.itemName or "")
                local bagId, slotIndex, resolvedName = MOD.FindFoodByReference(itemLink, itemName)
                local label = NormalizarTextoEtiqueta(tostring(resolvedName or itemName or ""))
                if label ~= "" then
                    local disponible = bagId ~= nil and slotIndex ~= nil
                    entries[#entries + 1] = {
                        text = label,
                        callback = function()
                            if not disponible then
                                return false
                            end
                            return MOD.ConsumeHistoryFood(itemLink, itemName, options)
                        end,
                        enabled = disponible,
                        tooltipText = disponible and nil or GetString(EZO_SIDE_WIDGET_FOOD_HISTORY_MISSING_TOOLTIP),
                        previewKind = "item",
                        previewItemLink = itemLink,
                    }
                end
            end
        end
    end
    if #entries == 0 then
        entries[#entries + 1] = {
            text = GetString(EZO_SIDE_WIDGET_FOOD_HISTORY_EMPTY),
            empty = true,
            callback = function() end,
        }
    end
    return entries
end

function MOD.GetHistoryEmptyLabel()
    return GetString(EZO_SIDE_WIDGET_FOOD_HISTORY_EMPTY)
end

function MOD.BuildLayoutPreviewTooltip()
    local foodInfo = MOD.GetBuffInfo()
    local foodRecordadoBag, _, foodRecordadoNombre, _, foodRecordadoQuality = MOD.FindRecordedFood()
    local foodRecordadoDisponible = foodRecordadoBag ~= nil
    local foodLegendaria = type(ITEM_QUALITY_LEGENDARY) == "number" and foodRecordadoQuality == ITEM_QUALITY_LEGENDARY
    return MOD.BuildTooltip(foodInfo, foodRecordadoNombre, foodRecordadoDisponible, foodLegendaria)
end

function MOD.BuildWidgetData()
    local foodInfo = MOD.GetBuffInfo()
    local foodState = MOD.BuildVisualState(foodInfo)
    local foodPrimaryHandler = nil
    local foodSecondaryHandler = nil
    local foodRecordadoBag, _, foodRecordadoNombre, _, foodRecordadoQuality = MOD.FindRecordedFood()
    local foodRecordadoDisponible = foodRecordadoBag ~= nil
    local foodLegendaria = type(ITEM_QUALITY_LEGENDARY) == "number" and foodRecordadoQuality == ITEM_QUALITY_LEGENDARY

    if foodRecordadoDisponible then
        foodPrimaryHandler = function()
            return MOD.ReuseRecordedFood()
        end
        foodSecondaryHandler = function()
            return false
        end
    end

    return {
        slotKey = "food_buff",
        visible = true,
        texture = "/esoui/art/inventory/inventory_tabIcon_Craftbag_provisioning_up.dds",
        color = foodState.color,
        alpha = foodState.alpha,
        tooltipText = MOD.BuildTooltip(foodInfo, foodRecordadoNombre, foodRecordadoDisponible, foodLegendaria),
        primaryHandler = foodPrimaryHandler,
        secondaryHandler = foodSecondaryHandler,
        pulse = foodState.pulse,
    }
end

function MOD.SetDebugState(state)
    state = zo_strlower(tostring(state or ""))
    if state == "" or state == "auto" or state == "off" then
        foodDebugState = nil
    elseif not (EZO and type(EZO.IsDebugModeEnabled) == "function" and EZO.IsDebugModeEnabled()) then
        return false
    elseif state == "green" or state == "yellow" or state == "red" then
        foodDebugState = state
    else
        return false
    end
    return true
end

function MOD.HasFoodBuff()
    return MOD.GetBuffInfo().active == true
end

-- Resincronizar la caché de mochila al activarse el jugador (login, cambio
-- de zona, reloadui). Es un único escaneo por activación; a partir de ahí
-- la mantienen al día los eventos de hueco individual.
EVENT_MANAGER:RegisterForEvent("EZOTools_Food_Activated",
    EVENT_PLAYER_ACTIVATED,
    function() MOD.SyncBackpackCache() end)
