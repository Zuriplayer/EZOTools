-- Módulo principal de EZOTools.
-- Gestiona la inicialización, variables guardadas, acciones de viaje/grupo/mantenimiento
-- y registro de comandos de chat.
EZOTools = EZOTools or {}
local EZO = EZOTools
local ADDON_NAME = "EZOTools"

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

local function ObtenerIdiomaPorDefectoCliente()
    if type(GetCVar) == "function" then
        local lang = zo_strlower(tostring(GetCVar("Language.2") or ""))
        if lang == "es" or lang == "en" then
            return lang
        end
    end
    return "en"
end

local AUTO_FRIEND_HOUSES_BY_GUILD = {
    ["hojablanca"] = {
        craftingHall = "@sunsetlu",
        secondaryHall = "@grukka",
    },
    ["fuego"] = {
        craftingHall = "@Whasabi",
        secondaryHall = "",
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

local function NormalizarClaveGuild(nombre)
    if type(nombre) ~= "string" then return nil end
    nombre = zo_strtrim(nombre)
    if nombre == "" then return nil end
    nombre = zo_strlower(nombre)
    nombre = nombre:gsub("%s+", " ")
    return nombre
end

function EZO.GetEligibleAutoFriendGuildChoices()
    local choices, values = {}, {}
    if type(GetNumGuilds) ~= "function" or type(GetGuildId) ~= "function" or type(GetGuildName) ~= "function" then
        return choices, values
    end

    local numGuilds = GetNumGuilds()
    for i = 1, numGuilds do
        local guildId = GetGuildId(i)
        local guildName = guildId and GetGuildName(guildId) or nil
        local guildKey = NormalizarClaveGuild(guildName)
        if guildKey and type(AUTO_FRIEND_HOUSES_BY_GUILD[guildKey]) == "table" then
            choices[#choices + 1] = guildName
            values[#values + 1] = guildKey
        end
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

function EZO.ApplyAutoFriendHousesSelection()
    if not (EZO.sv and EZO.sv.friends and EZO.sv.friends.autoAssignFriendHouses == true) then
        return false
    end

    local guildKey = NormalizarClaveGuild(EZO.sv.friends.autoAssignFriendGuildKey)
    if not guildKey then
        return false
    end

    local _, playerGuildValues = EZO.GetEligibleAutoFriendGuildChoices()
    local belongsToGuild = false
    for _, value in ipairs(playerGuildValues) do
        if value == guildKey then
            belongsToGuild = true
            break
        end
    end
    if not belongsToGuild then
        return false
    end

    local config = ObtenerAsignacionCasasPorGuild(guildKey)
    if type(config) ~= "table" then
        return false
    end

    EZO.sv.friends.craftingHall = tostring(config.craftingHall or "")
    EZO.sv.friends.secondaryHall = tostring(config.secondaryHall or "")
    return true
end

function EZO.SaveCurrentFriendHousesForSelectedGuild()
    if not (EZO.sv and EZO.sv.friends) then
        return false
    end

    local guildKey = NormalizarClaveGuild(EZO.sv.friends.autoAssignFriendGuildKey)
    if not guildKey then
        return false
    end

    local _, playerGuildValues = EZO.GetEligibleAutoFriendGuildChoices()
    local belongsToGuild = false
    for _, value in ipairs(playerGuildValues) do
        if value == guildKey then
            belongsToGuild = true
            break
        end
    end
    if not belongsToGuild then
        return false
    end

    EZO.sv.friends.customGuildFriendHouses = EZO.sv.friends.customGuildFriendHouses or {}
    EZO.sv.friends.customGuildFriendHouses[guildKey] = {
        craftingHall = tostring(EZO.sv.friends.craftingHall or ""),
        secondaryHall = tostring(EZO.sv.friends.secondaryHall or ""),
    }
    return true
end

function EZO:Initialize()
    local world = GetWorldName()
    local defaultLanguage = ObtenerIdiomaPorDefectoCliente()

    -- Valores por defecto de las variables guardadas (por cuenta y mundo)
    local defaults = {
        general = {
            language          = defaultLanguage,
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
            guildCustomImageEnabled = true,
            simulateGamepad  = false,
            hideInCombat     = false,
            hideInMenus      = false,
            locked           = false,
            lastPetCollectibleId = 0,
            lastCompanionCollectibleId = 0,
            lastAssistantCollectibleId = 0,
            lastFoodItemLink = "",
            lastFoodItemName = "",
            recentFoodItems = {},
            x                = nil,
            y                = nil,
        },
        friends = {
            craftingHall   = "",
            secondaryHall  = "",
            autoAssignFriendHouses = true,
            autoAssignFriendGuildKey = "",
            customGuildFriendHouses = {},
        },
    }

    self.sv = ZO_SavedVars:NewAccountWide("EZOTools_Saved", 1, world, defaults)

    -- Aplicar idioma guardado
    if EZO_Lang and EZO_Lang.Apply then
        EZO_Lang.Apply(self.sv.general.language or "en")
    end

    -- Si el texto del overlay sigue siendo el placeholder de fábrica, usar el nombre de cuenta.
    -- GetDisplayName() devuelve "@NombreCuenta" del jugador — lo más útil como texto por defecto.
    if not self.sv.overlay.text or self.sv.overlay.text == "EZOTools" then
        self.sv.overlay.text = GetDisplayName() or GetString(EZO_MSG_INIT)
    end

    do
        local guildKey = NormalizarClaveGuild(self.sv.friends.autoAssignFriendGuildKey)
        local _, eligibleValues = self.GetEligibleAutoFriendGuildChoices()
        local isEligible = false
        for _, value in ipairs(eligibleValues) do
            if value == guildKey then
                isEligible = true
                break
            end
        end
        if not isEligible then
            self.sv.friends.autoAssignFriendGuildKey = ""
            if #eligibleValues == 0 then
                self.sv.friends.autoAssignFriendHouses = false
            end
        end
    end

    self.ApplyAutoFriendHousesSelection()

    -- Inicializar submódulos en orden
    if EZOTools_Menu      and EZOTools_Menu.Init      then EZOTools_Menu.Init()      end
    if EZOTools_Overlay   and EZOTools_Overlay.Init   then EZOTools_Overlay.Init()   end
    if EZOTools_Keybinds  and EZOTools_Keybinds.Init  then EZOTools_Keybinds.Init()  end
    if EZOTools_KeyboardEnterOverride and EZOTools_KeyboardEnterOverride.Init then
        EZOTools_KeyboardEnterOverride.Init()
    end

    safeChat(GetString(EZO_MSG_INIT))

    if self.RegisterSlashCommands then self:RegisterSlashCommands() end


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
    safeChat(GetString(EZO_CMD_HELP_VERSION))
    safeChat(GetString(EZO_CMD_HELP_DEBUG))
    safeChat(GetString(EZO_CMD_HELP_HELP))
end

-- Muestra las hermandades del jugador e indica cuál está representando actualmente.
-- GetRepresentedGuildId() es la API asociada al nombre de hermandad visible desde U49.
local function _comandoGuilds()
    local numGuilds = GetNumGuilds and GetNumGuilds() or 0
    if numGuilds == 0 then
        safeChat(GetString(EZO_CMD_GUILDS_NONE))
        return
    end

    local representedId = GetRepresentedGuildId and GetRepresentedGuildId() or 0

    safeChat(zo_strformat(GetString(EZO_CMD_GUILDS_HEADER), numGuilds))
    for i = 1, numGuilds do
        local guildId  = GetGuildId(i)
        local nombre   = GetGuildName(guildId) or "?"
        local miembros = GetNumGuildMembers(guildId) or 0
        local marcador = (guildId == representedId) and GetString(EZO_CMD_GUILDS_REPRESENTED) or ""
        safeChat(zo_strformat(GetString(EZO_CMD_GUILDS_ROW), i, nombre, miembros, guildId, marcador))
    end

    if representedId == 0 then
        safeChat(GetString(EZO_CMD_GUILDS_NONE_REP))
    end
end

-- Volcado de diagnóstico general del addon.
local function _comandoInfo()
    safeChat(GetString(EZO_CMD_INFO_HEADER))

    -- Zona
    local zonaIdx = GetUnitZoneIndex and GetUnitZoneIndex("player") or nil
    local zona = (zonaIdx and GetZoneNameByIndex and GetZoneNameByIndex(zonaIdx)) or "?"
    safeChat(zo_strformat(GetString(EZO_CMD_INFO_ZONE), tostring(zona)))

    -- Grupo
    local enGrupo = IsUnitGrouped and IsUnitGrouped("player")
    if enGrupo then
        local tamano = GetGroupSize and GetGroupSize() or "?"
        safeChat(zo_strformat(GetString(EZO_CMD_INFO_GROUP), tostring(tamano)))
        local leaderTag = GetGroupLeaderUnitTag and GetGroupLeaderUnitTag()
        if leaderTag and leaderTag ~= "" then
            local leaderName = (GetUnitDisplayName and GetUnitDisplayName(leaderTag)) or leaderTag
            safeChat(zo_strformat(GetString(EZO_CMD_INFO_LEADER), tostring(leaderName)))
        end
    else
        safeChat(GetString(EZO_CMD_INFO_NO_GROUP))
    end

    -- Mantenimiento
    local umbralRep = (EZOTools.sv and EZOTools.sv.general and tonumber(EZOTools.sv.general.repairThreshold)) or 40
    local umbralRec = (EZOTools.sv and EZOTools.sv.general and tonumber(EZOTools.sv.general.rechargeThreshold)) or 50
    local necesitaReparar  = EZOTools.CanRepairEquipped  and EZOTools.CanRepairEquipped()
    local necesitaRecargar = EZOTools.CanRechargeWeapons and EZOTools.CanRechargeWeapons()
    safeChat(zo_strformat(GetString(EZO_CMD_INFO_REPAIR), umbralRep, necesitaReparar and GetString(EZO_CMD_INFO_NEEDED) or GetString(EZO_CMD_INFO_OK)))
    safeChat(zo_strformat(GetString(EZO_CMD_INFO_RECHARGE), umbralRec, necesitaRecargar and GetString(EZO_CMD_INFO_NEEDED) or GetString(EZO_CMD_INFO_OK)))

    -- Guild representada
    local representedId = GetRepresentedGuildId and GetRepresentedGuildId() or 0
    if representedId ~= 0 then
        local nombreGuild = (GetGuildName and GetGuildName(representedId)) or "?"
        safeChat(zo_strformat(GetString(EZO_CMD_INFO_GUILD), nombreGuild, representedId))
    else
        safeChat(GetString(EZO_CMD_INFO_NO_GUILD))
    end

    safeChat(GetString(EZO_CMD_INFO_FOOTER))
end

local function _comandoVersion()
    local lang = (EZO_Lang and EZO_Lang.current) or (EZOTools.sv and EZOTools.sv.general and EZOTools.sv.general.language) or "?"
    local lam = (_G.LibAddonMenu2 and "yes") or "no"
    local overlay = (EZOTools_Overlay and EZOTools_Overlay.Refresh and "yes") or "no"
    local gamepad = (EZOTools.GamepadDialog and EZOTools.GamepadDialog.Open and "yes") or "no"

    safeChat(zo_strformat(GetString(EZO_CMD_VERSION_HEADER), EZOTools.ADDON_VERSION))
    safeChat(zo_strformat(GetString(EZO_CMD_VERSION_LANGUAGE), tostring(lang)))
    safeChat(zo_strformat(GetString(EZO_CMD_VERSION_LAM), lam))
    safeChat(zo_strformat(GetString(EZO_CMD_VERSION_OVERLAY), overlay))
    safeChat(zo_strformat(GetString(EZO_CMD_VERSION_GAMEPAD), gamepad))
end

local EjecutarDebugTexload, EjecutarDebugTex, EjecutarDebugDots, EjecutarDebugLayout, EjecutarDebugFood

local function _mostrarAyudaDebug()
    safeChat(GetString(EZO_CMD_DEBUG_TITLE))
    safeChat(GetString(EZO_CMD_DEBUG_INFO))
    safeChat(GetString(EZO_CMD_DEBUG_GUILDS))
    safeChat(GetString(EZO_CMD_DEBUG_TEX))
    safeChat(GetString(EZO_CMD_DEBUG_TEXLOAD))
    safeChat(GetString(EZO_CMD_DEBUG_DOTS))
    safeChat(GetString(EZO_CMD_DEBUG_LAYOUT))
    safeChat(GetString(EZO_CMD_DEBUG_FOOD))
end

local function _ejecutarDebug(sub, arg)
    sub = zo_strlower(sub or "")
    if sub == "" or sub == "help" or sub == "?" then
        _mostrarAyudaDebug()
        return true
    end
    if sub == "info" then
        _comandoInfo()
        return true
    end
    if sub == "guilds" then
        _comandoGuilds()
        return true
    end
    if sub == "tex" then
        EjecutarDebugTex()
        return true
    end
    if sub == "texload" then
        EjecutarDebugTexload()
        return true
    end
    if sub == "dots" then
        EjecutarDebugDots()
        return true
    end
    if sub == "layout" then
        EjecutarDebugLayout()
        return true
    end
    if sub == "food" then
        EjecutarDebugFood(arg)
        return true
    end
    _mostrarAyudaDebug()
    return true
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
        _mostrarAyudaPrincipal(); return
    end
    if a1 == "version" then
        _comandoVersion(); return
    end
    if a1 == "debug" then
        _ejecutarDebug(a2, a3); return
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
    d("[EZOTools] Panel de comandos no disponible (ToggleCommandPanel no cargado)")
end


EjecutarDebugFood = function(modo)
    if not (EZOTools_Overlay and EZOTools_Overlay.SetFoodDebugState) then
        EZOTools.Print(GetString(EZO_CMD_LAYOUT_NA))
        return
    end
    modo = zo_strlower(tostring(modo or ""))
    if modo == "" then
        EZOTools.Print(GetString(EZO_CMD_DEBUG_FOOD_USAGE))
        return
    end
    if not EZOTools_Overlay.SetFoodDebugState(modo) then
        EZOTools.Print(GetString(EZO_CMD_DEBUG_FOOD_USAGE))
        return
    end
    EZOTools.Print(zo_strformat(GetString(EZO_CMD_DEBUG_FOOD_SET), modo))
end

-- Diagnóstico: comprueba la carga de texturas del overlay.
EjecutarDebugTexload = function()
    local ventana = _G["EZOTexTest"]
    if ventana and not ventana:IsHidden() then
        ventana:SetHidden(true)
        return
    end
    if not ventana then
        ventana = WINDOW_MANAGER:CreateTopLevelWindow("EZOTexTest")
    end
    ventana:SetDimensions(200, 200)
    ventana:ClearAnchors()
    ventana:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    ventana:SetHidden(false)

    local texturas = {
        "/esoui/art/treeicons/store_indexicon_vanitypets_up.dds",
        "/esoui/art/treeicons/collections_indexicon_noncombatpets_up.dds",
        "/esoui/art/treeicons/store_indexicon_companions_up.dds",
        "/esoui/art/treeicons/store_indexicon_assistants_up.dds",
        "/esoui/art/treeicons/collections_indexicon_companions_up.dds",
    }
    for i, ruta in ipairs(texturas) do
        local nombre = "EZOTexTest" .. i
        local t = _G[nombre]
        if not t then
            t = WINDOW_MANAGER:CreateControl(nombre, ventana, CT_TEXTURE)
        end
        t:SetDimensions(32, 32)
        t:ClearAnchors()
        t:SetAnchor(TOPLEFT, ventana, TOPLEFT, 0, (i-1)*36)
        t:SetTexture(ruta)
        t:SetHidden(false)
        local ok = t:IsTextureLoaded()
        EZOTools.Print(string.format("[%d] %s = %s", i, ruta:match("[^/]+$"), tostring(ok)))
    end
end

-- Diagnóstico de texturas de iconos del overlay
EjecutarDebugTex = function()
    local iconos = {
        {nombre="MaintDot",    ctrl=EZOTools_MaintDot},
        {nombre="FoodDot",     ctrl=EZOTools_FoodDot},
        {nombre="ChargeDot",   ctrl=EZOTools_ChargeDot},
        {nombre="PetDot",      ctrl=EZOToolsPetDot2},
        {nombre="CompanionDot",ctrl=EZOToolsCompDot2},
        {nombre="AssistantDot",ctrl=EZOToolsAssistDot2},
    }
    for _, v in ipairs(iconos) do
        if v.ctrl then
            EZOTools.Print(string.format("%s: exists=true hidden=%s texLoaded=%s",
                v.nombre,
                tostring(v.ctrl:IsHidden()),
                tostring(v.ctrl:IsTextureLoaded())))
        else
            EZOTools.Print(v.nombre .. ": NO EXISTE")
        end
    end
end

EjecutarDebugLayout = function()
    if not (EZOTools_Overlay and EZOTools_Overlay.ToggleLayoutPreview) then
        EZOTools.Print(GetString(EZO_CMD_LAYOUT_NA))
        return
    end
    local activo = EZOTools_Overlay.ToggleLayoutPreview()
    EZOTools.Print(activo and GetString(EZO_CMD_LAYOUT_ON) or GetString(EZO_CMD_LAYOUT_OFF))
end

-- Diagnóstico rápido del estado de iconos inferiores.
EjecutarDebugDots = function()
    local EZO_Overlay = EZOTools_Overlay
    if not EZO_Overlay then
        EZOTools.Print("EZOTools_Overlay no existe")
        return
    end
    local pet = _G["EZOToolsPetDot2"]
    local comp = _G["EZOToolsCompDot2"]
    local assist = _G["EZOToolsAssistDot2"]
    EZOTools.Print("PetDot2: " .. tostring(pet))
    EZOTools.Print("CompDot2: " .. tostring(comp))
    EZOTools.Print("AssistDot2: " .. tostring(assist))
    if pet then
        EZOTools.Print("Pet hidden=" .. tostring(pet:IsHidden()) ..
            " texture=" .. tostring(pet:GetTextureFileName()))
    end
    if comp then
        EZOTools.Print("Comp hidden=" .. tostring(comp:IsHidden()) ..
            " texture=" .. tostring(comp:GetTextureFileName()))
    end
    if assist then
        EZOTools.Print("Assist hidden=" .. tostring(assist:IsHidden()) ..
            " texture=" .. tostring(assist:GetTextureFileName()))
    end
    local numBuffs = GetNumBuffs and GetNumBuffs("player") or "N/A"
    local groupSize = GetGroupSize and GetGroupSize() or "N/A"
    local hasComp = HasActiveCompanion and HasActiveCompanion() or false
    local petId = GetActiveCollectibleByType and
        GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_VANITY_PET, GAMEPLAY_ACTOR_CATEGORY_PLAYER) or 0
    local assistId = GetActiveCollectibleByType and
        GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_ASSISTANT, GAMEPLAY_ACTOR_CATEGORY_PLAYER) or 0
    EZOTools.Print("grupo=" .. tostring(groupSize) ..
        " companion=" .. tostring(hasComp) ..
        " petId=" .. tostring(petId) ..
        " assistId=" .. tostring(assistId))
end
