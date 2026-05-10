-- Proveedor comun para aliados/coleccionables de HOLD Y y los iconos del overlay.
-- Mantiene configuracion e historiales fuera de overlay.lua; la ejecucion visual
-- sigue delegada en el overlay para no alterar el flujo estable de UseCollectible.
EZOTools_QuickUtilityAllies = EZOTools_QuickUtilityAllies or {}

local MOD = EZOTools_QuickUtilityAllies
local EZO = EZOTools

local ALLY_CONFIG = {
    mount = {
        rememberedKey = "lastMountCollectibleId",
        historyKey = "recentMountCollectibles",
        fallbackNameKey = "EZO_DOT_MOUNT_FALLBACK_NAME",
        historyEmptyKey = "EZO_DOT_MOUNT_HISTORY_EMPTY",
        emptyActionKey = "EZO_UTILITY_EMPTY_OPEN_MOUNT_COLLECTIONS",
        collectibleCategoryType = COLLECTIBLE_CATEGORY_TYPE_MOUNT,
        openCategoryRoot = true,
        historyLimit = 10,
        showRecentHoverPreview = true,
    },
    pet = {
        rememberedKey = "lastPetCollectibleId",
        historyKey = "recentPetCollectibles",
        fallbackNameKey = "EZO_DOT_PET_FALLBACK_NAME",
        historyEmptyKey = "EZO_DOT_PET_HISTORY_EMPTY",
        emptyActionKey = "EZO_UTILITY_EMPTY_OPEN_PET_COLLECTIONS",
        collectibleCategoryType = COLLECTIBLE_CATEGORY_TYPE_VANITY_PET,
        openCategoryRoot = true,
        historyLimit = 10,
        showRecentHoverPreview = true,
    },
    companion = {
        rememberedKey = "lastCompanionCollectibleId",
        historyKey = "recentCompanionCollectibles",
        fallbackNameKey = "EZO_DOT_COMPANION_FALLBACK_NAME",
        historyEmptyKey = "EZO_DOT_COMPANION_HISTORY_EMPTY",
        emptyActionKey = "EZO_UTILITY_EMPTY_OPEN_COMPANION_COLLECTIONS",
        collectibleCategoryType = COLLECTIBLE_CATEGORY_TYPE_COMPANION,
        historyLimit = 5,
        showRecentHoverPreview = true,
    },
    assistant = {
        rememberedKey = "lastAssistantCollectibleId",
        historyKey = "recentAssistantCollectibles",
        fallbackNameKey = "EZO_DOT_ASSISTANT_FALLBACK_NAME",
        historyEmptyKey = "EZO_DOT_ASSISTANT_HISTORY_EMPTY",
        emptyActionKey = "EZO_UTILITY_EMPTY_OPEN_ASSISTANT_COLLECTIONS",
        collectibleCategoryType = COLLECTIBLE_CATEGORY_TYPE_ASSISTANT,
        historyLimit = 5,
        showRecentHoverPreview = true,
    },
}

local function OverlaySV()
    return EZO and EZO.sv and EZO.sv.overlay or nil
end

local function GetStringByName(name)
    local stringId = type(name) == "string" and _G[name] or nil
    if stringId ~= nil and type(GetString) == "function" then
        return GetString(stringId)
    end
    return ""
end

local function ResolveCollectibleName(collectibleId, fallback)
    collectibleId = tonumber(collectibleId) or 0
    local getCollectibleName = _G.GetCollectibleName
    if collectibleId > 0 and type(getCollectibleName) == "function" then
        local ok, name = pcall(getCollectibleName, collectibleId)
        if ok and type(name) == "string" and name ~= "" then
            return zo_strformat("<<C:1>>", name)
        end
    end
    return tostring(fallback or "")
end

function MOD.GetConfig(kind)
    return ALLY_CONFIG[tostring(kind or "")]
end

function MOD.GetRemembered(kind)
    local config = MOD.GetConfig(kind)
    local overlaySV = OverlaySV()
    if not (config and overlaySV) then return 0 end
    local collectibleId = tonumber(overlaySV[config.rememberedKey]) or 0
    if collectibleId < 0 then return 0 end
    return collectibleId
end

function MOD.SetRemembered(kind, collectibleId)
    local config = MOD.GetConfig(kind)
    local overlaySV = OverlaySV()
    collectibleId = tonumber(collectibleId) or 0
    if not (config and overlaySV) or collectibleId <= 0 then return end
    overlaySV[config.rememberedKey] = collectibleId
end

function MOD.GetHistory(kind)
    local config = MOD.GetConfig(kind)
    local overlaySV = OverlaySV()
    if not (config and overlaySV) then return {} end
    local history = overlaySV[config.historyKey]
    if type(history) ~= "table" then return {} end
    return history
end

function MOD.AddToHistory(kind, collectibleId)
    local config = MOD.GetConfig(kind)
    local overlaySV = OverlaySV()
    collectibleId = tonumber(collectibleId) or 0
    if not (config and overlaySV) or collectibleId <= 0 then return end

    local history = overlaySV[config.historyKey]
    if type(history) ~= "table" then
        history = {}
        overlaySV[config.historyKey] = history
    end

    local limit = tonumber(config.historyLimit) or 5
    local nextHistory = { collectibleId }
    for _, entryId in ipairs(history) do
        local value = tonumber(entryId) or 0
        if value > 0 and value ~= collectibleId then
            nextHistory[#nextHistory + 1] = value
        end
        if #nextHistory >= limit then break end
    end
    overlaySV[config.historyKey] = nextHistory
end

function MOD.GetFallbackName(kind)
    local config = MOD.GetConfig(kind)
    return GetStringByName(config and config.fallbackNameKey)
end

function MOD.GetHistoryEmptyLabel(kind)
    local config = MOD.GetConfig(kind)
    return GetStringByName(config and config.historyEmptyKey)
end

function MOD.GetEmptyActionLabel(kind)
    local config = MOD.GetConfig(kind)
    return GetStringByName(config and config.emptyActionKey)
end

function MOD.BuildRecentEntries(kind, includeEmptyAction, callbackFactory, emptyCallback)
    local config = MOD.GetConfig(kind)
    local entries = {}
    if not config then return entries end

    for _, collectibleId in ipairs(MOD.GetHistory(kind)) do
        local finalId = tonumber(collectibleId) or 0
        if finalId > 0 then
            entries[#entries + 1] = {
                text = ResolveCollectibleName(finalId, MOD.GetFallbackName(kind)),
                callback = type(callbackFactory) == "function" and callbackFactory(finalId) or nil,
                previewCollectibleId = finalId,
            }
        end
    end

    local emptyLabel = MOD.GetEmptyActionLabel(kind)
    if includeEmptyAction == true and emptyLabel ~= "" then
        entries[#entries + 1] = {
            text = emptyLabel,
            callback = emptyCallback,
            empty = false,
        }
    end

    if #entries == 0 then
        entries[#entries + 1] = {
            text = MOD.GetHistoryEmptyLabel(kind),
            empty = true,
            callback = function() end,
        }
    end

    return entries
end
