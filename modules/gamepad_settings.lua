-- Módulo de diálogo de ajustes rápidos de EZOTools (compatible gamepad y teclado).
-- Ofrece los umbrales de reparación y recarga sin necesitar LibAddonMenu.
-- Los valores se modifican pulsando SELECT, que los cicla en incrementos de 5%.

local EZO = _G.EZOTools or {}
_G.EZOTools = EZO

EZO.GamepadSettingsDialog = EZO.GamepadSettingsDialog or {}
local Dialog = EZO.GamepadSettingsDialog

local NOMBRE_DIALOGO = "EZO_GAMEPAD_SETTINGS_DIALOG"
Dialog.DIALOG_NAME   = NOMBRE_DIALOGO

local function ConstruirSubtituloDialogo()
    local autor = tostring((EZO and EZO.AUTHOR) or "@Zuriplayer")
    local version = tostring((EZO and EZO.ADDON_VERSION) or "")
    return zo_strformat(GetString(EZO_MENU_DIALOG_SUBTITLE), autor, version)
end

-- Garantiza que los valores por defecto de mantenimiento existen
-- AsegurarDefectos disponible como EZOTools_AsegurarDefectos (shared_utils.lua)
local AsegurarDefectos = EZOTools_AsegurarDefectos

-- Redondea y limita un valor a un rango entero
local function ClampInt(v, minV, maxV)
    v = tonumber(v)
    if not v then return minV end
    v = zo_floor(v + 0.5)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

-- Avanza el umbral en 'paso' unidades; vuelve al mínimo al superar el máximo
local function CiclarUmbral(actual, paso, minV, maxV)
    actual = ClampInt(actual, minV, maxV)
    local siguiente = actual + paso
    if siguiente > maxV then siguiente = minV end
    return siguiente
end

-- Comprueba si el diálogo de ajustes está visible mediante el control interno
local function EsDialogoVisible()
    local dlg = nil
    if type(ZO_Dialogs_FindDialog) == "function" then
        dlg = ZO_Dialogs_FindDialog(NOMBRE_DIALOGO)
    end
    local control = (dlg and dlg.control)
        or (dlg and dlg.dialog and dlg.dialog.control)
        or (dlg and dlg.dialog)
    if control and type(control.IsHidden) == "function" then
        return not control:IsHidden()
    end
    return false
end

-- Extrae el callback de un dato de entrada (mismo patrón que gamepad_dialog.lua)
-- ExtraerCallback disponible como EZOTools_ExtraerCallback (shared_utils.lua)
local ExtraerCallback = EZOTools_ExtraerCallback
local CerrarDialogoGamepad = EZOTools_CerrarDialogoGamepad
local ActivarSeleccionDialogoGamepad = EZOTools_ActivarSeleccionDialogoGamepad

-- API pública: devuelve true si el diálogo está visible
function Dialog.IsShowing()
    local dlg = Dialog._activeDialog
    if dlg then
        local control = dlg.control or (dlg.dialog and dlg.dialog.control) or dlg.dialog
        if control and type(control.IsHidden) == "function" then
            return not control:IsHidden()
        end
        return true
    end
    return EsDialogoVisible()
end

-- API pública: activa la entrada actualmente seleccionada
function Dialog.ActivateSelected()
    return ActivarSeleccionDialogoGamepad(Dialog._activeDialog)
end

-- Añade una entrada a la lista de ajustes
local function AgregarEntrada(lista, texto, callback, clave)
    if type(lista) ~= "table" or type(texto) ~= "string" or type(callback) ~= "function" then return end
    lista[#lista + 1] = { text = texto, callback = callback, settingKey = clave }
end

-- Construye las entradas del diálogo de ajustes con los valores actuales
local function ConstruirEntradasAjustes()
    AsegurarDefectos()
    local entradas = {}

    AgregarEntrada(entradas,
        zo_strformat(GetString(EZO_SETTINGS_RECHARGE_THRESHOLD), EZO.sv.general.rechargeThreshold),
        function()
            AsegurarDefectos()
            EZO.sv.general.rechargeThreshold = CiclarUmbral(EZO.sv.general.rechargeThreshold, 5, 5, 100)
            Dialog.RefreshInPlace()
        end,
        "rechargeThreshold")

    AgregarEntrada(entradas,
        zo_strformat(GetString(EZO_SETTINGS_REPAIR_THRESHOLD), EZO.sv.general.repairThreshold),
        function()
            AsegurarDefectos()
            EZO.sv.general.repairThreshold = CiclarUmbral(EZO.sv.general.repairThreshold, 5, 5, 100)
            Dialog.RefreshInPlace()
        end,
        "repairThreshold")

    -- Volver al panel principal de comandos
    AgregarEntrada(entradas,
        GetString(EZO_SETTINGS_BACK),
        function()
            Dialog.Close()
            local main = (EZO and EZO.GamepadDialog)
                or (_G.EZOTools_GamepadDialog)
            if main and type(main.Open) == "function" then
                if zo_callLater then
                    zo_callLater(function() pcall(function() main.Open() end) end, 200)
                else
                    pcall(function() main.Open() end)
                end
            end
        end)

    AgregarEntrada(entradas,
        GetString(EZO_SETTINGS_CLOSE),
        function() Dialog.Close() end)

    return entradas
end

local function ConstruirBotones()
    local buttons = {}

    buttons[#buttons + 1] = {
        keybind  = "DIALOG_PRIMARY",
        text     = SI_GAMEPAD_SELECT_OPTION,
        callback = function(dialog)
            local cb = nil
            if dialog and dialog.entryList
                and type(dialog.entryList.GetTargetData) == "function" then
                cb = ExtraerCallback(dialog.entryList:GetTargetData())
            end
            if cb then cb() end
            return false
        end,
    }
    buttons[#buttons + 1] = {
        keybind  = "DIALOG_NEGATIVE",
        text     = SI_DIALOG_EXIT,
        callback = function() Dialog.Close() end,
    }
    return buttons
end

-- Registra el diálogo en ZO_Dialogs si aún no está registrado
local function AsegurarRegistrado()
    if Dialog._registered then return end

    ZO_Dialogs_RegisterCustomDialog(NOMBRE_DIALOGO, {
        gamepadInfo    = { dialogType = GAMEPAD_DIALOGS.PARAMETRIC },
        title          = { text = "E|cB040FFZ|rOTools" },
        mainText       = { text = ConstruirSubtituloDialogo() },
        blockDialogReleaseOnPress = true,
        parametricList = {},

        setup = function(dialog)
            Dialog._activeDialog = dialog
            local list = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(list)

            local entradas = ConstruirEntradasAjustes()
            Dialog._entryDataByKey = {}

            for _, e in ipairs(entradas) do
                local ed = ZO_GamepadEntryData:New(e.text)
                ed.callback   = e.callback
                ed.settingKey = e.settingKey

                if e.settingKey then
                    Dialog._entryDataByKey[e.settingKey] = ed
                end

                -- Requerido por diálogos paramétricos gamepad
                ed.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                    ZO_GamepadMenuEntryTemplate_Setup(control, data.text, nil, nil, nil, selected)
                end

                table.insert(list, {
                    template  = "ZO_GamepadMenuEntryTemplate",
                    entryData = ed,
                })
            end

            ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog)
        end,

        OnShownCallback = function(dialog)
            local core = EZO and EZO.SideMenuCore
            if core and type(core.AttachListTriggerNavigation) == "function" then
                core.AttachListTriggerNavigation(Dialog, function()
                    return dialog and dialog.entryList or nil
                end)
            end
        end,

        onHidingCallback = function()
            local core = EZO and EZO.SideMenuCore
            if core and type(core.DetachListTriggerNavigation) == "function" then
                core.DetachListTriggerNavigation(Dialog)
            end
        end,

        buttons = ConstruirBotones(),

        finishedCallback = function(dialog)
            local core = EZO and EZO.SideMenuCore
            if core and type(core.DetachListTriggerNavigation) == "function" then
                core.DetachListTriggerNavigation(Dialog)
            end
            Dialog._activeDialog = nil
        end,
    })

    Dialog._registered = true
end

-- API pública: abre el diálogo en modo gamepad
function Dialog.OpenGamepad()
    AsegurarDefectos()
    AsegurarRegistrado()
    ZO_Dialogs_ShowGamepadDialog(NOMBRE_DIALOGO)
    return false
end

-- API pública: abre el diálogo (usa gamepad por defecto; el menú de ratón llama OpenMouse)
function Dialog.Open()
    return Dialog.OpenGamepad()
end

-- API pública: abre el submenú de ajustes en modo ratón (ZO_Menu)
function Dialog.OpenMouse(anchor)
    AsegurarDefectos()

    if type(AddMenuItem) ~= "function" or type(ShowMenu) ~= "function" then
        -- Si no se puede abrir el menú contextual, intenta abrir el panel completo de LAM.
        local LAM = _G.LibAddonMenu2
        if LAM and type(LAM.OpenToPanel) == "function" then
            local panel = _G.EZOTools_Panel
            if panel ~= nil then pcall(function() LAM:OpenToPanel(panel) end) end
        end
        return false
    end

    -- Reutilizar ancla del menú contextual si no se proporciona
    if not anchor and _G.EZOTools_ContextMenu and _G.EZOTools_ContextMenu._lastAnchor then
        anchor = _G.EZOTools_ContextMenu._lastAnchor
    end
    anchor = anchor or GuiRoot

    if ClearMenu then ClearMenu() end

    local menuAbierto = true
    local posicionFija = nil  -- { x, y } capturada al abrir por primera vez

    -- Aplica la posición fija para que el submenú no salte al cursor
    local function AplicarPosicionFija()
        local menuCtrl = _G.ZO_Menu
        if not menuCtrl then return end
        if posicionFija and posicionFija.x and posicionFija.y then
            menuCtrl:ClearAnchors()
            menuCtrl:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posicionFija.x, posicionFija.y)
        else
            posicionFija = { x = menuCtrl:GetLeft() or 0, y = menuCtrl:GetTop() or 0 }
        end
    end

    local function TrasMostrarMenu()
        if zo_callLater then
            zo_callLater(function()
                if menuAbierto then AplicarPosicionFija() end
            end, 1)
        else
            AplicarPosicionFija()
        end
    end

    local function Reconstruir()
        if ClearMenu then ClearMenu() end

        -- Umbral de recarga
        AddMenuItem(zo_strformat(GetString(EZO_SETTINGS_RECHARGE_THRESHOLD), EZO.sv.general.rechargeThreshold), function()
            AsegurarDefectos()
            EZO.sv.general.rechargeThreshold = CiclarUmbral(EZO.sv.general.rechargeThreshold, 5, 5, 100)
            if zo_callLater then
                zo_callLater(function() if menuAbierto then Reconstruir() end end, 10)
            else
                if menuAbierto then Reconstruir() end
            end
        end)

        -- Umbral de reparación
        AddMenuItem(zo_strformat(GetString(EZO_SETTINGS_REPAIR_THRESHOLD), EZO.sv.general.repairThreshold), function()
            AsegurarDefectos()
            EZO.sv.general.repairThreshold = CiclarUmbral(EZO.sv.general.repairThreshold, 5, 5, 100)
            if zo_callLater then
                zo_callLater(function() if menuAbierto then Reconstruir() end end, 10)
            else
                if menuAbierto then Reconstruir() end
            end
        end)

        if AddMenuSeparator then AddMenuSeparator() end

        -- Volver al menú principal
        if _G.EZOTools_ContextMenu and type(_G.EZOTools_ContextMenu.OpenMouse) == "function" then
            AddMenuItem(GetString(EZO_SETTINGS_BACK), function()
                menuAbierto = false
                local posVuelta = posicionFija
                if not posVuelta and _G.ZO_Menu then
                    posVuelta = { x = _G.ZO_Menu:GetLeft() or 0, y = _G.ZO_Menu:GetTop() or 0 }
                end
                local function reabrirPadre()
                    pcall(function() _G.EZOTools_ContextMenu.OpenMouse(anchor) end)
                    if posVuelta and _G.ZO_Menu then
                        _G.ZO_Menu:ClearAnchors()
                        _G.ZO_Menu:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posVuelta.x or 0, posVuelta.y or 0)
                    end
                end
                if zo_callLater then zo_callLater(reabrirPadre, 10) else reabrirPadre() end
            end)
        end

        AddMenuItem(GetString(EZO_SETTINGS_CLOSE), function()
            menuAbierto = false
            posicionFija = nil
            if HideMenu then HideMenu() end
            if EZOTools then EZOTools._contextMenuOpen = false end
        end)

        -- Mantener posición fija del menú
        if posicionFija and _G.ZO_Menu then
            _G.ZO_Menu:ClearAnchors()
            _G.ZO_Menu:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posicionFija.x, posicionFija.y)
        end
        if ShowMenu then ShowMenu(anchor) end
        TrasMostrarMenu()
        if EZOTools then EZOTools._contextMenuOpen = true end
    end

    Reconstruir()
    return true
end

-- API pública: cierra el diálogo
function Dialog.Close()
    Dialog._activeDialog = nil
    CerrarDialogoGamepad(NOMBRE_DIALOGO)
end

-- API pública: actualiza los textos de las entradas sin reconstruir la lista (preserva selección)
function Dialog.RefreshInPlace()
    AsegurarDefectos()
    local dialog = Dialog._activeDialog
    if not dialog or not dialog.entryList then return end

    local mapa = Dialog._entryDataByKey
    if type(mapa) == "table" then
        local edRecarga = mapa["rechargeThreshold"]
        if type(edRecarga) == "table" then
            edRecarga.text = zo_strformat(GetString(EZO_SETTINGS_RECHARGE_THRESHOLD), EZO.sv.general.rechargeThreshold)
        end
        local edReparacion = mapa["repairThreshold"]
        if type(edReparacion) == "table" then
            edReparacion.text = zo_strformat(GetString(EZO_SETTINGS_REPAIR_THRESHOLD), EZO.sv.general.repairThreshold)
        end
    end

    if type(dialog.entryList.RefreshVisible) == "function" then
        dialog.entryList:RefreshVisible()
    elseif type(ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList) == "function" then
        ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(dialog)
    end
end

-- Alias para compatibilidad con código anterior
function Dialog.Refresh()
    Dialog.RefreshInPlace()
end
