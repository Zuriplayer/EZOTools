-- Módulo de diálogo gamepad principal de EZOTools.
-- Implementa el panel de comandos como diálogo paramétrico de gamepad (GAMEPAD_DIALOGS.PARAMETRIC).
-- Se abre al pulsar el keybind del panel de comandos o al hacer clic en el overlay con gamepad.

local EZO = _G.EZOTools or {}
_G.EZOTools = EZO

EZO.GamepadDialog = EZO.GamepadDialog or {}
local Dialog = EZO.GamepadDialog

local NOMBRE_DIALOGO = "EZO_GAMEPAD_CONTEXT_DIALOG"
Dialog.DIALOG_NAME = NOMBRE_DIALOGO

local function ConstruirSubtituloDialogo()
    local autor = tostring((EZO and EZO.AUTHOR) or "@Zuriplayer")
    local version = tostring((EZO and EZO.ADDON_VERSION) or "")
    return zo_strformat(GetString(EZO_MENU_DIALOG_SUBTITLE), autor, version)
end

-- Cierra el diálogo actual de forma segura (necesario antes de abrir otro diálogo gamepad)
local function CerrarDialogoActual()
    EZOTools_CerrarDialogoGamepad(NOMBRE_DIALOGO)
end

-- Construye la lista de acciones del menú desde el módulo actions
local function RecopilarAcciones()
    local acciones = {}
    if _G.EZOTools_Actions and type(_G.EZOTools_Actions.BuildEntries) == "function" then
        local ok, entradas = pcall(_G.EZOTools_Actions.BuildEntries)
        if ok and type(entradas) == "table" then
            for _, e in ipairs(entradas) do
                if type(e) == "table"
                    and (type(e.text) == "string" or type(e.text) == "function")
                    and type(e.callback) == "function"
                then
                    table.insert(acciones, { name = e.text, callback = e.callback })
                end
            end
        end
    end

    if EZO
        and type(EZO.CanOpenDebugLogViewer) == "function"
        and EZO.CanOpenDebugLogViewer() then
        local debugEntry = {
            name = GetString(EZO_MENU_DEBUG_VIEWER),
            callback = function()
                CerrarDialogoActual()
                local function abrirVisor()
                    if EZO and type(EZO.OpenDebugLogViewer) == "function" then
                        EZO.OpenDebugLogViewer()
                    end
                end
                if zo_callLater then
                    zo_callLater(function() pcall(abrirVisor) end, 200)
                else
                    pcall(abrirVisor)
                end
            end,
        }

        if #acciones > 0 then
            table.insert(acciones, #acciones, debugEntry)
        else
            table.insert(acciones, debugEntry)
        end
    end

    return acciones
end

-- Resuelve el nombre de una acción (puede ser función o string)
local function ResolverNombre(n)
    if type(n) == "function" then
        local ok, val = pcall(n)
        if ok then return tostring(val) end
        return "Item"
    end
    return tostring(n or "Item")
end

-- Extrae el callback de un dato de entrada (soporta varios formatos de ZO_GamepadEntryData)
-- ExtraerCallback disponible como EZOTools_ExtraerCallback (shared_utils.lua)
local ExtraerCallback = EZOTools_ExtraerCallback
local AdjuntarActivacionRaton = EZOTools_AdjuntarActivacionRatonGamepad
local BuscarDialogoGamepad = EZOTools_BuscarDialogoGamepad
local ActivarSeleccionDialogoGamepad = EZOTools_ActivarSeleccionDialogoGamepad

-- Registra el diálogo en el sistema ZO_Dialogs si aún no está registrado
local function AsegurarRegistrado()
    if Dialog._registered then return end

    ZO_Dialogs_RegisterCustomDialog(NOMBRE_DIALOGO, {
        gamepadInfo    = { dialogType = GAMEPAD_DIALOGS.PARAMETRIC },
        title          = { text = "E|cB040FFZ|rOTools" },
        mainText       = { text = ConstruirSubtituloDialogo() },
        parametricList = {},

        setup = function(dialog)
            local list = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(list)

            -- IMPORTANTE: los diálogos paramétricos de gamepad requieren que cada entryData
            -- tenga un campo 'setup' válido. Sin él, ESO lanza "function expected instead of nil"
            -- en ZO_GenericDialog_Gamepad.lua:745.
            local acciones = RecopilarAcciones()
            for _, a in ipairs(acciones) do
                local ed = ZO_GamepadEntryData:New(ResolverNombre(a.name))

                -- Si es la entrada de Ajustes abierta desde dentro del diálogo gamepad,
                -- cerrar el diálogo actual antes de abrir el de ajustes para evitar conflictos
                local cb = a.callback
                if type(a.name) == "string" and a.name == GetString(EZO_MENU_SETTINGS)
                    and type(cb) == "function" then
                    local cbOriginal = cb
                    cb = function()
                        CerrarDialogoActual()
                        zo_callLater(function() pcall(cbOriginal) end, 200)
                    end
                end

                ed.callback = cb
                ed.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    -- ZO_GamepadMenuEntryTemplate_Setup espera el texto como string, no la tabla entryData
                    ZO_GamepadMenuEntryTemplate_Setup(control, data.text, nil, nil, nil, selected)
                    AdjuntarActivacionRaton(control, data)
                end

                table.insert(list, {
                    template  = "ZO_GamepadMenuEntryTemplate",
                    entryData = ed,
                })
            end

            ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog)

            -- Red de seguridad: si la lista queda vacía, mostrar entrada dummy con setup válido
            if dialog.entryList and dialog.entryList.GetNumItems
                and dialog.entryList:GetNumItems() == 0 then
                local ed = ZO_GamepadEntryData:New(GetString(EZO_MENU_TITLE))
                ed.callback = function() end
                ed.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    ZO_GamepadMenuEntryTemplate_Setup(control, data.text, nil, nil, nil, selected)
                    AdjuntarActivacionRaton(control, data)
                end
                table.insert(list, { template = "ZO_GamepadMenuEntryTemplate", entryData = ed })
                ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog)
            end
        end,

        buttons = {
            {   -- Seleccionar (A / ✕)
                keybind  = "DIALOG_PRIMARY",
                text     = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local data = dialog.entryList and dialog.entryList.GetTargetData
                        and dialog.entryList:GetTargetData() or nil
                    local cb = ExtraerCallback(data)
                    if cb then cb() end
                end,
            },
            {   -- Volver / cerrar (B / ◯)
                keybind  = "DIALOG_NEGATIVE",
                text     = SI_DIALOG_EXIT,
                callback = function(dialog) end,
            },
        },
    })

    Dialog._registered = true
end

-- Busca el objeto de diálogo activo en el sistema ZO_Dialogs
local function BuscarDialogo()
    return BuscarDialogoGamepad(NOMBRE_DIALOGO)
end

-- API pública: devuelve true si el diálogo está visible ahora mismo
function Dialog.IsShowing()
    local dlg = BuscarDialogo()
    if dlg and dlg.control and type(dlg.control.IsHidden) == "function" then
        return not dlg.control:IsHidden()
    end
    if type(ZO_Dialogs_IsShowing) == "function" then
        local ok, v = pcall(function() return ZO_Dialogs_IsShowing(NOMBRE_DIALOGO) end)
        if ok then return v end
    end
    return false
end

-- API pública: cierra el diálogo
function Dialog.Close()
    CerrarDialogoActual()
end

-- API pública: activa la entrada actualmente seleccionada en la lista
function Dialog.ActivateSelected()
    return ActivarSeleccionDialogoGamepad(BuscarDialogo())
end

-- API pública: abre el diálogo
function Dialog.Open()
    AsegurarRegistrado()
    ZO_Dialogs_ShowGamepadDialog(NOMBRE_DIALOGO)
end
