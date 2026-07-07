-- Módulo principal de EZOTools.
-- Gestiona la inicialización, variables guardadas, acciones de viaje/grupo/mantenimiento
-- y registro de comandos de chat.
EZOTools = EZOTools or {}
local EZO = EZOTools
local ADDON_NAME = "EZOTools"
local LANGUAGE_AUTO = "auto"
EZO.runtime = EZO.runtime or {}
EZO.runtime.debugMode = EZO.runtime.debugMode == true

-- Función de chat unificada: usa LibChatMessage si está disponible, si no d()
local function safeChat(msg)
    if LibChatMessage then
        LibChatMessage(ADDON_NAME, "EZO"):Print(tostring(msg))
    else
        d(tostring(msg))
    end
end

-- Guardamos safeChat en el namespace para que otros módulos puedan usarla
EZO.Print = safeChat

function EZO.IsDebugModeEnabled()
    return EZO.runtime and EZO.runtime.debugMode == true
end

function EZO.SetDebugModeEnabled(enabled)
    EZO.runtime = EZO.runtime or {}
    enabled = enabled == true
    EZO.runtime.debugMode = enabled
    if EZO.sv and EZO.sv.general then
        EZO.sv.general.debugMode = enabled
    end

    if (not enabled)
        and EZO.sv
        and EZOTools_Overlay
        and type(EZOTools_Overlay.SetFoodDebugState) == "function" then
        EZOTools_Overlay.SetFoodDebugState("auto")
    end
end

local function ObtenerIdiomaPorDefectoCliente()
    if type(GetCVar) == "function" then
        local lang = zo_strlower(tostring(GetCVar("Language.2") or ""))
        local prefix = lang:sub(1, 2)
        if prefix == "es" then
            return "es"
        end
        if prefix == "en" then
            return "en"
        end
    end
    return "en"
end

function EZO.GetDefaultLanguage()
    return LANGUAGE_AUTO
end

function EZO.GetClientLanguage()
    return ObtenerIdiomaPorDefectoCliente()
end

function EZO.GetEffectiveLanguage(language)
    language = tostring(language or LANGUAGE_AUTO)
    if language == "es" or language == "en" then
        return language
    end
    return ObtenerIdiomaPorDefectoCliente()
end

function EZO.IsForcedLanguage(language)
    language = tostring(language or LANGUAGE_AUTO)
    return language == "es" or language == "en"
end

local function MergeUniqueNumberHistory(target, source, key, maxItems)
    if type(target) ~= "table" or type(source) ~= "table" then return end
    if type(source[key]) ~= "table" then return end

    local merged = {}
    local seen = {}
    local limit = math.max(1, tonumber(maxItems) or 5)

    local function AddValue(value)
        value = tonumber(value) or 0
        if value <= 0 or seen[value] then
            return
        end
        seen[value] = true
        merged[#merged + 1] = value
    end

    if type(target[key]) == "table" then
        for _, value in ipairs(target[key]) do
            AddValue(value)
            if #merged >= limit then break end
        end
    end

    if #merged < limit then
        for _, value in ipairs(source[key]) do
            AddValue(value)
            if #merged >= limit then break end
        end
    end

    target[key] = merged
end

local function MigrateLegacyCharacterOverlayData(csvOverlay, accountOverlay)
    if type(csvOverlay) ~= "table" or type(accountOverlay) ~= "table" then
        return
    end

    if (tonumber(accountOverlay.lastCompanionCollectibleId) or 0) == 0 then
        local companionId = tonumber(csvOverlay.lastCompanionCollectibleId) or 0
        if companionId > 0 then
            accountOverlay.lastCompanionCollectibleId = companionId
        end
    end

    MergeUniqueNumberHistory(accountOverlay, csvOverlay, "recentCompanionCollectibles", 5)
end

function EZO:Initialize()
    local world = GetWorldName()
    local manualFriendHouseProfileKey = EZO.FRIEND_HOUSE_MANUAL_PROFILE_KEY or "__manual"
    EZO.runtime = EZO.runtime or {}

    -- Valores por defecto de las variables guardadas (por cuenta y mundo)
    local defaults = {
        general = {
            language          = LANGUAGE_AUTO,
            debugMode         = false,
            repairThreshold   = 25,
            rechargeThreshold = 25,
            repairKitAlertEnabled   = true,
            repairKitAlertThreshold = 25,
            soulGemAlertEnabled     = true,
            soulGemAlertThreshold   = 25,
        },
        overlay = {
            enabled          = true,
            alpha            = 1.0,
            scale            = 1.0,
            text             = "EZOTools",
            contextualIconTooltips = true,
            playerTextScale  = 1.0,
            playerTextColor  = { 1, 1, 1, 1 },
            guildLabelColor  = { 0.7, 0.7, 0.7, 1 },
            hideNoGuildLabel = false,
            guildCustomImageEnabled = false,
            simulateGamepad  = false,
            hideInCombat     = false,
            locked           = false,
            lastMountCollectibleId = 0,
            lastPetCollectibleId = 0,
            lastCompanionCollectibleId = 0,
            lastAssistantCollectibleId = 0,
            recentMountCollectibles = {},
            recentPetCollectibles = {},
            recentCompanionCollectibles = {},
            recentAssistantCollectibles = {},
            recentOwnHouses = {},
            recentOtherHouses = {},
            x                = nil,
            y                = nil,
        },
        friends = {
            craftingHall   = "",
            secondaryHall  = "",
            manualCraftingHall = "",
            manualSecondaryHall = "",
            editCraftingHall = "",
            editSecondaryHall = "",
            manualFriendHousesMigrated = false,
            autoAssignFriendHouses = false,
            autoAssignFriendGuildKey = "",
            manualActiveFriendHouseProfileKey = manualFriendHouseProfileKey,
            manualActiveFriendHouseProfileInitialized = true,
            friendHouseProfileKey = manualFriendHouseProfileKey,
            fuegoFriendHouseDefaultMigrated = false,
            customGuildFriendHouses = {},
        },
    }

    local charDefaults = {
        overlay = {
            lastCompanionCollectibleId = 0,
            recentCompanionCollectibles = {},
            lastFoodItemLink = "",
            lastFoodItemName = "",
            recentFoodItems = {},
        },
    }

    self.sv = ZO_SavedVars:NewAccountWide("EZOTools_Saved", 1, world, defaults)
    self.csv = ZO_SavedVars:NewCharacterIdSettings("EZOTools_SavedChar", 1, world, charDefaults)
    MigrateLegacyCharacterOverlayData(self.csv and self.csv.overlay, self.sv and self.sv.overlay)
    EZO.runtime.debugMode = self.sv and self.sv.general and self.sv.general.debugMode == true

    -- Aplicar idioma guardado
    if EZO_Lang and EZO_Lang.Apply then
        EZO_Lang.Apply(self.sv.general.language or LANGUAGE_AUTO)
    end

    -- Si el texto del overlay sigue siendo el placeholder de fábrica, usar el nombre de cuenta.
    -- GetDisplayName() devuelve "@NombreCuenta" del jugador — lo más útil como texto por defecto.
    if not self.sv.overlay.text or self.sv.overlay.text == "EZOTools" then
        self.sv.overlay.text = GetDisplayName() or GetString(EZO_MSG_INIT)
    end

    if self.sv.friends and self.sv.friends.manualFriendHousesMigrated ~= true then
        self.sv.friends.manualCraftingHall = tostring(self.sv.friends.craftingHall or "")
        self.sv.friends.manualSecondaryHall = tostring(self.sv.friends.secondaryHall or "")
        self.sv.friends.manualFriendHousesMigrated = true
    end
    if EZO.MigrateLegacyFriendHouseProfiles then
        EZO.MigrateLegacyFriendHouseProfiles(self.sv.friends)
    end
    if self.sv.friends and (not self.sv.friends.friendHouseProfileKey or self.sv.friends.friendHouseProfileKey == "") then
        self.sv.friends.friendHouseProfileKey = manualFriendHouseProfileKey
    end
    if self.sv.friends and self.sv.friends.manualActiveFriendHouseProfileInitialized ~= true then
        self.sv.friends.manualActiveFriendHouseProfileKey = manualFriendHouseProfileKey
        self.sv.friends.manualActiveFriendHouseProfileInitialized = true
    elseif self.sv.friends and (not self.sv.friends.manualActiveFriendHouseProfileKey or self.sv.friends.manualActiveFriendHouseProfileKey == "") then
        self.sv.friends.manualActiveFriendHouseProfileKey = manualFriendHouseProfileKey
    end
    do
        local profileKey = tostring(self.sv.friends.friendHouseProfileKey or "")
        if EZO.IsFriendHouseProfileKeyValid and not EZO.IsFriendHouseProfileKeyValid(profileKey) then
            self.sv.friends.friendHouseProfileKey = manualFriendHouseProfileKey
        end

        local manualActiveProfileKey = tostring(self.sv.friends.manualActiveFriendHouseProfileKey or "")
        if EZO.IsFriendHouseProfileKeyValid and not EZO.IsFriendHouseProfileKeyValid(manualActiveProfileKey) then
            self.sv.friends.manualActiveFriendHouseProfileKey = manualFriendHouseProfileKey
        end

        local oldGuildKey = EZO.NormalizeGuildKey and EZO.NormalizeGuildKey(self.sv.friends.autoAssignFriendGuildKey) or nil
        if oldGuildKey and EZO.IsPlayerGuildKey and not EZO.IsPlayerGuildKey(oldGuildKey) then
            self.sv.friends.autoAssignFriendGuildKey = ""
        end

    end
    if self.sv.friends and EZO.LoadSelectedFriendHouseProfileForEditing then
        EZO.LoadSelectedFriendHouseProfileForEditing()
    end

    if self.RefreshActiveFriendHouses then
        self.RefreshActiveFriendHouses()
    end

    -- Inicializar submódulos en orden
    if EZOTools_Menu      and EZOTools_Menu.Init      then EZOTools_Menu.Init()      end
    if EZOTools_QuickUtilityHouses and EZOTools_QuickUtilityHouses.Init then
        EZOTools_QuickUtilityHouses.Init()
    end
    if EZOTools_Overlay   and EZOTools_Overlay.Init   then EZOTools_Overlay.Init()   end
    if EZOTools_Keybinds  and EZOTools_Keybinds.Init  then EZOTools_Keybinds.Init()  end
    if EZOTools_KeyboardEnterOverride and EZOTools_KeyboardEnterOverride.Init then
        EZOTools_KeyboardEnterOverride.Init()
    end

    safeChat(GetString(EZO_MSG_INIT))

    if self.RegisterSlashCommands then self:RegisterSlashCommands() end

end

-- ============================================================
-- Registro de eventos principales
-- ============================================================

-- Inicialización al cargar el addon
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, function(_, name)
    if name == ADDON_NAME then
        EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
        EZOTools:Initialize()
    end
end)

-- Refrescar el overlay cada vez que el jugador se activa (cambio de zona, reloadui, login).
-- Se mantiene registrado permanentemente porque el overlay puede necesitar actualizarse
-- al volver de una instancia, cambiar de zona, etc.
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, function()
    local function refrescarOverlay()
        if EZOTools_Overlay and EZOTools_Overlay.Refresh then
            EZOTools_Overlay.Refresh()
        end
        -- Refrescar dot al activar — EVENT_INVENTORY_SINGLE_SLOT_UPDATE cubre cambios en tiempo real
        if EZOTools_Overlay and EZOTools_Overlay.RefreshDot then
            EZOTools_Overlay.RefreshDot()
        end
    end
    refrescarOverlay()
    if type(zo_callLater) == "function" then
        zo_callLater(refrescarOverlay, 500)
        zo_callLater(refrescarOverlay, 1500)
    end
end)

-- ============================================================
-- Funciones de toggle (usadas por keybinds y menú)
-- ============================================================

function EZOTools.ReloadUIBinding() ReloadUI() end

function EZOTools.ToggleOverlay()
    if EZOTools_Overlay and EZOTools_Overlay.Toggle then EZOTools_Overlay.Toggle() end
end

-- ============================================================
-- Comandos de chat (/ezo, /ezotools)
-- ============================================================

local function _mostrarAyudaPrincipal()
    safeChat(GetString(EZO_CMD_HELP_TITLE))
    safeChat(GetString(EZO_CMD_HELP_STATUS))
    if EZO.IsDebugModeEnabled() then
        safeChat(GetString(EZO_CMD_HELP_DEBUG))
    end
    safeChat(GetString(EZO_CMD_HELP_ABOUT))
    safeChat(GetString(EZO_CMD_HELP_HELP))
end

-- Información de autor y contacto. También la usa la entrada
-- "Acerca de EZOTools" del diálogo de ajustes gamepad.
function EZO.ShowAboutInfo()
    safeChat(zo_strformat(GetString(EZO_CMD_BANNER), EZOTools.ADDON_VERSION))
    safeChat(GetString(EZO_CMD_ABOUT_AUTHOR))
    safeChat(zo_strformat(GetString(EZO_CMD_ABOUT_DISCORD), tostring(EZOTools.CONTACT_DISCORD or "")))
end

local function _mostrarAyudaDetallada()
    _mostrarAyudaPrincipal()
    safeChat(GetString(EZO_CMD_HELP_DETAIL_STATUS))
    if EZO.IsDebugModeEnabled() then
        safeChat(GetString(EZO_CMD_HELP_DETAIL_DEBUG))
    end
    safeChat(GetString(EZO_CMD_HELP_CONTACT))
end

local function _comandoVersion()
    local lang = (EZO_Lang and EZO_Lang.current) or (EZOTools.sv and EZOTools.sv.general and EZOTools.sv.general.language) or "?"
    local lam = (_G.LibAddonMenu2 and "yes") or "no"
    local overlay = (EZOTools_Overlay and EZOTools_Overlay.Refresh and "yes") or "no"
    local gamepad = (EZOTools.GamepadDialog and EZOTools.GamepadDialog.Open and "yes") or "no"
    local apiVersion = (type(GetAPIVersion) == "function" and tostring(GetAPIVersion())) or "n/a"

    safeChat(zo_strformat(GetString(EZO_CMD_VERSION_HEADER), EZOTools.ADDON_VERSION))
    safeChat(zo_strformat(GetString(EZO_CMD_VERSION_API), apiVersion))
    safeChat(zo_strformat(GetString(EZO_CMD_VERSION_LANGUAGE), tostring(lang)))
    safeChat(zo_strformat(GetString(EZO_CMD_VERSION_LAM), lam))
    safeChat(zo_strformat(GetString(EZO_CMD_VERSION_OVERLAY), overlay))
    safeChat(zo_strformat(GetString(EZO_CMD_VERSION_GAMEPAD), gamepad))
end

local function _manejadorSlash(arg)
    local trimmed = zo_strtrim(tostring(arg or ""))
    if trimmed == "" then
        safeChat(zo_strformat(GetString(EZO_CMD_BANNER), EZOTools.ADDON_VERSION))
        _mostrarAyudaPrincipal()
        return
    end
    local a1, a2, a3 = zo_strsplit(" ", trimmed)
    a1 = zo_strlower(a1 or "")
    a2 = zo_strlower(a2 or "")
    a3 = zo_strlower(a3 or "")
    if a1 == "help" or a1 == "?" then
        _mostrarAyudaDetallada(); return
    end
    if a1 == "status" then
        _comandoVersion(); return
    end
    if a1 == "about" then
        EZO.ShowAboutInfo(); return
    end
    if a1 == "debug" then
        if EZO.Debug and type(EZO.Debug.Execute) == "function" then
            EZO.Debug.Execute(a2, a3)
        else
            safeChat(GetString(EZO_MSG_DEBUG_LOGGER_UNAVAILABLE))
        end
        return
    end
    _mostrarAyudaPrincipal()
end

function EZO.RegisterSlashCommands(_self)
    -- Preferir LibSlashCommander si está disponible (autocompletado y mejor UX)
    if LibSlashCommander and LibSlashCommander.Register then
        LibSlashCommander:Register({"/ezo", "/ezotools"}, _manejadorSlash, "EZOTools")
    else
        -- Variante nativa si LibSlashCommander no está disponible.
        SLASH_COMMANDS["/ezo"]      = _manejadorSlash
        SLASH_COMMANDS["/ezotools"] = _manejadorSlash
    end
    safeChat(GetString(EZO_CMD_REGISTERED))
end

-- ============================================================
-- Wrapper para keybind de Bindings.xml
-- ============================================================

-- Bindings.xml llama directamente a esta función global
function EZOTools_ToggleCommandPanel()
    local ezo = _G.EZOTools
    if type(ezo) == "table" and type(ezo.ToggleCommandPanel) == "function" then
        return ezo.ToggleCommandPanel()
    end
    safeChat(GetString(EZO_MSG_CMD_PANEL_MISSING))
end

function EZOTools_ToggleUtilityPanel()
    local ezo = _G.EZOTools
    if type(ezo) == "table" and type(ezo.ToggleUtilityPanel) == "function" then
        return ezo.ToggleUtilityPanel()
    end
    safeChat(GetString(EZO_MSG_UTILITY_PANEL_MISSING))
end

function EZOTools_ToggleGroupActivitiesPanel()
    local ezo = _G.EZOTools
    if type(ezo) == "table" and type(ezo.ToggleGroupActivitiesPanel) == "function" then
        return ezo.ToggleGroupActivitiesPanel()
    end
    safeChat(GetString(EZO_MSG_GROUP_ACTIVITIES_PANEL_MISSING))
end

function EZOTools_ToggleTrialTravelPanel()
    return EZOTools_ToggleGroupActivitiesPanel()
end
