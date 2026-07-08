-- Catalogo central de actividades de grupo gestionadas por EZOTools.
-- No inventar ids: los campos de id deben rellenarse solo cuando esten verificados.
-- Esquema previsto: key, kind, name, aliases, zoneId, activityId, fastTravelNodeId.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.RaidLeaderActivityCatalog = EZO.RaidLeaderActivityCatalog or {}
local MOD = EZO.RaidLeaderActivityCatalog

local TRIALS = {
    {
        key = "aetherian_archive",
        kind = "trial",
        name = "Aetherian Archive",
        aliases = { "Aetherian Archive", "Archivo Aetheriano" },
    },
    {
        key = "hel_ra_citadel",
        kind = "trial",
        name = "Hel Ra Citadel",
        aliases = { "Hel Ra Citadel", "Ciudadela de Hel Ra" },
    },
    {
        key = "sanctum_ophidia",
        kind = "trial",
        name = "Sanctum Ophidia",
        aliases = { "Sanctum Ophidia" },
    },
    {
        key = "maw_of_lorkhaj",
        kind = "trial",
        name = "Maw of Lorkhaj",
        aliases = { "Maw of Lorkhaj", "Lorkhaj" },
    },
    {
        key = "halls_of_fabrication",
        kind = "trial",
        name = "Halls of Fabrication",
        aliases = { "Halls of Fabrication", "Fabrication" },
    },
    {
        key = "asylum_sanctorium",
        kind = "trial",
        name = "Asylum Sanctorium",
        aliases = { "Asylum Sanctorium", "Sanctorium" },
    },
    {
        key = "cloudrest",
        kind = "trial",
        name = "Cloudrest",
        aliases = { "Cloudrest" },
    },
    {
        key = "sunspire",
        kind = "trial",
        name = "Sunspire",
        aliases = { "Sunspire" },
    },
    {
        key = "kynes_aegis",
        kind = "trial",
        name = "Kyne's Aegis",
        aliases = { "Kyne's Aegis", "Kyne's Aegis", "Kyne" },
    },
    {
        key = "rockgrove",
        kind = "trial",
        name = "Rockgrove",
        aliases = { "Rockgrove" },
    },
    {
        key = "dreadsail_reef",
        kind = "trial",
        name = "Dreadsail Reef",
        aliases = { "Dreadsail Reef" },
    },
    {
        key = "sanitys_edge",
        kind = "trial",
        name = "Sanity's Edge",
        aliases = { "Sanity's Edge", "Sanity's Edge" },
    },
    {
        key = "lucent_citadel",
        kind = "trial",
        name = "Lucent Citadel",
        aliases = { "Lucent Citadel" },
    },
    {
        key = "ossein_cage",
        kind = "trial",
        name = "Ossein Cage",
        aliases = { "Ossein Cage" },
    },
}

local DUNGEONS = {}
local TRIAL_BY_KEY = {}

local function CopyAliases(aliases)
    local copy = {}
    if type(aliases) == "table" then
        for i, alias in ipairs(aliases) do
            copy[i] = alias
        end
    end
    return copy
end

local function CopyActivity(activity)
    if type(activity) ~= "table" then return nil end
    local copy = {}
    for key, value in pairs(activity) do
        if key == "aliases" then
            copy.aliases = CopyAliases(value)
        else
            copy[key] = value
        end
    end
    return copy
end

local function CopyList(source)
    local copy = {}
    if type(source) ~= "table" then return copy end
    for i, activity in ipairs(source) do
        copy[i] = CopyActivity(activity)
    end
    return copy
end

for _, trial in ipairs(TRIALS) do
    TRIAL_BY_KEY[trial.key] = trial
end

function MOD.GetTrialDefinitions()
    return CopyList(TRIALS)
end

function MOD.GetDungeonDefinitions()
    return CopyList(DUNGEONS)
end

function MOD.GetTrialByKey(trialKey)
    return CopyActivity(TRIAL_BY_KEY[tostring(trialKey or "")])
end

function MOD.GetActivityDefinitions(kind)
    kind = tostring(kind or "")
    if kind == "trial" then
        return MOD.GetTrialDefinitions()
    end
    if kind == "dungeon" then
        return MOD.GetDungeonDefinitions()
    end
    local activities = MOD.GetTrialDefinitions()
    local dungeons = MOD.GetDungeonDefinitions()
    for _, dungeon in ipairs(dungeons) do
        activities[#activities + 1] = dungeon
    end
    return activities
end
