-- Debug y diagnostico tecnico de EZOTools.
-- Mantiene los reportes largos fuera del chat y los envia al backend tecnico opcional.
EZOTools = EZOTools or {}

local EZO = EZOTools
local ADDON_NAME = "EZOTools"
local Debug = EZO.Debug or {}
EZO.Debug = Debug

local function safeChat(msg)
    if type(EZO.Print) == "function" then
        EZO.Print(msg)
    else
        d(tostring(msg))
    end
end

function EZO.DebugLog(msg, force)
    if not force and not EZO.IsDebugModeEnabled() then
        return false
    end
    local lib = _G.LibDebugLogger
    if type(lib) ~= "function" and type(lib) ~= "table" then
        return false
    end

    local logger = EZO._debugLogger
    if logger == nil then
        local ok, created = false, nil
        if type(lib) == "function" then
            ok, created = pcall(lib, ADDON_NAME)
        end
        if (not ok or created == nil) and type(lib) == "table" and type(lib.Create) == "function" then
            ok, created = pcall(function()
                return lib:Create(ADDON_NAME)
            end)
            if not ok or created == nil then
                ok, created = pcall(lib.Create, ADDON_NAME)
            end
        end
        if ok and created ~= nil then
            logger = created
            EZO._debugLogger = logger
        end
    end

    if not logger then
        return false
    end

    if type(logger.SetMinLevelOverride) == "function" and type(lib) == "table" and lib.LOG_LEVEL_DEBUG ~= nil then
        pcall(function()
            logger:SetMinLevelOverride(lib.LOG_LEVEL_DEBUG)
        end)
    end

    if type(logger.SetLogTracesOverride) == "function" then
        pcall(function()
            logger:SetLogTracesOverride(false)
        end)
    end

    if type(logger.Debug) == "function" then
        return pcall(function()
            logger:Debug("%s", tostring(msg))
        end)
    end

    if type(logger.Log) == "function" and type(lib) == "table" and lib.LOG_LEVEL_DEBUG ~= nil then
        return pcall(function()
            logger:Log(lib.LOG_LEVEL_DEBUG, "%s", tostring(msg))
        end)
    end

    return false
end

function EZO.DebugPrint(msg, force)
    if EZO.DebugLog(msg, force) then
        return true
    end
    return false
end

function EZO.CanOpenDebugLogViewer(force)
    if not force and not EZO.IsDebugModeEnabled() then
        return false
    end
    local viewer = _G.DebugLogViewer
    if not viewer then
        return false
    end
    return type(viewer.ShowWindow) == "function"
        or type(viewer.ToggleWindow) == "function"
end

function EZO.OpenDebugLogViewer(force)
    if not EZO.CanOpenDebugLogViewer(force) then
        safeChat(GetString(EZO_MSG_DEBUG_VIEWER_UNAVAILABLE))
        return false
    end

    local viewer = _G.DebugLogViewer
    if type(viewer.ShowWindow) == "function" then
        viewer.ShowWindow()
        return true
    end
    if type(viewer.ToggleWindow) == "function" then
        viewer.ToggleWindow()
        return true
    end

    safeChat(GetString(EZO_MSG_DEBUG_VIEWER_UNAVAILABLE))
    return false
end

local function ConstruirReporteGuilds()
    local lineas = {}
    local numGuilds = GetNumGuilds and GetNumGuilds() or 0
    if numGuilds == 0 then
        lineas[#lineas + 1] = GetString(EZO_CMD_GUILDS_NONE)
        return lineas
    end

    local representedId = GetRepresentedGuildId and GetRepresentedGuildId() or 0

    lineas[#lineas + 1] = zo_strformat(GetString(EZO_CMD_GUILDS_HEADER), numGuilds)
    for i = 1, numGuilds do
        local guildId  = GetGuildId(i)
        local nombre   = GetGuildName(guildId) or "?"
        local miembros = GetNumGuildMembers(guildId) or 0
        local marcador = (guildId == representedId) and GetString(EZO_CMD_GUILDS_REPRESENTED) or ""
        lineas[#lineas + 1] = zo_strformat(GetString(EZO_CMD_GUILDS_ROW), i, nombre, miembros, guildId, marcador)
    end

    if representedId == 0 then
        lineas[#lineas + 1] = GetString(EZO_CMD_GUILDS_NONE_REP)
    end

    return lineas
end

local function ConstruirReporteInfo()
    local lineas = {
        GetString(EZO_CMD_INFO_HEADER),
    }

    local zonaIdx = GetUnitZoneIndex and GetUnitZoneIndex("player") or nil
    local zona = (zonaIdx and GetZoneNameByIndex and GetZoneNameByIndex(zonaIdx)) or "?"
    lineas[#lineas + 1] = zo_strformat(GetString(EZO_CMD_INFO_ZONE), tostring(zona))

    local enGrupo = IsUnitGrouped and IsUnitGrouped("player")
    if enGrupo then
        local tamano = GetGroupSize and GetGroupSize() or "?"
        lineas[#lineas + 1] = zo_strformat(GetString(EZO_CMD_INFO_GROUP), tostring(tamano))
        local leaderTag = GetGroupLeaderUnitTag and GetGroupLeaderUnitTag()
        if leaderTag and leaderTag ~= "" then
            local leaderName = (GetUnitDisplayName and GetUnitDisplayName(leaderTag)) or leaderTag
            lineas[#lineas + 1] = zo_strformat(GetString(EZO_CMD_INFO_LEADER), tostring(leaderName))
        end
    else
        lineas[#lineas + 1] = GetString(EZO_CMD_INFO_NO_GROUP)
    end

    local umbralRep = (EZO.sv and EZO.sv.general and tonumber(EZO.sv.general.repairThreshold)) or 40
    local umbralRec = (EZO.sv and EZO.sv.general and tonumber(EZO.sv.general.rechargeThreshold)) or 50
    local necesitaReparar  = EZO.CanRepairEquipped and EZO.CanRepairEquipped()
    local necesitaRecargar = EZO.CanRechargeWeapons and EZO.CanRechargeWeapons()
    lineas[#lineas + 1] = zo_strformat(GetString(EZO_CMD_INFO_REPAIR), umbralRep, necesitaReparar and GetString(EZO_CMD_INFO_NEEDED) or GetString(EZO_CMD_INFO_OK))
    lineas[#lineas + 1] = zo_strformat(GetString(EZO_CMD_INFO_RECHARGE), umbralRec, necesitaRecargar and GetString(EZO_CMD_INFO_NEEDED) or GetString(EZO_CMD_INFO_OK))

    local representedId = GetRepresentedGuildId and GetRepresentedGuildId() or 0
    if representedId ~= 0 then
        local nombreGuild = (GetGuildName and GetGuildName(representedId)) or "?"
        lineas[#lineas + 1] = zo_strformat(GetString(EZO_CMD_INFO_GUILD), nombreGuild, representedId)
    else
        lineas[#lineas + 1] = GetString(EZO_CMD_INFO_NO_GUILD)
    end

    lineas[#lineas + 1] = GetString(EZO_CMD_INFO_FOOTER)
    return lineas
end

local function FormatearResultadoFuncion(nombre, ...)
    local fn = _G[nombre]
    if type(fn) ~= "function" then
        return string.format("%s: unavailable", nombre)
    end
    local ok, v1, v2, v3, v4 = pcall(fn, ...)
    if not ok then
        return string.format("%s: error=%s", nombre, tostring(v1))
    end
    local valores = { v1, v2, v3, v4 }
    local partes = {}
    for i = 1, 4 do
        if valores[i] ~= nil then
            partes[#partes + 1] = string.format("result%d=%s", i, tostring(valores[i]))
        end
    end
    if #partes == 0 then
        return string.format("%s: ok result=nil", nombre)
    end
    return string.format("%s: ok -- %s", nombre, table.concat(partes, " -- "))
end

local function ConstruirReporteHouse()
    local lineas = {
        "=== House diagnostic ===",
    }

    local zonaIdx = GetUnitZoneIndex and GetUnitZoneIndex("player") or nil
    local zona = (zonaIdx and GetZoneNameByIndex and GetZoneNameByIndex(zonaIdx)) or "?"
    lineas[#lineas + 1] = "zoneName=" .. tostring(zona)

    lineas[#lineas + 1] = FormatearResultadoFuncion("GetMapName")
    if type(GetCurrentMapZoneIndex) == "function" then
        local ok, mapZoneIndex = pcall(GetCurrentMapZoneIndex)
        lineas[#lineas + 1] = "GetCurrentMapZoneIndex=" .. tostring(ok and mapZoneIndex or "error")
        if ok and type(GetZoneId) == "function" then
            local okZone, zoneId = pcall(GetZoneId, mapZoneIndex)
            lineas[#lineas + 1] = "GetZoneId(currentMapZoneIndex)=" .. tostring(okZone and zoneId or "error")
        end
    else
        lineas[#lineas + 1] = "GetCurrentMapZoneIndex=unavailable"
    end

    lineas[#lineas + 1] = FormatearResultadoFuncion("GetCurrentZoneHouseId")
    lineas[#lineas + 1] = FormatearResultadoFuncion("GetHousingPrimaryHouse")
    lineas[#lineas + 1] = FormatearResultadoFuncion("IsOwnerOfCurrentHouse")
    lineas[#lineas + 1] = FormatearResultadoFuncion("IsLocalPlayerHouseOwner")
    lineas[#lineas + 1] = FormatearResultadoFuncion("CanLocalPlayerEditHouse")
    lineas[#lineas + 1] = FormatearResultadoFuncion("CanLocalPlayerBrowseFurniture")
    lineas[#lineas + 1] = FormatearResultadoFuncion("CanLeaveCurrentLocationViaTeleport")
    lineas[#lineas + 1] = FormatearResultadoFuncion("GetCurrentHouseOwner")
    lineas[#lineas + 1] = "COLLECTIBLE_CATEGORY_TYPE_HOUSE=" .. tostring(COLLECTIBLE_CATEGORY_TYPE_HOUSE)

    if COLLECTIBLE_CATEGORY_TYPE_HOUSE ~= nil then
        lineas[#lineas + 1] = FormatearResultadoFuncion("GetTotalCollectiblesByCategoryType", COLLECTIBLE_CATEGORY_TYPE_HOUSE)
        lineas[#lineas + 1] = FormatearResultadoFuncion("GetCollectibleIdFromType", COLLECTIBLE_CATEGORY_TYPE_HOUSE, 1)
    end
    do
        local saved = EZO and EZO.sv and EZO.sv.overlay and EZO.sv.overlay.recentOwnHouses
        lineas[#lineas + 1] = "recentOwnHouses=" .. tostring(type(saved) == "table" and #saved or 0)
    end
    do
        local saved = EZO and EZO.sv and EZO.sv.overlay and EZO.sv.overlay.recentOtherHouses
        lineas[#lineas + 1] = "recentOtherHouses=" .. tostring(type(saved) == "table" and #saved or 0)
    end

    local currentHouseId = nil
    if type(GetCurrentZoneHouseId) == "function" then
        local ok, houseId = pcall(GetCurrentZoneHouseId)
        if ok then currentHouseId = tonumber(houseId) or 0 end
    end
    if currentHouseId and currentHouseId > 0 then
        lineas[#lineas + 1] = FormatearResultadoFuncion("CanJumpToHouseFromCurrentLocation", currentHouseId)
        if _G.HOUSING_SOCIAL_MANAGER and type(_G.HOUSING_SOCIAL_MANAGER.GetHouseName) == "function" then
            local okName, houseName = pcall(function()
                return _G.HOUSING_SOCIAL_MANAGER:GetHouseName(currentHouseId)
            end)
            lineas[#lineas + 1] = "HOUSING_SOCIAL_MANAGER:GetHouseName(currentHouseId)=" .. tostring(okName and houseName or "error")
        else
            lineas[#lineas + 1] = "HOUSING_SOCIAL_MANAGER:GetHouseName=unavailable"
        end
    end

    lineas[#lineas + 1] = "========================"
    return lineas
end

function Debug.EmitReport(titulo, lineas, options)
    local force = options == true
        or (type(options) == "table" and options.force == true)
    local reporte = {}
    local tituloFinal = tostring(titulo or "EZOTools debug")
    reporte[#reporte + 1] = tituloFinal
    if type(lineas) == "table" then
        for _, linea in ipairs(lineas) do
            reporte[#reporte + 1] = tostring(linea)
        end
    elseif lineas ~= nil then
        reporte[#reporte + 1] = tostring(lineas)
    end
    if EZO.DebugPrint(table.concat(reporte, "\n"), force) then
        if EZO.CanOpenDebugLogViewer(force) then
            safeChat(zo_strformat(GetString(EZO_MSG_DEBUG_REPORT_SENT), tituloFinal))
        else
            safeChat(zo_strformat(GetString(EZO_MSG_DEBUG_REPORT_LOGGED_VIEWER_MISSING), tituloFinal))
        end
    else
        safeChat(GetString(EZO_MSG_DEBUG_LOGGER_UNAVAILABLE))
    end
end

local function MostrarAyudaDebug()
    if not EZO.IsDebugModeEnabled() then
        safeChat(GetString(EZO_MSG_DEBUG_MODE_DISABLED))
        return
    end
    Debug.EmitReport(GetString(EZO_CMD_DEBUG_TITLE), {
        GetString(EZO_CMD_DEBUG_INFO),
        GetString(EZO_CMD_DEBUG_GUILDS),
        GetString(EZO_CMD_DEBUG_TEX),
        GetString(EZO_CMD_DEBUG_TEXLOAD),
        GetString(EZO_CMD_DEBUG_DOTS),
        GetString(EZO_CMD_DEBUG_LAYOUT),
        GetString(EZO_CMD_DEBUG_FOOD),
        GetString(EZO_CMD_DEBUG_HOUSE),
    })
end

local function EjecutarDebugFood(modo)
    if not (EZOTools_Overlay and EZOTools_Overlay.SetFoodDebugState) then
        Debug.EmitReport("EZOTools debug food", GetString(EZO_CMD_LAYOUT_NA))
        return
    end
    modo = zo_strlower(tostring(modo or ""))
    if modo == "" then
        Debug.EmitReport("EZOTools debug food", GetString(EZO_CMD_DEBUG_FOOD_USAGE))
        return
    end
    if not EZOTools_Overlay.SetFoodDebugState(modo) then
        Debug.EmitReport("EZOTools debug food", GetString(EZO_CMD_DEBUG_FOOD_USAGE))
        return
    end
    Debug.EmitReport("EZOTools debug food", zo_strformat(GetString(EZO_CMD_DEBUG_FOOD_SET), modo))
end

local function EjecutarDebugTexload()
    local lineas = {}
    local ventana = _G["EZOTexTest"]
    if ventana then
        ventana:SetHidden(true)
    else
        ventana = WINDOW_MANAGER:CreateTopLevelWindow("EZOTexTest")
    end
    ventana:SetDimensions(1, 1)
    ventana:ClearAnchors()
    ventana:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    ventana:SetMouseEnabled(false)
    ventana:SetAlpha(0)
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
        t:SetHidden(true)
        lineas[#lineas + 1] = string.format("[%d] %s = %s", i, ruta:match("[^/]+$"), tostring(ok))
    end
    ventana:SetHidden(true)
    Debug.EmitReport("EZOTools debug texload", lineas)
end

local function EjecutarDebugTex()
    local lineas = {}
    local iconos = {
        {nombre="MountDot",    ctrl=EZOToolsMountDot2},
        {nombre="PetDot",      ctrl=EZOToolsPetDot2},
        {nombre="CompanionDot",ctrl=EZOToolsCompDot2},
        {nombre="AssistantDot",ctrl=EZOToolsAssistDot2},
    }
    for _, v in ipairs(iconos) do
        if v.ctrl then
            lineas[#lineas + 1] = string.format("%s: exists=true hidden=%s texLoaded=%s",
                v.nombre,
                tostring(v.ctrl:IsHidden()),
                tostring(v.ctrl:IsTextureLoaded()))
        else
            lineas[#lineas + 1] = v.nombre .. ": NO EXISTE"
        end
    end
    Debug.EmitReport("EZOTools debug tex", lineas)
end

local function EjecutarDebugLayout()
    if not (EZOTools_Overlay and EZOTools_Overlay.ToggleLayoutPreview) then
        Debug.EmitReport("EZOTools debug layout", GetString(EZO_CMD_LAYOUT_NA))
        return
    end
    local activo = EZOTools_Overlay.ToggleLayoutPreview()
    Debug.EmitReport("EZOTools debug layout", activo and GetString(EZO_CMD_LAYOUT_ON) or GetString(EZO_CMD_LAYOUT_OFF))
end

local function EjecutarDebugDots()
    local EZO_Overlay = EZOTools_Overlay
    if not EZO_Overlay then
        Debug.EmitReport("EZOTools debug dots", "EZOTools_Overlay no existe")
        return
    end
    local lineas = {}
    local pet = _G["EZOToolsPetDot2"]
    local comp = _G["EZOToolsCompDot2"]
    local assist = _G["EZOToolsAssistDot2"]
    lineas[#lineas + 1] = "PetDot2: " .. tostring(pet)
    lineas[#lineas + 1] = "CompDot2: " .. tostring(comp)
    lineas[#lineas + 1] = "AssistDot2: " .. tostring(assist)
    if pet then
        lineas[#lineas + 1] = "Pet hidden=" .. tostring(pet:IsHidden()) ..
            " texture=" .. tostring(pet:GetTextureFileName())
    end
    if comp then
        lineas[#lineas + 1] = "Comp hidden=" .. tostring(comp:IsHidden()) ..
            " texture=" .. tostring(comp:GetTextureFileName())
    end
    if assist then
        lineas[#lineas + 1] = "Assist hidden=" .. tostring(assist:IsHidden()) ..
            " texture=" .. tostring(assist:GetTextureFileName())
    end
    local numBuffs = GetNumBuffs and GetNumBuffs("player") or "N/A"
    local groupSize = GetGroupSize and GetGroupSize() or "N/A"
    local hasComp = HasActiveCompanion and HasActiveCompanion() or false
    local petId = GetActiveCollectibleByType and
        GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_VANITY_PET, GAMEPLAY_ACTOR_CATEGORY_PLAYER) or 0
    local assistId = GetActiveCollectibleByType and
        GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_ASSISTANT, GAMEPLAY_ACTOR_CATEGORY_PLAYER) or 0
    lineas[#lineas + 1] = "grupo=" .. tostring(groupSize) ..
        " companion=" .. tostring(hasComp) ..
        " petId=" .. tostring(petId) ..
        " assistId=" .. tostring(assistId)
    lineas[#lineas + 1] = "buffs=" .. tostring(numBuffs)
    Debug.EmitReport("EZOTools debug dots", lineas)
end

function Debug.Execute(sub, arg)
    if not EZO.IsDebugModeEnabled() then
        safeChat(GetString(EZO_MSG_DEBUG_MODE_DISABLED))
        return true
    end
    sub = zo_strlower(sub or "")
    if sub == "" or sub == "help" or sub == "?" then
        MostrarAyudaDebug()
        return true
    end
    if sub == "info" then
        Debug.EmitReport("EZOTools debug info", ConstruirReporteInfo())
        return true
    end
    if sub == "guilds" then
        Debug.EmitReport("EZOTools debug guilds", ConstruirReporteGuilds())
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
    if sub == "house" then
        Debug.EmitReport("EZOTools debug house", ConstruirReporteHouse())
        return true
    end
    MostrarAyudaDebug()
    return true
end
