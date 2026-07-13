-- Reusable HUD status panel with optional contextual actions.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.StatusPanel = EZO.StatusPanel or {}
local MOD = EZO.StatusPanel

local PANEL_WIDTH = 520
local PANEL_MIN_HEIGHT = 190
local PANEL_MAX_HEIGHT = 680
local CONTENT_LEFT = 16
local CONTENT_RIGHT = -16
local ACTION_WIDTH = 180

local ICONS = {
    success = "EsoUI/Art/Miscellaneous/bullet.dds",
    pending = "EsoUI/Art/Miscellaneous/bullet.dds",
    error = "EsoUI/Art/Miscellaneous/bullet.dds",
}

local DENSITY_LAYOUTS = {
    comfortable = {
        contextY = 44,
        afterContext = 31,
        afterProgress = 31,
        afterStage = 34,
        alertGap = 14,
        metricsGap = 16,
        rowsTitleHeight = 26,
        rowGap = 4,
        rowHeightKeyboard = 38,
        rowHeightGamepad = 42,
        bottom = 16,
    },
    standard = {
        contextY = 43,
        afterContext = 29,
        afterProgress = 29,
        afterStage = 31,
        alertGap = 12,
        metricsGap = 12,
        rowsTitleHeight = 24,
        rowGap = 3,
        rowHeightKeyboard = 36,
        rowHeightGamepad = 40,
        bottom = 14,
    },
    compact = {
        contextY = 41,
        afterContext = 27,
        afterProgress = 27,
        afterStage = 28,
        alertGap = 10,
        metricsGap = 8,
        rowsTitleHeight = 22,
        rowGap = 2,
        rowHeightKeyboard = 34,
        rowHeightGamepad = 38,
        bottom = 12,
    },
}

local COLORS = {
    success = { 0.40, 0.80, 0.40, 1 },
    info = { 0.40, 0.75, 1.00, 1 },
    pending = { 0.85, 0.79, 0.36, 1 },
    warning = { 1.00, 0.67, 0.00, 1 },
    error = { 1.00, 0.40, 0.40, 1 },
    muted = { 0.60, 0.60, 0.60, 1 },
    normal = { 0.94, 0.94, 0.90, 1 },
}

local Panel = {}
Panel.__index = Panel

local panels = {}
local platformEventRegistered = false

local function GetColor(value, fallback)
    if type(value) == "table" then
        return value
    end
    return COLORS[value] or COLORS[fallback or "normal"]
end

local function SetColor(control, value, fallback)
    local color = GetColor(value, fallback)
    control:SetColor(color[1], color[2], color[3], color[4] or 1)
end

local function SafeInvoke(callback, ...)
    if type(callback) ~= "function" then
        return false
    end
    local ok, result = pcall(callback, ...)
    if not ok and EZO and type(EZO.DebugPrint) == "function" then
        EZO.DebugPrint(zo_strformat(GetString(EZO_DEBUG_STATUS_PANEL_CALLBACK_FAILED), tostring(result)))
    end
    return ok, result
end

local function IsGamepadMode()
    return type(IsInGamepadPreferredMode) == "function" and IsInGamepadPreferredMode()
end

local function RegisterPlatformEvent()
    if platformEventRegistered
        or not EVENT_MANAGER
        or EVENT_GAMEPAD_PREFERRED_MODE_CHANGED == nil then
        return
    end
    platformEventRegistered = true
    EVENT_MANAGER:RegisterForEvent("EZOTools_StatusPanel_Platform", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function()
        for _, panel in pairs(panels) do
            panel:ApplyPlatformStyle()
            panel:Render()
        end
    end)
end

function Panel:RefreshMouseState()
    self.control:SetMovable(self.movable == true)
    self.control:SetMouseEnabled(self.movable == true or self.interactionActive == true)
end

function Panel:SetMovable(enabled)
    self.movable = enabled == true
    self:RefreshMouseState()
end

function Panel:SetWidth(width)
    width = tonumber(width)
    if not width or width <= 0 then
        return false
    end
    self.width = width
    if self.model then
        self:Render()
    else
        self.control:SetWidth(width)
    end
    return true
end

function Panel:SetPosition(x, y)
    self.control:ClearAnchors()
    if tonumber(x) and tonumber(y) then
        self.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, tonumber(x), tonumber(y))
    else
        self.control:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, -40, 140)
    end
end

function Panel:GetPosition()
    return self.control:GetLeft(), self.control:GetTop()
end

function Panel:SetMoveStopCallback(callback)
    self.onMoveStop = callback
end

function Panel:ApplyPlatformStyle()
    local gamepad = IsGamepadMode()
    self.rowHeight = gamepad and 32 or 28
    self.metricsHeight = gamepad and 46 or 42
    self.title:SetFont(gamepad and "ZoFontGamepadBold27" or "ZoFontWinH3")
    self.phase:SetFont(gamepad and "ZoFontGamepad22" or "ZoFontGameShadow")
    self.context:SetFont(gamepad and "ZoFontGamepad27" or "ZoFontGame")
    self.totalTime:SetFont(gamepad and "ZoFontGamepad22" or "ZoFontGame")
    self.stage:SetFont(gamepad and "ZoFontGamepad27" or "ZoFontGameShadow")
    self.stageTime:SetFont(gamepad and "ZoFontGamepad22" or "ZoFontGameSmall")
    self.alertText:SetFont(gamepad and "ZoFontGamepad27" or "ZoFontGame")
    self.rowsTitle:SetFont(gamepad and "ZoFontGamepadBold22" or "ZoFontGameShadow")
    self.progressValue:SetFont(gamepad and "ZoFontGamepad22" or "ZoFontGameShadow")
    for _, control in ipairs(self.metricControls or {}) do
        control:GetNamedChild("Value"):SetFont(gamepad and "ZoFontGamepad27" or "ZoFontWinH3")
        control:GetNamedChild("Label"):SetFont(gamepad and "ZoFontGamepad22" or "ZoFontGameSmall")
    end
end

function Panel:RemoveKeybinds()
    if self.keybindsAdded and KEYBIND_STRIP and self.keybindGroup then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindGroup)
    end
    self.keybindsAdded = false
end

function Panel:RefreshKeybinds()
    self:RemoveKeybinds()
    if not self.interactionActive
        or self.control:IsHidden()
        or not KEYBIND_STRIP
        or type(self.actions) ~= "table"
        or #self.actions == 0 then
        return
    end

    local group = {}
    for _, action in ipairs(self.actions) do
        if #group < 2 and action.visible ~= false and action.keybind then
            local actionId = action.id
            group[#group + 1] = {
                alignment = action.alignment or KEYBIND_STRIP_ALIGN_RIGHT,
                name = action.label or "",
                keybind = action.keybind,
                enabled = action.enabled ~= false,
                callback = function()
                    self:InvokeAction(actionId)
                end,
            }
        end
    end
    if #group > 0 then
        self.keybindGroup = group
        KEYBIND_STRIP:AddKeybindButtonGroup(group)
        self.keybindsAdded = true
    end
end

function Panel:SetInteractionActive(enabled)
    self.interactionActive = enabled == true and type(self.actions) == "table" and #self.actions > 0
    self:RefreshMouseState()
    if self.model then
        self:Render()
    else
        self:RefreshKeybinds()
        self:RenderActions()
    end
end

function Panel:InvokeAction(actionId)
    if not self.interactionActive then
        return false
    end
    for _, action in ipairs(self.actions or {}) do
        if action.id == actionId and action.visible ~= false and action.enabled ~= false then
            local ok = SafeInvoke(action.callback, action, self)
            return ok
        end
    end
    return false
end

function Panel:RenderActions()
    self.actionPool:ReleaseAllObjects()
    self.actionsControl:SetHidden(true)
    self.actionsControl:SetHeight(0)
    if not self.interactionActive then
        return 0
    end

    local visibleActions = {}
    for _, action in ipairs(self.actions or {}) do
        if #visibleActions < 2 and action.visible ~= false then
            visibleActions[#visibleActions + 1] = action
        end
    end
    if #visibleActions == 0 then
        return 0
    end

    local gamepad = IsGamepadMode()
    for index, action in ipairs(visibleActions) do
        local actionId = action.id
        local control = self.actionPool:AcquireObject()
        control:SetHidden(false)
        control:SetDimensions(ACTION_WIDTH, 35)
        control:SetAnchor(TOPRIGHT, self.actionsControl, TOPRIGHT, -((index - 1) * ACTION_WIDTH), 0)
        ApplyTemplateToControl(control, gamepad and "ZO_KeybindButton_Gamepad_Template" or "ZO_KeybindButton_Keyboard_Template")
        control:SetKeybind(
            action.keybind,
            false,
            action.gamepadKeybind or action.keybind,
            false
        )
        control:SetText(action.label or "")
        control:SetEnabled(action.enabled ~= false)
        control:SetCallback(function()
            self:InvokeAction(actionId)
        end)
    end
    self.actionsControl:SetHidden(false)
    self.actionsControl:SetHeight(35)
    return 35
end

function Panel:RenderRows(rows)
    self.rowPool:ReleaseAllObjects()
    self.rowsControl:SetHeight(0)
    local rowCount = type(rows) == "table" and #rows or 0
    local gamepad = IsGamepadMode()
    local layout = self.currentLayout or DENSITY_LAYOUTS.compact
    local rowGap = tonumber(layout.rowGap) or 2
    local rowHeight = tonumber(self.rowHeight) or 28
    for index, row in ipairs(rows or {}) do
        local control = self.rowPool:AcquireObject()
        local icon = control:GetNamedChild("Icon")
        local name = control:GetNamedChild("Name")
        local status = control:GetNamedChild("Status")
        local location = control:GetNamedChild("Location")
        local background = control:GetNamedChild("Background")
        control:SetHidden(false)
        control:SetHeight(rowHeight)
        control:SetAnchor(TOPLEFT, self.rowsControl, TOPLEFT, 0, (index - 1) * (rowHeight + rowGap))
        control:SetAnchor(TOPRIGHT, self.rowsControl, TOPRIGHT, 0, (index - 1) * (rowHeight + rowGap))
        background:SetAlpha(index % 2 == 0 and 0.40 or 0.24)
        icon:SetTexture(row.icon or ICONS[row.iconType or row.tone or "pending"])
        icon:SetHidden(row.icon == false)
        local iconSize = gamepad and 16 or 14
        icon:ClearAnchors()
        icon:SetDimensions(iconSize, iconSize)
        SetColor(icon, row.tone, "pending")
        status:ClearAnchors()
        location:ClearAnchors()
        name:ClearAnchors()
        status:SetVerticalAlignment(TEXT_ALIGN_CENTER)
        location:SetVerticalAlignment(TEXT_ALIGN_CENTER)
        name:SetVerticalAlignment(TEXT_ALIGN_CENTER)
        if tostring(row.location or "") ~= "" then
            local locationWidth = gamepad and 175 or 165
            local statusWidth = gamepad and 110 or 90
            icon:SetAnchor(LEFT, control, LEFT, 5, 0)
            location:SetHidden(false)
            location:SetDimensions(locationWidth, rowHeight)
            location:SetAnchor(RIGHT, control, RIGHT, -7, 0)
            location:SetFont(gamepad and "ZoFontGamepad18" or "ZoFontGameSmall")
            location:SetText(tostring(row.location))
            SetColor(location, row.locationTone, "muted")
            status:SetDimensions(statusWidth, rowHeight)
            status:SetAnchor(RIGHT, location, LEFT, -8, 0)
            name:SetHeight(rowHeight)
            name:SetAnchor(LEFT, icon, RIGHT, 6, 0)
            name:SetAnchor(RIGHT, status, LEFT, -8, 0)
        else
            icon:SetAnchor(LEFT, control, LEFT, 5, 0)
            status:SetDimensions(170, rowHeight)
            status:SetAnchor(RIGHT, control, RIGHT, -7, 0)
            location:SetHidden(true)
            location:SetText("")
            name:SetHeight(gamepad and 26 or 22)
            name:SetAnchor(LEFT, icon, RIGHT, 6, 0)
            name:SetAnchor(RIGHT, status, LEFT, -8, 0)
        end
        name:SetFont(gamepad and "ZoFontGamepad22" or "ZoFontGame")
        name:SetText(tostring(row.name or ""))
        status:SetFont(gamepad and "ZoFontGamepad22" or "ZoFontGameSmall")
        status:SetText(tostring(row.status or ""))
        SetColor(status, row.tone, "normal")
    end
    local height = rowCount > 0 and (rowCount * rowHeight) + ((rowCount - 1) * rowGap) or 0
    self.rowsControl:SetHeight(height)
    return height
end

function Panel:RenderMetrics(metrics)
    local count = math.min(4, type(metrics) == "table" and #metrics or 0)
    for index, control in ipairs(self.metricControls) do
        local metric = metrics and metrics[index]
        control:ClearAnchors()
        if index <= count and metric then
            control:SetHidden(false)
            local slotWidth = math.floor((self.width - 32) / count)
            control:SetDimensions(slotWidth, self.metricsHeight or 42)
            control:SetAnchor(TOPLEFT, self.metricsControl, TOPLEFT, (index - 1) * slotWidth, 0)
            control:GetNamedChild("Value"):SetText(tostring(metric.value or ""))
            control:GetNamedChild("Label"):SetText(tostring(metric.label or ""))
            SetColor(control:GetNamedChild("Value"), metric.tone, "normal")
        else
            control:SetHidden(true)
        end
    end
    self.metricsControl:SetHeight(count > 0 and (self.metricsHeight or 42) or 0)
    self.metricsControl:SetHidden(count == 0)
    return count > 0 and (self.metricsHeight or 42) or 0
end

function Panel:Render()
    if not self.model then
        return
    end
    local model = self.model
    local rows = model.rows or {}
    local density = tostring(model.density or "")
    if not DENSITY_LAYOUTS[density] then
        if #rows <= 4 then
            density = "comfortable"
        elseif #rows <= 7 then
            density = "standard"
        else
            density = "compact"
        end
    end
    local layout = DENSITY_LAYOUTS[density]
    self.currentLayout = layout
    self.phase:ClearAnchors()
    self.phase:SetDimensions(100, 28)
    self.phase:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, CONTENT_RIGHT, 11)
    self.title:ClearAnchors()
    self.title:SetDimensions(math.max(120, self.width - 144), 30)
    self.title:SetAnchor(TOPLEFT, self.control, TOPLEFT, CONTENT_LEFT, 11)
    self.title:SetText(tostring(model.title or ""))
    self.phase:SetText(tostring(model.phaseText or ""))
    self.context:SetText(tostring(model.contextText or ""))
    self.totalTime:SetText(tostring(model.totalTimeText or ""))
    self.stage:SetText(tostring(model.statusText or ""))
    self.stageTime:SetText(tostring(model.statusTimeText or ""))

    local progress = model.progress or {}
    self.progress:SetMinMax(tonumber(progress.min) or 0, tonumber(progress.max) or 1)
    self.progress:SetValue(tonumber(progress.value) or 0)
    self.progress:GetNamedChild("Progress"):SetText("")
    self.progressValue:SetText(tostring(progress.text or ""))

    local y = layout.contextY
    self.context:ClearAnchors()
    self.context:SetAnchor(TOPLEFT, self.control, TOPLEFT, CONTENT_LEFT, y)
    self.context:SetAnchor(TOPRIGHT, self.totalTime, TOPLEFT, -8, 0)
    self.totalTime:ClearAnchors()
    self.totalTime:SetDimensions(92, 22)
    self.totalTime:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, CONTENT_RIGHT, y)
    y = y + layout.afterContext

    self.progress:ClearAnchors()
    self.progress:SetAnchor(TOPLEFT, self.control, TOPLEFT, CONTENT_LEFT, y)
    self.progress:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, CONTENT_RIGHT, y)
    y = y + layout.afterProgress

    self.stage:ClearAnchors()
    self.stage:SetAnchor(TOPLEFT, self.control, TOPLEFT, CONTENT_LEFT, y)
    self.stage:SetAnchor(TOPRIGHT, self.stageTime, TOPLEFT, -8, 0)
    self.stageTime:ClearAnchors()
    self.stageTime:SetDimensions(92, 22)
    self.stageTime:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, CONTENT_RIGHT, y)
    y = y + layout.afterStage

    local alert = model.alert
    self.alert:ClearAnchors()
    if alert and tostring(alert.text or "") ~= "" then
        self.alert:SetHidden(false)
        self.alertText:SetText(tostring(alert.text))
        self.alert:SetWidth(self.width - 32)
        local alertHeight = math.max(34, (tonumber(self.alertText:GetTextHeight()) or 20) + 12)
        self.alert:SetHeight(alertHeight)
        self.alert:SetAnchor(TOPLEFT, self.control, TOPLEFT, CONTENT_LEFT, y)
        self.alert:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, CONTENT_RIGHT, y)
        local alertColor = GetColor(alert.tone, "warning")
        self.alertBackdrop:SetCenterColor(alertColor[1] * 0.10, alertColor[2] * 0.10, alertColor[3] * 0.10, 0.90)
        self.alertBackdrop:SetEdgeColor(alertColor[1], alertColor[2], alertColor[3], 0.90)
        y = y + alertHeight + layout.alertGap
    else
        self.alert:SetHidden(true)
        self.alert:SetHeight(0)
    end

    local metricsHeight = self:RenderMetrics(model.metrics)
    self.metricsControl:ClearAnchors()
    if metricsHeight > 0 then
        self.metricsControl:SetAnchor(TOPLEFT, self.control, TOPLEFT, CONTENT_LEFT, y)
        self.metricsControl:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, CONTENT_RIGHT, y)
        y = y + metricsHeight + layout.metricsGap
    end

    local rowsHeight = self:RenderRows(rows)
    self.rowsTitle:ClearAnchors()
    self.rowsControl:ClearAnchors()
    if #rows > 0 then
        self.rowsTitle:SetHidden(false)
        self.rowsTitle:SetText(tostring(model.rowsTitle or ""))
        self.rowsTitle:SetAnchor(TOPLEFT, self.control, TOPLEFT, CONTENT_LEFT, y)
        self.rowsTitle:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, CONTENT_RIGHT, y)
        y = y + layout.rowsTitleHeight
        self.rowsControl:SetAnchor(TOPLEFT, self.control, TOPLEFT, CONTENT_LEFT, y)
        self.rowsControl:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, CONTENT_RIGHT, y)
        y = y + rowsHeight
    else
        self.rowsTitle:SetHidden(true)
    end

    self.actions = model.actions or self.actions or {}
    local actionsHeight = self:RenderActions()
    self.actionsControl:ClearAnchors()
    if actionsHeight > 0 then
        y = y + 10
        self.actionsControl:SetAnchor(TOPLEFT, self.control, TOPLEFT, CONTENT_LEFT, y)
        self.actionsControl:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, CONTENT_RIGHT, y)
        y = y + actionsHeight
    end

    y = y + layout.bottom
    self.control:SetDimensions(self.width, math.max(PANEL_MIN_HEIGHT, math.min(PANEL_MAX_HEIGHT, y)))
    self:RefreshKeybinds()
end

function Panel:SetModel(model)
    self.model = model or {}
    local modelWidth = tonumber(self.model.width)
    if modelWidth and modelWidth > 0 then
        self.width = modelWidth
    end
    self.actions = self.model.actions or {}
    if #self.actions == 0 and self.interactionActive then
        self.interactionActive = false
        self:RefreshMouseState()
    end
    self:Render()
end

function Panel:SetHidden(hidden)
    hidden = hidden == true
    self.requestedHidden = hidden
    if hidden then
        self:RemoveKeybinds()
        self.interactionActive = false
        self:RefreshMouseState()
    end
    self.control:SetHidden(hidden)
    if not hidden then
        self:RefreshKeybinds()
    end
end

function Panel:IsHidden()
    return self.control:IsHidden()
end

function Panel:GetControl()
    return self.control
end

function MOD.Create(id, options)
    if not WINDOW_MANAGER
        or type(CreateControlFromVirtual) ~= "function"
        or not ZO_ControlPool then
        return nil
    end
    id = tostring(id or "Default"):gsub("[^%w_]", "")
    if panels[id] then
        return panels[id]
    end
    options = options or {}
    local control = CreateControlFromVirtual("EZOToolsStatusPanel" .. id, GuiRoot, "EZOToolsStatusPanelTemplate")
    local self = setmetatable({
        id = id,
        control = control,
        width = tonumber(options.width) or PANEL_WIDTH,
        movable = false,
        interactionActive = false,
        actions = {},
        requestedHidden = true,
    }, Panel)

    self.title = control:GetNamedChild("Title")
    self.phase = control:GetNamedChild("Phase")
    self.context = control:GetNamedChild("Context")
    self.totalTime = control:GetNamedChild("TotalTime")
    self.progress = control:GetNamedChild("Progress")
    self.progressValueBackdrop = control:GetNamedChild("ProgressValueBackdrop")
    self.progressValue = control:GetNamedChild("ProgressValue")
    self.progressValueBackdrop:SetDrawLayer(DL_OVERLAY)
    self.progressValueBackdrop:SetDrawLevel(10)
    self.progressValue:SetDrawLayer(DL_OVERLAY)
    self.progressValue:SetDrawLevel(11)
    self.stage = control:GetNamedChild("Stage")
    self.stageTime = control:GetNamedChild("StageTime")
    self.alert = control:GetNamedChild("Alert")
    self.alertBackdrop = self.alert:GetNamedChild("Backdrop")
    self.alertText = self.alert:GetNamedChild("Text")
    self.metricsControl = control:GetNamedChild("Metrics")
    self.metricControls = {
        self.metricsControl:GetNamedChild("1"),
        self.metricsControl:GetNamedChild("2"),
        self.metricsControl:GetNamedChild("3"),
        self.metricsControl:GetNamedChild("4"),
    }
    self.rowsTitle = control:GetNamedChild("RowsTitle")
    self.rowsControl = control:GetNamedChild("Rows")
    self.actionsControl = control:GetNamedChild("Actions")
    self.rowPool = ZO_ControlPool:New("EZOToolsStatusPanelRowTemplate", self.rowsControl, id .. "Row")
    self.actionPool = ZO_ControlPool:New("EZOToolsStatusPanelActionTemplate", self.actionsControl, id .. "Action")

    control:SetDimensions(self.width, PANEL_MIN_HEIGHT)
    control:SetHandler("OnMoveStop", function()
        if self.onMoveStop then
            local left, top = self:GetPosition()
            SafeInvoke(self.onMoveStop, left, top, self)
        end
    end)
    self:SetPosition(options.x, options.y)
    self:SetMovable(options.movable)
    self:ApplyPlatformStyle()

    if ZO_SimpleSceneFragment and HUD_SCENE and HUD_UI_SCENE then
        self.sceneFragment = ZO_SimpleSceneFragment:New(control)
        self.sceneFragment:RegisterCallback("StateChange", function(_, newState)
            if newState == SCENE_FRAGMENT_SHOWING or newState == SCENE_FRAGMENT_SHOWN then
                control:SetHidden(self.requestedHidden == true)
            end
        end)
        HUD_SCENE:AddFragment(self.sceneFragment)
        HUD_UI_SCENE:AddFragment(self.sceneFragment)
    end

    panels[id] = self
    RegisterPlatformEvent()
    return self
end

MOD.COLORS = COLORS
MOD.ICONS = ICONS
