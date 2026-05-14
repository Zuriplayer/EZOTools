-- Wrapper comun para menus ZO_Menu de recientes en overlay-raton.
EZOTools_QuickUtilityRecentMenu = EZOTools_QuickUtilityRecentMenu or {}

local MOD = EZOTools_QuickUtilityRecentMenu

local function NormalizarTextoTooltip(texto)
    if type(texto) ~= "string" then
        return texto
    end
    texto = texto:gsub("|n", "\n")
    texto = texto:gsub("([%.%!%?])n([%u])", "%1\n%2")
    return texto
end

local function AddEntry(label, onSelect, tooltipText, enabled, onEnter, onExit)
    if type(label) ~= "string" or label == "" then
        return false
    end
    label = NormalizarTextoTooltip(label)

    local index = nil
    if type(AddCustomMenuItem) == "function" then
        index = AddCustomMenuItem(label, onSelect, MENU_ADD_OPTION_LABEL, nil, nil, nil, nil, nil, nil, onEnter, onExit, enabled ~= false)
    elseif type(AddMenuItem) == "function" then
        index = AddMenuItem(label, onSelect)
    else
        return false
    end

    if type(index) == "number" and type(AddCustomMenuTooltip) == "function" and type(tooltipText) == "string" and tooltipText ~= "" then
        AddCustomMenuTooltip(NormalizarTextoTooltip(tooltipText), index)
    end

    return true
end

function MOD.Open(anchor, entries, emptyLabel)
    if ClearMenu then
        ClearMenu()
    end

    local entriesAdded = 0
    if type(entries) == "table" then
        for _, entry in ipairs(entries) do
            if type(entry) == "table" and AddEntry(
                tostring(entry.label or ""),
                entry.onSelect,
                entry.tooltipText,
                entry.enabled,
                entry.onEnter,
                entry.onExit
            ) then
                entriesAdded = entriesAdded + 1
            end
        end
    end

    if entriesAdded == 0 then
        AddEntry(tostring(emptyLabel or ""), function() return true end, nil, false)
    end

    if ShowMenu then
        ShowMenu(anchor)
    end
end

function MOD.OpenFood(anchor, quickUtility, handlers)
    if not (quickUtility and type(quickUtility.BuildRecentEntries) == "function") then
        MOD.Open(anchor, {}, "")
        return
    end

    handlers = type(handlers) == "table" and handlers or {}
    local entries = {}
    local recentEntries = quickUtility.BuildRecentEntries("food") or {}
    for _, entry in ipairs(recentEntries) do
        local itemLinkTooltip = tostring(entry.previewItemLink or "")
        entries[#entries + 1] = {
            label = tostring(entry.text or ""),
            enabled = entry.empty ~= true,
            onEnter = function(control)
                if itemLinkTooltip ~= "" and type(handlers.ShowItem) == "function" then
                    handlers.ShowItem(control, itemLinkTooltip)
                end
            end,
            onExit = function()
                if type(handlers.ClearItem) == "function" then
                    handlers.ClearItem()
                end
            end,
            onSelect = function()
                if type(entry.callback) == "function" then
                    entry.callback()
                end
            end,
        }
    end

    MOD.Open(anchor, entries, "")
end
