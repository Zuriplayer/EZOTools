-- Módulo de mantenimiento de EZOTools.
-- Gestiona la detección, reparación y recarga de equipamiento equipado.
-- Extraído de EZOTools.lua para mantener el fichero principal limpio.

local EZO = EZOTools

-- ============================================================
-- Helpers privados
-- ============================================================

local function ObtenerUmbralReparacion()
    return (EZO.sv and EZO.sv.general and tonumber(EZO.sv.general.repairThreshold)) or 40
end

local function ObtenerUmbralRecarga()
    return (EZO.sv and EZO.sv.general and tonumber(EZO.sv.general.rechargeThreshold)) or 50
end

-- Llama a una función de la API ESO de forma segura.
-- Intento directo primero; si falla reintenta con CallSecureProtected si está disponible.
local function LlamarApi(nombreFuncion, ...)
    local fn = _G[nombreFuncion]
    if type(fn) == "function" then
        local ok, res = pcall(fn, ...)
        if ok then return res end
        if type(CallSecureProtected) == "function" then
            local ok2, res2 = pcall(CallSecureProtected, nombreFuncion, ...)
            if ok2 then return res2 end
        end
        return nil
    end
    if type(CallSecureProtected) == "function" then
        local ok3, res3 = pcall(CallSecureProtected, nombreFuncion, ...)
        if ok3 then return res3 end
    end
    return nil
end

-- Busca el primer kit de reparación en la mochila
local function BuscarKitReparacion()
    if type(GetBagSize) ~= "function" or type(IsItemRepairKit) ~= "function" then return nil end
    for slot = 0, GetBagSize(BAG_BACKPACK) do
        if IsItemRepairKit(BAG_BACKPACK, slot) then
            return BAG_BACKPACK, slot
        end
    end
    return nil
end

-- Busca la primera gema de alma cargada en la mochila
local function BuscarGemaAlmaCargada()
    if type(GetBagSize) ~= "function" then return nil end
    for slot = 0, GetBagSize(BAG_BACKPACK) do
        if type(IsItemSoulGem) == "function" then
            if IsItemSoulGem(SOUL_GEM_TYPE_FILLED, BAG_BACKPACK, slot) then
                return BAG_BACKPACK, slot
            end
        elseif type(GetSoulGemItemInfo) == "function" then
            -- Fallback para versiones sin IsItemSoulGem
            local _, soulGemType = GetSoulGemItemInfo(BAG_BACKPACK, slot)
            if soulGemType == SOUL_GEM_TYPE_FILLED then
                return BAG_BACKPACK, slot
            end
        end
    end
    return nil
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

function EZOTools.CanRepairEquipped()
    local umbral = ObtenerUmbralReparacion()
    for _, ranura in ipairs(RANURAS_ARMADURA) do
        if type(DoesItemHaveDurability) == "function" and DoesItemHaveDurability(BAG_WORN, ranura) then
            local cond = GetItemCondition(BAG_WORN, ranura)
            if cond ~= nil and cond <= umbral then return true end
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
            if cond ~= nil and cond <= umbral then
                local kitBag, kitSlot = BuscarKitReparacion()
                if not kitBag then
                    EZOTools.Print(GetString(EZO_MSG_NO_REPAIR_KITS))
                    break
                end
                if _G["RepairItemWithRepairKit"] ~= nil then
                    LlamarApi("RepairItemWithRepairKit", BAG_WORN, ranura, kitBag, kitSlot)
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
        if pct ~= nil and pct <= umbral then return true end
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
        if pct ~= nil and pct <= umbral then
            -- Re-buscar gema en cada iteración por si se agotó el stack anterior
            local gemBag, gemSlot = BuscarGemaAlmaCargada()
            if not gemBag then
                EZOTools.Print(GetString(EZO_MSG_NO_SOUL_GEMS))
                break
            end
            if _G["ChargeItemWithSoulGem"] ~= nil then
                LlamarApi("ChargeItemWithSoulGem", BAG_WORN, ranura, gemBag, gemSlot)
                recargadoAlgo = true
            else
                EZOTools.Print(zo_strformat(GetString(EZO_MSG_ACTION_FAILED), "ChargeItemWithSoulGem"))
                break
            end
        end
    end
    if recargadoAlgo then EZOTools.Print(GetString(EZO_MSG_RECHARGE_DONE)) end
end
