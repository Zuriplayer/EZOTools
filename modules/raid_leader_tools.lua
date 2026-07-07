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

local function IsPlayerInInstance()
    local ok, value = SafeCall(IsInInstance)
    if ok then
        return value == true
    end

    ok, value = SafeCall(IsUnitInDungeon, "player")
    if ok then
        return value == true
    end

    return false
end

local TRIALS = {
    {
        key = "aetherian_archive",
        name = "Aetherian Archive",
        aliases = { "Aetherian Archive", "Archivo Aetheriano" },
    },
    {
        key = "hel_ra_citadel",
        name = "Hel Ra Citadel",
        aliases = { "Hel Ra Citadel", "Ciudadela de Hel Ra" },
    },
    {
        key = "sanctum_ophidia",
        name = "Sanctum Ophidia",
        aliases = { "Sanctum Ophidia" },
    },
    {
        key = "maw_of_lorkhaj",
        name = "Maw of Lorkhaj",
        aliases = { "Maw of Lorkhaj", "Lorkhaj" },
    },
    {
        key = "halls_of_fabrication",
        name = "Halls of Fabrication",
        aliases = { "Halls of Fabrication", "Fabrication" },
    },
    {
        key = "asylum_sanctorium",
        name = "Asylum Sanctorium",
        aliases = { "Asylum Sanctorium", "Sanctorium" },
    },
    {
        key = "cloudrest",
        name = "Cloudrest",
        aliases = { "Cloudrest" },
    },
    {
        key = "sunspire",
        name = "Sunspire",
        aliases = { "Sunspire" },
    },
    {
        key = "kynes_aegis",
        name = "Kyne's Aegis",
        aliases = { "Kyne's Aegis", "Kyne’s Aegis", "Kyne" },
    },
    {
        key = "rockgrove",
        name = "Rockgrove",
        aliases = { "Rockgrove" },
    },
    {
        key = "dreadsail_reef",
        name = "Dreadsail Reef",
        aliases = { "Dreadsail Reef" },
    },
    {
        key = "sanitys_edge",
        name = "Sanity's Edge",
        aliases = { "Sanity's Edge", "Sanity’s Edge" },
    },
    {
        key = "lucent_citadel",
        name = "Lucent Citadel",
        aliases = { "Lucent Citadel" },
    },
    {
        key = "ossein_cage",
        name = "Ossein Cage",
        aliases = { "Ossein Cage" },
    },
}

local TRIAL_BY_KEY = {}
for _, trial in ipairs(TRIALS) do
    TRIAL_BY_KEY[trial.key] = trial
end

local function EnsureRaidLeaderSavedVariables()
    EZO.sv = EZO.sv or {}
    EZO.sv.raidLeaderTools = EZO.sv.raidLeaderTools or {}
    return EZO.sv.raidLeaderTools
end

local function NormalizeNodeName(value)
    value = tostring(value or "")
    value = value:gsub("’", "'"):gsub("`", "'"):gsub("´", "'")
    value = string.lower(value)
    value = value:gsub("[^%w]+", "")
    return value
end

local function IsKnownFastTravelNode(known)
    return known == true or known == 1
end

local function NodeMatchesTrial(nodeName, trial)
    local normalizedNode = NormalizeNodeName(nodeName)
    if normalizedNode == "" or type(trial) ~= "table" then
        return false
    end

    local aliases = trial.aliases or {}
    for _, alias in ipairs(aliases) do
        local normalizedAlias = NormalizeNodeName(alias)
        if normalizedAlias ~= ""
            and (normalizedNode == normalizedAlias
                or string.find(normalizedNode, normalizedAlias, 1, true) ~= nil) then
            return true
        end
    end
    return false
end

local function FindFastTravelNodeForTrial(trial)
    if type(GetNumFastTravelNodes) ~= "function"
        or type(GetFastTravelNodeInfo) ~= "function" then
        return nil, nil
    end

    local okCount, count = SafeCall(GetNumFastTravelNodes)
    count = okCount and tonumber(count) or 0
    for nodeIndex = 1, count do
        local okNode, known, nodeName = SafeCall(GetFastTravelNodeInfo, nodeIndex)
        if okNode and IsKnownFastTravelNode(known) and NodeMatchesTrial(nodeName, trial) then
            return nodeIndex, tostring(nodeName or trial.name)
        end
    end
    return nil, nil
end

local function GetGroupDifficultyChangeReasonText(reason)
    if reason ~= nil and type(GetString) == "function" then
        local reasonText = GetString("SI_GROUPDIFFICULTYCHANGEREASON", reason)
        if reasonText and reasonText ~= "" then
            return reasonText
        end
    end
    return nil
end

local function TrySetVeteranDifficulty()
    if type(SetVeteranDifficulty) ~= "function" then
        return false, nil
    end

    local current = GetEffectiveDungeonDifficulty()
    if current == DUNGEON_DIFFICULTY_VETERAN then
        return true, nil
    end

    local canChange, reason = GetDifficultyChangeState()
    if canChange then
        SetVeteranDifficulty(true)
        return true, nil
    end

    return false, GetGroupDifficultyChangeReasonText(reason)
end

local function GetTrialByKey(trialKey)
    return TRIAL_BY_KEY[tostring(trialKey or "")]
end

function MOD.GetTrialDefinitions()
    local copy = {}
    for i, trial in ipairs(TRIALS) do
        copy[i] = trial
    end
    return copy
end

function MOD.GetLastTrialKey()
    local sv = EZO.sv and EZO.sv.raidLeaderTools
    return sv and sv.lastTrialKey or nil
end

function MOD.GetTrialName(trialKey)
    local trial = GetTrialByKey(trialKey)
    return trial and trial.name or ""
end

function MOD.GetLastTrialMenuText()
    local trial = GetTrialByKey(MOD.GetLastTrialKey())
    if not trial then
        return GetString(EZO_MENU_TRIAL_TRAVEL_LAST_NONE)
    end
    return zo_strformat(GetString(EZO_MENU_TRIAL_TRAVEL_LAST), trial.name)
end

function MOD.TravelToTrial(trialKey)
    local trial = GetTrialByKey(trialKey)
    if not trial then
        return false
    end

    local veteranReady, blockedReason = TrySetVeteranDifficulty()
    if not veteranReady then
        if blockedReason and blockedReason ~= "" then
            Print(zo_strformat(GetString(EZO_MSG_TRIAL_TRAVEL_VETERAN_BLOCKED_REASON), blockedReason))
        else
            Print(GetString(EZO_MSG_TRIAL_TRAVEL_VETERAN_BLOCKED))
        end
    end

    if type(FastTravelToNode) ~= "function" then
        Print(GetString(EZO_MSG_TRIAL_TRAVEL_UNAVAILABLE))
        return false
    end

    local nodeIndex = FindFastTravelNodeForTrial(trial)
    if not nodeIndex then
        Print(zo_strformat(GetString(EZO_MSG_TRIAL_TRAVEL_NODE_MISSING), trial.name))
        return false
    end

    local sv = EnsureRaidLeaderSavedVariables()
    sv.lastTrialKey = trial.key

    Print(zo_strformat(GetString(EZO_MSG_TRIAL_TRAVEL_START), trial.name))
    local okTravel = SafeCall(FastTravelToNode, nodeIndex)
    if not okTravel then
        Print(GetString(EZO_MSG_TRIAL_TRAVEL_UNAVAILABLE))
    end
    return false
end

function MOD.TravelToLastTrial()
    local lastTrialKey = MOD.GetLastTrialKey()
    if not GetTrialByKey(lastTrialKey) then
        Print(GetString(EZO_MSG_TRIAL_TRAVEL_LAST_NONE))
        return false
    end
    return MOD.TravelToTrial(lastTrialKey)
end

function MOD.BuildTrialTravelEntries()
    local entries = {}
    entries[#entries + 1] = {
        text = MOD.GetLastTrialMenuText,
        callback = function() return MOD.TravelToLastTrial() end,
    }
    for _, trial in ipairs(TRIALS) do
        local trialKey = trial.key
        local trialName = trial.name
        entries[#entries + 1] = {
            text = trialName,
            callback = function() return MOD.TravelToTrial(trialKey) end,
        }
    end
    return entries
end

function MOD.CanShowDungeonDifficultyOption()
    if type(SetVeteranDifficulty) ~= "function" then
        return false
    end
    return MOD.IsPlayerGroupLeader() and not IsPlayerInInstance()
end

function MOD.CanChangeDungeonDifficulty()
    if type(SetVeteranDifficulty) ~= "function"
        or not MOD.IsPlayerGroupLeader()
        or IsPlayerInInstance() then
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
