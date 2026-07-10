# EZOTools

EZOTools es un addon beta de calidad de vida para *The Elder Scrolls Online* en PC. Añade un pequeño overlay en pantalla y paneles de comandos compatibles con teclado, ratón y mando para viajes, acciones de grupo, utilidades, mantenimiento y diagnóstico.

¿Prefieres inglés? Lee el [README en inglés](README.md).

Soporte, errores y sugerencias: https://discord.gg/ekw8zUAcRm

## Estado

Versión actual: **2.0.18**.

Este addon está en beta pública. Las funciones implementadas son utilizables, pero algunas herramientas nuevas de grupo y trials siguen siendo experimentales y conviene probarlas con cuidado antes de depender de ellas en raids organizadas.

## Requisitos

- The Elder Scrolls Online para PC.
- [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu.html), obligatorio.
- Opcional: LibChatMessage para mensajes de chat más limpios.
- Opcional: LibDebugLogger y DebugLogViewer para informes técnicos de diagnóstico.
- Opcional: LibSlashCommander para un mejor registro de comandos slash.

## Funciones principales

### Overlay HUD

- Overlay movible de EZOTools en pantalla.
- Bloqueo opcional, escala, texto de nombre de jugador, color del texto y tamaño del texto.
- Opción para ocultarlo durante combate.
- Simulación opcional de estilo gamepad solo para el overlay.
- Tooltips contextuales para el overlay y los iconos laterales.
- Etiqueta del gremio representado, color configurable para esa etiqueta y opción para ocultar el texto "Sin gremio".
- Soporte de imagen personalizada para packs de gremio incluidos en el addon.
- Widgets laterales de aviso para Gemas de alma llenas y kits de reparación bajos.
- Widgets laterales para estado de comida/bebida, reparación de armadura, recarga de armas y sus previsualizaciones.

### Panel de comandos

El panel principal de comandos está disponible desde el keybind del addon, el flujo de mando y el overlay/menú contextual cuando corresponde. Actualmente incluye:

- Viajar a tu casa principal.
- Viajar a las casas configuradas de artesanía y secundaria.
- Saltar al líder del grupo cuando ESO lo permite y tú no eres el líder.
- Abandonar grupo.
- Salir de instancia.
- Abandonar grupo y salir de instancia.
- Reparar el equipo equipado cuando alguna pieza está por debajo del umbral configurado.
- Recargar armas cuando algún encantamiento está por debajo del umbral configurado.
- Recargar interfaz.
- Abrir ajustes rápidos.
- Abrir el panel completo de LibAddonMenu.
- Abrir Actividades de grupo.

### Utilidades rápidas

El panel de utilidades rápidas agrupa comodidades de uso frecuente fuera de combate:

- Recuperar montura, mascota, compañero y asistente.
- Historial reciente de monturas, mascotas, compañeros y asistentes.
- Accesos de estado vacío a las pantallas de colección correspondientes de ESO.
- Seguimiento de comida y bebida, historial reciente de comida/bebida y reutilización opcional con confirmación.
- Historial de casas propias.
- Historial de casas de otros jugadores.

### Actividades de grupo

El panel Actividades de grupo es un menú separado para acciones relacionadas con dungeons, trials y grupo:

- Informe informativo de estado del grupo mostrado como entrada amarilla informativa.
- Informe de estado del grupo enviado al log técnico cuando LibDebugLogger está disponible.
- Submenú de viaje a trials en veterano, con "Última trial" y la lista centralizada actual de trials.
- Cambio de dificultad de instancia entre Normal y Veterano cuando ESO lo permite.
- El cambio de dificultad se oculta dentro de una instancia porque ESO no permite cambiarla ahí.
- Disbandear grupo, visible solo si eres líder y ESO expone `GroupDisband()` sin requerir votación de grupo.

La lista de trials vive en `modules/raid_leader_activity_catalog.lua`. Centraliza los nombres y alias de trials implementadas. Los campos para IDs como `zoneId`, `activityId` y `fastTravelNodeId` quedan reservados para datos verificados.

### Perfiles de casas de gremio

- Nombres de cuenta manuales para casa de artesanía y casa secundaria.
- Perfil editable "Valores propios".
- Autoasignación opcional desde el gremio representado cuando ese gremio tiene un perfil guardado o interno.
- Valores activos de artesanía/secundaria visibles en el panel de ajustes.

### Mantenimiento

- Umbral configurable de reparación de equipo equipado.
- Umbral configurable de recarga de armas.
- Alerta configurable de kits de reparación bajos.
- Alerta configurable de Gemas de alma llenas bajas.
- Las entradas de reparación/recarga solo aparecen cuando hacen falta.

### Idioma

- Localización en inglés y español.
- El modo automático sigue el idioma del cliente de ESO.
- Hay selección manual de idioma en ajustes.

### Comandos slash y diagnóstico

Comandos registrados:

- `/ezo`
- `/ezotools`
- `/ezo help`
- `/ezo status`
- `/ezo about`
- `/ezo debug ...` cuando el modo debug está activado.

Los comandos de diagnóstico incluyen estado de ejecución, información de gremios, comprobaciones de texturas/iconos, previsualización de diseño de iconos laterales, estado debug de comida y diagnóstico de vivienda actual. Los informes técnicos largos están pensados para LibDebugLogger y DebugLogViewer, no para llenar el chat normal.

## Límites de seguridad

EZOTools no es un addon de automatización para combate ni decisiones de juego.

- No juega el combate, no elige rotaciones, no selecciona enemigos y no reacciona a mecánicas por ti.
- No encola, resetea, reagrupa, invita, expulsa ni rellena raids automáticamente.
- No cambia la dificultad de instancia mientras estás dentro de una instancia.
- No evita restricciones de ESO; las acciones se intentan solo mediante APIs de ESO y solo cuando el addon puede verificar que la función existe.
- El viaje a trials intenta usar nodos de viaje rápido conocidos e informa diagnóstico cuando no encuentra un nodo.
- El disband de grupo solo se expone al líder y solo cuando la API relevante de ESO está disponible.
- Las herramientas debug son para soporte y desarrollo; no son necesarias para el uso normal.

## Ajustes

Abre el panel completo desde los ajustes de complementos de ESO o desde el propio EZOTools. Los ajustes actuales cubren:

- Idioma.
- Activación y bloqueo del overlay.
- Escala del overlay.
- Texto del overlay.
- Color y tamaño del nombre de jugador.
- Ocultar durante combate.
- Tooltips contextuales.
- Comportamiento de imagen/etiqueta de gremio.
- Selección y edición de perfiles de casas de gremio.
- Umbrales de reparación y recarga.
- Alertas de kits de reparación y Gemas de alma.
- Modo debug.

## Instalación

1. Instala la librería obligatoria LibAddonMenu-2.0.
2. Descarga o clona este repositorio.
3. Copia la carpeta `EZOTools` dentro de:

   ```text
   Documents/Elder Scrolls Online/live/AddOns/
   ```

4. Activa EZOTools desde la pantalla de complementos del juego.
5. Usa `/reloadui` después de instalar o actualizar.

## Pruebas recomendadas

Después de instalar o actualizar:

- Confirmar que el addon carga sin errores Lua.
- Ejecutar `/reloadui`.
- Ejecutar `/ezo status`.
- Abrir el panel completo de configuración.
- Probar el panel de comandos con teclado/mando.
- Probar las interacciones del overlay con ratón separadas de los menús laterales.
- Probar chat y `Enter`.
- Probar `ESC` y los menús normales del juego.
- Si pruebas herramientas de grupo, usa primero un grupo controlado y revisa los informes de DebugLogViewer si algo no se comporta como esperas.

## Metadatos del repositorio

GitHub About debe describir el addon actual, no solo su función original de viaje. La metadata pública actual debe usar Discord como enlace de soporte/homepage y topics como `lua`, `gamepad`, `elder-scrolls-online`, `esoui` y `eso-addon`.

## Licencia

MIT. Ver [LICENSE](LICENSE).

Desarrollado y mantenido por Zuriplayer.
