-- Invitaciones de grupo activadas por palabras configuradas en mensajes de chat.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.GroupAutoinvite = EZO.GroupAutoinvite or {}
local MOD = EZO.GroupAutoinvite

local EVENT_NAMESPACE = "EZOTools_GroupAutoinvite"
local INVITE_COOLDOWN_MS = 15000
local INVITE_DELAY_MS = 100
local recentInvites = {}
local allowedChannels = {}
local initialized = false

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

local function EmitReport(stage, lines)
    if not (EZO and type(EZO.IsDebugModeEnabled) == "function" and EZO.IsDebugModeEnabled()) then
        return
    end
    if not (EZO.Debug and type(EZO.Debug.EmitReport) == "function") then
        return
    end
    local report = {
        "=== EZOTools group autoinvite ===",
        "stage=" .. tostring(stage or ""),
    }
    for _, line in ipairs(lines or {}) do
        report[#report + 1] = tostring(line)
    end
    report[#report + 1] = "================================"
    EZO.Debug.EmitReport(GetString(EZO_DEBUG_GROUP_AUTOINVITE_TITLE), report)
end

local function GetSettings()
    EZO.sv = EZO.sv or {}
    EZO.sv.groupAutoinvite = EZO.sv.groupAutoinvite or {}
    local settings = EZO.sv.groupAutoinvite
    if settings.enabled == nil then settings.enabled = false end
    if settings.keywords == nil then settings.keywords = "" end
    return settings
end

local function Trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function NormalizeForMatch(value)
    value = string.lower(tostring(value or ""))
    value = value:gsub("[%c%p]+", " ")
    value = value:gsub("%s+", " ")
    return Trim(value)
end

function MOD.ParseKeywords(value)
    local keywords = {}
    local seen = {}
    value = tostring(value or ""):gsub("[,;]+", " ")
    for entry in value:gmatch("%S+") do
        local normalized = NormalizeForMatch(entry)
        if normalized ~= "" and not seen[normalized] then
            seen[normalized] = true
            keywords[#keywords + 1] = normalized
        end
    end
    return keywords
end

function MOD.FindMatchingKeyword(message, configuredKeywords)
    local normalizedMessage = NormalizeForMatch(message)
    if normalizedMessage == "" then return nil end
    local paddedMessage = " " .. normalizedMessage .. " "
    for _, keyword in ipairs(MOD.ParseKeywords(configuredKeywords)) do
        if string.find(paddedMessage, " " .. keyword .. " ", 1, true) then
            return keyword
        end
    end
    return nil
end

local function AddAllowedChannel(globalName)
    local channelType = _G[globalName]
    if channelType ~= nil then
        allowedChannels[channelType] = true
    end
end

local function BuildAllowedChannels()
    allowedChannels = {}
    AddAllowedChannel("CHAT_CHANNEL_SAY")
    AddAllowedChannel("CHAT_CHANNEL_YELL")
    AddAllowedChannel("CHAT_CHANNEL_ZONE")
    AddAllowedChannel("CHAT_CHANNEL_WHISPER")
    for index = 1, 5 do
        AddAllowedChannel("CHAT_CHANNEL_GUILD_" .. tostring(index))
    end
    for index = 1, 3 do
        AddAllowedChannel("CHAT_CHANNEL_ZONE_LANGUAGE_" .. tostring(index))
    end
end

local function IsDisplayNameInCurrentGroup(displayName)
    if type(GetGroupSize) ~= "function" or type(GetUnitDisplayName) ~= "function" then
        return false
    end
    local target = string.lower(tostring(displayName or ""))
    if target == "" then return false end
    local groupSize = tonumber(GetGroupSize()) or 0
    for index = 1, groupSize do
        local current = string.lower(tostring(GetUnitDisplayName("group" .. tostring(index)) or ""))
        if current == target then
            return true
        end
    end
    return false
end

local function CanInviteFromCurrentGroup()
    local grouped = type(IsUnitGrouped) == "function" and IsUnitGrouped("player") == true
    if not grouped then return true end
    return type(IsUnitGroupLeader) == "function" and IsUnitGroupLeader("player") == true
end

local function GetInviteTarget(fromName, fromDisplayName)
    local displayName = Trim(fromDisplayName)
    if displayName ~= "" then
        return displayName, displayName
    end

    local characterName = Trim(fromName):gsub("%^.+", "")
    return characterName, characterName
end

local function GetNowMilliseconds()
    if type(GetGameTimeMilliseconds) == "function" then
        return tonumber(GetGameTimeMilliseconds()) or 0
    end
    return 0
end

local function RequestInvite(inviteTarget, displayName, channelType, matchedKeyword)
    local function ExecuteRequest()
        local result = "requested"
        if not CanInviteFromCurrentGroup() then
            result = "not-leader"
            recentInvites[string.lower(displayName)] = nil
        elseif IsDisplayNameInCurrentGroup(displayName) then
            result = "already-grouped"
            recentInvites[string.lower(displayName)] = nil
        elseif type(GroupInviteByName) ~= "function" then
            result = "api-unavailable"
            recentInvites[string.lower(displayName)] = nil
        else
            local ok, err = SafeCall(GroupInviteByName, inviteTarget)
            if not ok then
                result = "request-error: " .. tostring(err or "unknown")
                recentInvites[string.lower(displayName)] = nil
            end
        end

        EmitReport("invite-requested", {
            "chat.channelType=" .. tostring(channelType or ""),
            "chat.sender=" .. tostring(displayName),
            "chat.keyword=" .. tostring(matchedKeyword),
            "invite.target=" .. tostring(inviteTarget),
            "invite.result=" .. tostring(result),
        })
    end

    if type(zo_callLater) == "function" then
        zo_callLater(ExecuteRequest, INVITE_DELAY_MS)
    else
        ExecuteRequest()
    end
end

local function OnChatMessage(_, channelType, fromName, text, isCustomerService, fromDisplayName)
    local settings = GetSettings()
    if settings.enabled ~= true then
        return
    end

    local inviteTarget, displayName = GetInviteTarget(fromName, fromDisplayName)
    local matchedKeyword = MOD.FindMatchingKeyword(text, settings.keywords)
    if matchedKeyword then
        EmitReport("keyword-detected", {
            "chat.channelType=" .. tostring(channelType or ""),
            "chat.whisperChannelType=" .. tostring(_G.CHAT_CHANNEL_WHISPER or ""),
            "chat.channelAllowed=" .. tostring(allowedChannels[channelType] == true),
            "chat.customerService=" .. tostring(isCustomerService == true),
            "chat.sender=" .. tostring(displayName),
            "chat.keyword=" .. tostring(matchedKeyword),
        })
    end

    if not matchedKeyword or not allowedChannels[channelType] or isCustomerService == true then
        return
    end

    local ownDisplayName = type(GetDisplayName) == "function" and Trim(GetDisplayName()) or ""
    if displayName == "" or string.lower(displayName) == string.lower(ownDisplayName) then
        return
    end

    local result = "scheduled"
    if not CanInviteFromCurrentGroup() then
        result = "not-leader"
    elseif IsDisplayNameInCurrentGroup(displayName) then
        result = "already-grouped"
    elseif type(GroupInviteByName) ~= "function" then
        result = "api-unavailable"
    else
        local nowMs = GetNowMilliseconds()
        local previousMs = tonumber(recentInvites[string.lower(displayName)]) or 0
        if nowMs > 0 and previousMs > 0 and (nowMs - previousMs) < INVITE_COOLDOWN_MS then
            result = "cooldown"
        else
            recentInvites[string.lower(displayName)] = nowMs
            RequestInvite(inviteTarget, displayName, channelType, matchedKeyword)
        end
    end

    EmitReport("keyword-evaluated", {
        "chat.channelType=" .. tostring(channelType or ""),
        "chat.sender=" .. tostring(displayName),
        "chat.keyword=" .. tostring(matchedKeyword),
        "invite.target=" .. tostring(inviteTarget),
        "invite.result=" .. tostring(result),
    })
end

local function OnGroupInviteResponse(_, inviteeName, responseCode)
    EmitReport("invite-response", {
        "invite.name=" .. tostring(inviteeName or ""),
        "invite.responseCode=" .. tostring(responseCode or ""),
    })
end

local function RegisterEvent(eventManager, eventId, callback)
    if eventId == nil then
        return false, "event-unavailable"
    end

    if type(eventManager.UnregisterForEvent) == "function" then
        pcall(eventManager.UnregisterForEvent, eventManager, EVENT_NAMESPACE, eventId)
    end
    return pcall(eventManager.RegisterForEvent, eventManager, EVENT_NAMESPACE, eventId, callback)
end

function MOD.Initialize()
    local eventManager = _G.EVENT_MANAGER
    if not eventManager or type(eventManager.RegisterForEvent) ~= "function" then
        EmitReport("initialization-failed", {
            "eventManager.type=" .. tostring(type(eventManager)),
            "eventManager.registerAvailable=false",
        })
        return false
    end

    BuildAllowedChannels()
    local chatRegistered, chatError = RegisterEvent(eventManager, EVENT_CHAT_MESSAGE_CHANNEL, OnChatMessage)
    local responseRegistered, responseError = RegisterEvent(
        eventManager,
        _G.EVENT_GROUP_INVITE_RESPONSE,
        OnGroupInviteResponse
    )
    initialized = chatRegistered == true

    local settings = GetSettings()
    EmitReport("initialization", {
        "eventManager.type=" .. tostring(type(eventManager)),
        "chat.eventId=" .. tostring(EVENT_CHAT_MESSAGE_CHANNEL or ""),
        "chat.registered=" .. tostring(chatRegistered == true),
        "chat.error=" .. tostring(chatError or ""),
        "chat.whisperChannelType=" .. tostring(_G.CHAT_CHANNEL_WHISPER or ""),
        "response.eventId=" .. tostring(_G.EVENT_GROUP_INVITE_RESPONSE or ""),
        "response.registered=" .. tostring(responseRegistered == true),
        "response.error=" .. tostring(responseError or ""),
        "settings.enabled=" .. tostring(settings.enabled == true),
        "settings.keywordCount=" .. tostring(#MOD.ParseKeywords(settings.keywords)),
    })
    return initialized
end

function MOD.GetSettings()
    return GetSettings()
end

function MOD.IsInitialized()
    return initialized
end
