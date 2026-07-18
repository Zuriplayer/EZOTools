-- Member-facing informational group activity panel.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.GroupActivityPeerPanel = EZO.GroupActivityPeerPanel or {}
local MOD = EZO.GroupActivityPeerPanel

local EVENT_NAMESPACE = "EZOTools_GroupActivityPeerPanel"
local UPDATE_NAMESPACE = EVENT_NAMESPACE .. "_Expiry"
local PANEL_WIDTH = 480

local panel
local currentLeaderState
local currentLeaderUnitTag
local simulatedSnapshot
local simulationActive = false
local initialized = false

local function IsGrouped()
    return type(IsUnitGrouped) == "function" and IsUnitGrouped("player") == true
end

local function IsGroupLeader()
    local tools = EZO and EZO.RaidLeaderTools
    if tools and type(tools.IsPlayerGroupLeader) == "function" then
        return tools.IsPlayerGroupLeader() == true
    end
    return type(IsUnitGroupLeader) == "function" and IsUnitGroupLeader("player") == true
end

local function GetParticipantSessionModule()
    return EZO and EZO.GroupActivityParticipantSession
end

local function BuildSnapshot()
    if simulationActive and type(simulatedSnapshot) == "table" then
        return simulatedSnapshot
    end

    local tools = EZO and EZO.RaidLeaderTools
    if tools and type(tools.BuildResetSnapshot) == "function" then
        local ok, snapshot = pcall(tools.BuildResetSnapshot)
        if ok and type(snapshot) == "table" then
            return snapshot
        end
    end
    return {
        group = { isGrouped = IsGrouped(), isLeader = IsGroupLeader(), size = 0, members = {} },
        instance = { inInstance = false, zoneName = "", difficultyName = "" },
    }
end

local function GetPlayerDisplayName()
    if type(GetDisplayName) == "function" then
        local name = GetDisplayName()
        if type(name) == "string" and name ~= "" then
            return name
        end
    end
    return "Player"
end

local function GetLeaderUnitTag(snapshot)
    local group = snapshot and snapshot.group or {}
    for _, member in ipairs(group.members or {}) do
        if member.isLeader == true and type(member.unitTag) == "string" and member.unitTag ~= "" then
            return member.unitTag
        end
    end
    return nil
end

local function ResolveTargetName(targetKey)
    targetKey = tostring(targetKey or "")
    local catalog = EZO and EZO.RaidLeaderActivityCatalog
    if catalog and type(catalog.GetTrialByKey) == "function" then
        local ok, activity = pcall(catalog.GetTrialByKey, targetKey)
        if ok and type(activity) == "table" and tostring(activity.name or "") ~= "" then
            return tostring(activity.name)
        end
    end
    return targetKey
end

local function GetActivityTypeText(activityType)
    if activityType == "trial" then
        return GetString(EZO_GROUP_ACTIVITY_PEER_TYPE_TRIAL)
    elseif activityType == "dungeon" then
        return GetString(EZO_GROUP_ACTIVITY_PEER_TYPE_DUNGEON)
    elseif activityType == "arena" then
        return GetString(EZO_GROUP_ACTIVITY_PEER_TYPE_ARENA)
    end
    return GetString(EZO_MENU_GROUP_ACTIVITIES_TITLE)
end

local function GetDifficultyText(difficulty)
    if difficulty == "normal" or difficulty == DUNGEON_DIFFICULTY_NORMAL then
        return GetString(EZO_GROUP_INFORMATION_MODE_NORMAL)
    elseif difficulty == "veteran" or difficulty == DUNGEON_DIFFICULTY_VETERAN then
        return GetString(EZO_GROUP_INFORMATION_MODE_VETERAN)
    end
    return GetString(EZO_GROUP_ACTIVITY_PEER_DIFFICULTY_UNKNOWN)
end

local function GetRemoteStageText(stage)
    local stringIds = {
        idle = EZO_GROUP_ACTIVITY_PEER_STAGE_IDLE,
        staging = EZO_GROUP_ACTIVITY_PEER_STAGE_STAGING,
        returning = EZO_GROUP_ACTIVITY_PEER_STAGE_RETURNING,
        waitingMembers = EZO_GROUP_ACTIVITY_PEER_STAGE_WAITING_MEMBERS,
        complete = EZO_GROUP_ACTIVITY_PEER_STAGE_COMPLETE,
        failed = EZO_GROUP_ACTIVITY_PEER_STAGE_FAILED,
    }
    return GetString(stringIds[stage] or EZO_GROUP_ACTIVITY_PEER_PHASE_REMOTE)
end

local function GetRemoteResultText(result)
    local stringIds = {
        unknown = EZO_GROUP_ACTIVITY_PEER_RESULT_UNKNOWN,
        active = EZO_GROUP_ACTIVITY_PEER_RESULT_ACTIVE,
        complete = EZO_GROUP_ACTIVITY_PEER_RESULT_COMPLETE,
        cancelled = EZO_GROUP_ACTIVITY_PEER_RESULT_CANCELLED,
        failed = EZO_GROUP_ACTIVITY_PEER_RESULT_FAILED,
        interrupted = EZO_GROUP_ACTIVITY_PEER_RESULT_INTERRUPTED,
    }
    return GetString(stringIds[result] or EZO_GROUP_ACTIVITY_PEER_RESULT_UNKNOWN)
end

local function GetCurrentLeaderState(leaderUnitTag)
    local participantSession = GetParticipantSessionModule()
    if not IsGrouped() and participantSession and type(participantSession.GetLeaderState) == "function" then
        local retainedState = participantSession.GetLeaderState()
        if type(retainedState) == "table" then
            return retainedState
        end
    end
    if type(currentLeaderState) ~= "table" then
        return nil
    end
    if leaderUnitTag and currentLeaderUnitTag and leaderUnitTag ~= currentLeaderUnitTag then
        currentLeaderState = nil
        currentLeaderUnitTag = leaderUnitTag
        return nil
    end
    local expiresAt = tonumber(currentLeaderState.expiresAt)
    local now = type(GetFrameTimeSeconds) == "function" and tonumber(GetFrameTimeSeconds()) or 0
    if expiresAt and expiresAt <= now then
        if not IsGrouped() and participantSession and type(participantSession.GetLeaderState) == "function" then
            local retainedState = participantSession.GetLeaderState()
            if type(retainedState) == "table"
                and tonumber(retainedState.sessionId) == tonumber(currentLeaderState.sessionId) then
                return retainedState
            end
        end
        currentLeaderState = nil
        return nil
    end
    return currentLeaderState
end

local function GetTransportStatus()
    if simulationActive then
        return { reason = "active", simulated = true }
    end

    local integration = EZO and EZO.EZOCoreIntegration
    if not (integration and type(integration.GetGroupPresenceStatus) == "function") then
        return { reason = "ezocoreMissing" }
    end

    local status = integration.GetGroupPresenceStatus()
    if type(status) == "table" then
        return status
    end
    return { reason = integration.IsAvailable and integration.IsAvailable() and "serviceMissing" or "ezocoreMissing" }
end

local function GetTransportText(status)
    local reason = tostring(status and status.reason or "")
    if reason == "active" then
        return GetString(EZO_GROUP_ACTIVITY_PEER_TRANSPORT_ACTIVE), "success", "ON"
    elseif reason == "protocolDefinitionPending" or reason == "reservedIdsMissing" then
        return GetString(EZO_GROUP_ACTIVITY_PEER_TRANSPORT_PENDING), "warning", "PEND"
    elseif reason == "libGroupBroadcastMissing" then
        return GetString(EZO_GROUP_ACTIVITY_PEER_TRANSPORT_LIB_MISSING), "warning", "LIB"
    elseif reason == "serviceMissing" then
        return GetString(EZO_GROUP_ACTIVITY_PEER_TRANSPORT_SERVICE_MISSING), "warning", "CORE"
    elseif reason == "ezocoreMissing" then
        return GetString(EZO_GROUP_ACTIVITY_PEER_TRANSPORT_CORE_MISSING), "muted", "OFF"
    end
    return GetString(EZO_GROUP_ACTIVITY_PEER_TRANSPORT_UNKNOWN), "muted", "?"
end

local function GetLeaderCompatibility(leaderUnitTag)
    if simulationActive then
        return "compatible"
    end
    if IsGroupLeader() then
        return "compatible"
    end

    local integration = EZO and EZO.EZOCoreIntegration
    if not (leaderUnitTag and integration and type(integration.GetPeerCompatibility) == "function") then
        return "unknown"
    end
    return integration.GetPeerCompatibility(
        leaderUnitTag,
        "ezotools",
        "group.activityState.provider",
        tonumber(integration.GROUP_ACTIVITY_API_VERSION) or 2)
end

local function GetCompatibilityText(compatibility)
    if compatibility == "compatible" then
        return GetString(EZO_GROUP_ACTIVITY_PEER_COMPATIBLE), "success", "OK"
    elseif compatibility == "incompatible" then
        return GetString(EZO_GROUP_ACTIVITY_PEER_INCOMPATIBLE), "error", "NO"
    end
    return GetString(EZO_GROUP_ACTIVITY_PEER_UNKNOWN), "muted", "?"
end

local function GetUnitDisplayNameSafe(unitTag)
    if type(unitTag) == "string" and unitTag ~= "" and type(GetUnitDisplayName) == "function" then
        local ok, displayName = pcall(GetUnitDisplayName, unitTag)
        if ok and type(displayName) == "string" and displayName ~= "" then
            return displayName
        end
    end
    return nil
end

local function GetSnapshotMemberName(snapshot, unitTag)
    for _, member in ipairs(snapshot and snapshot.group and snapshot.group.members or {}) do
        if member.unitTag == unitTag then
            return tostring(member.displayName or member.characterName or "")
        end
    end
    return ""
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
    if type(unitTag) ~= "string" or unitTag == ""
        or type(GetUnitZoneIndex) ~= "function"
        or type(GetZoneNameByIndex) ~= "function" then
        return ""
    end
    local okIndex, zoneIndex = pcall(GetUnitZoneIndex, unitTag)
    if not okIndex or not zoneIndex then
        return ""
    end
    local okName, zoneName = pcall(GetZoneNameByIndex, zoneIndex)
    return FormatZoneName(okName and zoneName or "")
end

local function BuildLeaderRow(snapshot, leaderUnitTag, leaderState)
    if type(leaderUnitTag) ~= "string" or leaderUnitTag == "" then
        return nil
    end
    local name = GetUnitDisplayNameSafe(leaderUnitTag) or GetSnapshotMemberName(snapshot, leaderUnitTag)
    if name == "" then
        name = GetString(EZO_GROUP_ACTIVITY_PEER_LEADER_UNKNOWN)
    end
    local zoneName = simulationActive and ResolveTargetName(leaderState and leaderState.targetKey)
        or GetUnitZoneName(leaderUnitTag)
    local zoneKnown = zoneName ~= ""
    if zoneName == "" then
        zoneName = GetString(EZO_GROUP_ACTIVITY_PEER_LOCATION_UNKNOWN)
    end
    return {
        id = "leader",
        name = name,
        status = GetString(EZO_GROUP_ACTIVITY_PEER_ROLE_LEADER),
        tone = "normal",
        iconType = "pending",
        location = zoneName,
        locationTone = zoneKnown and "info" or "muted",
    }
end

local function BuildPlayerRow(snapshot, leaderUnitTag)
    local group = snapshot.group or {}
    local sameInstance
    if simulationActive then
        sameInstance = true
    elseif type(leaderUnitTag) == "string" and leaderUnitTag ~= ""
        and type(IsGroupMemberInSameInstanceAsPlayer) == "function" then
        local ok, value = pcall(IsGroupMemberInSameInstanceAsPlayer, leaderUnitTag)
        if ok and type(value) == "boolean" then
            sameInstance = value == true
        end
    end

    local location = GetString(EZO_GROUP_ACTIVITY_PEER_LOCATION_UNKNOWN)
    local tone = "muted"
    local iconType = "pending"
    if group.isLeader then
        location = FormatZoneName(snapshot.instance and snapshot.instance.zoneName)
        if location == "" then
            location = GetString(EZO_GROUP_ACTIVITY_PEER_LOCATION_UNKNOWN)
        else
            tone = "info"
            iconType = "success"
        end
    elseif sameInstance == true then
        location = GetString(EZO_GROUP_ACTIVITY_PEER_LOCATION_SAME_LEADER)
        tone = "success"
        iconType = "success"
    elseif sameInstance == false then
        location = GetString(EZO_GROUP_ACTIVITY_PEER_LOCATION_DIFFERENT_LEADER)
        tone = "warning"
        iconType = "pending"
    end

    return {
        id = "player",
        name = GetPlayerDisplayName(),
        status = group.isLeader and GetString(EZO_GROUP_ACTIVITY_PEER_ROLE_LEADER) or GetString(EZO_GROUP_ACTIVITY_PEER_ROLE_MEMBER),
        tone = tone,
        iconType = iconType,
        location = location,
        locationTone = tone,
    }
end

local function BuildRosterRow(member)
    local unitTag = tostring(member and member.unitTag or "")
    local name = tostring(member and (member.displayName or member.characterName) or "")
    if name == "" then
        name = GetUnitDisplayNameSafe(unitTag) or unitTag
    end
    local zoneName = GetUnitZoneName(unitTag)
    if zoneName == "" then
        zoneName = GetString(EZO_GROUP_ACTIVITY_PEER_LOCATION_UNKNOWN)
    end

    local sameInstance = name == GetPlayerDisplayName() and true or nil
    if sameInstance == nil and type(IsGroupMemberInSameInstanceAsPlayer) == "function" and unitTag ~= "" then
        local ok, value = pcall(IsGroupMemberInSameInstanceAsPlayer, unitTag)
        if ok and type(value) == "boolean" then
            sameInstance = value
        end
    end

    local tone = sameInstance == true and "success" or sameInstance == false and "warning" or "muted"
    return {
        id = unitTag,
        name = name,
        status = member and member.isLeader == true
            and GetString(EZO_GROUP_ACTIVITY_PEER_ROLE_LEADER)
            or GetString(EZO_GROUP_ACTIVITY_PEER_ROLE_MEMBER),
        tone = tone,
        iconType = sameInstance == true and "success" or "pending",
        location = zoneName,
        locationTone = zoneName == GetString(EZO_GROUP_ACTIVITY_PEER_LOCATION_UNKNOWN) and "muted" or tone,
    }
end

local function BuildRetainedRosterRows(snapshot, retainedSession)
    local currentByName = {}
    for _, member in ipairs(snapshot and snapshot.group and snapshot.group.members or {}) do
        local displayName = tostring(member.displayName or "")
        if displayName ~= "" then
            currentByName[displayName] = member
        end
    end

    local playerName = GetPlayerDisplayName()
    local participantSession = GetParticipantSessionModule()
    local inviteStatus = participantSession and type(participantSession.GetLocalInviteStatus) == "function"
        and participantSession.GetLocalInviteStatus()
        or "none"
    local rows = {}
    for _, retained in ipairs(retainedSession and retainedSession.roster or {}) do
        local displayName = tostring(retained.displayName or "")
        local current = currentByName[displayName]
        if current then
            rows[#rows + 1] = BuildRosterRow(current)
        else
            local isPlayer = displayName == playerName
            local status = GetString(EZO_GROUP_ACTIVITY_PEER_NOT_IN_GROUP)
            local tone = "muted"
            local iconType = "pending"
            if isPlayer and inviteStatus == "received" then
                status = GetString(EZO_GROUP_ACTIVITY_PEER_INVITE_RECEIVED)
                tone = "warning"
            end
            local zoneName = isPlayer and GetUnitZoneName("player") or tostring(retained.lastZoneName or "")
            if zoneName == "" then
                zoneName = GetString(EZO_GROUP_ACTIVITY_PEER_LOCATION_UNKNOWN)
            elseif not isPlayer then
                zoneName = zo_strformat(GetString(EZO_GROUP_ACTIVITY_PEER_LAST_KNOWN_LOCATION), zoneName)
            end
            rows[#rows + 1] = {
                id = displayName,
                name = displayName,
                status = status,
                tone = tone,
                iconType = iconType,
                location = zoneName,
                locationTone = isPlayer and "info" or "muted",
            }
        end
    end
    return rows
end

local function BuildLocationRows(snapshot, leaderUnitTag, leaderState)
    local participantSession = GetParticipantSessionModule()
    local retainedSession = participantSession and type(participantSession.Get) == "function"
        and participantSession.Get()
        or nil
    if retainedSession and leaderState
        and tonumber(retainedSession.sessionId) == tonumber(leaderState.sessionId) then
        if type(participantSession.RefreshObservedRoster) == "function" then
            participantSession.RefreshObservedRoster(snapshot)
        end
        local retainedRows = BuildRetainedRosterRows(snapshot, retainedSession)
        if #retainedRows > 0 then
            return retainedRows
        end
    end

    local rows = {}
    local members = snapshot.group and snapshot.group.members or {}
    for _, member in ipairs(members) do
        if member.isLeader == true then
            rows[#rows + 1] = BuildRosterRow(member)
        end
    end
    for _, member in ipairs(members) do
        if member.isLeader ~= true then
            rows[#rows + 1] = BuildRosterRow(member)
        end
    end
    if #rows > 0 then
        return rows
    end

    if not (snapshot.group and snapshot.group.isLeader) then
        local leaderRow = BuildLeaderRow(snapshot, leaderUnitTag, leaderState)
        if leaderRow then
            rows[#rows + 1] = leaderRow
        end
    end
    rows[#rows + 1] = BuildPlayerRow(snapshot, leaderUnitTag)
    return rows
end

local function GetLocalLeaderActivityState()
    if not IsGroupLeader() then
        return nil
    end
    local reset = EZO and EZO.RaidLeaderReset
    if not (reset and type(reset.GetPublicActivityState) == "function") then
        return nil
    end
    local ok, state = pcall(reset.GetPublicActivityState)
    return ok and type(state) == "table" and state or nil
end

local function BuildModel()
    local snapshot = BuildSnapshot()
    local group = snapshot.group or {}
    local leaderUnitTag = GetLeaderUnitTag(snapshot) or currentLeaderUnitTag
    local transportStatus = GetTransportStatus()
    local _, transportTone, transportShort = GetTransportText(transportStatus)
    local compatibility = GetLeaderCompatibility(leaderUnitTag)
    local _, compatibilityTone, compatibilityShort = GetCompatibilityText(compatibility)
    local leaderState = GetLocalLeaderActivityState() or GetCurrentLeaderState(leaderUnitTag)
    local isRemoteState = leaderState and leaderState.remoteProtocol == true

    local target = leaderState and tostring(leaderState.targetName or "") or ""
    if target == "" and leaderState then
        target = ResolveTargetName(leaderState.targetKey)
    end
    if target == "" then
        target = GetString(EZO_GROUP_ACTIVITY_PEER_PANEL_TITLE)
    end

    local mode = leaderState and tostring(leaderState.modeName or "") or ""
    if leaderState and leaderState.difficulty ~= nil then
        mode = GetDifficultyText(leaderState.difficulty)
    end
    if isRemoteState then
        mode = string.format(
            "%s | %s",
            GetActivityTypeText(leaderState.activityType),
            GetDifficultyText(leaderState.difficulty))
    elseif mode == "" then
        mode = GetString(EZO_GROUP_ACTIVITY_PEER_DIFFICULTY_UNKNOWN)
    end

    local phaseIndex = tonumber(leaderState and (isRemoteState and leaderState.progressCurrent or leaderState.phaseIndex)) or 0
    local totalPhases = tonumber(leaderState and (isRemoteState and leaderState.progressTotal or leaderState.totalPhases)) or 0
    local hasLeaderState = type(leaderState) == "table"
    local pendingCount = tonumber(leaderState and (leaderState.pendingCount or leaderState.pendingMembers))
    local expectedCount = tonumber(leaderState and (leaderState.expectedCount or leaderState.capturedMembers))
    local pendingValue = pendingCount
    if pendingCount ~= nil and expectedCount ~= nil then
        pendingValue = string.format("%d/%d", pendingCount, expectedCount)
    end
    local hasProgress = hasLeaderState and totalPhases > 0
    local isGroupIdle = not hasLeaderState
    local progressValue = hasProgress and math.min(phaseIndex, totalPhases) or 0
    local progressMax = hasProgress and totalPhases or 1
    local phaseText = isGroupIdle
        and GetString(EZO_GROUP_INFORMATION_PHASE)
        or hasLeaderState
        and (isRemoteState and GetRemoteStageText(leaderState.stage)
            or leaderState.resetComplete and GetString(EZO_INSTANCE_RESET_STATUS_COMPLETE)
            or (hasProgress and zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_PHASE_SHORT), phaseIndex, progressMax)
                or GetString(EZO_GROUP_ACTIVITY_PEER_PHASE_REMOTE)))
        or GetString(EZO_GROUP_ACTIVITY_PEER_PHASE_LOCAL)
    local statusText = isGroupIdle
        and GetString(EZO_GROUP_INFORMATION_STATUS_READY)
        or hasLeaderState
        and (isRemoteState and GetRemoteResultText(leaderState.result)
            or tostring(leaderState.statusText or GetString(EZO_GROUP_ACTIVITY_PEER_STATUS_REMOTE)))
        or GetString(EZO_GROUP_ACTIVITY_PEER_STATUS_WAITING)

    local alert = nil
    if simulationActive then
        alert = {
            text = GetString(EZO_GROUP_ACTIVITY_PEER_SIMULATION_ACTIVE),
            tone = "info",
        }
    elseif not group.isGrouped then
        local participantSession = GetParticipantSessionModule()
        if participantSession and type(participantSession.HasSession) == "function"
            and participantSession.HasSession() then
            alert = {
                text = GetString(EZO_GROUP_ACTIVITY_PEER_DISBAND_GAP),
                tone = "warning",
            }
        end
    end

    local contextText
    if isGroupIdle then
        local zoneName = GetUnitZoneName(leaderUnitTag)
        if zoneName == "" then
            zoneName = FormatZoneName(snapshot.instance and snapshot.instance.zoneName)
        end
        local difficulty = snapshot.instance and snapshot.instance.difficulty
        local difficultyName
        if difficulty == DUNGEON_DIFFICULTY_NORMAL then
            difficultyName = GetString(EZO_GROUP_INFORMATION_MODE_NORMAL)
        elseif difficulty == DUNGEON_DIFFICULTY_VETERAN then
            difficultyName = GetString(EZO_GROUP_INFORMATION_MODE_VETERAN)
        else
            difficultyName = tostring(snapshot.instance and snapshot.instance.difficultyName or "")
        end
        if difficultyName == "" then
            difficultyName = GetString(EZO_GROUP_ACTIVITY_PEER_DIFFICULTY_UNKNOWN)
        end
        contextText = zoneName ~= "" and string.format("%s - %s", zoneName, difficultyName) or difficultyName
    else
        contextText = zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_ACTIVITY), GetString(EZO_MENU_GROUP_ACTIVITIES_TITLE), mode)
    end

    local metrics = {
        {
            value = group.size or 0,
            label = GetString(EZO_GROUP_ACTIVITY_PEER_METRIC_GROUP),
            tone = group.isGrouped and "normal" or "muted",
        },
    }
    if not isGroupIdle then
        metrics[#metrics + 1] = {
            value = hasLeaderState and (pendingValue or "-") or "-",
            label = GetString(EZO_GROUP_ACTIVITY_PEER_METRIC_PENDING),
            tone = pendingCount ~= nil and (pendingCount == 0 and "success" or "warning") or "muted",
        }
    end
    metrics[#metrics + 1] = {
        value = transportShort,
        label = GetString(EZO_GROUP_ACTIVITY_PEER_METRIC_EZOCORE),
        tone = transportTone,
    }
    if not isGroupIdle then
        metrics[#metrics + 1] = {
            value = compatibilityShort,
            label = GetString(EZO_GROUP_ACTIVITY_PEER_METRIC_LEADER),
            tone = compatibilityTone,
        }
    end

    return {
        width = PANEL_WIDTH,
        density = "comfortable",
        title = target,
        phaseText = phaseText,
        contextText = contextText,
        totalTimeText = "",
        progress = {
            hidden = isGroupIdle,
            min = 0,
            max = progressMax,
            value = progressValue,
            text = hasProgress
                and zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_PROGRESS), progressValue, progressMax)
                or GetString(EZO_GROUP_ACTIVITY_PEER_PROGRESS_WAITING),
        },
        statusText = statusText,
        statusTimeText = "",
        alert = alert,
        metrics = metrics,
        rowsTitle = GetString(EZO_GROUP_ACTIVITY_PEER_ROWS_TITLE),
        rowLocationWidth = 205,
        rowStatusWidth = 70,
        rows = BuildLocationRows(snapshot, leaderUnitTag, leaderState),
        actions = {
            {
                id = "close",
                label = GetString(EZO_SETTINGS_CLOSE),
                keybind = "DIALOG_NEGATIVE",
                callback = function()
                    MOD.Hide()
                end,
            },
        },
    }
end

local function EnsurePanel()
    if panel then
        return panel
    end
    local statusPanel = EZO and EZO.StatusPanel
    if not (statusPanel and type(statusPanel.Create) == "function") then
        return nil
    end
    panel = statusPanel.Create("GroupActivityPeer", { width = PANEL_WIDTH })
    if not panel then
        return nil
    end
    panel:SetHidden(true)
    return panel
end

function MOD.CanShowInMenu()
    local participantSession = GetParticipantSessionModule()
    return IsGrouped()
        or (participantSession and type(participantSession.HasSession) == "function"
            and participantSession.HasSession())
end

function MOD.Show()
    local reset = EZO and EZO.RaidLeaderReset
    if reset and type(reset.HasSession) == "function" and reset.HasSession()
        and type(reset.ShowStatus) == "function" then
        MOD.Hide()
        return reset.ShowStatus()
    end

    local win = EnsurePanel()
    if not win then
        return false
    end

    local integration = EZO and EZO.EZOCoreIntegration
    if not simulationActive and integration then
        local snapshot = BuildSnapshot()
        local leaderUnitTag = GetLeaderUnitTag(snapshot)
        if leaderUnitTag and type(integration.GetPeerActivityState) == "function" then
            local cachedState = integration.GetPeerActivityState(leaderUnitTag)
            if type(cachedState) == "table" then
                MOD.SetLeaderActivityState(leaderUnitTag, cachedState)
            end
        end
        if type(integration.RequestGroupPresence) == "function" then
            pcall(integration.RequestGroupPresence)
        end
    end

    win:SetModel(BuildModel())
    win:SetInteractionActive(true)
    win:SetHidden(false)
    if EVENT_MANAGER and type(EVENT_MANAGER.RegisterForUpdate) == "function" then
        EVENT_MANAGER:UnregisterForUpdate(UPDATE_NAMESPACE)
        EVENT_MANAGER:RegisterForUpdate(UPDATE_NAMESPACE, 1000, MOD.Refresh)
    end
    return false
end

local function GetSimulatedModeName()
    if type(GetString) == "function" and DUNGEON_DIFFICULTY_VETERAN ~= nil then
        return GetString("SI_DUNGEONDIFFICULTY", DUNGEON_DIFFICULTY_VETERAN)
    end
    return "Veteran"
end

local function BuildSimulatedState(mode)
    mode = tostring(mode or "")
    local state = {
        remoteProtocol = true,
        sourceAddonId = "ezotools",
        activityType = "trial",
        difficulty = "veteran",
        sessionId = 1,
        targetKey = "aetherian_archive",
        targetName = "Aetherian Archive",
        stage = "waitingMembers",
        result = "active",
        progressCurrent = 6,
        progressTotal = 6,
        expectedCount = 11,
        pendingCount = 3,
    }

    if mode == "complete" or mode == "done" then
        state.stage = "complete"
        state.result = "complete"
        state.pendingCount = 0
    elseif mode == "returning" then
        state.stage = "returning"
        state.progressCurrent = 5
        state.pendingCount = 8
    elseif mode == "staging" then
        state.stage = "staging"
        state.progressCurrent = 3
        state.pendingCount = 10
    end

    return state
end

local function BuildSimulatedSnapshot()
    return {
        group = {
            isGrouped = true,
            isLeader = false,
            size = 12,
            members = {
                { unitTag = "group1", displayName = "@RaidLeader", characterName = "Raid Leader", isLeader = true },
                { unitTag = "player", displayName = GetPlayerDisplayName(), characterName = "Player", isLeader = false },
            },
        },
        instance = {
            inInstance = true,
            zoneName = "Aetherian Archive",
            difficultyName = GetSimulatedModeName(),
            canChangeDifficulty = false,
        },
    }
end

function MOD.ShowSimulation(mode)
    simulationActive = true
    simulatedSnapshot = BuildSimulatedSnapshot()
    currentLeaderUnitTag = "group1"
    currentLeaderState = BuildSimulatedState(mode)
    return MOD.Show()
end

function MOD.IsSimulationActive()
    return simulationActive == true
end

function MOD.Hide()
    if EVENT_MANAGER and type(EVENT_MANAGER.UnregisterForUpdate) == "function" then
        EVENT_MANAGER:UnregisterForUpdate(UPDATE_NAMESPACE)
    end
    if panel then
        panel:SetHidden(true)
    end
    return false
end

function MOD.Toggle()
    if panel and type(panel.IsHidden) == "function" and not panel:IsHidden() then
        return MOD.Hide()
    end
    return MOD.Show()
end

function MOD.Refresh()
    if panel and type(panel.IsHidden) == "function" and not panel:IsHidden() then
        panel:SetModel(BuildModel())
        panel:SetInteractionActive(true)
    end
end

function MOD.SetLeaderActivityState(unitTag, state)
    currentLeaderUnitTag = type(unitTag) == "string" and unitTag ~= "" and unitTag or currentLeaderUnitTag
    if type(state) == "table" then
        local receivedAt = tonumber(state.receivedAt)
            or (type(GetFrameTimeSeconds) == "function" and tonumber(GetFrameTimeSeconds()))
            or 0
        currentLeaderState = {
            remoteProtocol = true,
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
            receivedAt = receivedAt,
            expiresAt = tonumber(state.expiresAt) or (receivedAt + (tonumber(state.ttlSeconds) or 0)),
        }
        local participantSession = GetParticipantSessionModule()
        if participantSession and type(participantSession.Capture) == "function" then
            participantSession.Capture(currentLeaderUnitTag, currentLeaderState, BuildSnapshot())
        end
    else
        currentLeaderState = nil
    end
    MOD.Refresh()
    return currentLeaderState ~= nil
end

function MOD.ClearLeaderActivityState()
    currentLeaderState = nil
    currentLeaderUnitTag = nil
    simulationActive = false
    simulatedSnapshot = nil
    local participantSession = GetParticipantSessionModule()
    if participantSession and type(participantSession.Clear) == "function" then
        participantSession.Clear()
    end
    MOD.Refresh()
    return true
end

function MOD.ExecuteDebug(argument)
    argument = zo_strlower(zo_strtrim(tostring(argument or "")))
    if argument == "off" then
        MOD.ClearLeaderActivityState()
        MOD.Hide()
        if type(EZO.Print) == "function" then
            EZO.Print(GetString(EZO_DEBUG_GROUP_ACTIVITY_PANEL_HIDDEN))
        end
        return true
    end

    if argument ~= "" and argument ~= "complete" and argument ~= "done" and argument ~= "returning" and argument ~= "staging" then
        if type(EZO.Print) == "function" then
            EZO.Print(GetString(EZO_CMD_DEBUG_GROUP_ACTIVITY_USAGE))
        end
        return false
    end

    MOD.ShowSimulation(argument)
    if type(EZO.Print) == "function" then
        EZO.Print(GetString(EZO_DEBUG_GROUP_ACTIVITY_PANEL_SHOWN))
    end
    return true
end

function MOD.Initialize()
    if initialized or type(EVENT_MANAGER) ~= "table" then
        return
    end
    initialized = true
    if EVENT_PLAYER_ACTIVATED ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, function()
            MOD.Refresh()
        end)
    end
    if EVENT_GROUP_UPDATE ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_UPDATE, function()
            if not MOD.CanShowInMenu() then
                MOD.Hide()
            else
                MOD.Refresh()
            end
        end)
    end
    if EVENT_LEADER_UPDATE ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_LEADER_UPDATE, function()
            if not MOD.CanShowInMenu() then
                MOD.Hide()
            else
                MOD.Refresh()
            end
        end)
    end
end
