-- Datos y estado del modo guild de EZOTools.
-- Esta es la unica lista de guilds con imagen y casas predefinidas.
EZOTools = EZOTools or {}
EZOTools_GuildPack = EZOTools_GuildPack or {}

local EZO = EZOTools
local MOD = EZOTools_GuildPack

local GUILD_PACK = {
    ["hojablanca"] = {
        textures = {
            "/AddOns/EZOTools/media/guild_overlays/hojablanca.dds",
            "EZOTools/media/guild_overlays/hojablanca.dds",
        },
        friendHouses = { craftingHall = "@sunsetlu", secondaryHall = "@grukka" },
    },
    ["fuego"] = {
        textures = {
            "/AddOns/EZOTools/media/guild_overlays/fuego.dds",
            "EZOTools/media/guild_overlays/fuego.dds",
        },
        friendHouses = { craftingHall = "@Whasabi", secondaryHall = "@Whasabi" },
    },
    ["sombras de lorkhan"] = {
        textures = {
            "/AddOns/EZOTools/media/guild_overlays/sombra.dds",
            "EZOTools/media/guild_overlays/sombra.dds",
        },
        friendHouses = { craftingHall = "@Salander7", secondaryHall = "@Sr.Manco" },
    },
}

local unlockedKeys = nil

function MOD.NormalizeGuildKey(name)
    if type(name) ~= "string" then return nil end
    name = zo_strtrim(name)
    if name == "" then return nil end
    return zo_strlower(name):gsub("%s+", " ")
end

local function RecalculateUnlockedGuilds()
    unlockedKeys = {}
    if type(GetNumGuilds) ~= "function"
        or type(GetGuildId) ~= "function"
        or type(GetGuildName) ~= "function" then
        return
    end

    for i = 1, GetNumGuilds() do
        local guildId = GetGuildId(i)
        local key = MOD.NormalizeGuildKey(guildId and GetGuildName(guildId))
        if key and GUILD_PACK[key] then
            unlockedKeys[key] = true
        end
    end
end

local function GetUnlockedGuilds()
    if unlockedKeys == nil then
        RecalculateUnlockedGuilds()
    end
    return unlockedKeys
end

function MOD.Refresh()
    unlockedKeys = nil
end

function MOD.IsUnlocked()
    return next(GetUnlockedGuilds()) ~= nil
end

function MOD.IsGuildUnlocked(guildName)
    local key = MOD.NormalizeGuildKey(guildName)
    return key ~= nil and GetUnlockedGuilds()[key] == true
end

function MOD.GetRepresentedGuildName()
    if type(GetRepresentedGuildId) ~= "function" or type(GetGuildName) ~= "function" then
        return nil
    end
    local guildId = GetRepresentedGuildId()
    if not guildId or guildId == 0 then
        return nil
    end
    local guildName = GetGuildName(guildId)
    if type(guildName) ~= "string" or guildName == "" then
        return nil
    end
    return guildName
end

function MOD.GetRepresentedGuildKey()
    return MOD.NormalizeGuildKey(MOD.GetRepresentedGuildName())
end

function MOD.GetRepresentedGuildEntry()
    local guildName = MOD.GetRepresentedGuildName()
    local key = MOD.NormalizeGuildKey(guildName)
    if not key or not MOD.IsGuildUnlocked(key) then
        return nil
    end
    return GUILD_PACK[key], key, guildName
end

function MOD.IsModeEnabled()
    return EZO.sv and EZO.sv.guild and EZO.sv.guild.modeEnabled == true
end

function MOD.SetModeEnabled(enabled)
    if not (EZO.sv and EZO.sv.guild) then
        return false
    end
    EZO.sv.guild.modeEnabled = enabled == true
    return true
end

function MOD.GetActiveTextures()
    if not MOD.IsModeEnabled() then return nil end
    local entry = MOD.GetRepresentedGuildEntry()
    return entry and entry.textures or nil
end

function MOD.GetActiveFriendHouses()
    if not MOD.IsModeEnabled() then return nil end
    local entry = MOD.GetRepresentedGuildEntry()
    return entry and entry.friendHouses or nil
end

local function HandleGuildMembershipChanged(eventCode)
    MOD.Refresh()
    if EZO and type(EZO.RefreshActiveFriendHouses) == "function" then
        EZO.RefreshActiveFriendHouses(eventCode ~= EVENT_GUILD_DATA_LOADED)
    end
    if EZOTools_Overlay and type(EZOTools_Overlay.Refresh) == "function" then
        EZOTools_Overlay.Refresh()
    end
    if EZOTools_LAM and type(EZOTools_LAM.RequestSettingsRefresh) == "function" then
        EZOTools_LAM.RequestSettingsRefresh(true)
    end
end

EVENT_MANAGER:RegisterForEvent(
    "EZOTools_GuildPack_Joined",
    EVENT_GUILD_SELF_JOINED_GUILD,
    HandleGuildMembershipChanged)
EVENT_MANAGER:RegisterForEvent(
    "EZOTools_GuildPack_Left",
    EVENT_GUILD_SELF_LEFT_GUILD,
    HandleGuildMembershipChanged)
EVENT_MANAGER:RegisterForEvent(
    "EZOTools_GuildPack_DataLoaded",
    EVENT_GUILD_DATA_LOADED,
    HandleGuildMembershipChanged)
