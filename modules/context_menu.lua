-- Módulo de menú contextual de EZOTools (modo ratón).
-- Construye y muestra el menú ZO_Menu anclado al overlay cuando el jugador
-- hace clic derecho sobre él.

EZOTools_ContextMenu = EZOTools_ContextMenu or {}
local EZO = EZOTools

local function ReportarErrorMenu(err)
    if not (EZO and type(EZO.IsDebugModeEnabled) == "function" and EZO.IsDebugModeEnabled()) then
        return
    end
    if EZO and type(EZO.DebugPrint) == "function" then
        EZO.DebugPrint(zo_strformat(GetString(EZO_MSG_MENU_CALLBACK_FAILED), tostring(err)))
    end
end

-- Construye la lista de entradas usando el módulo actions (fuente única de verdad)
local function ConstruirEntradas()
    if _G.EZOTools_Actions and type(_G.EZOTools_Actions.BuildEntries) == "function" then
        local ok, entradas = pcall(_G.EZOTools_Actions.BuildEntries)
        if ok and type(entradas) == "table" then
            return entradas
        end
    end
    return {}
end

EZOTools_ContextMenu.BuildEntries = ConstruirEntradas

-- Resuelve el control de anclaje: si el control está oculto, usa GuiRoot
local function ResolverAncla(anchor)
    if anchor and anchor.IsHidden and not anchor:IsHidden() then
        return anchor
    end
    return GuiRoot
end

-- Abre el menú contextual en modo ratón anclado al control dado
function EZOTools_ContextMenu.OpenMouse(anchor)
    anchor = ResolverAncla(anchor)
    -- Guardamos el ancla para que los submenús (como Ajustes) puedan reutilizarla
    EZOTools_ContextMenu._lastAnchor = anchor

    if ClearMenu then ClearMenu() end

    local entradas = ConstruirEntradas()
    for _, e in ipairs(entradas) do
        if AddMenuItem then
            AddMenuItem(e.text or "?", function()
                -- La entrada "settings" abre el submenú de ajustes en modo ratón,
                -- no el diálogo gamepad
                if (e.key == "settings")
                    and EZOTools and EZOTools.GamepadSettingsDialog
                    and type(EZOTools.GamepadSettingsDialog.OpenMouse) == "function" then
                    if zo_callLater then
                        zo_callLater(function()
                            EZOTools.GamepadSettingsDialog.OpenMouse(anchor)
                        end, 10)
                    else
                        EZOTools.GamepadSettingsDialog.OpenMouse(anchor)
                    end
                    return true
                end

                if (e.key == "groupActivities")
                    and EZOTools and EZOTools.RaidLeaderActivitiesDialog
                    and type(EZOTools.RaidLeaderActivitiesDialog.OpenMouse) == "function" then
                    if zo_callLater then
                        zo_callLater(function()
                            EZOTools.RaidLeaderActivitiesDialog.OpenMouse(anchor)
                        end, 10)
                    else
                        EZOTools.RaidLeaderActivitiesDialog.OpenMouse(anchor)
                    end
                    return true
                end

                local ok, retOrErr = pcall(e.callback or function() end)
                local mantenerAbierto = (ok and retOrErr == true) or false
                if not ok then
                    ReportarErrorMenu(retOrErr)
                end
                if not mantenerAbierto then
                    if HideMenu then HideMenu() end
                    if EZOTools then EZOTools._contextMenuOpen = false end
                end
            end)
        end
    end

    if ShowMenu then ShowMenu(anchor) end
    if EZOTools then EZOTools._contextMenuOpen = true end
end

-- Abre el menú contextual nativo de gamepad (ZO_GamepadContextMenu) si está disponible
local function AbrirMenuContextualGamepad()
    if GAMEPAD_CONTEXT_MENU and GAMEPAD_CONTEXT_MENU.AddOption and GAMEPAD_CONTEXT_MENU.Show then
        local ok = pcall(function()
            if GAMEPAD_CONTEXT_MENU.Clear then GAMEPAD_CONTEXT_MENU:Clear() end
            local entradas = ConstruirEntradas()
            for _, e in ipairs(entradas) do
                GAMEPAD_CONTEXT_MENU:AddOption(e.text or "?", function()
                    local ok2, err2 = pcall(e.callback or function() end)
                    if not ok2 then ReportarErrorMenu(err2) end
                    if GAMEPAD_CONTEXT_MENU.Hide then GAMEPAD_CONTEXT_MENU:Hide() end
                end)
            end
            GAMEPAD_CONTEXT_MENU:Show()
        end)
        if ok then return true end
    end
    return false
end

-- Abre el diálogo paramétrico de gamepad si no está disponible ZO_GamepadContextMenu.
local function AbrirDialogoGamepad()
    local nombre = "EZO_GAMEPAD_MENU"
    if not ZO_Dialogs_IsDialogRegistered(nombre) then
        ZO_Dialogs_RegisterCustomDialog(nombre, {
            gamepadInfo  = { dialogType = GAMEPAD_DIALOGS.PARAMETRIC_LIST },
            title        = { text = GetString(EZO_MENU_TITLE) },
            setup        = function(dialog)
                local list = dialog.info.parametricList
                ZO_ClearNumericallyIndexedTable(list)
                local entradas = ConstruirEntradas()
                for _, e in ipairs(entradas) do
                    local ed = ZO_GamepadEntryData:New(e.text or "?")
                    ed.callback = e.callback
                    table.insert(list, { template = "ZO_GamepadItemEntryTemplate", entryData = ed })
                end
                dialog:setupFunc()
            end,
            parametricList = {},
            buttons = {
                {
                    keybind  = "DIALOG_PRIMARY",
                    text     = SI_GAMEPAD_SELECT_OPTION,
                    callback = function(dialog)
                        local data = dialog.entryList:GetTargetData()
                        if data and data.entryData and data.entryData.callback then
                            local ok, err = pcall(data.entryData.callback)
                            if not ok then ReportarErrorMenu(err) end
                        end
                        ZO_Dialogs_ReleaseDialogOnButtonPress(nombre)
                    end,
                },
                { keybind = "DIALOG_NEGATIVE", text = SI_DIALOG_EXIT },
            },
        })
    end
    return pcall(function() ZO_Dialogs_ShowGamepadDialog(nombre) end)
end

-- Abre el menú de forma inteligente según el contexto (ya abierto → cerrar; gamepad → diálogo; ratón → ZO_Menu)
function EZOTools_ContextMenu.OpenSmart(anchor)
    -- Si ya está abierto, cerrarlo
    if EZOTools and EZOTools._contextMenuOpen and HideMenu then
        HideMenu()
        EZOTools._contextMenuOpen = false
        return
    end
    zo_callLater(function()
        if AbrirMenuContextualGamepad() then return end
        local ok = AbrirDialogoGamepad()
        if ok then return end
        EZOTools_ContextMenu.OpenMouse(anchor)
    end, 150)
end
