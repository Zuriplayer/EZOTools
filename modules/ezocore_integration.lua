-- Optional local integration with EZOCore.
-- EZOTools must keep working when EZOCore is not installed.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.EZOCoreIntegration = EZO.EZOCoreIntegration or {}
local MOD = EZO.EZOCoreIntegration

local registered = false

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

function MOD.IsAvailable()
    return GetEZOCore() ~= nil
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
            },
        })
    end)

    if ok and result == true then
        registered = true
        Debug("Registered EZOTools with EZOCore.")
        return true
    end

    Debug("EZOCore registration skipped or rejected: " .. tostring(result))
    return false
end
