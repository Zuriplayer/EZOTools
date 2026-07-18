-- Retains locally observed reset participants across the intentional disband gap.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.GroupActivityParticipantSession = EZO.GroupActivityParticipantSession or {}
local MOD = EZO.GroupActivityParticipantSession

local EVENT_NAMESPACE = "EZOTools_GroupActivityParticipantSession"

local session
local initialized = false

local function IsGrouped()
    return type(IsUnitGrouped) == "function" and IsUnitGrouped("player") == true
end

local function NowSeconds()
    if type(GetFrameTimeSeconds) == "function" then
        return tonumber(GetFrameTimeSeconds()) or 0
    end
    return 0
end

local function TouchLeaderState(ttlSeconds)
    if not (session and type(session.leaderState) == "table") then
        return
    end
    local ttl = tonumber(ttlSeconds) or tonumber(session.leaderState.ttlSeconds) or 60
    local now = NowSeconds()
    session.leaderState.receivedAt = now
    session.leaderState.ttlSeconds = ttl
    session.leaderState.expiresAt = now + ttl
end

local function FormatZoneName(zoneName)
    zoneName = tostring(zoneName or "")
    if zoneName == "" or type(zo_strformat) ~= "function" then
        return zoneName
    end
    if SI_ZONE_NAME ~= nil then
        return zo_strformat(SI_ZONE_NAME, zoneName)
    end
    return zo_strformat("<<1>>", zoneName)
end

local function GetUnitZoneName(unitTag)
    if type(GetUnitZoneIndex) ~= "function" or type(GetZoneNameByIndex) ~= "function" then
        return ""
    end
    local okIndex, zoneIndex = pcall(GetUnitZoneIndex, unitTag)
    if not okIndex or not zoneIndex then
        return ""
    end
    local okName, zoneName = pcall(GetZoneNameByIndex, zoneIndex)
    return FormatZoneName(okName and zoneName or "")
end

local function IsTrackedResult(result)
    return result == "active" or result == "interrupted" or result == "unknown"
end

local function CopyLeaderState(state)
    return {
        remoteProtocol = state.remoteProtocol == true,
        sourceAddonId = state.sourceAddonId,
        activityType = state.activityType,
        stage = state.stage,
        result = state.result,
        difficulty = state.difficulty,
        sessionId = state.sessionId,
        progressCurrent = state.progressCurrent,
        progressTotal = state.progressTotal,
        pendingCount = state.pendingCount,
        expectedCount = state.expectedCount,
        targetKey = state.targetKey,
        ttlSeconds = state.ttlSeconds,
        receivedAt = state.receivedAt,
        expiresAt = state.expiresAt,
    }
end

local function FindLeaderDisplayName(snapshot, leaderUnitTag)
    for _, member in ipairs(snapshot and snapshot.group and snapshot.group.members or {}) do
        if member.isLeader == true or member.unitTag == leaderUnitTag then
            local displayName = tostring(member.displayName or "")
            if displayName ~= "" then
                return displayName
            end
        end
    end
    if type(GetUnitDisplayName) == "function" and type(leaderUnitTag) == "string" and leaderUnitTag ~= "" then
        local ok, displayName = pcall(GetUnitDisplayName, leaderUnitTag)
        if ok then
            return tostring(displayName or "")
        end
    end
    return ""
end

local function CaptureRoster(snapshot)
    local roster = {}
    local members = snapshot and snapshot.group and snapshot.group.members or {}
    for leaderPass = 1, 2 do
        for _, member in ipairs(members) do
            local include = leaderPass == 1 and member.isLeader == true
                or leaderPass == 2 and member.isLeader ~= true
            local displayName = tostring(member.displayName or "")
            if include and displayName ~= "" then
                roster[#roster + 1] = {
                    displayName = displayName,
                    characterName = tostring(member.characterName or ""),
                    isLeader = member.isLeader == true,
                    lastZoneName = GetUnitZoneName(tostring(member.unitTag or "")),
                }
            end
        end
    end
    return roster
end

local function UpdateObservedRoster(snapshot)
    if not session or not (snapshot and snapshot.group and snapshot.group.isGrouped) then
        return
    end
    local observedByName = {}
    for _, member in ipairs(snapshot.group.members or {}) do
        local displayName = tostring(member.displayName or "")
        if displayName ~= "" then
            observedByName[displayName] = member
        end
    end
    for _, retained in ipairs(session.roster) do
        local observed = observedByName[retained.displayName]
        if observed then
            local zoneName = GetUnitZoneName(tostring(observed.unitTag or ""))
            if zoneName ~= "" then
                retained.lastZoneName = zoneName
            end
        end
    end
end

function MOD.Capture(leaderUnitTag, state, snapshot)
    if type(state) ~= "table" or not IsTrackedResult(tostring(state.result or "")) then
        if type(state) == "table" and state.result ~= nil then
            session = nil
        end
        return false
    end

    local sessionId = tonumber(state.sessionId)
    if sessionId == nil then
        return false
    end

    local isNewSession = not session or tonumber(session.sessionId) ~= sessionId
    if isNewSession then
        local roster = CaptureRoster(snapshot)
        if #roster == 0 then
            return false
        end
        session = {
            sessionId = sessionId,
            leaderUnitTag = tostring(leaderUnitTag or ""),
            leaderDisplayName = FindLeaderDisplayName(snapshot, leaderUnitTag),
            roster = roster,
            localInviteStatus = "none",
        }
    end

    session.leaderState = CopyLeaderState(state)
    session.leaderUnitTag = tostring(leaderUnitTag or session.leaderUnitTag or "")
    local leaderDisplayName = FindLeaderDisplayName(snapshot, leaderUnitTag)
    if leaderDisplayName ~= "" then
        session.leaderDisplayName = leaderDisplayName
    end
    UpdateObservedRoster(snapshot)
    return true
end

function MOD.Get()
    return session
end

function MOD.HasSession()
    return type(session) == "table" and type(session.leaderState) == "table"
end

function MOD.GetLeaderState()
    return session and session.leaderState or nil
end

function MOD.GetLeaderDisplayName()
    return session and tostring(session.leaderDisplayName or "") or ""
end

function MOD.GetCurrentLeaderUnitTag()
    if not session or not IsGrouped() then
        return nil
    end
    local expectedDisplayName = tostring(session.leaderDisplayName or "")
    local tools = EZO and EZO.RaidLeaderTools
    if tools and type(tools.BuildResetSnapshot) == "function" then
        local ok, snapshot = pcall(tools.BuildResetSnapshot)
        if ok and type(snapshot) == "table" then
            for _, member in ipairs(snapshot.group and snapshot.group.members or {}) do
                if member.isLeader == true
                    and (expectedDisplayName == "" or tostring(member.displayName or "") == expectedDisplayName) then
                    return tostring(member.unitTag or "")
                end
            end
        end
    end
    if type(GetGroupLeaderUnitTag) == "function" then
        local leaderUnitTag = GetGroupLeaderUnitTag()
        if type(leaderUnitTag) == "string" and leaderUnitTag ~= "" then
            if expectedDisplayName == "" or type(GetUnitDisplayName) ~= "function" then
                return leaderUnitTag
            end
            local ok, displayName = pcall(GetUnitDisplayName, leaderUnitTag)
            if ok and tostring(displayName or "") == expectedDisplayName then
                return leaderUnitTag
            end
        end
    end
    return nil
end

function MOD.RefreshObservedRoster(snapshot)
    UpdateObservedRoster(snapshot)
end

function MOD.GetLocalInviteStatus()
    return session and tostring(session.localInviteStatus or "none") or "none"
end

function MOD.Clear()
    session = nil
    return true
end

local function OnGroupInviteReceived(_, _, inviterDisplayName)
    if not session or tostring(inviterDisplayName or "") ~= tostring(session.leaderDisplayName or "") then
        return
    end
    session.localInviteStatus = "received"
    if type(session.leaderState) == "table" then
        session.leaderState.stage = "waitingMembers"
        session.leaderState.result = "active"
        local total = tonumber(session.leaderState.progressTotal) or 0
        if total > 0 then
            session.leaderState.progressCurrent = total
        end
        TouchLeaderState(90)
    end
    local panel = EZO and EZO.GroupActivityPeerPanel
    if panel and type(panel.Refresh) == "function" then
        panel.Refresh()
    end
end

local function IsSessionLeaderInCurrentGroup()
    local tools = EZO and EZO.RaidLeaderTools
    if not (session and tools and type(tools.BuildResetSnapshot) == "function") then
        return false
    end
    local ok, snapshot = pcall(tools.BuildResetSnapshot)
    if not ok or type(snapshot) ~= "table" then
        return false
    end
    for _, member in ipairs(snapshot.group and snapshot.group.members or {}) do
        if member.isLeader == true
            and tostring(member.displayName or "") == tostring(session.leaderDisplayName or "") then
            return true
        end
    end
    return false
end

local function OnGroupChanged()
    if not session then
        return
    end
    local expectedSessionId = session.sessionId
    local function Evaluate()
        if not session or session.sessionId ~= expectedSessionId then
            return
        end
        if IsGrouped() then
            if IsSessionLeaderInCurrentGroup() then
                session.localInviteStatus = "accepted"
                TouchLeaderState(90)
            else
                session = nil
            end
        end
        local memberTravel = EZO and EZO.GroupActivityMemberTravel
        if memberTravel and type(memberTravel.OnParticipantSessionChanged) == "function" then
            memberTravel.OnParticipantSessionChanged("group-changed")
        end
        local panel = EZO and EZO.GroupActivityPeerPanel
        if panel and type(panel.Refresh) == "function" then
            panel.Refresh()
        end
    end
    if IsGrouped() and type(zo_callLater) == "function" then
        zo_callLater(Evaluate, 250)
    else
        Evaluate()
    end
end

function MOD.Initialize()
    if initialized or type(EVENT_MANAGER) ~= "table" then
        return
    end
    initialized = true
    if EVENT_GROUP_INVITE_RECEIVED ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_INVITE_RECEIVED, OnGroupInviteReceived)
    end
    if EVENT_GROUP_UPDATE ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_UPDATE, OnGroupChanged)
    end
    if EVENT_GROUP_MEMBER_JOINED ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_MEMBER_JOINED, OnGroupChanged)
    end
end
