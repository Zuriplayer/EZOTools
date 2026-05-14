-- Resolucion de previews para HOLD Y.
-- Interpreta los datos de preview y delega el render en la capa visual.
EZOTools_QuickUtilityPreview = EZOTools_QuickUtilityPreview or {}

local MOD = EZOTools_QuickUtilityPreview

function MOD.Show(control, entryData, handlers)
    if not control or type(entryData) ~= "table" or type(handlers) ~= "table" then
        return false
    end

    local previewKind = tostring(entryData.previewKind or "")
    if previewKind == "item" then
        local itemLink = tostring(entryData.previewItemLink or "")
        if itemLink ~= "" and type(handlers.ShowItem) == "function" then
            handlers.ShowItem(control, itemLink)
            return true
        end
        return false
    end

    if previewKind == "collectible" then
        local collectibleId = tonumber(entryData.previewCollectibleId) or 0
        if collectibleId > 0 and type(handlers.ShowCollectible) == "function" then
            handlers.ShowCollectible(control, collectibleId, tostring(entryData.previewFallbackName or ""))
            return true
        end
        return false
    end

    return false
end
