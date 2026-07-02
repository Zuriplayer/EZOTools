-- Menu lateral rapido de utilidades (HOLD Y / equivalente teclado).
-- Comparte infraestructura con HOLD X y mantiene recientes como submenu separado.

local EZO = _G.EZOTools or {}
_G.EZOTools = EZO

local Core = EZO.SideMenuCore
EZO.GamepadUtilityDialog = EZO.GamepadUtilityDialog or {}
local Dialog = EZO.GamepadUtilityDialog

local NOMBRE_DIALOGO = "EZO_GAMEPAD_UTILITY_DIALOG"
local QuickUtility = _G.EZOTools_QuickUtility

-- Versión única en shared_utils.lua
local ConstruirSubtituloDialogo = EZOTools_ConstruirSubtituloDialogo

local function RecopilarAcciones()
    if QuickUtility and type(QuickUtility.BuildEntries) == "function" then
        return QuickUtility.BuildEntries()
    end
    return {}
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

local function PrepararCallback(entry)
    local actionKey = tostring(entry.key or "")
    local actionText = tostring(entry.text or "")
    local cbOriginal = function()
        return AbrirDialogoRecientes({ key = actionKey, text = actionText })
    end
    return function()
        EZOTools_CerrarDialogoGamepad(NOMBRE_DIALOGO)
        if zo_callLater then
            zo_callLater(function() pcall(cbOriginal) end, 200)
        else
            pcall(cbOriginal)
        end
        return false
    end
end

if Core and type(Core.CreateDialog) == "function" then
    Core.CreateDialog({
        namespace = Dialog,
        dialogName = NOMBRE_DIALOGO,
        titleText = function() return GetString(EZO_UTILITY_MENU_TITLE) end,
        mainText = ConstruirSubtituloDialogo,
        emptyText = function() return GetString(EZO_UTILITY_MENU_TITLE) end,
        buildEntries = RecopilarAcciones,
        prepareCallback = PrepararCallback,
        trackActiveDialog = true,
        onNegative = function(_, _, closeCurrent)
            closeCurrent()
        end,
    })
end
