-- Menu lateral principal de EZOTools (HOLD X / equivalente teclado).
-- Usa el nucleo comun de menus laterales y conserva la formula de seleccion estable.

local EZO = _G.EZOTools or {}
_G.EZOTools = EZO

local Core = EZO.SideMenuCore
EZO.GamepadDialog = EZO.GamepadDialog or {}
local Dialog = EZO.GamepadDialog

local NOMBRE_DIALOGO = "EZO_GAMEPAD_CONTEXT_DIALOG"

-- Versión única en shared_utils.lua
local ConstruirSubtituloDialogo = EZOTools_ConstruirSubtituloDialogo

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
                    acciones[#acciones + 1] = { name = e.text, callback = e.callback }
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
                EZOTools_CerrarDialogoGamepad(NOMBRE_DIALOGO)
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
            acciones[#acciones + 1] = debugEntry
        end
    end

    return acciones
end

local function PrepararCallback(entry, cb, dialog, closeCurrent)
    if type(entry.name) == "string" and entry.name == GetString(EZO_MENU_SETTINGS)
        and type(cb) == "function" then
        local cbOriginal = cb
        return function()
            closeCurrent()
            zo_callLater(function() pcall(cbOriginal) end, 200)
        end
    end
    return cb
end

if Core and type(Core.CreateDialog) == "function" then
    Core.CreateDialog({
        namespace = Dialog,
        dialogName = NOMBRE_DIALOGO,
        titleText = "E|cB040FFZ|rOTools",
        mainText = ConstruirSubtituloDialogo,
        emptyText = function() return GetString(EZO_MENU_TITLE) end,
        buildEntries = RecopilarAcciones,
        prepareCallback = PrepararCallback,
    })
end
