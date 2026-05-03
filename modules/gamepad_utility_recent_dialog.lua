-- Módulo de subdiálogo de recientes para utilidades rápidas.
-- Muestra las últimas entradas de la categoría seleccionada y ejecuta la acción
-- asociada al elegir una fila.

local EZO = _G.EZOTools or {}
_G.EZOTools = EZO

EZO.GamepadUtilityRecentDialog = EZO.GamepadUtilityRecentDialog or {}
local Dialog = EZO.GamepadUtilityRecentDialog

local NOMBRE_DIALOGO = "EZO_GAMEPAD_UTILITY_RECENT_DIALOG"
Dialog.DIALOG_NAME = NOMBRE_DIALOGO
Dialog._currentKey = nil
Dialog._currentTitle = nil
local QuickUtility = _G.EZOTools_QuickUtility

local function CerrarDialogoActual()
    EZOTools_CerrarDialogoGamepad(NOMBRE_DIALOGO)
end

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
        return QuickUtility.BuildRecentEntries(Dialog._currentKey, true)
    end
    return {}
end

local ExtraerCallback = EZOTools_ExtraerCallback
local AdjuntarActivacionRaton = EZOTools_AdjuntarActivacionRatonGamepad
local BuscarDialogoGamepad = EZOTools_BuscarDialogoGamepad
local ActivarSeleccionDialogoGamepad = EZOTools_ActivarSeleccionDialogoGamepad

local function NormalizarTextoEntradaLista(texto)
    texto = tostring(texto or "")
    if QuickUtility and type(QuickUtility.NormalizeTooltipText) == "function" then
        texto = QuickUtility.NormalizeTooltipText(texto)
    end
    texto = texto:gsub("|H.-|h(.-)|h", "%1")
    texto = texto:gsub("|c%x%x%x%x%x%x", "")
    texto = texto:gsub("|r", "")
    texto = texto:gsub("%^%a+", "")
    texto = texto:gsub("\n", " ")
    texto = texto:gsub("%s+", " ")
    return zo_strtrim(texto)
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

local function AsegurarRegistrado()
    if Dialog._registered then return end

    ZO_Dialogs_RegisterCustomDialog(NOMBRE_DIALOGO, {
        gamepadInfo = { dialogType = GAMEPAD_DIALOGS.PARAMETRIC },
        title = {
            text = function()
                return tostring(Dialog._currentTitle or GetString(EZO_UTILITY_MENU_TITLE))
            end,
        },
        mainText = { text = "" },
        parametricList = {},

        setup = function(dialog)
            Dialog._activeDialog = dialog
            Dialog._lastPreviewData = nil
            Dialog._lastPreviewControl = nil
            local list = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(list)

            local added = 0
            for _, action in ipairs(RecopilarEntradasRecientes()) do
                local rowText = NormalizarTextoEntradaLista(action.text)
                local ed = ZO_GamepadEntryData:New(rowText)
                ed.callback = action.callback
                ed.previewKind = action.previewKind
                ed.previewItemLink = action.previewItemLink
                ed.previewCollectibleId = action.previewCollectibleId
                ed.previewFallbackName = action.previewFallbackName
                ed.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    ZO_GamepadMenuEntryTemplate_Setup(control, data.text, nil, nil, nil, selected)
                    AdjuntarActivacionRaton(control, data)
                    if selected then
                        AplicarPreviewSeleccionado(control, data)
                    end
                end
                table.insert(list, {
                    template = "ZO_GamepadMenuEntryTemplate",
                    entryData = ed,
                })
                added = added + 1
            end

            ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog)

            if dialog.entryList and dialog.entryList.GetNumItems
                and dialog.entryList:GetNumItems() == 0 then
                local config = nil
                if QuickUtility and type(QuickUtility.GetHistoryEmptyLabel) == "function" then
                    local text = QuickUtility.GetHistoryEmptyLabel(Dialog._currentKey)
                    if type(text) == "string" and text ~= "" then
                        config = NormalizarTextoEntradaLista(text)
                    end
                end
                if type(config) == "string" and config ~= "" then
                    local ed = ZO_GamepadEntryData:New(config)
                    ed.callback = function() end
                    ed.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        ZO_GamepadMenuEntryTemplate_Setup(control, data.text, nil, nil, nil, selected)
                        AdjuntarActivacionRaton(control, data)
                    end
                    table.insert(list, {
                        template = "ZO_GamepadMenuEntryTemplate",
                        entryData = ed,
                    })
                    ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog)
                end
            end
        end,

        buttons = {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local data = dialog.entryList and dialog.entryList.GetTargetData
                        and dialog.entryList:GetTargetData() or nil
                    local cb = ExtraerCallback(data)
                    if cb then cb() end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_EXIT,
                callback = function()
                    DetenerActualizacionPreview()
                    CerrarDialogoActual()
                    ReabrirDialogoUtilidades()
                end,
            },
        },

        finishedCallback = function()
            DetenerActualizacionPreview()
            Dialog._activeDialog = nil
        end,
    })

    Dialog._registered = true
end

local function BuscarDialogo()
    return BuscarDialogoGamepad(NOMBRE_DIALOGO)
end

function Dialog.IsShowing()
    local dlg = Dialog._activeDialog or BuscarDialogo()
    if dlg and dlg.control and type(dlg.control.IsHidden) == "function" then
        return not dlg.control:IsHidden()
    end
    if type(ZO_Dialogs_IsShowing) == "function" then
        local ok, value = pcall(function() return ZO_Dialogs_IsShowing(NOMBRE_DIALOGO) end)
        if ok then return value end
    end
    return false
end

function Dialog.Close()
    DetenerActualizacionPreview()
    CerrarDialogoActual()
end

function Dialog.ActivateSelected()
    return ActivarSeleccionDialogoGamepad(BuscarDialogo())
end

function Dialog.Open(clave, titulo)
    Dialog._currentKey = tostring(clave or "")
    Dialog._currentTitle = tostring(titulo or GetString(EZO_UTILITY_MENU_TITLE))
    AsegurarRegistrado()
    ZO_Dialogs_ShowGamepadDialog(NOMBRE_DIALOGO)
end
