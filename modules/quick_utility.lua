-- Proveedor de entradas de HOLD Y.
-- Construye el menu principal y delega en overlay.lua la ejecucion/recientes/previews
-- que aun dependen de comida, colecciones y tooltips del overlay.
EZOTools_QuickUtility = EZOTools_QuickUtility or {}

local MOD = EZOTools_QuickUtility

local function ObtenerOverlay()
    local overlay = _G.EZOTools_Overlay
    if type(overlay) == "table" then
        return overlay
    end
    return nil
end

local function AgregarEntrada(entries, key, textId)
    if type(entries) ~= "table" or type(key) ~= "string" or key == "" or not textId then
        return
    end
    local text = GetString(textId)
    if type(text) ~= "string" or text == "" then
        return
    end
    entries[#entries + 1] = {
        key = key,
        text = text,
        callback = function()
            local overlay = ObtenerOverlay()
            if overlay and type(overlay.ExecuteQuickUtilityAction) == "function" then
                return overlay.ExecuteQuickUtilityAction(key)
            end
            return false
        end,
    }
end

function MOD.BuildEntries()
    local entries = {}
    AgregarEntrada(entries, "assistant", EZO_UTILITY_ENTRY_ASSISTANT)
    AgregarEntrada(entries, "companion", EZO_UTILITY_ENTRY_COMPANION)
    AgregarEntrada(entries, "food", EZO_UTILITY_ENTRY_FOOD)
    AgregarEntrada(entries, "pet", EZO_UTILITY_ENTRY_PET)
    AgregarEntrada(entries, "mount", EZO_UTILITY_ENTRY_MOUNT)
    return entries
end

function MOD.BuildRecentEntries(key, useEmptyAction)
    local overlay = ObtenerOverlay()
    if overlay and type(overlay.BuildQuickUtilityRecentEntries) == "function" then
        local ok, entries = pcall(overlay.BuildQuickUtilityRecentEntries, key, useEmptyAction)
        if ok and type(entries) == "table" then
            return entries
        end
    end
    return {}
end

function MOD.GetHistoryEmptyLabel(key)
    local overlay = ObtenerOverlay()
    if overlay and type(overlay.GetQuickUtilityHistoryEmptyLabel) == "function" then
        local ok, text = pcall(overlay.GetQuickUtilityHistoryEmptyLabel, key)
        if ok and type(text) == "string" then
            return text
        end
    end
    return ""
end

function MOD.ShowPreview(control, entryData)
    local overlay = ObtenerOverlay()
    if overlay and type(overlay.ShowQuickUtilityPreview) == "function" then
        local ok, shown = pcall(overlay.ShowQuickUtilityPreview, control, entryData)
        return ok and shown == true
    end
    return false
end

function MOD.HidePreview()
    local overlay = ObtenerOverlay()
    if overlay and type(overlay.HideQuickUtilityPreview) == "function" then
        pcall(overlay.HideQuickUtilityPreview)
    end
end

function MOD.NormalizeTooltipText(text)
    text = tostring(text or "")
    local overlay = ObtenerOverlay()
    if overlay and type(overlay.NormalizeTooltipText) == "function" then
        local ok, normalized = pcall(overlay.NormalizeTooltipText, text)
        if ok and type(normalized) == "string" then
            return normalized
        end
    end
    return text
end
