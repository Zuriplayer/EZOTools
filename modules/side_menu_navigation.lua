-- Navegacion comun para menus laterales gamepad de EZOTools.
-- Mantiene LT/RT y saltos de lista fuera del constructor de dialogos.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.SideMenuCore = EZO.SideMenuCore or {}
local Core = EZO.SideMenuCore

local function EsCabeceraEntrada(data)
    return type(data) == "table" and (data.isHeader or data.header)
end

local function ResolverLista(listaOrDialogo)
    if type(listaOrDialogo) == "function" then
        local ok, resolved = pcall(listaOrDialogo)
        if not ok then
            return nil
        end
        listaOrDialogo = resolved
    end

    if type(listaOrDialogo) ~= "table" and type(listaOrDialogo) ~= "userdata" then
        return nil
    end

    if listaOrDialogo.entryList then
        return listaOrDialogo.entryList
    end
    return listaOrDialogo
end

local function EstaListaNavegable(lista)
    if not lista then
        return false
    end
    if type(lista.IsActive) == "function" then
        local ok, active = pcall(function() return lista:IsActive() end)
        if ok and active == false then
            return false
        end
    end
    if type(lista.IsEmpty) == "function" then
        local ok, empty = pcall(function() return lista:IsEmpty() end)
        if ok and empty == true then
            return false
        end
    elseif type(lista.GetNumItems) == "function" then
        local ok, count = pcall(function() return lista:GetNumItems() end)
        if ok and (tonumber(count) or 0) <= 0 then
            return false
        end
    end
    return true
end

local function SaltarLista(listaOrDialogo, haciaFinal, headerComparator)
    local lista = ResolverLista(listaOrDialogo)
    if not EstaListaNavegable(lista) then
        return false
    end

    local movementTypes = _G.ZO_PARAMETRIC_MOVEMENT_TYPES or {}
    local jumpType = haciaFinal and movementTypes.JUMP_NEXT or movementTypes.JUMP_PREVIOUS
    local comparator = headerComparator or EsCabeceraEntrada

    if haciaFinal then
        if type(lista.SetNextSelectedDataByEval) == "function" then
            local ok, moved = pcall(function()
                return lista:SetNextSelectedDataByEval(comparator, jumpType)
            end)
            if ok and moved then
                return true
            end
        end
        if type(lista.SetLastIndexSelected) == "function" then
            local ok = pcall(function() lista:SetLastIndexSelected(jumpType) end)
            return ok == true
        end
    else
        if type(lista.SetPreviousSelectedDataByEval) == "function" then
            local ok, moved = pcall(function()
                return lista:SetPreviousSelectedDataByEval(comparator, jumpType)
            end)
            if ok and moved then
                return true
            end
        end
        if type(lista.SetFirstIndexSelected) == "function" then
            local ok = pcall(function() lista:SetFirstIndexSelected(jumpType) end)
            return ok == true
        end
    end

    return false
end

function Core.AddListTriggerNavigation(descriptor, listaOrDialogo, headerComparator)
    if type(descriptor) ~= "table" then
        return
    end

    descriptor[#descriptor + 1] = {
        name = "EZOToolsSideMenuPrevious",
        keybind = "UI_SHORTCUT_LEFT_TRIGGER",
        ethereal = true,
        callback = function()
            SaltarLista(listaOrDialogo, false, headerComparator)
        end,
    }
    descriptor[#descriptor + 1] = {
        name = "EZOToolsSideMenuNext",
        keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
        ethereal = true,
        callback = function()
            SaltarLista(listaOrDialogo, true, headerComparator)
        end,
    }
end

local triggerUpdateSerial = 0
local TRIGGER_UPDATE_MS = 40
local TRIGGER_THRESHOLD = 0.75

local function LeerMagnitudGatillo(izquierdo)
    if _G.DIRECTIONAL_INPUT then
        local metodo = izquierdo and DIRECTIONAL_INPUT.GetLeftTriggerMagnitude
            or DIRECTIONAL_INPUT.GetRightTriggerMagnitude
        if type(metodo) == "function" then
            local ok, magnitud = pcall(function()
                return metodo(DIRECTIONAL_INPUT)
            end)
            if ok then
                return tonumber(magnitud) or 0
            end
        end
    end

    local fallback = izquierdo and _G.GetGamepadLeftTriggerMagnitude
        or _G.GetGamepadRightTriggerMagnitude
    if type(fallback) == "function" then
        local ok, magnitud = pcall(fallback)
        if ok then
            return tonumber(magnitud) or 0
        end
    end
    return 0
end

local function MoverListaExtremo(listaOrDialogo, haciaFinal)
    local lista = ResolverLista(listaOrDialogo)
    if not EstaListaNavegable(lista) then
        return false
    end

    local movementTypes = _G.ZO_PARAMETRIC_MOVEMENT_TYPES or {}
    local jumpType = haciaFinal and movementTypes.JUMP_NEXT or movementTypes.JUMP_PREVIOUS
    local methodName = haciaFinal and "SetLastIndexSelected" or "SetFirstIndexSelected"
    local method = lista[methodName]
    if type(method) ~= "function" then
        return false
    end

    local ok = pcall(function()
        method(lista, jumpType)
    end)
    return ok == true
end

function Core.DetachListTriggerNavigation(owner)
    if type(owner) ~= "table" then
        return
    end

    if owner._listTriggerUpdateName and _G.EVENT_MANAGER
        and type(EVENT_MANAGER.UnregisterForUpdate) == "function" then
        local updateName = owner._listTriggerUpdateName
        pcall(function()
            EVENT_MANAGER:UnregisterForUpdate(updateName)
        end)
    end
    owner._listTriggerUpdateName = nil
    owner._listTriggerLeftDown = false
    owner._listTriggerRightDown = false
end

function Core.AttachListTriggerNavigation(owner, listaOrDialogo)
    if type(owner) ~= "table" or not _G.EVENT_MANAGER
        or type(EVENT_MANAGER.RegisterForUpdate) ~= "function" then
        return
    end

    if not ResolverLista(listaOrDialogo) then
        return
    end

    Core.DetachListTriggerNavigation(owner)

    triggerUpdateSerial = triggerUpdateSerial + 1
    owner._listTriggerUpdateName = "EZOTools_SideMenuTriggers_" .. tostring(triggerUpdateSerial)
    owner._listTriggerLeftDown = false
    owner._listTriggerRightDown = false

    EVENT_MANAGER:RegisterForUpdate(owner._listTriggerUpdateName, TRIGGER_UPDATE_MS, function()
        local lista = ResolverLista(listaOrDialogo)
        if not EstaListaNavegable(lista) then
            return
        end

        local leftDown = LeerMagnitudGatillo(true) >= TRIGGER_THRESHOLD
        local rightDown = LeerMagnitudGatillo(false) >= TRIGGER_THRESHOLD

        if leftDown and not owner._listTriggerLeftDown then
            MoverListaExtremo(lista, false)
        end
        if rightDown and not owner._listTriggerRightDown then
            MoverListaExtremo(lista, true)
        end

        owner._listTriggerLeftDown = leftDown
        owner._listTriggerRightDown = rightDown
    end)
end

Core.AttachListTriggerKeybinds = Core.AttachListTriggerNavigation
Core.DetachListTriggerKeybinds = Core.DetachListTriggerNavigation
