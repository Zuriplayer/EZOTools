-- Gestion de casas para HOLD Y.
-- Mantiene fuera de overlay.lua la deteccion, persistencia y ejecucion de casas.
EZOTools_QuickUtilityHouses = EZOTools_QuickUtilityHouses or {}

local MOD = EZOTools_QuickUtilityHouses
local EZO = EZOTools

local OWN_HOUSE_HISTORY_LIMIT = 10
local OTHER_HOUSE_HISTORY_LIMIT = 20
local initialized = false

local function ObtenerOverlaySV()
    return EZO and EZO.sv and EZO.sv.overlay or nil
end

local function CerrarDialogosUtilidadRapida()
    local recentDialog = EZO and EZO.GamepadUtilityRecentDialog
    if recentDialog and type(recentDialog.Close) == "function" then
        pcall(function() recentDialog.Close() end)
    end
    local utilityDialog = EZO and EZO.GamepadUtilityDialog
    if utilityDialog and type(utilityDialog.Close) == "function" then
        pcall(function() utilityDialog.Close() end)
    end
end

local function EjecutarTrasCerrarUtilidades(fn)
    if type(fn) ~= "function" then return false end
    CerrarDialogosUtilidadRapida()
    if type(zo_callLater) == "function" then
        zo_callLater(function() pcall(fn) end, 120)
    else
        pcall(fn)
    end
    return true
end

local function NormalizarTextoEtiqueta(texto)
    texto = tostring(texto or "")
    texto = texto:gsub("|H.-|h(.-)|h", "%1")
    texto = texto:gsub("|c%x%x%x%x%x%x", "")
    texto = texto:gsub("|r", "")
    texto = texto:gsub("%^%a+", "")
    texto = texto:gsub("\n", " ")
    texto = texto:gsub("%s+", " ")
    return zo_strtrim(texto)
end

local function ObtenerNombreCasa(houseId)
    houseId = tonumber(houseId) or 0
    if houseId <= 0 then
        return ""
    end
    local manager = _G.HOUSING_SOCIAL_MANAGER
    if manager and type(manager.GetHouseName) == "function" then
        local ok, nombre = pcall(function()
            return manager:GetHouseName(houseId)
        end)
        if ok and type(nombre) == "string" and nombre ~= "" then
            return nombre
        end
    end
    return zo_strformat(GetString(EZO_UTILITY_HOUSES_FALLBACK_NAME) .. " <<1>>", houseId)
end

local function ObtenerCasaPrincipalId()
    if type(GetHousingPrimaryHouse) ~= "function" then
        return 0
    end
    local ok, houseId = pcall(GetHousingPrimaryHouse)
    if ok then
        return tonumber(houseId) or 0
    end
    return 0
end

local function ObtenerCasaActualPropiaId()
    if type(GetCurrentZoneHouseId) ~= "function" then
        return 0
    end
    local ok, houseId = pcall(GetCurrentZoneHouseId)
    houseId = ok and (tonumber(houseId) or 0) or 0
    if houseId <= 0 then
        return 0
    end

    if type(IsOwnerOfCurrentHouse) ~= "function" then
        return 0
    end
    local okOwner, isOwner = pcall(IsOwnerOfCurrentHouse)
    if not okOwner or isOwner ~= true then
        return 0
    end

    if houseId == ObtenerCasaPrincipalId() then
        return 0
    end
    return houseId
end

local function ObtenerPropietarioCasaActual()
    if type(GetCurrentHouseOwner) ~= "function" then
        return ""
    end
    local ok, owner = pcall(GetCurrentHouseOwner)
    if not ok then
        return ""
    end
    return zo_strtrim(tostring(owner or ""))
end

local function ObtenerCasaActualAjena()
    if type(GetCurrentZoneHouseId) ~= "function" then
        return nil
    end
    local ok, houseId = pcall(GetCurrentZoneHouseId)
    houseId = ok and (tonumber(houseId) or 0) or 0
    if houseId <= 0 then
        return nil
    end

    if type(IsOwnerOfCurrentHouse) == "function" then
        local okOwner, isOwner = pcall(IsOwnerOfCurrentHouse)
        if not okOwner or isOwner == true then
            return nil
        end
    end

    local owner = ObtenerPropietarioCasaActual()
    if owner == "" then
        return nil
    end
    local player = type(GetDisplayName) == "function" and tostring(GetDisplayName() or "") or ""
    if player ~= "" and zo_strlower(owner) == zo_strlower(player) then
        return nil
    end

    return {
        houseId = houseId,
        owner = owner,
        name = ObtenerNombreCasa(houseId),
    }
end

local function ObtenerHistorialCasasPropias()
    local overlaySV = ObtenerOverlaySV()
    if not overlaySV then
        return {}
    end
    local history = overlaySV.recentOwnHouses
    if type(history) ~= "table" then
        history = {}
        overlaySV.recentOwnHouses = history
    end
    return history
end

local function ObtenerHistorialCasasAjenas()
    local overlaySV = ObtenerOverlaySV()
    if not overlaySV then
        return {}
    end
    local history = overlaySV.recentOtherHouses
    if type(history) ~= "table" then
        history = {}
        overlaySV.recentOtherHouses = history
    end
    return history
end

local function GuardarCasaPropiaEnHistorial(houseId)
    local overlaySV = ObtenerOverlaySV()
    if not overlaySV then return end
    houseId = tonumber(houseId) or 0
    if houseId <= 0 or houseId == ObtenerCasaPrincipalId() then
        return
    end

    local history = ObtenerHistorialCasasPropias()
    local nombre = ObtenerNombreCasa(houseId)
    local newHistory = {
        {
            houseId = houseId,
            name = nombre,
        },
    }

    for _, entry in ipairs(history) do
        local oldHouseId = nil
        local oldName = ""
        if type(entry) == "table" then
            oldHouseId = tonumber(entry.houseId) or 0
            oldName = tostring(entry.name or "")
        else
            oldHouseId = tonumber(entry) or 0
        end
        if oldHouseId > 0 and oldHouseId ~= houseId and oldHouseId ~= ObtenerCasaPrincipalId() then
            newHistory[#newHistory + 1] = {
                houseId = oldHouseId,
                name = oldName ~= "" and oldName or ObtenerNombreCasa(oldHouseId),
            }
        end
        if #newHistory >= OWN_HOUSE_HISTORY_LIMIT then
            break
        end
    end

    overlaySV.recentOwnHouses = newHistory
end

local function GuardarCasaAjenaEnHistorial(houseId, owner, houseName)
    local overlaySV = ObtenerOverlaySV()
    if not overlaySV then return end
    houseId = tonumber(houseId) or 0
    owner = zo_strtrim(tostring(owner or ""))
    if houseId <= 0 or owner == "" then
        return
    end

    local ownerKey = zo_strlower(owner)
    local history = ObtenerHistorialCasasAjenas()
    local newHistory = {
        {
            houseId = houseId,
            owner = owner,
            name = tostring(houseName or "") ~= "" and tostring(houseName) or ObtenerNombreCasa(houseId),
        },
    }

    for _, entry in ipairs(history) do
        if type(entry) == "table" then
            local oldHouseId = tonumber(entry.houseId) or 0
            local oldOwner = zo_strtrim(tostring(entry.owner or ""))
            local oldOwnerKey = zo_strlower(oldOwner)
            if oldHouseId > 0 and oldOwner ~= "" and not (oldHouseId == houseId and oldOwnerKey == ownerKey) then
                newHistory[#newHistory + 1] = {
                    houseId = oldHouseId,
                    owner = oldOwner,
                    name = tostring(entry.name or "") ~= "" and tostring(entry.name) or ObtenerNombreCasa(oldHouseId),
                }
            end
        end
        if #newHistory >= OTHER_HOUSE_HISTORY_LIMIT then
            break
        end
    end

    overlaySV.recentOtherHouses = newHistory
end

local function ViajarACasaPropia(houseId)
    houseId = tonumber(houseId) or 0
    if houseId <= 0 or type(RequestJumpToHouse) ~= "function" then
        return false
    end
    GuardarCasaPropiaEnHistorial(houseId)
    return EjecutarTrasCerrarUtilidades(function()
        RequestJumpToHouse(houseId)
    end)
end

local function ViajarACasaAjena(houseId, owner)
    houseId = tonumber(houseId) or 0
    owner = zo_strtrim(tostring(owner or ""))
    if houseId <= 0 or owner == "" then
        return false
    end
    local manager = _G.HOUSING_SOCIAL_MANAGER
    if not ((manager and type(manager.VisitHouse) == "function") or type(JumpToSpecificHouse) == "function") then
        return false
    end
    GuardarCasaAjenaEnHistorial(houseId, owner, ObtenerNombreCasa(houseId))
    return EjecutarTrasCerrarUtilidades(function()
        if manager and type(manager.VisitHouse) == "function" then
            manager:VisitHouse(houseId, owner, false)
        elseif type(JumpToSpecificHouse) == "function" then
            JumpToSpecificHouse(owner, houseId, false)
        end
    end)
end

local function AgregarEntrada(entries, texto, callback, previewData)
    if type(entries) ~= "table" or type(texto) ~= "string" or texto == "" or type(callback) ~= "function" then
        return
    end
    local data = {
        text = texto,
        callback = callback,
    }
    if type(previewData) == "table" then
        for k, v in pairs(previewData) do
            data[k] = v
        end
    end
    entries[#entries + 1] = data
end

function MOD.RecordCurrentHouse()
    local ownHouseId = ObtenerCasaActualPropiaId()
    if ownHouseId > 0 then
        GuardarCasaPropiaEnHistorial(ownHouseId)
        return true
    end

    local otherHouse = ObtenerCasaActualAjena()
    if type(otherHouse) == "table" then
        GuardarCasaAjenaEnHistorial(otherHouse.houseId, otherHouse.owner, otherHouse.name)
        return true
    end
    return false
end

function MOD.ExecuteAction(key)
    if tostring(key or "") == "houses" then
        return EjecutarTrasCerrarUtilidades(function()
            local collections = EZO and EZO.QuickUtilityCollections or _G.EZOTools_QuickUtilityCollections
            if collections and type(collections.OpenRootByCategoryType) == "function" then
                collections.OpenRootByCategoryType(COLLECTIBLE_CATEGORY_TYPE_HOUSE)
            end
        end)
    end
    return false
end

function MOD.BuildRecentEntries(key, useEmptyAction)
    key = tostring(key or "")
    local entries = {}

    if key == "houses" then
        local primaryHouseId = ObtenerCasaPrincipalId()
        for _, entry in ipairs(ObtenerHistorialCasasPropias()) do
            local houseId = 0
            local houseName = ""
            if type(entry) == "table" then
                houseId = tonumber(entry.houseId) or 0
                houseName = tostring(entry.name or "")
            else
                houseId = tonumber(entry) or 0
            end
            if houseId > 0 and houseId ~= primaryHouseId then
                if houseName == "" then
                    houseName = ObtenerNombreCasa(houseId)
                end
                local label = NormalizarTextoEtiqueta(houseName)
                if label ~= "" then
                    AgregarEntrada(entries, label, function()
                        return ViajarACasaPropia(houseId)
                    end, {
                        previewKind = "house",
                        previewHouseId = houseId,
                    })
                end
            end
        end

        if #entries == 0 then
            AgregarEntrada(entries, GetString(EZO_UTILITY_HOUSES_VISIT_HINT), function()
                return false
            end, {
                empty = true,
            })
        end

        if useEmptyAction == true or #entries == 0 then
            AgregarEntrada(entries, GetString(EZO_UTILITY_HOUSES_OPEN_COLLECTIONS), function()
                return MOD.ExecuteAction("houses")
            end, {
                emptyAction = true,
            })
        end
        return entries
    end

    if key == "otherHouses" then
        for _, entry in ipairs(ObtenerHistorialCasasAjenas()) do
            if type(entry) == "table" then
                local houseId = tonumber(entry.houseId) or 0
                local owner = zo_strtrim(tostring(entry.owner or ""))
                if houseId > 0 and owner ~= "" then
                    local houseName = tostring(entry.name or "")
                    if houseName == "" then
                        houseName = ObtenerNombreCasa(houseId)
                    end
                    local label = NormalizarTextoEtiqueta(zo_strformat("<<1>> - <<2>>", houseName, owner))
                    if label ~= "" then
                        AgregarEntrada(entries, label, function()
                            return ViajarACasaAjena(houseId, owner)
                        end, {
                            previewKind = "otherHouse",
                            previewHouseId = houseId,
                            previewOwner = owner,
                        })
                    end
                end
            end
        end

        if #entries == 0 then
            AgregarEntrada(entries, GetString(EZO_UTILITY_OTHER_HOUSES_VISIT_HINT), function()
                return false
            end, {
                empty = true,
            })
        end
        return entries
    end

    return nil
end

function MOD.GetHistoryEmptyLabel(key)
    key = tostring(key or "")
    if key == "houses" then
        return GetString(EZO_UTILITY_HOUSES_HISTORY_EMPTY)
    end
    if key == "otherHouses" then
        return GetString(EZO_UTILITY_OTHER_HOUSES_HISTORY_EMPTY)
    end
    return nil
end

function MOD.Init()
    if initialized then
        return
    end
    initialized = true

    MOD.RecordCurrentHouse()

    if EVENT_MANAGER and EVENT_PLAYER_ACTIVATED then
        EVENT_MANAGER:RegisterForEvent(
            "EZOTools_QuickUtilityHouses_PlayerActivated",
            EVENT_PLAYER_ACTIVATED,
            function()
                MOD.RecordCurrentHouse()
                if type(zo_callLater) == "function" then
                    zo_callLater(function()
                        MOD.RecordCurrentHouse()
                    end, 1000)
                end
            end
        )
    end
end
