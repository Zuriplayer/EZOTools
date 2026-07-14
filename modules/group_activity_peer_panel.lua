-- Member-facing group activity status panel.
-- It is local-only for now; future EZOCore group transport can feed it with
-- leader state without exposing the full roster.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.GroupActivityPeerPanel = EZO.GroupActivityPeerPanel or {}
local MOD = EZO.GroupActivityPeerPanel

local EVENT_NAMESPACE = "EZOTools_GroupActivityPeerPanel"
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

    local integration = EZO and EZO.EZOCoreIntegration
    if not (leaderUnitTag and integration and type(integration.GetPeerCompatibility) == "function") then
        return "unknown"
    end
    return integration.GetPeerCompatibility(leaderUnitTag, "ezotools", "group.activityState.provider", 1)
end

local function GetCompatibilityText(compatibility)
    if compatibility == "compatible" then
        return GetString(EZO_GROUP_ACTIVITY_PEER_COMPATIBLE), "success", "OK"
    elseif compatibility == "incompatible" then
        return GetString(EZO_GROUP_ACTIVITY_PEER_INCOMPATIBLE), "error", "NO"
    end
    return GetString(EZO_GROUP_ACTIVITY_PEER_UNKNOWN), "muted", "?"
end

local function BuildPlayerRow(snapshot)
    local group = snapshot.group or {}
    local instance = snapshot.instance or {}
    local inInstance = instance.inInstance == true
    local location = inInstance
        and (tostring(instance.zoneName or "") ~= "" and tostring(instance.zoneName) or GetString(EZO_GROUP_ACTIVITY_PEER_LOCATION_INSTANCE))
        or GetString(EZO_GROUP_ACTIVITY_PEER_LOCATION_NOT_INSTANCE)

    return {
        id = "player",
        name = GetPlayerDisplayName(),
        status = group.isLeader and GetString(EZO_GROUP_ACTIVITY_PEER_ROLE_LEADER) or GetString(EZO_GROUP_ACTIVITY_PEER_ROLE_MEMBER),
        tone = inInstance and "info" or "muted",
        iconType = inInstance and "pending" or "success",
        location = location,
        locationTone = inInstance and "info" or "muted",
    }
end

local function BuildModel()
    local snapshot = BuildSnapshot()
    local group = snapshot.group or {}
    local instance = snapshot.instance or {}
    local leaderUnitTag = currentLeaderUnitTag or GetLeaderUnitTag(snapshot)
    local transportStatus = GetTransportStatus()
    local transportText, transportTone, transportShort = GetTransportText(transportStatus)
    local _, compatibilityTone, compatibilityShort = GetCompatibilityText(GetLeaderCompatibility(leaderUnitTag))
    local leaderState = currentLeaderState

    local target = leaderState and tostring(leaderState.targetName or "") or ""
    if target == "" then
        target = GetString(EZO_GROUP_ACTIVITY_PEER_PANEL_TITLE)
    end

    local mode = leaderState and tostring(leaderState.modeName or "") or ""
    if mode == "" then
        mode = tostring(instance.difficultyName or "")
    end
    if mode == "" then
        mode = GetString(EZO_INSTANCE_RESET_STATUS_TARGET_UNKNOWN)
    end

    local phaseIndex = tonumber(leaderState and leaderState.phaseIndex)
    local totalPhases = tonumber(leaderState and leaderState.totalPhases) or 1
    local hasLeaderState = type(leaderState) == "table"
    local progressValue = hasLeaderState and (phaseIndex or 0) or 0
    local progressMax = hasLeaderState and math.max(1, totalPhases) or 1
    local phaseText = hasLeaderState
        and (leaderState.resetComplete and GetString(EZO_INSTANCE_RESET_STATUS_COMPLETE)
            or (phaseIndex and zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_PHASE_SHORT), phaseIndex, progressMax)
                or GetString(EZO_GROUP_ACTIVITY_PEER_PHASE_REMOTE)))
        or GetString(EZO_GROUP_ACTIVITY_PEER_PHASE_LOCAL)
    local statusText = hasLeaderState
        and tostring(leaderState.statusText or GetString(EZO_GROUP_ACTIVITY_PEER_STATUS_REMOTE))
        or GetString(EZO_GROUP_ACTIVITY_PEER_STATUS_WAITING)

    local alert = nil
    if simulationActive then
        alert = {
            text = GetString(EZO_GROUP_ACTIVITY_PEER_SIMULATION_ACTIVE),
            tone = "info",
        }
    elseif not hasLeaderState then
        alert = {
            text = transportText,
            tone = transportTone,
        }
    end

    return {
        width = PANEL_WIDTH,
        density = "comfortable",
        title = target,
        phaseText = phaseText,
        contextText = zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_ACTIVITY), GetString(EZO_MENU_GROUP_ACTIVITIES_TITLE), mode),
        totalTimeText = "",
        progress = {
            min = 0,
            max = progressMax,
            value = progressValue,
            text = hasLeaderState
                and zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_PROGRESS), progressValue, progressMax)
                or GetString(EZO_GROUP_ACTIVITY_PEER_PROGRESS_WAITING),
        },
        statusText = statusText,
        statusTimeText = "",
        alert = alert,
        metrics = {
            {
                value = group.size or 0,
                label = GetString(EZO_GROUP_ACTIVITY_PEER_METRIC_GROUP),
                tone = group.isGrouped and "normal" or "muted",
            },
            {
                value = transportShort,
                label = GetString(EZO_GROUP_ACTIVITY_PEER_METRIC_EZOCORE),
                tone = transportTone,
            },
            {
                value = compatibilityShort,
                label = GetString(EZO_GROUP_ACTIVITY_PEER_METRIC_LEADER),
                tone = compatibilityTone,
            },
        },
        rowsTitle = GetString(EZO_GROUP_ACTIVITY_PEER_ROWS_TITLE),
        rows = {
            BuildPlayerRow(snapshot),
        },
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
    return IsGrouped() and not IsGroupLeader()
end

function MOD.Show()
    local win = EnsurePanel()
    if not win then
        return false
    end

    local integration = EZO and EZO.EZOCoreIntegration
    if not simulationActive and integration and type(integration.RequestGroupPresence) == "function" then
        pcall(integration.RequestGroupPresence)
    end

    win:SetModel(BuildModel())
    win:SetInteractionActive(true)
    win:SetHidden(false)
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
        schemaVersion = 1,
        sourceAddon = "ezotools",
        activityType = "instanceReset",
        runId = "debug-local-simulation",
        targetKey = "aetherian_archive",
        targetName = "Aetherian Archive",
        modeName = GetSimulatedModeName(),
        stage = "waiting-members",
        statusText = GetString(EZO_INSTANCE_RESET_STAGE_WAITING_MEMBERS),
        phaseIndex = 6,
        totalPhases = 6,
        resetComplete = false,
        capturedMembers = 11,
        pendingMembers = 3,
        startedAtMs = 0,
        updatedAtMs = 0,
    }

    if mode == "complete" or mode == "done" then
        state.stage = "waiting-trial-entry"
        state.statusText = GetString(EZO_INSTANCE_RESET_STAGE_READY_FOR_ENTRY)
        state.resetComplete = true
        state.pendingMembers = 0
    elseif mode == "returning" then
        state.stage = "returning"
        state.statusText = GetString(EZO_INSTANCE_RESET_STAGE_RETURNING)
        state.phaseIndex = 5
        state.pendingMembers = 8
    elseif mode == "staging" then
        state.stage = "waiting-home"
        state.statusText = GetString(EZO_INSTANCE_RESET_STAGE_WAITING_HOME)
        state.phaseIndex = 3
        state.pendingMembers = 10
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
    currentLeaderState = type(state) == "table" and state or nil
    MOD.Refresh()
    return currentLeaderState ~= nil
end

function MOD.ClearLeaderActivityState()
    currentLeaderState = nil
    currentLeaderUnitTag = nil
    simulationActive = false
    simulatedSnapshot = nil
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
