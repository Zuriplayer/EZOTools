-- Registro de secciones para el panel LibAddonMenu de EZOTools.
-- Los módulos llaman a RegisterSection() para añadir sus opciones.
-- menu.lua las recoge y construye el panel LAM completo.

EZOTools_LAM = EZOTools_LAM or {}
local REG = EZOTools_LAM
REG._sections = REG._sections or {}

-- Registra una sección de opciones.
-- name:     identificador único de la sección
-- order:    número de orden (menor = antes)
-- provider: función que devuelve la tabla de opciones LAM
function REG.RegisterSection(name, order, provider)
    REG._sections[name] = { order = order or 100, provider = provider }
end

-- Devuelve todas las opciones de todas las secciones ordenadas por 'order'
function REG.GetSortedOptions()
    local lista = {}
    for k, v in pairs(REG._sections) do
        lista[#lista + 1] = { name = k, order = v.order, provider = v.provider }
    end
    table.sort(lista, function(a, b) return a.order < b.order end)

    local opciones = {}
    for _, s in ipairs(lista) do
        local ok, contenido = pcall(s.provider)
        if ok and type(contenido) == "table" then
            for _, x in ipairs(contenido) do
                opciones[#opciones + 1] = x
            end
        end
    end
    return opciones
end

local PLAYER_TEXT_SCALE_MIN = 0.6
local PLAYER_TEXT_SCALE_MAX = 1.0

local function ObtenerColorOverlay(configValue, fallback)
    if type(configValue) == "table" then
        local r = tonumber(configValue[1])
        local g = tonumber(configValue[2])
        local b = tonumber(configValue[3])
        local a = tonumber(configValue[4])
        if r and g and b then
            return r, g, b, a or 1
        end
    end
    return fallback[1], fallback[2], fallback[3], fallback[4]
end

local function ObtenerTextoOverlay()
    local EZO = EZOTools
    local t = EZO and EZO.sv and EZO.sv.overlay and EZO.sv.overlay.text
    if t == nil or (type(t) == "string" and t:match("^%s*$")) then
        return GetDisplayName() or GetString(EZO_MSG_INIT)
    end
    return tostring(t)
end

local function RefrescarOverlay()
    if EZOTools_Overlay and type(EZOTools_Overlay.Refresh) == "function" then
        EZOTools_Overlay.Refresh()
    end
end

local ultimoAvisoIdiomaForzadoMs = 0

local function AvisarIdiomaForzado()
    local nowMs = type(GetGameTimeMilliseconds) == "function" and GetGameTimeMilliseconds() or 0
    if nowMs > 0 and (nowMs - ultimoAvisoIdiomaForzadoMs) < 1000 then
        return
    end
    ultimoAvisoIdiomaForzadoMs = nowMs

    local warningStringId = _G.EZO_MSG_LANGUAGE_FORCED_WARNING
    if EZOTools and type(EZOTools.Print) == "function" and warningStringId ~= nil then
        EZOTools.Print(GetString(warningStringId))
    end
end

local function RegistrarSeccionesBase()
    if REG._baseSectionsRegistered then
        return
    end
    REG._baseSectionsRegistered = true

    REG.RegisterSection("general", 1, function()
        local EZO = EZOTools
        return {
            { type = "header", name = GetString(EZO_OPTION_GENERAL) },
            {
                type          = "dropdown",
                name          = GetString(EZO_OPTION_LANGUAGE),
                choices       = { GetString(EZO_OPTION_LANGUAGE_AUTO), "English", "Español" },
                choicesValues = { "auto", "en", "es" },
                getFunc       = function() return EZO.sv.general.language or "auto" end,
                setFunc       = function(v)
                    v = tostring(v or "auto")
                    EZO.sv.general.language = v
                    if EZO_Lang and EZO_Lang.Apply then EZO_Lang.Apply(v) end
                    if EZO.IsForcedLanguage and EZO.IsForcedLanguage(v) then
                        AvisarIdiomaForzado()
                    end
                    RefrescarOverlay()
                end,
                default = (EZO.GetDefaultLanguage and EZO.GetDefaultLanguage()) or "auto",
                width   = "half",
                tooltip = GetString(EZO_OPTION_LANGUAGE_TOOLTIP),
            },
        }
    end)

    REG.RegisterSection("overlay", 10, function()
        local EZO = EZOTools
        return {
            { type = "header", name = GetString(EZO_OPTION_OVERLAY) },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_OVERLAY_ENABLE),
                getFunc = function() return EZO.sv.overlay.enabled end,
                setFunc = function(v) EZO.sv.overlay.enabled = v; RefrescarOverlay() end,
                default = true,
            },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_OVERLAY_LOCK),
                getFunc = function() return EZO.sv.overlay.locked end,
                setFunc = function(v)
                    if EZOTools_Overlay and type(EZOTools_Overlay.SetLocked) == "function" then
                        EZOTools_Overlay.SetLocked(v)
                    end
                    RefrescarOverlay()
                end,
                default = false,
            },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_OVERLAY_SIMULATE_GAMEPAD),
                getFunc = function() return EZO.sv.overlay.simulateGamepad end,
                setFunc = function(v) EZO.sv.overlay.simulateGamepad = v; RefrescarOverlay() end,
                default = false,
            },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_OVERLAY_HIDE_COMBAT),
                getFunc = function() return EZO.sv.overlay.hideInCombat end,
                setFunc = function(v) EZO.sv.overlay.hideInCombat = v; RefrescarOverlay() end,
                default = false,
            },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_OVERLAY_CONTEXTUAL_TOOLTIPS),
                tooltip = GetString(EZO_OPTION_OVERLAY_CONTEXTUAL_TOOLTIPS_TOOLTIP),
                getFunc = function() return EZO.sv.overlay.contextualIconTooltips ~= false end,
                setFunc = function(v)
                    EZO.sv.overlay.contextualIconTooltips = v and true or false
                    RefrescarOverlay()
                end,
                default = true,
            },
            {
                type     = "slider",
                name     = GetString(EZO_OPTION_OVERLAY_SCALE),
                min      = 0.5, max = 2.0, step = 0.1,
                getFunc  = function() return EZO.sv.overlay.scale end,
                setFunc  = function(v) EZO.sv.overlay.scale = v; RefrescarOverlay() end,
                decimals = 2,
            },
            {
                type    = "colorpicker",
                name    = GetString(EZO_OPTION_OVERLAY_PLAYER_TEXT_COLOR),
                getFunc = function()
                    return ObtenerColorOverlay(EZO.sv.overlay.playerTextColor, { 1, 1, 1, 1 })
                end,
                setFunc = function(r, g, b, a)
                    EZO.sv.overlay.playerTextColor = { r, g, b, a or 1 }
                    RefrescarOverlay()
                end,
                default = { 1, 1, 1, 1 },
            },
            {
                type     = "slider",
                name     = GetString(EZO_OPTION_OVERLAY_PLAYER_TEXT_SIZE),
                min      = PLAYER_TEXT_SCALE_MIN, max = PLAYER_TEXT_SCALE_MAX, step = 0.05,
                getFunc  = function() return tonumber(EZO.sv.overlay.playerTextScale) or 1 end,
                setFunc  = function(v)
                    EZO.sv.overlay.playerTextScale = zo_clamp(tonumber(v) or 1, PLAYER_TEXT_SCALE_MIN, PLAYER_TEXT_SCALE_MAX)
                    RefrescarOverlay()
                end,
                default  = 1,
                decimals = 2,
            },
            {
                type        = "editbox",
                name        = GetString(EZO_OPTION_OVERLAY_TEXT),
                getFunc     = function() return ObtenerTextoOverlay() end,
                setFunc     = function(v)
                    if v == nil or (type(v) == "string" and v:match("^%s*$")) then
                        EZO.sv.overlay.text = nil
                    else
                        EZO.sv.overlay.text = v
                    end
                    RefrescarOverlay()
                end,
                isMultiline = false,
            },
            {
                type    = "button",
                name    = GetString(EZO_OPTION_OVERLAY_RESET_POS),
                tooltip = GetString(EZO_OPTION_OVERLAY_RESET_POS_TOOLTIP),
                func    = function()
                    if EZOTools_Overlay and type(EZOTools_Overlay.ResetPosition) == "function" then
                        EZOTools_Overlay.ResetPosition()
                    end
                    RefrescarOverlay()
                end,
                width   = "full",
            },
        }
    end)

    REG.RegisterSection("guild_overlay", 15, function()
        local EZO = EZOTools
        return {
            { type = "header", name = GetString(EZO_OPTION_GUILD_OVERLAY) },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE),
                tooltip = GetString(EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE_TOOLTIP),
                getFunc = function() return EZO.sv.overlay.guildCustomImageEnabled == true end,
                setFunc = function(v)
                    EZO.sv.overlay.guildCustomImageEnabled = v
                    RefrescarOverlay()
                end,
                default = false,
                width   = "full",
            },
            {
                type    = "colorpicker",
                name    = GetString(EZO_OPTION_GUILD_LABEL_COLOR),
                tooltip = GetString(EZO_OPTION_GUILD_LABEL_COLOR_TOOLTIP),
                getFunc = function()
                    return ObtenerColorOverlay(EZO.sv.overlay.guildLabelColor, { 0.7, 0.7, 0.7, 1 })
                end,
                setFunc = function(r, g, b, a)
                    EZO.sv.overlay.guildLabelColor = { r, g, b, a or 1 }
                    RefrescarOverlay()
                end,
                default = { 0.7, 0.7, 0.7, 1 },
            },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_GUILD_HIDE_NO_GUILD),
                tooltip = GetString(EZO_OPTION_GUILD_HIDE_NO_GUILD_TOOLTIP),
                getFunc = function() return EZO.sv.overlay.hideNoGuildLabel == true end,
                setFunc = function(v)
                    EZO.sv.overlay.hideNoGuildLabel = v == true
                    RefrescarOverlay()
                end,
                default = false,
                width   = "full",
            },
        }
    end)

    REG.RegisterSection("friend_houses", 20, function()
        local EZO = EZOTools
        if EZO.RefreshActiveFriendHouses then
            EZO.RefreshActiveFriendHouses()
        end
        return {
            { type = "header", name = GetString(EZO_OPTION_FRIENDS) },
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_FRIENDS_AUTO_ASSIGN),
                tooltip = GetString(EZO_OPTION_FRIENDS_AUTO_ASSIGN_TOOLTIP),
                getFunc = function() return EZO.sv.friends.autoAssignFriendHouses == true end,
                setFunc = function(v)
                    EZO.sv.friends.autoAssignFriendHouses = v
                    if v == false then
                        if EZO.ResetFriendHouseProfileDefaults then
                            EZO.ResetFriendHouseProfileDefaults()
                        elseif EZO.ApplyManualFriendHouseProfileSelection then
                            EZO.sv.friends.manualActiveFriendHouseProfileKey = EZO.FRIEND_HOUSE_MANUAL_PROFILE_KEY or "__manual"
                            EZO.ApplyManualFriendHouseProfileSelection()
                        end
                    elseif EZO.ApplyAutoFriendHousesSelection then
                        EZO.ApplyAutoFriendHousesSelection()
                    end
                end,
                default = false,
                width   = "full",
            },
            {
                type = "description",
                text = function()
                    if EZO.sv and EZO.sv.friends and EZO.sv.friends.autoAssignFriendHouses ~= true then
                        local manualKey = EZO.FRIEND_HOUSE_MANUAL_PROFILE_KEY or "__manual"
                        if tostring(EZO.sv.friends.manualActiveFriendHouseProfileKey or "") == "" then
                            EZO.sv.friends.manualActiveFriendHouseProfileKey = manualKey
                        end
                    end
                    if EZO.GetActiveFriendHousesDescription then
                        return EZO.GetActiveFriendHousesDescription()
                    end
                    return ""
                end,
                width = "full",
            },
            {
                type          = "dropdown",
                name          = GetString(EZO_OPTION_FRIENDS_MANUAL_ACTIVE_PROFILE),
                tooltip       = GetString(EZO_OPTION_FRIENDS_MANUAL_ACTIVE_PROFILE_TOOLTIP),
                choices       = (function()
                    if EZO.GetFriendHouseProfileChoices then
                        return EZO.GetFriendHouseProfileChoices()
                    end
                    return {}
                end)(),
                choicesValues = (function()
                    if EZO.GetFriendHouseProfileChoices then
                        local _, values = EZO.GetFriendHouseProfileChoices()
                        return values
                    end
                    return {}
                end)(),
                getFunc       = function() return EZO.sv.friends.manualActiveFriendHouseProfileKey or EZO.FRIEND_HOUSE_MANUAL_PROFILE_KEY or "__manual" end,
                setFunc       = function(v)
                    EZO.sv.friends.manualActiveFriendHouseProfileKey = tostring(v or EZO.FRIEND_HOUSE_MANUAL_PROFILE_KEY or "__manual")
                    EZO.sv.friends.manualActiveFriendHouseProfileInitialized = true
                    if EZO.sv.friends.autoAssignFriendHouses ~= true and EZO.ApplyManualFriendHouseProfileSelection then
                        EZO.ApplyManualFriendHouseProfileSelection()
                    end
                end,
                default       = EZO.FRIEND_HOUSE_MANUAL_PROFILE_KEY or "__manual",
                disabled      = function()
                    return EZO.sv.friends.autoAssignFriendHouses == true
                end,
            },
            {
                type = "description",
                text = GetString(EZO_OPTION_FRIENDS_EDIT_PROFILE_NOTE),
            },
            {
                type          = "dropdown",
                name          = GetString(EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD),
                tooltip       = GetString(EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD_TOOLTIP),
                choices       = (function()
                    if EZO.GetFriendHouseProfileChoices then
                        return EZO.GetFriendHouseProfileChoices()
                    end
                    return {}
                end)(),
                choicesValues = (function()
                    if EZO.GetFriendHouseProfileChoices then
                        local _, values = EZO.GetFriendHouseProfileChoices()
                        return values
                    end
                    return {}
                end)(),
                getFunc       = function() return EZO.sv.friends.friendHouseProfileKey or EZO.FRIEND_HOUSE_MANUAL_PROFILE_KEY or "__manual" end,
                setFunc       = function(v)
                    EZO.sv.friends.friendHouseProfileKey = tostring(v or EZO.FRIEND_HOUSE_MANUAL_PROFILE_KEY or "__manual")
                    if EZO.LoadSelectedFriendHouseProfileForEditing then
                        EZO.LoadSelectedFriendHouseProfileForEditing()
                    end
                end,
                default       = EZO.FRIEND_HOUSE_MANUAL_PROFILE_KEY or "__manual",
            },
            {
                type        = "editbox",
                name        = GetString(EZO_OPTION_FRIENDS_CRAFTING),
                getFunc     = function() return EZO.sv.friends.editCraftingHall or "" end,
                setFunc     = function(v)
                    EZO.sv.friends.editCraftingHall = tostring(v or "")
                end,
                isMultiline = false,
                default     = "",
            },
            {
                type        = "editbox",
                name        = GetString(EZO_OPTION_FRIENDS_SECONDARY),
                getFunc     = function() return EZO.sv.friends.editSecondaryHall or "" end,
                setFunc     = function(v)
                    EZO.sv.friends.editSecondaryHall = tostring(v or "")
                end,
                isMultiline = false,
                default     = "",
            },
            {
                type    = "button",
                name    = GetString(EZO_OPTION_FRIENDS_SAVE_SELECTED),
                tooltip = GetString(EZO_OPTION_FRIENDS_SAVE_SELECTED_TOOLTIP),
                func    = function()
                    if EZO.SaveCurrentFriendHousesForSelectedGuild then
                        EZO.SaveCurrentFriendHousesForSelectedGuild()
                    end
                end,
                width   = "full",
            },
        }
    end)
end

RegistrarSeccionesBase()
