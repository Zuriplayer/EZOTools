-- Ajustes de cámara de EZOTools.
-- Usa solo ajustes oficiales de ESO y deja que el cliente aplique sus límites.

EZOTools = EZOTools or {}
local EZO = EZOTools

EZO.CameraSettings = EZO.CameraSettings or {}
local MOD = EZO.CameraSettings

local EVENT_NAMESPACE = "EZOTools_CameraSettings"
local DEFAULT_DISTANCE = 15
local MIN_DISTANCE = 1
local MAX_DISTANCE = 50

local function ClampDistance(value)
    value = tonumber(value) or DEFAULT_DISTANCE
    if type(zo_clamp) == "function" then
        return zo_clamp(value, MIN_DISTANCE, MAX_DISTANCE)
    end
    if value < MIN_DISTANCE then return MIN_DISTANCE end
    if value > MAX_DISTANCE then return MAX_DISTANCE end
    return value
end

local function EnsureDefaults()
    if type(EZO.sv) ~= "table" then return end
    EZO.sv.camera = EZO.sv.camera or {}
    if EZO.sv.camera.thirdPersonDistanceEnabled == nil then
        EZO.sv.camera.thirdPersonDistanceEnabled = false
    end
    if EZO.sv.camera.thirdPersonDistance == nil then
        EZO.sv.camera.thirdPersonDistance = DEFAULT_DISTANCE
    end
end

local function IsCameraDistanceAvailable()
    return SETTING_TYPE_CAMERA ~= nil
        and CAMERA_SETTING_DISTANCE ~= nil
        and type(SetSetting) == "function"
end

function MOD.ApplyThirdPersonDistance()
    EnsureDefaults()
    if type(EZO.sv) ~= "table" or type(EZO.sv.camera) ~= "table" then
        return false
    end
    if EZO.sv.camera.thirdPersonDistanceEnabled ~= true then
        return false
    end
    if not IsCameraDistanceAvailable() then
        return false
    end

    local distance = ClampDistance(EZO.sv.camera.thirdPersonDistance)
    EZO.sv.camera.thirdPersonDistance = distance

    local ok = pcall(function()
        SetSetting(SETTING_TYPE_CAMERA, CAMERA_SETTING_DISTANCE, tostring(distance))
    end)
    if ok and type(SendAllCachedSettingMessages) == "function" then
        pcall(SendAllCachedSettingMessages)
    end
    return ok == true
end

local function GetAppliedDistance()
    if SETTING_TYPE_CAMERA == nil or CAMERA_SETTING_DISTANCE == nil or type(GetSetting) ~= "function" then
        return nil
    end

    local ok, value = pcall(function()
        return GetSetting(SETTING_TYPE_CAMERA, CAMERA_SETTING_DISTANCE)
    end)
    if not ok then
        return nil
    end
    return tonumber(value)
end

function MOD.Init()
    if MOD._initialized then
        return
    end
    MOD._initialized = true

    EnsureDefaults()
    MOD.ApplyThirdPersonDistance()

    if EVENT_MANAGER and EVENT_PLAYER_ACTIVATED then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, function()
            MOD.ApplyThirdPersonDistance()
        end)
    end
end

if EZOTools_LAM and EZOTools_LAM.RegisterSection then
    EZOTools_LAM.RegisterSection("camera", 18, function()
        EnsureDefaults()
        return {
            { type = "header", name = GetString(EZO_OPTION_CAMERA) },
            {
                type = "description",
                text = GetString(EZO_OPTION_CAMERA_DISTANCE_NOTE),
                width = "full",
            },
            {
                type = "checkbox",
                name = GetString(EZO_OPTION_CAMERA_DISTANCE_ENABLE),
                tooltip = GetString(EZO_OPTION_CAMERA_DISTANCE_ENABLE_TOOLTIP),
                getFunc = function()
                    EnsureDefaults()
                    return EZO.sv.camera.thirdPersonDistanceEnabled == true
                end,
                setFunc = function(v)
                    EnsureDefaults()
                    EZO.sv.camera.thirdPersonDistanceEnabled = v == true
                    MOD.ApplyThirdPersonDistance()
                end,
                default = false,
                disabled = function()
                    return not IsCameraDistanceAvailable()
                end,
            },
            {
                type = "slider",
                name = GetString(EZO_OPTION_CAMERA_DISTANCE),
                tooltip = GetString(EZO_OPTION_CAMERA_DISTANCE_TOOLTIP),
                min = MIN_DISTANCE,
                max = MAX_DISTANCE,
                step = 1,
                getFunc = function()
                    EnsureDefaults()
                    return ClampDistance(EZO.sv.camera.thirdPersonDistance)
                end,
                setFunc = function(v)
                    EnsureDefaults()
                    EZO.sv.camera.thirdPersonDistance = ClampDistance(v)
                    MOD.ApplyThirdPersonDistance()
                end,
                default = DEFAULT_DISTANCE,
                disabled = function()
                    EnsureDefaults()
                    return EZO.sv.camera.thirdPersonDistanceEnabled ~= true or not IsCameraDistanceAvailable()
                end,
            },
            {
                type = "description",
                text = function()
                    local applied = GetAppliedDistance()
                    if applied == nil then
                        return GetString(EZO_OPTION_CAMERA_DISTANCE_UNAVAILABLE)
                    end
                    return zo_strformat(GetString(EZO_OPTION_CAMERA_DISTANCE_APPLIED), applied)
                end,
                width = "full",
            },
        }
    end)
end
