-- Acciones de viaje, grupo e instancia.
-- Mantiene los mismos nombres publicos usados por Bindings.xml y action_exec.
EZOTools = EZOTools or {}

local EZO = EZOTools

local function Print(message)
    if EZO and type(EZO.Print) == "function" then
        EZO.Print(message)
    elseif type(d) == "function" then
        d(tostring(message))
    end
end

function EZO.JumpPrimaryHouse()
    local id = GetHousingPrimaryHouse()
    if id and id > 0 then
        RequestJumpToHouse(id)
    else
        Print(GetString(EZO_MSG_NO_PRIMARY_HOUSE))
    end
end

local function SaltarACasa(nombreCuenta)
    if nombreCuenta and nombreCuenta ~= "" then
        JumpToHouse(nombreCuenta)
        return true
    end
    return false
end

function EZO.JumpCraftingHall()
    local friends = EZO.sv and EZO.sv.friends or nil
    if not SaltarACasa(friends and friends.craftingHall) then
        Print(GetString(EZO_MSG_NO_CRAFTING_HALL))
    end
end

function EZO.JumpSecondaryHall()
    local friends = EZO.sv and EZO.sv.friends or nil
    if not SaltarACasa(friends and friends.secondaryHall) then
        Print(GetString(EZO_MSG_NO_SECONDARY_HALL))
    end
end

function EZO.CanJumpToLeader()
    if not IsUnitGrouped or not IsUnitGrouped("player") then return false end
    if GetGroupLeaderUnitTag and CanJumpToGroupMember then
        local leaderTag = GetGroupLeaderUnitTag()
        if leaderTag and leaderTag ~= "" then
            return CanJumpToGroupMember(leaderTag)
        end
    end
    return JumpToGroupLeader ~= nil
end

function EZO.GetLeaderJumpMenuText()
    local baseText = GetString(EZO_MENU_JUMP_LEADER)
    if not GetGroupLeaderUnitTag then
        return baseText
    end

    local leaderTag = GetGroupLeaderUnitTag()
    if not leaderTag or leaderTag == "" then
        return baseText
    end

    local displayName = ""
    if type(GetUnitDisplayName) == "function" then
        local okName, name = pcall(GetUnitDisplayName, leaderTag)
        if okName then
            displayName = tostring(name or "")
        end
    end

    local zoneName = ""
    if type(GetUnitZoneIndex) == "function" and type(GetZoneNameByIndex) == "function" then
        local okZoneIndex, zoneIndex = pcall(GetUnitZoneIndex, leaderTag)
        if okZoneIndex and zoneIndex then
            local okZoneName, name = pcall(GetZoneNameByIndex, zoneIndex)
            if okZoneName then
                zoneName = tostring(name or "")
            end
        end
    end

    if displayName ~= "" and zoneName ~= "" then
        return zo_strformat(GetString(EZO_MENU_JUMP_LEADER_WITH_LOCATION), displayName, zoneName)
    end
    if zoneName ~= "" then
        return zo_strformat(GetString(EZO_MENU_JUMP_LEADER_ZONE), zoneName)
    end
    if displayName ~= "" then
        return zo_strformat(GetString(EZO_MENU_JUMP_LEADER_PLAYER), displayName)
    end
    return baseText
end

function EZO.JumpToLeader()
    if not IsUnitGrouped or not IsUnitGrouped("player") then
        Print(GetString(EZO_MSG_NOT_IN_GROUP))
        return
    end

    local leaderTag = (GetGroupLeaderUnitTag and GetGroupLeaderUnitTag()) or nil
    if leaderTag and leaderTag ~= "" and CanJumpToGroupMember and JumpToGroupMember then
        if CanJumpToGroupMember(leaderTag) then
            -- CanJumpToGroupMember acepta unitTag; JumpToGroupMember necesita @Cuenta.
            local displayName = (GetUnitDisplayName and GetUnitDisplayName(leaderTag)) or ""
            if displayName ~= "" then
                JumpToGroupMember(displayName)
                return
            end
        end
    end

    if JumpToGroupLeader then
        JumpToGroupLeader("")
        return
    end

    Print(GetString(EZO_MSG_CANT_JUMP_LEADER))
end

function EZO.LeaveGroup()
    if type(GroupLeave) == "function" then
        GroupLeave()
        return true
    end
    return false
end

function EZO.LeaveInstance()
    if type(ExitInstanceImmediately) == "function" then
        ExitInstanceImmediately()
        return true
    end
    return false
end

function EZO.LeaveGroupAndInstance()
    local done = false
    if type(GroupLeave) == "function" then
        GroupLeave()
        done = true
    end
    if type(ExitInstanceImmediately) == "function" then
        ExitInstanceImmediately()
        done = true
    end
    return done
end

local function GetEffectiveDungeonDifficulty()
    if type(ZO_GetEffectiveDungeonDifficulty) == "function" then
        local ok, difficulty = pcall(ZO_GetEffectiveDungeonDifficulty)
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

function EZO.CanChangeDungeonDifficulty()
    if type(SetVeteranDifficulty) ~= "function"
        or type(CanPlayerChangeGroupDifficulty) ~= "function" then
        return false
    end
    if type(IsUnitGrouped) ~= "function"
        or type(IsUnitGroupLeader) ~= "function"
        or not IsUnitGrouped("player")
        or not IsUnitGroupLeader("player") then
        return false
    end

    local ok, canChange = pcall(CanPlayerChangeGroupDifficulty)
    return ok and canChange == true
end

function EZO.GetNextDungeonDifficulty()
    local current = GetEffectiveDungeonDifficulty()
    if current == DUNGEON_DIFFICULTY_VETERAN then
        return DUNGEON_DIFFICULTY_NORMAL
    end
    if current == DUNGEON_DIFFICULTY_NORMAL then
        return DUNGEON_DIFFICULTY_VETERAN
    end
    return nil
end

function EZO.GetDungeonDifficultyMenuText()
    local nextDifficulty = EZO.GetNextDungeonDifficulty()
    if nextDifficulty == nil then
        return GetString(EZO_MENU_DUNGEON_DIFFICULTY)
    end
    return zo_strformat(GetString(EZO_MENU_DUNGEON_DIFFICULTY_TO),
        GetDungeonDifficultyName(nextDifficulty))
end

function EZO.ToggleDungeonDifficulty()
    if not EZO.CanChangeDungeonDifficulty() then
        Print(GetString(EZO_MSG_DUNGEON_DIFFICULTY_CANT_CHANGE))
        return false
    end

    local nextDifficulty = EZO.GetNextDungeonDifficulty()
    if nextDifficulty == nil then
        return false
    end

    SetVeteranDifficulty(nextDifficulty == DUNGEON_DIFFICULTY_VETERAN)
    Print(zo_strformat(GetString(EZO_MSG_DUNGEON_DIFFICULTY_CHANGED),
        GetDungeonDifficultyName(nextDifficulty)))
    return true
end
