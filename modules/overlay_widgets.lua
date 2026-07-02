-- Estado y configuracion de widgets laterales del overlay.
-- El render y los handlers de raton siguen en overlay.lua para no mezclar UI con datos.
EZOTools_OverlayWidgets = EZOTools_OverlayWidgets or {}

local MOD = EZOTools_OverlayWidgets

local SIDE_SLOT_COUNT    = 4
local SIDE_SLOT_BASE     = 22
local SIDE_SLOT_MIN      = 18
local SIDE_SLOT_GAP      = 6
local SIDE_SLOT_MARGIN   = 12
local SIDE_SLOT_RADIUS_X = 0.50
local SIDE_SLOT_RADIUS_Y = 0.78
local SIDE_SLOT_Y        = { -0.50, -0.16, 0.16, 0.50 }

local SIDE_WIDGET_ASSIGNMENTS = {
    foodBuff        = { side = "right", index = 1 },
    repairEquipped  = { side = "left", index = 1 },
    repairKits      = { side = "left", index = 2 },
    rechargeWeapons = { side = "left", index = 3 },
    soulGems        = { side = "left", index = 4 },
}

local sideWidgetData = { left = {}, right = {} }
local layoutPreviewEnabled = false

function MOD.GetSlotCount()
    return SIDE_SLOT_COUNT
end

function MOD.GetSlotBase()
    return SIDE_SLOT_BASE
end

function MOD.GetSlotMin()
    return SIDE_SLOT_MIN
end

function MOD.GetSlotGap()
    return SIDE_SLOT_GAP
end

function MOD.GetSlotMargin()
    return SIDE_SLOT_MARGIN
end

function MOD.GetRadiusX()
    return SIDE_SLOT_RADIUS_X
end

function MOD.GetRadiusY()
    return SIDE_SLOT_RADIUS_Y
end

function MOD.GetYRatios()
    return SIDE_SLOT_Y
end

function MOD.GetAssignment(key)
    return SIDE_WIDGET_ASSIGNMENTS[key]
end

function MOD.GetSideName(side)
    if side == "left" then
        return GetString(EZO_SIDE_WIDGET_LEFT)
    end
    return GetString(EZO_SIDE_WIDGET_RIGHT)
end

function MOD.GetDataList(side)
    return sideWidgetData[side]
end

function MOD.BuildData(config)
    if type(config) ~= "table" then return nil end
    return {
        slotKey = config.slotKey,
        visible = config.visible ~= false,
        texture = config.texture,
        color = config.color,
        alpha = config.alpha or 1,
        tooltipText = config.tooltipText,
        tooltipStringId = config.tooltipStringId,
        tooltipArgs = config.tooltipArgs,
        actionId = config.actionId,
        secondaryActionId = config.secondaryActionId,
        gamepadActionId = config.gamepadActionId,
        primaryHandler = config.primaryHandler,
        secondaryHandler = config.secondaryHandler,
    }
end

function MOD.GetPreviewTooltip(side, index)
    for key, slotInfo in pairs(SIDE_WIDGET_ASSIGNMENTS) do
        if slotInfo and slotInfo.side == side and slotInfo.index == index then
            if key == "foodBuff" then
                return GetString(EZO_SIDE_WIDGET_FOOD_PREVIEW_TOOLTIP)
            end
            if key == "repairEquipped" then
                return GetString(EZO_SIDE_WIDGET_REPAIR_EQUIPPED_PREVIEW_TOOLTIP)
            end
            if key == "repairKits" then
                return GetString(EZO_SIDE_WIDGET_REPAIR_KITS_PREVIEW_TOOLTIP)
            end
            if key == "rechargeWeapons" then
                return GetString(EZO_SIDE_WIDGET_RECHARGE_WEAPONS_PREVIEW_TOOLTIP)
            end
            if key == "soulGems" then
                return GetString(EZO_SIDE_WIDGET_SOUL_GEMS_PREVIEW_TOOLTIP)
            end
        end
    end

    return zo_strformat(
        GetString(EZO_SIDE_WIDGET_PREVIEW_TOOLTIP),
        MOD.GetSideName(side),
        tostring(index))
end

function MOD.GetPreviewData(side, index)
    local previewTexture = "/esoui/art/buttons/large_leftarrow_up.dds"
    local previewColors = {
        left = {
            { 0.95, 0.85, 0.35, 0.95 },
            { 0.75, 0.86, 0.40, 0.95 },
            { 0.45, 0.80, 0.95, 0.95 },
            { 0.90, 0.55, 0.85, 0.95 },
        },
        right = {
            { 0.95, 0.70, 0.30, 0.95 },
            { 0.70, 0.70, 0.95, 0.95 },
            { 0.92, 0.92, 0.92, 0.95 },
            { 0.95, 0.35, 0.35, 0.95 },
        },
    }

    local assignedPreview = {
        repairEquipped = {
            texture = "/esoui/art/hud/broken_armor.dds",
            color = { 1.0, 0.30, 0.30, 0.95 },
        },
        repairKits = {
            texture = "/esoui/art/icons/quest_crate_001.dds",
            color = { 1.0, 0.32, 0.22, 0.95 },
        },
        rechargeWeapons = {
            texture = "/esoui/art/hud/broken_weapon.dds",
            color = { 1.0, 0.30, 0.30, 0.95 },
        },
        soulGems = {
            texture = "/esoui/art/icons/soulgem_006_filled.dds",
            color = { 1.0, 0.45, 0.15, 0.95 },
        },
        foodBuff = {
            texture = "/esoui/art/inventory/inventory_tabIcon_Craftbag_provisioning_up.dds",
            color = { 0.35, 0.85, 0.35, 0.95 },
        },
    }

    for key, slotInfo in pairs(SIDE_WIDGET_ASSIGNMENTS) do
        if slotInfo and slotInfo.side == side and slotInfo.index == index and assignedPreview[key] then
            return {
                visible = true,
                texture = assignedPreview[key].texture,
                color = assignedPreview[key].color,
                alpha = 0.95,
            }
        end
    end

    return {
        visible = true,
        texture = previewTexture,
        color = previewColors[side][index],
        alpha = 0.95,
    }
end

function MOD.GetRenderData(side, index)
    local dataList = sideWidgetData[side]
    local data = dataList and dataList[index] or nil
    if type(data) == "table" and data.visible ~= false and type(data.texture) == "string" and data.texture ~= "" then
        return data
    end
    if layoutPreviewEnabled then
        return MOD.GetPreviewData(side, index)
    end
    return nil
end

function MOD.Assign(slotInfo, data)
    if not slotInfo or not slotInfo.side or not slotInfo.index then return end
    local dataList = sideWidgetData[slotInfo.side]
    if not dataList then return end
    dataList[slotInfo.index] = data
end

function MOD.ToggleLayoutPreview()
    layoutPreviewEnabled = not layoutPreviewEnabled
    return layoutPreviewEnabled
end

function MOD.SetLayoutPreviewEnabled(enabled)
    layoutPreviewEnabled = enabled == true
    return layoutPreviewEnabled
end

function MOD.DisableLayoutPreview()
    return MOD.SetLayoutPreviewEnabled(false)
end

function MOD.IsLayoutPreviewEnabled()
    return layoutPreviewEnabled
end
