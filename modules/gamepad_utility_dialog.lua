-- Módulo de diálogo rápido de utilidades para gamepad.
-- Reutiliza la infraestructura de diálogos paramétricos del juego y ejecuta
-- las acciones rápidas equivalentes a los iconos inferiores del overlay.

local EZO = _G.EZOTools or {}
_G.EZOTools = EZO

EZO.GamepadUtilityDialog = EZO.GamepadUtilityDialog or {}
local Dialog = EZO.GamepadUtilityDialog

local NOMBRE_DIALOGO = "EZO_GAMEPAD_UTILITY_DIALOG"
Dialog.DIALOG_NAME = NOMBRE_DIALOGO

local function ConstruirSubtituloDialogo()
    local autor = tostring((EZO and EZO.AUTHOR) or "@Zuriplayer")
    local version = tostring((EZO and EZO.ADDON_VERSION) or "")
    return zo_strformat(GetString(EZO_MENU_DIALOG_SUBTITLE), autor, version)
end

local function CerrarDialogoActual()
    if ZO_Dialogs_ReleaseDialog then pcall(ZO_Dialogs_ReleaseDialog, NOMBRE_DIALOGO) end
    if ZO_Dialogs_HideDialog then pcall(ZO_Dialogs_HideDialog, NOMBRE_DIALOGO) end
end

local function RecopilarAcciones()
    if _G.EZOTools_Overlay and type(_G.EZOTools_Overlay.BuildQuickUtilityEntries) == "function" then
        local ok, entries = pcall(_G.EZOTools_Overlay.BuildQuickUtilityEntries)
        if ok and type(entries) == "table" then
            return entries
        end
    end
    return {}
end

local function ResolverNombre(n)
    if type(n) == "function" then
        local ok, val = pcall(n)
        if ok then return tostring(val) end
        return "Item"
    end
    return tostring(n or "Item")
end

local ExtraerCallback = EZOTools_ExtraerCallback

local function AdjuntarActivacionRaton(control, entryData)
    if not control or type(control.SetHandler) ~= "function" then return end
    if type(control.SetMouseEnabled) == "function" then
        control:SetMouseEnabled(true)
    end
    control:SetHandler("OnMouseUp", function(_, button, upInside)
        if button ~= MOUSE_BUTTON_INDEX_LEFT or not upInside then return end
        if type(entryData) == "table" and type(entryData.callback) == "function" then
            entryData.callback()
        end
    end)
end

local function AbrirDialogoRecientes(entry)
    local dlg = EZO and EZO.GamepadUtilityRecentDialog
    if not (dlg and type(dlg.Open) == "function") then
        return false
    end
    local clave = type(entry) == "table" and entry.key or ""
    local titulo = type(entry) == "table" and tostring(entry.text or "") or ""
    pcall(function() dlg.Open(clave, titulo) end)
    return true
end

local function AsegurarRegistrado()
    if Dialog._registered then return end

    ZO_Dialogs_RegisterCustomDialog(NOMBRE_DIALOGO, {
        gamepadInfo = { dialogType = GAMEPAD_DIALOGS.PARAMETRIC },
        title = { text = GetString(EZO_UTILITY_MENU_TITLE) },
        mainText = { text = ConstruirSubtituloDialogo() },
        parametricList = {},

        setup = function(dialog)
            Dialog._activeDialog = dialog
            local list = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(list)

            for _, action in ipairs(RecopilarAcciones()) do
                local ed = ZO_GamepadEntryData:New(ResolverNombre(action.text))
                local actionKey = tostring(action.key or "")
                local actionText = tostring(action.text or "")
                local cbOriginal = function()
                    return AbrirDialogoRecientes({ key = actionKey, text = actionText })
                end
                ed.callback = function()
                    CerrarDialogoActual()
                    if zo_callLater then
                        zo_callLater(function() pcall(cbOriginal) end, 200)
                    else
                        pcall(cbOriginal)
                    end
                    return false
                end
                ed.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    ZO_GamepadMenuEntryTemplate_Setup(control, data.text, nil, nil, nil, selected)
                    AdjuntarActivacionRaton(control, data)
                end
                table.insert(list, {
                    template = "ZO_GamepadMenuEntryTemplate",
                    entryData = ed,
                })
            end

            ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog)

            if dialog.entryList and dialog.entryList.GetNumItems
                and dialog.entryList:GetNumItems() == 0 then
                local ed = ZO_GamepadEntryData:New(GetString(EZO_UTILITY_MENU_TITLE))
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
                    CerrarDialogoActual()
                end,
            },
        },

        finishedCallback = function()
            Dialog._activeDialog = nil
        end,
    })

    Dialog._registered = true
end

local function BuscarDialogo()
    if type(ZO_Dialogs_FindDialog) == "function" then
        local dlg = ZO_Dialogs_FindDialog(NOMBRE_DIALOGO)
        if dlg then return dlg end
    end
    if type(ZO_Dialogs_GetDialog) == "function" then
        local dlg = ZO_Dialogs_GetDialog(NOMBRE_DIALOGO)
        if dlg then return dlg end
    end
    return nil
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
    CerrarDialogoActual()
end

function Dialog.ActivateSelected()
    local dlg = BuscarDialogo()
    if not dlg or not dlg.entryList or type(dlg.entryList.GetTargetData) ~= "function" then
        return false
    end
    local data = dlg.entryList:GetTargetData()
    local cb = ExtraerCallback(data)
    if cb then cb(); return true end
    return false
end

function Dialog.Open()
    AsegurarRegistrado()
    ZO_Dialogs_ShowGamepadDialog(NOMBRE_DIALOGO)
end
