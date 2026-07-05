-- Módulo de construcción de entradas de menú para EZOTools.
-- Es la fuente única de verdad para qué opciones aparecen en el menú,
-- tanto en el menú de ratón como en el diálogo de gamepad.
-- La visibilidad de cada entrada se evalúa en el momento de construir la lista.

EZOTools_Actions = EZOTools_Actions or {}
local A = EZOTools_Actions
local EZO = EZOTools

local function LlamadaSegura(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, ...)
    return ok, res
end

local function JugadorEnCombate()
    local ok, val = LlamadaSegura(IsUnitInCombat, "player")
    if ok then return val == true end
    return false
end

local function JugadorEnInstancia()
    local ok, dentro = LlamadaSegura(IsInInstance)
    if ok then return dentro == true end
    ok, dentro = LlamadaSegura(IsUnitInDungeon, "player")
    if ok then return dentro == true end
    return false
end

local function JugadorEnGrupo()
    local ok, enGrupo = LlamadaSegura(IsUnitGrouped, "player")
    if ok then return enGrupo == true end
    return false
end

local function PuedeSaltarACasa(houseId)
    if type(CanJumpToHouseFromCurrentLocation) == "function" then
        local ok, puede = LlamadaSegura(CanJumpToHouseFromCurrentLocation, houseId)
        if ok then return puede == true end
    end
    -- Si no hay función de comprobación, dejamos que el juego lo rechace si procede
    return true
end

-- Añade una entrada a la lista si el texto y el callback son válidos
local function AgregarEntrada(lista, texto, callback, clave)
    local tipoTexto = type(texto)
    if tipoTexto ~= "string" and tipoTexto ~= "number" and tipoTexto ~= "function" then return end
    if type(callback) ~= "function" then return end
    lista[#lista + 1] = { text = texto, callback = callback, key = clave }
end

-- Lanza una acción a través del InputRouter.
local function Trigger(accion, ctx)
    return (EZOTools_InputRouter and EZOTools_InputRouter.Trigger
        and EZOTools_InputRouter.Trigger("MENU", accion, ctx or {})) or false
end

-- Devuelve la lista de entradas del menú con visibilidad ya evaluada
function A.BuildEntries()
    local entradas = {}
    local enCombate = JugadorEnCombate()
    local enGrupo = JugadorEnGrupo()

    -- Dificultad de instancia: primera entrada, solo para lider de grupo.
    if not enCombate
        and EZO
        and type(EZO.CanShowDungeonDifficultyOption) == "function"
        and EZO.CanShowDungeonDifficultyOption()
        and type(EZO.GetDungeonDifficultyMenuText) == "function"
        and type(EZO.ToggleDungeonDifficulty) == "function" then
        AgregarEntrada(entradas,
            EZO.GetDungeonDifficultyMenuText,
            function() return Trigger("TOGGLE_DUNGEON_DIFFICULTY") end)
    end

    -- Viaje: casa principal del jugador (oculto en combate — el juego rechaza el viaje)
    if not enCombate then
        if type(GetHousingPrimaryHouse) == "function" and type(RequestJumpToHouse) == "function" then
            local ok, houseId = LlamadaSegura(GetHousingPrimaryHouse)
            if ok and type(houseId) == "number" and houseId ~= 0 then
                if PuedeSaltarACasa(houseId) then
                    AgregarEntrada(entradas,
                        GetString(EZO_MENU_TRAVEL_PRIMARY),
                        function() return Trigger("JUMP_PRIMARY_HOUSE") end)
                end
            end
        end
    end

    -- Viaje: casas configuradas (solo fuera de combate)
    if not enCombate then
        if EZO and type(EZO.JumpCraftingHall) == "function"
            and EZO.sv and EZO.sv.friends
            and EZO.sv.friends.craftingHall ~= "" then
            AgregarEntrada(entradas,
                GetString(EZO_MENU_TRAVEL_CRAFTING),
                function() return Trigger("JUMP_CRAFTING_HOUSE") end)
        end
        if EZO and type(EZO.JumpSecondaryHall) == "function"
            and EZO.sv and EZO.sv.friends
            and EZO.sv.friends.secondaryHall ~= "" then
            AgregarEntrada(entradas,
                GetString(EZO_MENU_TRAVEL_SECONDARY),
                function() return Trigger("JUMP_SECONDARY_HOUSE") end)
        end
    end

    -- Salto al líder (requiere estar en grupo Y que el salto sea posible)
    if not enCombate
        and JugadorEnGrupo()
        and EZO and type(EZO.CanJumpToLeader) == "function"
        and type(EZO.JumpToLeader) == "function" then
        local ok, puede = LlamadaSegura(EZO.CanJumpToLeader)
        if ok and puede == true then
            local leaderText = GetString(EZO_MENU_JUMP_LEADER)
            if type(EZO.GetLeaderJumpMenuText) == "function" then
                local okText, text = LlamadaSegura(EZO.GetLeaderJumpMenuText)
                if okText and type(text) == "string" and text ~= "" then
                    leaderText = text
                end
            end
            AgregarEntrada(entradas,
                leaderText,
                function() return Trigger("JUMP_TO_LEADER") end)
        end
    end

    -- Acciones de grupo e instancia
    local enInstancia = JugadorEnInstancia()

    if enGrupo and type(EZO.LeaveGroup) == "function" then
        AgregarEntrada(entradas,
            GetString(EZO_MENU_LEAVE_GROUP),
            function() return Trigger("LEAVE_GROUP") end)
    end
    if enInstancia and type(EZO.LeaveInstance) == "function" then
        AgregarEntrada(entradas,
            GetString(EZO_MENU_LEAVE_INSTANCE),
            function() return Trigger("LEAVE_INSTANCE") end)
    end
    if enGrupo and enInstancia and type(EZO.LeaveGroupAndInstance) == "function" then
        AgregarEntrada(entradas,
            GetString(EZO_MENU_LEAVE_GROUP_INSTANCE),
            function() return Trigger("LEAVE_GROUP_AND_INSTANCE") end)
    end

    -- Mantenimiento: reparar equipo (solo si hay piezas por debajo del umbral)
    -- El umbral se lee una sola vez y se pasa al texto del menú
    if not enCombate then
        local umbralRep = (EZO.sv and EZO.sv.general and tonumber(EZO.sv.general.repairThreshold)) or 40
        if type(EZO.CanRepairEquipped) == "function"
            and EZO.CanRepairEquipped()
            and type(EZO.RepairEquipped) == "function" then
            AgregarEntrada(entradas,
                zo_strformat(GetString(EZO_MENU_REPAIR), umbralRep),
                function() EZO.RepairEquipped() end)
        end
    end

    -- Mantenimiento: recargar armas (solo si hay armas por debajo del umbral)
    if not enCombate then
        local umbralRec = (EZO.sv and EZO.sv.general and tonumber(EZO.sv.general.rechargeThreshold)) or 50
        if type(EZO.CanRechargeWeapons) == "function"
            and EZO.CanRechargeWeapons()
            and type(EZO.RechargeWeapons) == "function" then
            AgregarEntrada(entradas,
                zo_strformat(GetString(EZO_MENU_RECHARGE), umbralRec),
                function() EZO.RechargeWeapons() end)
        end
    end

    -- Recargar interfaz (siempre visible)
    AgregarEntrada(entradas,
        GetString(EZO_MENU_RELOAD),
        function() ReloadUI() end)

    -- Ajustes al final, justo encima de cerrar, para no separar las acciones principales.
    AgregarEntrada(entradas,
        GetString(EZO_MENU_SETTINGS),
        function() return Trigger("OPEN_SETTINGS") end,
        "settings")

    if not enCombate then
        AgregarEntrada(entradas,
            GetString(EZO_MENU_ADDON_SETTINGS),
            function() return Trigger("OPEN_ADDON_SETTINGS") end)
    end

    -- Cerrar menú (siempre al final)
    AgregarEntrada(entradas,
        GetString(EZO_MENU_EXIT),
        function()
            if HideMenu then HideMenu() end
            if ZO_Dialogs_ReleaseDialog and EZOTools
                and EZOTools.GamepadDialog and EZOTools.GamepadDialog.DIALOG_NAME then
                ZO_Dialogs_ReleaseDialog(EZOTools.GamepadDialog.DIALOG_NAME)
            elseif ZO_Dialogs_HideDialog and EZOTools
                and EZOTools.GamepadDialog and EZOTools.GamepadDialog.DIALOG_NAME then
                ZO_Dialogs_HideDialog(EZOTools.GamepadDialog.DIALOG_NAME)
            end
        end)

    return entradas
end
