-- Optional informational reset-state sharing through EZOCore.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.GroupActivitySharing = EZO.GroupActivitySharing or {}
local MOD = EZO.GroupActivitySharing

local ACTIVE_TTL_SECONDS = 90
local TERMINAL_TTL_SECONDS = 45
local REFRESH_SECONDS = 45

local lastFingerprint
local lastPublishedAt = 0
local lastFailureReason
local republishScheduled = false

local function NowSeconds()
    if type(GetFrameTimeSeconds) == "function" then
        return tonumber(GetFrameTimeSeconds()) or 0
    end
    return 0
end

local function DebugFailure(reason)
    reason = tostring(reason or "unknown")
    if reason == lastFailureReason then
        return
    end
    lastFailureReason = reason
    if EZO and type(EZO.DebugPrint) == "function" then
        EZO.DebugPrint("[GroupActivitySharing] publish skipped: " .. reason)
    end
end

local function ResolveStageAndResult(state, overrides)
    overrides = type(overrides) == "table" and overrides or {}
    if overrides.stage and overrides.result then
        return overrides.stage, overrides.result
    end

    local rawStage = tostring(state.stage or "")
    local pending = tonumber(state.pendingMembers) or 0
    if rawStage == "interrupted" then
        local resumeStage = tostring(state.resumeStage or "")
        if resumeStage == "returning" then
            return "returning", "interrupted"
        elseif resumeStage == "inviting" then
            return "waitingMembers", "interrupted"
        end
        return "staging", "interrupted"
    elseif state.resetComplete == true or rawStage == "trial-entered" then
        return "complete", "complete"
    elseif rawStage == "waiting-trial-entry" then
        return pending > 0 and "waitingMembers" or "complete", pending > 0 and "active" or "complete"
    elseif rawStage == "inviting" or rawStage == "waiting-members" then
        return "waitingMembers", "active"
    elseif rawStage == "returning" then
        return "returning", "active"
    elseif rawStage == "cleared" then
        return "idle", "cancelled"
    end
    return "staging", "active"
end

local function NormalizeDifficulty(value)
    if value == "normal"
        or (DUNGEON_DIFFICULTY_NORMAL ~= nil and value == DUNGEON_DIFFICULTY_NORMAL) then
        return "normal"
    elseif value == "veteran"
        or (DUNGEON_DIFFICULTY_VETERAN ~= nil and value == DUNGEON_DIFFICULTY_VETERAN) then
        return "veteran"
    end
    return "unknown"
end

local function NormalizeInteger(value, minimum, maximum)
    value = math.floor(tonumber(value) or minimum)
    return math.max(minimum, math.min(maximum, value))
end

local function BuildCompactState(state, overrides)
    if type(state) ~= "table" then
        return nil
    end

    local targetKey = tostring(state.targetKey or "")
    local sessionId = math.floor(tonumber(state.sessionId or state.runId) or -1)
    if targetKey == "" or sessionId < 0 or sessionId > 4294967295 then
        return nil
    end

    local activityType = tostring(state.activityType or "")
    if activityType ~= "trial" and activityType ~= "dungeon" and activityType ~= "arena" then
        return nil
    end

    local stage, result = ResolveStageAndResult(state, overrides)
    local terminal = result ~= "active" and result ~= "unknown" and result ~= "interrupted"
    local progressTotal = NormalizeInteger(state.totalPhases, 0, 15)
    local progressCurrent = NormalizeInteger(state.phaseIndex, 0, progressTotal)
    local expectedCount = NormalizeInteger(state.capturedMembers, 0, 12)
    local pendingCount = NormalizeInteger(state.pendingMembers, 0, expectedCount)
    return {
        sourceAddonKey = "ezotools",
        activityType = activityType,
        stage = stage,
        result = result,
        difficulty = NormalizeDifficulty(state.difficulty),
        sessionId = sessionId,
        progressCurrent = progressCurrent,
        progressTotal = progressTotal,
        pendingCount = pendingCount,
        expectedCount = expectedCount,
        targetKey = targetKey,
        ttlSeconds = terminal and TERMINAL_TTL_SECONDS or ACTIVE_TTL_SECONDS,
    }
end

local function GetFingerprint(state)
    return table.concat({
        tostring(state.activityType),
        tostring(state.stage),
        tostring(state.result),
        tostring(state.difficulty),
        tostring(state.sessionId),
        tostring(state.progressCurrent),
        tostring(state.progressTotal),
        tostring(state.pendingCount),
        tostring(state.expectedCount),
        tostring(state.targetKey),
        tostring(state.ttlSeconds),
    }, "|")
end

function MOD.PublishResetState(state, overrides, force)
    local compact = BuildCompactState(state, overrides)
    if not compact then
        return false, "invalidLocalState"
    end

    local participantSession = EZO and EZO.GroupActivityParticipantSession
    local tools = EZO and EZO.RaidLeaderTools
    if participantSession and type(participantSession.Capture) == "function"
        and tools and type(tools.BuildResetSnapshot) == "function" then
        local ok, snapshot = pcall(tools.BuildResetSnapshot)
        if ok and type(snapshot) == "table" then
            participantSession.Capture("player", compact, snapshot)
        end
    end

    local now = NowSeconds()
    local fingerprint = GetFingerprint(compact)
    if force ~= true and fingerprint == lastFingerprint and now - lastPublishedAt < REFRESH_SECONDS then
        return true, "unchanged"
    end

    local integration = EZO and EZO.EZOCoreIntegration
    if not (integration and type(integration.PublishGroupActivityState) == "function") then
        return false, "integrationMissing"
    end

    local published, reason = integration.PublishGroupActivityState(compact)
    if published then
        lastFingerprint = fingerprint
        lastPublishedAt = now
        lastFailureReason = nil
        return true
    end
    DebugFailure(reason)
    return false, reason
end

function MOD.PublishCurrentResetState(force)
    local reset = EZO and EZO.RaidLeaderReset
    if not (reset and type(reset.GetPublicActivityState) == "function") then
        return false, "resetStateUnavailable"
    end
    return MOD.PublishResetState(reset.GetPublicActivityState(), nil, force)
end

function MOD.RepublishCurrentResetState(delayMs)
    if republishScheduled then
        return false
    end
    republishScheduled = true
    local function Publish()
        republishScheduled = false
        MOD.PublishCurrentResetState(true)
    end
    if type(zo_callLater) == "function" and tonumber(delayMs) and delayMs > 0 then
        zo_callLater(Publish, delayMs)
    else
        Publish()
    end
    return true
end

function MOD.ResetPublicationCache()
    lastFingerprint = nil
    lastPublishedAt = 0
    lastFailureReason = nil
end
