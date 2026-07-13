-- Debug-only data provider for reviewing the reusable status panel layout.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.StatusPanelPreview = EZO.StatusPanelPreview or {}
local MOD = EZO.StatusPanelPreview

local DEFAULT_WIDTH = 520
local MIN_WIDTH = 420
local MAX_WIDTH = 620
local previewPanel

local PREVIEW_MEMBERS = {
    { name = "@AldmeriHealer", statusKey = "EZO_INSTANCE_RESET_MEMBER_STATUS_JOINED", requests = 1, tone = "success", iconType = "success" },
    { name = "@DragonknightTank", statusKey = "EZO_INSTANCE_RESET_MEMBER_STATUS_JOINED", requests = 1, tone = "success", iconType = "success" },
    { name = "@ClockworkWarden", statusKey = "EZO_INSTANCE_RESET_MEMBER_STATUS_JOINED", requests = 1, tone = "success", iconType = "success" },
    { name = "@NecromancerSupport", statusKey = "EZO_INSTANCE_RESET_MEMBER_STATUS_JOINED", requests = 1, tone = "success", iconType = "success" },
    { name = "@TemplarOfTheDawn", statusKey = "EZO_INSTANCE_RESET_MEMBER_STATUS_JOINED", requests = 1, tone = "success", iconType = "success" },
    { name = "@SorcererDamage", statusKey = "EZO_INSTANCE_RESET_MEMBER_STATUS_JOINED", requests = 1, tone = "success", iconType = "success" },
    { name = "@NightbladeDamage", statusKey = "EZO_INSTANCE_RESET_MEMBER_STATUS_JOINED", requests = 1, tone = "success", iconType = "success" },
    { name = "@ArcanistSupport", statusKey = "EZO_INSTANCE_RESET_MEMBER_STATUS_INVITED", requests = 1, tone = "info", iconType = "pending" },
    { name = "@LongAccountNameTest", statusKey = "EZO_INSTANCE_RESET_MEMBER_STATUS_INVITED", requests = 1, tone = "info", iconType = "pending" },
    { name = "@PendingMemberOne", statusKey = "EZO_INSTANCE_RESET_MEMBER_STATUS_PENDING", requests = 0, tone = "pending", iconType = "pending" },
    { name = "@PendingMemberTwo", statusKey = "EZO_INSTANCE_RESET_MEMBER_STATUS_PENDING", requests = 0, tone = "pending", iconType = "pending" },
}

local function Print(message)
    if type(EZO.Print) == "function" then
        EZO.Print(message)
    end
end

local function GetTrialName()
    local catalog = EZO.RaidLeaderActivityCatalog
    local trial = catalog and type(catalog.GetTrialByKey) == "function"
        and catalog.GetTrialByKey("aetherian_archive") or nil
    return trial and tostring(trial.name or "") or "Aetherian Archive"
end

local function BuildRows()
    local rows = {}
    for index, member in ipairs(PREVIEW_MEMBERS) do
        local location
        local locationTone
        local memberStatus = GetString(_G[member.statusKey])
        local status = memberStatus
        if member.statusKey == "EZO_INSTANCE_RESET_MEMBER_STATUS_JOINED" then
            if index <= 6 then
                location = GetString(EZO_INSTANCE_RESET_MEMBER_LOCATION_SAME)
                locationTone = "success"
            else
                location = GetString(EZO_INSTANCE_RESET_MEMBER_LOCATION_DIFFERENT)
                locationTone = "warning"
            end
        else
            status = zo_strformat(
                GetString(EZO_INSTANCE_RESET_STATUS_MEMBER_STATE_REQUESTS),
                memberStatus,
                member.requests
            )
        end
        rows[#rows + 1] = {
            id = member.name,
            name = member.name,
            status = status,
            tone = member.tone,
            iconType = member.iconType,
            location = location,
            locationTone = locationTone,
        }
    end
    return rows
end

local function EnsurePanel(width)
    if not previewPanel then
        local panelModule = EZO.StatusPanel
        if not panelModule or type(panelModule.Create) ~= "function" then
            return nil
        end
        previewPanel = panelModule.Create("ResetLayoutPreview", { width = width })
    end
    if previewPanel then
        previewPanel:SetWidth(width)
        previewPanel:SetMovable(true)
    end
    return previewPanel
end

function MOD.BuildModel()
    return {
        width = DEFAULT_WIDTH,
        density = "compact",
        title = GetTrialName(),
        phaseText = zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_PHASE_SHORT), 6, 6),
        contextText = zo_strformat(
            GetString(EZO_INSTANCE_RESET_STATUS_ACTIVITY),
            GetString(EZO_INSTANCE_RESET_STATUS_TITLE),
            GetString("SI_DUNGEONDIFFICULTY", DUNGEON_DIFFICULTY_VETERAN)
        ),
        totalTimeText = "03:03",
        progress = {
            min = 0,
            max = 6,
            value = 6,
            text = zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_PROGRESS), 6, 6),
        },
        statusText = GetString(EZO_INSTANCE_RESET_STAGE_INVITING),
        statusTimeText = "00:18",
        metrics = {
            { value = 11, label = GetString(EZO_INSTANCE_RESET_STATUS_METRIC_CAPTURED) },
            { value = 7, label = GetString(EZO_INSTANCE_RESET_STATUS_METRIC_IN_GROUP), tone = "success" },
            { value = 4, label = GetString(EZO_INSTANCE_RESET_STATUS_METRIC_PENDING), tone = "warning" },
            { value = 9, label = GetString(EZO_INSTANCE_RESET_STATUS_METRIC_INVITES), tone = "info" },
        },
        rowsTitle = zo_strformat(GetString(EZO_INSTANCE_RESET_STATUS_MEMBERS_COUNT), #PREVIEW_MEMBERS),
        rows = BuildRows(),
    }
end

local function Show(width)
    local panel = EnsurePanel(width)
    if not panel then
        Print(GetString(EZO_CMD_LAYOUT_NA))
        return false
    end
    panel:SetModel(MOD.BuildModel())
    panel:SetWidth(width)
    panel:SetHidden(false)
    local control = panel:GetControl()
    local left = math.max(0, (GuiRoot:GetWidth() - control:GetWidth()) / 2)
    local top = math.max(0, (GuiRoot:GetHeight() - control:GetHeight()) / 2)
    panel:SetPosition(left, top)
    Print(zo_strformat(GetString(EZO_DEBUG_RESET_PANEL_SHOWN), width))
    return true
end

function MOD.Hide(silent)
    local wasVisible = previewPanel and not previewPanel:IsHidden() or false
    if previewPanel then
        previewPanel:SetHidden(true)
    end
    if silent ~= true then
        Print(GetString(EZO_DEBUG_RESET_PANEL_HIDDEN))
    end
    return wasVisible
end

function MOD.Execute(argument)
    argument = zo_strlower(zo_strtrim(tostring(argument or "")))
    if argument == "off" then
        MOD.Hide(false)
        return true
    end
    if argument == "" and previewPanel and not previewPanel:IsHidden() then
        MOD.Hide(false)
        return true
    end
    local width = tonumber(argument) or DEFAULT_WIDTH
    width = math.max(MIN_WIDTH, math.min(MAX_WIDTH, math.floor(width)))
    return Show(width)
end
