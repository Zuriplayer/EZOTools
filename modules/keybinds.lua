-- Módulo de keybinds de EZOTools.
-- Las acciones se declaran en Bindings.xml; los atajos predeterminados se
-- registran aquí con la API nativa de defaults, sin tocar bindings persistidos.
EZOTools_Keybinds = EZOTools_Keybinds or {}

local MOD = EZOTools_Keybinds
local EVENT_NAMESPACE = "EZOTools_DefaultKeybinds"

local DEFAULT_BINDS = {
    {
        action = "EZO_TOGGLE_COMMAND_PANEL",
        key = "KEY_GAMEPAD_BUTTON_3_HOLD",
    },
    {
        action = "EZO_TOGGLE_COMMAND_PANEL",
        key = "KEY_NUMPAD0",
        modifiers = { "KEY_CTRL", "KEY_ALT" },
    },
    {
        action = "EZO_TOGGLE_UTILITY_PANEL",
        key = "KEY_GAMEPAD_BUTTON_4_HOLD",
    },
    {
        action = "EZO_TOGGLE_UTILITY_PANEL",
        key = "KEY_NUMPAD1",
        modifiers = { "KEY_CTRL", "KEY_ALT" },
    },
    {
        action = "EZO_TOGGLE_GROUP_ACTIVITIES_PANEL",
        key = "KEY_NUMPAD2",
        modifiers = { "KEY_CTRL", "KEY_ALT" },
    },
    {
        action = "EZO_RESET_INSTANCE",
        key = "KEY_NUMPAD3",
        modifiers = { "KEY_CTRL", "KEY_ALT" },
    },
    {
        action = "EZO_DISBAND_GROUP",
        key = "KEY_NUMPAD4",
        modifiers = { "KEY_CTRL", "KEY_ALT" },
    },
    {
        action = "EZO_TRAVEL_PRIMARY_HOUSE",
        key = "KEY_H",
        modifiers = { "KEY_ALT" },
    },
    {
        action = "EZO_RELOAD_UI",
        key = "KEY_NUMPAD_MINUS",
    },
}

local function GetKeyConstant(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end

    local value = _G[name]
    if type(value) == "number" then
        return value
    end

    return nil
end

local function GetBindingParts(definition)
    local key = GetKeyConstant(definition.key)
    if not key then
        return nil
    end

    local modifiers = definition.modifiers or {}
    local mod1 = GetKeyConstant(modifiers[1]) or KEY_INVALID
    local mod2 = GetKeyConstant(modifiers[2]) or KEY_INVALID
    local mod3 = GetKeyConstant(modifiers[3]) or KEY_INVALID
    local mod4 = GetKeyConstant(modifiers[4]) or KEY_INVALID

    return key, mod1, mod2, mod3, mod4
end

local function ApplyDefaults()
    if type(CreateDefaultActionBind) ~= "function" then
        return false
    end

    local failed = 0

    for index = 1, #DEFAULT_BINDS do
        local definition = DEFAULT_BINDS[index]
        local key, mod1, mod2, mod3, mod4 = GetBindingParts(definition)

        if key then
            local ok = pcall(function()
                CreateDefaultActionBind(definition.action, key, mod1, mod2, mod3, mod4)
            end)

            if not ok then
                failed = failed + 1
            end
        else
            failed = failed + 1
        end
    end

    return failed == 0
end

function MOD.Init()
    if not EVENT_MANAGER or type(EVENT_MANAGER.RegisterForEvent) ~= "function" or type(EVENT_KEYBINDINGS_LOADED) ~= "number" then
        return
    end

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_KEYBINDINGS_LOADED, function()
        EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_KEYBINDINGS_LOADED)
        ApplyDefaults()
    end)
end
