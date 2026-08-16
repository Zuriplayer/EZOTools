# EZOTools

EZOTools es un addon beta de calidad de vida para *The Elder Scrolls Online* en PC. Añade un pequeño overlay en pantalla y paneles de comandos compatibles con teclado, ratón y mando para viajes, acciones de grupo, utilidades, mantenimiento y diagnóstico.

¿Prefieres inglés? Lee el [README en inglés](README.md).
Soporte, errores y sugerencias: https://discord.gg/FtP4KapGua

## Estado

Versión actual: **2.0.94**.

Este addon está en beta pública. Las funciones implementadas son utilizables, pero algunas herramientas nuevas de grupo y trials siguen siendo experimentales y conviene probarlas con cuidado antes de depender de ellas en raids organizadas.

## Descargas

| Canal | Versión | Recomendado para |
| --- | --- | --- |
| Beta estable | [2.0.0](https://github.com/Zuriplayer/EZOTools/releases/tag/v2.0.0) | Uso habitual |
| Beta temprana para testers | [2.0.72-beta.1](https://github.com/Zuriplayer/EZOTools/releases/tag/v2.0.72-beta.1) | Probar los últimos cambios de grupos, reset de instancia, idioma compartido y ajustes |

## Requisitos

- The Elder Scrolls Online para PC.
- [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu.html), obligatorio.
- Opcional: LibChatMessage para mensajes de chat más limpios.
- Opcional: LibDebugLogger y DebugLogViewer para informes técnicos de diagnóstico. Los diagnósticos automáticos se omiten silenciosamente cuando no hay logger y nunca pasan al chat; un comando `/ezo debug` solicitado expresamente puede mostrar un único aviso de disponibilidad.
- Opcional: LibSlashCommander para un mejor registro de comandos slash.
- Opcional: EZOCore con LibGroupBroadcast 2.0.0 para compartir de forma compacta e informativa el estado de Actividades de grupo entre jugadores que estén agrupados en ese momento. EZOTools nunca es propietario ni registra por sí mismo el protocolo de grupo.

## Funciones principales

### Overlay HUD

- Overlay movible de EZOTools en pantalla.
- Bloqueo opcional, escala, texto de nombre de jugador, color del texto y tamaño del texto.
- Opción para ocultarlo durante combate.
- Simulación opcional de estilo gamepad solo para el overlay.
- Tooltips contextuales para el overlay y los iconos laterales.
- Etiqueta del gremio representado, color configurable para esa etiqueta y opción para ocultar el texto "Sin gremio".
- Modo guild opcional para Hojablanca, Fuego y Sombras de Lorkhan. Usa la imagen de la guild admitida que esté representada en C.
- Widgets laterales de aviso para Gemas de alma llenas y kits de reparación bajos.
- Widgets laterales para estado de comida/bebida, reparación de armadura, recarga de armas y sus previsualizaciones.

### Panel de comandos

El panel principal de comandos está disponible desde el keybind del addon, el flujo de mando y el overlay/menú contextual cuando corresponde. Actualmente incluye:

- Viajar a tu casa principal.
- Viajar a las casas configuradas de artesanía y secundaria.
- Saltar al líder del grupo cuando ESO lo permite y tú no eres el líder.
- Salir de la instancia actual cuando ESO informa de que se permite la salida inmediata.
- Abandonar el grupo, o abandonar el grupo y salir de la instancia actual a la vez, cuando ESO informa de que esas acciones están disponibles.
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
- El indicador de comida/bebida lee el efecto activo y su `abilityId` nativo exacto. Obtiene el ID desde los enlaces de provisiones recordadas y, como respaldo, aprende el ID real del efecto al consumirlas; los ID aprendidos se conservan tras volver a entrar. Una provisión ya activa en una instalación limpia puede requerir un consumo antes de ser reconocida.
- Las entradas recientes de comida/bebida siguen visibles pero deshabilitadas cuando el objeto recordado ya no está en tu inventario.
- Historial de casas propias.
- Historial de casas de otros jugadores.

### Actividades de grupo

El panel Actividades de grupo es un menú separado para acciones relacionadas con dungeons, trials y grupo:

- Las acciones válidas de raid leader aparecen primero: Disbandear grupo, Resetear instancia y después el control de dificultad. Disbandear grupo y Resetear instancia se omiten por completo cuando el jugador actual no es líder; no se muestran como filas desactivadas.
- Abandonar grupo, disponible para cualquier jugador agrupado independientemente de si es líder.
- Abandonar grupo, Salir de instancia y Abandonar grupo y salir de instancia están disponibles desde el panel principal de comandos cuando ESO lo permite, incluso durante el combate. Abandonar grupo y Abandonar grupo y salir de instancia también siguen disponibles desde Actividades de grupo. Intencionadamente no se duplican en el panel de ajustes de EZOTools. Estas acciones rápidas son independientes de Resetear instancia y de las herramientas de líder.
- `Estado del grupo` no es una entrada seleccionable del menú. Cuando están activados el modo debug y su opción específica en LAM, EZOTools escribe automáticamente en Log Viewer una captura previa del grupo y la instancia antes de ejecutar un comando de Actividades de grupo; el informe no se escribe en el chat.
- Cualquier jugador agrupado, incluido el líder, puede abrir bajo demanda "Información del grupo" desde Actividades de grupo. Reutiliza el mismo componente estructurado que la ventana de reset del líder sin iniciar ni modificar un reset. Su vista inactiva es la misma para todos los miembros: zona del líder, dificultad efectiva del grupo, tamaño, estado del transporte EZOCore y roster actual con el líder primero y la zona informada localmente para cada jugador. Cuando el cliente local posee una sesión de reset, este comando muestra el panel operativo de reset ya existente en vez de abrir un segundo panel de información del grupo. Los miembros pueden recibir el tipo de actividad, destino estable, etapa y resultado del líder mediante clientes compatibles de EZOCore y LibGroupBroadcast. Cuando un reset anunciado disuelve intencionadamente el grupo, cada cliente compatible conserva la sesión y el roster observados localmente para que Información del grupo siga disponible: la zona del jugador local y la recepción de la invitación del líder para reagruparse se actualizan localmente, mientras los jugadores ausentes se muestran expresamente sin grupo y con su última ubicación conocida.
- Submenú de viaje a trials en veterano, con "Última trial" y la lista centralizada actual de trials.
- Cambio de dificultad de instancia entre Normal y Veterano cuando ESO lo permite.
- El cambio de dificultad se oculta dentro de una instancia porque ESO no permite cambiarla ahí.
- Ayuda experimental de reset, disponible únicamente para un líder agrupado cuya zona actual coincida con una trial reconocida. El hall, el interior de la trial activa, los wipes y el último boss ya completado utilizan el mismo flujo completo; el progreso de la raid no cambia la disponibilidad ni omite fases. Las zonas no compatibles y las mazmorras no muestran la acción y nunca alcanzan el paso de disband.
- El reset captura y vuelve a verificar inmediatamente el grupo actual, la trial detectada, el índice estable de zona y el modo Normal/Veterano; disbandea; alcanza el destino puente seleccionado; espera; verifica el modo capturado; vuelve a la misma trial; y solicita invitaciones para los miembros capturados. El destino puede ser la casa principal, de artesanía o secundaria, o `Salir de instancia` para cuentas sin una casa configurada.
- La ventana movible y local del líder es un panel HUD estructurado con estilo nativo, no un bloque de texto multilínea. Presenta actividad y modo, barra de progreso de seis fases, acción y temporizador actuales, contadores de grupo alineados, avisos y una fila por miembro capturado con estado por color. Cada fila alinea verticalmente en regiones estables la marca, la cuenta y el estado relevante. Un miembro fuera del grupo muestra su estado en el proceso y las invitaciones enviadas; un miembro confirmado en el grupo omite ese histórico y muestra en su lugar si está en la misma instancia que el líder. El ancho, el espaciado y el ritmo de las filas se adaptan a rosters pequeños, medios y completos de trial; los puntos nativos de estado evitan que las filas informativas parezcan casillas pulsables. Los nombres de cuenta y textos de estado largos usan elipsis en vez de deformar la composición. Los jugadores presentes después del snapshot se identifican como `no capturados` en vez del ambiguo `adicionales`. El panel también muestra respuestas de ESO cuando pueden asociarse a una cuenta capturada y el estado definitivo de incorporación obtenido del grupo actual.
- Tras finalizar los intentos configurados, la ventana continúa monitorizando a los miembros capturados pendientes hasta que entren. Volver a ejecutar Resetear instancia reanuda la fase incompleta actual y todas las posteriores: se solicita otra vez el desplazamiento interrumpido al destino puente o a la trial, mientras que una fase 6 incompleta reinicia su pasada de invitaciones. Una fase con miembros pendientes no se confunde con un reset nuevo.
- Cuando no queda ningún miembro capturado pendiente, el panel deja de mostrar temporizadores de fase y presenta `RESET COMPLETADO` con un mensaje final que indica que las acciones del reset han terminado y el líder espera entrar en la trial. Solo este estado posterior al regreso ya completado puede sustituirse mediante un reset nuevo confirmado explícitamente desde un contexto válido de líder agrupado dentro de una trial. Las fases 1-5 y una fase 6 incompleta se conservan para reanudarlas.
- Puede ordenarse un reset durante el combate. Primero se disbandea el grupo y después la fase puente espera a que el líder salga de combate antes de solicitar el salto a la casa elegida o la salida inmediata de la instancia.
- Durante un reset no interrumpido, cargar el vestíbulo de la trial no cierra la sesión. El panel se limpia cuando ESO informa de que la trial está en curso y el líder ya no está en el área de preparación; el evento de inicio queda como fallback cuando la consulta del vestíbulo no está disponible. Un disband independiente posterior lo limpia por separado.
- Reset de instancia está habilitado por defecto mediante una opción maestra de LAM. Al desactivarla no pueden iniciarse resets nuevos ni retenidos desde el menú o el keybind, mientras que una sesión existente todavía puede cancelarse de forma segura. Los miembros capturados se invitan siempre como parte del flujo de reset; las invitaciones ya no son un paso opcional independiente.
- Las fases son estrictas: disband, confirmación del destino puente elegido, espera, dificultad capturada, trial objetivo e incorporaciones se comprueban por separado. Con `Salir de instancia`, la espera solo empieza cuando el líder ya no está en la trial capturada. Un salto rechazado, una salida inmediata denegada o una dificultad no confirmada interrumpen el proceso en vez de continuar con supuestos inseguros.
- Un reset interrumpido puede reanudarse durante la sesión actual de la interfaz. Resetear instancia permanece visible en Actividades de grupo para esa sesión guardada aunque el disband interno haya dejado solo al líder original; esta excepción solo reanuda la ejecución capturada y no muestra las demás acciones exclusivas de líder. Los cronómetros interrumpidos permanecen congelados hasta la reanudación. Primero se comprueba si se alcanzó la casa elegida, si se abandonó la trial capturada cuando está seleccionado `Salir de instancia`, o si el líder ya está de vuelta en la trial objetivo antes de solicitar otra acción. Si el líder se mueve antes o durante la solicitud de regreso, EZOTools conserva la fase 5 y pide al líder que se detenga y vuelva a ejecutar Resetear instancia; así se repite solo la fase de regreso, sin rehacer el snapshot, el disband, el destino puente ni la espera. El snapshot no persiste tras `/reloadui` o cerrar sesión.
- La fase 1 de snapshot y la fase 2 de disband pueden completarse en el mismo frame, por lo que la fase 3 puede ser el primer estado visible; no se añaden retrasos artificiales para mostrar fases breves.
- Disbandear grupo solo está disponible para el líder cuando ESO expone `GroupDisband()` sin requerir votación.
- Tras solicitar el disband, el addon comprueba durante varios segundos el estado real del grupo e informa de si ESO confirmó que el líder dejó de estar agrupado.
- Un disband independiente confirmado elimina cualquier sesión de reset conservada y oculta su panel de estado. El disband interno del propio reset queda marcado explícitamente y no elimina el proceso en curso.
- Después de que el reset haya reconstruido un grupo, abandonar o disbandear ese grupo también elimina la sesión conservada. Tras el regreso del líder, salir de la trial capturada también la elimina. La transición al destino puente elegido y el regreso obligatorio no activan ninguna de estas limpiezas.
- El roster capturado se mantiene como objetivo del reset. Un miembro capturado que después salga voluntariamente o sea expulsado queda registrado y excluido de nuevos reintentos automáticos. Los jugadores que entren después de la captura aparecen como miembros actuales adicionales, pero no se añaden silenciosamente al objetivo original del reset.
- La confirmación configurable protege reset y disband. En teclado vincula expresamente la `E`/acción primaria mostrada con confirmar y la acción negativa del diálogo con cancelar; el mando usa su equivalente nativo. Solo puede haber una confirmación peligrosa pendiente y una segunda acción no puede sustituir su callback. Con debug activo, Log Viewer registra el despacho desde el menú lateral, la solicitud de confirmación, el diálogo visible, el resultado aceptado/cancelado, la ejecución del callback y el resultado observable de la acción.
- El panel de reset es la vista operativa en tiempo real. Con debug activo, Log Viewer recibe entradas `Info` agrupadas para el inicio, los cierres de fase, la reanudación y el cierre de sesión, además de un `Warning` cuando la ejecución se interrumpe o rechaza. Los eventos individuales de grupo, viaje e invitación se acumulan en esos resúmenes en vez de generar cada uno un informe completo repetido. El progreso normal de inicio, viaje, espera, reanudación e invitaciones no se duplica en el chat; el chat queda reservado para rechazos previos al inicio y el único aviso accionable de interrupción.
- Mientras el raid leader está agrupado, los cambios del ciclo de reset se ofrecen a EZOCore como actualizaciones compactas e informativas de `activityState`. Solo EZOCore es propietario del protocolo `EZO_CORE_GROUP_V2` (ID temporal de prueba beta `511`) y del evento de solicitud `EZO_CORE_GROUP_REQUEST_V1` (evento temporal de prueba beta `39`). Las actualizaciones se deduplican y se refrescan con un intervalo limitado antes de que venza su TTL. Como LibGroupBroadcast está limitado al grupo, no puede entregarse ninguna actualización del líder mientras el disband del reset haya dejado a los jugadores fuera de un grupo común. Durante ese intervalo, EZOTools conserva únicamente el estado y el roster ya observados localmente, actualiza la zona actual del propio jugador y la invitación de reagrupación recibida, y marca las demás ubicaciones como últimas conocidas. El intercambio en vivo del líder se reanuda para cada miembro conforme se reconstruye el grupo.
- Los miembros pueden activar expresamente una única solicitud automática de viaje por cada sesión de actividad recibida. Después de que el jugador acepte manualmente la invitación de grupo, EZOTools exige un estado validado del líder actual, un objetivo compatible de trial/mazmorra/arena, una etapa de espera de miembros o completada y que ESO confirme que el líder está en otra instancia y que se permite viajar hasta él. El ajuste está desactivado por defecto y nunca acepta por sí mismo la invitación de grupo.
- Mientras exista cualquier sesión de reset activa o retenida, `Cancelar reset de instancia` es la primera entrada de Actividades de grupo. Usa la confirmación nativa compartida, detiene el seguimiento del addon, desregistra los eventos del reset y cierra el panel. No puede retirar invitaciones ya enviadas ni un viaje que ESO ya haya aceptado.
- Inmediatamente antes del disband del reset, EZOTools guarda en las SavedVariables de cuenta una plantilla compacta de la última actividad: nombres de cuenta verificados y capturados, clave/nombre de trial, índice de zona y dificultad. Cuando la sesión de reset se cancela o limpia, `Iniciar último grupo e instancia` puede invitar a los miembros guardados que falten y reutilizar después el viaje existente a la trial con la dificultad memorizada. La acción no está disponible mientras exista otra sesión de reset ni cuando el jugador está agrupado bajo otro líder.
- Keybinds asignables para Actividades de grupo, reset de instancia y disband de grupo. Los valores por defecto continúan la secuencia existente: `Ctrl+Alt+Num2`, `Ctrl+Alt+Num3` y `Ctrl+Alt+Num4`.
- La pantalla Controles de ESO agrupa todas las acciones de EZOTools bajo `EZO AddOns > EZOTools`; el cambio es solo de presentación y no reasigna teclas.

La lista de trials vive en `modules/raid_leader_activity_catalog.lua`. Centraliza los nombres y alias de trials implementadas. Los campos para IDs como `zoneId`, `activityId` y `fastTravelNodeId` quedan reservados para datos verificados.

### Autoinvitación de grupo

- Autoinvitación opcional por chat, desactivada por defecto y configurada en LAM.
- Admite varias palabras de invitación simultáneas separadas por espacios, líneas, comas o punto y coma. Cada palabra configurada es una alternativa independiente: basta con que coincida cualquiera de ellas.
- La coincidencia no distingue mayúsculas y omite los signos que rodean el texto. Por ejemplo, `+trial1` coincide con la palabra configurada `trial1`, mientras que un texto parcial dentro de una palabra mayor no coincide.
- Escucha mensajes de jugadores en los canales decir, gritar, zona, zona por idioma, susurro y gremio. El sistema, los PNJ y el chat de grupo no generan invitaciones.
- Solo solicita la invitación cuando estás solo o eres el líder actual, omite al propio jugador y a las cuentas ya detectadas en el grupo, y bloquea solicitudes repetidas a la misma cuenta durante 15 segundos.
- Con debug activo, las coincidencias y la decisión de invitación se escriben en Log Viewer sin copiar el texto del mensaje de chat.

### Casas manuales y modo guild

- Los nombres de cuenta manuales para la casa primaria de artesanía y la casa secundaria son el modo estable por defecto.
- El modo manual mantiene siempre el logo de EZOTools y usa esos dos valores fijos de casas.
- Mientras visitas una casa en modo manual, los dos botones de casa actual pueden guardar esa casa exacta y su propietario como casa primaria de artesanía o destino secundario. Guardarla no inicia ningún viaje.
- Las acciones de viaje y la preparación del reset regresan a la casa exacta capturada. Editar manualmente un nombre de cuenta borra el ID de casa capturado y conserva el comportamiento anterior de viajar a la casa principal de esa cuenta.
- Los miembros de Hojablanca, Fuego o Sombras de Lorkhan reciben un apartado separado de modo guild en Ajustes.
- El modo guild no tiene selector manual de guild. Usa la imagen y las casas integradas únicamente para la guild admitida que esté representada en C.
- Cambiar la guild representada en C actualiza automáticamente la imagen, las casas efectivas y los valores deshabilitados de LAM cuando el sondeo de guild representada detecta el cambio (en un máximo de cinco segundos).
- Mientras el modo guild está activo, los campos de casas manuales siguen visibles y deshabilitados mientras muestran las casas efectivas de la guild; sus valores manuales permanecen guardados y se recuperan sin cambios al volver al modo manual.
- Si C no apunta a una guild admitida, EZOTools avisa al jugador y vuelve de forma segura al logo de EZOTools y a las casas manuales.
- Los valores activos de artesanía/secundaria se muestran en el tooltip del apartado Casas manuales.

### Mantenimiento

- Umbral configurable de reparación de equipo equipado.
- Umbral configurable de recarga de armas.
- Alerta configurable de kits de reparación bajos.
- Alerta configurable de Gemas de alma llenas bajas.
- Las entradas de reparación/recarga solo aparecen cuando hacen falta.

### Idioma

- Localización en inglés y español.
- Cuando una versión compatible de EZOCore ofrece gestión central del idioma de la familia EZO, EZOTools puede heredar ese ajuste compartido.
- Sin EZOCore, el modo heredado cae al idioma del cliente de ESO.
- Los modos local automático y manual siguen disponibles en ajustes.

### Comandos slash y diagnóstico

Comandos registrados:

- `/ezo`
- `/ezotools`
- `/ezo help`
- `/ezo status`
- `/ezo about`
- `/ezo debug ...` cuando el modo debug está activado.

Los comandos de diagnóstico incluyen estado de ejecución, información de gremios, comprobaciones de texturas/iconos, previsualización de diseño de iconos laterales, estado debug de comida, diagnóstico de vivienda, una vista previa aislada del panel de reset con 11 miembros y una simulación del panel de Actividades de grupo para miembros. Con el modo debug activo, usa `/ezo debug resetpanel` para el diseño actual de 520 px, `/ezo debug resetpanel 460` para comparar otro ancho entre 420 y 620 px y `/ezo debug resetpanel off` para cerrarlo. Usa `/ezo debug groupactivity`, `/ezo debug groupactivity staging`, `/ezo debug groupactivity returning` o `/ezo debug groupactivity complete` para previsualizar estados locales del panel de miembro sin tráfico de grupo; `/ezo debug groupactivity off` lo cierra. Estas vistas previas nunca inician ni modifican una sesión de reset. Cambiar la opción de LAM para mover la ventana también cierra el preview independiente del reset antes de mostrar, restaurar u ocultar el panel real, por lo que las dos instancias de panel de reset no pueden permanecer visibles a la vez. Los informes técnicos usan los niveles nativos `Info`, `Warning`, `Error` y `Debug` de LibDebugLogger según corresponda y nunca pasan automáticamente al chat normal.

## Límites de seguridad

EZOTools no es un addon de automatización para combate ni decisiones de juego.

- No juega el combate, no elige rotaciones, no selecciona enemigos y no reacciona a mecánicas por ti.
- No encola, expulsa, rellena raids ni toma decisiones de combate o juego.
- La autoinvitación por chat solo funciona después de activarla expresamente y cuando coincide una palabra configurada. No puede aceptar invitaciones, evitar las restricciones de liderazgo o tamaño del grupo ni garantizar que ESO entregue la solicitud; usa palabras distintivas porque cualquier participante de un canal compatible puede activar una coincidencia.
- La ayuda de reset es una acción explícita del líder disponible solo dentro de una trial reconocida. Las mazmorras y zonas no compatibles no son objetivos de reset y la ayuda no se ejecuta pasivamente.
- Los keybinds de reset de instancia y disband de grupo son comandos explícitos y respetan las mismas comprobaciones de líder/API que las entradas del menú.
- La confirmación de reset y disband está activada por defecto, solo permite una acción peligrosa pendiente y puede desactivarse en ajustes.
- La ventana detallada del reset sigue siendo local para el líder que inició el proceso. EZOCore recibe únicamente el tipo de actividad compacto, etapa, resultado, enum Normal/Veterano, progreso real de fase, recuentos previstos/pendientes, sesión, clave del objetivo y TTL. No se transmiten entradas del roster, nombres de cuenta, texto de estado localizado, temporizadores ni historial de invitaciones. Cada miembro solo puede detectar una invitación recibida por su propio cliente; mientras no exista un transporte de grupo común no puede confirmar invitaciones ni ubicaciones actuales de los demás antiguos miembros.
- El panel de actividad de grupo para miembros es informativo. El estado recibido no puede ejecutar órdenes remotas, aceptar invitaciones ni modificar el grupo. EZOCore no transmite entradas del roster; el panel crea y conserva su roster únicamente a partir de los miembros observados localmente antes del disband. El ajuste opcional e independiente de viaje de miembros es una reacción local ante estado validado del líder, no una orden remota: está desactivado por defecto, realiza como máximo una solicitud de salto por sesión de actividad, no manipula el aviso nativo de viaje de ESO y no puede garantizar que el servidor complete el desplazamiento solicitado.
- La plantilla de última actividad es información local de cuenta y contiene nombres de usuario de ESO guardados. Solo se actualiza desde un snapshot verificado del reset y únicamente se utiliza tras confirmar expresamente `Iniciar último grupo e instancia`; nunca invita ni viaja automáticamente al iniciar sesión o recargar.
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

Con EZOCore activo, abre el panel completo desde Ajustes > EZO > EZOTools o desde el propio EZOTools. El panel no se duplica en la lista estándar de Addons de ESO. El overlay y la ventana de estado del reset se registran por separado en el modo compartido de disposición de interfaz; al cerrar Settings se vuelve a HUD/HUD_UI y las previsualizaciones activas permanecen movibles. Sin EZOCore, los mismos controles siguen disponibles mediante el fallback independiente de LibAddonMenu. Todas las cabeceras de sección usan el mismo icono de información morado; pasa el ratón sobre la cabecera para leer su explicación general sin ocupar espacio permanente en el panel. La ayuda de un ajuste concreto aparece al pasar el ratón sobre ese mismo ajuste. Los ajustes maestros refrescan sus controles dependientes de inmediato tanto dentro de EZOCore como en el panel independiente de LibAddonMenu. Los ajustes actuales cubren:

- Idioma.
- Activación y bloqueo del overlay.
- Escala del overlay.
- Texto del overlay.
- Color y tamaño del nombre de jugador.
- Ocultar durante combate.
- Tooltips contextuales.
- Comportamiento de la etiqueta del gremio representado.
- Valores fijos manuales para las casas primaria/secundaria.
- Un apartado condicional de modo guild para miembros válidos, controlado exclusivamente por la guild representada en C.
- Diagnóstico automático del estado del grupo antes de las acciones de Actividades de grupo, disponible solo mientras el modo debug global está activado.
- Activación de autoinvitación por chat y palabras de invitación alternativas simultáneas.
- Los ajustes de reset de instancia comienzan con una opción maestra de habilitación. Cuando está desactivada, los controles dependientes aparecen visualmente inactivos. Después incluye confirmación (activada por defecto), destino puente, movimiento de la ventana de estado con una vista temporal completa de colocación para 11 miembros, tiempo de espera, retraso de invitaciones y reintentos. La explicación experimental está disponible en el icono de información situado junto al encabezado de la sección.
- Viaje de miembros en actividades de grupo ofrece una única casilla, desactivada por defecto, para solicitar automáticamente el viaje al líder actual después de aceptar manualmente la invitación de reagrupación. El tooltip de su sección explica el requisito de EZOCore/LibGroupBroadcast y sus límites de seguridad.
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
- Abrir el panel completo desde Ajustes > EZO y comprobar que EZOTools no aparece duplicado en la lista estándar de Addons.
- Desactivar EZOCore y comprobar que el fallback independiente de LibAddonMenu sigue disponible.
- Probar el panel de comandos con teclado/mando.
- Abrir Controles y comprobar que las acciones aparecen bajo `EZO AddOns > EZOTools` sin cambiar sus teclas asignadas.
- Probar las interacciones del overlay con ratón separadas de los menús laterales.
- Probar chat y `Enter`.
- Probar `ESC` y los menús normales del juego.
- Si pruebas herramientas de grupo, usa primero un grupo controlado y revisa los informes de DebugLogViewer si algo no se comporta como esperas.
- Desde un cliente localizado, abre Viajar a trials y solicita un viaje al Archivo Aetérico; comprueba que se use el nodo verificado del catálogo en vez de depender solo del nombre mostrado. Repite la prueba mediante Resetear instancia para cubrir la ruta de viaje compartida.
- Si pruebas reset de instancia, usa primero un grupo pequeño controlado. Prueba tanto una casa configurada como `Salir de instancia`; verifica espera en combate, confirmación del destino puente, dificultad capturada, vuelta, solicitudes, respuestas, salidas o expulsiones, entradas adicionales e incorporación al grupo antes de una raid organizada.
- Desactiva la opción maestra de Reset de instancia y comprueba que sus controles LAM dependientes queden en gris, que Resetear instancia desaparezca de Actividades de grupo y que su keybind directo no pueda iniciar ni reanudar el flujo. Si ya existe una sesión, comprueba que Cancelar reset de instancia siga disponible; vuelve a habilitar la opción antes de continuar las pruebas. Pasa el ratón sobre todas las cabeceras LAM y sobre sus controles con ayuda específica para verificar que los tooltips aparezcan sin párrafos explicativos permanentes.
- En un grupo ya formado, transfiere el liderazgo al jugador con EZOTools mientras Actividades de grupo está abierto y comprueba que las acciones de líder aparezcan tras el refresco diferido del contexto. Repite el reset desde el hall, el interior activo, después de un wipe y tras el último boss; todos los casos deben capturar el grupo actual y ejecutar el flujo completo de destino puente y regreso sin omitir fases.
- Durante la fase de regreso, prueba tanto iniciar el viaje mientras ya te mueves como moverte durante el casteo. Comprueba que se conserva la fase 5 con un mensaje de acción específico; después detente y verifica que Resetear instancia repite solo el viaje de regreso.
- Interrumpe el desplazamiento de la fase 3 después del disband interno. Comprueba que los cronómetros del panel se detengan, que Actividades de grupo siga mostrando Resetear instancia estando solo y que seleccionarlo reanude la fase puente retenida sin mostrar Disbandear grupo ni los controles de dificultad.
- Durante los estados activo, interrumpido, esperando miembros y reset completado, comprueba que Cancelar reset de instancia sea la primera entrada de Actividades de grupo con ratón, menú de teclado y menú de mando. Confirma la cancelación y verifica que el panel se cierre y que ni la cancelación ni callbacks retrasados reactiven la sesión.
- Después de cancelar, comprueba que aparezca Iniciar último grupo e instancia, que la confirmación muestre la trial y el número de miembros memorizados, que solo invite a miembros guardados ausentes y que viaje mediante la ruta existente con la dificultad capturada. Verifica que se oculte durante un reset activo y cuando estés agrupado bajo otro líder.
- Con debug activo, verifica que un reset genere resúmenes amarillos `Info` en los límites del ciclo de vida y un único aviso si se interrumpe. Las entradas/salidas del grupo y las respuestas de invitación deben actualizar el panel sin generar un informe completo independiente por evento, y el progreso normal del reset no debe copiarse al chat.
- Mientras la fase 6 aún tenga miembros pendientes, ejecuta otra vez Resetear instancia y comprueba que la confirmación de reanudación reinicia las invitaciones sin sustituir el snapshot. Cuando todos los miembros capturados estén agrupados, verifica que el panel muestre `RESET COMPLETADO` sin temporizadores de fase y que un reset posterior confirmado explícitamente pueda crear un snapshot nuevo.
- Prueba Abandonar grupo tanto como líder como sin serlo, Salir de instancia cuando ESO permita la salida inmediata y Abandonar grupo y salir de instancia cuando se cumplan ambas condiciones. Comprueba que las acciones válidas aparezcan en el panel principal de comandos pero no en LAM, y que Abandonar grupo junto con Abandonar grupo y salir de instancia permanezcan disponibles en Actividades de grupo. Repite con ratón, menú de teclado y menú de mando, incluido combate cuando ESO siga permitiendo la acción.
- Comprueba que `Estado del grupo` ya no aparezca en Actividades de grupo. Con el modo debug y el registro automático del estado activados, ejecuta cada acción de grupo disponible y verifica que Log Viewer reciba una única captura previa con el valor `action` correspondiente; desactiva la opción LAM y comprueba que dejen de generarse esas capturas.
- Abre Información del grupo en el líder y en un miembro sin una sesión de reset. Comprueba que ambos muestren el mismo tamaño, zona del líder con formato nativo, una etiqueta explícita `Normal`/`Veterano` separada de la zona mediante un guion y el roster completo, sin texto de estado recortado, progreso, pendientes, mensajes de espera remota ni filas duplicadas. Después instala en ambos clientes la misma beta de EZOCore con protocolo v2 y la misma compilación de EZOTools, inicia un reset controlado como líder y abre Información del grupo en ambos clientes. Comprueba que el líder conserve únicamente el panel operativo de reset existente y que no aparezca un segundo panel de información del grupo. Comprueba que el miembro reciba la clave/nombre de la trial, modo Normal/Veterano, progreso exacto y pendientes; el panel del miembro no debe fabricar progreso desde la etapa ni usar su dificultad local. Tras el disband intencionado, comprueba que Información del grupo siga disponible, conserve el roster capturado, actualice la zona del jugador local, marque los miembros ausentes sin grupo y con ubicaciones de última observación, y cambie la fila local al recibir la invitación de reagrupación. Comprueba que el estado en vivo del líder se reanude al volver al grupo. Cerrar el panel no debe afectar al grupo, viajes, invitaciones ni reset. Repite sin EZOCore para verificar el fallback local.
- Activa el viaje automático solo en el cliente de prueba que no es líder. Acepta manualmente la invitación de reagrupación del reset mientras estás fuera de la instancia objetivo del líder y comprueba que EZOTools solicite un único salto al líder actual. Repite estando ya en la misma instancia, como líder, con el ajuste desactivado, con estado caducado o incompatible y cuando ESO indique que el salto no está disponible; ninguno de esos casos debe solicitar el viaje. Verifica que un estado repetido de la misma sesión no provoque otro salto.
- Con el modo debug activo, ejecuta `/ezo debug groupactivity`, `/ezo debug groupactivity returning`, `/ezo debug groupactivity complete` y `/ezo debug groupactivity off`. Comprueba que el panel simulado de miembro se marque claramente como datos debug, muestre solo las filas de ubicación del líder y del propio jugador en lugar del roster completo y se cierre sin cambiar grupo, viajes ni reset.
- Durante esa prueba, verifica que el panel se oculte en inventario/menús, permanezca visible en el vestíbulo y se limpie normalmente cuando el líder abandone el área de preparación.
- Verifica el panel estructurado del reset con uno, cuatro y once miembros capturados (el líder no figura como miembro capturado). Al activar en LAM la opción de mover, debe aparecer la vista completa de colocación con once miembros; arrástrala con el botón izquierdo y confirma que el derecho no la mueve. Al desactivar la opción debe restaurarse el estado real del reset u ocultarse el panel. Comprueba que las métricas queden centradas y alineadas, que los nombres no se superpongan al estado de invitación ni de ubicación, que la barra de seis fases y su contador central sean legibles, que los avisos amplíen limpiamente el panel y que cambiar entre teclado y mando adapte la tipografía nativa sin mover ni redimensionar otras interfaces. Para miembros agrupados, verifica los estados verde de misma instancia y amarillo de instancia distinta; los miembros sin `unitTag` actual deben permanecer en gris y con ubicación desconocida.
- Después de una sesión de reset completada o conservada, forma un grupo controlado y ejecuta Disbandear grupo de manera independiente. Verifica que ESO confirme el disband, que el panel se cierre y que Log Viewer registre `reset-session-cleared` con el modo debug activado.
- Después de que un reset reconstruya el grupo, prueba Abandonar grupo y Disbandear grupo de forma independiente. Comprueba que ambas acciones cierren el panel conservado; después repite el proceso y sal de la trial capturada tras el regreso para verificar que el cambio de zona también lo cierre sin afectar a las fases del destino puente.
- Para la autoinvitación, configura al menos dos palabras, actívala y prueba desde otra cuenta mensajes exactos, en mayúsculas, con `+palabra` y con la misma secuencia dentro de una palabra mayor en chat de gremio o susurro. Comprueba que solo inviten las coincidencias válidas, que un jugador no líder no invite y que un mensaje repetido durante 15 segundos no genere otra solicitud. Con debug activado, verifica las fases `initialization`, `keyword-detected`, `keyword-evaluated`, `invite-requested` y, cuando exista, `invite-response` en Log Viewer. Desactiva la opción y comprueba que los mensajes coincidentes dejen de invitar.
- Verifica que Resetear instancia no esté disponible fuera de una trial reconocida y que allí no disbandee el grupo.

## Componente de UI reutilizable

La ventana de reset utiliza el panel de estado genérico documentado en [docs/status-panel.md](docs/status-panel.md). El componente es independiente de la lógica de grupos y trials e incluye un modo de acciones opcional, activado expresamente, para consumidores con ratón, teclado y mando.

## Metadatos del repositorio

GitHub About debe describir el addon actual, no solo su función original de viaje. La metadata pública actual debe usar Discord como enlace de soporte/homepage y topics como `lua`, `gamepad`, `elder-scrolls-online`, `esoui` y `eso-addon`.

## Licencia

MIT. Ver [LICENSE](LICENSE).

Desarrollado y mantenido por Zuriplayer.
