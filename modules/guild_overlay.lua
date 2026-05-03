-- Logica de guild representada/tabardo e imagen asociada al overlay.
-- El modulo visual sigue aplicando colores y texturas sobre sus controles.
EZOTools = EZOTools or {}

EZOTools_GuildOverlay = EZOTools_GuildOverlay or {}

local MOD = EZOTools_GuildOverlay
local EZO = EZOTools

local DEFAULT_OVERLAY_TEXTURES = {
    "/AddOns/EZOTools/media/ezotools_logo.dds",
    "/AddOns/EZOTools/Media/ezotools_logo.dds",
    "EZOTools/media/ezotools_logo.dds",
    "EZOTools/Media/ezotools_logo.dds",
}

local GUILD_OVERLAY_TEXTURES = {
    ["children of lamae"] = {
        "/AddOns/EZOTools/media/guild_overlays/children_of_lamae.dds",
        "EZOTools/media/guild_overlays/children_of_lamae.dds",
    },
    ["fuego"] = {
        "/AddOns/EZOTools/media/guild_overlays/fuego.dds",
        "EZOTools/media/guild_overlays/fuego.dds",
    },
    ["hojablanca"] = {
        "/AddOns/EZOTools/media/guild_overlays/hojablanca.dds",
        "EZOTools/media/guild_overlays/hojablanca.dds",
    },
    ["liga latina"] = {
        "/AddOns/EZOTools/media/guild_overlays/liga_latina.dds",
        "EZOTools/media/guild_overlays/liga_latina.dds",
    },
    ["ad-minions"] = {
        "/AddOns/EZOTools/media/guild_overlays/minion.dds",
        "EZOTools/media/guild_overlays/minion.dds",
    },
    ["sombras de lorkhan"] = {
        "/AddOns/EZOTools/media/guild_overlays/sombra.dds",
        "EZOTools/media/guild_overlays/sombra.dds",
    },
}

local function NormalizarClaveGuild(nombre)
    if EZO and type(EZO.NormalizeGuildKey) == "function" then
        return EZO.NormalizeGuildKey(nombre)
    end
    if type(nombre) ~= "string" then return nil end
    nombre = zo_strtrim(nombre)
    if nombre == "" then return nil end
    nombre = zo_strlower(nombre)
    nombre = nombre:gsub("%s+", " ")
    return nombre
end

function MOD.GetTabardGuildName()
    if type(IsPlayerWearingGuildTabard) == "function" then
        if not IsPlayerWearingGuildTabard() then return nil end
    end

    local slotTabard = EQUIP_SLOT_TABARD or 10
    if type(GetItemType) == "function" then
        local itemType = GetItemType(BAG_WORN, slotTabard)
        if itemType ~= ITEMTYPE_TABARD then return nil end
    end

    if type(GetItemLink) == "function" and type(GetItemLinkGuildName) == "function" then
        local link = GetItemLink(BAG_WORN, slotTabard, LINK_STYLE_DEFAULT)
        if link and link ~= "" then
            local guildName = GetItemLinkGuildName(link)
            if guildName and guildName ~= "" then return guildName end
        end
    end

    return ""
end

function MOD.GetRepresentedGuildName()
    if type(GetRepresentedGuildId) ~= "function" then return nil end
    local guildId = GetRepresentedGuildId()
    if not guildId or guildId == 0 then return nil end
    if type(GetGuildName) ~= "function" then return nil end
    return GetGuildName(guildId)
end

function MOD.GetRepresentedGuildTexturePaths()
    if not (EZO.sv and EZO.sv.overlay and EZO.sv.overlay.guildCustomImageEnabled == true) then
        return nil
    end
    if MOD.GetTabardGuildName() ~= nil then
        return nil
    end
    local guildName = MOD.GetRepresentedGuildName()
    local guildKey = NormalizarClaveGuild(guildName)
    if not guildKey then return nil end
    return GUILD_OVERLAY_TEXTURES[guildKey]
end

function MOD.GetCentralTexturePaths()
    local guildPaths = MOD.GetRepresentedGuildTexturePaths()
    if type(guildPaths) == "table" and #guildPaths > 0 then
        return guildPaths, DEFAULT_OVERLAY_TEXTURES
    end
    return DEFAULT_OVERLAY_TEXTURES, nil
end
