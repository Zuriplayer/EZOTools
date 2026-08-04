# EZOTools

EZOTools is a beta quality-of-life addon for *The Elder Scrolls Online* on PC. It provides a small HUD overlay plus keyboard, mouse, and gamepad-friendly command panels for travel, group actions, utilities, maintenance, and diagnostics.

Prefer Spanish? Read the [Spanish README](README.es.md).
Support, bug reports, and suggestions: https://discord.gg/FtP4KapGua

## Status

Current version: **2.0.94**.

This addon is in public beta. The implemented features are usable, but some newer group and trial tools are still experimental and should be tested carefully before relying on them in organized runs.

## Downloads

| Channel | Version | Recommended for |
| --- | --- | --- |
| Stable beta | [2.0.0](https://github.com/Zuriplayer/EZOTools/releases/tag/v2.0.0) | Regular use |
| Early tester beta | [2.0.72-beta.1](https://github.com/Zuriplayer/EZOTools/releases/tag/v2.0.72-beta.1) | Testing the latest group, instance-reset, shared-language, and settings changes |

## Requirements

- The Elder Scrolls Online for PC.
- [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu.html), required.
- Optional: LibChatMessage for cleaner chat output.
- Optional: LibDebugLogger and DebugLogViewer for technical diagnostic reports. Automatic diagnostics are silently skipped when no logger is available and never fall back to chat; an explicitly requested `/ezo debug` command may show one availability message.
- Optional: LibSlashCommander for improved slash command registration.
- Optional: EZOCore with LibGroupBroadcast 2.0.0 for compact, informational Group Activities state sharing between currently grouped players. EZOTools never owns or registers the group protocol itself.

## Main Features

### HUD Overlay

- Movable on-screen EZOTools overlay.
- Optional lock, scale, player name text, player text color, and player text size.
- Optional hide during combat.
- Optional gamepad-style overlay simulation.
- Contextual tooltips for overlay and side icons.
- Represented guild label, configurable guild label color, and optional hiding of the "No guild" text.
- Optional Guild mode for Hojablanca, Fuego, and Sombras de Lorkhan. It uses the image of the supported guild currently represented in C.
- Low stock side widgets for filled Soul Gems and repair kits.
- Side widgets for food/drink status, armor repair, weapon recharge, and related previews.

### Command Panel

The main command panel is available from the addon keybind, gamepad flow, and the overlay/context menu where applicable. It currently includes:

- Travel to your primary house.
- Travel to configured crafting and secondary houses.
- Jump to the group leader when ESO allows it and you are not the leader.
- Leave the current instance when ESO reports that immediate exit is available.
- Leave your group, or leave your group and the current instance together, when ESO reports that those actions are available.
- Repair equipped gear when any equipped item is below the configured durability threshold.
- Recharge weapons when any weapon enchant is below the configured charge threshold.
- Reload UI.
- Open quick settings.
- Open the full LibAddonMenu settings panel.
- Open Group Activities.

### Quick Utilities

The quick utility panel groups frequently used non-combat conveniences:

- Mount, pet, companion, and assistant recall.
- Recent history for mounts, pets, companions, and assistants.
- Empty-state shortcuts to the relevant ESO collection screens.
- Food and drink tracking, recent food/drink history, and optional reuse with confirmation.
- Recent food/drink entries stay visible but disabled when the remembered item is no longer in your inventory.
- Owned house history.
- Other players' house history.

### Group Activities

The Group Activities panel is a separate menu for dungeon, trial, and group-related actions:

- Valid raid-leader actions are placed first: Disband Group, Instance Reset, and then the difficulty control. Disband Group and Instance Reset are omitted entirely when the current player is not the group leader; they are not shown as disabled rows.
- Leave group, available to any grouped player regardless of leadership.
- Leave group, Leave instance, and Leave group and instance are available from the main command panel when ESO allows them, including during combat. Leave group and Leave group and instance also remain available from Group Activities. They are intentionally not duplicated in the EZOTools settings panel. These quick actions are independent from Instance Reset and leader tools.
- `Group status` is not a selectable menu entry. When debug mode and the dedicated LAM option are enabled, EZOTools automatically writes a pre-action group and instance snapshot to Log Viewer before a Group Activities command runs; it does not write the report to chat.
- Any grouped player, including the leader, can open "Group information" on demand from Group Activities. It reuses the same structured status-panel component as the leader reset window without starting or changing a reset. Its idle view is the same for every member: leader zone, effective group difficulty, group size, EZOCore transport state and the current roster with the leader first and each locally reported zone. When the local client owns a reset session, this command shows the existing operational reset panel instead of opening a second group-information panel. Members can receive the leader's activity type, resolved stable target, stage and result through compatible EZOCore and LibGroupBroadcast clients. When an announced reset intentionally disbands the group, each compatible client retains the locally observed session and roster so Group Information remains available: the local player's zone and receipt of the leader's regroup invitation update locally, while absent players are explicitly shown as not grouped with their last known location.
- Trial Travel submenu for veteran trial travel, including "Last trial" and the current centralized trial list.
- Instance difficulty switch between Normal and Veteran when ESO allows it.
- Difficulty switching is hidden while inside an instance because ESO does not allow changing it there.
- Experimental instance reset helper, available only to a grouped leader whose current zone matches a recognized trial. The hall, the active trial interior, wipes, and a completed final boss use the same full reset flow; raid progress does not change eligibility or skip phases. Unsupported zones and dungeons do not expose the action and never reach the disband step.
- The reset captures and immediately revalidates the current group, detected trial, stable zone index, and current Normal/Veteran mode; disbands; reaches the selected staging destination; waits; verifies the captured mode; returns to the same trial; and requests invitations for captured members. The staging destination can be the primary, crafting, or secondary house, or `Leave instance` for accounts without a configured house.
- The movable leader-only status window is a structured native-style HUD panel rather than a multiline text block. It presents the activity and mode, six-phase progress bar, current action and timer, aligned group counters, alerts, and one color-coded row per captured member. Each member row vertically aligns its marker, account, and relevant state in stable regions. A member outside the group shows workflow state and invitations sent; a confirmed group member omits that history and instead shows whether they are in the same instance as the leader. Width, spacing, and row rhythm adapt to small, medium, and full trial rosters; compact native status dots avoid suggesting that informational rows are clickable checkboxes. Long account names and status text are ellipsized instead of disturbing the layout. Players present after the snapshot are identified as `not captured` rather than the ambiguous `additional`. The panel also shows ESO invite responses when they can be matched to a captured account and definitive joined status from current group membership.
- After the configured invitation attempts finish, the status window keeps monitoring pending captured members until they join. Running Reset Instance again resumes the current incomplete phase and every following phase: interrupted staging or return travel is requested again, while incomplete phase 6 restarts its invitation pass. A phase with pending members is not mistaken for a new reset.
- When no captured member remains pending, the panel stops presenting phase timers and shows `RESET COMPLETE` with a final message that reset actions are complete and the leader is waiting to enter the trial. Only this completed post-return state can be replaced by an explicitly confirmed new reset from a valid grouped-leader trial context. Phases 1-5 and incomplete phase 6 are preserved for resume.
- A reset may be ordered during combat. The group is disbanded first, then the staging phase waits for the leader to leave combat before requesting the selected house jump or immediate instance exit.
- During an uninterrupted reset, loading the trial entrance hall does not close the session. The panel clears after ESO reports the trial in progress and the leader is no longer in the raid staging area; the raid-start event remains the fallback when the staging query is unavailable. A later standalone disband clears it separately.
- Instance Reset is enabled by default through a master LAM setting. Disabling it prevents new resets and retained resets from starting through the menu or keybind, while an existing session can still be cancelled safely. Captured members are always invited as part of the reset flow; invitations are no longer an independently optional step.
- Reset phases are strict: disband, selected staging confirmation, wait, captured difficulty, target trial, and member joins are checked separately. With `Leave instance`, the wait starts only after the leader is no longer in the captured trial. A rejected jump, refused immediate exit, or unconfirmed difficulty interrupts the process instead of continuing with unsafe assumptions.
- An interrupted reset remains resumable in the current UI session. Reset Instance remains visible in Group Activities for that saved session even after the internal disband leaves the original leader solo; this exception resumes only the captured run and does not expose other leader-only actions. Interrupted timers remain frozen until resume. Resume first checks whether the selected house has been reached, the captured trial has been left when `Leave instance` is selected, or the leader is back in the target trial before issuing another request. If the leader moves before or during the return request, EZOTools preserves phase 5 and asks the leader to stop moving and run Reset Instance again; this retries only the return phase instead of repeating snapshot, disband, staging, or the wait. The snapshot is not persisted through `/reloadui` or logout.
- Snapshot phase 1 and disband phase 2 may complete within the same frame, so phase 3 can be the first visible state; the addon does not add artificial delays just to display short phases.
- Disband group is visible only when you are the group leader and ESO exposes `GroupDisband()` without a required group vote.
- After a disband request, the addon checks the real group state for several seconds and reports whether ESO confirmed that the leader left the group.
- A standalone confirmed disband clears any retained reset session and hides its status panel. The reset's own internal disband is explicitly marked and does not clear the running workflow.
- After the reset has rebuilt a group, leaving or disbanding that group also clears the retained session. After the leader has returned, leaving the captured trial clears it as well. The selected staging transition and the required return trip do not trigger either cleanup rule.
- The captured roster remains the reset target. A captured member who later leaves voluntarily or is removed is recorded and excluded from further automatic retries. Players who join after capture are shown as additional current members but are not silently added to the original reset target.
- Configurable confirmation protects reset and disband. Keyboard explicitly binds the displayed `E`/primary action to confirm and the negative dialog action to cancel; gamepad uses its native equivalent. Only one dangerous confirmation can be pending, and a second action cannot replace its callback. With debug enabled, Log Viewer records the side-menu dispatch, confirmation request, visible dialog, accepted/cancelled result, callback execution, and observable action result.
- The reset panel is the live operational display. With debug enabled, Log Viewer receives grouped `Info` entries for reset start, completed phase boundaries, resume, and session closure, plus a `Warning` when the run is interrupted or rejected. Individual group, travel, and invitation events are accumulated into those summaries instead of producing a full repeated report. Normal start, travel, wait, resume, and invitation progress is not duplicated in chat; chat is reserved for pre-start rejection and the single actionable interruption notice.
- While the raid leader is grouped, reset lifecycle changes are offered to EZOCore as compact informational `activityState` updates. EZOCore alone owns protocol `EZO_CORE_GROUP_V2` (temporary beta test ID `511`) and request event `EZO_CORE_GROUP_REQUEST_V1` (temporary beta test event `39`). Updates are deduplicated and refreshed at a bounded interval before their TTL expires. Because LibGroupBroadcast is group-scoped, no leader update can be delivered while the reset's disband phase has left players outside a common group. During that gap, EZOTools retains only state and roster data already observed locally, updates the local player's current zone and received regroup invitation, and labels other locations as last known. Live leader sharing resumes for each member as the group is rebuilt.
- Group members can explicitly opt in to one automatic travel request per received activity session. After the player has manually accepted the group invitation, EZOTools requires validated state from the current leader, a compatible trial/dungeon/arena target, a waiting-members or complete stage, and ESO confirmation that the leader is in another instance and can be jumped to. The setting is off by default and never accepts the group invitation itself.
- While any reset session is active or retained, `Cancel instance reset` is the first Group Activities entry. It uses the shared native confirmation, stops addon tracking, unregisters reset events, and closes the panel. It cannot retract invitations already sent or a travel request already accepted by ESO.
- Immediately before the reset disband, EZOTools stores a compact last-activity template in account SavedVariables: the verified captured account names, trial key/name, zone index, and difficulty. After the reset session is cancelled or otherwise cleared, `Start last group and instance` can invite missing saved members and then reuse the existing trial travel with the saved difficulty. The action is unavailable while another reset session exists or while grouped under another leader.
- Assignable keybinds for Group Activities, instance reset, and group disband. Current defaults continue the existing sequence: `Ctrl+Alt+Num2`, `Ctrl+Alt+Num3`, and `Ctrl+Alt+Num4`.

The trial list lives in `modules/raid_leader_activity_catalog.lua`. It centralizes implemented trial names and aliases. Fields for IDs such as `zoneId`, `activityId`, and `fastTravelNodeId` are intentionally left for verified data only.

### Group Autoinvite

- Optional chat autoinvite, disabled by default and configured in LAM.
- Accepts multiple simultaneous invitation words separated by spaces, new lines, commas, or semicolons. Every configured word is an independent alternative: matching any one of them is sufficient.
- Matching is case-insensitive and ignores surrounding punctuation. For example, `+trial1` matches the configured keyword `trial1`, while partial text inside a larger word does not match.
- Listens to player messages in say, yell, zone, language-zone, whisper, and guild channels. System, NPC, and group chat are not invitation sources.
- Requests the invitation only while you are solo or the current group leader, skips the local player and accounts already detected in the group, and suppresses repeated requests to the same account for 15 seconds.
- With debug enabled, matched keywords and the invitation decision are written to Log Viewer without copying the chat message text.

### Manual Houses and Guild Mode

- Manual primary Crafting Hall and secondary house account names are the stable default.
- Manual mode always keeps the EZOTools logo and uses those two fixed house values.
- Members of Hojablanca, Fuego, or Sombras de Lorkhan receive a separate Guild mode section in Settings.
- Guild mode has no manual guild selector. It uses the built-in image and houses only for the supported guild currently represented in C.
- Changing the guild represented in C automatically updates the effective guild image, houses, and disabled LAM values when the represented-guild poll detects the change (within five seconds).
- While Guild mode is enabled, the manual house fields remain visible and disabled while showing the effective guild houses; their manual values stay saved and are restored unchanged when returning to manual mode.
- If C does not point to a supported guild, EZOTools warns the player and safely falls back to the EZOTools logo and manual houses.
- Active crafting/secondary values are shown in the Manual houses section tooltip.

### Maintenance

- Configurable equipped gear repair threshold.
- Configurable weapon recharge threshold.
- Configurable low repair kit alert.
- Configurable low filled Soul Gem alert.
- Repair/recharge menu entries only appear when needed.

### Language

- English and Spanish localization.
- When a compatible EZOCore version provides central EZO-family language management, EZOTools can inherit that shared setting.
- Without EZOCore, the inherited mode falls back to the ESO client language.
- Local automatic and manual language overrides remain available in settings.

### Slash Commands and Diagnostics

Registered commands:

- `/ezo`
- `/ezotools`
- `/ezo help`
- `/ezo status`
- `/ezo about`
- `/ezo debug ...` when debug mode is enabled.

Diagnostic commands include runtime status, guild information, texture/icon checks, side icon layout preview, food debug state, current housing diagnostics, an isolated 11-member reset-panel preview, and a simulated member-facing Group Activities panel. With debug mode enabled, use `/ezo debug resetpanel` for the current 520 px layout, `/ezo debug resetpanel 460` to compare another width from 420 to 620 px, and `/ezo debug resetpanel off` to close it. Use `/ezo debug groupactivity`, `/ezo debug groupactivity staging`, `/ezo debug groupactivity returning`, or `/ezo debug groupactivity complete` to preview local member-panel states without group traffic; `/ezo debug groupactivity off` closes it. These previews never start or modify a reset session. Changing the LAM move-window option also closes the standalone reset preview before showing, restoring, or hiding the real reset panel, so both reset-panel instances cannot remain visible together. Technical reports use the native LibDebugLogger `Info`, `Warning`, `Error`, and `Debug` levels as appropriate and never fall back to normal chat automatically.

## Safety Boundaries

EZOTools is not an automation addon for combat or gameplay decisions.

- It does not play combat, choose rotations, target enemies, or react to mechanics for you.
- It does not queue, kick, fill raids, or make combat/gameplay decisions.
- Chat autoinvite runs only after it is explicitly enabled and a configured keyword matches. It cannot accept group invitations, bypass leadership or group-size restrictions, or guarantee that ESO delivers an invitation; use distinctive keywords because any supported chat participant can trigger a match.
- The instance reset helper is an explicit leader action available only inside a recognized trial. Dungeons and unsupported zones are not reset targets, and the helper does not run passively.
- Instance reset and group disband keybinds are explicit commands and still respect the same leader/API checks as the menu entries.
- Confirmation for instance reset and group disband is enabled by default, allows only one pending dangerous action, and can be disabled in settings.
- The detailed reset status window remains local to the leader who started the process. EZOCore receives only compact activity type, stage, result, Normal/Veteran enum, real phase progress, expected/pending counts, session, target key and TTL. Roster entries, account names, localized status text, timers and invitation history are not transmitted. Each member can detect only an invitation received by that client; it cannot confirm invitations or current locations for other former group members while no common group transport exists.
- The member-facing group activity panel is informational. Received state cannot execute remote commands, accept invitations, or change the group. EZOCore does not transmit roster entries; the panel builds and retains its roster only from group members observed locally before the disband. The separate optional member-travel setting is a local reaction to validated leader state, not a remote command: it is disabled by default, makes at most one jump request per activity session, does not manipulate ESO's native travel prompt, and cannot guarantee that the server completes the requested jump.
- The last-activity template is local account data and contains saved ESO display names. It is updated only from a verified reset snapshot and is used only after the explicit `Start last group and instance` confirmation; it does not invite or travel automatically on login or reload.
- Reset return travel only works for a trial matched to the verified catalog. The captured Normal/Veteran mode must be confirmed before travel or the process is interrupted.
- Return travel is not retried automatically while the leader is moving. The retained phase must be resumed explicitly with the existing Reset Instance action after the leader stops.
- Invite counters record API requests, not guaranteed delivery. A member is treated as joined only when current group membership or the group-join event confirms it.
- A later group member is reported as additional rather than assumed to replace a captured member. EZOTools does not decide replacements, kick players, or invite that additional player as part of the saved reset roster.
- It does not change instance difficulty while you are inside an instance.
- It does not bypass ESO restrictions; actions are attempted only through ESO-provided APIs and only when the addon can verify the relevant function exists.
- Trial travel attempts to use known fast travel nodes and reports diagnostics when a node cannot be found.
- Group disband is only exposed to the leader and only when the relevant ESO API is available.
- Debug tools are for troubleshooting and development; they are not required for normal use.

## Settings

With EZOCore enabled, open the complete panel under Settings > EZO > EZOTools or from EZOTools itself. The panel is not duplicated in ESO's standard Addons settings list. Its overlay and reset status window register independently in the shared interface layout mode; closing Settings returns to HUD/HUD_UI where the active previews remain movable. Without EZOCore, the same controls remain available through the standalone LibAddonMenu fallback. Every section heading uses the same purple information icon; hover the heading to read its general explanation without occupying permanent panel space. Help for an individual setting appears when hovering that setting itself. Master settings refresh their dependent controls immediately in both EZOCore-hosted and standalone LibAddonMenu panels. Current settings cover:

- Language.
- Overlay enabled/locked state.
- Overlay scale.
- Overlay text.
- Player name color and size.
- Combat hiding.
- Contextual tooltips.
- Represented guild label behavior.
- Fixed manual primary/secondary house values.
- A conditional Guild mode section for eligible members, driven exclusively by the guild represented in C.
- Automatic pre-action group-status diagnostics for Group Activities, available only while the global debug mode is enabled.
- Chat autoinvite enable toggle and simultaneous alternative invitation words.
- Instance reset settings start with a master enable toggle. When disabled, the dependent controls are visibly unavailable. The section then provides confirmation (enabled by default), staging destination, movable status window with a temporary full 11-member placement preview, wait timer, invite delay, and reinvite attempts. The experimental explanation is available from the information icon beside the section heading.
- Group activity member travel provides one disabled-by-default checkbox for automatically requesting travel to the current leader after manually accepting the regroup invitation. Its section tooltip explains the EZOCore/LibGroupBroadcast requirement and safety limits.
- Repair and recharge thresholds.
- Low repair kit and Soul Gem alerts.
- Debug mode.

## Installation

1. Install the required LibAddonMenu-2.0 library.
2. Download or clone this repository.
3. Copy the `EZOTools` folder into:

   ```text
   Documents/Elder Scrolls Online/live/AddOns/
   ```

4. Enable EZOTools in the in-game Add-Ons screen.
5. Use `/reloadui` after installing or updating.

## Recommended Testing

After installing or updating:

- Confirm the addon loads without Lua errors.
- Run `/reloadui`.
- Run `/ezo status`.
- Open the full settings panel under Settings > EZO and confirm EZOTools is not duplicated in the standard Addons list.
- Disable EZOCore and confirm the standalone LibAddonMenu fallback remains available.
- Test the command panel with keyboard/gamepad.
- Test the overlay mouse interactions separately from the side menus.
- Test chat and `Enter`.
- Test `ESC` and normal game menus.
- If testing group tools, use a controlled group first and review DebugLogViewer reports if anything does not behave as expected.
- From a localized client, open Trial Travel and request a trip to Aetherian Archive; confirm that the verified catalog node is used rather than depending only on the displayed node name. Repeat through Instance Reset to cover the shared travel route.
- If testing instance reset, use a small controlled group first. Test both a configured house and `Leave instance`; verify combat waiting, staging confirmation, captured difficulty, return travel, invite requests, responses, member exits/removals, additional joins, and joined-state tracking before an organized raid.
- Disable the Instance Reset master setting and verify that its dependent LAM controls are greyed out, Reset Instance disappears from Group Activities, and its direct keybind cannot start or resume the workflow. If a session already exists, verify that Cancel Instance Reset remains available; re-enable the setting before continuing reset tests. Hover every LAM section heading and its field-specific controls to verify that the information tooltips appear without persistent explanatory paragraphs.
- In a pre-existing group, transfer leadership to the EZOTools player while Group Activities is open and confirm that leader actions appear after the delayed context refresh. Repeat the reset from the trial hall, the active interior, after a wipe, and after the final boss; every case must capture the current group and execute the complete staging/return flow without skipping phases.
- During the return phase, test both starting while already moving and moving during the travel cast. Confirm that phase 5 is retained with a specific action message, then stop moving and verify that Reset Instance retries only the return trip.
- Interrupt the phase 3 staging trip after the internal disband. Confirm that the panel timers stop, Group Activities still shows Reset Instance while solo, and selecting it resumes the retained staging phase without showing Disband Group or difficulty controls.
- During active, interrupted, waiting-members, and reset-complete states, verify that Cancel Instance Reset is the first Group Activities entry in mouse, keyboard-menu, and gamepad-menu modes. Confirm cancellation and check that the panel closes and neither cancellation nor delayed callbacks revive the session.
- After cancelling, verify that Start Last Group and Instance appears, confirms the remembered trial and member count, invites only missing saved members, and travels through the existing trial route at the captured difficulty. Confirm that it is hidden during an active reset and while grouped under another leader.
- With debug enabled, verify that a reset produces yellow `Info` summaries at lifecycle boundaries and one warning if interrupted. Group joins/leaves and invitation responses must update the panel without generating a complete standalone report for each event, and normal reset progress must not be copied to chat.
- While phase 6 still has pending members, run Reset Instance again and confirm that the resume dialog restarts invitations without replacing the snapshot. Once every captured member is grouped, confirm that the panel shows `RESET COMPLETE` without phase timers and that a later explicitly confirmed reset can create a new snapshot.
- Verify Leave group as both leader and non-leader, Leave instance where ESO allows immediate exit, and Leave group and instance when both conditions are true. Confirm the valid actions appear in the main command panel but not in LAM, and that Leave group plus Leave group and instance remain available in Group Activities. Repeat in mouse, keyboard-menu, and gamepad-menu flows, including combat where ESO still allows the action.
- Confirm that `Group status` no longer appears in Group Activities. With debug mode and automatic group-status logging enabled, run each available group action and verify that Log Viewer receives one pre-action snapshot containing the corresponding `action` value; disable the LAM option and verify that these snapshots stop.
- Open Group Information on the leader and a member with no reset session. Confirm that both show the same group size, natively formatted leader zone, an explicit `Normal`/`Veteran` label separated from the zone by a hyphen, and the complete roster, without truncated status text, progress, pending counts, remote-waiting messages or duplicated rows. Then install the same EZOCore protocol-v2 beta and EZOTools build on both clients, start a controlled reset as leader, and open Group Information on both clients. Confirm that the leader keeps only the existing operational reset panel and that no second group-information panel appears. Confirm that the member receives the trial key/name, Normal/Veteran mode, exact phase progress and pending count; the member panel must not fabricate progress from the stage or use its local difficulty. After the intentional disband, confirm that Group Information remains available, the captured roster is retained, the local player's zone updates, absent members are marked not grouped with last-known locations, and the local row changes when the regroup invitation is received. Confirm that live leader state resumes after rejoining. Closing the panel must not affect the group, travel, invitations or reset state. Repeat without EZOCore to verify the local fallback.
- Enable automatic member travel only on the non-leader test client. Accept the reset regroup invitation manually while outside the leader's target instance and confirm that EZOTools requests one jump to the current leader. Repeat while already in the same instance, as leader, with the setting disabled, with an expired or incompatible state, and with ESO reporting that the jump is unavailable; none of those cases may request travel. Confirm that a repeated state for the same session does not trigger another jump.
- With debug mode enabled, run `/ezo debug groupactivity`, `/ezo debug groupactivity returning`, `/ezo debug groupactivity complete`, and `/ezo debug groupactivity off`. Confirm that the simulated member panel clearly marks itself as debug data, shows only leader/self location rows rather than the full roster, and closes without changing group, travel, or reset state.
- During that test, verify that the panel stays hidden in inventory/game menus, remains visible in the trial entrance hall, and normally clears after the leader leaves the raid staging area.
- Verify the structured reset panel with one, four, and eleven captured members (the leader is not listed as a captured member). Enabling the LAM move option must show the complete eleven-member placement preview; drag it with the left mouse button and confirm the right button does not move it. Disabling the option must restore the real reset state or hide the panel. Check that metrics remain centered and aligned, member names do not overlap their invitation or location status, the six-phase bar and its centered counter remain readable, alerts expand the panel cleanly, and switching between keyboard and gamepad changes the native typography without moving or resizing unrelated UI. For grouped members, verify the green same-instance and yellow different-instance states; members without a current group unit tag must remain gray and unknown.
- After a completed or retained reset session, form a controlled group and run standalone Disband Group. Verify that ESO confirms the disband, the panel closes, and Log Viewer reports `reset-session-cleared` when debug mode is enabled.
- After a reset rebuilds the group, test manual Leave Group and standalone Disband Group. Confirm that both close the retained panel; then repeat the flow and leave the captured trial after the return to confirm that zone departure also closes it without affecting the staging phases.
- For autoinvite, configure at least two keywords, enable it, and test exact, uppercase, `+keyword`, and unrelated larger-word messages from another account in guild or whisper chat. Confirm that only valid matches invite, that a non-leader does not invite, and that a repeated message within 15 seconds does not issue another request. With debug enabled, verify the `initialization`, `keyword-detected`, `keyword-evaluated`, `invite-requested`, and available `invite-response` stages in Log Viewer. Disable the option and confirm that matching messages stop inviting.
- Verify that Reset Instance is unavailable outside a recognized trial and does not disband the group there.

## Reusable UI component

The reset window uses the generic status panel documented in [docs/status-panel.md](docs/status-panel.md). The component is independent from group and trial logic and includes an optional, explicitly activated action mode for mouse, keyboard, and gamepad consumers.

## Repository Metadata

GitHub About should describe the current addon, not only its original travel function. The current public metadata is intended to use Discord as the support/homepage link and topics such as `lua`, `gamepad`, `elder-scrolls-online`, `esoui`, and `eso-addon`.

## License

MIT. See [LICENSE](LICENSE).

Developed and maintained by Zuriplayer.
