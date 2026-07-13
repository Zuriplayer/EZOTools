-- Diagnostico read-only para actividades de grupo/trial/dungeon.
-- No ejecuta acciones de grupo ni modifica estado del jugador.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.RaidLeaderStatus = EZO.RaidLeaderStatus or {}
local MOD = EZO.RaidLeaderStatus

local function YesNo(value)
    return value and "yes" or "no"
end

local function IsAutomaticReportEnabled()
    if not (EZO and type(EZO.IsDebugModeEnabled) == "function" and EZO.IsDebugModeEnabled()) then
        return false
    end
    local settings = EZO.sv and EZO.sv.groupActivities
    return not settings or settings.logGroupStatusOnAction ~= false
end

local function BuildSnapshot()
    local tools = EZO and EZO.RaidLeaderTools
    if tools and type(tools.BuildResetSnapshot) == "function" then
        local ok, snapshot = pcall(tools.BuildResetSnapshot)
        if ok and type(snapshot) == "table" then
            return snapshot
        end
    end
    return {
        group = { isGrouped = false, isLeader = false, size = 0, members = {} },
        instance = { inInstance = false, zoneName = "", difficultyName = "", canChangeDifficulty = false },
    }
end

local function BuildDebugLines(snapshot, actionKey)
    local group = snapshot.group or {}
    local instance = snapshot.instance or {}
    local lines = {
        "=== EZOTools group activity status ===",
        "action=" .. tostring(actionKey or ""),
        "group.isGrouped=" .. YesNo(group.isGrouped),
        "group.isLeader=" .. YesNo(group.isLeader),
        "group.size=" .. tostring(group.size or 0),
        "instance.inInstance=" .. YesNo(instance.inInstance),
        "instance.zoneIndex=" .. tostring(instance.zoneIndex or ""),
        "instance.zoneName=" .. tostring(instance.zoneName or ""),
        "instance.difficulty=" .. tostring(instance.difficulty or ""),
        "instance.difficultyName=" .. tostring(instance.difficultyName or ""),
        "instance.canChangeDifficulty=" .. YesNo(instance.canChangeDifficulty),
        "snapshot.createdAtMs=" .. tostring(snapshot.createdAtMs or ""),
    }

    if type(group.members) == "table" and #group.members > 0 then
        lines[#lines + 1] = "members:"
        for index, member in ipairs(group.members) do
            lines[#lines + 1] = string.format(
                "  [%d] tag=%s leader=%s display=%s character=%s",
                index,
                tostring(member.unitTag or ""),
                YesNo(member.isLeader),
                tostring(member.displayName or ""),
                tostring(member.characterName or ""))
        end
    else
        lines[#lines + 1] = "members: none"
    end

    lines[#lines + 1] = "======================================"
    return lines
end

function MOD.EmitForAction(actionKey)
    if not IsAutomaticReportEnabled() then
        return false
    end

    local snapshot = BuildSnapshot()
    if EZO and EZO.Debug and type(EZO.Debug.EmitReport) == "function" then
        EZO.Debug.EmitReport(GetString(EZO_DEBUG_GROUP_STATUS_TITLE), BuildDebugLines(snapshot, actionKey))
        return true
    end

    return false
end
