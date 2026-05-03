-- Proveedor de entradas de HOLD Y.
-- Construye el menu principal y delega en overlay.lua la ejecucion/recientes/previews
-- que aun dependen de comida, colecciones y tooltips del overlay.
EZOTools_QuickUtility = EZOTools_QuickUtility or {}

local MOD = EZOTools_QuickUtility

local CATEGORY_DEFINITIONS = {
    { key = "assistant", textKey = "EZO_UTILITY_ENTRY_ASSISTANT" },
    { key = "companion", textKey = "EZO_UTILITY_ENTRY_COMPANION" },
    { key = "food", textKey = "EZO_UTILITY_ENTRY_FOOD" },
    { key = "pet", textKey = "EZO_UTILITY_ENTRY_PET" },
    { key = "mount", textKey = "EZO_UTILITY_ENTRY_MOUNT" },
    { key = "houses", textKey = "EZO_UTILITY_ENTRY_HOUSES" },
    { key = "otherHouses", textKey = "EZO_UTILITY_ENTRY_OTHER_HOUSES" },
}

local function ObtenerOverlay()
    local overlay = _G.EZOTools_Overlay
    if type(overlay) == "table" then
        return overlay
    end
    return nil
end

local function AgregarEntrada(entries, key, textKey)
    if type(entries) ~= "table" or type(key) ~= "string" or key == "" or type(textKey) ~= "string" then
        return
    end
    local textId = _G[textKey]
    if textId == nil then return end
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
    for _, definition in ipairs(CATEGORY_DEFINITIONS) do
        AgregarEntrada(entries, definition.key, definition.textKey)
    end
    return entries
end

function MOD.BuildRecentEntries(key, useEmptyAction)
    key = tostring(key or "")
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
    key = tostring(key or "")
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
