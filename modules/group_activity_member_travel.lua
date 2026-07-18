-- Optional member-side travel reaction to validated EZOCore activity state.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.GroupActivityMemberTravel = EZO.GroupActivityMemberTravel or {}
local MOD = EZO.GroupActivityMemberTravel

local EVENT_NAMESPACE = "EZOTools_GroupActivityMemberTravel"
local RETRY_DELAY_MS = 1500
local MAX_READINESS_CHECKS = 10

local pendingState
local pendingLeaderUnitTag
local readinessChecks = 0
local retryToken = 0
local lastHandledSessionKey
local initialized = false

local function IsEnabled()
    local settings = EZO and EZO.sv and EZO.sv.groupActivities
    return settings and settings.autoTravelToLeaderAfterRegroup == true
end

local function IsGroupedMember()
    if type(IsUnitGrouped) ~= "function" or not IsUnitGrouped("player") then
        return false
    end
    return type(IsUnitGroupLeader) ~= "function" or not IsUnitGroupLeader("player")
end

local function GetSessionKey(state)
    return table.concat({
        tostring(state and state.sourceAddonId or ""),
        tostring(state and state.sessionId or ""),
        tostring(state and state.targetKey or ""),
    }, "|")
end

local function GetParticipantSession()
    local participantSession = EZO and EZO.GroupActivityParticipantSession
    if participantSession and type(participantSession.Get) == "function" then
        local session = participantSession.Get()
        if type(session) == "table" then
            return participantSession, session
        end
    end
    return participantSession, nil
end

local function IsEligibleState(state)
    if type(state) ~= "table" or tostring(state.sourceAddonId or "") ~= "ezotools" then
        return false
    end
    local activityType = tostring(state.activityType or "")
    if activityType ~= "trial" and activityType ~= "dungeon" and activityType ~= "arena" then
        return false
    end
    local stage = tostring(state.stage or "")
    local result = tostring(state.result or "")
    return (stage == "waitingMembers" or stage == "complete")
        and (result == "active" or result == "complete")
        and tostring(state.targetKey or "") ~= ""
end

local function ResolveCurrentLeaderUnitTag()
    local leaderUnitTag = type(GetGroupLeaderUnitTag) == "function" and GetGroupLeaderUnitTag() or nil
    if type(leaderUnitTag) == "string" and leaderUnitTag ~= "" then
        local _, session = GetParticipantSession()
        local expectedDisplayName = session and tostring(session.leaderDisplayName or "") or ""
        if expectedDisplayName == "" or type(GetUnitDisplayName) ~= "function" then
            return leaderUnitTag
        end
        local ok, displayName = pcall(GetUnitDisplayName, leaderUnitTag)
        if ok and tostring(displayName or "") == expectedDisplayName then
            return leaderUnitTag
        end
    end

    local participantSession = EZO and EZO.GroupActivityParticipantSession
    if participantSession and type(participantSession.GetCurrentLeaderUnitTag) == "function" then
        leaderUnitTag = participantSession.GetCurrentLeaderUnitTag()
        if type(leaderUnitTag) == "string" and leaderUnitTag ~= "" then
            return leaderUnitTag
        end
    end
    return nil
end

local function SeedPendingFromParticipantSession()
    local participantSession, session = GetParticipantSession()
    if not (participantSession and session and type(session.leaderState) == "table") then
        return false
    end
    if pendingState and tonumber(pendingState.sessionId) == tonumber(session.leaderState.sessionId) then
        return true
    end
    if not IsEligibleState(session.leaderState) then
        return false
    end

    local receivedAt = tonumber(session.leaderState.receivedAt)
        or (type(GetFrameTimeSeconds) == "function" and tonumber(GetFrameTimeSeconds()))
        or 0
    pendingState = {
        sourceAddonId = session.leaderState.sourceAddonId or "ezotools",
        activityType = session.leaderState.activityType,
        stage = session.leaderState.stage,
        result = session.leaderState.result,
        sessionId = session.leaderState.sessionId,
        targetKey = session.leaderState.targetKey,
        expiresAt = tonumber(session.leaderState.expiresAt)
            or (receivedAt + (tonumber(session.leaderState.ttlSeconds) or 0)),
    }
    pendingLeaderUnitTag = participantSession.GetCurrentLeaderUnitTag
        and participantSession.GetCurrentLeaderUnitTag()
        or tostring(session.leaderUnitTag or "")
    readinessChecks = 0
    retryToken = retryToken + 1
    return true
end

local function EmitResult(result, reason, jumpResult)
    if not (EZO and EZO.Debug and type(EZO.Debug.EmitReport) == "function") then
        return
    end
    EZO.Debug.EmitReport(GetString(EZO_DEBUG_GROUP_ACTIVITY_MEMBER_TRAVEL_TITLE), {
        "result=" .. tostring(result or ""),
        "reason=" .. tostring(reason or ""),
        "jumpResult=" .. tostring(jumpResult or ""),
        "leaderUnitTag=" .. tostring(pendingLeaderUnitTag or ""),
        "sessionId=" .. tostring(pendingState and pendingState.sessionId or ""),
        "targetKey=" .. tostring(pendingState and pendingState.targetKey or ""),
        "readinessChecks=" .. tostring(readinessChecks),
    }, { level = "info" })
end

local function ClearPending()
    pendingState = nil
    pendingLeaderUnitTag = nil
    readinessChecks = 0
    retryToken = retryToken + 1
end

local TryAutoTravel

local function ScheduleRetry()
    if type(zo_callLater) ~= "function" then
        return false
    end
    retryToken = retryToken + 1
    local expectedToken = retryToken
    zo_callLater(function()
        if expectedToken == retryToken then
            TryAutoTravel()
        end
    end, RETRY_DELAY_MS)
    return true
end

local function RetryOrStop(reason, jumpResult)
    readinessChecks = readinessChecks + 1
    if readinessChecks < MAX_READINESS_CHECKS and ScheduleRetry() then
        return false
    end
    EmitResult("skipped", reason, jumpResult)
    ClearPending()
    return false
end

TryAutoTravel = function()
    if not pendingState and not SeedPendingFromParticipantSession() then
        return false
    end
    if not IsEnabled() then
        ClearPending()
        return false
    end

    local now = type(GetFrameTimeSeconds) == "function" and tonumber(GetFrameTimeSeconds()) or 0
    if tonumber(pendingState.expiresAt) and pendingState.expiresAt <= now then
        EmitResult("skipped", "state-expired")
        ClearPending()
        return false
    end
    if not IsGroupedMember() then
        return RetryOrStop("not-grouped-member")
    end

    local leaderUnitTag = ResolveCurrentLeaderUnitTag()
    if not leaderUnitTag or leaderUnitTag == "" then
        return RetryOrStop("leader-unavailable")
    end
    pendingLeaderUnitTag = leaderUnitTag

    local sessionKey = GetSessionKey(pendingState)
    if sessionKey == lastHandledSessionKey then
        ClearPending()
        return false
    end

    if type(IsGroupMemberInSameInstanceAsPlayer) ~= "function" then
        return RetryOrStop("instance-check-unavailable")
    end
    local instanceCheckOk, sameInstance = pcall(IsGroupMemberInSameInstanceAsPlayer, leaderUnitTag)
    if not instanceCheckOk then
        return RetryOrStop("instance-check-failed")
    end
    if sameInstance == true then
        EmitResult("skipped", "already-same-instance")
        lastHandledSessionKey = sessionKey
        ClearPending()
        return false
    end

    local canJump, jumpResult = false, nil
    if type(CanJumpToGroupMember) == "function" then
        local ok, available, result = pcall(CanJumpToGroupMember, leaderUnitTag)
        canJump = ok and available == true
        jumpResult = result
    end
    if not canJump then
        return RetryOrStop("jump-unavailable", jumpResult)
    end

    local requested, reason = false, "jump-api-unavailable"
    if EZO and type(EZO.JumpToLeader) == "function" then
        requested, reason = EZO.JumpToLeader({
            silent = true,
            allowFallback = false,
            leaderUnitTag = leaderUnitTag,
        })
    end
    if requested == true then
        lastHandledSessionKey = sessionKey
        EmitResult("requested", reason, jumpResult)
        ClearPending()
        return true
    end

    return RetryOrStop(reason, jumpResult)
end

function MOD.OnLeaderActivityState(unitTag, state)
    if not IsEnabled() or not IsEligibleState(state) then
        return false
    end
    local receivedAt = tonumber(state.receivedAt)
        or (type(GetFrameTimeSeconds) == "function" and tonumber(GetFrameTimeSeconds()))
        or 0
    pendingState = {
        sourceAddonId = state.sourceAddonId,
        activityType = state.activityType,
        stage = state.stage,
        result = state.result,
        sessionId = state.sessionId,
        targetKey = state.targetKey,
        expiresAt = receivedAt + (tonumber(state.ttlSeconds) or 0),
    }
    pendingLeaderUnitTag = tostring(unitTag or "")
    readinessChecks = 0
    retryToken = retryToken + 1
    return TryAutoTravel()
end

function MOD.OnParticipantSessionChanged()
    if not IsEnabled() then
        return false
    end
    SeedPendingFromParticipantSession()
    return TryAutoTravel()
end

function MOD.OnSettingChanged(enabled)
    if enabled ~= true then
        ClearPending()
        return
    end
    local integration = EZO and EZO.EZOCoreIntegration
    if integration and type(integration.RequestGroupPresence) == "function" then
        pcall(integration.RequestGroupPresence)
    end
end

function MOD.Initialize()
    if initialized or type(EVENT_MANAGER) ~= "table" then
        return
    end
    initialized = true

    if EVENT_GROUP_MEMBER_JOINED ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_MEMBER_JOINED, function(_, _, _, isLocalPlayer)
            if isLocalPlayer ~= true or not IsEnabled() then
                return
            end
            local integration = EZO and EZO.EZOCoreIntegration
            if integration and type(integration.RequestGroupPresence) == "function" then
                pcall(integration.RequestGroupPresence)
            end
            SeedPendingFromParticipantSession()
            ScheduleRetry()
        end)
    end
    if EVENT_GROUP_UPDATE ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_UPDATE, TryAutoTravel)
    end
    if EVENT_LEADER_UPDATE ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_LEADER_UPDATE, TryAutoTravel)
    end
    if EVENT_PLAYER_ACTIVATED ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, TryAutoTravel)
    end
end
