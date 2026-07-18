-- Persisted group activity template shared by raid-leader workflows.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.RaidLeaderActivitySession = EZO.RaidLeaderActivitySession or {}
local MOD = EZO.RaidLeaderActivitySession

local function Print(message)
    if EZO and type(EZO.Print) == "function" then
        EZO.Print(message)
    end
end

local function EmitAutomaticGroupStatus(actionKey)
    local status = EZO and EZO.RaidLeaderStatus
    if status and type(status.EmitForAction) == "function" then
        pcall(status.EmitForAction, actionKey)
    end
end

local function GetSavedVariables()
    EZO.sv = EZO.sv or {}
    EZO.sv.raidLeaderActivitySession = EZO.sv.raidLeaderActivitySession or {}
    return EZO.sv.raidLeaderActivitySession
end

local function CopyDisplayNames(members)
    local names = {}
    local seen = {}
    local playerName = type(GetDisplayName) == "function" and tostring(GetDisplayName() or "") or ""
    for _, member in ipairs(type(members) == "table" and members or {}) do
        local displayName = type(member) == "table"
            and tostring(member.displayName or "")
            or tostring(member or "")
        if displayName ~= "" and displayName ~= playerName and not seen[displayName] then
            seen[displayName] = true
            names[#names + 1] = displayName
        end
    end
    return names
end

local function EmitReport(stage, activity, extra)
    if not (EZO and EZO.Debug and type(EZO.Debug.EmitReport) == "function") then
        return
    end
    local lines = {
        "stage=" .. tostring(stage or ""),
        "trial.key=" .. tostring(activity and activity.trialKey or ""),
        "trial.name=" .. tostring(activity and activity.trialName or ""),
        "difficulty=" .. tostring(activity and activity.difficulty or ""),
        "members=" .. tostring(activity and type(activity.members) == "table" and #activity.members or 0),
    }
    if type(extra) == "table" then
        for _, line in ipairs(extra) do
            lines[#lines + 1] = tostring(line)
        end
    end
    EZO.Debug.EmitReport(GetString(EZO_DEBUG_LAST_GROUP_ACTIVITY_TITLE), lines, { level = "info" })
end

function MOD.SaveResetSnapshot(snapshot, trialKey, trialName)
    local group = type(snapshot) == "table" and snapshot.group or nil
    local instance = type(snapshot) == "table" and snapshot.instance or nil
    local members = CopyDisplayNames(group and group.members)
    trialKey = tostring(trialKey or "")
    if trialKey == "" or #members == 0 then
        return false
    end

    local activity = {
        schemaVersion = 1,
        trialKey = trialKey,
        trialName = tostring(trialName or ""),
        difficulty = tonumber(instance and instance.difficulty),
        zoneIndex = tonumber(instance and instance.zoneIndex),
        members = members,
    }
    GetSavedVariables().lastActivity = activity
    EmitReport("saved", activity)
    return true
end

function MOD.GetLastActivity()
    local activity = GetSavedVariables().lastActivity
    if type(activity) ~= "table"
        or tostring(activity.trialKey or "") == ""
        or type(activity.members) ~= "table"
        or #activity.members == 0 then
        return nil
    end
    return activity
end

function MOD.HasLastActivity()
    return MOD.GetLastActivity() ~= nil
end

function MOD.CanStartLastActivity()
    local activity = MOD.GetLastActivity()
    local tools = EZO and EZO.RaidLeaderTools
    if not activity or not tools
        or type(tools.InviteDisplayNames) ~= "function"
        or type(tools.TravelToTrialWithDifficulty) ~= "function"
        or type(GroupInviteByName) ~= "function" then
        return false
    end

    local reset = EZO and EZO.RaidLeaderReset
    if reset and type(reset.HasSession) == "function" and reset.HasSession() then
        return false
    end

    local grouped = type(IsUnitGrouped) == "function" and IsUnitGrouped("player")
    if grouped and type(tools.IsPlayerGroupLeader) == "function" and not tools.IsPlayerGroupLeader() then
        return false
    end
    return true
end

function MOD.StartLastActivityConfirmed()
    if not MOD.CanStartLastActivity() then
        Print(GetString(EZO_MSG_LAST_GROUP_ACTIVITY_UNAVAILABLE))
        return false
    end

    local activity = MOD.GetLastActivity()
    local tools = EZO.RaidLeaderTools
    local available, invited, errors = tools.InviteDisplayNames(activity.members)
    if not available then
        Print(GetString(EZO_MSG_LAST_GROUP_ACTIVITY_UNAVAILABLE))
        EmitReport("invite-unavailable", activity)
        return false
    end

    EmitReport("invites-requested", activity, {
        "invited=" .. tostring(invited or 0),
        "errors=" .. tostring(errors or 0),
    })
    return tools.TravelToTrialWithDifficulty(activity.trialKey, activity.difficulty, function(requested, reason)
        EmitReport("travel-result", activity, {
            "requested=" .. tostring(requested == true),
            "reason=" .. tostring(reason or ""),
        })
    end)
end

function MOD.StartLastActivity()
    if not MOD.CanStartLastActivity() then
        Print(GetString(EZO_MSG_LAST_GROUP_ACTIVITY_UNAVAILABLE))
        return false
    end

    local activity = MOD.GetLastActivity()
    local tools = EZO and EZO.RaidLeaderTools
    EmitAutomaticGroupStatus("start-last-group-activity")
    if tools and type(tools.ConfirmDangerousAction) == "function" then
        return tools.ConfirmDangerousAction(
            GetString(EZO_CONFIRM_LAST_GROUP_ACTIVITY_TITLE),
            zo_strformat(
                GetString(EZO_CONFIRM_LAST_GROUP_ACTIVITY_TEXT),
                tostring(activity.trialName or activity.trialKey),
                #activity.members
            ),
            GetString(EZO_CONFIRM_LAST_GROUP_ACTIVITY_CONFIRM),
            MOD.StartLastActivityConfirmed,
            "start-last-group-activity"
        )
    end
    return MOD.StartLastActivityConfirmed()
end
