-- Módulo de keybinds de EZOTools.
-- Las acciones se declaran en Bindings.xml; los atajos predeterminados se
-- registran aquí con la API nativa de defaults, sin tocar bindings persistidos.
EZOTools_Keybinds = EZOTools_Keybinds or {}

local MOD = EZOTools_Keybinds
local EVENT_NAMESPACE = "EZOTools_DefaultKeybinds"

local DEFAULT_BINDS = {
    {
        action = "EZO_TOGGLE_COMMAND_PANEL",
        key = "KEY_NUMPAD1",
        modifiers = { "KEY_SHIFT" },
    },
    {
        action = "EZO_TOGGLE_UTILITY_PANEL",
        key = "KEY_NUMPAD2",
        modifiers = { "KEY_SHIFT" },
    },
    {
        action = "EZO_TRAVEL_PRIMARY_HOUSE",
        key = "KEY_NUMPAD_ADD",
    },
    {
        action = "EZO_RELOAD_UI",
        key = "KEY_NUMPAD_MINUS",
    },
}

local function IsAddonInstalledAndEnabled(addonName)
    if type(addonName) ~= "string" or addonName == "" then
        return false
    end

    local manager
    if type(_G.GetAddOnManager) == "function" then
        local ok, resolved = pcall(_G.GetAddOnManager)
        if ok then
            manager = resolved
        end
    end
    manager = manager or _G.AddOnManager or _G.ADD_ON_MANAGER
    if not manager or type(manager.GetNumAddOns) ~= "function" or type(manager.GetAddOnInfo) ~= "function" then
        return false
    end

    local ok, enabled = pcall(function()
        for index = 1, manager:GetNumAddOns() do
            local name, _, _, _, isEnabled = manager:GetAddOnInfo(index)
            if name == addonName then
                return isEnabled == true
            end
        end
        return false
    end)

    return ok and enabled == true
end

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

local function IsBindingAssignedToOtherAction(targetKey, targetMod1, targetMod2, targetMod3, targetMod4, excludedAction)
    if type(GetNumActionLayers) ~= "function"
        or type(GetActionLayerInfo) ~= "function"
        or type(GetActionLayerCategoryInfo) ~= "function"
        or type(GetActionInfo) ~= "function"
        or type(GetMaxBindingsPerAction) ~= "function"
        or type(GetActionBindingInfo) ~= "function" then
        return true
    end

    local ok, assigned = pcall(function()
        for layerIndex = 1, GetNumActionLayers() do
            local _, categoryCount = GetActionLayerInfo(layerIndex)
            for categoryIndex = 1, categoryCount do
                local _, actionCount = GetActionLayerCategoryInfo(layerIndex, categoryIndex)
                for actionIndex = 1, actionCount do
                    local actionName = GetActionInfo(layerIndex, categoryIndex, actionIndex)
                    if actionName ~= excludedAction then
                        for bindingIndex = 1, GetMaxBindingsPerAction() do
                            local key, mod1, mod2, mod3, mod4 = GetActionBindingInfo(
                                layerIndex,
                                categoryIndex,
                                actionIndex,
                                bindingIndex
                            )
                            if key == targetKey
                                and mod1 == targetMod1
                                and mod2 == targetMod2
                                and mod3 == targetMod3
                                and mod4 == targetMod4 then
                                return true
                            end
                        end
                    end
                end
            end
        end
        return false
    end)

    return not ok or assigned == true
end

local function ApplyDefaults()
    if not IsAddonInstalledAndEnabled("EZOTools") or type(CreateDefaultActionBind) ~= "function" then
        return false
    end

    local failed = 0

    for index = 1, #DEFAULT_BINDS do
        local definition = DEFAULT_BINDS[index]
        local key, mod1, mod2, mod3, mod4 = GetBindingParts(definition)

        if key and not IsBindingAssignedToOtherAction(
            key,
            mod1,
            mod2,
            mod3,
            mod4,
            definition.action
        ) then
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
