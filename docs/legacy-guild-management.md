# Legacy Guild Management Snapshot

Date: 2026-07-28

This document preserves the current EZOTools guild-management implementation
before any future simplification. It is intentionally descriptive only: it does
not change runtime behavior, SavedVariables, assets, or manifest load order.

## Snapshot Markers

- Archive branch: `archive/guild-management-before-simplify-2026-07-28`
- Archive tag: `ezotools-guild-management-legacy-2026-07-28`
- Canonical workspace at capture time: `E:\DEV\EZOTools`
- Base branch at capture time: `main`

## Runtime Components

- `modules/guild_pack.lua`
  - Owns the built-in guild whitelist.
  - Maps normalized guild names to optional overlay textures and predefined
    friend-house assignments.
  - Keeps a lazy cache of unlocked guild keys.
  - Invalidates the cache on guild join, guild leave, and guild-data-loaded
    events.

- `modules/guild_overlay.lua`
  - Resolves tabard guild name and represented guild name.
  - Chooses custom guild overlay textures only when custom guild images are
    enabled, no tabard guild is active, and `EZOTools_GuildPack` unlocks the
    represented guild.
  - Falls back to the normal EZOTools logo paths when no custom guild texture
    is available.

- `modules/friend_houses.lua`
  - Normalizes guild names into stable keys.
  - Builds player-guild choices for settings.
  - Applies manual, selected-guild, and represented-guild friend-house
    profiles.
  - Uses player-saved custom guild profiles before built-in guild-pack values.
  - Migrates the historical `fuego` secondary-house default once.

- `modules/overlay.lua`
  - Renders the guild label above the central logo.
  - Uses tabard guild first, represented guild second, and a no-guild label
    otherwise.
  - Polls represented-guild id because ESO does not expose a dedicated event
    for represented-guild changes.
  - Refreshes the central texture through `EZOTools_GuildOverlay`.

- `modules/lam_registry.lua`
  - Registers the Guild Image settings section.
  - Shows the custom guild image toggle only when the guild pack is unlocked.
  - Registers represented-guild label color and no-guild label visibility.
  - Registers Guild Houses profile editing and auto-assignment settings.

- `modules/debug.lua`
  - Provides `/ezo debug guilds`.
  - Includes represented-guild information in the broader debug info report.

## Manifest Entries

Current related load order in `EZOTools.txt`:

1. `modules/guild_pack.lua`
2. `modules/friend_houses.lua`
3. `modules/guild_overlay.lua`
4. Later consumers: `modules/lam_registry.lua`, `modules/overlay.lua`,
   `modules/debug.lua`

Current guild-overlay assets in the manifest:

- `media/guild_overlays/children_of_lamae.dds`
- `media/guild_overlays/fuego.dds`
- `media/guild_overlays/hojablanca.dds`
- `media/guild_overlays/liga_latina.dds`
- `media/guild_overlays/minion.dds`
- `media/guild_overlays/sombra.dds`

## SavedVariables Surface

Current guild-related values under `EZOTools.sv.overlay`:

- `guildLabelColor`
- `hideNoGuildLabel`
- `guildCustomImageEnabled`

Current guild-house values under `EZOTools.sv.friends`:

- `autoAssignFriendHouses`
- `autoAssignFriendGuildKey` legacy cleanup field
- `friendHouseProfileKey`
- `manualActiveFriendHouseProfileKey`
- `manualActiveFriendHouseProfileInitialized`
- `manualCraftingHall`
- `manualSecondaryHall`
- `editCraftingHall`
- `editSecondaryHall`
- `customGuildFriendHouses`
- `fuegoFriendHouseDefaultMigrated`

Do not purge these values automatically during simplification unless there is a
separate migration plan and a tested downgrade/rollback story.

## Built-In Guild Pack Data

Current built-in guild keys:

- `hojablanca`
- `fuego`
- `children of lamae`
- `ad-minions`
- `sombras de lorkhan`
- `liga latina`

These entries can contain:

- `textures`: ordered texture-path fallbacks for the overlay logo.
- `friendHouses`: predefined crafting and secondary house owners.

## Public Documentation Surface

Current README features that mention this area:

- Represented guild label.
- Configurable represented-guild label color.
- Optional hiding of the no-guild label.
- Custom guild image support for included guild packs.
- Guild House Profiles.
- Auto-assignment from represented guild when a saved or internal profile
  exists.
- Guild diagnostics in `/ezo debug`.

If the feature is simplified, update both `README.md` and `README.es.md` in the
same commit so they no longer advertise removed behavior.

## Restoration Guide

To restore the whole archived implementation:

```powershell
git -C E:\DEV\EZOTools switch main
git -C E:\DEV\EZOTools restore --source ezotools-guild-management-legacy-2026-07-28 -- .
```

To restore only the guild modules and assets after a simplification:

```powershell
git -C E:\DEV\EZOTools restore --source ezotools-guild-management-legacy-2026-07-28 -- `
  modules/guild_pack.lua `
  modules/friend_houses.lua `
  modules/guild_overlay.lua `
  media/guild_overlays
```

When restoring only selected pieces, also inspect:

- `EZOTools.txt` for load order and asset inclusion.
- `EZOTools.lua` for SavedVariables defaults and migration cleanup.
- `modules/lam_registry.lua` for settings sections.
- `modules/overlay.lua` for label/texture consumers.
- `modules/debug.lua` and localization keys for diagnostics.
- `README.md` and `README.es.md` for user-facing behavior.

## Validation Checklist Before Reusing

- Addon loads without Lua errors.
- `/reloadui` works.
- `/ezo` opens normally.
- Settings open under EZOCore and standalone LibAddonMenu fallback.
- Guild Image settings appear only when expected.
- Represented-guild label updates after changing represented guild.
- Tabard state still takes priority over represented guild label/image.
- Custom guild image falls back to the normal logo when unavailable.
- Friend-house auto-assignment uses manual values when no valid represented
  guild profile exists.
- `/ezo debug guilds` reports represented guild and guild list correctly.
- Keyboard, gamepad, chat/Enter, and ESC behavior are unchanged.
