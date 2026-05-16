-- Nucleo comun para menus laterales parametricos de gamepad/teclado.
-- El dialogo usa APIs gamepad de ESO, pero tambien lo disparan keybinds de teclado.
-- Encapsula el patron de seleccion que ya funciona: target data -> callback extraido -> ejecucion.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.SideMenuCore = EZO.SideMenuCore or {}
local Core = EZO.SideMenuCore

local ExtraerCallback = EZOTools_ExtraerCallback
local AdjuntarActivacionRaton = EZOTools_AdjuntarActivacionRatonGamepad
local BuscarDialogoGamepad = EZOTools_BuscarDialogoGamepad
local ActivarSeleccionDialogoGamepad = EZOTools_ActivarSeleccionDialogoGamepad

local function CerrarDialogo(nombreDialogo)
    EZOTools_CerrarDialogoGamepad(nombreDialogo)
end

local function ResolverTexto(valor)
    if type(valor) == "function" then
        local ok, texto = pcall(valor)
        if ok then
            return tostring(texto)
        end
        return "Item"
    end
    return tostring(valor or "Item")
end

local function CopiarDatosEntrada(origen, destino)
    if type(origen) ~= "table" or type(destino) ~= "table" then
        return
    end
    for k, v in pairs(origen) do
        if k ~= "text" and k ~= "name" and k ~= "callback" then
            destino[k] = v
        end
    end
end

local function CrearSetupEntrada(config)
    return function(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_GamepadMenuEntryTemplate_Setup(control, data.text, nil, nil, nil, selected)
        AdjuntarActivacionRaton(control, data)
        if type(config.onEntrySetup) == "function" then
            config.onEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        end
    end
end

function Core.CreateDialog(config)
    config = config or {}
    local dialog = config.namespace or {}
    local nombreDialogo = tostring(config.dialogName or "")
    dialog.DIALOG_NAME = nombreDialogo

    local function CerrarActual()
        CerrarDialogo(nombreDialogo)
    end

    local function BuscarDialogo()
        return BuscarDialogoGamepad(nombreDialogo)
    end

    local function ConstruirBotones()
        local buttons = {}

        buttons[#buttons + 1] = {
            keybind = "DIALOG_PRIMARY",
            text = SI_GAMEPAD_SELECT_OPTION,
            callback = function(zoDialog)
                local data = zoDialog.entryList and zoDialog.entryList.GetTargetData
                    and zoDialog.entryList:GetTargetData() or nil
                local cb = ExtraerCallback(data)
                if cb then cb() end
            end,
        }
        buttons[#buttons + 1] = {
            keybind = "DIALOG_NEGATIVE",
            text = SI_DIALOG_EXIT,
            callback = function(zoDialog)
                if type(config.onNegative) == "function" then
                    config.onNegative(zoDialog, dialog, CerrarActual)
                end
            end,
        }
        return buttons
    end

    local function ConstruirEntradas()
        if type(config.buildEntries) ~= "function" then
            return {}
        end
        local ok, entries = pcall(config.buildEntries, dialog)
        if ok and type(entries) == "table" then
            return entries
        end
        return {}
    end

    local function AsegurarRegistrado()
        if dialog._registered then return end

        ZO_Dialogs_RegisterCustomDialog(nombreDialogo, {
            gamepadInfo = { dialogType = GAMEPAD_DIALOGS.PARAMETRIC },
            title = { text = ResolverTexto(config.titleText or "") },
            mainText = { text = ResolverTexto(config.mainText or "") },
            blockDialogReleaseOnPress = config.blockDialogReleaseOnPress == true,
            parametricList = {},

            setup = function(zoDialog)
                if config.trackActiveDialog then
                    dialog._activeDialog = zoDialog
                end
                if type(config.onBeforeSetup) == "function" then
                    config.onBeforeSetup(zoDialog, dialog)
                end

                local list = zoDialog.info.parametricList
                ZO_ClearNumericallyIndexedTable(list)

                local setupEntry = CrearSetupEntrada(config)
                for _, entry in ipairs(ConstruirEntradas()) do
                    if type(entry) == "table" then
                        local texto = ResolverTexto(entry.text or entry.name)
                        local ed = ZO_GamepadEntryData:New(texto)
                        CopiarDatosEntrada(entry, ed)
                        local cb = entry.callback
                        if type(config.prepareCallback) == "function" then
                            local preparado = config.prepareCallback(entry, cb, dialog, CerrarActual)
                            if preparado ~= nil then
                                cb = preparado
                            end
                        end
                        ed.callback = cb
                        ed.setup = setupEntry
                        if type(config.onEntryCreated) == "function" then
                            config.onEntryCreated(entry, ed, dialog)
                        end
                        table.insert(list, {
                            template = "ZO_GamepadMenuEntryTemplate",
                            entryData = ed,
                        })
                    end
                end

                ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(zoDialog)

                if zoDialog.entryList and zoDialog.entryList.GetNumItems
                    and zoDialog.entryList:GetNumItems() == 0 then
                    local ed = ZO_GamepadEntryData:New(ResolverTexto(config.emptyText or config.titleText or "Item"))
                    ed.callback = function() end
                    ed.setup = setupEntry
                    table.insert(list, {
                        template = "ZO_GamepadMenuEntryTemplate",
                        entryData = ed,
                    })
                    ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(zoDialog)
                end
            end,

            OnShownCallback = function(zoDialog)
                Core.AttachListTriggerNavigation(dialog, function()
                    return zoDialog and zoDialog.entryList or nil
                end)
                if type(config.onShown) == "function" then
                    config.onShown(zoDialog, dialog)
                end
            end,

            onHidingCallback = function(zoDialog)
                Core.DetachListTriggerNavigation(dialog)
                if type(config.onHiding) == "function" then
                    config.onHiding(zoDialog, dialog)
                end
            end,

            buttons = ConstruirBotones(),

            finishedCallback = function(zoDialog)
                Core.DetachListTriggerNavigation(dialog)
                if config.trackActiveDialog then
                    dialog._activeDialog = nil
                end
                if type(config.onFinished) == "function" then
                    config.onFinished(zoDialog, dialog)
                end
            end,
        })

        dialog._registered = true
    end

    function dialog.IsShowing()
        local dlg = config.trackActiveDialog and dialog._activeDialog or nil
        dlg = dlg or BuscarDialogo()
        if dlg and dlg.control and type(dlg.control.IsHidden) == "function" then
            return not dlg.control:IsHidden()
        end
        if type(ZO_Dialogs_IsShowing) == "function" then
            local ok, value = pcall(function() return ZO_Dialogs_IsShowing(nombreDialogo) end)
            if ok then return value end
        end
        return false
    end

    function dialog.Close()
        CerrarActual()
    end

    function dialog.ActivateSelected()
        return ActivarSeleccionDialogoGamepad(BuscarDialogo())
    end

    function dialog.Open(...)
        if type(config.beforeOpen) == "function" then
            config.beforeOpen(dialog, ...)
        end
        AsegurarRegistrado()
        ZO_Dialogs_ShowGamepadDialog(nombreDialogo)
    end

    return dialog
end
