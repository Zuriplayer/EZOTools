# EZOTools — AI Development Rules


<!-- EZO-SHARED-LAM-START -->
## Estándar LAM compartido

Antes de crear o modificar ajustes LibAddonMenu, leer y aplicar:
`E:\DEV\EZOFamilyDocs\docs\ezo-lam-settings-style.md`

Las reglas específicas de este addon tienen prioridad. Si el archivo compartido
no está accesible, no modificar LAM e indicarlo explícitamente.
<!-- EZO-SHARED-LAM-END -->
Este proyecto es un addon para The Elder Scrolls Online (ESO).

El entorno Lua de ESO es LIMITADO y no equivale a Lua estándar.

El objetivo es generar código SEGURO, COMPATIBLE y FÁCILMENTE REVISABLE.

---

# 🔧 Tecnologías

- Lua
- XML
- archivo manifest (.txt)

---

# 🔒 REGLAS OBLIGATORIAS

## 1. APIs de ESO
- No inventar APIs.
- Si no estás seguro de una API, detente y dilo explícitamente.
- Prioriza reutilizar funciones existentes del proyecto.

## 2. Librerías
- No usar librerías externas salvo indicación expresa.
- Usar correctamente:
  - LibAddonMenu-2.0
  - LibChatMessage

## 3. Cambios controlados
- Mantener cambios pequeños y revisables.
- No refactorizar grandes partes del proyecto.
- No modificar código no relacionado con la tarea.

## 4. Archivos y manifest
- No renombrar archivos sin necesidad.
- No eliminar archivos del manifest.
- Si se añade un archivo:
  - añadirlo a EZOTools.txt
  - respetar el orden lógico existente

## 4.1 Versionado
- Para cualquier cambio visible del addon, actualizar versión con:
  - `.\tools\bump-version.ps1 -Patch`
  - o `.\tools\bump-version.ps1 -Version x.y.z`
- Si el cambio se prepara para release o hay parche de ESO, comprobar también la API del cliente:
  - en juego: `/script d(GetAPIVersion())`
  - o fuente fiable ESOUI/UESP actual
- `## APIVersion` controla si ESO muestra el addon como desactualizado en la pantalla de complementos/addons.
- No adivinar `## APIVersion`; solo cambiarlo si el valor actual está verificado.
- Para actualizar API usar:
  - `.\tools\bump-version.ps1 -Patch -ApiVersion <api_actual>`
  - o `.\tools\bump-version.ps1 -Version x.y.z -ApiVersion <api_actual>`
- Mantener como máximo dos valores en `## APIVersion`; ESO ignora entradas adicionales.
- No editar versiones manualmente salvo que la herramienta no esté disponible.
- La versión visible debe quedar sincronizada entre:
  - `EZOTools.txt` (`## Version`)
  - `modules/core.lua` (`EZOTools.ADDON_VERSION`)
- `## AddOnVersion` debe incrementarse cuando cambia la versión visible.
- Antes de commit, ejecutar:
  - `.\tools\bump-version.ps1 -Check`
  - si se conoce la API actual: `.\tools\bump-version.ps1 -Check -ApiVersion <api_actual>`
  - `git diff --check`
- Después de un commit validado, si existe remoto configurado, recomendar push explícitamente al usuario. No hacer push sin petición expresa.

## 5. Globals
- Evitar globals innecesarias.
- Usar siempre:
  EZOTools = EZOTools or {}

## 6. Lua no soportado
NO usar:
- os.*
- io.*
- require()
- librerías estándar no soportadas por ESO

---

# 🧠 CONVENCIONES DEL PROYECTO

- Inicialización en EVENT_ADD_ON_LOADED
- SavedVariables centralizadas
- Código modular en /modules
- Separación clara:
  - lógica
  - UI
  - persistencia
- `modules/overlay.lua` debe tratarse como capa de presentación del overlay:
  - NO añadir nuevas reglas de negocio, historiales, persistencia ni lógica de menús rápidos directamente en `overlay.lua`.
  - Las funcionalidades de HOLD X/HOLD Y/futuros menús laterales deben vivir en módulos dedicados por dominio o proveedor (`quick_utility_*`, `side_menu_*`, etc.) y exponerse mediante APIs pequeñas.
  - `overlay.lua` puede orquestar refrescos visuales y delegar llamadas, pero no debe convertirse en el punto donde se acumulan nuevas funcionalidades.
  - Si una nueva funcionalidad necesita estado propio, reglas de filtrado, historial o diagnóstico, crear/usar un módulo específico y añadirlo al manifest en orden lógico.

---

# ⚠️ REGLAS ESPECÍFICAS DE ESO

## Eventos
- Usar EVENT_MANAGER:RegisterForEvent
- Prefijo obligatorio: "EZOTools_"
- Desregistrar eventos si aplica

## UI / XML
- No modificar XML sin necesidad
- No crear controles sin validar contexto
- Mantener compatibilidad UI existente

## Input (CRÍTICO)
Archivos sensibles:
- keyboard_enter_override.lua
- input_router.lua
- keybinds.lua

Reglas:
- NO cambiar comportamiento sin indicación explícita
- NO interceptar teclas globalmente
- NO romper navegación de menús

Contrato funcional de modos de interacción:
- `overlay-raton`
- `rapido-gamepad`
- `rapido-teclado`
- `cursor-ui-explicito`

Definición obligatoria de cada modo:
- `overlay-raton`: interacción directa con los iconos del overlay en pantalla.
- `overlay-raton`: hover = tooltip.
- `overlay-raton`: clic izquierdo = acción directa.
- `overlay-raton`: clic derecho = listado de recientes.
- `rapido-gamepad`: menú lateral rápido abierto por `HOLD Y`.
- `rapido-gamepad`: navegación y selección con lógica gamepad.
- `rapido-gamepad`: no depende del hover ni del foco del overlay.
- `rapido-teclado`: equivalente funcional de `rapido-gamepad`, pero disparado por keybind.
- `rapido-teclado`: no equivale a `overlay-raton`.
- `cursor-ui-explicito`: solo sirve para sacar el juego del control de cámara y dar cursor/UI.
- `cursor-ui-explicito`: no sustituye `overlay-raton`, `rapido-gamepad` ni `rapido-teclado`.

Reglas obligatorias para no mezclar modos:
- NO usar el trigger de un modo para probar otro modo.
- NO llamar "modo teclado" al gameplay normal con teclado+ratón si se está hablando del menú rápido por keybind.
- NO reasignar por defecto una tecla si ya existe un flujo estable de otro modo cercano.
- NO cambiar clic izquierdo/derecho del `overlay-raton` salvo petición explícita.
- Si hay duda entre comportamiento del juego y comportamiento del addon, detenerse y aclararlo antes de editar.

Formato obligatorio antes de tocar input/UI:
- Modo afectado.
- Modos que NO deben cambiar.
- Trigger exacto.
- Resultado esperado.
- Resultado explícitamente prohibido.

Matriz mínima de validación para cualquier cambio de input/UI:
- `overlay-raton`
- `rapido-gamepad`
- `rapido-teclado`
- chat / `Enter`
- `ESC` / menús del juego

## Compatibilidad
Todo cambio debe funcionar en:
- modo teclado
- modo gamepad

---

# 🌍 LOCALIZACIÓN

- Usar lang/en.lua y lang/es.lua
- No hardcodear textos
- Usar sistema de strings del addon

---

# 📚 Documentación

- Toda modificación funcional, de configuración, comportamiento, alcance o requisitos debe incluir en el mismo trabajo la revisión y actualización de `README.md` y `README.es.md`.
- Ambos README deben mantenerse equivalentes y sincronizados.
- Ningún README debe anunciar funciones, límites o requisitos que no coincidan con el código actual.
- Deben actualizarse las secciones afectadas: funciones, límites de seguridad, requisitos, instalación y pruebas.
- Antes de cerrar cualquier cambio se debe comprobar expresamente que ambos README siguen completos y actualizados.

---

# ⚠️ KNOWN PITFALLS (CRÍTICO)

Problemas históricos que NO deben reintroducirse:

## 1. ENTER no funciona
- Causa típica: override incorrecto en input
- Regla: no modificar keyboard_enter_override sin permiso

## 2. Menús no responden
- Causa: interceptación de input o foco incorrecto
- Regla: no alterar input_router sin análisis

### Contrato de acciones del menú lateral
- Las acciones normales deben usar el callback directo creado por `SideMenuCore`, igual que las demás entradas ejecutables.
- No cerrar el diálogo ni añadir `zo_callLater` antes de una acción normal.
- El patrón cerrar + retrasar + abrir se reserva exclusivamente para transiciones a un submenú o diálogo que realmente lo necesite.
- Antes de cambiar el enrutado de una acción que no responde, sustituir temporalmente su ejecución por una ventana pasiva para comprobar si el callback fue alcanzado.
- Reset y disband son acciones peligrosas: deben llamar a las APIs compartidas `RaidLeaderReset.Start()` y `RaidLeaderTools.DisbandGroup()`, igual que overlay y keybindings.
- Desde el menú lateral se cierra primero el diálogo padre y se difiere 50 ms la llamada compartida; esta excepción existe porque se abre una confirmación nativa real.
- La confirmación compartida usa `ZO_Dialogs_ShowDialog` en teclado y `ZO_Dialogs_ShowGamepadDialog` con `GAMEPAD_DIALOGS.BASIC` en mando.
- No crear un segundo menú paramétrico para confirmar ni implementar doble pulsación; esas rutas causaron fallos históricos de foco y callbacks.
- El callback afirmativo se guarda fuera de `dialog.data`; no debe borrarse desde `finishedCallback` porque ESO puede finalizar el diálogo antes de entregar la acción.
- Tras confirmar, diferir 50 ms la acción real para que ESO libere completamente el diálogo antes de entrar en `StartConfirmed` o `DisbandGroupConfirmed`.
- Con debug activo, cualquier diagnóstico de esta transición debe enviarse a Log Viewer.

## 3. LAM (LibAddonMenu) roto
- Causa: cambios en lam_registry o estructura de settings
- Regla: mantener estructura existente

## 4. Gamepad desincronizado
- Causa: cambios solo pensados para teclado
- Regla: siempre validar ambos modos

## 5. Manifest incorrecto
- Causa: archivos no añadidos o mal ordenados
- Regla: revisar EZOTools.txt siempre

---

# 🧪 PROCESO DE DESARROLLO

## Antes de implementar
- Enumerar supuestos
- Identificar riesgos
- Indicar incertidumbres

## Durante la implementación
- Mostrar cambios por archivo
- No generar archivos completos innecesariamente

## Después de implementar
- Explicar qué se ha hecho
- Indicar posibles efectos secundarios

---

# 🧪 CHECKLIST DE PRUEBAS (OBLIGATORIO)

Siempre incluir:

- ¿Carga el addon sin errores Lua?
- ¿Funciona /reloadui?
- ¿Funciona el comando /ezo?
- ¿Abre el menú de configuración?
- ¿Input teclado correcto?
- ¿Modo gamepad correcto?

---

# 🚫 NO HACER

- No reescribir sistemas completos
- No cambiar arquitectura
- No optimizar sin necesidad
- No añadir abstracciones innecesarias
- No tocar múltiples módulos sin justificación

---

# 🧠 CUANDO HAYA DUDA

- NO asumir
- NO inventar
- PREGUNTAR o indicar incertidumbre

---

# 🎯 OBJETIVO

Generar código estable, compatible con ESO y alineado con EZOTools, evitando romper funcionalidades existentes.
## Publicacion en Discord

### Principios

- La publicacion en Discord es un paso separado de commit/push. No se publica nada automaticamente.
- No se publica nada sin confirmacion explicita del usuario.
- Ante cualquier duda sobre que publicar, en que canal, o con que contenido: preguntar antes de actuar, nunca asumir.
- El contenido publico (releases, announcements, status) es siempre en ingles, **excepto `#downloads`, que es bilingue (ingles + espanol)**. Es la unica excepcion a la regla de idioma.
- El contenido publico debe ser util para terceros: descarga, uso, cambios visibles, advertencias relevantes. No es un registro de desarrollo.
- Nunca incluir detalles internos en contenido publico: rutas locales, symlinks, nombres de rama, referencias al NAS, PTS/live local, mecanica de los workflows, o decisiones internas de implementacion.

### Tono del texto en ingles

- Nivel: aficionado a la programacion avanzado, no jerga de profesional ni tono corporativo de release notes.
- Evitar sonar pedante: parte de la audiencia conoce al autor personalmente.
- No es sinonimo de simple o vulgar; es cercano y claro, sin tecnicismos innecesarios.

### Cuando publicar

- Solo si hay cambio funcional real, correccion importante, o version suficientemente estable para jugadores/testers.
- No publicar por cada commit ni por cambios internos menores que no afectan al usuario.
- `#announcements` se actualiza en cada actividad publicable (status, beta o release): mantener informados a jugadores/testers es la funcion de ese canal, no reservarlo solo para hitos grandes. Sigue sujeto a confirmacion explicita como cualquier otra publicacion.

### Confirmacion obligatoria

- Antes de lanzar un workflow real, preguntar y dejar claro que opcion se va a ejecutar: `status`, `beta`, `release + download`, `announcement`, o `no publicar`.
- Los workflows de Discord tienen `confirm_publish` con valor por defecto `DRY_RUN`; solo publicar si el usuario ha autorizado explicitamente y se escribe exactamente `PUBLISH`.
- No activar `publish_download` ni `publish_announcement` salvo autorizacion expresa del usuario, aunque se este publicando otra cosa a la vez.

### Validacion previa obligatoria

Antes de publicar cualquier cosa:

- version sincronizada (manifest, core.lua, ezo-addon.json),
- ZIP limpio generado y verificado,
- cambios commiteados y pusheados,
- pruebas basicas hechas, o limitaciones declaradas si no las hay,
- si es release y aplica, API de ESO verificada o confirmada sin cambios.

### Canal de referencia del addon

- Existe un canal con el nombre del addon (p. ej. `#EZOTools`) con la guia de funcionalidad/uso, en ingles y espanol, breve.
- No forma parte de los workflows; lo publica el usuario a mano. Claude prepara/actualiza el texto en `docs/ezo-feature-guide.md`, nunca lo publica.
- Se actualiza solo cuando cambia funcionalidad visible para el usuario, no en cada patch.

Para detalles operativos (canales, ZIP, scripts), usar `docs/ezo-discord-automation.md`.

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
