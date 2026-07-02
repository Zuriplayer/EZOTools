-- Módulo de mantenimiento de EZOTools.
-- Gestiona la detección, reparación y recarga de equipamiento equipado.
-- Extraído de EZOTools.lua para mantener el fichero principal limpio.

local EZO = EZOTools

-- ============================================================
-- Utilidades internas del módulo.
-- ============================================================

local function ObtenerUmbralReparacion()
    return (EZO.sv and EZO.sv.general and tonumber(EZO.sv.general.repairThreshold)) or 40
end

local function ObtenerUmbralRecarga()
    return (EZO.sv and EZO.sv.general and tonumber(EZO.sv.general.rechargeThreshold)) or 50
end

local function ObtenerUmbralStockConsumibles()
    return 10
end

local function ObtenerUmbralStockKitsReparacion()
    return (EZO.sv and EZO.sv.general and tonumber(EZO.sv.general.repairKitAlertThreshold)) or ObtenerUmbralStockConsumibles()
end

local function ObtenerUmbralStockGemasAlma()
    return (EZO.sv and EZO.sv.general and tonumber(EZO.sv.general.soulGemAlertThreshold)) or ObtenerUmbralStockConsumibles()
end

local function EstaAlertaKitsReparacionActiva()
    if not (EZO.sv and EZO.sv.general) then return true end
    return EZO.sv.general.repairKitAlertEnabled ~= false
end

local function EstaAlertaGemasAlmaActiva()
    if not (EZO.sv and EZO.sv.general) then return true end
    return EZO.sv.general.soulGemAlertEnabled ~= false
end

-- Llama a una función de la API ESO de forma segura.
-- Intento directo primero; si falla reintenta con CallSecureProtected si está disponible.
local function LlamarApi(nombreFuncion, ...)
    local esProtegida = false
    if type(IsProtectedFunction) == "function" then
        local okProt, resProt = pcall(IsProtectedFunction, nombreFuncion)
        if okProt and resProt then
            esProtegida = true
        end
    end

    local fn = _G[nombreFuncion]
    if type(fn) == "function" then
        local ok, res = pcall(fn, ...)
        if ok then
            if res ~= nil and res ~= false then
                return res
            end
            if res == nil and not esProtegida then
                return true
            end
        end
        if esProtegida and type(CallSecureProtected) == "function" then
            local ok2, res2 = pcall(CallSecureProtected, nombreFuncion, ...)
            if ok2 then return res2 end
        end
        return res
    end
    if type(CallSecureProtected) == "function" then
        local ok3, res3 = pcall(CallSecureProtected, nombreFuncion, ...)
        if ok3 then return res3 end
    end
    return nil
end

local function IterarSlotsMochila(fnPorSlot)
    if type(GetBagSize) ~= "function" or type(fnPorSlot) ~= "function" then return nil end
    local bagSize = GetBagSize(BAG_BACKPACK)
    if type(bagSize) ~= "number" or bagSize <= 0 then return nil end
    for slot = 0, bagSize - 1 do
        local resultados = { fnPorSlot(slot) }
        if resultados[1] ~= nil then
            return unpack(resultados)
        end
    end
    return nil
end

local function ObtenerStackSlot(slot)
    if type(GetSlotStackSize) ~= "function" then return 1 end
    local stack = GetSlotStackSize(BAG_BACKPACK, slot)
    if type(stack) ~= "number" or stack < 1 then return 1 end
    return stack
end

-- ============================================================
-- Caché de recuentos de consumibles.
-- Recontar la mochila entera en cada refresco es caro y el resultado
-- solo cambia cuando cambia el inventario: se guarda el último recuento
-- y se invalida por evento (ver registro al final del módulo).
-- ============================================================
local cachedRepairKitCount = nil
local cachedFilledSoulGemCount = nil

local function InvalidarCacheStock()
    cachedRepairKitCount = nil
    cachedFilledSoulGemCount = nil
end

-- Busca el primer kit de reparación en la mochila
local function BuscarKitReparacion()
    if type(IsItemRepairKit) ~= "function" then return nil end
    return IterarSlotsMochila(function(slot)
        if IsItemRepairKit(BAG_BACKPACK, slot) then
            return BAG_BACKPACK, slot
        end
        return nil
    end)
end

local function ContarKitsReparacion()
    if cachedRepairKitCount ~= nil then
        return cachedRepairKitCount
    end
    if type(IsItemRepairKit) ~= "function" then return 0 end
    local total = 0
    IterarSlotsMochila(function(slot)
        if IsItemRepairKit(BAG_BACKPACK, slot) then
            total = total + ObtenerStackSlot(slot)
        end
        return nil
    end)
    cachedRepairKitCount = total
    return total
end

-- Busca la primera gema de alma cargada en la mochila
local function BuscarGemaAlmaCargada()
    return IterarSlotsMochila(function(slot)
        if type(IsItemSoulGem) == "function" then
            if IsItemSoulGem(SOUL_GEM_TYPE_FILLED, BAG_BACKPACK, slot) then
                return BAG_BACKPACK, slot
            end
        elseif type(GetSoulGemItemInfo) == "function" then
            -- Compatibilidad con clientes donde no exista IsItemSoulGem.
            local _, soulGemType = GetSoulGemItemInfo(BAG_BACKPACK, slot)
            if soulGemType == SOUL_GEM_TYPE_FILLED then
                return BAG_BACKPACK, slot
            end
        end
        return nil
    end)
end

local function ContarGemasAlmaCargadas()
    if cachedFilledSoulGemCount ~= nil then
        return cachedFilledSoulGemCount
    end
    local total = 0
    IterarSlotsMochila(function(slot)
        local esGema = false
        if type(IsItemSoulGem) == "function" then
            esGema = IsItemSoulGem(SOUL_GEM_TYPE_FILLED, BAG_BACKPACK, slot) and true or false
        elseif type(GetSoulGemItemInfo) == "function" then
            local _, soulGemType = GetSoulGemItemInfo(BAG_BACKPACK, slot)
            esGema = (soulGemType == SOUL_GEM_TYPE_FILLED)
        end
        if esGema then
            total = total + ObtenerStackSlot(slot)
        end
        return nil
    end)
    cachedFilledSoulGemCount = total
    return total
end

-- Ranuras de armadura/joyería con durabilidad
local RANURAS_ARMADURA = {
    EQUIP_SLOT_HEAD, EQUIP_SLOT_SHOULDERS, EQUIP_SLOT_CHEST, EQUIP_SLOT_HAND,
    EQUIP_SLOT_WAIST, EQUIP_SLOT_LEGS, EQUIP_SLOT_FEET,
    EQUIP_SLOT_NECK, EQUIP_SLOT_RING1, EQUIP_SLOT_RING2,
    EQUIP_SLOT_MAIN_HAND, EQUIP_SLOT_OFF_HAND, EQUIP_SLOT_BACKUP_MAIN, EQUIP_SLOT_BACKUP_OFF,
}

-- Ranuras de armas con encantamiento recargable
local RANURAS_ARMAS = {
    EQUIP_SLOT_MAIN_HAND, EQUIP_SLOT_OFF_HAND,
    EQUIP_SLOT_BACKUP_MAIN, EQUIP_SLOT_BACKUP_OFF,
}

-- Devuelve el porcentaje de carga del encantamiento de un arma (0-100) o nil si no aplica
local function ObtenerPorcentajeCargaArma(ranura)
    if type(IsItemChargeable) == "function" then
        if not IsItemChargeable(BAG_WORN, ranura) then return nil end
    end
    if type(GetChargeInfoForItem) ~= "function" then return nil end
    local cargas, maxCargas = GetChargeInfoForItem(BAG_WORN, ranura)
    if cargas == nil or maxCargas == nil or maxCargas <= 0 then return nil end
    return math.max(0, math.min(100, (cargas * 100) / maxCargas))
end

-- ============================================================
-- API pública (expuesta en EZOTools.*)
-- ============================================================

function EZOTools.GetRepairKitCount()
    return ContarKitsReparacion()
end

function EZOTools.GetFilledSoulGemCount()
    return ContarGemasAlmaCargadas()
end

function EZOTools.GetRepairKitStockThreshold()
    return ObtenerUmbralStockKitsReparacion()
end

function EZOTools.GetSoulGemStockThreshold()
    return ObtenerUmbralStockGemasAlma()
end

function EZOTools.HasLowRepairKitStock()
    return EstaAlertaKitsReparacionActiva() and ContarKitsReparacion() <= ObtenerUmbralStockKitsReparacion()
end

function EZOTools.HasLowSoulGemStock()
    return EstaAlertaGemasAlmaActiva() and ContarGemasAlmaCargadas() <= ObtenerUmbralStockGemasAlma()
end

function EZOTools.CanRepairEquipped()
    local umbral = ObtenerUmbralReparacion()
    for _, ranura in ipairs(RANURAS_ARMADURA) do
        if type(DoesItemHaveDurability) == "function" and DoesItemHaveDurability(BAG_WORN, ranura) then
            local cond = GetItemCondition(BAG_WORN, ranura)
            if cond ~= nil and cond < 100 and cond <= umbral then return true end
        end
    end
    return false
end

function EZOTools.RepairEquipped()
    if IsPlayerInCombat and IsPlayerInCombat() then
        EZOTools.Print(GetString(EZO_MSG_CANT_REPAIR_COMBAT))
        return
    end
    local umbral = ObtenerUmbralReparacion()
    local reparadoAlgo = false
    for _, ranura in ipairs(RANURAS_ARMADURA) do
        if type(DoesItemHaveDurability) == "function" and DoesItemHaveDurability(BAG_WORN, ranura) then
            local cond = GetItemCondition(BAG_WORN, ranura)
            if cond ~= nil and cond < 100 and cond <= umbral then
                local kitBag, kitSlot = BuscarKitReparacion()
                if not kitBag then
                    EZOTools.Print(GetString(EZO_MSG_NO_REPAIR_KITS))
                    break
                end
                if _G["RepairItemWithRepairKit"] ~= nil then
                    local ok = LlamarApi("RepairItemWithRepairKit", BAG_WORN, ranura, kitBag, kitSlot)
                    if ok == nil or ok == false then
                        EZOTools.Print(zo_strformat(GetString(EZO_MSG_ACTION_FAILED), "RepairItemWithRepairKit"))
                        break
                    end
                    reparadoAlgo = true
                else
                    EZOTools.Print(zo_strformat(GetString(EZO_MSG_ACTION_FAILED), "RepairItemWithRepairKit"))
                    break
                end
            end
        end
    end
    if reparadoAlgo then EZOTools.Print(GetString(EZO_MSG_REPAIR_DONE)) end
end

function EZOTools.CanRechargeWeapons()
    local umbral = ObtenerUmbralRecarga()
    for _, ranura in ipairs(RANURAS_ARMAS) do
        local pct = ObtenerPorcentajeCargaArma(ranura)
        if pct ~= nil and pct < 100 and pct <= umbral then return true end
    end
    return false
end

function EZOTools.RechargeWeapons()
    if IsPlayerInCombat and IsPlayerInCombat() then
        EZOTools.Print(GetString(EZO_MSG_CANT_RECHARGE_COMBAT))
        return
    end
    local umbral = ObtenerUmbralRecarga()
    local recargadoAlgo = false
    for _, ranura in ipairs(RANURAS_ARMAS) do
        local pct = ObtenerPorcentajeCargaArma(ranura)
        if pct ~= nil and pct < 100 and pct <= umbral then
            -- Re-buscar gema en cada iteración por si se agotó el stack anterior
            local gemBag, gemSlot = BuscarGemaAlmaCargada()
            if not gemBag then
                EZOTools.Print(GetString(EZO_MSG_NO_SOUL_GEMS))
                break
            end
            if _G["ChargeItemWithSoulGem"] ~= nil then
                local ok = LlamarApi("ChargeItemWithSoulGem", BAG_WORN, ranura, gemBag, gemSlot)
                if ok == nil or ok == false then
                    EZOTools.Print(zo_strformat(GetString(EZO_MSG_ACTION_FAILED), "ChargeItemWithSoulGem"))
                    break
                end
                recargadoAlgo = true
            else
                EZOTools.Print(zo_strformat(GetString(EZO_MSG_ACTION_FAILED), "ChargeItemWithSoulGem"))
                break
            end
        end
    end
    if recargadoAlgo then EZOTools.Print(GetString(EZO_MSG_RECHARGE_DONE)) end
end

-- ============================================================
-- Invalidación de la caché de recuentos.
-- Solo interesa la mochila: el filtro por bag evita despertar con
-- cambios de banco, casa o equipo puesto.
-- ============================================================
EVENT_MANAGER:RegisterForEvent("EZOTools_Maintenance_Stock",
    EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
    function() InvalidarCacheStock() end)
if type(EVENT_MANAGER.AddFilterForEvent) == "function" and REGISTER_FILTER_BAG_ID ~= nil then
    EVENT_MANAGER:AddFilterForEvent("EZOTools_Maintenance_Stock",
        EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
        REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
end
EVENT_MANAGER:RegisterForEvent("EZOTools_Maintenance_Activated",
    EVENT_PLAYER_ACTIVATED,
    function() InvalidarCacheStock() end)




