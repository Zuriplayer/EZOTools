# EZOTools

EZOTools es un addon beta de calidad de vida para *The Elder Scrolls Online* en PC. Añade un pequeño overlay en pantalla y paneles de comandos compatibles con teclado, ratón y mando para viajes, acciones de grupo, utilidades, mantenimiento y diagnóstico.

¿Prefieres inglés? Lee el [README en inglés](README.md).
Soporte, errores y sugerencias: https://discord.gg/ekw8zUAcRm

## Estado

Versión actual: **2.0.64**.

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

- Las acciones válidas de raid leader aparecen primero: Disbandear grupo, Resetear instancia y después el control de dificultad. Disbandear grupo y Resetear instancia se omiten por completo cuando el jugador actual no es líder; no se muestran como filas desactivadas.
- Abandonar grupo, disponible para cualquier jugador agrupado independientemente de si es líder.
- Salir de instancia, disponible cuando `CanExitInstanceImmediately()` de ESO informa de que se permite la salida inmediata.
- Abandonar grupo y salir de instancia, disponible cuando las dos acciones anteriores son válidas. Estas tres acciones son independientes de Resetear instancia y de las herramientas de líder.
- `Estado del grupo` no es una entrada seleccionable del menú. Cuando están activados el modo debug y su opción específica en LAM, EZOTools escribe automáticamente en Log Viewer una captura previa del grupo y la instancia antes de ejecutar un comando de Actividades de grupo; el informe no se escribe en el chat.
- Submenú de viaje a trials en veterano, con "Última trial" y la lista centralizada actual de trials.
- Cambio de dificultad de instancia entre Normal y Veterano cuando ESO lo permite.
- El cambio de dificultad se oculta dentro de una instancia porque ESO no permite cambiarla ahí.
- Ayuda experimental de reset, disponible únicamente para un líder agrupado dentro de una trial reconocida. Las zonas no compatibles y las mazmorras no muestran la acción y nunca alcanzan el paso de disband.
- El reset captura y vuelve a verificar inmediatamente el grupo actual, la trial detectada, el índice estable de zona y el modo Normal/Veterano; disbandea; viaja a una casa puente configurada; espera; verifica el modo capturado; vuelve a la misma trial; y solicita invitaciones para los miembros capturados.
- La ventana movible y local del líder es un panel HUD estructurado con estilo nativo, no un bloque de texto multilínea. Presenta actividad y modo, barra de progreso de seis fases, acción y temporizador actuales, contadores de grupo alineados, avisos y una fila por miembro capturado con estado por color. Cada fila alinea verticalmente en regiones estables la marca, la cuenta y el estado relevante. Un miembro fuera del grupo muestra su estado en el proceso y las invitaciones enviadas; un miembro confirmado en el grupo omite ese histórico y muestra en su lugar si está en la misma instancia que el líder. El ancho, el espaciado y el ritmo de las filas se adaptan a rosters pequeños, medios y completos de trial; los puntos nativos de estado evitan que las filas informativas parezcan casillas pulsables. Los nombres de cuenta y textos de estado largos usan elipsis en vez de deformar la composición. Los jugadores presentes después del snapshot se identifican como `no capturados` en vez del ambiguo `adicionales`. El panel también muestra respuestas de ESO cuando pueden asociarse a una cuenta capturada y el estado definitivo de incorporación obtenido del grupo actual.
- Tras finalizar los intentos configurados, la ventana continúa monitorizando a los miembros capturados pendientes hasta que entren. Volver a ejecutar Resetear instancia reanuda la fase incompleta actual y todas las posteriores: se solicita otra vez el viaje interrumpido a casa o a la trial, mientras que una fase 6 incompleta reinicia su pasada de invitaciones. Una fase con miembros pendientes no se confunde con un reset nuevo.
- Cuando no queda ningún miembro capturado pendiente, el panel deja de mostrar temporizadores de fase y presenta `RESET COMPLETADO` con un mensaje final que indica que las acciones del reset han terminado y el líder espera entrar en la trial. Solo este estado posterior al regreso ya completado puede sustituirse mediante un reset nuevo confirmado explícitamente desde un contexto válido de líder agrupado dentro de una trial. Las fases 1-5 y una fase 6 incompleta se conservan para reanudarlas.
- Puede ordenarse un reset durante el combate. Primero se disbandea el grupo y después la fase de viaje espera a que el líder salga de combate antes de solicitar el salto a la casa puente.
- Durante un reset no interrumpido, cargar el vestíbulo de la trial no cierra la sesión. El panel se limpia cuando ESO informa de que la trial está en curso y el líder ya no está en el área de preparación; el evento de inicio queda como fallback cuando la consulta del vestíbulo no está disponible. Un disband independiente posterior lo limpia por separado.
- Las invitaciones a miembros capturados están activadas por defecto. Su estado se captura al iniciar, se muestra durante las fases y, si están desactivadas, se advierte en la confirmación.
- Las fases son estrictas: disband, llegada a casa, espera, dificultad capturada, trial objetivo e incorporaciones se comprueban por separado. Un salto rechazado o una dificultad no confirmada interrumpen el proceso en vez de continuar con supuestos inseguros.
- Un reset interrumpido puede reanudarse durante la sesión actual de la interfaz. Primero se comprueba si el líder ya está en una casa o de vuelta en la trial objetivo antes de solicitar otro viaje. Si el líder se mueve antes o durante la solicitud de regreso, EZOTools conserva la fase 5 y pide al líder que se detenga y vuelva a ejecutar Resetear instancia; así se repite solo la fase de regreso, sin rehacer el snapshot, el disband, el viaje a casa ni la espera. El snapshot no persiste tras `/reloadui` o cerrar sesión.
- La fase 1 de snapshot y la fase 2 de disband pueden completarse en el mismo frame, por lo que la fase 3 puede ser el primer estado visible; no se añaden retrasos artificiales para mostrar fases breves.
- Disbandear grupo solo está disponible para el líder cuando ESO expone `GroupDisband()` sin requerir votación.
- Tras solicitar el disband, el addon comprueba durante varios segundos el estado real del grupo e informa de si ESO confirmó que el líder dejó de estar agrupado.
- Un disband independiente confirmado elimina cualquier sesión de reset conservada y oculta su panel de estado. El disband interno del propio reset queda marcado explícitamente y no elimina el proceso en curso.
- Después de que el reset haya reconstruido un grupo, abandonar o disbandear ese grupo también elimina la sesión conservada. Tras el regreso del líder, salir de la trial capturada también la elimina. El viaje a la casa puente y el regreso obligatorio no activan ninguna de estas limpiezas.
- El roster capturado se mantiene como objetivo del reset. Un miembro capturado que después salga voluntariamente o sea expulsado queda registrado y excluido de nuevos reintentos automáticos. Los jugadores que entren después de la captura aparecen como miembros actuales adicionales, pero no se añaden silenciosamente al objetivo original del reset.
- La confirmación configurable protege reset y disband. Teclado y mando usan sus rutas nativas, solo puede haber una confirmación peligrosa pendiente y una segunda acción no puede sustituir su callback. Con debug activo, Log Viewer registra el despacho desde el menú lateral, la solicitud de confirmación, el diálogo visible, el resultado aceptado/cancelado, la ejecución del callback y el resultado observable de la acción.
- Keybinds asignables para Actividades de grupo, reset de instancia y disband de grupo. Los valores por defecto continúan la secuencia existente: `Ctrl+Alt+Num2`, `Ctrl+Alt+Num3` y `Ctrl+Alt+Num4`.

La lista de trials vive en `modules/raid_leader_activity_catalog.lua`. Centraliza los nombres y alias de trials implementadas. Los campos para IDs como `zoneId`, `activityId` y `fastTravelNodeId` quedan reservados para datos verificados.

### Autoinvitación de grupo

- Autoinvitación opcional por chat, desactivada por defecto y configurada en LAM.
- Admite varias palabras de invitación simultáneas separadas por espacios, líneas, comas o punto y coma. Cada palabra configurada es una alternativa independiente: basta con que coincida cualquiera de ellas.
- La coincidencia no distingue mayúsculas y omite los signos que rodean el texto. Por ejemplo, `+trial1` coincide con la palabra configurada `trial1`, mientras que un texto parcial dentro de una palabra mayor no coincide.
- Escucha mensajes de jugadores en los canales decir, gritar, zona, zona por idioma, susurro y gremio. El sistema, los PNJ y el chat de grupo no generan invitaciones.
- Solo solicita la invitación cuando estás solo o eres el líder actual, omite al propio jugador y a las cuentas ya detectadas en el grupo, y bloquea solicitudes repetidas a la misma cuenta durante 15 segundos.
- Con debug activo, las coincidencias y la decisión de invitación se escriben en Log Viewer sin copiar el texto del mensaje de chat.

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

Los comandos de diagnóstico incluyen estado de ejecución, información de gremios, comprobaciones de texturas/iconos, previsualización de diseño de iconos laterales, estado debug de comida, diagnóstico de vivienda y una vista previa aislada del panel de reset con 11 miembros. Con el modo debug activo, usa `/ezo debug resetpanel` para el diseño actual de 520 px, `/ezo debug resetpanel 460` para comparar otro ancho entre 420 y 620 px y `/ezo debug resetpanel off` para cerrarlo. Esta vista previa nunca inicia ni modifica una sesión de reset. Cambiar la opción de LAM para mover la ventana también cierra este preview independiente antes de mostrar, restaurar u ocultar el panel real del reset, por lo que las dos instancias no pueden permanecer visibles a la vez. Los informes técnicos largos están pensados para LibDebugLogger y DebugLogViewer, no para llenar el chat normal.

## Límites de seguridad

EZOTools no es un addon de automatización para combate ni decisiones de juego.

- No juega el combate, no elige rotaciones, no selecciona enemigos y no reacciona a mecánicas por ti.
- No encola, expulsa, rellena raids ni toma decisiones de combate o juego.
- La autoinvitación por chat solo funciona después de activarla expresamente y cuando coincide una palabra configurada. No puede aceptar invitaciones, evitar las restricciones de liderazgo o tamaño del grupo ni garantizar que ESO entregue la solicitud; usa palabras distintivas porque cualquier participante de un canal compatible puede activar una coincidencia.
- La ayuda de reset es una acción explícita del líder disponible solo dentro de una trial reconocida. Las mazmorras y zonas no compatibles no son objetivos de reset y la ayuda no se ejecuta pasivamente.
- Los keybinds de reset de instancia y disband de grupo son comandos explícitos y respetan las mismas comprobaciones de líder/API que las entradas del menú.
- La confirmación de reset y disband está activada por defecto, solo permite una acción peligrosa pendiente y puede desactivarse en ajustes.
- La ventana de estado del reset es local para el líder que inició el proceso. Todavía no envía estado a otros jugadores.
- El viaje de vuelta solo funciona para una trial emparejada con el catálogo verificado. El modo Normal/Veterano capturado debe confirmarse antes de viajar o el proceso se interrumpe.
- El viaje de regreso no se reintenta automáticamente mientras el líder se mueve. La fase conservada debe reanudarse de forma explícita mediante la acción Resetear instancia existente cuando el líder se haya detenido.
- Los contadores de invitación registran solicitudes a la API, no una entrega garantizada. Un miembro solo se considera incorporado cuando lo confirma el grupo actual o el evento de incorporación.
- Un miembro posterior se informa como adicional en vez de asumir que sustituye a uno capturado. EZOTools no decide sustituciones, expulsa jugadores ni invita a ese miembro adicional como parte del roster guardado del reset.
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
- Diagnóstico automático del estado del grupo antes de las acciones de Actividades de grupo, disponible solo mientras el modo debug global está activado.
- Activación de autoinvitación por chat y palabras de invitación alternativas simultáneas.
- Los ajustes de reset de instancia sitúan primero la activación de invitaciones a miembros capturados, seguida de confirmación, casa puente, movimiento de la ventana de estado con una vista temporal completa de colocación para 11 miembros, tiempo de espera, retraso de invitaciones y reintentos.
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
- Si pruebas reset de instancia, usa primero un grupo pequeño controlado. Verifica espera en combate, viaje a casa, dificultad capturada, vuelta, solicitudes, respuestas, salidas o expulsiones, entradas adicionales e incorporación al grupo antes de una raid organizada.
- Durante la fase de regreso, prueba tanto iniciar el viaje mientras ya te mueves como moverte durante el casteo. Comprueba que se conserva la fase 5 con un mensaje de acción específico; después detente y verifica que Resetear instancia repite solo el viaje de regreso.
- Mientras la fase 6 aún tenga miembros pendientes, ejecuta otra vez Resetear instancia y comprueba que la confirmación de reanudación reinicia las invitaciones sin sustituir el snapshot. Cuando todos los miembros capturados estén agrupados, verifica que el panel muestre `RESET COMPLETADO` sin temporizadores de fase y que un reset posterior confirmado explícitamente pueda crear un snapshot nuevo.
- Prueba Abandonar grupo tanto como líder como sin serlo, Salir de instancia cuando ESO permita la salida inmediata y Abandonar grupo y salir de instancia cuando se cumplan ambas condiciones. Comprueba que estas entradas aparezcan en Actividades de grupo y no en el panel principal, usando ratón, menú de teclado y menú de mando.
- Comprueba que `Estado del grupo` ya no aparezca en Actividades de grupo. Con el modo debug y el registro automático del estado activados, ejecuta cada acción de grupo disponible y verifica que Log Viewer reciba una única captura previa con el valor `action` correspondiente; desactiva la opción LAM y comprueba que dejen de generarse esas capturas.
- Durante esa prueba, verifica que el panel se oculte en inventario/menús, permanezca visible en el vestíbulo y se limpie normalmente cuando el líder abandone el área de preparación.
- Verifica el panel estructurado del reset con uno, cuatro y once miembros capturados (el líder no figura como miembro capturado). Al activar en LAM la opción de mover, debe aparecer la vista completa de colocación con once miembros; al desactivarla debe restaurarse el estado real del reset u ocultarse el panel. Comprueba que las métricas queden centradas y alineadas, que los nombres no se superpongan al estado de invitación ni de ubicación, que la barra de seis fases y su contador central sean legibles, que los avisos amplíen limpiamente el panel y que cambiar entre teclado y mando adapte la tipografía nativa sin mover ni redimensionar otras interfaces. Para miembros agrupados, verifica los estados verde de misma instancia y amarillo de instancia distinta; los miembros sin `unitTag` actual deben permanecer en gris y con ubicación desconocida.
- Después de una sesión de reset completada o conservada, forma un grupo controlado y ejecuta Disbandear grupo de manera independiente. Verifica que ESO confirme el disband, que el panel se cierre y que Log Viewer registre `reset-session-cleared` con el modo debug activado.
- Después de que un reset reconstruya el grupo, prueba Abandonar grupo y Disbandear grupo de forma independiente. Comprueba que ambas acciones cierren el panel conservado; después repite el proceso y sal de la trial capturada tras el regreso para verificar que el cambio de zona también lo cierre sin afectar a las fases de la casa puente.
- Para la autoinvitación, configura al menos dos palabras, actívala y prueba desde otra cuenta mensajes exactos, en mayúsculas, con `+palabra` y con la misma secuencia dentro de una palabra mayor en chat de gremio o susurro. Comprueba que solo inviten las coincidencias válidas, que un jugador no líder no invite y que un mensaje repetido durante 15 segundos no genere otra solicitud. Con debug activado, verifica las fases `initialization`, `keyword-detected`, `keyword-evaluated`, `invite-requested` y, cuando exista, `invite-response` en Log Viewer. Desactiva la opción y comprueba que los mensajes coincidentes dejen de invitar.
- Verifica que Resetear instancia no esté disponible fuera de una trial reconocida y que allí no disbandee el grupo.

## Componente de UI reutilizable

La ventana de reset utiliza el panel de estado genérico documentado en [docs/status-panel.md](docs/status-panel.md). El componente es independiente de la lógica de grupos y trials e incluye un modo de acciones opcional, activado expresamente, para consumidores con ratón, teclado y mando.

## Metadatos del repositorio

GitHub About debe describir el addon actual, no solo su función original de viaje. La metadata pública actual debe usar Discord como enlace de soporte/homepage y topics como `lua`, `gamepad`, `elder-scrolls-online`, `esoui` y `eso-addon`.

## Licencia

MIT. Ver [LICENSE](LICENSE).

Desarrollado y mantenido por Zuriplayer.
