-- Resolucion de casas manuales y del modo guild.
-- Las acciones de viaje siguen consumiendo craftingHall y secondaryHall.
EZOTools = EZOTools or {}

local EZO = EZOTools

local function GetGuildPack()
    return _G.EZOTools_GuildPack
end

local function GetManualFriendHouses()
    local friends = EZO.sv and EZO.sv.friends
    if type(friends) ~= "table" then return nil end
    return {
        craftingHall = tostring(friends.manualCraftingHall or ""),
        secondaryHall = tostring(friends.manualSecondaryHall or ""),
    }
end

local function ApplyFriendHouses(config)
    local friends = EZO.sv and EZO.sv.friends
    if type(config) ~= "table" or type(friends) ~= "table" then
        return false
    end
    friends.craftingHall = tostring(config.craftingHall or "")
    friends.secondaryHall = tostring(config.secondaryHall or "")
    return true
end

local function ShowRepresentedGuildWarning()
    local pack = GetGuildPack()
    if not (pack and type(pack.IsUnlocked) == "function" and pack.IsUnlocked()) then
        return
    end
    if EZO and type(EZO.Print) == "function" then
        EZO.Print(GetString(EZO_MSG_GUILD_MODE_REPRESENTED_REQUIRED))
    end
end

function EZO.IsGuildModeEnabled()
    local pack = GetGuildPack()
    return pack and type(pack.IsModeEnabled) == "function" and pack.IsModeEnabled() == true
end

function EZO.SetGuildModeEnabled(enabled, showWarning)
    local pack = GetGuildPack()
    if not (pack and type(pack.SetModeEnabled) == "function" and pack.SetModeEnabled(enabled)) then
        return false
    end
    EZO.RefreshActiveFriendHouses(showWarning == true)
    return true
end

function EZO.RefreshActiveFriendHouses(showWarning)
    local pack = GetGuildPack()
    if EZO.IsGuildModeEnabled()
        and pack
        and type(pack.GetActiveFriendHouses) == "function" then
        local guildHouses = pack.GetActiveFriendHouses()
        if type(guildHouses) == "table" then
            return ApplyFriendHouses(guildHouses)
        end
        if showWarning == true then
            ShowRepresentedGuildWarning()
        end
    end
    return ApplyFriendHouses(GetManualFriendHouses())
end

local function SetManualFriendHouse(field, value)
    local friends = EZO.sv and EZO.sv.friends
    if type(friends) ~= "table" then
        return false
    end
    friends[field] = tostring(value or "")
    EZO.RefreshActiveFriendHouses(false)
    return true
end

function EZO.SetManualCraftingHall(value)
    return SetManualFriendHouse("manualCraftingHall", value)
end

function EZO.SetManualSecondaryHall(value)
    return SetManualFriendHouse("manualSecondaryHall", value)
end

local function GetDisplayedFriendHouse(activeField, manualField)
    local friends = EZO.sv and EZO.sv.friends
    if type(friends) ~= "table" then
        return ""
    end
    if EZO.IsGuildModeEnabled() then
        return tostring(friends[activeField] or "")
    end
    return tostring(friends[manualField] or "")
end

function EZO.GetDisplayedCraftingHall()
    return GetDisplayedFriendHouse("craftingHall", "manualCraftingHall")
end

function EZO.GetDisplayedSecondaryHall()
    return GetDisplayedFriendHouse("secondaryHall", "manualSecondaryHall")
end

function EZO.GetActiveFriendHousesDescription()
    local friends = EZO.sv and EZO.sv.friends
    if type(friends) ~= "table" then
        return ""
    end
    local empty = GetString(EZO_OPTION_FRIENDS_ACTIVE_EMPTY)
    local craftingHall = tostring(friends.craftingHall or "")
    local secondaryHall = tostring(friends.secondaryHall or "")
    if craftingHall == "" then craftingHall = empty end
    if secondaryHall == "" then secondaryHall = empty end
    return zo_strformat(GetString(EZO_OPTION_FRIENDS_ACTIVE_VALUES), craftingHall, secondaryHall)
end
