-- Herramientas experimentales para lider de grupo/raid.
-- Centraliza capturas de grupo, estado de instancia y acciones preparatorias.
EZOTools = EZOTools or {}

local EZO = EZOTools
EZO.RaidLeaderTools = EZO.RaidLeaderTools or {}
local MOD = EZO.RaidLeaderTools
local CONFIRM_DIALOG_NAME = "EZOTOOLS_CONFIRM_RAID_LEADER_ACTION"
local confirmDialogRegistered = false
local confirmDialogSupportsGamepad = false
local pendingConfirmData = nil
local pendingConfirmCallback = nil
local confirmationOpen = false
local confirmationVisible = false
local confirmationSequence = 0
local pendingConfirmId = nil
local pendingConfirmAction = nil

local function Print(message)
    if EZO and type(EZO.Print) == "function" then
        EZO.Print(message)
    elseif type(d) == "function" then
        d(tostring(message))
    end
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

local function EmitAutomaticGroupStatus(actionKey)
    local status = EZO and EZO.RaidLeaderStatus
    if status and type(status.EmitForAction) == "function" then
        SafeCall(status.EmitForAction, actionKey)
    end
end

local function ShouldConfirmDangerousActions()
    local settings = EZO.sv and EZO.sv.raidLeaderReset
    if type(settings) ~= "table" then
        return true
    end
    return settings.confirmDangerousActions ~= false
end

local function IsGamepadPreferred()
    if type(EZOTools_EsModoGamepadPreferido) == "function" then
        return EZOTools_EsModoGamepadPreferido() == true
    end
    if type(IsInGamepadPreferredMode) == "function" then
        return IsInGamepadPreferredMode() == true
    end
    if type(IsInGamepadMode) == "function" then
        return IsInGamepadMode() == true
    end
    return false
end

local function EmitConfirmationDiagnostic(stage, inputMode, title, actionKey, actionId, result)
    if not (EZO and type(EZO.IsDebugModeEnabled) == "function" and EZO.IsDebugModeEnabled()) then
        return
    end
    if not (EZO.Debug and type(EZO.Debug.EmitReport) == "function") then
        return
    end
    EZO.Debug.EmitReport(GetString(EZO_DEBUG_GROUP_ACTIVITIES_TITLE), {
        "=== EZOTools raid action confirmation ===",
        "stage=" .. tostring(stage or ""),
        "action=" .. tostring(actionKey or ""),
        "actionId=" .. tostring(actionId or ""),
        "inputMode=" .. tostring(inputMode or ""),
        "title=" .. tostring(title or ""),
        "result=" .. tostring(result or ""),
        "================================",
    })
end

local function EmitRaidActionDiagnostic(actionKey, phase, result, detail)
    if not (EZO and type(EZO.IsDebugModeEnabled) == "function" and EZO.IsDebugModeEnabled()) then
        return
    end
    if not (EZO.Debug and type(EZO.Debug.EmitReport) == "function") then
        return
    end
    EZO.Debug.EmitReport(GetString(EZO_DEBUG_GROUP_ACTIVITIES_TITLE), {
        "=== EZOTools raid action result ===",
        "action=" .. tostring(actionKey or ""),
        "phase=" .. tostring(phase or ""),
        "result=" .. tostring(result or ""),
        "detail=" .. tostring(detail or ""),
        "================================",
    })
end

local function RunConfirmedAction(callback, inputMode, title, actionKey, actionId)
    if type(callback) ~= "function" then
        EmitConfirmationDiagnostic("callback-missing", inputMode, title, actionKey, actionId, "failed")
        return
    end

    local function Run()
        EmitConfirmationDiagnostic("executing", inputMode, title, actionKey, actionId, "started")
        local ok, result = SafeCall(callback)
        if not ok then
            EmitConfirmationDiagnostic("callback-error", inputMode, title, actionKey, actionId, result)
            Print(zo_strformat(GetString(EZO_MSG_MENU_CALLBACK_FAILED), tostring(result or "error")))
            return
        end
        EmitConfirmationDiagnostic("callback-complete", inputMode, title, actionKey, actionId, "returned")
    end

    if type(zo_callLater) == "function" then
        zo_callLater(Run, 50)
    else
        Run()
    end
end

local function ClearPendingConfirmation()
    pendingConfirmData = nil
    pendingConfirmCallback = nil
    confirmationOpen = false
    confirmationVisible = false
    pendingConfirmId = nil
    pendingConfirmAction = nil
end

local function FindConfirmationDialog()
    if type(EZOTools_BuscarDialogoGamepad) == "function" then
        return EZOTools_BuscarDialogoGamepad(CONFIRM_DIALOG_NAME)
    end
    if type(ZO_Dialogs_FindDialog) == "function" then
        return ZO_Dialogs_FindDialog(CONFIRM_DIALOG_NAME)
    end
    return nil
end

local function CheckConfirmationVisibility(data, inputMode)
    if type(data) ~= "table" or pendingConfirmId ~= data.actionId or not confirmationOpen then
        return
    end
    local found = confirmationVisible or FindConfirmationDialog() ~= nil
    EmitConfirmationDiagnostic(
        "visibility-check",
        inputMode,
        data.title,
        data.actionKey,
        data.actionId,
        found and "visible" or "not-found"
    )
    if not found then
        ClearPendingConfirmation()
        Print(GetString(EZO_MSG_RAID_ACTION_CONFIRM_UNAVAILABLE))
    end
end

local function ResolveConfirmationData(dialog)
    local data = dialog and dialog.data or nil
    if type(data) == "table" and data.actionId ~= nil then
        return data
    end
    if type(pendingConfirmData) == "table" then
        return pendingConfirmData
    end
    return type(data) == "table" and data or {}
end

local function EnsureConfirmDialog()
    if confirmDialogRegistered then
        return true
    end
    if type(ZO_Dialogs_RegisterCustomDialog) ~= "function" then
        return false
    end

    local dialogInfo = {
        canQueue = true,
        OnShownCallback = function(dialog)
            local data = ResolveConfirmationData(dialog)
            confirmationVisible = true
            EmitConfirmationDiagnostic(
                "visible",
                IsGamepadPreferred() and "gamepad" or "keyboard",
                data.title,
                data.actionKey or pendingConfirmAction,
                data.actionId or pendingConfirmId,
                "shown"
            )
        end,
        title = {
            text = function(dialog)
                local data = ResolveConfirmationData(dialog)
                return tostring(data.title or GetString(EZO_CONFIRM_RAID_ACTION_TITLE))
            end,
        },
        mainText = {
            text = function(dialog)
                local data = ResolveConfirmationData(dialog)
                return tostring(data.body or "")
            end,
        },
        buttons = {
            [1] = {
                keybind = "DIALOG_PRIMARY",
                text = function(dialog)
                    local data = ResolveConfirmationData(dialog)
                    return tostring(data.confirmText or GetString(EZO_CONFIRM_RAID_ACTION_CONFIRM))
                end,
                callback = function(dialog)
                    local data = ResolveConfirmationData(dialog)
                    local callback = pendingConfirmCallback
                    local inputMode = IsGamepadPreferred() and "gamepad" or "keyboard"
                    local actionKey = data.actionKey or pendingConfirmAction
                    local actionId = data.actionId or pendingConfirmId
                    local title = data.title
                    ClearPendingConfirmation()
                    EmitConfirmationDiagnostic("confirmed", inputMode, title, actionKey, actionId, "accepted")
                    RunConfirmedAction(callback, inputMode, title, actionKey, actionId)
                end,
            },
            [2] = {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
                callback = function(dialog)
                    local data = ResolveConfirmationData(dialog)
                    EmitConfirmationDiagnostic(
                        "cancelled",
                        IsGamepadPreferred() and "gamepad" or "keyboard",
                        data.title,
                        data.actionKey or pendingConfirmAction,
                        data.actionId or pendingConfirmId,
                        "cancelled"
                    )
                    ClearPendingConfirmation()
                end,
            },
        },
        noChoiceCallback = function(dialog)
            local data = ResolveConfirmationData(dialog)
            if pendingConfirmId ~= data.actionId then
                return
            end
            EmitConfirmationDiagnostic(
                "cancelled",
                IsGamepadPreferred() and "gamepad" or "keyboard",
                data.title,
                data.actionKey or pendingConfirmAction,
                data.actionId or pendingConfirmId,
                "cancelled"
            )
            ClearPendingConfirmation()
        end,
    }
    if type(GAMEPAD_DIALOGS) == "table" and GAMEPAD_DIALOGS.BASIC ~= nil then
        dialogInfo.gamepadInfo = { dialogType = GAMEPAD_DIALOGS.BASIC }
        confirmDialogSupportsGamepad = true
    end
    ZO_Dialogs_RegisterCustomDialog(CONFIRM_DIALOG_NAME, dialogInfo)
    confirmDialogRegistered = true
    return true
end

local function ShowGamepadConfirmDialog(data)
    if not EnsureConfirmDialog()
        or not confirmDialogSupportsGamepad
        or type(ZO_Dialogs_ShowGamepadDialog) ~= "function" then
        return false
    end
    pendingConfirmData = data
    local ok = SafeCall(ZO_Dialogs_ShowGamepadDialog, CONFIRM_DIALOG_NAME, data)
    if not ok then
        pendingConfirmData = nil
    else
        confirmationOpen = true
    end
    return ok == true
end

function MOD.ConfirmDangerousAction(title, body, confirmText, onConfirm, actionKey)
    if type(onConfirm) ~= "function" then
        return false
    end
    if confirmationOpen then
        EmitConfirmationDiagnostic(
            "already-open",
            IsGamepadPreferred() and "gamepad" or "keyboard",
            title,
            actionKey,
            pendingConfirmId,
            "rejected"
        )
        Print(GetString(EZO_MSG_RAID_ACTION_CONFIRM_ALREADY_OPEN))
        return false
    end
    confirmationSequence = confirmationSequence + 1
    local actionId = confirmationSequence
    actionKey = tostring(actionKey or "raid-action")
    EmitConfirmationDiagnostic(
        "requested",
        IsGamepadPreferred() and "gamepad" or "keyboard",
        title,
        actionKey,
        actionId,
        "pending"
    )
    if not ShouldConfirmDangerousActions() then
        ClearPendingConfirmation()
        EmitConfirmationDiagnostic("confirmation-disabled", "direct", title, actionKey, actionId, "executing")
        RunConfirmedAction(onConfirm, "direct", title, actionKey, actionId)
        return false
    end
    local data = {
        title = title,
        body = body,
        confirmText = confirmText,
        actionKey = actionKey,
        actionId = actionId,
    }
    pendingConfirmData = data
    pendingConfirmCallback = onConfirm
    pendingConfirmId = actionId
    pendingConfirmAction = actionKey
    confirmationVisible = false

    if IsGamepadPreferred() and ShowGamepadConfirmDialog(data) then
        EmitConfirmationDiagnostic("show-requested", "gamepad", title, actionKey, actionId, "queued")
        if type(zo_callLater) == "function" then
            zo_callLater(function() CheckConfirmationVisibility(data, "gamepad") end, 1000)
        end
        return false
    end

    if not EnsureConfirmDialog() or type(ZO_Dialogs_ShowDialog) ~= "function" then
        ClearPendingConfirmation()
        EmitConfirmationDiagnostic("unavailable", "keyboard", title, actionKey, actionId, "failed")
        Print(GetString(EZO_MSG_RAID_ACTION_CONFIRM_UNAVAILABLE))
        return false
    end
    local ok = SafeCall(ZO_Dialogs_ShowDialog, CONFIRM_DIALOG_NAME, data)
    if not ok then
        ClearPendingConfirmation()
        EmitConfirmationDiagnostic("unavailable", "keyboard", title, actionKey, actionId, "failed")
        Print(GetString(EZO_MSG_RAID_ACTION_CONFIRM_UNAVAILABLE))
        return false
    end
    confirmationOpen = true
    EmitConfirmationDiagnostic("show-requested", "keyboard", title, actionKey, actionId, "queued")
    if type(zo_callLater) == "function" then
        zo_callLater(function() CheckConfirmationVisibility(data, "keyboard") end, 1000)
    end
    return false
end

function MOD.IsPlayerGroupLeader()
    return type(IsUnitGrouped) == "function"
        and type(IsUnitGroupLeader) == "function"
        and IsUnitGrouped("player")
        and IsUnitGroupLeader("player")
end

local function GetEffectiveDungeonDifficulty()
    if type(ZO_GetEffectiveDungeonDifficulty) == "function" then
        local ok, difficulty = SafeCall(ZO_GetEffectiveDungeonDifficulty)
        if ok then
            return difficulty
        end
    end

    if type(IsUnitGrouped) == "function"
        and IsUnitGrouped("player")
        and type(IsGroupUsingVeteranDifficulty) == "function" then
        return IsGroupUsingVeteranDifficulty()
            and DUNGEON_DIFFICULTY_VETERAN
            or DUNGEON_DIFFICULTY_NORMAL
    end

    if type(IsUnitUsingVeteranDifficulty) == "function" then
        return IsUnitUsingVeteranDifficulty("player")
            and DUNGEON_DIFFICULTY_VETERAN
            or DUNGEON_DIFFICULTY_NORMAL
    end

    return nil
end

local function GetDungeonDifficultyName(difficulty)
    if type(GetString) == "function" and difficulty ~= nil then
        return GetString("SI_DUNGEONDIFFICULTY", difficulty)
    end
    return tostring(difficulty or "")
end

local function YesNo(value)
    return value and "yes" or "no"
end

local function EmitTrialTravelDiagnostic(trial, nodeIndex, nodeName, targetDifficulty, difficultyReady, difficultyChanged, blockedReason, stage, okTravel)
    if not (EZO and EZO.Debug and type(EZO.Debug.EmitReport) == "function") then
        return
    end

    local difficulty = GetEffectiveDungeonDifficulty()
    local lines = {
        "=== EZOTools trial travel ===",
        "stage=" .. tostring(stage or ""),
        "trial.key=" .. tostring(trial and trial.key or ""),
        "trial.name=" .. tostring(trial and trial.name or ""),
        "node.index=" .. tostring(nodeIndex or ""),
        "node.name=" .. tostring(nodeName or ""),
        "difficulty.target=" .. tostring(targetDifficulty or ""),
        "difficulty.targetName=" .. tostring(GetDungeonDifficultyName(targetDifficulty)),
        "difficulty.current=" .. tostring(difficulty or ""),
        "difficulty.currentName=" .. tostring(GetDungeonDifficultyName(difficulty)),
        "difficulty.ready=" .. YesNo(difficultyReady),
        "difficulty.changed=" .. YesNo(difficultyChanged),
        "difficulty.blockedReason=" .. tostring(blockedReason or ""),
        "travel.ok=" .. tostring(okTravel),
        "================================",
    }
    EZO.Debug.EmitReport(GetString(EZO_DEBUG_TRIAL_TRAVEL_TITLE), lines, { level = "info" })
end

local function GetDifficultyChangeState()
    if type(CanPlayerChangeGroupDifficulty) ~= "function" then
        return false, nil
    end
    local ok, canChange, reason = SafeCall(CanPlayerChangeGroupDifficulty)
    if ok then
        return canChange == true, reason
    end
    return false, nil
end

local function IsPlayerInInstance()
    local ok, value = SafeCall(IsInInstance)
    if ok then
        return value == true
    end

    ok, value = SafeCall(IsUnitInDungeon, "player")
    if ok then
        return value == true
    end

    return false
end

local function EnsureRaidLeaderSavedVariables()
    EZO.sv = EZO.sv or {}
    EZO.sv.raidLeaderTools = EZO.sv.raidLeaderTools or {}
    return EZO.sv.raidLeaderTools
end

local function GetCatalog()
    return EZO and EZO.RaidLeaderActivityCatalog
end

local function GetTrialDefinitions()
    local catalog = GetCatalog()
    if catalog and type(catalog.GetTrialDefinitions) == "function" then
        local ok, trials = SafeCall(catalog.GetTrialDefinitions)
        if ok and type(trials) == "table" then
            return trials
        end
    end
    return {}
end

local function NormalizeNodeName(value)
    value = tostring(value or "")
    value = value:gsub("’", "'"):gsub("`", "'"):gsub("´", "'")
    value = string.lower(value)
    value = value:gsub("[^%w]+", "")
    return value
end

local function IsKnownFastTravelNode(known)
    return known == true or known == 1
end

local function NodeMatchesTrial(nodeName, trial)
    local normalizedNode = NormalizeNodeName(nodeName)
    if normalizedNode == "" or type(trial) ~= "table" then
        return false
    end

    local aliases = trial.aliases or {}
    for _, alias in ipairs(aliases) do
        local normalizedAlias = NormalizeNodeName(alias)
        if normalizedAlias ~= ""
            and (normalizedNode == normalizedAlias
                or string.find(normalizedNode, normalizedAlias, 1, true) ~= nil) then
            return true
        end
    end
    return false
end

local function FindFastTravelNodeForTrial(trial)
    if type(GetNumFastTravelNodes) ~= "function"
        or type(GetFastTravelNodeInfo) ~= "function" then
        return nil, nil
    end

    local configuredNodeIndex = tonumber(trial and trial.fastTravelNodeId)
    if configuredNodeIndex then
        local okNode, known, nodeName = SafeCall(GetFastTravelNodeInfo, configuredNodeIndex)
        if okNode and IsKnownFastTravelNode(known) then
            return configuredNodeIndex, tostring(nodeName or trial.name)
        end
    end

    local okCount, count = SafeCall(GetNumFastTravelNodes)
    count = okCount and tonumber(count) or 0
    for nodeIndex = 1, count do
        local okNode, known, nodeName = SafeCall(GetFastTravelNodeInfo, nodeIndex)
        if okNode and IsKnownFastTravelNode(known) and NodeMatchesTrial(nodeName, trial) then
            return nodeIndex, tostring(nodeName or trial.name)
        end
    end
    return nil, nil
end

local function GetGroupDifficultyChangeReasonText(reason)
    if reason ~= nil and type(GetString) == "function" then
        local reasonText = GetString("SI_GROUPDIFFICULTYCHANGEREASON", reason)
        if reasonText and reasonText ~= "" then
            return reasonText
        end
    end
    return nil
end

local function TrySetDungeonDifficulty(targetDifficulty)
    if type(SetVeteranDifficulty) ~= "function" then
        return false, false, nil
    end

    if targetDifficulty ~= DUNGEON_DIFFICULTY_NORMAL
        and targetDifficulty ~= DUNGEON_DIFFICULTY_VETERAN then
        return false, false, nil
    end

    local current = GetEffectiveDungeonDifficulty()
    if current == targetDifficulty then
        return true, false, nil
    end

    local canChange, reason = GetDifficultyChangeState()
    if canChange then
        local okSet = SafeCall(SetVeteranDifficulty, targetDifficulty == DUNGEON_DIFFICULTY_VETERAN)
        if okSet then
            return true, true, nil
        end
    end

    return false, false, GetGroupDifficultyChangeReasonText(reason)
end

local function GetTrialByKey(trialKey)
    local catalog = GetCatalog()
    if catalog and type(catalog.GetTrialByKey) == "function" then
        local ok, trial = SafeCall(catalog.GetTrialByKey, trialKey)
        if ok and type(trial) == "table" then
            return trial
        end
    end
    return nil
end

local function TravelToTrialInternal(trialKey, targetDifficulty, onResult)
    local function NotifyTravelResult(success, reason)
        if type(onResult) == "function" then
            SafeCall(onResult, success == true, reason)
        end
    end

    local trial = GetTrialByKey(trialKey)
    if not trial then
        NotifyTravelResult(false, "trial-missing")
        return false
    end

    local difficultyReady, difficultyChanged, blockedReason = true, false, nil
    if targetDifficulty ~= nil then
        difficultyReady, difficultyChanged, blockedReason = TrySetDungeonDifficulty(targetDifficulty)
        if not difficultyReady then
            local difficultyName = GetDungeonDifficultyName(targetDifficulty)
            if blockedReason and blockedReason ~= "" then
                Print(zo_strformat(GetString(EZO_MSG_TRIAL_TRAVEL_DIFFICULTY_BLOCKED_REASON), difficultyName, blockedReason))
            else
                Print(zo_strformat(GetString(EZO_MSG_TRIAL_TRAVEL_DIFFICULTY_BLOCKED), difficultyName))
            end
            EmitTrialTravelDiagnostic(trial, nil, nil, targetDifficulty, false, false, blockedReason, "difficulty-blocked", false)
            NotifyTravelResult(false, "difficulty-blocked")
            return false
        end
    end

    if type(FastTravelToNode) ~= "function" then
        Print(GetString(EZO_MSG_TRIAL_TRAVEL_UNAVAILABLE))
        EmitTrialTravelDiagnostic(trial, nil, nil, targetDifficulty, difficultyReady, difficultyChanged, blockedReason, "fast-travel-unavailable", false)
        NotifyTravelResult(false, "fast-travel-unavailable")
        return false
    end

    local nodeIndex, nodeName = FindFastTravelNodeForTrial(trial)
    if not nodeIndex then
        Print(zo_strformat(GetString(EZO_MSG_TRIAL_TRAVEL_NODE_MISSING), trial.name))
        EmitTrialTravelDiagnostic(trial, nil, nodeName, targetDifficulty, difficultyReady, difficultyChanged, blockedReason, "node-missing", false)
        NotifyTravelResult(false, "node-missing")
        return false
    end

    local difficultyCheckAttempts = 0
    local function DoTravel()
        if targetDifficulty ~= nil and GetEffectiveDungeonDifficulty() ~= targetDifficulty then
            difficultyCheckAttempts = difficultyCheckAttempts + 1
            if difficultyChanged
                and type(zo_callLater) == "function"
                and difficultyCheckAttempts < 10 then
                zo_callLater(DoTravel, 200)
                return
            end
            local difficultyName = GetDungeonDifficultyName(targetDifficulty)
            Print(zo_strformat(GetString(EZO_MSG_TRIAL_TRAVEL_DIFFICULTY_BLOCKED), difficultyName))
            EmitTrialTravelDiagnostic(trial, nodeIndex, nodeName, targetDifficulty, false, difficultyChanged, "not-confirmed", "difficulty-not-confirmed", false)
            NotifyTravelResult(false, "difficulty-not-confirmed")
            return
        end

        local sv = EnsureRaidLeaderSavedVariables()
        sv.lastTrialKey = trial.key

        Print(zo_strformat(GetString(EZO_MSG_TRIAL_TRAVEL_START), trial.name))
        local okTravel = SafeCall(FastTravelToNode, nodeIndex)
        if not okTravel then
            Print(GetString(EZO_MSG_TRIAL_TRAVEL_UNAVAILABLE))
        end
        EmitTrialTravelDiagnostic(trial, nodeIndex, nodeName, targetDifficulty, difficultyReady, difficultyChanged, blockedReason, "travel-called", okTravel)
        NotifyTravelResult(okTravel, okTravel and "requested" or "call-failed")
    end

    if difficultyChanged and type(zo_callLater) == "function" then
        zo_callLater(DoTravel, 200)
    else
        DoTravel()
    end
    return false
end

function MOD.GetTrialDefinitions()
    return GetTrialDefinitions()
end

function MOD.GetLastTrialKey()
    local sv = EZO.sv and EZO.sv.raidLeaderTools
    return sv and sv.lastTrialKey or nil
end

function MOD.GetTrialName(trialKey)
    local trial = GetTrialByKey(trialKey)
    return trial and trial.name or ""
end

function MOD.GetLastTrialMenuText()
    local trial = GetTrialByKey(MOD.GetLastTrialKey())
    if not trial then
        return GetString(EZO_MENU_TRIAL_TRAVEL_LAST_NONE)
    end
    return zo_strformat(GetString(EZO_MENU_TRIAL_TRAVEL_LAST), trial.name)
end

function MOD.TravelToTrial(trialKey)
    EmitAutomaticGroupStatus("trial-travel:" .. tostring(trialKey or ""))
    return TravelToTrialInternal(trialKey, DUNGEON_DIFFICULTY_VETERAN)
end

function MOD.TravelToTrialWithDifficulty(trialKey, targetDifficulty, onResult)
    return TravelToTrialInternal(trialKey, targetDifficulty, onResult)
end

function MOD.TravelToLastTrial()
    local lastTrialKey = MOD.GetLastTrialKey()
    if not GetTrialByKey(lastTrialKey) then
        Print(GetString(EZO_MSG_TRIAL_TRAVEL_LAST_NONE))
        return false
    end
    return MOD.TravelToTrial(lastTrialKey)
end

function MOD.BuildTrialTravelEntries()
    local entries = {}
    entries[#entries + 1] = {
        text = MOD.GetLastTrialMenuText,
        callback = function() return MOD.TravelToLastTrial() end,
    }
    for _, trial in ipairs(GetTrialDefinitions()) do
        local trialKey = trial.key
        local trialName = trial.name
        entries[#entries + 1] = {
            text = trialName,
            callback = function() return MOD.TravelToTrial(trialKey) end,
        }
    end
    return entries
end

function MOD.CanShowDungeonDifficultyOption()
    if type(SetVeteranDifficulty) ~= "function" then
        return false
    end
    return MOD.IsPlayerGroupLeader() and not IsPlayerInInstance()
end

function MOD.CanDisbandGroup()
    if type(GroupDisband) ~= "function" or not MOD.IsPlayerGroupLeader() then
        return false
    end
    if type(DoesGroupModificationRequireVote) == "function" then
        local ok, requiresVote = SafeCall(DoesGroupModificationRequireVote)
        if ok and requiresVote == true then
            return false
        end
    end
    return true
end

function MOD.DisbandGroup()
    if not MOD.CanDisbandGroup() then
        Print(GetString(EZO_MSG_GROUP_DISBAND_UNAVAILABLE))
        return false
    end

    EmitAutomaticGroupStatus("disband-group")
    return MOD.ConfirmDangerousAction(
        GetString(EZO_CONFIRM_DISBAND_GROUP_TITLE),
        GetString(EZO_CONFIRM_DISBAND_GROUP_TEXT),
        GetString(EZO_CONFIRM_DISBAND_GROUP_CONFIRM),
        MOD.DisbandGroupConfirmed,
        "disband-group"
    )
end

function MOD.DisbandGroupConfirmed()
    if not MOD.CanDisbandGroup() then
        EmitRaidActionDiagnostic("disband-group", "precondition", "rejected", "unavailable")
        Print(GetString(EZO_MSG_GROUP_DISBAND_UNAVAILABLE))
        return false
    end

    local ok, err = SafeCall(GroupDisband)
    if not ok then
        EmitRaidActionDiagnostic("disband-group", "request", "failed", err)
        Print(GetString(EZO_MSG_GROUP_DISBAND_UNAVAILABLE))
        return false
    end

    EmitRaidActionDiagnostic("disband-group", "request", "sent", "GroupDisband")
    Print(GetString(EZO_MSG_GROUP_DISBAND_STARTED))

    local function VerifyDisband(attempt)
        local grouped = type(IsUnitGrouped) == "function" and IsUnitGrouped("player")
        if not grouped then
            EmitRaidActionDiagnostic("disband-group", "verification", "confirmed", attempt)
            Print(GetString(EZO_MSG_GROUP_DISBAND_CONFIRMED))
            local reset = EZO and EZO.RaidLeaderReset
            if reset and type(reset.HandleExternalDisbandConfirmed) == "function" then
                SafeCall(reset.HandleExternalDisbandConfirmed, "raid-leader-tools")
            end
            return
        end
        if attempt >= 8 or type(zo_callLater) ~= "function" then
            EmitRaidActionDiagnostic("disband-group", "verification", "not-confirmed", attempt)
            Print(GetString(EZO_MSG_GROUP_DISBAND_NOT_CONFIRMED))
            return
        end
        zo_callLater(function() VerifyDisband(attempt + 1) end, 500)
    end

    if type(zo_callLater) == "function" then
        zo_callLater(function() VerifyDisband(1) end, 500)
    else
        VerifyDisband(1)
    end
    return false
end

function MOD.CanChangeDungeonDifficulty()
    if type(SetVeteranDifficulty) ~= "function"
        or not MOD.IsPlayerGroupLeader()
        or IsPlayerInInstance() then
        return false
    end

    local canChange = GetDifficultyChangeState()
    return canChange == true
end

function MOD.GetNextDungeonDifficulty()
    local current = GetEffectiveDungeonDifficulty()
    if current == DUNGEON_DIFFICULTY_VETERAN then
        return DUNGEON_DIFFICULTY_NORMAL
    end
    if current == DUNGEON_DIFFICULTY_NORMAL then
        return DUNGEON_DIFFICULTY_VETERAN
    end
    return nil
end

function MOD.GetDungeonDifficultyMenuText()
    local nextDifficulty = MOD.GetNextDungeonDifficulty()
    if nextDifficulty == nil then
        return GetString(EZO_MENU_DUNGEON_DIFFICULTY)
    end
    return zo_strformat(GetString(EZO_MENU_DUNGEON_DIFFICULTY_TO),
        GetDungeonDifficultyName(nextDifficulty))
end

function MOD.ToggleDungeonDifficulty()
    local canChange, reason = GetDifficultyChangeState()
    if not MOD.IsPlayerGroupLeader()
        or type(SetVeteranDifficulty) ~= "function"
        or not canChange then
        if reason ~= nil and type(GetString) == "function" then
            local reasonText = GetString("SI_GROUPDIFFICULTYCHANGEREASON", reason)
            if reasonText and reasonText ~= "" then
                Print(zo_strformat(GetString(EZO_MSG_DUNGEON_DIFFICULTY_CANT_CHANGE_REASON), reasonText))
                return false
            end
        end
        Print(GetString(EZO_MSG_DUNGEON_DIFFICULTY_CANT_CHANGE))
        return false
    end

    local nextDifficulty = MOD.GetNextDungeonDifficulty()
    if nextDifficulty == nil then
        return false
    end

    EmitAutomaticGroupStatus("toggle-instance-difficulty")
    SetVeteranDifficulty(nextDifficulty == DUNGEON_DIFFICULTY_VETERAN)
    Print(zo_strformat(GetString(EZO_MSG_DUNGEON_DIFFICULTY_CHANGED),
        GetDungeonDifficultyName(nextDifficulty)))
    return true
end

function MOD.BuildGroupSnapshot()
    local snapshot = {
        isGrouped = false,
        isLeader = MOD.IsPlayerGroupLeader(),
        size = 0,
        members = {},
    }

    if type(IsUnitGrouped) ~= "function" or not IsUnitGrouped("player") then
        return snapshot
    end

    snapshot.isGrouped = true
    snapshot.size = (type(GetGroupSize) == "function" and GetGroupSize()) or 0

    if type(GetGroupUnitTagByIndex) ~= "function" then
        return snapshot
    end

    for i = 1, snapshot.size do
        local unitTag = GetGroupUnitTagByIndex(i)
        if unitTag and unitTag ~= "" then
            local displayName = ""
            if type(GetUnitDisplayName) == "function" then
                local okName, name = SafeCall(GetUnitDisplayName, unitTag)
                if okName then displayName = tostring(name or "") end
            end

            local characterName = ""
            if type(GetUnitName) == "function" then
                local okChar, name = SafeCall(GetUnitName, unitTag)
                if okChar then characterName = tostring(name or "") end
            end

            local zoneIndex = nil
            local zoneName = ""
            if type(GetUnitZoneIndex) == "function" then
                local okZone, idx = SafeCall(GetUnitZoneIndex, unitTag)
                if okZone then zoneIndex = idx end
            end
            if zoneIndex and type(GetZoneNameByIndex) == "function" then
                local okZoneName, name = SafeCall(GetZoneNameByIndex, zoneIndex)
                if okZoneName then zoneName = tostring(name or "") end
            end

            snapshot.members[#snapshot.members + 1] = {
                unitTag = unitTag,
                displayName = displayName,
                characterName = characterName,
                zoneIndex = zoneIndex,
                zoneName = zoneName,
                isLeader = type(IsUnitGroupLeader) == "function" and IsUnitGroupLeader(unitTag) or false,
            }
        end
    end

    return snapshot
end

function MOD.GetCurrentGroupDisplayNameMap()
    local names = {}
    if type(IsUnitGrouped) ~= "function" or not IsUnitGrouped("player") then
        return names
    end
    if type(GetGroupSize) ~= "function" or type(GetGroupUnitTagByIndex) ~= "function" then
        return names
    end

    local okSize, groupSize = SafeCall(GetGroupSize)
    groupSize = okSize and tonumber(groupSize) or 0
    for index = 1, groupSize do
        local okTag, unitTag = SafeCall(GetGroupUnitTagByIndex, index)
        if okTag and unitTag and type(GetUnitDisplayName) == "function" then
            local okName, displayName = SafeCall(GetUnitDisplayName, unitTag)
            displayName = okName and tostring(displayName or "") or ""
            if displayName ~= "" then
                names[displayName] = unitTag
            end
        end
    end
    return names
end

function MOD.InviteDisplayNames(displayNames, options)
    if type(GroupInviteByName) ~= "function" or type(displayNames) ~= "table" then
        return false, 0, 0
    end

    options = type(options) == "table" and options or {}
    local currentNames = MOD.GetCurrentGroupDisplayNameMap()
    local playerName = type(GetDisplayName) == "function" and tostring(GetDisplayName() or "") or ""
    local seen = {}
    local invited = 0
    local errors = 0

    for _, rawName in ipairs(displayNames) do
        local displayName = tostring(rawName or "")
        local shouldInvite = displayName ~= ""
            and displayName ~= playerName
            and not currentNames[displayName]
            and not seen[displayName]
        if shouldInvite and type(options.shouldInvite) == "function" then
            local okFilter, accepted = SafeCall(options.shouldInvite, displayName)
            shouldInvite = okFilter and accepted ~= false
        end
        if shouldInvite then
            seen[displayName] = true
            local ok = SafeCall(GroupInviteByName, displayName)
            if ok then
                invited = invited + 1
            else
                errors = errors + 1
            end
            if type(options.onResult) == "function" then
                SafeCall(options.onResult, displayName, ok)
            end
        end
    end

    return true, invited, errors
end

function MOD.BuildInstanceSnapshot()
    local inInstance = false
    local ok, value = SafeCall(IsInInstance)
    if ok then
        inInstance = value == true
    else
        ok, value = SafeCall(IsUnitInDungeon, "player")
        if ok then inInstance = value == true end
    end

    local zoneIndex = nil
    if type(GetUnitZoneIndex) == "function" then
        local okZone, idx = SafeCall(GetUnitZoneIndex, "player")
        if okZone then zoneIndex = idx end
    end

    local zoneName = ""
    if zoneIndex and type(GetZoneNameByIndex) == "function" then
        local okName, name = SafeCall(GetZoneNameByIndex, zoneIndex)
        if okName then zoneName = tostring(name or "") end
    end

    local difficulty = GetEffectiveDungeonDifficulty()
    return {
        inInstance = inInstance,
        zoneIndex = zoneIndex,
        zoneName = zoneName,
        difficulty = difficulty,
        difficultyName = GetDungeonDifficultyName(difficulty),
        canChangeDifficulty = MOD.CanChangeDungeonDifficulty(),
    }
end

function MOD.BuildResetSnapshot()
    return {
        group = MOD.BuildGroupSnapshot(),
        instance = MOD.BuildInstanceSnapshot(),
        createdAtMs = type(GetFrameTimeMilliseconds) == "function"
            and GetFrameTimeMilliseconds()
            or nil,
    }
end

-- Compatibilidad temporal con las entradas actuales del menu HOLD X.
EZO.CanShowDungeonDifficultyOption = MOD.CanShowDungeonDifficultyOption
EZO.CanChangeDungeonDifficulty = MOD.CanChangeDungeonDifficulty
EZO.GetNextDungeonDifficulty = MOD.GetNextDungeonDifficulty
EZO.GetDungeonDifficultyMenuText = MOD.GetDungeonDifficultyMenuText
EZO.ToggleDungeonDifficulty = MOD.ToggleDungeonDifficulty
