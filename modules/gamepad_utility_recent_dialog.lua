-- Módulo de subdiálogo de recientes para utilidades rápidas.
-- Muestra las últimas entradas de la categoría seleccionada y ejecuta la acción
-- asociada al elegir una fila.

local EZO = _G.EZOTools or {}
_G.EZOTools = EZO

local Core = EZO.SideMenuCore
EZO.GamepadUtilityRecentDialog = EZO.GamepadUtilityRecentDialog or {}
local Dialog = EZO.GamepadUtilityRecentDialog

local NOMBRE_DIALOGO = "EZO_GAMEPAD_UTILITY_RECENT_DIALOG"
Dialog.DIALOG_NAME = NOMBRE_DIALOGO
Dialog._currentKey = nil
Dialog._currentTitle = nil
local QuickUtility = _G.EZOTools_QuickUtility

local function OcultarPreviewActual()
    if QuickUtility and type(QuickUtility.HidePreview) == "function" then
        QuickUtility.HidePreview()
    end
end

local function ReabrirDialogoUtilidades()
    local dlg = EZO and EZO.GamepadUtilityDialog
    if dlg and type(dlg.Open) == "function" then
        if zo_callLater then
            zo_callLater(function() pcall(function() dlg.Open() end) end, 150)
        else
            pcall(function() dlg.Open() end)
        end
    end
end

local function RecopilarEntradasRecientes()
    if QuickUtility and type(QuickUtility.BuildRecentEntries) == "function" then
        local options = nil
        if tostring(Dialog._currentKey or "") == "food" then
            options = { skipLegendaryConfirm = true }
        end
        return QuickUtility.BuildRecentEntries(Dialog._currentKey, true, options)
    end
    return {}
end

-- Versión única en shared_utils.lua
local function NormalizarTextoEntradaLista(texto)
    return EZOTools_NormalizarTextoEtiqueta(tostring(texto or ""))
end

local function AplicarPreviewSeleccionado(control, data)
    if not control or type(data) ~= "table" then
        return
    end
    if data == Dialog._lastPreviewData and control == Dialog._lastPreviewControl then
        return
    end
    Dialog._lastPreviewData = data
    Dialog._lastPreviewControl = control
    OcultarPreviewActual()

    if QuickUtility and type(QuickUtility.ShowPreview) == "function" then
        QuickUtility.ShowPreview(control, data)
    end
end

local function DetenerActualizacionPreview()
    Dialog._lastPreviewData = nil
    Dialog._lastPreviewControl = nil
    OcultarPreviewActual()
end

local function ObtenerTextoVacio()
    if QuickUtility and type(QuickUtility.GetHistoryEmptyLabel) == "function" then
        local text = QuickUtility.GetHistoryEmptyLabel(Dialog._currentKey)
        if type(text) == "string" and text ~= "" then
            return NormalizarTextoEntradaLista(text)
        end
    end
    return ""
end

local function ConstruirEntradas()
    local entradas = {}
    for _, action in ipairs(RecopilarEntradasRecientes()) do
        if type(action) == "table" then
            action.text = NormalizarTextoEntradaLista(action.text)
            entradas[#entradas + 1] = action
        end
    end
    return entradas
end

if Core and type(Core.CreateDialog) == "function" then
    Core.CreateDialog({
        namespace = Dialog,
        dialogName = NOMBRE_DIALOGO,
        titleText = function()
            return tostring(Dialog._currentTitle or GetString(EZO_UTILITY_MENU_TITLE))
        end,
        mainText = "",
        emptyText = ObtenerTextoVacio,
        buildEntries = ConstruirEntradas,
        allowBlankEmptyEntry = false,
        trackActiveDialog = true,
        dynamicText = true,
        beforeOpen = function(_, clave, titulo)
            Dialog._currentKey = tostring(clave or "")
            Dialog._currentTitle = tostring(titulo or GetString(EZO_UTILITY_MENU_TITLE))
        end,
        onBeforeSetup = function()
            Dialog._lastPreviewData = nil
            Dialog._lastPreviewControl = nil
        end,
        onEntrySetup = function(control, data, selected)
            if selected then
                AplicarPreviewSeleccionado(control, data)
            end
        end,
        onNegative = function(_, _, closeCurrent)
            DetenerActualizacionPreview()
            closeCurrent()
            ReabrirDialogoUtilidades()
        end,
        onFinished = function()
            DetenerActualizacionPreview()
        end,
    })
end

local AbrirDialogoRecientes = Dialog.Open
local CerrarDialogoRecientes = Dialog.Close

function Dialog.Open(clave, titulo)
    if type(AbrirDialogoRecientes) == "function" then
        AbrirDialogoRecientes(clave, titulo)
    end
end

function Dialog.Close()
    DetenerActualizacionPreview()
    if type(CerrarDialogoRecientes) == "function" then
        CerrarDialogoRecientes()
    end
end
