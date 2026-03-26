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

function EZO:Initialize()
    local world = GetWorldName()

    -- Valores por defecto de las variables guardadas (por cuenta y mundo)
    local defaults = {
        general = {
            language          = "en",
            repairThreshold   = 40,
            rechargeThreshold = 50,
        },
        overlay = {
            enabled          = true,
            alpha            = 1.0,
            scale            = 1.0,
            text             = "EZOTools",
            simulateGamepad  = false,
            hideInCombat     = false,
            hideInMenus      = true,
            locked           = false,
            x                = nil,
            y                = nil,
        },
        friends = {
            craftingHall   = "",
            secondaryHall  = "",
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

    -- Inicializar submódulos en orden
    if EZOTools_Menu      and EZOTools_Menu.Init      then EZOTools_Menu.Init()      end
    if EZOTools_Overlay   and EZOTools_Overlay.Init   then EZOTools_Overlay.Init()   end
    if EZOTools_Keybinds  and EZOTools_Keybinds.Init  then EZOTools_Keybinds.Init()  end
    if EZOTools_KeyboardEnterOverride and EZOTools_KeyboardEnterOverride.Init then
        EZOTools_KeyboardEnterOverride.Init()
    end

    safeChat(GetString(EZO_MSG_INIT))

    if self.RegisterSlashCommands then self:RegisterSlashCommands() end


    -- Asignar keybind por defecto del panel de comandos para gamepad.
    -- CreateDefaultActionBind solo actúa si el slot está vacío — nunca sobreescribe.
    -- KEY_GAMEPAD_BUTTON_3_HOLD = X-hold en Xbox / cuadrado-hold en PS.
    -- ESO traduce automáticamente al icono correcto según el mando conectado.
    -- Hay que esperar EVENT_KEYBINDINGS_LOADED para que el sistema de bindings esté listo.
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_DefaultBind",
        EVENT_KEYBINDINGS_LOADED,
        function()
            EVENT_MANAGER:UnregisterForEvent(ADDON_NAME .. "_DefaultBind", EVENT_KEYBINDINGS_LOADED)
            if type(CreateDefaultActionBind) == "function" then
                CreateDefaultActionBind("EZO_TOGGLE_COMMAND_PANEL",
                    KEY_GAMEPAD_BUTTON_3_HOLD,  -- X-hold Xbox / cuadrado-hold PS
                    KEY_INVALID, KEY_INVALID, KEY_INVALID, KEY_INVALID)
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
    -- Fallback: si la API no expone CanJumpToGroupMember, permitir si hay función de salto
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

    -- Fallback a JumpToGroupLeader si no podemos resolver el nombre
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

-- Muestra las guilds del jugador e indica cuál está representando actualmente.
-- GetRepresentedGuildId() es la API que corresponde al Guild Nameplate de U49.
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

local EjecutarDebugTexload, EjecutarDebugTex, EjecutarDebugDots

local function _mostrarAyudaDebug()
    safeChat(GetString(EZO_CMD_DEBUG_TITLE))
    safeChat(GetString(EZO_CMD_DEBUG_INFO))
    safeChat(GetString(EZO_CMD_DEBUG_GUILDS))
    safeChat(GetString(EZO_CMD_DEBUG_TEX))
    safeChat(GetString(EZO_CMD_DEBUG_TEXLOAD))
    safeChat(GetString(EZO_CMD_DEBUG_DOTS))
end

local function _ejecutarDebug(sub)
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
    local a1, a2 = zo_strsplit(" ", trimmed)
    a1 = zo_strlower(a1 or "")
    a2 = zo_strlower(a2 or "")
    if a1 == "help" or a1 == "?" then
        _mostrarAyudaPrincipal(); return
    end
    if a1 == "version" then
        _comandoVersion(); return
    end
    if a1 == "debug" then
        _ejecutarDebug(a2); return
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
        -- Fallback nativo sin LibSlashCommander
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


-- Diagnóstico: prueba carga de texturas de pet y companion
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

-- Diagnóstico iconos pet/companion: /ezodots
EjecutarDebugDots = function()
    local EZO_Overlay = EZOTools_Overlay
    if not EZO_Overlay then
        EZOTools.Print("EZOTools_Overlay no existe")
        return
    end
    local pet = _G["EZOToolsPetDot2"]
    local comp = _G["EZOToolsCompDot2"]
    EZOTools.Print("PetDot2: " .. tostring(pet))
    EZOTools.Print("CompDot2: " .. tostring(comp))
    if pet then
        EZOTools.Print("Pet hidden=" .. tostring(pet:IsHidden()) ..
            " texture=" .. tostring(pet:GetTextureFileName()))
    end
    if comp then
        EZOTools.Print("Comp hidden=" .. tostring(comp:IsHidden()) ..
            " texture=" .. tostring(comp:GetTextureFileName()))
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


