-- Reset controlado de instancia para lider de grupo/raid.
-- Primera version: snapshot, disband, viaje a casa, espera, regreso e invitaciones basicas.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.RaidLeaderReset = EZO.RaidLeaderReset or {}
local MOD = EZO.RaidLeaderReset

local EVENT_NAMESPACE = "EZOTools_RaidLeaderReset"
local STATUS_UPDATE_NAMESPACE = "EZOTools_RaidLeaderReset_StatusUpdate"
local DEFAULT_DESTINATION = "primary"
local DEFAULT_WAIT_SECONDS = 30
local DEFAULT_INVITE_DELAY_SECONDS = 10
local DEFAULT_REINVITE_DELAY_SECONDS = 30
local DEFAULT_REINVITE_ATTEMPTS = 1
local TOTAL_PHASES = 6
local MAX_HOUSE_CHECKS = 12
local MAX_RETURN_CHECKS = 12
local RETURN_TRAVEL_MONITOR_INTERVAL_MS = 250
local RETURN_TRAVEL_START_TIMEOUT_MS = 20000

local activeRun = nil
local statusRun = nil
local displayedRunId = nil
local statusPanel, statusWin
local statusWindowUnlocked = false
local GetCurrentGroupDisplayNames
local CheckStagingArrival
local CheckReturnArrival
local CompleteRun
local EmitReport
local IsAtTargetInstance
local OnPlayerActivated
local OnRaidTrialStarted
local OnPlayerCombatState
local OnPrepareForJump
local OnJumpFailed
local OnGroupInviteResponse
local OnGroupMemberJoined
local OnGroupMemberLeft
local OnGroupUpdate
local CheckTrialEntryCompletion
local ClearResetSession
local CheckRetainedSessionGroupState
local CheckRetainedSessionLocationState

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

local function EmitAutomaticGroupStatus(actionKey)
    local status = EZO and EZO.RaidLeaderStatus
    if status and type(status.EmitForAction) == "function" then
        SafeCall(status.EmitForAction, actionKey)
    end
end

local function Print(message)
    if EZO and type(EZO.Print) == "function" then
        EZO.Print(message)
    elseif type(d) == "function" then
        d(tostring(message))
    end
end

local function GetSettings()
    EZO.sv = EZO.sv or {}
    EZO.sv.raidLeaderReset = EZO.sv.raidLeaderReset or {}
    local settings = EZO.sv.raidLeaderReset
    if settings.destination == nil or settings.destination == "" then
        settings.destination = DEFAULT_DESTINATION
    end
    if settings.waitSeconds == nil then settings.waitSeconds = DEFAULT_WAIT_SECONDS end
    if settings.inviteDelaySeconds == nil then settings.inviteDelaySeconds = DEFAULT_INVITE_DELAY_SECONDS end
    if settings.reinviteDelaySeconds == nil then settings.reinviteDelaySeconds = DEFAULT_REINVITE_DELAY_SECONDS end
    if settings.reinviteAttempts == nil then settings.reinviteAttempts = DEFAULT_REINVITE_ATTEMPTS end
    if settings.enabled == nil then settings.enabled = true end
    settings.inviteMembers = nil
    if settings.confirmDangerousActions == nil then settings.confirmDangerousActions = true end
    return settings
end

local function IsResetEnabled()
    return GetSettings().enabled ~= false
end

local function ClampNumber(value, fallback, minValue, maxValue)
    value = tonumber(value) or fallback
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function IsHUDSceneVisible()
    return SCENE_MANAGER
        and type(SCENE_MANAGER.IsShowing) == "function"
        and (SCENE_MANAGER:IsShowing("hud") or SCENE_MANAGER:IsShowing("hudui"))
end

local function ApplyStatusWindowPosition()
    if not statusPanel then return end
    local settings = GetSettings()
    local x = tonumber(settings.statusWindowX)
    local y = tonumber(settings.statusWindowY)
    statusPanel:SetPosition(x, y)
end

local function ApplyStatusWindowInteraction()
    if not statusPanel then return end
    statusPanel:SetMovable(statusWindowUnlocked)
end

local function ApplyStatusWindowPlacementPreview()
    local preview = EZO and EZO.StatusPanelPreview
    if not statusPanel or not preview or type(preview.BuildModel) ~= "function" then
        return false
    end
    statusPanel:SetModel(preview.BuildModel())
    statusPanel:SetHidden(false)
    return true
end

local function EnsureStatusWindow()
    if statusWin or not WINDOW_MANAGER then
        return statusWin
    end

    local panelModule = EZO and EZO.StatusPanel
    if not panelModule or type(panelModule.Create) ~= "function" then
        return nil
    end
    statusPanel = panelModule.Create("RaidLeaderReset", { width = 520 })
    if not statusPanel then
        return nil
    end
    statusWin = statusPanel:GetControl()
    statusPanel:SetHidden(true)
    ApplyStatusWindowPosition()
    ApplyStatusWindowInteraction()
    statusPanel:SetMoveStopCallback(function(left, top)
        local settings = GetSettings()
        settings.statusWindowX = math.floor(left + 0.5)
        settings.statusWindowY = math.floor(top + 0.5)
    end)

    return statusWin
end

local function GetCapturedNames(run)
    local names = {}
    local playerName = type(GetDisplayName) == "function" and tostring(GetDisplayName() or "") or ""
    local group = run and run.snapshot and run.snapshot.group or {}
    for _, member in ipairs(group.members or {}) do
        local displayName = tostring(member.displayName or "")
        if displayName ~= "" and displayName ~= playerName then
            names[#names + 1] = displayName
        end
    end
    return names
end

local function EnsureMemberStates(run)
    run.memberStates = run.memberStates or {}
    for _, displayName in ipairs(GetCapturedNames(run)) do
        if not run.memberStates[displayName] then
            run.memberStates[displayName] = {
                displayName = displayName,
                invitesSent = 0,
                inviteResponses = 0,
                requestErrors = 0,
                status = "pending",
            }
        end
    end
    return run.memberStates
end

local function GetCapturedNameSet(run)
    local captured = {}
    for _, displayName in ipairs(GetCapturedNames(run)) do
        captured[displayName] = true
    end
    return captured
end

local function GetAdditionalNames(run, currentNames)
    local additional = {}
    currentNames = currentNames or GetCurrentGroupDisplayNames()
    local captured = GetCapturedNameSet(run)
    local playerName = type(GetDisplayName) == "function" and tostring(GetDisplayName() or "") or ""
    for displayName in pairs(currentNames or {}) do
        if displayName ~= "" and displayName ~= playerName and not captured[displayName] then
            additional[#additional + 1] = displayName
        end
    end
    table.sort(additional)
    return additional
end

local function GetCurrentCapturedCount(run, currentNames)
    currentNames = currentNames or GetCurrentGroupDisplayNames()
    local count = 0
    for _, displayName in ipairs(GetCapturedNames(run)) do
        if currentNames[displayName] then count = count + 1 end
    end
    return count
end

local function SyncMemberStates(run, currentNames)
    currentNames = currentNames or GetCurrentGroupDisplayNames()
    local statesByName = EnsureMemberStates(run)
    local ordered = {}
    for _, displayName in ipairs(GetCapturedNames(run)) do
        local state = statesByName[displayName]
        if currentNames[displayName] then
            state.status = "joined"
            state.joinedAfterReset = run.returnConfirmed == true or state.joinedAfterReset == true
            state.excludeFromInvites = nil
            state.excludedStatus = nil
        elseif state.excludeFromInvites == true then
            state.status = state.excludedStatus or "left"
        elseif state.responseStatus then
            state.status = state.responseStatus
        elseif (tonumber(state.invitesSent) or 0) > 0 then
            state.status = "invited"
        elseif (tonumber(state.requestErrors) or 0) > 0 then
            state.status = "error"
        else
            state.status = "pending"
        end
        ordered[#ordered + 1] = state
    end
    return ordered
end

local function GetPendingNames(run, currentNames)
    currentNames = currentNames or GetCurrentGroupDisplayNames()
    local pending = {}
    local statesByName = EnsureMemberStates(run)
    for _, displayName in ipairs(GetCapturedNames(run)) do
        local state = statesByName[displayName]
        if not currentNames[displayName] and not (state and state.excludeFromInvites == true) then
            pending[#pending + 1] = displayName
        end
    end
    return pending
end

local function GetMemberStatusText(status)
    if status == "joined" then
        return GetString(EZO_INSTANCE_RESET_MEMBER_STATUS_JOINED)
    elseif status == "invited" then
        return GetString(EZO_INSTANCE_RESET_MEMBER_STATUS_INVITED)
    elseif status == "accepted" then
        return GetString(EZO_INSTANCE_RESET_MEMBER_STATUS_ACCEPTED)
    elseif status == "declined" then
        return GetString(EZO_INSTANCE_RESET_MEMBER_STATUS_DECLINED)
    elseif status == "ignored" then
        return GetString(EZO_INSTANCE_RESET_MEMBER_STATUS_IGNORED)
    elseif status == "error" then
        return GetString(EZO_INSTANCE_RESET_MEMBER_STATUS_ERROR)
    elseif status == "kicked" then
        return GetString(EZO_INSTANCE_RESET_MEMBER_STATUS_KICKED)
    elseif status == "left" then
        return GetString(EZO_INSTANCE_RESET_MEMBER_STATUS_LEFT)
    end
    return GetString(EZO_INSTANCE_RESET_MEMBER_STATUS_PENDING)
end

local function BuildMemberSummaryLines(run)
    local lines = {}
    if not run then
        return lines
    end
    local currentNames = GetCurrentGroupDisplayNames()
    for index, state in ipairs(SyncMemberStates(run, currentNames)) do
        lines[#lines + 1] = string.format(
            "member[%d]=%s status:%s invites:%d responses:%d errors:%d excluded:%s",
            index,
            tostring(state.displayName or ""),
            tostring(state.status or "pending"),
            tonumber(state.invitesSent) or 0,
            tonumber(state.inviteResponses) or 0,
            tonumber(state.requestErrors) or 0,
            tostring(state.excludeFromInvites == true)
        )
    end
    return lines
end

local function JoinNames(list, emptyText)
    if type(list) ~= "table" or #list == 0 then
        return emptyText or "-"
    end

    local shown = {}
    local maxShown = 12
    for i = 1, math.min(#list, maxShown) do
        shown[#shown + 1] = tostring(list[i])
    end
    if #list > maxShown then
        shown[#shown + 1] = zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_MORE), #list - maxShown)
    end
    return table.concat(shown, ", ")
end

local function GetNowMilliseconds()
    if type(GetFrameTimeMilliseconds) == "function" then
        return tonumber(GetFrameTimeMilliseconds()) or 0
    end
    return 0
end

local function FormatDurationMilliseconds(milliseconds)
    local totalSeconds = math.max(0, math.floor((tonumber(milliseconds) or 0) / 1000))
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, seconds)
    end
    return string.format("%02d:%02d", minutes, seconds)
end

local function GetMemberTone(status)
    if status == "joined" or status == "accepted" then
        return "success", "success"
    elseif status == "invited" then
        return "info", "pending"
    elseif status == "declined" or status == "ignored" or status == "error" or status == "kicked" then
        return "error", "error"
    elseif status == "left" then
        return "muted", "error"
    end
    return "pending", "pending"
end

local function GetStatusPanelWidth(memberCount)
    memberCount = tonumber(memberCount) or 0
    local gamepad = type(IsInGamepadPreferredMode) == "function" and IsInGamepadPreferredMode()
    if memberCount <= 4 then
        return gamepad and 500 or 480
    elseif memberCount <= 7 then
        return gamepad and 510 or 500
    end
    return 520
end

local function GetMemberLocation(currentNames, displayName)
    local unitTag = currentNames and currentNames[displayName]
    if type(unitTag) ~= "string" or unitTag == "" then
        return GetString(EZO_INSTANCE_RESET_MEMBER_LOCATION_UNKNOWN), "muted"
    end
    if type(IsUnitOnline) == "function" then
        local onlineOk, online = SafeCall(IsUnitOnline, unitTag)
        if onlineOk and online ~= true then
            return GetString(EZO_INSTANCE_RESET_MEMBER_LOCATION_UNKNOWN), "muted"
        end
    end
    if type(IsGroupMemberInSameInstanceAsPlayer) ~= "function" then
        return GetString(EZO_INSTANCE_RESET_MEMBER_LOCATION_UNKNOWN), "muted"
    end
    local ok, sameInstance = SafeCall(IsGroupMemberInSameInstanceAsPlayer, unitTag)
    if not ok then
        return GetString(EZO_INSTANCE_RESET_MEMBER_LOCATION_UNKNOWN), "muted"
    end
    if sameInstance == true then
        return GetString(EZO_INSTANCE_RESET_MEMBER_LOCATION_SAME), "success"
    end
    return GetString(EZO_INSTANCE_RESET_MEMBER_LOCATION_DIFFERENT), "warning"
end

local function BuildPublicActivityState(run)
    if not run then
        return nil
    end
    local pending = GetPendingNames(run)
    local instance = run.snapshot and run.snapshot.instance or {}
    return {
        schemaVersion = 1,
        sourceAddon = "ezotools",
        activityType = "trial",
        sessionId = tonumber(run.id) or 0,
        runId = tostring(run.id or ""),
        targetKey = tostring(run.targetTrialKey or ""),
        targetName = tostring(run.targetTrialName or ""),
        difficulty = tonumber(instance.difficulty),
        modeName = tostring(instance.difficultyName or ""),
        stage = tostring(run.stage or ""),
        resumeStage = tostring(run.resumeStage or ""),
        statusText = tostring(run.statusText or ""),
        phaseIndex = tonumber(run.phaseIndex) or 0,
        totalPhases = TOTAL_PHASES,
        resetComplete = run.stage == "waiting-trial-entry" and #pending == 0,
        capturedMembers = #GetCapturedNames(run),
        pendingMembers = #pending,
        startedAtMs = tonumber(run.startedAtMs) or 0,
        updatedAtMs = GetNowMilliseconds(),
    }
end

local function PublishRunActivityState(run, overrides, force)
    local sharing = EZO and EZO.GroupActivitySharing
    if sharing and type(sharing.PublishResetState) == "function" then
        SafeCall(sharing.PublishResetState, BuildPublicActivityState(run), overrides, force)
    end
end

local function UpdateStatusWindow(run, stageText, phaseIndex)
    if not run then
        return
    end

    stageText = stageText or run.statusText or tostring(run.stage or "")
    run.statusText = stageText
    local nextPhaseIndex = tonumber(phaseIndex)
    if nextPhaseIndex then
        if run.phaseIndex ~= nextPhaseIndex then
            run.phaseStartedAtMs = GetNowMilliseconds()
        end
        run.phaseIndex = nextPhaseIndex
    end
    PublishRunActivityState(run)

    local win = EnsureStatusWindow()
    if not win then
        return
    end

    local currentNames = GetCurrentGroupDisplayNames()
    local memberStates = SyncMemberStates(run, currentNames)
    local captured = #memberStates
    local pending = GetPendingNames(run, currentNames)
    local currentCaptured = GetCurrentCapturedCount(run, currentNames)
    local additional = GetAdditionalNames(run, currentNames)
    local invitedTotal = tonumber(run.invitedTotal) or 0
    local target = run.targetTrialName ~= "" and run.targetTrialName or GetString(EZO_INSTANCE_RESET_STATUS_TARGET_UNKNOWN)
    local instance = run.snapshot and run.snapshot.instance or {}
    local mode = tostring(instance.difficultyName or "")
    if mode == "" then
        mode = GetString(EZO_INSTANCE_RESET_STATUS_TARGET_UNKNOWN)
    end
    local nowMs = GetNowMilliseconds()
    local displayNowMs = run.stage == "interrupted"
        and (tonumber(run.interruptedAtMs) or nowMs)
        or nowMs
    local elapsedText = FormatDurationMilliseconds(displayNowMs - (tonumber(run.startedAtMs) or displayNowMs))
    local phaseElapsedText = FormatDurationMilliseconds(displayNowMs - (tonumber(run.phaseStartedAtMs) or displayNowMs))
    local resetComplete = run.stage == "waiting-trial-entry" and #pending == 0
    local phaseIndexValue = tonumber(run.phaseIndex) or 1
    local phaseText = resetComplete
        and GetString(EZO_INSTANCE_RESET_STATUS_COMPLETE)
        or zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_PHASE_SHORT), phaseIndexValue, TOTAL_PHASES)
    local statusTimeText = resetComplete and "" or phaseElapsedText
    if tonumber(run.waitEndsAtMs) then
        statusTimeText = FormatDurationMilliseconds(math.max(0, run.waitEndsAtMs - nowMs))
    end

    local alertLines = {}
    local alertTone = "info"
    if run.resumeStage then
        alertLines[#alertLines + 1] = run.resumeHintText or GetString(EZO_INSTANCE_RESET_STATUS_RESUME_HINT)
        alertTone = "warning"
    end
    if #additional > 0 then
        alertLines[#alertLines + 1] = zo_strformat(
            GetString(EZO_INSTANCE_RESET_STATUS_ADDITIONAL),
            JoinNames(additional, GetString(EZO_INSTANCE_RESET_STATUS_NONE))
        )
    end

    local memberRows = {}
    for _, state in ipairs(memberStates) do
        local tone, iconType = GetMemberTone(state.status)
        local isInGroup = state.status == "joined"
        local location
        local locationTone
        local statusText
        if isInGroup then
            location, locationTone = GetMemberLocation(currentNames, state.displayName)
            statusText = GetMemberStatusText(state.status)
        else
            statusText = zo_strformat(
                GetString(EZO_INSTANCE_RESET_STATUS_MEMBER_STATE_REQUESTS),
                GetMemberStatusText(state.status),
                tonumber(state.invitesSent) or 0
            )
        end
        memberRows[#memberRows + 1] = {
            id = state.displayName,
            name = state.displayName,
            status = statusText,
            tone = tone,
            iconType = iconType,
            location = location,
            locationTone = locationTone,
        }
    end

    if statusWindowUnlocked and ApplyStatusWindowPlacementPreview() then
        return
    end

    statusPanel:SetModel({
        width = GetStatusPanelWidth(captured),
        title = target,
        phaseText = phaseText,
        contextText = zo_strformat(
            GetString(EZO_INSTANCE_RESET_STATUS_ACTIVITY),
            GetString(EZO_INSTANCE_RESET_STATUS_TITLE),
            mode
        ),
        totalTimeText = elapsedText,
        progress = {
            min = 0,
            max = TOTAL_PHASES,
            value = phaseIndexValue,
            text = zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_PROGRESS), phaseIndexValue, TOTAL_PHASES),
        },
        statusText = stageText,
        statusTimeText = statusTimeText,
        alert = #alertLines > 0 and {
            text = table.concat(alertLines, "\n"),
            tone = alertTone,
        } or nil,
        metrics = {
            {
                value = captured,
                label = GetString(EZO_INSTANCE_RESET_STATUS_METRIC_CAPTURED),
            },
            {
                value = currentCaptured,
                label = GetString(EZO_INSTANCE_RESET_STATUS_METRIC_IN_GROUP),
                tone = currentCaptured == captured and "success" or "normal",
            },
            {
                value = #pending,
                label = GetString(EZO_INSTANCE_RESET_STATUS_METRIC_PENDING),
                tone = #pending > 0 and "warning" or "success",
            },
            {
                value = invitedTotal,
                label = GetString(EZO_INSTANCE_RESET_STATUS_METRIC_INVITES),
                tone = "info",
            },
        },
        rowsTitle = zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_MEMBERS_COUNT), #memberStates),
        rows = memberRows,
    })
    displayedRunId = tostring(run.id or "")
    statusPanel:SetHidden(not IsHUDSceneVisible())
end

local function StopStatusTicker()
    if EVENT_MANAGER and type(EVENT_MANAGER.UnregisterForUpdate) == "function" then
        EVENT_MANAGER:UnregisterForUpdate(STATUS_UPDATE_NAMESPACE)
    end
end

local function StartStatusTicker()
    if not (EVENT_MANAGER and type(EVENT_MANAGER.RegisterForUpdate) == "function") then
        return
    end
    StopStatusTicker()
    EVENT_MANAGER:RegisterForUpdate(STATUS_UPDATE_NAMESPACE, 1000, function()
        local run = activeRun or statusRun
        if not run then
            StopStatusTicker()
        elseif CheckTrialEntryCompletion and CheckTrialEntryCompletion(run, "status-ticker") then
            return
        elseif CheckRetainedSessionLocationState and CheckRetainedSessionLocationState(run, "status-ticker") then
            return
        elseif CheckRetainedSessionGroupState and CheckRetainedSessionGroupState(run, "status-ticker") then
            return
        elseif not activeRun
            and statusRun
            and statusRun.stage == "waiting-members"
            and #GetPendingNames(statusRun) == 0 then
            CompleteRun(statusRun, false)
        else
            UpdateStatusWindow(run)
        end
    end)
end

local function HideStatusWindow(delayMs, run)
    if not statusWin then
        return
    end
    local expectedRunId = run and tostring(run.id or "") or nil
    local function Hide()
        if statusPanel and (not expectedRunId or displayedRunId == expectedRunId) then
            statusPanel:SetHidden(true)
            displayedRunId = nil
        end
    end
    if type(zo_callLater) == "function" and tonumber(delayMs) and delayMs > 0 then
        zo_callLater(Hide, delayMs)
    else
        Hide()
    end
end

local function UnregisterTravelEvent()
    if type(EVENT_MANAGER) ~= "table" then
        return
    end
    if EVENT_PLAYER_ACTIVATED ~= nil then
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED)
    end
    if EVENT_PLAYER_COMBAT_STATE ~= nil then
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_COMBAT_STATE)
    end
    if EVENT_JUMP_FAILED ~= nil then
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_JUMP_FAILED)
    end
    if EVENT_PREPARE_FOR_JUMP ~= nil then
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_PREPARE_FOR_JUMP)
    end
end

local function UnregisterRunEvents()
    UnregisterTravelEvent()
    if type(EVENT_MANAGER) == "table" and EVENT_RAID_TRIAL_STARTED ~= nil then
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_RAID_TRIAL_STARTED)
    end
    if type(EVENT_MANAGER) == "table" and EVENT_GROUP_INVITE_RESPONSE ~= nil then
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_INVITE_RESPONSE)
    end
    if type(EVENT_MANAGER) == "table" and EVENT_GROUP_MEMBER_JOINED ~= nil then
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_MEMBER_JOINED)
    end
    if type(EVENT_MANAGER) == "table" and EVENT_GROUP_MEMBER_LEFT ~= nil then
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_MEMBER_LEFT)
    end
    if type(EVENT_MANAGER) == "table" and EVENT_GROUP_UPDATE ~= nil then
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_UPDATE)
    end
end

CompleteRun = function(run, monitorPending, completionText)
    if not run then
        return
    end
    run.waitEndsAtMs = nil
    run.resumeStage = nil
    run.interruptionReason = nil
    if activeRun and run and activeRun.id == run.id then
        activeRun = nil
    end
    UnregisterTravelEvent()

    local pending = GetPendingNames(run)
    if monitorPending == true and #pending > 0 then
        run.stage = "waiting-members"
        statusRun = run
        UpdateStatusWindow(run, GetString(EZO_INSTANCE_RESET_STAGE_WAITING_MEMBERS), 6)
        EmitReport("waiting-members", run, {
            "pending.count=" .. tostring(#pending),
        })
        StartStatusTicker()
        return
    end

    if tostring(run.targetTrialKey or "") ~= "" then
        run.stage = "waiting-trial-entry"
        statusRun = run
        local waitingText = completionText or GetString(EZO_INSTANCE_RESET_STAGE_WAITING_TRIAL_ENTRY)
        if #pending == 0 then
            waitingText = GetString(EZO_INSTANCE_RESET_STAGE_READY_FOR_ENTRY)
        end
        UpdateStatusWindow(run, waitingText, 6)
        EmitReport("waiting-trial-entry", run, {
            "pending.count=" .. tostring(#pending),
        })
        StartStatusTicker()
        return
    end

    if statusRun and statusRun.id == run.id then
        statusRun = nil
    end
    UpdateStatusWindow(run, completionText or GetString(EZO_INSTANCE_RESET_STAGE_COMPLETE), 6)
    EmitReport("complete", run, {
        "pending.count=" .. tostring(#pending),
    })
    HideStatusWindow(20000, run)
    StopStatusTicker()
    UnregisterRunEvents()
end

local REPORT_LEVEL_BY_STAGE = {
    ["started"] = "info",
    ["disband-confirmed"] = "info",
    ["waiting-at-staging"] = "info",
    ["returning"] = "info",
    ["returned-activation"] = "info",
    ["invites-disabled"] = "info",
    ["waiting-members"] = "info",
    ["waiting-trial-entry"] = "info",
    ["complete"] = "info",
    ["resumed"] = "info",
    ["trial-entered"] = "info",
    ["reset-session-cleared"] = "info",
    ["new-reset-superseding-previous"] = "info",
    ["interrupted"] = "warning",
    ["start-rejected"] = "warning",
}

local TERMINAL_REPORT_STAGES = {
    ["waiting-members"] = true,
    ["waiting-trial-entry"] = true,
    ["complete"] = true,
    ["interrupted"] = true,
    ["trial-entered"] = true,
    ["reset-session-cleared"] = true,
}

local function AccumulateReportEvent(run, stage)
    if not run then
        return
    end
    run.reportEventCounts = run.reportEventCounts or {}
    run.reportEventCounts[stage] = (tonumber(run.reportEventCounts[stage]) or 0) + 1
    run.reportEventTotal = (tonumber(run.reportEventTotal) or 0) + 1
    run.lastReportEvent = stage
end

local function AppendEventSummary(lines, run)
    local counts = run and run.reportEventCounts
    if type(counts) ~= "table" then
        return
    end
    local stages = {}
    for stage in pairs(counts) do
        stages[#stages + 1] = stage
    end
    table.sort(stages)
    for _, stage in ipairs(stages) do
        lines[#lines + 1] = string.format("events.%s=%d", stage, tonumber(counts[stage]) or 0)
    end
end

local function GetReportKey(stage, run)
    if stage == "interrupted" then
        return stage .. ":" .. tostring(run and run.interruptionCount or 0)
    end
    if stage == "resumed" then
        return stage .. ":" .. tostring(run and run.interruptionCount or 0)
    end
    return stage
end

EmitReport = function(stage, run, extra)
    if not (EZO and EZO.IsDebugModeEnabled and EZO.IsDebugModeEnabled()) then
        return
    end
    if not (EZO.Debug and type(EZO.Debug.EmitReport) == "function") then
        return
    end

    stage = tostring(stage or "")
    local level = REPORT_LEVEL_BY_STAGE[stage]
    if level == nil then
        AccumulateReportEvent(run, stage)
        return
    end

    if run then
        run.reportedLifecycleStages = run.reportedLifecycleStages or {}
        local reportKey = GetReportKey(stage, run)
        if run.reportedLifecycleStages[reportKey] == true then
            return
        end
        run.reportedLifecycleStages[reportKey] = true
    end

    local snapshot = run and run.snapshot or {}
    local group = snapshot.group or {}
    local instance = snapshot.instance or {}
    local nowMs = GetNowMilliseconds()
    local currentNames = run and GetCurrentGroupDisplayNames() or {}
    local pending = run and GetPendingNames(run) or {}
    local lines = {
        "=== EZOTools instance reset ===",
        "run.id=" .. tostring(run and run.id or "none"),
        "stage=" .. stage,
        "phase=" .. tostring(run and run.phaseIndex or "") .. "/" .. tostring(TOTAL_PHASES),
        "elapsed.ms=" .. tostring(run and math.max(0, nowMs - (tonumber(run.startedAtMs) or nowMs)) or 0),
        "phase.elapsed.ms=" .. tostring(run and math.max(0, nowMs - (tonumber(run.phaseStartedAtMs) or nowMs)) or 0),
        "destination=" .. tostring(run and run.destination or ""),
        "target.trialKey=" .. tostring(run and run.targetTrialKey or ""),
        "target.trialName=" .. tostring(run and run.targetTrialName or ""),
        "group.size=" .. tostring(group.size or 0),
        "group.isLeader=" .. tostring(group.isLeader == true),
        "group.currentCaptured=" .. tostring(run and GetCurrentCapturedCount(run, currentNames) or 0),
        "group.pending=" .. tostring(#pending),
        "instance.inInstance=" .. tostring(instance.inInstance == true),
        "instance.zoneName=" .. tostring(instance.zoneName or ""),
        "instance.difficulty=" .. tostring(instance.difficulty or ""),
        "instance.difficultyName=" .. tostring(instance.difficultyName or ""),
        "run.invitesSent=" .. tostring(run and run.invitedTotal or 0),
        "run.inviteAttempt=" .. tostring(run and run.inviteAttempt or 0),
        "events.total=" .. tostring(run and run.reportEventTotal or 0),
        "run.internalDisbandExpected=" .. tostring(run and run.internalDisbandExpected == true),
        "run.internalDisbandConfirmed=" .. tostring(run and run.internalDisbandConfirmed == true),
        "run.groupReformedObserved=" .. tostring(run and run.groupReformedObserved == true),
        "run.returnTravelPrepared=" .. tostring(run and run.returnTravelPrepared == true),
    }
    if type(extra) == "table" then
        for _, line in ipairs(extra) do
            lines[#lines + 1] = tostring(line)
        end
    end
    AppendEventSummary(lines, run)
    if TERMINAL_REPORT_STAGES[stage] then
        for _, line in ipairs(BuildMemberSummaryLines(run)) do
            lines[#lines + 1] = line
        end
    end
    lines[#lines + 1] = "================================"
    EZO.Debug.EmitReport(GetString(EZO_DEBUG_INSTANCE_RESET_TITLE), lines, { level = level })
    if run then
        run.reportEventCounts = {}
        run.reportEventTotal = 0
        run.lastReportEvent = nil
    end
end

ClearResetSession = function(run, source)
    if not run then return false end
    EmitReport("reset-session-cleared", run, {
        "clear.source=" .. tostring(source or ""),
        "clear.previousStage=" .. tostring(run.stage or ""),
    })
    local sourceText = tostring(source or "")
    local cancelled = sourceText == "user-cancelled"
        or string.find(sourceText, "standalone", 1, true) ~= nil
        or string.find(sourceText, "leave", 1, true) ~= nil
        or string.find(sourceText, "new-reset", 1, true) ~= nil
    PublishRunActivityState(run, {
        stage = cancelled and "idle" or "failed",
        result = cancelled and "cancelled" or "failed",
    }, true)
    if activeRun and activeRun.id == run.id then activeRun = nil end
    if statusRun and statusRun.id == run.id then statusRun = nil end
    run.stage = "cleared"
    run.waitEndsAtMs = nil
    run.resumeStage = nil
    run.interruptionReason = nil
    StopStatusTicker()
    UnregisterRunEvents()
    HideStatusWindow(0, run)
    return true
end

local function IsInternalDisbandPending(run)
    return run ~= nil
        and run.stage == "disbanding"
        and run.internalDisbandExpected == true
        and run.internalDisbandConfirmed ~= true
end

local function IsPlayerCurrentlyGrouped()
    return type(IsUnitGrouped) == "function" and IsUnitGrouped("player") == true
end

CheckRetainedSessionGroupState = function(run, source)
    if not run or run.internalDisbandConfirmed ~= true then
        return false
    end
    if IsPlayerCurrentlyGrouped() then
        run.groupReformedObserved = true
        return false
    end
    if run.groupReformedObserved == true and not IsInternalDisbandPending(run) then
        return ClearResetSession(run, "group-no-longer-formed:" .. tostring(source or "unknown"))
    end
    return false
end

CheckRetainedSessionLocationState = function(run, source)
    if not run or run.returnConfirmed ~= true then
        return false
    end
    if run.stage ~= "inviting" and run.stage ~= "waiting-members" and run.stage ~= "waiting-trial-entry" then
        return false
    end
    if IsAtTargetInstance(run) then
        return false
    end
    return ClearResetSession(run, "player-left-target-instance:" .. tostring(source or "unknown"))
end

local function Normalize(value)
    value = tostring(value or "")
    value = value:gsub("’", "'"):gsub("`", "'"):gsub("´", "'")
    value = string.lower(value)
    value = value:gsub("[^%w]+", "")
    return value
end

local function DetectTrialFromZone(zoneName)
    local catalog = EZO and EZO.RaidLeaderActivityCatalog
    if not (catalog and type(catalog.GetTrialDefinitions) == "function") then
        return nil
    end

    local normalizedZone = Normalize(zoneName)
    if normalizedZone == "" then
        return nil
    end

    local ok, trials = SafeCall(catalog.GetTrialDefinitions)
    if not ok or type(trials) ~= "table" then
        return nil
    end

    for _, trial in ipairs(trials) do
        local aliases = trial.aliases or {}
        for _, alias in ipairs(aliases) do
            local normalizedAlias = Normalize(alias)
            if normalizedAlias ~= ""
                and (normalizedZone == normalizedAlias
                    or string.find(normalizedZone, normalizedAlias, 1, true) ~= nil
                    or string.find(normalizedAlias, normalizedZone, 1, true) ~= nil) then
                return trial
            end
        end
    end
    return nil
end

IsAtTargetInstance = function(run)
    if not run or tostring(run.targetTrialKey or "") == "" then
        return false
    end
    local tools = EZO and EZO.RaidLeaderTools
    if not (tools and type(tools.BuildInstanceSnapshot) == "function") then
        return false
    end
    local ok, instance = SafeCall(tools.BuildInstanceSnapshot)
    if not ok or type(instance) ~= "table" then
        return false
    end
    local targetZoneIndex = tonumber(run.targetZoneIndex)
    local currentZoneIndex = tonumber(instance.zoneIndex)
    if targetZoneIndex and currentZoneIndex and targetZoneIndex == currentZoneIndex then
        return true
    end
    local trial = DetectTrialFromZone(instance.zoneName)
    return trial and tostring(trial.key or "") == tostring(run.targetTrialKey or "")
end

local function GetResumableRun()
    if activeRun or not statusRun then
        return nil
    end
    if statusRun.resumeStage then
        return statusRun
    end
    if statusRun.stage == "waiting-members" then
        return statusRun
    end
    if statusRun.stage == "waiting-trial-entry" and #GetPendingNames(statusRun) > 0 then
        return statusRun
    end
    return nil
end

local function InterruptRun(run, reasonCode, reasonText, resumeStage, resumeHintText, chatMessage)
    if not run then
        return false
    end
    if activeRun and activeRun.id == run.id then
        activeRun = nil
    end
    run.stage = "interrupted"
    run.waitEndsAtMs = nil
    run.resumeStage = resumeStage
    run.resumeHintText = resumeHintText
    run.interruptionReason = reasonCode
    run.interruptionCount = (tonumber(run.interruptionCount) or 0) + 1
    run.interruptedAtMs = GetNowMilliseconds()
    statusRun = run
    UnregisterTravelEvent()
    UpdateStatusWindow(run, reasonText, run.phaseIndex)
    EmitReport("interrupted", run, {
        "interruption.reason=" .. tostring(reasonCode or ""),
        "interruption.count=" .. tostring(run.interruptionCount),
        "resume.stage=" .. tostring(resumeStage or ""),
    })
    Print(chatMessage or GetString(EZO_MSG_INSTANCE_RESET_INTERRUPTED))
    StartStatusTicker()
    return false
end

local function GetDestination()
    local settings = GetSettings()
    local destination = tostring(settings.destination or DEFAULT_DESTINATION)
    if destination ~= "primary"
        and destination ~= "crafting"
        and destination ~= "secondary"
        and destination ~= "leave-instance" then
        destination = DEFAULT_DESTINATION
    end
    return destination
end

local function CanTravelToDestination(destination)
    if destination == "leave-instance" then
        return EZO
            and type(EZO.CanLeaveInstance) == "function"
            and type(EZO.LeaveInstance) == "function"
    end

    if destination == "primary" then
        if type(GetHousingPrimaryHouse) ~= "function" or type(RequestJumpToHouse) ~= "function" then
            return false
        end
        local ok, houseId = SafeCall(GetHousingPrimaryHouse)
        return ok and tonumber(houseId) ~= nil and tonumber(houseId) > 0
    end

    if type(JumpToHouse) ~= "function" then
        return false
    end

    local friends = EZO.sv and EZO.sv.friends or {}
    local account = destination == "crafting"
        and tostring(friends.craftingHall or "")
        or tostring(friends.secondaryHall or "")
    return account ~= ""
end

local function TravelToDestination(destination)
    if destination == "leave-instance" then
        local ok, requested = SafeCall(EZO.LeaveInstance)
        return ok and requested == true
    end

    if destination == "primary" then
        local ok, houseId = SafeCall(GetHousingPrimaryHouse)
        if ok and tonumber(houseId) and tonumber(houseId) > 0 then
            local okJump = SafeCall(RequestJumpToHouse, houseId)
            return okJump == true
        end
        return false
    end

    local friends = EZO.sv and EZO.sv.friends or {}
    local account = destination == "crafting"
        and tostring(friends.craftingHall or "")
        or tostring(friends.secondaryHall or "")
    if account ~= "" and type(JumpToHouse) == "function" then
        local okJump = SafeCall(JumpToHouse, account)
        return okJump == true
    end
    return false
end

local function IsPlayerInHouse()
    if type(GetCurrentZoneHouseId) == "function" then
        local ok, houseId = SafeCall(GetCurrentZoneHouseId)
        if ok and tonumber(houseId) and tonumber(houseId) > 0 then
            return true
        end
    end
    if type(IsOwnerOfCurrentHouse) == "function" then
        local ok, isOwner = SafeCall(IsOwnerOfCurrentHouse)
        if ok and isOwner == true then
            return true
        end
    end
    if type(IsLocalPlayerHouseOwner) == "function" then
        local ok, isOwner = SafeCall(IsLocalPlayerHouseOwner)
        if ok and isOwner == true then
            return true
        end
    end
    return false
end

local function IsLeaveInstanceDestination(run)
    return run and run.destination == "leave-instance"
end

local function IsStagingDestinationReached(run)
    if IsLeaveInstanceDestination(run) then
        return not IsAtTargetInstance(run)
    end
    return IsPlayerInHouse()
end

local function GetStagingTravelText(run)
    if IsLeaveInstanceDestination(run) then
        return GetString(EZO_INSTANCE_RESET_STAGE_LEAVING_INSTANCE)
    end
    return GetString(EZO_INSTANCE_RESET_STAGE_TRAVELING_HOME)
end

local function GetStagingWaitText(run)
    if IsLeaveInstanceDestination(run) then
        return GetString(EZO_INSTANCE_RESET_STAGE_WAITING_OUTSIDE_INSTANCE)
    end
    return GetString(EZO_INSTANCE_RESET_STAGE_WAITING_HOME)
end

local function GetStagingNotReachedText(run)
    if IsLeaveInstanceDestination(run) then
        return GetString(EZO_INSTANCE_RESET_STAGE_INSTANCE_NOT_LEFT)
    end
    return GetString(EZO_INSTANCE_RESET_STAGE_HOME_NOT_REACHED)
end

local function IsPlayerInCombat()
    if type(IsUnitInCombat) ~= "function" then
        return false
    end
    local ok, inCombat = SafeCall(IsUnitInCombat, "player")
    return ok and inCombat == true
end

local function IsPlayerMovingNow()
    if type(IsPlayerMoving) ~= "function" then return false end
    local ok, moving = SafeCall(IsPlayerMoving)
    return ok and moving == true
end

function GetCurrentGroupDisplayNames()
    local tools = EZO and EZO.RaidLeaderTools
    if tools and type(tools.GetCurrentGroupDisplayNameMap) == "function" then
        return tools.GetCurrentGroupDisplayNameMap()
    end
    return {}
end

local function VerifyInitialSnapshotMembers(run)
    local group = run and run.snapshot and run.snapshot.group
    if not group or group.isGrouped ~= true or group.isLeader ~= true then
        return false, 0
    end

    local currentNames = GetCurrentGroupDisplayNames()
    local playerName = type(GetDisplayName) == "function" and tostring(GetDisplayName() or "") or ""
    local verifiedMembers = {}
    local removed = 0
    for _, member in ipairs(group.members or {}) do
        local displayName = tostring(member.displayName or "")
        if displayName ~= "" and (currentNames[displayName] or displayName == playerName) then
            verifiedMembers[#verifiedMembers + 1] = member
        else
            removed = removed + 1
        end
    end
    if #verifiedMembers == 0 then
        return false, removed
    end

    group.members = verifiedMembers
    group.size = #verifiedMembers
    run.snapshot.verifiedAtMs = GetNowMilliseconds()
    run.snapshot.lastVerificationRemoved = removed
    return true, removed
end

local function InviteSnapshotMembers(run)
    if not run or not run.snapshot or not run.snapshot.group then
        return false
    end
    local tools = EZO and EZO.RaidLeaderTools
    if not tools or type(tools.InviteDisplayNames) ~= "function" then
        EmitReport("invite-unavailable", run)
        return false
    end

    local memberStates = EnsureMemberStates(run)
    local available, invited = tools.InviteDisplayNames(GetCapturedNames(run), {
        shouldInvite = function(displayName)
            local state = memberStates[displayName]
            return not state or state.excludeFromInvites ~= true
        end,
        onResult = function(displayName, ok)
            local state = memberStates[displayName]
            if not state then return end
            if ok then
                state.invitesSent = (tonumber(state.invitesSent) or 0) + 1
                state.responseStatus = nil
                state.lastResponse = nil
                state.status = "invited"
            else
                state.requestErrors = (tonumber(state.requestErrors) or 0) + 1
                state.status = "error"
            end
        end,
    })
    if not available then
        EmitReport("invite-unavailable", run)
        return false
    end

    run.inviteAttempt = (run.inviteAttempt or 0) + 1
    run.inviteCycleAttempt = (run.inviteCycleAttempt or 0) + 1
    run.invitedTotal = (run.invitedTotal or 0) + invited
    EmitReport("invites-sent", run, {
        "invited.count=" .. tostring(invited),
        "invite.attempt=" .. tostring(run.inviteAttempt),
    })
    return true
end

local function ScheduleInvites(run)
    local settings = GetSettings()
    if run.targetTrialKey ~= "" and not IsAtTargetInstance(run) then
        InterruptRun(
            run,
            "target-instance-not-confirmed",
            GetString(EZO_INSTANCE_RESET_STAGE_TARGET_NOT_CONFIRMED),
            "returning"
        )
        return
    end
    if type(zo_callLater) ~= "function" then
        UpdateStatusWindow(run, GetString(EZO_INSTANCE_RESET_STAGE_INVITING), 6)
        local invitesAvailable = InviteSnapshotMembers(run)
        if invitesAvailable then
            CompleteRun(run, true)
        else
            CompleteRun(run, false, GetString(EZO_INSTANCE_RESET_STAGE_INVITES_UNAVAILABLE))
        end
        return
    end

    local inviteDelayMs = ClampNumber(settings.inviteDelaySeconds, DEFAULT_INVITE_DELAY_SECONDS, 0, 120) * 1000
    local reinviteDelayMs = ClampNumber(settings.reinviteDelaySeconds, DEFAULT_REINVITE_DELAY_SECONDS, 10, 300) * 1000
    local maxAttempts = ClampNumber(settings.reinviteAttempts, DEFAULT_REINVITE_ATTEMPTS, 0, 5) + 1
    UpdateStatusWindow(run, GetString(EZO_INSTANCE_RESET_STAGE_WAITING_INVITES), 6)

    local function DoInvite()
        if not activeRun or activeRun.id ~= run.id then
            return
        end
        if run.targetTrialKey ~= "" and not IsAtTargetInstance(run) then
            InterruptRun(
                run,
                "target-instance-lost",
                GetString(EZO_INSTANCE_RESET_STAGE_TARGET_NOT_CONFIRMED),
                "returning"
            )
            return
        end
        if #GetPendingNames(run) == 0 then
            CompleteRun(run, false)
            return
        end
        UpdateStatusWindow(run, GetString(EZO_INSTANCE_RESET_STAGE_INVITING), 6)
        local invitesAvailable = InviteSnapshotMembers(run)
        if not invitesAvailable then
            CompleteRun(run, false, GetString(EZO_INSTANCE_RESET_STAGE_INVITES_UNAVAILABLE))
            return
        end
        if (run.inviteCycleAttempt or 0) < maxAttempts then
            zo_callLater(DoInvite, reinviteDelayMs)
        else
            CompleteRun(run, true)
        end
    end
    zo_callLater(DoInvite, inviteDelayMs)
end

local function ContinueAfterConfirmedReturn(run)
    if not activeRun or activeRun.id ~= run.id or run.stage ~= "returning" then
        return
    end
    run.returnConfirmed = true
    run.internalDisbandExpected = false
    run.stage = "inviting"
    run.returnChecks = 0
    EmitReport("returned-activation", run)
    UpdateStatusWindow(run, GetString(EZO_INSTANCE_RESET_STAGE_RETURNED), 6)
    ScheduleInvites(run)
end

local function InterruptCancelledReturn(run, reasonCode, stageText)
    return InterruptRun(
        run,
        reasonCode,
        stageText,
        "returning",
        GetString(EZO_INSTANCE_RESET_STATUS_RETRY_RETURN_HINT),
        GetString(EZO_MSG_INSTANCE_RESET_RETURN_CANCELLED)
    )
end

local function MonitorReturnTravel(run)
    if not activeRun or activeRun.id ~= run.id or run.stage ~= "returning" then return end
    if IsAtTargetInstance(run) then return end

    if run.returnTravelPrepared == true then
        return
    end
    if IsPlayerMovingNow() then
        InterruptCancelledReturn(
            run,
            "return-travel-cancelled-movement",
            GetString(EZO_INSTANCE_RESET_STAGE_RETURN_CANCELLED_MOVEMENT)
        )
        return
    end
    local requestedAtMs = tonumber(run.returnTravelRequestedAtMs)
    if requestedAtMs and GetNowMilliseconds() - requestedAtMs >= RETURN_TRAVEL_START_TIMEOUT_MS then
        InterruptCancelledReturn(
            run,
            "return-travel-not-started",
            GetString(EZO_INSTANCE_RESET_STAGE_RETURN_CANCELLED)
        )
        return
    end
    if type(zo_callLater) == "function" then
        zo_callLater(function() MonitorReturnTravel(run) end, RETURN_TRAVEL_MONITOR_INTERVAL_MS)
    end
end

local function ReturnToInstance(run)
    if not run then return end
    run.waitEndsAtMs = nil
    if run.targetTrialKey ~= "" and EZO.RaidLeaderTools then
        local tools = EZO.RaidLeaderTools
        local travelFn = type(tools.TravelToTrialWithDifficulty) == "function"
            and tools.TravelToTrialWithDifficulty
            or tools.TravelToTrial
        if type(travelFn) ~= "function" then
            EmitReport("return-travel-unavailable", run)
            InterruptRun(
                run,
                "return-travel-unavailable",
                GetString(EZO_INSTANCE_RESET_STAGE_RETURN_UNAVAILABLE),
                "returning"
            )
            return
        end

        run.stage = "returning"
        EmitReport("returning", run)
        UpdateStatusWindow(run, GetString(EZO_INSTANCE_RESET_STAGE_RETURNING), 5)
        if IsPlayerMovingNow() then
            InterruptCancelledReturn(
                run,
                "return-travel-blocked-moving",
                GetString(EZO_INSTANCE_RESET_STAGE_RETURN_CANCELLED_MOVEMENT)
            )
            return
        end
        run.returnChecks = 0
        run.returnTravelPrepared = false
        run.returnTravelRequestedAtMs = nil
        local targetDifficulty = run.snapshot and run.snapshot.instance and run.snapshot.instance.difficulty or nil
        travelFn(run.targetTrialKey, targetDifficulty, function(requested, reason)
            if requested == true then
                run.returnTravelRequestedAtMs = GetNowMilliseconds()
                if type(zo_callLater) == "function" then
                    zo_callLater(function() MonitorReturnTravel(run) end, RETURN_TRAVEL_MONITOR_INTERVAL_MS)
                end
                return
            end
            if not activeRun or activeRun.id ~= run.id or run.stage ~= "returning" then
                return
            end
            EmitReport("return-travel-request-failed", run, {
                "travel.reason=" .. tostring(reason or ""),
            })
            InterruptRun(
                run,
                "return-travel-request-failed",
                GetString(EZO_INSTANCE_RESET_STAGE_RETURN_UNAVAILABLE),
                "returning"
            )
        end)
        if type(zo_callLater) == "function" then
            zo_callLater(function()
                if activeRun and activeRun.id == run.id and run.stage == "returning" then
                    CheckReturnArrival(run)
                end
            end, 5000)
        else
            CheckReturnArrival(run)
        end
        return
    end

    Print(GetString(EZO_MSG_INSTANCE_RESET_NO_INSTANCE_TARGET))
    EmitReport("no-instance-target", run)
    run.stage = "inviting"
    UpdateStatusWindow(run, GetString(EZO_INSTANCE_RESET_STAGE_NO_TARGET), 6)
    ScheduleInvites(run)
end

function CheckReturnArrival(run)
    if not activeRun or activeRun.id ~= run.id or run.stage ~= "returning" then
        return
    end
    if IsAtTargetInstance(run) then
        ContinueAfterConfirmedReturn(run)
        return
    end

    run.returnChecks = (tonumber(run.returnChecks) or 0) + 1
    if run.returnChecks >= MAX_RETURN_CHECKS then
        InterruptRun(
            run,
            "target-instance-not-reached",
            GetString(EZO_INSTANCE_RESET_STAGE_TARGET_NOT_CONFIRMED),
            "returning"
        )
        return
    end

    if type(zo_callLater) == "function" then
        zo_callLater(function() CheckReturnArrival(run) end, 5000)
    end
end

local function StartStagingTravel(run)
    if not run then return end
    if IsPlayerInCombat() then
        run.stage = "waiting-combat"
        run.houseChecks = 0
        UpdateStatusWindow(run, GetString(EZO_INSTANCE_RESET_STAGE_WAITING_COMBAT), 3)
        EmitReport("waiting-for-combat-end", run)
        return false
    end
    run.stage = "traveling-home"
    run.houseChecks = 0
    UpdateStatusWindow(run, GetStagingTravelText(run), 3)
    if not TravelToDestination(run.destination) then
        return InterruptRun(
            run,
            "staging-travel-unavailable",
            GetStagingNotReachedText(run),
            "traveling-home"
        )
    end

    if type(zo_callLater) == "function" then
        zo_callLater(function() CheckStagingArrival(run) end, 6000)
    end
    return false
end

local function WaitForDisbandThenTravel(run)
    if not run then return end
    run.disbandChecks = (run.disbandChecks or 0) + 1

    local stillGrouped = type(IsUnitGrouped) == "function" and IsUnitGrouped("player")
    if not stillGrouped then
        run.internalDisbandConfirmed = true
        run.internalDisbandExpected = false
        EmitReport("disband-confirmed", run, {
            "disband.checks=" .. tostring(run.disbandChecks or 0),
            "disband.result=confirmed",
        })
        StartStagingTravel(run)
        return
    end
    if run.disbandChecks >= 8 or type(zo_callLater) ~= "function" then
        EmitReport("disband-not-confirmed", run, {
            "disband.checks=" .. tostring(run.disbandChecks or 0),
            "disband.result=not-confirmed",
        })
        InterruptRun(
            run,
            "disband-not-confirmed",
            GetString(EZO_INSTANCE_RESET_STAGE_DISBAND_NOT_CONFIRMED),
            "disbanding"
        )
        return
    end

    zo_callLater(function()
        if activeRun and activeRun.id == run.id and run.stage == "disbanding" then
            WaitForDisbandThenTravel(run)
        end
    end, 1000)
end

local function StartWaitAtStaging(run)
    if not run then return end
    run.stage = "waiting"
    local settings = GetSettings()
    local waitMs = ClampNumber(settings.waitSeconds, DEFAULT_WAIT_SECONDS, 5, 300) * 1000
    run.waitEndsAtMs = GetNowMilliseconds() + waitMs
    EmitReport("waiting-at-staging", run)
    UpdateStatusWindow(run, GetStagingWaitText(run), 4)
    if type(zo_callLater) == "function" then
        zo_callLater(function()
            if activeRun and activeRun.id == run.id then
                if IsStagingDestinationReached(run) then
                    ReturnToInstance(run)
                else
                    InterruptRun(
                        run,
                        "staging-destination-left",
                        GetStagingNotReachedText(run),
                        "traveling-home"
                    )
                end
            end
        end, waitMs)
    elseif IsStagingDestinationReached(run) then
        ReturnToInstance(run)
    else
        InterruptRun(
            run,
            "staging-destination-left",
            GetStagingNotReachedText(run),
            "traveling-home"
        )
    end
end

function CheckStagingArrival(run)
    if not activeRun or activeRun.id ~= run.id or run.stage ~= "traveling-home" then
        return
    end

    if IsStagingDestinationReached(run) then
        StartWaitAtStaging(run)
        return
    end

    run.houseChecks = (run.houseChecks or 0) + 1
    if run.houseChecks >= MAX_HOUSE_CHECKS then
        EmitReport("staging-not-confirmed", run)
        InterruptRun(
            run,
            "staging-destination-not-reached",
            GetStagingNotReachedText(run),
            "traveling-home"
        )
        return
    end

    if type(zo_callLater) == "function" then
        zo_callLater(function() CheckStagingArrival(run) end, 5000)
    end
end

OnPlayerActivated = function()
    local run = activeRun or statusRun
    if not run then return end
    if CheckRetainedSessionLocationState(run, "player-activated") then return end
    if not activeRun then return end
    if activeRun.stage == "waiting-combat" then
        if not IsPlayerInCombat() then
            StartStagingTravel(activeRun)
        end
    elseif activeRun.stage == "traveling-home" then
        if IsStagingDestinationReached(activeRun) then
            StartWaitAtStaging(activeRun)
        end
    elseif activeRun.stage == "returning" and IsAtTargetInstance(activeRun) then
        ContinueAfterConfirmedReturn(activeRun)
    end
end

local function RegisterRunEvents()
    if type(EVENT_MANAGER) ~= "table" then
        return
    end
    if EVENT_PLAYER_ACTIVATED ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    end
    if EVENT_RAID_TRIAL_STARTED ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_RAID_TRIAL_STARTED, OnRaidTrialStarted)
    end
    if EVENT_PLAYER_COMBAT_STATE ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_COMBAT_STATE, OnPlayerCombatState)
    end
    if EVENT_JUMP_FAILED ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_JUMP_FAILED, OnJumpFailed)
    end
    if EVENT_PREPARE_FOR_JUMP ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PREPARE_FOR_JUMP, OnPrepareForJump)
    end
    if EVENT_GROUP_INVITE_RESPONSE ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_INVITE_RESPONSE, OnGroupInviteResponse)
    end
    if EVENT_GROUP_MEMBER_JOINED ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_MEMBER_JOINED, OnGroupMemberJoined)
    end
    if EVENT_GROUP_MEMBER_LEFT ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_MEMBER_LEFT, OnGroupMemberLeft)
    end
    if EVENT_GROUP_UPDATE ~= nil then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GROUP_UPDATE, OnGroupUpdate)
    end
end

local function FindMemberStateByName(run, characterName, displayName)
    if not run then return nil end
    local states = EnsureMemberStates(run)
    characterName = tostring(characterName or "")
    displayName = tostring(displayName or "")
    if displayName ~= "" and states[displayName] then
        return states[displayName]
    end
    if characterName ~= "" and states[characterName] then
        return states[characterName]
    end
    return nil
end

local function GetInviteResponseStatus(response)
    if response == GROUP_INVITE_RESPONSE_ACCEPTED then
        return "accepted"
    elseif response == GROUP_INVITE_RESPONSE_INVITED then
        return "invited"
    elseif response == GROUP_INVITE_RESPONSE_DECLINED then
        return "declined"
    elseif response == GROUP_INVITE_RESPONSE_IGNORED then
        return "ignored"
    end
    return "error"
end

OnGroupInviteResponse = function(_, inviterName, response, inviterDisplayName)
    local run = activeRun or statusRun
    if not run then return end
    local state = FindMemberStateByName(run, inviterName, inviterDisplayName)
    if state then
        state.inviteResponses = (tonumber(state.inviteResponses) or 0) + 1
        state.lastResponse = response
        state.responseStatus = GetInviteResponseStatus(response)
        state.status = state.responseStatus
        UpdateStatusWindow(run)
    end
    EmitReport("group-invite-response", run, {
        "event.inviterName=" .. tostring(inviterName or ""),
        "event.inviterDisplayName=" .. tostring(inviterDisplayName or ""),
        "event.response=" .. tostring(response or ""),
        "event.memberMatched=" .. tostring(state ~= nil),
    })
end

OnGroupMemberJoined = function(_, memberCharacterName, memberDisplayName, isLocalPlayer)
    local run = activeRun or statusRun
    if not run then return end
    local state = FindMemberStateByName(run, memberCharacterName, memberDisplayName)
    if state then
        state.responseStatus = nil
        state.status = "joined"
        state.joinedAfterReset = run.returnConfirmed == true or state.joinedAfterReset == true
        state.excludeFromInvites = nil
        state.excludedStatus = nil
        state.leaveReason = nil
    end
    CheckRetainedSessionGroupState(run, "group-member-joined")
    EmitReport("group-member-joined", run, {
        "event.memberCharacterName=" .. tostring(memberCharacterName or ""),
        "event.memberDisplayName=" .. tostring(memberDisplayName or ""),
        "event.isLocalPlayer=" .. tostring(isLocalPlayer == true),
        "event.memberMatched=" .. tostring(state ~= nil),
    })
    UpdateStatusWindow(run)
    if not activeRun and run.stage == "waiting-members" and #GetPendingNames(run) == 0 then
        CompleteRun(run, false)
    end
end

OnGroupMemberLeft = function(_, memberCharacterName, reason, isLocalPlayer, isLeader, memberDisplayName, actionRequiredVote)
    local run = activeRun or statusRun
    if not run then return end
    local internalDisband = IsInternalDisbandPending(run)
    local state = nil
    if isLocalPlayer ~= true and not internalDisband then
        state = FindMemberStateByName(run, memberCharacterName, memberDisplayName)
        if state then
            state.responseStatus = nil
            state.excludeFromInvites = true
            state.leaveReason = reason
            state.excludedStatus = GROUP_LEAVE_REASON_KICKED ~= nil
                and reason == GROUP_LEAVE_REASON_KICKED
                and "kicked"
                or "left"
            state.status = state.excludedStatus
        end
    end

    EmitReport("group-member-left", run, {
        "event.memberCharacterName=" .. tostring(memberCharacterName or ""),
        "event.memberDisplayName=" .. tostring(memberDisplayName or ""),
        "event.reason=" .. tostring(reason or ""),
        "event.isLocalPlayer=" .. tostring(isLocalPlayer == true),
        "event.isLeader=" .. tostring(isLeader == true),
        "event.actionRequiredVote=" .. tostring(actionRequiredVote == true),
        "event.expectedInternalDisband=" .. tostring(internalDisband),
        "event.memberMatched=" .. tostring(state ~= nil),
        "event.excludedFromRetries=" .. tostring(state and state.excludeFromInvites == true or false),
    })

    if isLocalPlayer == true then
        if internalDisband then
            return
        end
        ClearResetSession(run, "local-player-left-group:" .. tostring(reason or ""))
        return
    end
    if internalDisband then
        return
    end

    UpdateStatusWindow(run)
    if not activeRun and run.stage == "waiting-members" and #GetPendingNames(run) == 0 then
        CompleteRun(run, false)
    end
end

OnGroupUpdate = function()
    local run = activeRun or statusRun
    if not run then return end
    if CheckRetainedSessionGroupState(run, "group-update") then return end
    local currentNames = GetCurrentGroupDisplayNames()
    local sortedCurrentNames = {}
    for displayName in pairs(currentNames) do
        sortedCurrentNames[#sortedCurrentNames + 1] = displayName
    end
    table.sort(sortedCurrentNames)
    local compositionSignature = table.concat(sortedCurrentNames, "|")
    if run.lastGroupCompositionSignature == compositionSignature then
        return
    end
    run.lastGroupCompositionSignature = compositionSignature
    local additional = GetAdditionalNames(run, currentNames)
    SyncMemberStates(run, currentNames)
    EmitReport("group-update", run, {
        "current.captured=" .. tostring(GetCurrentCapturedCount(run, currentNames)),
        "current.additional=" .. tostring(#additional),
        "current.additionalNames=" .. table.concat(additional, ","),
    })
    UpdateStatusWindow(run)
end

OnPlayerCombatState = function(_, inCombat)
    local run = activeRun
    if not run or run.stage ~= "waiting-combat" or inCombat == true then
        return
    end
    EmitReport("combat-ended", run)
    StartStagingTravel(run)
end

OnPrepareForJump = function(_, zoneName)
    local run = activeRun
    if not run or run.stage ~= "returning" then return end
    run.returnTravelPrepared = true
    EmitReport("return-jump-prepared", run, {
        "event.zoneName=" .. tostring(zoneName or ""),
    })
end

OnJumpFailed = function(_, reason)
    local run = activeRun
    if not run or (run.stage ~= "traveling-home" and run.stage ~= "returning") then
        return
    end
    local resumeStage = run.stage
    run.lastJumpResult = reason
    EmitReport("jump-failed", run, {
        "event.jumpResult=" .. tostring(reason or ""),
        "resume.stage=" .. tostring(resumeStage),
    })
    InterruptRun(run, "jump-failed", GetString(EZO_INSTANCE_RESET_STAGE_TRAVEL_FAILED), resumeStage)
end

CheckTrialEntryCompletion = function(run, source)
    if not run or run.returnConfirmed ~= true then
        return false
    end
    if tostring(run.targetTrialKey or "") == "" or not IsAtTargetInstance(run) then
        return false
    end
    local trialStarted = run.trialStartedObserved == true
    if type(IsRaidInProgress) == "function" then
        local ok, inProgress = SafeCall(IsRaidInProgress)
        if ok and inProgress == true then
            trialStarted = true
            run.trialStartedObserved = true
        end
    end
    if not trialStarted then return false end

    if type(IsPlayerInRaidStagingArea) == "function" then
        local ok, inStagingArea = SafeCall(IsPlayerInRaidStagingArea)
        if ok and inStagingArea == true then
            if run.trialEntryDeferredReported ~= true then
                run.trialEntryDeferredReported = true
                EmitReport("trial-started-leader-still-staging", run, {
                    "source=" .. tostring(source or ""),
                })
            end
            return false
        end
    end

    if activeRun and activeRun.id == run.id then activeRun = nil end
    if statusRun and statusRun.id == run.id then statusRun = nil end
    run.stage = "trial-entered"
    run.waitEndsAtMs = nil
    run.resumeStage = nil
    run.resumeHintText = nil
    run.interruptionReason = nil
    PublishRunActivityState(run, { stage = "complete", result = "complete" }, true)
    EmitReport("trial-entered", run, {
        "source=" .. tostring(source or ""),
    })
    StopStatusTicker()
    UnregisterRunEvents()
    HideStatusWindow(0, run)
    return true
end

OnRaidTrialStarted = function(_, trialName)
    local run = activeRun or statusRun
    if not run then return end
    if run.returnConfirmed ~= true then
        EmitReport("raid-trial-start-ignored-before-return", run, {
            "event.trialName=" .. tostring(trialName or ""),
        })
        return
    end
    run.trialStartedObserved = true
    EmitReport("raid-trial-started", run, {
        "event.trialName=" .. tostring(trialName or ""),
    })
    CheckTrialEntryCompletion(run, "raid-trial-started")
end

function MOD.ResumeConfirmed()
    if not IsResetEnabled() then
        Print(GetString(EZO_MSG_INSTANCE_RESET_DISABLED))
        return false
    end
    if activeRun then
        Print(GetString(EZO_MSG_INSTANCE_RESET_ALREADY_RUNNING))
        return false
    end
    local run = GetResumableRun()
    if not run then
        Print(GetString(EZO_MSG_INSTANCE_RESET_RESUME_UNAVAILABLE))
        return false
    end

    local resumeStage = run.resumeStage or "inviting"
    local resumedAtMs = GetNowMilliseconds()
    if tonumber(run.interruptedAtMs) and tonumber(run.startedAtMs) then
        run.startedAtMs = run.startedAtMs + math.max(0, resumedAtMs - run.interruptedAtMs)
    end
    run.interruptedAtMs = nil
    run.resumeStage = nil
    run.resumeHintText = nil
    run.interruptionReason = nil
    run.phaseStartedAtMs = resumedAtMs
    run.waitEndsAtMs = nil
    activeRun = run
    statusRun = run
    StartStatusTicker()
    RegisterRunEvents()
    EmitReport("resumed", run, {
        "resume.stage=" .. tostring(resumeStage),
    })
    if resumeStage == "disbanding" then
        run.stage = "disbanding"
        run.disbandChecks = 0
        run.internalDisbandConfirmed = false
        UpdateStatusWindow(run, GetString(EZO_INSTANCE_RESET_STAGE_DISBANDING), 2)
        local stillGrouped = type(IsUnitGrouped) == "function" and IsUnitGrouped("player")
        if not stillGrouped then
            run.internalDisbandConfirmed = true
            run.internalDisbandExpected = false
            StartStagingTravel(run)
            return false
        end
        local tools = EZO and EZO.RaidLeaderTools
        local isLeader = tools
            and type(tools.IsPlayerGroupLeader) == "function"
            and tools.IsPlayerGroupLeader()
        if not isLeader or type(GroupDisband) ~= "function" then
            return InterruptRun(
                run,
                "disband-resume-unavailable",
                GetString(EZO_INSTANCE_RESET_STAGE_DISBAND_NOT_CONFIRMED),
                "disbanding"
            )
        end
        EmitReport("disband-requested", run, {
            "disband.result=requesting-resume",
        })
        run.internalDisbandExpected = true
        local ok = SafeCall(GroupDisband)
        if not ok then
            return InterruptRun(
                run,
                "disband-call-failed",
                GetString(EZO_INSTANCE_RESET_STAGE_DISBAND_NOT_CONFIRMED),
                "disbanding"
            )
        end
        WaitForDisbandThenTravel(run)
        return false
    elseif resumeStage == "traveling-home" or resumeStage == "waiting-combat" then
        if IsStagingDestinationReached(run) then
            StartWaitAtStaging(run)
        else
            StartStagingTravel(run)
        end
        return false
    elseif resumeStage == "returning" then
        if IsAtTargetInstance(run) then
            ContinueAfterConfirmedReturn(run)
        else
            ReturnToInstance(run)
        end
        return false
    elseif resumeStage == "inviting" then
        run.stage = "inviting"
        run.inviteCycleAttempt = 0
        ScheduleInvites(run)
        return false
    end

    return InterruptRun(
        run,
        "resume-stage-invalid",
        GetString(EZO_INSTANCE_RESET_STAGE_RESUME_INVALID),
        "traveling-home"
    )
end

local function GetCurrentSupportedTrial()
    local tools = EZO and EZO.RaidLeaderTools
    if not (tools and type(tools.BuildInstanceSnapshot) == "function") then
        return nil, nil
    end
    local ok, instance = SafeCall(tools.BuildInstanceSnapshot)
    if not ok or type(instance) ~= "table" then
        return nil, instance
    end
    return DetectTrialFromZone(instance.zoneName), instance
end

local function HasFreshResetContext()
    if not (EZO.RaidLeaderTools and type(EZO.RaidLeaderTools.IsPlayerGroupLeader) == "function") then
        return false
    end
    local trial = GetCurrentSupportedTrial()
    return trial ~= nil
        and EZO.RaidLeaderTools.IsPlayerGroupLeader()
        and type(IsUnitGrouped) == "function"
        and IsUnitGrouped("player")
        and type(GroupDisband) == "function"
end

local function IsReplaceablePostReturnRun(run)
    if not run or run.returnConfirmed ~= true then
        return false
    end
    local stage = tostring(run.stage or "")
    local isPostReturn = tonumber(run.phaseIndex) == 6
        or stage == "inviting"
        or stage == "waiting-members"
        or stage == "waiting-trial-entry"
    return isPostReturn and #GetPendingNames(run) == 0
end

local function GetReplaceableRunForFreshStart()
    local run = activeRun or statusRun
    if IsReplaceablePostReturnRun(run) and HasFreshResetContext() then
        return run
    end
    return nil
end

function MOD.HasSession()
    return activeRun ~= nil or statusRun ~= nil
end

function MOD.GetPublicActivityState()
    local run = activeRun or statusRun
    return BuildPublicActivityState(run)
end

function MOD.CancelConfirmed()
    local run = activeRun or statusRun
    if not run then
        return false
    end
    return ClearResetSession(run, "user-cancelled")
end

function MOD.Cancel()
    if not MOD.HasSession() then
        return false
    end
    EmitAutomaticGroupStatus("cancel-instance-reset")
    local tools = EZO and EZO.RaidLeaderTools
    if tools and type(tools.ConfirmDangerousAction) == "function" then
        return tools.ConfirmDangerousAction(
            GetString(EZO_CONFIRM_INSTANCE_RESET_CANCEL_TITLE),
            GetString(EZO_CONFIRM_INSTANCE_RESET_CANCEL_TEXT),
            GetString(EZO_CONFIRM_INSTANCE_RESET_CANCEL_CONFIRM),
            MOD.CancelConfirmed,
            "cancel-instance-reset"
        )
    end
    return MOD.CancelConfirmed()
end

function MOD.CanStart()
    if not IsResetEnabled() then
        return false
    end
    if GetReplaceableRunForFreshStart() then
        return true
    end
    if activeRun then
        return false
    end
    if GetResumableRun() then
        return true
    end
    return HasFreshResetContext()
end

function MOD.StartConfirmed()
    if not IsResetEnabled() then
        Print(GetString(EZO_MSG_INSTANCE_RESET_DISABLED))
        return false
    end
    local replaceableRun = GetReplaceableRunForFreshStart()
    if activeRun and not replaceableRun then
        EmitReport("start-rejected", activeRun, {
            "start.result=already-running",
        })
        Print(GetString(EZO_MSG_INSTANCE_RESET_ALREADY_RUNNING))
        return false
    end
    if not HasFreshResetContext() then
        EmitReport("start-rejected", nil, {
            "start.result=fresh-context-unavailable",
        })
        Print(GetString(EZO_MSG_INSTANCE_RESET_UNAVAILABLE))
        return false
    end
    if type(DoesGroupModificationRequireVote) == "function" then
        local ok, requiresVote = SafeCall(DoesGroupModificationRequireVote)
        if ok and requiresVote == true then
            EmitReport("start-rejected", nil, {
                "start.result=group-vote-required",
            })
            Print(GetString(EZO_MSG_GROUP_DISBAND_UNAVAILABLE))
            return false
        end
    end

    local destination = GetDestination()
    if not CanTravelToDestination(destination) then
        EmitReport("start-rejected", nil, {
            "start.result=destination-unavailable",
            "destination=" .. tostring(destination or ""),
        })
        Print(GetString(EZO_MSG_INSTANCE_RESET_DESTINATION_UNAVAILABLE))
        return false
    end

    local snapshot = EZO.RaidLeaderTools.BuildResetSnapshot()
    local snapshotGroup = snapshot.group or {}
    if snapshotGroup.isGrouped ~= true or snapshotGroup.isLeader ~= true then
        EmitReport("start-rejected", nil, {
            "start.result=group-changed-before-snapshot",
        })
        Print(GetString(EZO_MSG_INSTANCE_RESET_UNAVAILABLE))
        return false
    end
    local instance = snapshot.instance or {}
    local trial = DetectTrialFromZone(instance.zoneName)
    if not trial then
        EmitReport("start-rejected", nil, {
            "start.result=unsupported-target",
            "instance.zoneName=" .. tostring(instance.zoneName or ""),
        })
        Print(GetString(EZO_MSG_INSTANCE_RESET_UNSUPPORTED_TARGET))
        return false
    end
    local run = {
        id = tostring(type(GetFrameTimeMilliseconds) == "function" and GetFrameTimeMilliseconds() or math.random(1000000)),
        stage = "starting",
        destination = destination,
        snapshot = snapshot,
        targetTrialKey = trial and tostring(trial.key or "") or "",
        targetTrialName = trial and tostring(trial.name or "") or "",
        targetZoneIndex = tonumber(instance.zoneIndex),
        inviteAttempt = 0,
        inviteCycleAttempt = 0,
        invitedTotal = 0,
        houseChecks = 0,
        phaseIndex = 1,
        startedAtMs = GetNowMilliseconds(),
        phaseStartedAtMs = GetNowMilliseconds(),
        waitEndsAtMs = nil,
        interruptionCount = 0,
        internalDisbandExpected = false,
        internalDisbandConfirmed = false,
        groupReformedObserved = false,
    }

    local snapshotVerified, removedBeforeDisband = VerifyInitialSnapshotMembers(run)
    if not snapshotVerified then
        EmitReport("start-rejected", run, {
            "start.result=snapshot-verification-failed",
            "snapshot.removedBeforeDisband=" .. tostring(removedBeforeDisband or 0),
        })
        Print(GetString(EZO_MSG_INSTANCE_RESET_UNAVAILABLE))
        return false
    end
    run.snapshot.removedBeforeDisband = tonumber(removedBeforeDisband) or 0

    if replaceableRun then
        local replacementSnapshotVerified, removedBeforeReplacement = VerifyInitialSnapshotMembers(run)
        if not replacementSnapshotVerified then
            EmitReport("start-rejected", run, {
                "start.result=replacement-snapshot-verification-failed",
                "snapshot.removedBeforeReplacement=" .. tostring(removedBeforeReplacement or 0),
            })
            Print(GetString(EZO_MSG_INSTANCE_RESET_UNAVAILABLE))
            return false
        end
        run.snapshot.removedBeforeDisband = (tonumber(run.snapshot.removedBeforeDisband) or 0)
            + (tonumber(removedBeforeReplacement) or 0)
        EmitReport("new-reset-superseding-previous", replaceableRun, {
            "start.previousStage=" .. tostring(replaceableRun.stage or ""),
            "start.previousPhase=" .. tostring(replaceableRun.phaseIndex or ""),
        })
        ClearResetSession(replaceableRun, "new-reset-replaces-post-return")
    end

    activeRun = run
    statusRun = run
    StartStatusTicker()
    RegisterRunEvents()

    EmitReport("started", run, {
        "snapshot.verified=true",
        "snapshot.removedBeforeDisband=" .. tostring(removedBeforeDisband or 0),
    })
    UpdateStatusWindow(run, GetString(EZO_INSTANCE_RESET_STAGE_STARTING), 1)

    local finalSnapshotVerified, removedAtDisband = VerifyInitialSnapshotMembers(run)
    if not finalSnapshotVerified then
        EmitReport("start-rejected", run, {
            "start.result=group-changed-before-disband",
        })
        ClearResetSession(run, "group-changed-before-disband")
        Print(GetString(EZO_MSG_INSTANCE_RESET_UNAVAILABLE))
        return false
    end
    if (tonumber(removedAtDisband) or 0) > 0 then
        run.snapshot.removedBeforeDisband = (tonumber(run.snapshot.removedBeforeDisband) or 0)
            + tonumber(removedAtDisband)
        EmitReport("snapshot-updated-before-disband", run, {
            "snapshot.removedAtDisband=" .. tostring(removedAtDisband),
            "snapshot.finalGroupSize=" .. tostring(run.snapshot.group and run.snapshot.group.size or 0),
        })
        UpdateStatusWindow(run)
    end

    local activitySession = EZO and EZO.RaidLeaderActivitySession
    if activitySession and type(activitySession.SaveResetSnapshot) == "function" then
        SafeCall(activitySession.SaveResetSnapshot, run.snapshot, run.targetTrialKey, run.targetTrialName)
    end

    EmitReport("disband-requested", run, {
        "disband.result=requesting",
    })
    run.stage = "disbanding"
    run.internalDisbandExpected = true
    run.internalDisbandConfirmed = false
    UpdateStatusWindow(run, GetString(EZO_INSTANCE_RESET_STAGE_DISBANDING), 2)
    local disbandOk = SafeCall(GroupDisband)
    if not disbandOk then
        return InterruptRun(
            run,
            "disband-call-failed",
            GetString(EZO_INSTANCE_RESET_STAGE_DISBAND_NOT_CONFIRMED),
            "disbanding"
        )
    end
    WaitForDisbandThenTravel(run)
    return false
end

function MOD.Start()
    if not IsResetEnabled() then
        Print(GetString(EZO_MSG_INSTANCE_RESET_DISABLED))
        return false
    end
    local replaceableRun = GetReplaceableRunForFreshStart()
    if activeRun and not replaceableRun then
        Print(GetString(EZO_MSG_INSTANCE_RESET_ALREADY_RUNNING))
        return false
    end
    local resumableRun = not replaceableRun and GetResumableRun() or nil
    if resumableRun then
        EmitAutomaticGroupStatus("instance-reset-resume")
        local tools = EZO and EZO.RaidLeaderTools
        if tools and type(tools.ConfirmDangerousAction) == "function" then
            return tools.ConfirmDangerousAction(
                GetString(EZO_CONFIRM_INSTANCE_RESET_RESUME_TITLE),
                GetString(EZO_CONFIRM_INSTANCE_RESET_RESUME_TEXT),
                GetString(EZO_CONFIRM_INSTANCE_RESET_RESUME_CONFIRM),
                MOD.ResumeConfirmed,
                "instance-reset-resume"
            )
        end
        return MOD.ResumeConfirmed()
    end
    if not HasFreshResetContext() then
        Print(GetString(EZO_MSG_INSTANCE_RESET_UNAVAILABLE))
        return false
    end

    EmitAutomaticGroupStatus("instance-reset")
    local tools = EZO and EZO.RaidLeaderTools
    if tools and type(tools.ConfirmDangerousAction) == "function" then
        return tools.ConfirmDangerousAction(
            GetString(EZO_CONFIRM_INSTANCE_RESET_TITLE),
            GetString(EZO_CONFIRM_INSTANCE_RESET_TEXT),
            GetString(EZO_CONFIRM_INSTANCE_RESET_CONFIRM),
            MOD.StartConfirmed,
            "instance-reset"
        )
    end

    return MOD.StartConfirmed()
end

function MOD.GetDestinationChoices()
    return {
        GetString(EZO_OPTION_INSTANCE_RESET_DESTINATION_PRIMARY),
        GetString(EZO_OPTION_INSTANCE_RESET_DESTINATION_CRAFTING),
        GetString(EZO_OPTION_INSTANCE_RESET_DESTINATION_SECONDARY),
        GetString(EZO_MENU_LEAVE_INSTANCE),
    }, { "primary", "crafting", "secondary", "leave-instance" }
end

function MOD.IsStatusWindowUnlocked()
    return statusWindowUnlocked
end

function MOD.SetStatusWindowUnlocked(enabled)
    statusWindowUnlocked = enabled == true
    local realRun = activeRun or statusRun
    local preview = EZO and EZO.StatusPanelPreview
    local standalonePreviewClosed = preview
        and type(preview.Hide) == "function"
        and preview.Hide(true) == true
        or false
    local win = EnsureStatusWindow()
    ApplyStatusWindowInteraction()

    if EZO and type(EZO.DebugPrint) == "function" then
        EZO.DebugPrint(string.format(
            "Reset status placement mode: unlocked=%s standalonePreviewClosed=%s activeRun=%s statusRun=%s",
            tostring(statusWindowUnlocked),
            tostring(standalonePreviewClosed),
            tostring(activeRun ~= nil),
            tostring(statusRun ~= nil)
        ))
    end

    if not win then
        return false
    end
    if statusWindowUnlocked and ApplyStatusWindowPlacementPreview() then
        return true
    end
    if realRun then
        UpdateStatusWindow(realRun)
    elseif not statusWindowUnlocked then
        statusPanel:SetHidden(true)
    end
    return MOD.IsStatusWindowUnlocked() == (enabled == true)
end

function MOD.HandleExternalDisbandConfirmed(source)
    local run = activeRun or statusRun
    if not run then return false end
    if IsInternalDisbandPending(run) then
        EmitReport("external-disband-notification-ignored", run, {
            "notification.source=" .. tostring(source or ""),
            "notification.reason=internal-reset-disband-active",
        })
        return false
    end
    return ClearResetSession(run, "external-disband:" .. tostring(source or "unknown"))
end

function MOD.GetSettings()
    return GetSettings()
end
