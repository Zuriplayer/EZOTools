-- Registro de secciones para el panel LibAddonMenu de EZOTools.
-- Los módulos llaman a RegisterSection() para añadir sus opciones.
-- menu.lua las recoge y construye el panel LAM completo.

EZOTools_LAM = EZOTools_LAM or {}
local REG = EZOTools_LAM
REG._sections = REG._sections or {}

local INFO_HEADER_TEXTURE = "EsoUI/Art/Miscellaneous/help_icon.dds"

function REG.CreateInfoHeader(name, tooltip)
    return {
        type = "header",
        name = zo_strformat(
            "<<1>> |cB040FF|t26:26:<<2>>:inheritcolor|t|r",
            tostring(name or ""),
            INFO_HEADER_TEXTURE
        ),
        tooltip = tooltip,
    }
end

function REG.RequestSettingsRefresh(forceRebuild)
    local function RefreshHostedPanel()
        if EZOTools and EZOTools.ezoSettingsRegistered
            and EZOCore
            and type(EZOCore.RefreshSettingsPanel) == "function" then
            pcall(function() EZOCore:RefreshSettingsPanel(forceRebuild == true) end)
        end
    end

    if forceRebuild == true and type(zo_callLater) == "function" then
        zo_callLater(RefreshHostedPanel, 1)
    else
        RefreshHostedPanel()
    end

    local LAM = LibAddonMenu2
    local util = LAM and LAM.util
    if util and type(util.RequestRefreshIfNeeded) == "function" then
        local panel = EZOTools and EZOTools._lamPanel or _G.EZOTools_Panel
        if panel then
            pcall(util.RequestRefreshIfNeeded, panel)
        end
    end
end

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

-- Versión única en shared_utils.lua
local ObtenerColorOverlay = EZOTools_ObtenerColorOverlay

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

local function ObtenerGuildPack()
    return _G.EZOTools_GuildPack
end

local function CombinarTooltips(general, estado)
    if estado == nil or estado == "" then
        return tostring(general or "")
    end
    return zo_strformat("<<1>>|n|n<<2>>", tostring(general or ""), tostring(estado))
end

local function ObtenerDescripcionCasasManuales()
    local estado = ""
    if EZOTools and type(EZOTools.GetActiveFriendHousesDescription) == "function" then
        estado = EZOTools.GetActiveFriendHousesDescription()
    end
    return CombinarTooltips(GetString(EZO_OPTION_FRIENDS_NOTE), estado)
end

local function ObtenerDescripcionModoGuild()
    local pack = ObtenerGuildPack()
    if not pack then
        return GetString(EZO_OPTION_GUILD_MODE_NOTE)
    end
    local entry, _, guildName = nil, nil, nil
    if type(pack.GetRepresentedGuildEntry) == "function" then
        entry, _, guildName = pack.GetRepresentedGuildEntry()
    end
    local estado = entry
        and zo_strformat(GetString(EZO_OPTION_GUILD_MODE_ACTIVE), tostring(guildName or ""))
        or GetString(EZO_OPTION_GUILD_MODE_REPRESENTED_REQUIRED)
    return CombinarTooltips(GetString(EZO_OPTION_GUILD_MODE_NOTE), estado)
end

local function GuardarCasaActual(setterName, successStringId)
    local EZO = EZOTools
    local setter = EZO and EZO[setterName]
    local ok, destination = false, nil
    if type(setter) == "function" then
        ok, destination = setter()
    end

    if EZO and type(EZO.Print) == "function" then
        if ok and type(destination) == "table" then
            local account = tostring(destination.account or "")
            local houseName = tostring(destination.houseName or "")
            local label = account
            if houseName ~= "" then
                label = zo_strformat(GetString(EZO_OPTION_FRIENDS_ACTIVE_HOUSE), houseName, account)
            end
            EZO.Print(zo_strformat(GetString(successStringId), label))
        else
            EZO.Print(GetString(EZO_MSG_FRIEND_HOUSE_CAPTURE_FAILED))
        end
    end
    REG.RequestSettingsRefresh(true)
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
            REG.CreateInfoHeader(GetString(EZO_OPTION_GENERAL), GetString(EZO_OPTION_GENERAL_NOTE)),
            {
                type          = "dropdown",
                name          = GetString(EZO_OPTION_LANGUAGE),
                choices       = {
                    GetString(EZO_OPTION_LANGUAGE_AUTO),
                    "English",
                    "Español",
                },
                choicesValues = { "auto", "en", "es" },
                getFunc       = function()
                    local value = EZO.sv.general.language or (EZO.GetDefaultLanguage and EZO.GetDefaultLanguage()) or "auto"
                    if value == "inherit" then value = "auto" end
                    return value
                end,
                setFunc       = function(v)
                    v = tostring(v or (EZO.GetDefaultLanguage and EZO.GetDefaultLanguage()) or "auto")
                    if v == "inherit" then v = "auto" end
                    EZO.sv.general.language = v
                    if EZO.ApplyLanguagePreference then
                        EZO.ApplyLanguagePreference(v)
                    elseif EZO_Lang and EZO_Lang.Apply then
                        EZO_Lang.Apply(v)
                    end
                    if EZO.IsForcedLanguage and EZO.IsForcedLanguage(v) then
                        AvisarIdiomaForzado()
                    end
                    RefrescarOverlay()
                end,
                disabled = function()
                    local integration = EZO.EZOCoreIntegration
                    return integration
                        and type(integration.IsLanguageManagedByEZOCore) == "function"
                        and integration.IsLanguageManagedByEZOCore()
                end,
                default = (EZO.GetDefaultLanguage and EZO.GetDefaultLanguage()) or "auto",
                width   = "full",
                tooltip = GetString(EZO_OPTION_LANGUAGE_TOOLTIP),
            },
        }
    end)

    REG.RegisterSection("overlay", 10, function()
        local EZO = EZOTools
        return {
            REG.CreateInfoHeader(GetString(EZO_OPTION_OVERLAY), GetString(EZO_OPTION_OVERLAY_NOTE)),
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

    REG.RegisterSection("guild_label", 15, function()
        local EZO = EZOTools
        return {
            REG.CreateInfoHeader(
                GetString(EZO_OPTION_GUILD_LABEL),
                GetString(EZO_OPTION_GUILD_LABEL_NOTE)
            ),
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
            EZO.RefreshActiveFriendHouses(false)
        end
        return {
            REG.CreateInfoHeader(GetString(EZO_OPTION_FRIENDS), ObtenerDescripcionCasasManuales),
            {
                type        = "editbox",
                name        = GetString(EZO_OPTION_FRIENDS_CRAFTING),
                tooltip     = GetString(EZO_OPTION_FRIENDS_CRAFTING_TOOLTIP),
                getFunc     = function()
                    return EZO.GetDisplayedCraftingHall and EZO.GetDisplayedCraftingHall() or ""
                end,
                setFunc     = function(v)
                    if EZO.SetManualCraftingHall then
                        EZO.SetManualCraftingHall(v)
                    end
                end,
                isMultiline = false,
                default     = "",
                width       = "half",
                disabled    = function()
                    return EZO.IsGuildModeEnabled and EZO.IsGuildModeEnabled() == true
                end,
            },
            {
                type        = "editbox",
                name        = GetString(EZO_OPTION_FRIENDS_SECONDARY),
                tooltip     = GetString(EZO_OPTION_FRIENDS_SECONDARY_TOOLTIP),
                getFunc     = function()
                    return EZO.GetDisplayedSecondaryHall and EZO.GetDisplayedSecondaryHall() or ""
                end,
                setFunc     = function(v)
                    if EZO.SetManualSecondaryHall then
                        EZO.SetManualSecondaryHall(v)
                    end
                end,
                isMultiline = false,
                default     = "",
                width       = "half",
                disabled    = function()
                    return EZO.IsGuildModeEnabled and EZO.IsGuildModeEnabled() == true
                end,
            },
            {
                type     = "button",
                name     = GetString(EZO_OPTION_FRIENDS_CAPTURE_CRAFTING),
                tooltip  = GetString(EZO_OPTION_FRIENDS_CAPTURE_CRAFTING_TOOLTIP),
                func     = function()
                    GuardarCasaActual(
                        "SetCurrentHouseAsManualCraftingHall",
                        EZO_MSG_FRIEND_HOUSE_CAPTURED_CRAFTING
                    )
                end,
                width    = "half",
                disabled = function()
                    return EZO.IsGuildModeEnabled and EZO.IsGuildModeEnabled() == true
                end,
            },
            {
                type     = "button",
                name     = GetString(EZO_OPTION_FRIENDS_CAPTURE_SECONDARY),
                tooltip  = GetString(EZO_OPTION_FRIENDS_CAPTURE_SECONDARY_TOOLTIP),
                func     = function()
                    GuardarCasaActual(
                        "SetCurrentHouseAsManualSecondaryHall",
                        EZO_MSG_FRIEND_HOUSE_CAPTURED_SECONDARY
                    )
                end,
                width    = "half",
                disabled = function()
                    return EZO.IsGuildModeEnabled and EZO.IsGuildModeEnabled() == true
                end,
            },
        }
    end)

    REG.RegisterSection("guild_mode", 21, function()
        local EZO = EZOTools
        local pack = ObtenerGuildPack()
        if not (pack and type(pack.IsUnlocked) == "function" and pack.IsUnlocked()) then
            return {}
        end

        return {
            REG.CreateInfoHeader(GetString(EZO_OPTION_GUILD_MODE), ObtenerDescripcionModoGuild),
            {
                type    = "checkbox",
                name    = GetString(EZO_OPTION_GUILD_MODE_ENABLE),
                tooltip = GetString(EZO_OPTION_GUILD_MODE_ENABLE_TOOLTIP),
                getFunc = function()
                    return EZO.IsGuildModeEnabled and EZO.IsGuildModeEnabled() == true
                end,
                setFunc = function(v)
                    if EZO.SetGuildModeEnabled then
                        EZO.SetGuildModeEnabled(v, true)
                    end
                    RefrescarOverlay()
                    REG.RequestSettingsRefresh(true)
                end,
                default = false,
                width   = "full",
            },
        }
    end)

    REG.RegisterSection("group_autoinvite", 22, function()
        local EZO = EZOTools
        EZO.sv = EZO.sv or {}
        EZO.sv.groupAutoinvite = EZO.sv.groupAutoinvite or {}
        return {
            REG.CreateInfoHeader(
                GetString(EZO_OPTION_GROUP_AUTOINVITE),
                GetString(EZO_OPTION_GROUP_AUTOINVITE_NOTE)
            ),
            {
                type = "checkbox",
                name = GetString(EZO_OPTION_GROUP_AUTOINVITE_ENABLED),
                tooltip = GetString(EZO_OPTION_GROUP_AUTOINVITE_ENABLED_TOOLTIP),
                getFunc = function() return EZO.sv.groupAutoinvite.enabled == true end,
                setFunc = function(v) EZO.sv.groupAutoinvite.enabled = v == true end,
                default = false,
                width = "full",
            },
            {
                type = "editbox",
                name = GetString(EZO_OPTION_GROUP_AUTOINVITE_KEYWORDS),
                tooltip = GetString(EZO_OPTION_GROUP_AUTOINVITE_KEYWORDS_TOOLTIP),
                getFunc = function() return tostring(EZO.sv.groupAutoinvite.keywords or "") end,
                setFunc = function(v) EZO.sv.groupAutoinvite.keywords = tostring(v or "") end,
                isMultiline = true,
                default = "",
                width = "full",
            },
        }
    end)

    REG.RegisterSection("group_activity_member_travel", 24, function()
        local EZO = EZOTools
        EZO.sv = EZO.sv or {}
        EZO.sv.groupActivities = EZO.sv.groupActivities or {}
        return {
            REG.CreateInfoHeader(
                GetString(EZO_OPTION_GROUP_MEMBER_TRAVEL),
                GetString(EZO_OPTION_GROUP_MEMBER_TRAVEL_NOTE)
            ),
            {
                type = "checkbox",
                name = GetString(EZO_OPTION_GROUP_MEMBER_TRAVEL_ENABLED),
                tooltip = GetString(EZO_OPTION_GROUP_MEMBER_TRAVEL_ENABLED_TOOLTIP),
                getFunc = function()
                    return EZO.sv.groupActivities.autoTravelToLeaderAfterRegroup == true
                end,
                setFunc = function(value)
                    EZO.sv.groupActivities.autoTravelToLeaderAfterRegroup = value == true
                    local memberTravel = EZO.GroupActivityMemberTravel
                    if memberTravel and type(memberTravel.OnSettingChanged) == "function" then
                        memberTravel.OnSettingChanged(value == true)
                    end
                end,
                default = false,
                width = "full",
            },
        }
    end)

    REG.RegisterSection("raid_leader_reset", 25, function()
        local EZO = EZOTools
        EZO.sv = EZO.sv or {}
        EZO.sv.raidLeaderReset = EZO.sv.raidLeaderReset or {}
        EZO.sv.groupActivities = EZO.sv.groupActivities or {}
        local reset = EZO.RaidLeaderReset
        local function IsResetDisabled()
            return EZO.sv.raidLeaderReset.enabled == false
        end
        local choices, values
        if reset and type(reset.GetDestinationChoices) == "function" then
            choices, values = reset.GetDestinationChoices()
        else
            choices = {
                GetString(EZO_OPTION_INSTANCE_RESET_DESTINATION_PRIMARY),
                GetString(EZO_OPTION_INSTANCE_RESET_DESTINATION_CRAFTING),
                GetString(EZO_OPTION_INSTANCE_RESET_DESTINATION_SECONDARY),
                GetString(EZO_MENU_LEAVE_INSTANCE),
            }
            values = { "primary", "crafting", "secondary", "leave-instance" }
        end
        return {
            REG.CreateInfoHeader(
                GetString(EZO_OPTION_GROUP_ACTIVITIES_DIAGNOSTICS),
                GetString(EZO_OPTION_GROUP_STATUS_AUTO_LOG_TOOLTIP)
            ),
            {
                type = "checkbox",
                name = GetString(EZO_OPTION_GROUP_STATUS_AUTO_LOG),
                tooltip = GetString(EZO_OPTION_GROUP_STATUS_AUTO_LOG_TOOLTIP),
                getFunc = function() return EZO.sv.groupActivities.logGroupStatusOnAction ~= false end,
                setFunc = function(v) EZO.sv.groupActivities.logGroupStatusOnAction = v == true end,
                disabled = function()
                    return not (type(EZO.IsDebugModeEnabled) == "function" and EZO.IsDebugModeEnabled())
                end,
                default = true,
                width = "full",
            },
            REG.CreateInfoHeader(
                GetString(EZO_OPTION_INSTANCE_RESET),
                GetString(EZO_OPTION_INSTANCE_RESET_NOTE)
            ),
            {
                type = "checkbox",
                name = GetString(EZO_OPTION_INSTANCE_RESET_ENABLED),
                tooltip = GetString(EZO_OPTION_INSTANCE_RESET_ENABLED_TOOLTIP),
                getFunc = function() return EZO.sv.raidLeaderReset.enabled ~= false end,
                setFunc = function(v)
                    EZO.sv.raidLeaderReset.enabled = v == true
                    if v ~= true and reset and type(reset.SetStatusWindowUnlocked) == "function" then
                        reset.SetStatusWindowUnlocked(false)
                    end
                    REG.RequestSettingsRefresh()
                end,
                default = true,
                width = "full",
            },
            {
                type = "checkbox",
                name = GetString(EZO_OPTION_INSTANCE_RESET_CONFIRM_ACTIONS),
                tooltip = GetString(EZO_OPTION_INSTANCE_RESET_CONFIRM_ACTIONS_TOOLTIP),
                getFunc = function() return EZO.sv.raidLeaderReset.confirmDangerousActions ~= false end,
                setFunc = function(v) EZO.sv.raidLeaderReset.confirmDangerousActions = v == true end,
                disabled = IsResetDisabled,
                default = true,
                width = "full",
            },
            {
                type = "checkbox",
                name = GetString(EZO_OPTION_INSTANCE_RESET_MOVE_STATUS_WINDOW),
                tooltip = GetString(EZO_OPTION_INSTANCE_RESET_MOVE_STATUS_WINDOW_TOOLTIP),
                getFunc = function()
                    if reset and type(reset.IsStatusWindowUnlocked) == "function" then
                        return reset.IsStatusWindowUnlocked()
                    end
                    return false
                end,
                setFunc = function(v)
                    if reset and type(reset.SetStatusWindowUnlocked) == "function" then
                        reset.SetStatusWindowUnlocked(v)
                    end
                end,
                disabled = IsResetDisabled,
                default = false,
                width = "full",
            },
            {
                type = "dropdown",
                name = GetString(EZO_OPTION_INSTANCE_RESET_DESTINATION),
                tooltip = GetString(EZO_OPTION_INSTANCE_RESET_DESTINATION_TOOLTIP),
                choices = choices,
                choicesValues = values,
                getFunc = function()
                    return EZO.sv.raidLeaderReset.destination or "primary"
                end,
                setFunc = function(v)
                    EZO.sv.raidLeaderReset.destination = tostring(v or "primary")
                end,
                disabled = IsResetDisabled,
                default = "primary",
                width = "full",
            },
            {
                type = "slider",
                name = GetString(EZO_OPTION_INSTANCE_RESET_WAIT_SECONDS),
                tooltip = GetString(EZO_OPTION_INSTANCE_RESET_WAIT_SECONDS_TOOLTIP),
                min = 5, max = 300, step = 5,
                getFunc = function() return tonumber(EZO.sv.raidLeaderReset.waitSeconds) or 30 end,
                setFunc = function(v) EZO.sv.raidLeaderReset.waitSeconds = tonumber(v) or 30 end,
                disabled = IsResetDisabled,
                default = 30,
                width = "half",
            },
            {
                type = "slider",
                name = GetString(EZO_OPTION_INSTANCE_RESET_INVITE_DELAY_SECONDS),
                tooltip = GetString(EZO_OPTION_INSTANCE_RESET_INVITE_DELAY_SECONDS_TOOLTIP),
                min = 0, max = 120, step = 5,
                getFunc = function() return tonumber(EZO.sv.raidLeaderReset.inviteDelaySeconds) or 10 end,
                setFunc = function(v) EZO.sv.raidLeaderReset.inviteDelaySeconds = tonumber(v) or 10 end,
                disabled = IsResetDisabled,
                default = 10,
                width = "half",
            },
            {
                type = "slider",
                name = GetString(EZO_OPTION_INSTANCE_RESET_REINVITE_ATTEMPTS),
                tooltip = GetString(EZO_OPTION_INSTANCE_RESET_REINVITE_ATTEMPTS_TOOLTIP),
                min = 0, max = 5, step = 1,
                getFunc = function() return tonumber(EZO.sv.raidLeaderReset.reinviteAttempts) or 1 end,
                setFunc = function(v) EZO.sv.raidLeaderReset.reinviteAttempts = tonumber(v) or 1 end,
                disabled = IsResetDisabled,
                default = 1,
                width = "half",
            },
            {
                type = "slider",
                name = GetString(EZO_OPTION_INSTANCE_RESET_REINVITE_DELAY_SECONDS),
                tooltip = GetString(EZO_OPTION_INSTANCE_RESET_REINVITE_DELAY_SECONDS_TOOLTIP),
                min = 10, max = 300, step = 10,
                getFunc = function() return tonumber(EZO.sv.raidLeaderReset.reinviteDelaySeconds) or 30 end,
                setFunc = function(v) EZO.sv.raidLeaderReset.reinviteDelaySeconds = tonumber(v) or 30 end,
                disabled = IsResetDisabled,
                default = 30,
                width = "half",
            },
        }
    end)
end

RegistrarSeccionesBase()
