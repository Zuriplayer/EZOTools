# EZOTools

EZOTools is a beta quality-of-life addon for *The Elder Scrolls Online* on PC. It provides a small HUD overlay plus keyboard, mouse, and gamepad-friendly command panels for travel, group actions, utilities, maintenance, and diagnostics.

¿Prefieres español? Lee el [README en español](README.es.md).
Support, bug reports, and suggestions: https://discord.gg/ekw8zUAcRm

## Status

Current version: **2.0.18**.

This addon is in public beta. The implemented features are usable, but some newer group and trial tools are still experimental and should be tested carefully before relying on them in organized runs.

## Requirements

- The Elder Scrolls Online for PC.
- [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu.html), required.
- Optional: LibChatMessage for cleaner chat output.
- Optional: LibDebugLogger and DebugLogViewer for technical diagnostic reports.
- Optional: LibSlashCommander for improved slash command registration.

## Main Features

### HUD Overlay

- Movable on-screen EZOTools overlay.
- Optional lock, scale, player name text, player text color, and player text size.
- Optional hide during combat.
- Optional gamepad-style overlay simulation.
- Contextual tooltips for overlay and side icons.
- Represented guild label, configurable guild label color, and optional hiding of the "No guild" text.
- Custom guild image support for guild packs included in the addon.
- Low stock side widgets for filled Soul Gems and repair kits.
- Side widgets for food/drink status, armor repair, weapon recharge, and related previews.

### Command Panel

The main command panel is available from the addon keybind, gamepad flow, and the overlay/context menu where applicable. It currently includes:

- Travel to your primary house.
- Travel to configured crafting and secondary houses.
- Jump to the group leader when ESO allows it and you are not the leader.
- Leave group.
- Leave instance.
- Leave group and instance.
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
- Owned house history.
- Other players' house history.

### Group Activities

The Group Activities panel is a separate menu for dungeon, trial, and group-related actions:

- Informational group status report shown as an informational yellow menu entry.
- Group status report sent to technical logging when LibDebugLogger is available.
- Trial Travel submenu for veteran trial travel, including "Last trial" and the current centralized trial list.
- Instance difficulty switch between Normal and Veteran when ESO allows it.
- Difficulty switching is hidden while inside an instance because ESO does not allow changing it there.
- Disband group, visible only when you are the group leader and ESO exposes `GroupDisband()` without a required group vote.

The trial list lives in `modules/raid_leader_activity_catalog.lua`. It centralizes implemented trial names and aliases. Fields for IDs such as `zoneId`, `activityId`, and `fastTravelNodeId` are intentionally left for verified data only.

### Guild House Profiles

- Manual crafting and secondary house account names.
- Editable "Own values" profile.
- Optional auto-assignment from the represented guild when the guild has a saved or internal profile.
- Active crafting/secondary values shown in the settings panel.

### Maintenance

- Configurable equipped gear repair threshold.
- Configurable weapon recharge threshold.
- Configurable low repair kit alert.
- Configurable low filled Soul Gem alert.
- Repair/recharge menu entries only appear when needed.

### Language

- English and Spanish localization.
- Automatic language follows the ESO client language.
- Manual language override is available in settings.

### Slash Commands and Diagnostics

Registered commands:

- `/ezo`
- `/ezotools`
- `/ezo help`
- `/ezo status`
- `/ezo about`
- `/ezo debug ...` when debug mode is enabled.

Diagnostic commands include runtime status, guild information, texture/icon checks, side icon layout preview, food debug state, and current housing diagnostics. Long technical reports are intended for LibDebugLogger and DebugLogViewer, not for normal chat spam.

## Safety Boundaries

EZOTools is not an automation addon for combat or gameplay decisions.

- It does not play combat, choose rotations, target enemies, or react to mechanics for you.
- It does not automatically queue, reset, regroup, invite, kick, or fill raids.
- It does not change instance difficulty while you are inside an instance.
- It does not bypass ESO restrictions; actions are attempted only through ESO-provided APIs and only when the addon can verify the relevant function exists.
- Trial travel attempts to use known fast travel nodes and reports diagnostics when a node cannot be found.
- Group disband is only exposed to the leader and only when the relevant ESO API is available.
- Debug tools are for troubleshooting and development; they are not required for normal use.

## Settings

Open the full settings panel through ESO's Add-Ons settings or from EZOTools itself. Current settings cover:

- Language.
- Overlay enabled/locked state.
- Overlay scale.
- Overlay text.
- Player name color and size.
- Combat hiding.
- Contextual tooltips.
- Guild image/label behavior.
- Guild house profile selection and editing.
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
- Open the full settings panel.
- Test the command panel with keyboard/gamepad.
- Test the overlay mouse interactions separately from the side menus.
- Test chat and `Enter`.
- Test `ESC` and normal game menus.
- If testing group tools, use a controlled group first and review DebugLogViewer reports if anything does not behave as expected.

## Repository Metadata

GitHub About should describe the current addon, not only its original travel function. The current public metadata is intended to use Discord as the support/homepage link and topics such as `lua`, `gamepad`, `elder-scrolls-online`, `esoui`, and `eso-addon`.

## License

MIT. See [LICENSE](LICENSE).

Developed and maintained by Zuriplayer.
