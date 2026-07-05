-- Herramientas experimentales para lider de grupo/raid.
-- Centraliza capturas de grupo, estado de instancia y acciones preparatorias.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.RaidLeaderTools = EZO.RaidLeaderTools or {}
local MOD = EZO.RaidLeaderTools

local function Print(message)
    if EZO and type(EZO.Print) == "function" then
        EZO.Print(message)
    elseif type(d) == "function" then
        d(tostring(message))
    end
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

function MOD.IsPlayerGroupLeader()
    return type(IsUnitGrouped) == "function"
        and type(IsUnitGroupLeader) == "function"
        and IsUnitGrouped("player")
        and IsUnitGroupLeader("player")
end

local function GetEffectiveDungeonDifficulty()
    if type(ZO_GetEffectiveDungeonDifficulty) == "function" then
        local ok, difficulty = SafeCall(ZO_GetEffectiveDungeonDifficulty)
        if ok then
            return difficulty
        end
    end

    if type(IsUnitGrouped) == "function"
        and IsUnitGrouped("player")
        and type(IsGroupUsingVeteranDifficulty) == "function" then
        return IsGroupUsingVeteranDifficulty()
            and DUNGEON_DIFFICULTY_VETERAN
            or DUNGEON_DIFFICULTY_NORMAL
    end

    if type(IsUnitUsingVeteranDifficulty) == "function" then
        return IsUnitUsingVeteranDifficulty("player")
            and DUNGEON_DIFFICULTY_VETERAN
            or DUNGEON_DIFFICULTY_NORMAL
    end

    return nil
end

local function GetDungeonDifficultyName(difficulty)
    if type(GetString) == "function" and difficulty ~= nil then
        return GetString("SI_DUNGEONDIFFICULTY", difficulty)
    end
    return tostring(difficulty or "")
end

local function GetDifficultyChangeState()
    if type(CanPlayerChangeGroupDifficulty) ~= "function" then
        return false, nil
    end
    local ok, canChange, reason = SafeCall(CanPlayerChangeGroupDifficulty)
    if ok then
        return canChange == true, reason
    end
    return false, nil
end

function MOD.CanShowDungeonDifficultyOption()
    if type(SetVeteranDifficulty) ~= "function" then
        return false
    end
    return MOD.IsPlayerGroupLeader()
end

function MOD.CanChangeDungeonDifficulty()
    if type(SetVeteranDifficulty) ~= "function"
        or not MOD.IsPlayerGroupLeader() then
        return false
    end

    local canChange = GetDifficultyChangeState()
    return canChange == true
end

function MOD.GetNextDungeonDifficulty()
    local current = GetEffectiveDungeonDifficulty()
    if current == DUNGEON_DIFFICULTY_VETERAN then
        return DUNGEON_DIFFICULTY_NORMAL
    end
    if current == DUNGEON_DIFFICULTY_NORMAL then
        return DUNGEON_DIFFICULTY_VETERAN
    end
    return nil
end

function MOD.GetDungeonDifficultyMenuText()
    local nextDifficulty = MOD.GetNextDungeonDifficulty()
    if nextDifficulty == nil then
        return GetString(EZO_MENU_DUNGEON_DIFFICULTY)
    end
    return zo_strformat(GetString(EZO_MENU_DUNGEON_DIFFICULTY_TO),
        GetDungeonDifficultyName(nextDifficulty))
end

function MOD.ToggleDungeonDifficulty()
    local canChange, reason = GetDifficultyChangeState()
    if not MOD.IsPlayerGroupLeader()
        or type(SetVeteranDifficulty) ~= "function"
        or not canChange then
        if reason ~= nil and type(GetString) == "function" then
            local reasonText = GetString("SI_GROUPDIFFICULTYCHANGEREASON", reason)
            if reasonText and reasonText ~= "" then
                Print(zo_strformat(GetString(EZO_MSG_DUNGEON_DIFFICULTY_CANT_CHANGE_REASON), reasonText))
                return false
            end
        end
        Print(GetString(EZO_MSG_DUNGEON_DIFFICULTY_CANT_CHANGE))
        return false
    end

    local nextDifficulty = MOD.GetNextDungeonDifficulty()
    if nextDifficulty == nil then
        return false
    end

    SetVeteranDifficulty(nextDifficulty == DUNGEON_DIFFICULTY_VETERAN)
    Print(zo_strformat(GetString(EZO_MSG_DUNGEON_DIFFICULTY_CHANGED),
        GetDungeonDifficultyName(nextDifficulty)))
    return true
end

function MOD.BuildGroupSnapshot()
    local snapshot = {
        isGrouped = false,
        isLeader = MOD.IsPlayerGroupLeader(),
        size = 0,
        members = {},
    }

    if type(IsUnitGrouped) ~= "function" or not IsUnitGrouped("player") then
        return snapshot
    end

    snapshot.isGrouped = true
    snapshot.size = (type(GetGroupSize) == "function" and GetGroupSize()) or 0

    if type(GetGroupUnitTagByIndex) ~= "function" then
        return snapshot
    end

    for i = 1, snapshot.size do
        local unitTag = GetGroupUnitTagByIndex(i)
        if unitTag and unitTag ~= "" then
            local displayName = ""
            if type(GetUnitDisplayName) == "function" then
                local okName, name = SafeCall(GetUnitDisplayName, unitTag)
                if okName then displayName = tostring(name or "") end
            end

            local characterName = ""
            if type(GetUnitName) == "function" then
                local okChar, name = SafeCall(GetUnitName, unitTag)
                if okChar then characterName = tostring(name or "") end
            end

            snapshot.members[#snapshot.members + 1] = {
                unitTag = unitTag,
                displayName = displayName,
                characterName = characterName,
                isLeader = type(IsUnitGroupLeader) == "function" and IsUnitGroupLeader(unitTag) or false,
            }
        end
    end

    return snapshot
end

function MOD.BuildInstanceSnapshot()
    local inInstance = false
    local ok, value = SafeCall(IsInInstance)
    if ok then
        inInstance = value == true
    else
        ok, value = SafeCall(IsUnitInDungeon, "player")
        if ok then inInstance = value == true end
    end

    local zoneIndex = nil
    if type(GetUnitZoneIndex) == "function" then
        local okZone, idx = SafeCall(GetUnitZoneIndex, "player")
        if okZone then zoneIndex = idx end
    end

    local zoneName = ""
    if zoneIndex and type(GetZoneNameByIndex) == "function" then
        local okName, name = SafeCall(GetZoneNameByIndex, zoneIndex)
        if okName then zoneName = tostring(name or "") end
    end

    local difficulty = GetEffectiveDungeonDifficulty()
    return {
        inInstance = inInstance,
        zoneIndex = zoneIndex,
        zoneName = zoneName,
        difficulty = difficulty,
        difficultyName = GetDungeonDifficultyName(difficulty),
        canChangeDifficulty = MOD.CanChangeDungeonDifficulty(),
    }
end

function MOD.BuildResetSnapshot()
    return {
        group = MOD.BuildGroupSnapshot(),
        instance = MOD.BuildInstanceSnapshot(),
        createdAtMs = type(GetFrameTimeMilliseconds) == "function"
            and GetFrameTimeMilliseconds()
            or nil,
    }
end

-- Compatibilidad temporal con las entradas actuales del menu HOLD X.
EZO.CanShowDungeonDifficultyOption = MOD.CanShowDungeonDifficultyOption
EZO.CanChangeDungeonDifficulty = MOD.CanChangeDungeonDifficulty
EZO.GetNextDungeonDifficulty = MOD.GetNextDungeonDifficulty
EZO.GetDungeonDifficultyMenuText = MOD.GetDungeonDifficultyMenuText
EZO.ToggleDungeonDifficulty = MOD.ToggleDungeonDifficulty
