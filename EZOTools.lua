-- Módulo principal de EZOTools.
-- Gestiona la inicialización, variables guardadas, acciones de viaje/grupo/mantenimiento
-- y registro de comandos de chat.
EZOTools = EZOTools or {}
local EZO = EZOTools
local ADDON_NAME = "EZOTools"
EZO.runtime = EZO.runtime or {}
EZO.runtime.debugMode = EZO.runtime.debugMode == true

local function RegisterWithEZOBindings()
    if not (EZOBindings and type(EZOBindings.RegisterAddon) == "function") then
        return
    end

    EZOBindings:RegisterAddon(ADDON_NAME, {
        version = 1,
        actions = {
            {
                name = "EZO_TOGGLE_COMMAND_PANEL",
                keyboard = { preferred = "CTRL+ALT+KEY_NUMPAD0" },
                gamepad = {
                    preferred = "KEY_GAMEPAD_BUTTON_3_HOLD",
                    allowNativeReuse = {
                        KEY_GAMEPAD_BUTTON_3_HOLD = {
                            housing = true,
                            ui = true,
                        },
                    },
                },
                priority = 100,
                mode = "global",
            },
            {
                name = "EZO_TOGGLE_UTILITY_PANEL",
                keyboard = { preferred = "CTRL+ALT+KEY_NUMPAD1" },
                gamepad = {
                    preferred = "KEY_GAMEPAD_BUTTON_4_HOLD",
                    allowNativeReuse = {
                        KEY_GAMEPAD_BUTTON_4_HOLD = {
                            ui = true,
                        },
                    },
                },
                priority = 90,
                mode = "global",
            },
            {
                name = "EZO_TRAVEL_PRIMARY_HOUSE",
                keyboard = { preferred = "ALT+KEY_H" },
                mode = "global",
            },
            { name = "EZO_TRAVEL_CRAFTING_HALL", mode = "global" },
            { name = "EZO_TRAVEL_SECONDARY_HALL", mode = "global" },
            { name = "EZO_LEAVE_GROUP", mode = "global" },
            { name = "EZO_LEAVE_INSTANCE", mode = "global" },
            { name = "EZO_LEAVE_GROUP_INSTANCE", mode = "global" },
            {
                name = "EZO_RELOAD_UI",
                keyboard = { preferred = "KEY_NUMPAD_MINUS" },
                mode = "global",
            },
        },
    })
end

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
    return ObtenerIdiomaPorDefectoCliente()
end

local AUTO_FRIEND_HOUSES_BY_GUILD = {
    ["hojablanca"] = {
        craftingHall = "@sunsetlu",
        secondaryHall = "@grukka",
    },
    ["fuego"] = {
        craftingHall = "@Whasabi",
        secondaryHall = "@Whasabi",
    },
    ["children of lamae"] = {
        craftingHall = "@HoDPS",
        secondaryHall = "@LadyRee",
    },
    ["ad-minions"] = {
        craftingHall = "@Jogi1",
        secondaryHall = "@Stucca",
    },
    ["sombras de lorkhan"] = {
        craftingHall = "@Salander7",
        secondaryHall = "@RoseDarkSpiryt",
    },
}

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

function EZO.GetEligibleAutoFriendGuildChoices()
    return EZO.GetPlayerGuildChoices()
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

    local custom = EZO.sv and EZO.sv.friends and EZO.sv.friends.customGuildFriendHouses
    if type(custom) == "table" and type(custom[guildKey]) == "table" then
        return custom[guildKey]
    end

    if type(AUTO_FRIEND_HOUSES_BY_GUILD[guildKey]) == "table" then
        return AUTO_FRIEND_HOUSES_BY_GUILD[guildKey]
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

    if tostring(accountOverlay.lastFoodItemLink or "") == "" then
        local itemLink = tostring(csvOverlay.lastFoodItemLink or "")
        if itemLink ~= "" then
            accountOverlay.lastFoodItemLink = itemLink
        end
    end

    if tostring(accountOverlay.lastFoodItemName or "") == "" then
        local itemName = tostring(csvOverlay.lastFoodItemName or "")
        if itemName ~= "" then
            accountOverlay.lastFoodItemName = itemName
        end
    end

    MergeUniqueNumberHistory(accountOverlay, csvOverlay, "recentCompanionCollectibles", 5)

    if type(csvOverlay.recentFoodItems) == "table" then
        local mergedFood = {}
        local seenFood = {}

        local function AddFood(entry)
            if type(entry) ~= "table" then return end
            local itemLink = tostring(entry.itemLink or "")
            local itemName = tostring(entry.itemName or "")
            local key = (itemLink ~= "") and itemLink or itemName
            if key == "" or seenFood[key] then
                return
            end
            seenFood[key] = true
            mergedFood[#mergedFood + 1] = {
                itemLink = itemLink,
                itemName = itemName,
            }
        end

        if type(accountOverlay.recentFoodItems) == "table" then
            for _, entry in ipairs(accountOverlay.recentFoodItems) do
                AddFood(entry)
                if #mergedFood >= 5 then break end
            end
        end

        if #mergedFood < 5 then
            for _, entry in ipairs(csvOverlay.recentFoodItems) do
                AddFood(entry)
                if #mergedFood >= 5 then break end
            end
        end

        accountOverlay.recentFoodItems = mergedFood
    end
end

local function MigrateLegacyFriendHouseProfiles(friends)
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

function EZO:Initialize()
    local world = GetWorldName()
    local defaultLanguage = ObtenerIdiomaPorDefectoCliente()
    EZO.runtime = EZO.runtime or {}

    -- Valores por defecto de las variables guardadas (por cuenta y mundo)
    local defaults = {
        general = {
            language          = defaultLanguage,
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
            hideInMenus      = false,
            locked           = false,
            lastMountCollectibleId = 0,
            lastPetCollectibleId = 0,
            lastCompanionCollectibleId = 0,
            lastAssistantCollectibleId = 0,
            recentMountCollectibles = {},
            recentPetCollectibles = {},
            recentCompanionCollectibles = {},
            recentAssistantCollectibles = {},
            lastFoodItemLink = "",
            lastFoodItemName = "",
            recentFoodItems = {},
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
            manualActiveFriendHouseProfileKey = FRIEND_HOUSE_MANUAL_PROFILE_KEY,
            manualActiveFriendHouseProfileInitialized = true,
            friendHouseProfileKey = FRIEND_HOUSE_MANUAL_PROFILE_KEY,
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
        EZO_Lang.Apply(self.sv.general.language or "en")
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
    MigrateLegacyFriendHouseProfiles(self.sv.friends)
    if self.sv.friends and (not self.sv.friends.friendHouseProfileKey or self.sv.friends.friendHouseProfileKey == "") then
        self.sv.friends.friendHouseProfileKey = FRIEND_HOUSE_MANUAL_PROFILE_KEY
    end
    if self.sv.friends and self.sv.friends.manualActiveFriendHouseProfileInitialized ~= true then
        self.sv.friends.manualActiveFriendHouseProfileKey = FRIEND_HOUSE_MANUAL_PROFILE_KEY
        self.sv.friends.manualActiveFriendHouseProfileInitialized = true
    elseif self.sv.friends and (not self.sv.friends.manualActiveFriendHouseProfileKey or self.sv.friends.manualActiveFriendHouseProfileKey == "") then
        self.sv.friends.manualActiveFriendHouseProfileKey = FRIEND_HOUSE_MANUAL_PROFILE_KEY
    end
    do
        local profileKey = tostring(self.sv.friends.friendHouseProfileKey or "")
        if not EsClavePerfilCasasValida(profileKey) then
            self.sv.friends.friendHouseProfileKey = FRIEND_HOUSE_MANUAL_PROFILE_KEY
        end

        local manualActiveProfileKey = tostring(self.sv.friends.manualActiveFriendHouseProfileKey or "")
        if not EsClavePerfilCasasValida(manualActiveProfileKey) then
            self.sv.friends.manualActiveFriendHouseProfileKey = FRIEND_HOUSE_MANUAL_PROFILE_KEY
        end

        local oldGuildKey = NormalizarClaveGuild(self.sv.friends.autoAssignFriendGuildKey)
        if oldGuildKey and not PerteneceAGuildJugador(oldGuildKey) then
            self.sv.friends.autoAssignFriendGuildKey = ""
        end

    end
    if self.sv.friends then
        CargarPerfilCasasParaEditar(self.sv.friends.friendHouseProfileKey)
    end

    self.RefreshActiveFriendHouses()

    -- Inicializar submódulos en orden
    if EZOTools_Menu      and EZOTools_Menu.Init      then EZOTools_Menu.Init()      end
    if EZOTools_Overlay   and EZOTools_Overlay.Init   then EZOTools_Overlay.Init()   end
    if EZOTools_Keybinds  and EZOTools_Keybinds.Init  then EZOTools_Keybinds.Init()  end
    if EZOTools_KeyboardEnterOverride and EZOTools_KeyboardEnterOverride.Init then
        EZOTools_KeyboardEnterOverride.Init()
    end

    safeChat(GetString(EZO_MSG_INIT))

    if self.RegisterSlashCommands then self:RegisterSlashCommands() end

    RegisterWithEZOBindings()


    -- Asignar keybinds por defecto del panel de comandos.
    -- CreateDefaultActionBind solo actúa si el slot está vacío y el usuario puede cambiarlo luego.
    -- KEY_GAMEPAD_BUTTON_3_HOLD = X-hold en Xbox / cuadrado-hold en PS.
    -- En teclado usamos CTRL + ALT + Num 0 como combinación conservadora.
    -- Hay que esperar EVENT_KEYBINDINGS_LOADED para que el sistema de bindings esté listo.
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_DefaultBind",
        EVENT_KEYBINDINGS_LOADED,
        function()
            EVENT_MANAGER:UnregisterForEvent(ADDON_NAME .. "_DefaultBind", EVENT_KEYBINDINGS_LOADED)
            if type(CreateDefaultActionBind) == "function" then
                CreateDefaultActionBind("EZO_TOGGLE_COMMAND_PANEL",
                    KEY_GAMEPAD_BUTTON_3_HOLD,  -- X-hold Xbox / cuadrado-hold PS
                    KEY_INVALID, KEY_INVALID, KEY_INVALID, KEY_INVALID)
                CreateDefaultActionBind("EZO_TOGGLE_UTILITY_PANEL",
                    KEY_GAMEPAD_BUTTON_4_HOLD,  -- Y-hold Xbox / triángulo-hold PS
                    KEY_INVALID, KEY_INVALID, KEY_INVALID, KEY_INVALID)
                CreateDefaultActionBind("EZO_TOGGLE_COMMAND_PANEL",
                    KEY_NUMPAD0,
                    KEY_CTRL, KEY_ALT, KEY_INVALID, KEY_INVALID)
            end
        end)
end

-- EZOTools.OpenOverlayMenu eliminado (keybind EZO_OPEN_OVERLAY_MENU eliminado en v3.7.5)

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
    if EZOTools_Overlay and EZOTools_Overlay.Refresh then
        EZOTools_Overlay.Refresh()
    end
    -- Refrescar dot al activar — EVENT_INVENTORY_SINGLE_SLOT_UPDATE cubre cambios en tiempo real
    if EZOTools_Overlay and EZOTools_Overlay.RefreshDot then
        EZOTools_Overlay.RefreshDot()
    end
end)

-- ============================================================
-- Viajes: casa propia
-- ============================================================

function EZOTools.JumpPrimaryHouse()
    local id = GetHousingPrimaryHouse()
    if id and id > 0 then
        RequestJumpToHouse(id)
    else
        safeChat(GetString(EZO_MSG_NO_PRIMARY_HOUSE))
    end
end

-- Auxiliar interna: salta a la casa de una cuenta de amigo si está configurada
local function _saltarACasa(nombreCuenta)
    if nombreCuenta and nombreCuenta ~= "" then
        JumpToHouse(nombreCuenta)
        return true
    end
    return false
end

function EZOTools.JumpCraftingHall()
    if not _saltarACasa(EZOTools.sv.friends.craftingHall) then
        safeChat(GetString(EZO_MSG_NO_CRAFTING_HALL))
    end
end

function EZOTools.JumpSecondaryHall()
    if not _saltarACasa(EZOTools.sv.friends.secondaryHall) then
        safeChat(GetString(EZO_MSG_NO_SECONDARY_HALL))
    end
end

-- ============================================================
-- Viajes: líder de grupo
-- ============================================================

function EZOTools.CanJumpToLeader()
    if not IsUnitGrouped or not IsUnitGrouped("player") then return false end
    if GetGroupLeaderUnitTag and CanJumpToGroupMember then
        local leaderTag = GetGroupLeaderUnitTag()
        if leaderTag and leaderTag ~= "" then
            return CanJumpToGroupMember(leaderTag)
        end
    end
    -- Si la API no expone CanJumpToGroupMember, dejamos que el juego lo resuelva al saltar.
    return (JumpToGroupLeader ~= nil)
end

function EZOTools.JumpToLeader()
    if not IsUnitGrouped or not IsUnitGrouped("player") then
        safeChat(GetString(EZO_MSG_NOT_IN_GROUP))
        return
    end

    local leaderTag = (GetGroupLeaderUnitTag and GetGroupLeaderUnitTag()) or nil
    if leaderTag and leaderTag ~= "" and CanJumpToGroupMember and JumpToGroupMember then
        if CanJumpToGroupMember(leaderTag) then
            -- IMPORTANTE: CanJumpToGroupMember acepta unitTag pero JumpToGroupMember necesita
            -- el nombre de cuenta (@Cuenta). Resolver el nombre antes de llamar.
            local displayName = (GetUnitDisplayName and GetUnitDisplayName(leaderTag)) or ""
            if displayName ~= "" then
                JumpToGroupMember(displayName)
                return
            end
        end
    end

    -- Si no podemos resolver el nombre, prueba la variante general de salto al líder.
    if JumpToGroupLeader then
        JumpToGroupLeader("")
        return
    end

    safeChat(GetString(EZO_MSG_CANT_JUMP_LEADER))
end

-- ============================================================
-- Acciones de grupo e instancia
-- ============================================================

function EZOTools.LeaveGroup()
    if type(GroupLeave) == "function" then
        GroupLeave()
        return true
    end
    return false
end

function EZOTools.LeaveInstance()
    if type(ExitInstanceImmediately) == "function" then
        ExitInstanceImmediately()
        return true
    end
    return false
end

function EZOTools.LeaveGroupAndInstance()
    local hecho = false
    if type(GroupLeave) == "function" then
        GroupLeave()
        hecho = true
    end
    if type(ExitInstanceImmediately) == "function" then
        ExitInstanceImmediately()
        hecho = true
    end
    return hecho
end

-- ============================================================
-- Funciones de toggle (usadas por keybinds y menú)
-- ============================================================

function EZOTools.ReloadUIBinding() ReloadUI() end

function EZOTools.ToggleOverlay()
    if EZOTools_Overlay and EZOTools_Overlay.Toggle then EZOTools_Overlay.Toggle() end
end

-- EZOTools.ToggleGamepadStyle eliminado (keybind EZO_TOGGLE_GAMEPAD_STYLE eliminado en v3.7.5)

-- ============================================================
-- Comandos de chat (/ezo, /ezotools)
-- ============================================================

local function _mostrarAyudaPrincipal()
    safeChat(GetString(EZO_CMD_HELP_TITLE))
    safeChat(GetString(EZO_CMD_HELP_STATUS))
    if EZO.IsDebugModeEnabled() then
        safeChat(GetString(EZO_CMD_HELP_DEBUG))
    end
    safeChat(GetString(EZO_CMD_HELP_HELP))
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

local function _establecerModoEntrada(modoConst, etiqueta)
    if not (SETTING_TYPE_GAMEPAD and GAMEPAD_SETTING_INPUT_PREFERRED_MODE and SetSetting) then
        safeChat(GetString(EZO_MSG_INPUT_MODE_NA))
        return
    end
    if not modoConst then
        safeChat(GetString(EZO_MSG_INPUT_MODE_NA))
        return
    end
    SetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE, modoConst)
    safeChat(zo_strformat(GetString(EZO_MSG_INPUT_MODE_SET), etiqueta))
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

function EZO:RegisterSlashCommands()
    -- Preferir LibSlashCommander si está disponible (autocompletado y mejor UX)
    if LibSlashCommander and LibSlashCommander.Register then
        local LSC = LibSlashCommander
        local cmd = LSC:Register({"/ezo", "/ezotools"}, _manejadorSlash, "EZOTools")
        -- Sin subcomandos adicionales por ahora
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
