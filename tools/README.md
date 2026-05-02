# Tools

## Version management

Use `tools/bump-version.ps1` for every user-visible addon change.

The addon version has two stored values:

- `EZOTools.txt` -> `## Version`
- `modules/core.lua` -> `EZOTools.ADDON_VERSION`

All in-game version displays use `EZOTools.ADDON_VERSION`, including:

- LAM panel version
- gamepad dialog subtitles
- `/ezo`
- `/ezo version`
- debug/version chat output

`## AddOnVersion` is the ESO integer version in the manifest. It must increase when the visible version changes.

`## APIVersion` is the ESO client API compatibility marker used by the in-game AddOns screen. If it does not include the current client API, ESO can show the addon as outdated even when `## Version` and `## AddOnVersion` are correct.

Before a release or any package intended for use after an ESO patch:

- Get the current client API in-game with `/script d(GetAPIVersion())`.
- Alternatively verify the current live/PTS API from ESOUI/UESP before changing it.
- Do not guess the API version.
- Keep at most two API versions in `## APIVersion`; ESO ignores additional entries.

Examples:

```powershell
.\tools\bump-version.ps1 -Patch
```

```powershell
.\tools\bump-version.ps1 -Version 1.0.91
```

```powershell
.\tools\bump-version.ps1 -Version 1.0.91 -AddOnVersion 10002
```

```powershell
.\tools\bump-version.ps1 -Patch -ApiVersion 101049
```

```powershell
.\tools\bump-version.ps1 -Version 1.0.91 -ApiVersion "101049 101050"
```

```powershell
.\tools\bump-version.ps1 -Check
```

```powershell
.\tools\bump-version.ps1 -Check -ApiVersion 101049
```

Rules:

- Do not edit version numbers manually unless the script is unavailable.
- Run `.\tools\bump-version.ps1 -Check -ApiVersion <current GetAPIVersion()>` before release or after ESO patches.
- Run `.\tools\bump-version.ps1 -Check` before normal development commits if the current client API is not being changed.
- Run `git diff --check` after bumping.
- After a validated commit, recommend `git push` when a remote is configured. Do not push automatically unless explicitly requested.
