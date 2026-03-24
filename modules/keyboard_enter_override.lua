-- Módulo de interceptación de ENTER para EZOTools.
-- Cuando un diálogo de EZOTools (panel de comandos o ajustes) está visible,
-- intercepta la apertura del chat de texto para que ENTER active la selección
-- en lugar de abrir la barra de chat.
-- NOTA: no se engancha a GuiRoot; solo se prehookean los puntos de entrada del chat.

EZOTools_KeyboardEnterOverride = EZOTools_KeyboardEnterOverride or {}
local MOD = EZOTools_KeyboardEnterOverride

local EM           = EVENT_MANAGER
local instalado    = false
local intentos     = 0
local MAX_INTENTOS = 10

-- Devuelve true si algún diálogo de EZOTools está visible ahora mismo
local function HayDialogoEZOAbierto()
    local ezo = _G.EZOTools
    if type(ezo) ~= "table" then return false end

    -- Diálogo principal de comandos
    local dlg = nil
    if ezo.GamepadDialog and type(ezo.GamepadDialog.IsShowing) == "function" then
        dlg = ezo.GamepadDialog
    elseif _G.EZOTools_GamepadDialog and type(_G.EZOTools_GamepadDialog.IsShowing) == "function" then
        dlg = _G.EZOTools_GamepadDialog
    end
    if dlg and dlg.IsShowing() then return true end

    -- Diálogo de ajustes
    local sdlg = ezo.GamepadSettingsDialog
    if sdlg and type(sdlg.IsShowing) == "function" and sdlg.IsShowing() then
        return true
    end

    return false
end

-- Intercepta la apertura del chat si hay un diálogo EZO activo.
-- Devuelve true para bloquear la apertura del chat.
local function InterceptarEntradaChat()
    if not HayDialogoEZOAbierto() then return false end
    -- Ejecutar la selección actual del panel de comandos
    if _G.EZOTools and type(_G.EZOTools.ExecuteCommandPanelSelection) == "function" then
        pcall(function() _G.EZOTools.ExecuteCommandPanelSelection() end)
    end
    return true
end

-- Intenta instalar los prehooks sobre el sistema de chat
local function IntentarInstalar()
    if instalado then return true end
    if type(ZO_PreHook) ~= "function" then return false end

    local enganchadoAlgo = false

    -- Métodos del objeto CHAT_SYSTEM (más comunes)
    if _G.CHAT_SYSTEM and type(_G.CHAT_SYSTEM) == "table" then
        if type(_G.CHAT_SYSTEM.StartTextEntry) == "function" then
            ZO_PreHook(_G.CHAT_SYSTEM, "StartTextEntry", function() return InterceptarEntradaChat() end)
            enganchadoAlgo = true
        end
        if type(_G.CHAT_SYSTEM.BeginTextEntry) == "function" then
            ZO_PreHook(_G.CHAT_SYSTEM, "BeginTextEntry", function() return InterceptarEntradaChat() end)
            enganchadoAlgo = true
        end
    end

    -- Funciones globales (varían según versión de la UI)
    if type(_G.StartChatInput) == "function" then
        ZO_PreHook("StartChatInput", function() return InterceptarEntradaChat() end)
        enganchadoAlgo = true
    end
    if type(_G.ZO_ChatSystem_StartTextEntry) == "function" then
        ZO_PreHook("ZO_ChatSystem_StartTextEntry", function() return InterceptarEntradaChat() end)
        enganchadoAlgo = true
    end

    if enganchadoAlgo then
        instalado = true
        return true
    end
    return false
end

-- Reintento periódico hasta que el sistema de chat esté listo
local function ReintentarMasTarde()
    if instalado then return end
    intentos = intentos + 1
    if intentos > MAX_INTENTOS then
        -- Abandonar silenciosamente si no se puede instalar
        if EM then EM:UnregisterForUpdate("EZOTools_KeyboardEnterOverride_Retry") end
        return
    end
    if IntentarInstalar() then
        if EM then EM:UnregisterForUpdate("EZOTools_KeyboardEnterOverride_Retry") end
    end
end

function MOD.Init()
    if instalado then return end
    if IntentarInstalar() then return end

    -- El sistema de chat puede no estar listo en EVENT_ADD_ON_LOADED; reintentamos
    if EM and type(EM.RegisterForUpdate) == "function" then
        EM:RegisterForUpdate("EZOTools_KeyboardEnterOverride_Retry", 500, ReintentarMasTarde)
    elseif type(zo_callLater) == "function" then
        zo_callLater(function() IntentarInstalar() end, 500)
    end
end
