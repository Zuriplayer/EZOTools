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
        craftingHallHouseId = tonumber(friends.manualCraftingHallHouseId) or 0,
        secondaryHallHouseId = tonumber(friends.manualSecondaryHallHouseId) or 0,
        craftingHallHouseName = tostring(friends.manualCraftingHallHouseName or ""),
        secondaryHallHouseName = tostring(friends.manualSecondaryHallHouseName or ""),
    }
end

local function ApplyFriendHouses(config)
    local friends = EZO.sv and EZO.sv.friends
    if type(config) ~= "table" or type(friends) ~= "table" then
        return false
    end
    friends.craftingHall = tostring(config.craftingHall or "")
    friends.secondaryHall = tostring(config.secondaryHall or "")
    friends.craftingHallHouseId = tonumber(config.craftingHallHouseId) or 0
    friends.secondaryHallHouseId = tonumber(config.secondaryHallHouseId) or 0
    friends.craftingHallHouseName = tostring(config.craftingHallHouseName or "")
    friends.secondaryHallHouseName = tostring(config.secondaryHallHouseName or "")
    return true
end

local function Trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function GetCurrentHouseName(houseId)
    local manager = _G.HOUSING_SOCIAL_MANAGER
    if manager and type(manager.GetHouseName) == "function" then
        local ok, houseName = pcall(manager.GetHouseName, manager, houseId)
        if ok then
            return Trim(houseName)
        end
    end
    return ""
end

local function GetCurrentHouseDestination()
    if type(GetCurrentZoneHouseId) ~= "function" or type(GetCurrentHouseOwner) ~= "function" then
        return nil
    end

    local okHouse, houseId = pcall(GetCurrentZoneHouseId)
    houseId = okHouse and tonumber(houseId) or 0
    if houseId <= 0 then
        return nil
    end

    local okOwner, owner = pcall(GetCurrentHouseOwner)
    owner = okOwner and Trim(owner) or ""
    if owner == "" and type(IsOwnerOfCurrentHouse) == "function" then
        local okOwned, isOwned = pcall(IsOwnerOfCurrentHouse)
        if okOwned and isOwned == true and type(GetDisplayName) == "function" then
            local okDisplayName, displayName = pcall(GetDisplayName)
            owner = okDisplayName and Trim(displayName) or ""
        end
    end
    if owner == "" then
        return nil
    end

    return {
        account = owner,
        houseId = houseId,
        houseName = GetCurrentHouseName(houseId),
    }
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

local function SetManualFriendHouse(field, houseIdField, houseNameField, value)
    local friends = EZO.sv and EZO.sv.friends
    if type(friends) ~= "table" then
        return false
    end
    friends[field] = tostring(value or "")
    friends[houseIdField] = 0
    friends[houseNameField] = ""
    EZO.RefreshActiveFriendHouses(false)
    return true
end

function EZO.SetManualCraftingHall(value)
    return SetManualFriendHouse(
        "manualCraftingHall",
        "manualCraftingHallHouseId",
        "manualCraftingHallHouseName",
        value
    )
end

function EZO.SetManualSecondaryHall(value)
    return SetManualFriendHouse(
        "manualSecondaryHall",
        "manualSecondaryHallHouseId",
        "manualSecondaryHallHouseName",
        value
    )
end

local function SetCurrentHouseAsManualDestination(accountField, houseIdField, houseNameField)
    if EZO.IsGuildModeEnabled() then
        return false
    end
    local friends = EZO.sv and EZO.sv.friends
    local destination = GetCurrentHouseDestination()
    if type(friends) ~= "table" or type(destination) ~= "table" then
        return false
    end

    friends[accountField] = destination.account
    friends[houseIdField] = destination.houseId
    friends[houseNameField] = destination.houseName
    EZO.RefreshActiveFriendHouses(false)
    return true, destination
end

function EZO.SetCurrentHouseAsManualCraftingHall()
    return SetCurrentHouseAsManualDestination(
        "manualCraftingHall",
        "manualCraftingHallHouseId",
        "manualCraftingHallHouseName"
    )
end

function EZO.SetCurrentHouseAsManualSecondaryHall()
    return SetCurrentHouseAsManualDestination(
        "manualSecondaryHall",
        "manualSecondaryHallHouseId",
        "manualSecondaryHallHouseName"
    )
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
    local function FormatDestination(accountField, houseNameField)
        local account = tostring(friends[accountField] or "")
        local houseName = tostring(friends[houseNameField] or "")
        if account ~= "" and houseName ~= "" then
            return zo_strformat(GetString(EZO_OPTION_FRIENDS_ACTIVE_HOUSE), houseName, account)
        end
        return account
    end

    local craftingHall = FormatDestination("craftingHall", "craftingHallHouseName")
    local secondaryHall = FormatDestination("secondaryHall", "secondaryHallHouseName")
    if craftingHall == "" then craftingHall = empty end
    if secondaryHall == "" then secondaryHall = empty end
    return zo_strformat(GetString(EZO_OPTION_FRIENDS_ACTIVE_VALUES), craftingHall, secondaryHall)
end
