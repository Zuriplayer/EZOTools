-- Gestion de Casas del Gremio y perfiles manuales.
-- Mantiene esta logica fuera del modulo principal sin tocar acciones de viaje.
EZOTools = EZOTools or {}

local EZO = EZOTools

local FRIEND_HOUSE_MANUAL_PROFILE_KEY = "__manual"
EZO.FRIEND_HOUSE_MANUAL_PROFILE_KEY = FRIEND_HOUSE_MANUAL_PROFILE_KEY

local function NormalizarClaveGuild(nombre)
    if type(nombre) ~= "string" then return nil end
    nombre = zo_strtrim(nombre)
    if nombre == "" then return nil end
    nombre = zo_strlower(nombre)
    nombre = nombre:gsub("%s+", " ")
    return nombre
end

function EZO.NormalizeGuildKey(nombre)
    return NormalizarClaveGuild(nombre)
end

local function ObtenerGuildKeyRepresentada()
    if type(GetRepresentedGuildId) ~= "function" or type(GetGuildName) ~= "function" then
        return nil
    end
    local guildId = GetRepresentedGuildId()
    if not guildId or guildId == 0 then
        return nil
    end
    return NormalizarClaveGuild(GetGuildName(guildId))
end

function EZO.GetRepresentedGuildKey()
    return ObtenerGuildKeyRepresentada()
end

function EZO.GetPlayerGuildChoices()
    local choices, values = {}, {}
    if type(GetNumGuilds) ~= "function" or type(GetGuildId) ~= "function" or type(GetGuildName) ~= "function" then
        return choices, values
    end

    local numGuilds = GetNumGuilds()
    for i = 1, numGuilds do
        local guildId = GetGuildId(i)
        local guildName = guildId and GetGuildName(guildId) or nil
        local guildKey = NormalizarClaveGuild(guildName)
        if guildKey then
            choices[#choices + 1] = guildName
            values[#values + 1] = guildKey
        end
    end

    return choices, values
end

function EZO.GetFriendHouseProfileChoices()
    local choices = { GetString(EZO_OPTION_FRIENDS_PROFILE_MANUAL) }
    local values = { FRIEND_HOUSE_MANUAL_PROFILE_KEY }
    local guildChoices, guildValues = EZO.GetPlayerGuildChoices()
    for i, choice in ipairs(guildChoices) do
        choices[#choices + 1] = choice
        values[#values + 1] = guildValues[i]
    end
    return choices, values
end

local function ObtenerAsignacionCasasPorGuild(guildKey)
    guildKey = NormalizarClaveGuild(guildKey)
    if not guildKey then return nil end

    -- Los perfiles guardados por el propio jugador funcionan para cualquier gremio.
    local custom = EZO.sv and EZO.sv.friends and EZO.sv.friends.customGuildFriendHouses
    if type(custom) == "table" and type(custom[guildKey]) == "table" then
        return custom[guildKey]
    end

    -- Los valores predefinidos son contenido del guild pack: solo se
    -- aplican si el jugador pertenece a un gremio de su lista blanca.
    local pack = _G.EZOTools_GuildPack
    if pack and type(pack.GetFriendHouses) == "function" then
        return pack.GetFriendHouses(guildKey)
    end

    return nil
end

local function PerteneceAGuildJugador(guildKey)
    guildKey = NormalizarClaveGuild(guildKey)
    if not guildKey then return false end
    local _, playerGuildValues = EZO.GetPlayerGuildChoices()
    for _, value in ipairs(playerGuildValues) do
        if value == guildKey then
            return true
        end
    end
    return false
end

function EZO.IsPlayerGuildKey(guildKey)
    return PerteneceAGuildJugador(guildKey)
end

local function ObtenerAsignacionManualCasas()
    local friends = EZO.sv and EZO.sv.friends or nil
    if type(friends) ~= "table" then return nil end
    return {
        craftingHall = tostring(friends.manualCraftingHall or ""),
        secondaryHall = tostring(friends.manualSecondaryHall or ""),
    }
end

local function ObtenerAsignacionPerfilCasas(profileKey)
    profileKey = tostring(profileKey or FRIEND_HOUSE_MANUAL_PROFILE_KEY)
    if profileKey == "" or profileKey == FRIEND_HOUSE_MANUAL_PROFILE_KEY then
        return ObtenerAsignacionManualCasas()
    end
    local config = ObtenerAsignacionCasasPorGuild(profileKey)
    if type(config) == "table" then
        return config
    end
    return { craftingHall = "", secondaryHall = "" }
end

local function AplicarAsignacionCasas(config)
    if type(config) ~= "table" or not (EZO.sv and EZO.sv.friends) then
        return false
    end
    EZO.sv.friends.craftingHall = tostring(config.craftingHall or "")
    EZO.sv.friends.secondaryHall = tostring(config.secondaryHall or "")
    return true
end

local function AplicarValoresPropiosCasas()
    return AplicarAsignacionCasas(ObtenerAsignacionManualCasas())
end

local function CargarPerfilCasasParaEditar(profileKey)
    if not (EZO.sv and EZO.sv.friends) then
        return false
    end
    local config = ObtenerAsignacionPerfilCasas(profileKey)
    EZO.sv.friends.editCraftingHall = tostring(config.craftingHall or "")
    EZO.sv.friends.editSecondaryHall = tostring(config.secondaryHall or "")
    return true
end

local function EsClavePerfilCasasValida(profileKey)
    profileKey = tostring(profileKey or FRIEND_HOUSE_MANUAL_PROFILE_KEY)
    if profileKey == "" or profileKey == FRIEND_HOUSE_MANUAL_PROFILE_KEY then
        return true
    end
    return PerteneceAGuildJugador(profileKey)
end

function EZO.IsFriendHouseProfileKeyValid(profileKey)
    return EsClavePerfilCasasValida(profileKey)
end

function EZO.ApplyManualFriendHouseProfileSelection()
    if not (EZO.sv and EZO.sv.friends) then
        return false
    end

    local profileKey = tostring(EZO.sv.friends.manualActiveFriendHouseProfileKey or FRIEND_HOUSE_MANUAL_PROFILE_KEY)
    if not EsClavePerfilCasasValida(profileKey) then
        EZO.sv.friends.manualActiveFriendHouseProfileKey = FRIEND_HOUSE_MANUAL_PROFILE_KEY
        profileKey = FRIEND_HOUSE_MANUAL_PROFILE_KEY
    end

    return AplicarAsignacionCasas(ObtenerAsignacionPerfilCasas(profileKey))
end

function EZO.MigrateLegacyFriendHouseProfiles(friends)
    if type(friends) ~= "table" then
        return
    end
    if friends.fuegoFriendHouseDefaultMigrated == true then
        return
    end

    local custom = friends.customGuildFriendHouses
    local fuego = type(custom) == "table" and custom["fuego"] or nil
    if type(fuego) == "table" then
        local crafting = zo_strlower(tostring(fuego.craftingHall or ""))
        local secondary = zo_strlower(tostring(fuego.secondaryHall or ""))
        if crafting == "@whasabi" and (secondary == "" or secondary == "@grukka") then
            fuego.secondaryHall = "@Whasabi"
        end
    end

    friends.fuegoFriendHouseDefaultMigrated = true
end

function EZO.ApplyAutoFriendHousesSelection()
    if not (EZO.sv and EZO.sv.friends and EZO.sv.friends.autoAssignFriendHouses == true) then
        return false
    end

    local guildKey = ObtenerGuildKeyRepresentada()
    if not guildKey or not PerteneceAGuildJugador(guildKey) then
        AplicarValoresPropiosCasas()
        return false
    end

    local config = ObtenerAsignacionCasasPorGuild(guildKey)
    if type(config) ~= "table" then
        AplicarValoresPropiosCasas()
        return false
    end

    return AplicarAsignacionCasas(config)
end

function EZO.RefreshActiveFriendHouses()
    if not (EZO.sv and EZO.sv.friends) then
        return false
    end
    if EZO.sv.friends.autoAssignFriendHouses == true then
        return EZO.ApplyAutoFriendHousesSelection()
    end
    return EZO.ApplyManualFriendHouseProfileSelection()
end

function EZO.ResetFriendHouseProfileDefaults()
    if not (EZO.sv and EZO.sv.friends) then
        return false
    end
    EZO.sv.friends.autoAssignFriendHouses = false
    EZO.sv.friends.manualActiveFriendHouseProfileKey = FRIEND_HOUSE_MANUAL_PROFILE_KEY
    EZO.sv.friends.manualActiveFriendHouseProfileInitialized = true
    EZO.sv.friends.friendHouseProfileKey = FRIEND_HOUSE_MANUAL_PROFILE_KEY
    EZO.sv.friends.editCraftingHall = tostring(EZO.sv.friends.manualCraftingHall or "")
    EZO.sv.friends.editSecondaryHall = tostring(EZO.sv.friends.manualSecondaryHall or "")
    return EZO.RefreshActiveFriendHouses()
end

function EZO.GetActiveFriendHousesDescription()
    if not (EZO.sv and EZO.sv.friends) then
        return ""
    end
    EZO.RefreshActiveFriendHouses()
    local empty = GetString(EZO_OPTION_FRIENDS_ACTIVE_EMPTY)
    local craftingHall = tostring(EZO.sv.friends.craftingHall or "")
    local secondaryHall = tostring(EZO.sv.friends.secondaryHall or "")
    if craftingHall == "" then
        craftingHall = empty
    end
    if secondaryHall == "" then
        secondaryHall = empty
    end
    return zo_strformat(GetString(EZO_OPTION_FRIENDS_ACTIVE_VALUES), craftingHall, secondaryHall)
end

function EZO.LoadSelectedFriendHouseProfileForEditing()
    if not (EZO.sv and EZO.sv.friends) then
        return false
    end

    local profileKey = tostring(EZO.sv.friends.friendHouseProfileKey or FRIEND_HOUSE_MANUAL_PROFILE_KEY)
    if profileKey ~= "" and profileKey ~= FRIEND_HOUSE_MANUAL_PROFILE_KEY and not PerteneceAGuildJugador(profileKey) then
        return false
    end
    return CargarPerfilCasasParaEditar(profileKey)
end

function EZO.SaveCurrentFriendHousesForSelectedGuild()
    if not (EZO.sv and EZO.sv.friends) then
        return false
    end

    local profileKey = tostring(EZO.sv.friends.friendHouseProfileKey or FRIEND_HOUSE_MANUAL_PROFILE_KEY)
    if profileKey == "" or profileKey == FRIEND_HOUSE_MANUAL_PROFILE_KEY then
        EZO.sv.friends.manualCraftingHall = tostring(EZO.sv.friends.editCraftingHall or "")
        EZO.sv.friends.manualSecondaryHall = tostring(EZO.sv.friends.editSecondaryHall or "")
        if EZO.sv.friends.autoAssignFriendHouses ~= true
            and tostring(EZO.sv.friends.manualActiveFriendHouseProfileKey or FRIEND_HOUSE_MANUAL_PROFILE_KEY) == FRIEND_HOUSE_MANUAL_PROFILE_KEY
        then
            return EZO.ApplyManualFriendHouseProfileSelection()
        end
        return true
    end

    local guildKey = NormalizarClaveGuild(profileKey)
    if not guildKey or not PerteneceAGuildJugador(guildKey) then
        return false
    end

    EZO.sv.friends.customGuildFriendHouses = EZO.sv.friends.customGuildFriendHouses or {}
    EZO.sv.friends.customGuildFriendHouses[guildKey] = {
        craftingHall = tostring(EZO.sv.friends.editCraftingHall or ""),
        secondaryHall = tostring(EZO.sv.friends.editSecondaryHall or ""),
    }
    if EZO.sv.friends.autoAssignFriendHouses == true and guildKey == ObtenerGuildKeyRepresentada() then
        return EZO.ApplyAutoFriendHousesSelection()
    elseif EZO.sv.friends.autoAssignFriendHouses ~= true
        and guildKey == NormalizarClaveGuild(EZO.sv.friends.manualActiveFriendHouseProfileKey)
    then
        return EZO.ApplyManualFriendHouseProfileSelection()
    end
    return true
end
