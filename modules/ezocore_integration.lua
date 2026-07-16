-- Optional local integration with EZOCore.
-- EZOTools must keep working when EZOCore is not installed.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.EZOCoreIntegration = EZO.EZOCoreIntegration or {}
local MOD = EZO.EZOCoreIntegration
MOD.GROUP_ACTIVITY_API_VERSION = 2

local registered = false
local languageCallbackRegistered = false
local layoutSurfacesRegistered = false
local debugControllerRegistered = false
local activityCallbackRegistered = false
local presenceRequestCallbackRegistered = false
local GetEZOCore

local function Debug(message)
    if EZO and type(EZO.DebugPrint) == "function" then
        EZO.DebugPrint("[EZOCore] " .. tostring(message))
    end
end

function MOD.RegisterDebugController()
    if debugControllerRegistered then
        return true
    end

    local core = GetEZOCore()
    if not core or type(core.GetService) ~= "function" then
        return false
    end

    local service = core:GetService("family.debug", 1)
    if not service or type(service.RegisterController) ~= "function" then
        return false
    end

    local ok, result = pcall(function()
        return service:RegisterController({
            id = "ezotools.debug",
            addonId = "ezotools",
            addonName = "EZOTools",
            name = function() return GetString(EZO_OPTION_DEBUG_MODE) end,
            isEnabled = function()
                return EZO.IsDebugModeEnabled and EZO.IsDebugModeEnabled() == true
            end,
            setEnabled = function(enabled)
                if EZO.SetDebugModeEnabled then
                    EZO.SetDebugModeEnabled(enabled == true)
                end
                return EZO.IsDebugModeEnabled and EZO.IsDebugModeEnabled() == (enabled == true)
            end,
        })
    end)

    debugControllerRegistered = ok and result == true
    return debugControllerRegistered
end

GetEZOCore = function()
    local core = _G.EZOCore
    if type(core) ~= "table" or type(core.RegisterAddon) ~= "function" then
        return nil
    end
    return core
end

local function IsSupportedLanguage(language)
    return language == "es" or language == "en"
end

local function OnCoreLanguageChanged()
    if not EZO.sv or not EZO.sv.general then
        return
    end

    local language = EZO.sv.general.language or (EZO.GetDefaultLanguage and EZO.GetDefaultLanguage()) or "auto"
    if type(EZO.ApplyLanguagePreference) == "function" then
        EZO.ApplyLanguagePreference(language)
    elseif EZO_Lang and type(EZO_Lang.Apply) == "function" then
        EZO_Lang.Apply(language)
    end

    if EZOTools_Overlay and type(EZOTools_Overlay.Refresh) == "function" then
        EZOTools_Overlay.Refresh()
    end
end

function MOD.IsAvailable()
    return GetEZOCore() ~= nil
end

function MOD.IsLanguageManagedByEZOCore()
    local core = GetEZOCore()
    if not core or type(core.IsLanguageGloballyManaged) ~= "function" then
        return false
    end

    local ok, managed = pcall(function()
        return core:IsLanguageGloballyManaged()
    end)
    return ok and managed == true
end

function MOD.GetLanguage()
    local core = GetEZOCore()
    if not MOD.IsLanguageManagedByEZOCore() or not core or type(core.GetLanguage) ~= "function" then
        return nil
    end

    local ok, language = pcall(function()
        return core:GetLanguage()
    end)
    if ok and IsSupportedLanguage(language) then
        return language
    end
    return nil
end

function MOD.GetGroupPresenceService()
    local core = GetEZOCore()
    if not core or type(core.GetService) ~= "function" then
        return nil
    end

    local ok, service = pcall(function()
        return core:GetService("family.groupPresence", 1)
    end)
    if ok and type(service) == "table" then
        return service
    end
    return nil
end

function MOD.GetGroupPresenceStatus()
    local service = MOD.GetGroupPresenceService()
    if not service or type(service.GetStatus) ~= "function" then
        return nil
    end

    local ok, status = pcall(service.GetStatus)
    if ok and type(status) == "table" then
        return status
    end
    return nil
end

function MOD.RequestGroupPresence()
    local service = MOD.GetGroupPresenceService()
    if not service or type(service.RequestPresence) ~= "function" then
        return false, "serviceMissing"
    end

    local ok, result, reason = pcall(service.RequestPresence)
    if ok then
        return result == true, reason
    end
    return false, tostring(result or "requestFailed")
end

function MOD.PublishGroupActivityState(state)
    local service = MOD.GetGroupPresenceService()
    if not service or type(service.PublishActivityState) ~= "function" then
        return false, "serviceMissing"
    end

    local ok, published, reason = pcall(service.PublishActivityState, service, state)
    if ok then
        return published == true, reason
    end
    return false, tostring(published or "publishFailed")
end

function MOD.GetPeerActivityState(unitTag)
    local service = MOD.GetGroupPresenceService()
    if not service or type(service.GetPeerActivityState) ~= "function" then
        return nil
    end

    local ok, state = pcall(service.GetPeerActivityState, service, unitTag)
    if ok and type(state) == "table" then
        return state
    end
    return nil
end

function MOD.GetPeerCompatibility(unitTag, addonId, capability, minimumApiVersion)
    local service = MOD.GetGroupPresenceService()
    if not service or type(service.GetPeerCompatibility) ~= "function" then
        return "unknown"
    end

    local ok, compatibility = pcall(service.GetPeerCompatibility, service, unitTag, addonId, capability, minimumApiVersion)
    if ok and type(compatibility) == "string" then
        return compatibility
    end
    return "unknown"
end

function MOD.RegisterLanguageCallback()
    if languageCallbackRegistered then
        return true
    end

    local core = GetEZOCore()
    if not core or type(core.RegisterCallback) ~= "function" then
        return false
    end

    local eventName = core.EVENT_LANGUAGE_CHANGED or "EZO_CORE_LANGUAGE_CHANGED"
    local ok, result = pcall(function()
        return core:RegisterCallback(eventName, OnCoreLanguageChanged)
    end)
    if ok and result == true then
        languageCallbackRegistered = true
        return true
    end
    return false
end

local function OnGroupActivityStateUpdated(unitTag, state)
    if type(state) ~= "table" or tostring(state.sourceAddonId or "") ~= "ezotools" then
        return
    end
    if type(EZO.IsDebugModeEnabled) == "function"
        and EZO.IsDebugModeEnabled()
        and EZO._debugLoggerUnavailable ~= true then
        Debug(string.format(
            "Activity state received: leader=%s session=%s target=%s stage=%s result=%s difficulty=%s progress=%s/%s pending=%s/%s ttl=%s",
            tostring(unitTag or ""),
            tostring(state.sessionId or ""),
            tostring(state.targetKey or ""),
            tostring(state.stage or ""),
            tostring(state.result or ""),
            tostring(state.difficulty or "unknown"),
            tostring(state.progressCurrent or 0),
            tostring(state.progressTotal or 0),
            tostring(state.pendingCount or 0),
            tostring(state.expectedCount or 0),
            tostring(state.ttlSeconds or 0)))
    end
    local peerPanel = EZO and EZO.GroupActivityPeerPanel
    if peerPanel and type(peerPanel.SetLeaderActivityState) == "function" then
        peerPanel.SetLeaderActivityState(unitTag, state)
    end
    local memberTravel = EZO and EZO.GroupActivityMemberTravel
    if memberTravel and type(memberTravel.OnLeaderActivityState) == "function" then
        memberTravel.OnLeaderActivityState(unitTag, state)
    end
end

local function OnGroupPresenceRequested()
    local sharing = EZO and EZO.GroupActivitySharing
    if sharing and type(sharing.RepublishCurrentResetState) == "function" then
        sharing.RepublishCurrentResetState(1000)
    end
end

function MOD.RegisterGroupActivityCallbacks()
    local core = GetEZOCore()
    if not core or type(core.RegisterCallback) ~= "function" then
        return false
    end

    if not activityCallbackRegistered then
        local ok, result = pcall(function()
            return core:RegisterCallback("EZO_CORE_GROUP_ACTIVITY_STATE_UPDATED", OnGroupActivityStateUpdated)
        end)
        activityCallbackRegistered = ok and result == true
    end

    if not presenceRequestCallbackRegistered then
        local ok, result = pcall(function()
            return core:RegisterCallback("EZO_CORE_GROUP_PRESENCE_REQUESTED", OnGroupPresenceRequested)
        end)
        presenceRequestCallbackRegistered = ok and result == true
    end
    return activityCallbackRegistered
end

function MOD.RegisterLocalAddon()
    if registered then
        MOD.RegisterDebugController()
        MOD.RegisterGroupActivityCallbacks()
        return true
    end

    local core = GetEZOCore()
    if not core then
        Debug("EZOCore not installed; continuing with local-only EZOTools behavior.")
        return false
    end

    local ok, result = pcall(function()
        return core:RegisterAddon({
            id = "ezotools",
            name = EZO.ADDON_NAME or "EZOTools",
            version = EZO.ADDON_VERSION or "0.0.0",
            addOnVersion = tonumber(EZO.ADDON_VERSION_NUMERIC) or 0,
            apiVersion = MOD.GROUP_ACTIVITY_API_VERSION,
            capabilities = {
                "group.activities",
                "group.activityState.provider",
                "group.activityState.consumer",
                "family.debug.controller",
                "family.language.consumer",
                "family.layout.consumer",
            },
        })
    end)

    if ok and result == true then
        registered = true
        MOD.RegisterDebugController()
        MOD.RegisterLanguageCallback()
        MOD.RegisterGroupActivityCallbacks()
        Debug("Registered EZOTools with EZOCore.")
        return true
    end

    Debug("EZOCore registration skipped or rejected: " .. tostring(result))
    return false
end

function MOD.RegisterLayoutSurfaces()
    if layoutSurfacesRegistered then
        return true
    end

    local core = GetEZOCore()
    if not core or type(core.GetService) ~= "function" then
        return false
    end

    local service = core:GetService("family.layout", 1)
    if not service or type(service.RegisterSurface) ~= "function" then
        return false
    end

    local definitions = {
        {
            id = "ezotools.overlay",
            name = EZO_OPTION_OVERLAY,
            tooltip = EZO_OPTION_OVERLAY_NOTE,
            order = 10,
            setEditMode = function(enabled)
                EZOTools_Overlay.SetLayoutEditMode(enabled)
                return EZOTools_Overlay.IsLayoutEditMode() == (enabled == true)
            end,
            isEditMode = function()
                return EZOTools_Overlay.IsLayoutEditMode()
            end,
        },
        {
            id = "ezotools.reset-status",
            name = EZO_OPTION_INSTANCE_RESET_MOVE_STATUS_WINDOW,
            tooltip = EZO_OPTION_INSTANCE_RESET_MOVE_STATUS_WINDOW_TOOLTIP,
            order = 20,
            setEditMode = function(enabled)
                local reset = EZO and EZO.RaidLeaderReset
                if not reset
                    or type(reset.SetStatusWindowUnlocked) ~= "function"
                    or type(reset.IsStatusWindowUnlocked) ~= "function"
                then
                    return false
                end
                reset.SetStatusWindowUnlocked(enabled)
                return reset.IsStatusWindowUnlocked() == (enabled == true)
            end,
            isEditMode = function()
                local reset = EZO and EZO.RaidLeaderReset
                if not reset or type(reset.IsStatusWindowUnlocked) ~= "function" then
                    return false
                end
                return reset.IsStatusWindowUnlocked() == true
            end,
        },
    }

    for _, definition in ipairs(definitions) do
        local nameStringId = definition.name
        local tooltipStringId = definition.tooltip
        local ok, result = pcall(function()
            return service:RegisterSurface({
                id = definition.id,
                addonId = "ezotools",
                addonName = "EZOTools",
                name = function() return GetString(nameStringId) end,
                tooltip = function() return GetString(tooltipStringId) end,
                sortOrder = definition.order,
                setEditMode = definition.setEditMode,
                isEditMode = definition.isEditMode,
            })
        end)
        if not ok or result ~= true then
            return false
        end
    end

    layoutSurfacesRegistered = true
    return true
end
