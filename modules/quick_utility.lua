-- Fachada de datos/previews para HOLD Y.
-- De momento delega en overlay.lua para no mover logica funcional sensible.
-- El objetivo es que los dialogos de utilidades no dependan directamente del overlay.
EZOTools_QuickUtility = EZOTools_QuickUtility or {}

local MOD = EZOTools_QuickUtility

local function ObtenerOverlay()
    local overlay = _G.EZOTools_Overlay
    if type(overlay) == "table" then
        return overlay
    end
    return nil
end

function MOD.BuildEntries()
    local overlay = ObtenerOverlay()
    if overlay and type(overlay.BuildQuickUtilityEntries) == "function" then
        local ok, entries = pcall(overlay.BuildQuickUtilityEntries)
        if ok and type(entries) == "table" then
            return entries
        end
    end
    return {}
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
