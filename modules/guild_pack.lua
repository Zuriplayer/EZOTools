-- Contenido exclusivo para gremios amigos de EZOTools (el "huevo de pascua").
-- Este módulo es la ÚNICA lista blanca de gremios con extras: imágenes de
-- overlay y casas de gremio predefinidas. Si el jugador no pertenece a
-- ninguno de estos gremios, toda esta capa queda inerte y el addon se
-- comporta como un producto 100% genérico: sin opciones extra en el panel,
-- sin texturas propias y sin datos de terceros aplicados.
EZOTools_GuildPack = EZOTools_GuildPack or {}

local MOD = EZOTools_GuildPack

-- Lista blanca. La clave es el nombre del gremio normalizado
-- (minúsculas, espacios colapsados). Para añadir o quitar un gremio
-- amigo basta con tocar esta tabla: nada más en el addon la conoce.
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
    ["children of lamae"] = {
        textures = {
            "/AddOns/EZOTools/media/guild_overlays/children_of_lamae.dds",
            "EZOTools/media/guild_overlays/children_of_lamae.dds",
        },
        friendHouses = { craftingHall = "@HoDPS", secondaryHall = "@LadyRee" },
    },
    ["ad-minions"] = {
        textures = {
            "/AddOns/EZOTools/media/guild_overlays/minion.dds",
            "EZOTools/media/guild_overlays/minion.dds",
        },
        friendHouses = { craftingHall = "@Jogi1", secondaryHall = "@Stucca" },
    },
    ["sombras de lorkhan"] = {
        textures = {
            "/AddOns/EZOTools/media/guild_overlays/sombra.dds",
            "EZOTools/media/guild_overlays/sombra.dds",
        },
        friendHouses = { craftingHall = "@Salander7", secondaryHall = "@RoseDarkSpiryt" },
    },
    ["liga latina"] = {
        textures = {
            "/AddOns/EZOTools/media/guild_overlays/liga_latina.dds",
            "EZOTools/media/guild_overlays/liga_latina.dds",
        },
    },
}

-- Caché del desbloqueo: nil = pendiente de calcular. Se calcula una vez
-- y solo se recalcula cuando el jugador entra/sale de un gremio, para no
-- consultar la lista de gremios en cada refresco del overlay.
local unlockedKeys = nil

local function NormalizarClave(nombre)
    if EZOTools and type(EZOTools.NormalizeGuildKey) == "function" then
        return EZOTools.NormalizeGuildKey(nombre)
    end
    if type(nombre) ~= "string" then return nil end
    nombre = zo_strtrim(nombre)
    if nombre == "" then return nil end
    return zo_strlower(nombre):gsub("%s+", " ")
end

local function RecalcularDesbloqueo()
    unlockedKeys = {}
    if type(GetNumGuilds) ~= "function" then return end
    for i = 1, GetNumGuilds() do
        local guildId = GetGuildId(i)
        local key = NormalizarClave(guildId and GetGuildName(guildId))
        if key and GUILD_PACK[key] then
            unlockedKeys[key] = true
        end
    end
end

local function AsegurarDesbloqueo()
    if unlockedKeys == nil then
        RecalcularDesbloqueo()
    end
    return unlockedKeys
end

-- Invalida la caché; el próximo acceso recalcula con datos frescos.
function MOD.Refresh()
    unlockedKeys = nil
end

-- true si el jugador pertenece a al menos un gremio de la lista blanca.
function MOD.IsUnlocked()
    return next(AsegurarDesbloqueo()) ~= nil
end

function MOD.IsGuildUnlocked(guildName)
    local key = NormalizarClave(guildName)
    if not key then return false end
    return AsegurarDesbloqueo()[key] == true
end

-- Rutas de textura del overlay para un gremio, solo si está desbloqueado.
function MOD.GetTextures(guildName)
    if not MOD.IsGuildUnlocked(guildName) then return nil end
    return GUILD_PACK[NormalizarClave(guildName)].textures
end

-- Casas de gremio predefinidas para un gremio, solo si está desbloqueado.
function MOD.GetFriendHouses(guildName)
    if not MOD.IsGuildUnlocked(guildName) then return nil end
    return GUILD_PACK[NormalizarClave(guildName)].friendHouses
end

-- Mantener la caché al día cuando cambia la pertenencia a gremios.
-- Los datos de gremio pueden llegar después de EVENT_ADD_ON_LOADED,
-- por eso el cálculo es perezoso y estos eventos solo invalidan.
EVENT_MANAGER:RegisterForEvent("EZOTools_GuildPack_Joined",
    EVENT_GUILD_SELF_JOINED_GUILD, function() MOD.Refresh() end)
EVENT_MANAGER:RegisterForEvent("EZOTools_GuildPack_Left",
    EVENT_GUILD_SELF_LEFT_GUILD, function() MOD.Refresh() end)
EVENT_MANAGER:RegisterForEvent("EZOTools_GuildPack_DataLoaded",
    EVENT_GUILD_DATA_LOADED, function() MOD.Refresh() end)
