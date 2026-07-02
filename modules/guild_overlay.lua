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
    -- Las imágenes por gremio son contenido del guild pack: solo existen
    -- si el jugador pertenece a un gremio de su lista blanca.
    local pack = _G.EZOTools_GuildPack
    if not (pack and type(pack.GetTextures) == "function") then
        return nil
    end
    return pack.GetTextures(MOD.GetRepresentedGuildName())
end

function MOD.GetCentralTexturePaths()
    local guildPaths = MOD.GetRepresentedGuildTexturePaths()
    if type(guildPaths) == "table" and #guildPaths > 0 then
        return guildPaths, DEFAULT_OVERLAY_TEXTURES
    end
    return DEFAULT_OVERLAY_TEXTURES, nil
end
