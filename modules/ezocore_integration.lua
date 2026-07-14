-- Optional local integration with EZOCore.
-- EZOTools must keep working when EZOCore is not installed.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.EZOCoreIntegration = EZO.EZOCoreIntegration or {}
local MOD = EZO.EZOCoreIntegration

local registered = false
local languageCallbackRegistered = false

local function Debug(message)
    if EZO and type(EZO.DebugPrint) == "function" then
        EZO.DebugPrint("[EZOCore] " .. tostring(message))
    end
end

local function GetEZOCore()
    local core = _G.EZOCore
    if type(core) ~= "table" or type(core.RegisterAddon) ~= "function" then
        return nil
    end
    return core
end

local function IsSupportedLanguage(language)
    return language == "es" or language == "en"
end

local function OnCoreLanguageChanged()
    if not EZO.sv or not EZO.sv.general then
        return
    end

    local language = EZO.sv.general.language or (EZO.GetDefaultLanguage and EZO.GetDefaultLanguage()) or "auto"
    if type(EZO.ApplyLanguagePreference) == "function" then
        EZO.ApplyLanguagePreference(language)
    elseif EZO_Lang and type(EZO_Lang.Apply) == "function" then
        EZO_Lang.Apply(language)
    end

    if EZOTools_Overlay and type(EZOTools_Overlay.Refresh) == "function" then
        EZOTools_Overlay.Refresh()
    end
end

function MOD.IsAvailable()
    return GetEZOCore() ~= nil
end

function MOD.IsLanguageManagedByEZOCore()
    local core = GetEZOCore()
    if not core or type(core.IsLanguageGloballyManaged) ~= "function" then
        return false
    end

    local ok, managed = pcall(function()
        return core:IsLanguageGloballyManaged()
    end)
    return ok and managed == true
end

function MOD.GetLanguage()
    local core = GetEZOCore()
    if not MOD.IsLanguageManagedByEZOCore() or not core or type(core.GetLanguage) ~= "function" then
        return nil
    end

    local ok, language = pcall(function()
        return core:GetLanguage()
    end)
    if ok and IsSupportedLanguage(language) then
        return language
    end
    return nil
end

function MOD.RegisterLanguageCallback()
    if languageCallbackRegistered then
        return true
    end

    local core = GetEZOCore()
    if not core or type(core.RegisterCallback) ~= "function" then
        return false
    end

    local eventName = core.EVENT_LANGUAGE_CHANGED or "EZO_CORE_LANGUAGE_CHANGED"
    local ok, result = pcall(function()
        return core:RegisterCallback(eventName, OnCoreLanguageChanged)
    end)
    if ok and result == true then
        languageCallbackRegistered = true
        return true
    end
    return false
end

function MOD.RegisterLocalAddon()
    if registered then
        return true
    end

    local core = GetEZOCore()
    if not core then
        Debug("EZOCore not installed; continuing with local-only EZOTools behavior.")
        return false
    end

    local ok, result = pcall(function()
        return core:RegisterAddon({
            id = "ezotools",
            name = EZO.ADDON_NAME or "EZOTools",
            version = EZO.ADDON_VERSION or "0.0.0",
            addOnVersion = tonumber(EZO.ADDON_VERSION_NUMERIC) or 0,
            apiVersion = 1,
            capabilities = {
                "group.activities",
                "group.activityState.provider",
                "group.activityState.consumer",
                "family.language.consumer",
            },
        })
    end)

    if ok and result == true then
        registered = true
        MOD.RegisterLanguageCallback()
        Debug("Registered EZOTools with EZOCore.")
        return true
    end

    Debug("EZOCore registration skipped or rejected: " .. tostring(result))
    return false
end
