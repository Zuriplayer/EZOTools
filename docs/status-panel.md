# Reusable status panel

`modules/status_panel.lua` and `modules/status_panel.xml` implement a generic HUD
status panel. The component does not know about groups, trials, travel, instance
reset, persistence, or consumer state machines.

## Creating a panel

```lua
local panel = EZOTools.StatusPanel.Create("Example", {
    width = 520,
    x = 100,
    y = 100,
    movable = false,
})
```

The identifier must be stable and unique within the addon. Reusing an identifier
returns the existing panel.

## Presentation model

```lua
panel:SetModel({
    width = 480,
    density = "comfortable",
    title = "Operation",
    phaseText = "PHASE 2/4",
    contextText = "Target · Veteran",
    totalTimeText = "01:24",
    progress = {
        min = 0,
        max = 4,
        value = 2,
        text = "2 / 4",
    },
    statusText = "Waiting for members",
    statusTimeText = "00:12",
    alert = {
        text = "Action required",
        tone = "warning",
    },
    metrics = {
        { value = 12, label = "Captured" },
        { value = 8, label = "In group", tone = "success" },
        { value = 4, label = "Pending", tone = "warning" },
    },
    rowsTitle = "MEMBERS (12)",
    rows = {
        {
            id = "@Account",
            name = "@Account",
            status = "in group",
            tone = "success",
            iconType = "success",
            location = "same instance as leader",
            locationTone = "success",
        },
    },
})
```

Supported tones are `success`, `info`, `pending`, `warning`, `error`, `muted`,
and `normal`. Consumers may also pass an RGBA table. Metrics are limited to four
columns. Rows use pooled controls and are not multiline strings.
`location` and `locationTone` are optional. The consumer remains responsible for
obtaining and interpreting location data. Every member is rendered inside one
fixed-height layout row: marker, name, primary status, and location occupy four
anchored regions with a shared vertical center. The name region absorbs changes
in panel width, while the two status regions remain stable and ellipsize long
text. This keeps all information for a member aligned without relying on font
baselines or a floating second line.

The reset consumer supplies location only for members confirmed in the current
group. Joined rows omit the historical invite count and show group state plus
same/different-instance information. Rows not currently grouped show their
workflow state and invitations sent, without an unreliable location value.

`density` may be `comfortable`, `standard`, or `compact`. If omitted, the panel
selects it from the row count: up to four rows use comfortable spacing, five to
seven use standard spacing, and eight or more use compact spacing. `width` is an
optional per-model width; EZOTools uses 480, 500, and 520 pixels for those same
roster ranges in keyboard mode, with 500 and 510 pixel minimums for small and
medium gamepad rosters. Status markers use the native bullet texture rather than
checkbox artwork because rows are informational and not clickable settings.

## Visibility and movement

```lua
panel:SetHidden(false)
panel:SetMovable(true)
panel:SetWidth(480)
panel:SetPosition(x, y)
panel:SetMoveStopCallback(function(left, top)
    -- The consumer owns persistence.
end)
```

The component owns only presentation state. The consumer decides when the panel
is visible and where its position is stored. `SetWidth` re-renders an existing
model without changing consumer state. The progress value is displayed in a
contrasting centered badge so it remains readable over both the filled and
unfilled parts of the native progress bar.

`SetHidden` stores the consumer-requested visibility separately from the native
HUD scene fragment. When the HUD fragment is shown again after a menu closes,
the requested hidden state is reapplied so a panel closed in settings cannot be
reopened by the scene transition.

The EZOTools reset-layout provider exposes `StatusPanelPreview.Hide(silent)` so
settings-driven placement mode can close the standalone debug preview before it
shows or restores the real consumer panel. This prevents two independent panel
instances from remaining visible at the same time.

## Optional interaction

Actions are optional. A panel remains purely informational until the consumer
explicitly enables interaction. The action area supports at most two visible
actions so it remains suitable for concise choices such as Yes/No.

```lua
panel:SetModel({
    title = "Confirm operation",
    actions = {
        {
            id = "accept",
            label = "Yes",
            keybind = "DIALOG_PRIMARY",
            gamepadKeybind = "DIALOG_PRIMARY",
            callback = function()
                -- Consumer action.
            end,
        },
        {
            id = "cancel",
            label = "No",
            keybind = "DIALOG_NEGATIVE",
            gamepadKeybind = "DIALOG_NEGATIVE",
            callback = function()
                -- Consumer action.
            end,
        },
    },
})
panel:SetInteractionActive(true)
```

`SetInteractionActive(true)` temporarily adds the action descriptors to the
native `KEYBIND_STRIP` and enables mouse interaction. Hiding the panel deactivates
interaction and removes the descriptors; calling `SetInteractionActive(false)`
does the same. A consumer must only activate this state from an explicit UI
interaction mode; it must not leave contextual dialog bindings active during
normal camera control.

The panel does not open the cursor, change scenes, intercept global keys, or
replace native confirmation dialogs. A consumer that needs a modal confirmation
should continue using the shared keyboard/gamepad dialog path.

## Porting the pattern

Another EZO addon can copy the Lua and XML modules and rename the namespace and
global control prefixes. The implementation depends only on native ESO UI
controls. It does not require another EZO addon or an additional library.
