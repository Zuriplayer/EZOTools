# EZOTools — Claude Code project memory

@AGENTS.md

## Contexto adicional

- Guía común de la familia EZO: `EZO_FAMILY.md`, un nivel por encima de este repositorio en la carpeta Dev compartida de la familia (leerla antes de tocar bindings, gamepad, HUD/overlay o integraciones entre addons).
- El juego carga el addon vía symlinks hacia este mismo repositorio:
  - Live: `%USERPROFILE%\Documents\Elder Scrolls Online\live\addons\EZOTools`
  - PTS: `%USERPROFILE%\Documents\Elder Scrolls Online\pts\AddOns\EZOTools`
- Flujo de trabajo: editar → probar en juego (`/reloadui`) → `.\tools\bump-version.ps1` → commit → push.
- Publicación en Discord: paso separado, solo bajo petición explícita (ver `docs/ezo-discord-automation.md`).
- Lint local: `luacheck .` (config en `.luacheckrc`). Solo detecta sintaxis y variables; la validación real es en el juego.
  Si el directorio de trabajo es una ruta de red (UNC), `luacheck` no acepta esa cwd directamente; usar
  `cmd /c 'pushd "<ruta del repo>" && luacheck . --formatter plain & popd'`. Si ya es una ruta local, basta con `luacheck . --formatter plain`.
- El usuario prueba en el juego; Claude no puede ejecutar ESO. Pedir siempre confirmación de la checklist de pruebas de AGENTS.md tras cambios funcionales.

<!-- EZO-ESO-UPDATE-START -->
## Baseline obligatorio de ESO

Antes de analizar, modificar, validar, versionar o publicar este proyecto, leer
`..\EZOFamilyDocs\docs\eso-updates\current.md` y aplicar la política enlazada.

Baseline vigente: `U51-PTS-v12.1.0`.

- La matriz por addon vive en `..\EZOFamilyDocs\data\eso-update-baseline.json`.
- U51 sigue siendo PTS provisional hasta que exista verificación explícita.
- No cambiar `## APIVersion` por inferencia; verificarla en el cliente o en una
  fuente fiable de API.
- Si estos archivos no están disponibles, detener el trabajo sensible a
  compatibilidad e indicar el bloqueo.

Fuente remota de respaldo:
https://github.com/Zuriplayer/EZOFamilyDocs/blob/main/docs/eso-updates/current.md
<!-- EZO-ESO-UPDATE-END -->
