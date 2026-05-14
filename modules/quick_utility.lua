-- Proveedor de entradas de HOLD Y.
-- Construye el menu principal y delega en proveedores dedicados cuando existen.
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

local function ObtenerHouseProvider()
    local provider = _G.EZOTools_QuickUtilityHouses
    if type(provider) == "table" then
        return provider
    end
    return nil
end

local function ObtenerFoodProvider()
    local provider = _G.EZOTools_QuickUtilityFood
    if type(provider) == "table" then
        return provider
    end
    return nil
end

local function ObtenerAllyProvider()
    local provider = _G.EZOTools_QuickUtilityAllies
    if type(provider) == "table" then
        return provider
    end
    return nil
end

local function EsCategoriaCasas(key)
    key = tostring(key or "")
    return key == "houses" or key == "otherHouses"
end

local function ObtenerConfiguracionAliado(key)
    local provider = ObtenerAllyProvider()
    if provider and type(provider.GetConfig) == "function" then
        return provider.GetConfig(key)
    end
    return nil
end

local function ProgramarRefrescoOverlayDots()
    local overlay = ObtenerOverlay()
    if overlay and type(overlay.RefreshDot) == "function" then
        overlay.RefreshDot()
        if type(zo_callLater) == "function" then
            zo_callLater(function()
                if overlay and type(overlay.RefreshDot) == "function" then
                    overlay.RefreshDot()
                end
            end, 500)
            zo_callLater(function()
                if overlay and type(overlay.RefreshDot) == "function" then
                    overlay.RefreshDot()
                end
            end, 1500)
        end
    end
end

local function ObtenerAliadoActivoId(key)
    local provider = ObtenerAllyProvider()
    if provider and type(provider.GetActiveId) == "function" then
        return tonumber(provider.GetActiveId(key)) or 0
    end
    return 0
end

local function EjecutarAccionAliado(key, msgOcultarId, msgInvocarId)
    local provider = ObtenerAllyProvider()
    if not provider then
        return false
    end

    local activo = ObtenerAliadoActivoId(key) ~= 0
    if _G.EZOTools and type(_G.EZOTools.Print) == "function" then
        _G.EZOTools.Print(GetString(activo and msgOcultarId or msgInvocarId))
    end

    local ok = false
    if activo then
        ok = type(provider.HideActive) == "function" and provider.HideActive(key) or false
    else
        ok = type(provider.InvokeRemembered) == "function" and provider.InvokeRemembered(key) or false
    end
    if ok then
        ProgramarRefrescoOverlayDots()
    end
    return ok
end

local function EjecutarAccionUtilidad(key)
    if EsCategoriaCasas(key) then
        local provider = ObtenerHouseProvider()
        if provider and type(provider.ExecuteAction) == "function" then
            return provider.ExecuteAction(key)
        end
        return false
    end

    if key == "food" then
        local provider = ObtenerFoodProvider()
        if provider and type(provider.ReuseRecordedFood) == "function" then
            return provider.ReuseRecordedFood()
        end
        return false
    end

    if key == "assistant" then
        return EjecutarAccionAliado(key, EZO_MSG_HIDE_ASSISTANT, EZO_MSG_SUMMON_ASSISTANT)
    end
    if key == "companion" then
        return EjecutarAccionAliado(key, EZO_MSG_HIDE_COMPANION, EZO_MSG_SUMMON_COMPANION)
    end
    if key == "pet" then
        return EjecutarAccionAliado(key, EZO_MSG_HIDE_PET, EZO_MSG_SUMMON_PET)
    end
    if key == "mount" then
        local provider = ObtenerAllyProvider()
        if provider and type(provider.InvokeRemembered) == "function" then
            return provider.InvokeRemembered(key)
        end
    end

    return false
end

local function AbrirColeccionAliado(key)
    local provider = ObtenerAllyProvider()
    if provider and type(provider.OpenCollection) == "function" then
        return provider.OpenCollection(key)
    end
    return false
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
            return EjecutarAccionUtilidad(key)
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

function MOD.BuildRecentEntries(key, useEmptyAction, options)
    key = tostring(key or "")
    if key == "food" then
        local provider = ObtenerFoodProvider()
        if provider and type(provider.BuildRecentEntries) == "function" then
            local ok, entries = pcall(provider.BuildRecentEntries, options)
            if ok and type(entries) == "table" then
                return entries
            end
        end
        return {}
    end
    if EsCategoriaCasas(key) then
        local provider = ObtenerHouseProvider()
        if provider and type(provider.BuildRecentEntries) == "function" then
            local ok, entries = pcall(provider.BuildRecentEntries, key, useEmptyAction)
            if ok and type(entries) == "table" then
                return entries
            end
        end
        return {}
    end

    local provider = ObtenerAllyProvider()
    local config = ObtenerConfiguracionAliado(key)
    if provider and config and type(provider.BuildRecentEntries) == "function" then
        local ok, entries = pcall(
            provider.BuildRecentEntries,
            key,
            useEmptyAction == true,
            function(finalId)
                return function()
                    return type(provider.InvokeFromHistory) == "function"
                        and provider.InvokeFromHistory(key, finalId)
                        or false
                end
            end,
            function()
                return AbrirColeccionAliado(key)
            end
        )
        if ok and type(entries) == "table" then
            for _, entry in ipairs(entries) do
                if type(entry) == "table" and entry.previewCollectibleId then
                    entry.previewKind = "collectible"
                    entry.previewFallbackName = type(provider.GetFallbackName) == "function" and provider.GetFallbackName(key) or ""
                end
            end
            return entries
        end
    end
    return {}
end

function MOD.GetHistoryEmptyLabel(key)
    key = tostring(key or "")
    if key == "food" then
        local provider = ObtenerFoodProvider()
        if provider and type(provider.GetHistoryEmptyLabel) == "function" then
            local ok, text = pcall(provider.GetHistoryEmptyLabel)
            if ok and type(text) == "string" then
                return text
            end
        end
        return ""
    end
    if EsCategoriaCasas(key) then
        local provider = ObtenerHouseProvider()
        if provider and type(provider.GetHistoryEmptyLabel) == "function" then
            local ok, text = pcall(provider.GetHistoryEmptyLabel, key)
            if ok and type(text) == "string" then
                return text
            end
        end
        return ""
    end

    local provider = ObtenerAllyProvider()
    if ObtenerConfiguracionAliado(key) and provider and type(provider.GetHistoryEmptyLabel) == "function" then
        local ok, text = pcall(provider.GetHistoryEmptyLabel, key)
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
