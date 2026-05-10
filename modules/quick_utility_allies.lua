-- Proveedor comun para aliados/coleccionables de HOLD Y y los iconos del overlay.
-- Mantiene configuracion, historiales y ejecucion fuera de overlay.lua.
EZOTools_QuickUtilityAllies = EZOTools_QuickUtilityAllies or {}

local MOD = EZOTools_QuickUtilityAllies
local EZO = EZOTools

local ALLY_SWITCH_INITIAL_DELAY_MS = 1500
local ALLY_SWITCH_RETRY_DELAY_MS = 500
local ALLY_SWITCH_MAX_RETRIES = 6
local switchPending = false

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

local function UseCollectibleById(collectibleId, delayMs)
    if type(UseCollectible) ~= "function" then
        return false
    end
    collectibleId = tonumber(collectibleId) or 0
    if collectibleId <= 0 then
        return false
    end

    local delay = math.max(0, tonumber(delayMs) or 0)
    if delay > 0 and type(zo_callLater) == "function" then
        zo_callLater(function()
            UseCollectible(collectibleId)
        end, delay)
    else
        UseCollectible(collectibleId)
    end
    return true
end

local function ScheduleSwitch(targetKind, stillActiveFn, hideActiveFn, targetCollectibleId)
    if switchPending then
        return false
    end
    if type(stillActiveFn) ~= "function" or type(hideActiveFn) ~= "function" then
        return false
    end
    if not hideActiveFn() then
        return false
    end
    switchPending = true

    local function TryInvokeRemaining(attempts)
        if stillActiveFn() then
            if attempts > 0 and type(zo_callLater) == "function" then
                zo_callLater(function()
                    TryInvokeRemaining(attempts - 1)
                end, ALLY_SWITCH_RETRY_DELAY_MS)
            else
                switchPending = false
            end
            return
        end

        if targetCollectibleId and targetCollectibleId ~= 0 then
            UseCollectibleById(targetCollectibleId, 100)
        else
            MOD.UseRemembered(targetKind, 100)
        end
        switchPending = false
    end

    if type(zo_callLater) == "function" then
        zo_callLater(function()
            TryInvokeRemaining(ALLY_SWITCH_MAX_RETRIES)
        end, ALLY_SWITCH_INITIAL_DELAY_MS)
    else
        TryInvokeRemaining(0)
    end
    return true
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

function MOD.GetActiveId(kind)
    kind = tostring(kind or "")

    if kind == "pet" then
        if type(GetActiveCollectibleByType) ~= "function" then return 0 end
        return GetActiveCollectibleByType(
            COLLECTIBLE_CATEGORY_TYPE_VANITY_PET,
            GAMEPLAY_ACTOR_CATEGORY_PLAYER) or 0
    end

    if kind == "mount" then
        if type(GetActiveCollectibleByType) ~= "function" then return 0 end
        local mountId = GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT) or 0
        if mountId == 0 and GAMEPLAY_ACTOR_CATEGORY_PLAYER then
            local ok, value = pcall(GetActiveCollectibleByType, COLLECTIBLE_CATEGORY_TYPE_MOUNT, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
            if ok then
                mountId = tonumber(value) or 0
            end
        end
        return mountId
    end

    if kind == "assistant" then
        if type(GetActiveCollectibleByType) ~= "function" then return 0 end
        return GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_ASSISTANT) or 0
    end

    if kind == "companion" then
        if not (HasActiveCompanion and HasActiveCompanion()) then return 0 end
        if type(GetActiveCompanionDefId) ~= "function"
            or type(GetCompanionCollectibleId) ~= "function" then
            return 0
        end
        local companionId = GetActiveCompanionDefId()
        if not companionId or companionId == 0 then return 0 end
        return GetCompanionCollectibleId(companionId) or 0
    end

    return 0
end

function MOD.IsMounted()
    return type(IsMounted) == "function" and IsMounted() == true
end

function MOD.IsActive(kind)
    kind = tostring(kind or "")
    if kind == "mount" then
        return MOD.IsMounted() and MOD.GetActiveId("mount") ~= 0
    end
    return MOD.GetActiveId(kind) ~= 0
end

function MOD.UseById(collectibleId, delayMs)
    return UseCollectibleById(collectibleId, delayMs)
end

function MOD.UseRemembered(kind, delayMs)
    return UseCollectibleById(MOD.GetRemembered(kind), delayMs)
end

function MOD.HideActive(kind)
    kind = tostring(kind or "")

    if kind == "pet" or kind == "assistant" then
        return UseCollectibleById(MOD.GetActiveId(kind))
    end

    if kind == "companion" then
        if HasActiveCompanion and HasActiveCompanion() then
            local collectibleId = MOD.GetActiveId("companion")
            if collectibleId ~= 0 and UseCollectibleById(collectibleId) then
                return true
            end
            if type(DismissCompanion) == "function" then
                DismissCompanion()
                return true
            end
        end
        return false
    end

    return false
end

function MOD.InvokeRemembered(kind)
    kind = tostring(kind or "")

    if kind == "mount" then
        local activeMountId = MOD.GetActiveId("mount")
        if activeMountId ~= 0 then
            return UseCollectibleById(activeMountId)
        end
        return MOD.UseRemembered("mount")
    end

    if kind == "companion" then
        if MOD.GetActiveId("assistant") ~= 0 then
            return ScheduleSwitch(
                "companion",
                function() return MOD.GetActiveId("assistant") ~= 0 end,
                function() return MOD.HideActive("assistant") end
            )
        end
        return MOD.UseRemembered("companion")
    end

    if kind == "pet" or kind == "assistant" then
        return MOD.UseRemembered(kind)
    end

    return false
end

function MOD.InvokeFromHistory(kind, collectibleId)
    kind = tostring(kind or "")
    collectibleId = tonumber(collectibleId) or 0
    if not MOD.GetConfig(kind) or collectibleId <= 0 then
        return false
    end

    MOD.SetRemembered(kind, collectibleId)
    MOD.AddToHistory(kind, collectibleId)

    if kind == "companion" and MOD.GetActiveId("assistant") ~= 0 then
        return ScheduleSwitch(
            "companion",
            function() return MOD.GetActiveId("assistant") ~= 0 end,
            function() return MOD.HideActive("assistant") end,
            collectibleId
        )
    end

    return UseCollectibleById(collectibleId)
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
