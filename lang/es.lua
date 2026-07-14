-- Cadenas en español para EZOTools.
-- REGLA: mismas claves que en.lua, mismo orden.
EZO_STRINGS_ES = {

    -- -------------------------------------------------------------------------
    -- Categoría de keybind
    -- -------------------------------------------------------------------------
    SI_BINDING_CATEGORY_EZOTOOLS                = "E|cB040FFZ|rOTools",

    -- -------------------------------------------------------------------------
    -- Nombres de keybinds (aparecen en la pantalla de controles)
    -- -------------------------------------------------------------------------
    SI_BINDING_NAME_EZO_TOGGLE_COMMAND_PANEL    = "Abrir panel de comandos",
    SI_BINDING_NAME_EZO_TRAVEL_PRIMARY_HOUSE    = "Viajar a casa principal",
    SI_BINDING_NAME_EZO_TRAVEL_CRAFTING_HALL    = "Visitar sala de artesanía",
    SI_BINDING_NAME_EZO_TRAVEL_SECONDARY_HALL   = "Visitar sala secundaria",
    SI_BINDING_NAME_EZO_LEAVE_GROUP             = "Abandonar grupo",
    SI_BINDING_NAME_EZO_LEAVE_INSTANCE          = "Salir de instancia",
    SI_BINDING_NAME_EZO_LEAVE_GROUP_INSTANCE    = "Salir del grupo y de la instancia",
    SI_BINDING_NAME_EZO_RELOAD_UI               = "Recargar interfaz",
    SI_BINDING_NAME_EZO_TOGGLE_UTILITY_PANEL    = "Abrir panel de utilidades",
    SI_BINDING_NAME_EZO_TOGGLE_GROUP_ACTIVITIES_PANEL = "Abrir panel de actividades de grupo",
    SI_BINDING_NAME_EZO_RESET_INSTANCE          = "Resetear instancia",
    SI_BINDING_NAME_EZO_DISBAND_GROUP           = "Disbandear grupo",

    -- -------------------------------------------------------------------------
    -- Mensajes generales del addon
    -- -------------------------------------------------------------------------
    EZO_MSG_INIT                = "E|cB040FFZ|rOTools inicializado.",
    EZO_MSG_HIDE_PET            = "Ocultando mascota",
    EZO_MSG_HIDE_COMPANION      = "Ocultando compañero",
    EZO_MSG_HIDE_ASSISTANT      = "Ocultando asistente",
    EZO_MSG_USE_MOUNT           = "Seleccionando montura",
    EZO_MSG_SUMMON_PET          = "Invocando mascota",
    EZO_MSG_SUMMON_COMPANION    = "Invocando compañero",
    EZO_MSG_SUMMON_ASSISTANT    = "Invocando asistente",
    EZO_MSG_DEBUG_FOOD_CONSUME_ATTEMPT = "Intentando consumir <<1>>",
    EZO_MSG_DEBUG_FOOD_CONSUME_FAILED = "Debug comida: no se ha confirmado el consumo o el buff no se ha renovado.",
    EZO_MSG_DEBUG_FOOD_NO_RECORDED = "Debug comida: no hay ninguna comida o bebida recordada disponible.",
    EZO_MSG_DEBUG_MODE_DISABLED = "El modo debug está desactivado. Actívalo en la configuración del addon para usar /ezo debug.",

    -- -------------------------------------------------------------------------
    -- Panel LAM: sección General
    -- -------------------------------------------------------------------------
    EZO_OPTION_GENERAL                  = "General",
    EZO_OPTION_GENERAL_NOTE             = "Comportamiento del idioma y otros ajustes generales de EZOTools.",
    EZO_OPTION_LANGUAGE                 = "Idioma",
    EZO_OPTION_LANGUAGE_AUTO            = "Automático (cliente ESO)",
    EZO_OPTION_LANGUAGE_TOOLTIP         = "Idioma local usado cuando EZOCore no está instalado o su modo de idioma es 'dejar que cada addon elija'. Los idiomas centrales de EZOCore desactivan este selector. Forzar otro idioma puede mezclar textos del addon con nombres del sistema ESO.",
    EZO_MSG_LANGUAGE_FORCED_WARNING     = "Idioma forzado: los nombres de ESO pueden usar el idioma del juego.",

    -- -------------------------------------------------------------------------
    -- Panel LAM: sección Overlay
    -- -------------------------------------------------------------------------
    EZO_OPTION_OVERLAY                  = "Overlay",
    EZO_OPTION_OVERLAY_NOTE             = "Ajustes de visibilidad, estilo de interacción, escala, texto del jugador y posición del overlay en pantalla.",
    EZO_OPTION_OVERLAY_ENABLE           = "Activar overlay",
    EZO_OPTION_OVERLAY_LOCK             = "Bloquear posición del overlay",
    EZO_OPTION_OVERLAY_SIMULATE_GAMEPAD = "Simular estilo Gamepad (solo overlay)",
    EZO_OPTION_OVERLAY_HIDE_COMBAT      = "Ocultar en combate",
    EZO_OPTION_OVERLAY_CONTEXTUAL_TOOLTIPS = "Mostrar tooltips contextuales en los iconos",
    EZO_OPTION_OVERLAY_CONTEXTUAL_TOOLTIPS_TOOLTIP = "Muestra información contextual al pasar el ratón por los iconos del overlay y por los iconos laterales del addon.",
    EZO_OPTION_OVERLAY_SCALE            = "Escala del overlay",
    EZO_OPTION_OVERLAY_PLAYER_TEXT_COLOR = "Color del nombre del jugador",
    EZO_OPTION_OVERLAY_PLAYER_TEXT_SIZE = "Tamaño del nombre del jugador",
    EZO_OPTION_OVERLAY_TEXT             = "Texto del overlay",
    EZO_OPTION_OVERLAY_RESET_POS        = "Reiniciar posición",
    EZO_OPTION_OVERLAY_RESET_POS_TOOLTIP = "Devuelve el overlay a su posición inicial en pantalla.",
    EZO_OPTION_GUILD_OVERLAY            = "Imagen de gremio",
    EZO_OPTION_GUILD_LABEL_COLOR        = "Color del nombre del gremio representado",
    EZO_OPTION_GUILD_LABEL_COLOR_TOOLTIP = "Solo se aplica cuando hay un gremio representado seleccionado y no llevas tabardo. Los estados de tabardo y sin gremio mantienen sus colores actuales.",
    EZO_OPTION_GUILD_HIDE_NO_GUILD      = "Ocultar texto 'Sin gremio'",
    EZO_OPTION_GUILD_HIDE_NO_GUILD_TOOLTIP = "Si está activado, el overlay oculta el texto 'Sin gremio' cuando no hay ningún gremio representado en el selector C.",

    -- -------------------------------------------------------------------------
    -- Panel LAM: sección Casas de amigos
    -- -------------------------------------------------------------------------
    EZO_OPTION_FRIENDS          = "Casas del gremio",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN = "Autoasignar casas desde el gremio",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_TOOLTIP = "Si está activado, el addon usa el gremio representado en C solo si tiene perfil guardado o interno. Si no hay gremio válido en C, usa Valores propios.",
    EZO_OPTION_FRIENDS_ACTIVE_VALUES = "Casa activa Artesanía/Secundaria: |cC8A95A<<1>>|r / |cC8A95A<<2>>|r",
    EZO_OPTION_FRIENDS_ACTIVE_EMPTY = "(vacía)",
    EZO_OPTION_FRIENDS_MANUAL_ACTIVE_PROFILE = "Perfil activo manual",
    EZO_OPTION_FRIENDS_MANUAL_ACTIVE_PROFILE_TOOLTIP = "Cuando autoasignar está desactivado, este perfil define las casas que usará el addon para viajar. Por defecto es Valores propios hasta que lo cambies.",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD = "Perfil que estás editando",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD_TOOLTIP = "Elige Valores propios o un gremio de tu lista para editar sus casas guardadas. Las casillas inferiores solo editan este perfil y no cambian las casas activas hasta guardarlo y aplicarlo. La autoasignación usa siempre el gremio representado en C.",
    EZO_OPTION_FRIENDS_PROFILE_MANUAL = "Valores propios",
    EZO_OPTION_FRIENDS_SAVE_SELECTED = "Guardar perfil editado",
    EZO_OPTION_FRIENDS_SAVE_SELECTED_TOOLTIP = "Guarda las casas escritas para el perfil seleccionado. Si ese perfil coincide con el gremio autoasignado actual, se actualizarán también las casas activas.",
    EZO_OPTION_FRIENDS_CRAFTING = "Editar casa de artesanía (@jugador)",
    EZO_OPTION_FRIENDS_SECONDARY= "Editar casa secundaria (@jugador)",

    -- -------------------------------------------------------------------------
    -- Panel LAM: sección Actividades de grupo y reset de raid leader
    -- -------------------------------------------------------------------------
    EZO_OPTION_GROUP_ACTIVITIES_DIAGNOSTICS = "Diagnóstico de Actividades de grupo",
    EZO_OPTION_GROUP_STATUS_AUTO_LOG = "Registrar automáticamente el estado del grupo",
    EZO_OPTION_GROUP_STATUS_AUTO_LOG_TOOLTIP = "Con el modo debug activado, escribe en Log Viewer una captura del grupo y la instancia justo antes de ejecutar una acción de Actividades de grupo. No añade una entrada al menú ni escribe en el chat.",
    EZO_OPTION_GROUP_AUTOINVITE = "Autoinvitación de grupo",
    EZO_OPTION_GROUP_AUTOINVITE_NOTE = "Invita a jugadores cuando aparece cualquiera de las palabras configuradas en un canal de chat de jugadores compatible. Cada palabra es una alternativa independiente. EZOTools solo solicita invitaciones cuando estás solo o eres líder del grupo. Usa palabras distintivas para evitar coincidencias no deseadas.",
    EZO_OPTION_GROUP_AUTOINVITE_ENABLED = "Activar autoinvitación por chat",
    EZO_OPTION_GROUP_AUTOINVITE_ENABLED_TOOLTIP = "Desactivado por defecto. Al activarlo, los mensajes de chat coincidentes pueden solicitar invitaciones de grupo automáticamente.",
    EZO_OPTION_GROUP_AUTOINVITE_KEYWORDS = "Palabras de invitación activas",
    EZO_OPTION_GROUP_AUTOINVITE_KEYWORDS_TOOLTIP = "Introduce una o varias palabras separadas por espacios, líneas, comas o punto y coma. Cada palabra queda activa de forma independiente. La coincidencia ignora mayúsculas y signos alrededor, por lo que +palabra coincide con palabra.",
    EZO_OPTION_INSTANCE_RESET = "Reset de instancia",
    EZO_OPTION_INSTANCE_RESET_NOTE = "Ayuda experimental para raid leader. Captura el grupo actual, lo disbandea, alcanza el destino puente configurado, espera, vuelve a la trial detectada cuando sea posible y reinvita a los miembros capturados.",
    EZO_OPTION_INSTANCE_RESET_ENABLED = "Habilitar reset de instancia",
    EZO_OPTION_INSTANCE_RESET_ENABLED_TOOLTIP = "Habilita la acción Resetear instancia y sus ajustes. Al desactivarla no pueden iniciarse resets nuevos ni retenidos, pero Cancelar reset de instancia sigue disponible para una sesión existente.",
    EZO_OPTION_INSTANCE_RESET_CONFIRM_ACTIONS = "Confirmar reset y disband",
    EZO_OPTION_INSTANCE_RESET_CONFIRM_ACTIONS_TOOLTIP = "Muestra la ventana de confirmación para teclado o la confirmación nativa equivalente para mando antes del reset y disband.",
    EZO_OPTION_INSTANCE_RESET_MOVE_STATUS_WINDOW = "Mover ventana de estado del reset",
    EZO_OPTION_INSTANCE_RESET_MOVE_STATUS_WINDOW_TOOLTIP = "Muestra la vista completa de colocación con 11 miembros y desbloquea la ventana de estado para arrastrarla. Al desactivarlo se restaura el estado real del reset o se oculta la ventana.",
    EZO_OPTION_INSTANCE_RESET_DESTINATION = "Destino puente para reset",
    EZO_OPTION_INSTANCE_RESET_DESTINATION_TOOLTIP = "Destino usado tras disbandear el grupo. Elige una casa configurada o salir de la instancia actual antes de volver a la trial detectada.",
    EZO_OPTION_INSTANCE_RESET_DESTINATION_PRIMARY = "Casa principal",
    EZO_OPTION_INSTANCE_RESET_DESTINATION_CRAFTING = "Casa de artesanía",
    EZO_OPTION_INSTANCE_RESET_DESTINATION_SECONDARY = "Casa secundaria",
    EZO_OPTION_INSTANCE_RESET_WAIT_SECONDS = "Espera en destino puente (segundos)",
    EZO_OPTION_INSTANCE_RESET_WAIT_SECONDS_TOOLTIP = "Tiempo contado solo después de confirmar que se alcanzó la casa elegida o que se abandonó la trial capturada. Si no se confirma el destino puente, el reset se interrumpe y puede reanudarse.",
    EZO_OPTION_INSTANCE_RESET_INVITE_DELAY_SECONDS = "Retraso invitaciones tras volver (segundos)",
    EZO_OPTION_INSTANCE_RESET_INVITE_DELAY_SECONDS_TOOLTIP = "Tiempo que se espera antes de invitar a los miembros capturados tras volver o tras el margen de retorno.",
    EZO_OPTION_INSTANCE_RESET_REINVITE_ATTEMPTS = "Reintentos extra de invitación",
    EZO_OPTION_INSTANCE_RESET_REINVITE_ATTEMPTS_TOOLTIP = "Pasadas adicionales de invitación después de la primera. Los jugadores ya detectados en grupo se omiten.",
    EZO_OPTION_INSTANCE_RESET_REINVITE_DELAY_SECONDS = "Espera entre reintentos (segundos)",
    EZO_OPTION_INSTANCE_RESET_REINVITE_DELAY_SECONDS_TOOLTIP = "Tiempo entre pasadas repetidas de invitación.",

    -- -------------------------------------------------------------------------
    -- Panel LAM: sección Mantenimiento
    -- -------------------------------------------------------------------------
    EZO_OPTION_MAINTENANCE                = "Mantenimiento",
    EZO_OPTION_MAINTENANCE_NOTE           = "Umbrales que determinan cuándo están disponibles las acciones de reparar equipo y recargar armas.",
    EZO_OPTION_STOCK_ALERTS               = "Alertas de stock",
    EZO_OPTION_REPAIR_THRESHOLD           = "Umbral de reparación de equipo (%)",
    EZO_OPTION_REPAIR_THRESHOLD_TOOLTIP   = "La opción 'Reparar equipo' aparece en el menú solo si alguna pieza está por debajo de este porcentaje de durabilidad.",
    EZO_OPTION_RECHARGE_THRESHOLD         = "Umbral de recarga de armas (%)",
    EZO_OPTION_RECHARGE_THRESHOLD_TOOLTIP = "La opción 'Recargar armas' aparece en el menú solo si algún arma está por debajo de este porcentaje de carga de encantamiento.",
    EZO_OPTION_DEBUG                      = "Debug",
    EZO_OPTION_DEBUG_MODE                 = "Activar modo debug",
    EZO_OPTION_DEBUG_MODE_TOOLTIP         = "Habilita de forma persistente las funciones de debug del addon, incluido /ezo debug y las filas de inspección en menús bloqueados.",

    -- -------------------------------------------------------------------------
    -- Entradas del panel de comandos
    -- -------------------------------------------------------------------------
    EZO_MENU_TITLE                = "EZOTools",
    EZO_UTILITY_MENU_TITLE        = "Utilidades rápidas",
    EZO_MENU_DIALOG_SUBTITLE      = "<<1>>  ·  v<<2>>",
    EZO_MENU_SETTINGS             = "Ajustes rápidos",
    EZO_MENU_ADDON_SETTINGS       = "Ajustes completos (LAM)",
    EZO_MENU_TRAVEL_PRIMARY       = "Ir a mi casa",
    EZO_MENU_TRAVEL_CRAFTING      = "Ir a la casa de artesanía",
    EZO_MENU_TRAVEL_SECONDARY     = "Ir a la casa secundaria",
    EZO_MENU_JUMP_LEADER          = "Saltar al líder",
    EZO_MENU_JUMP_LEADER_PLAYER   = "Saltar al líder: <<1>>",
    EZO_MENU_JUMP_LEADER_ZONE     = "Saltar al líder: <<1>>",
    EZO_MENU_JUMP_LEADER_WITH_LOCATION = "Saltar al líder: <<1>> - <<2>>",
    EZO_MENU_LEAVE_GROUP          = "Abandonar grupo",
    EZO_MENU_LEAVE_INSTANCE       = "Salir de instancia",
    EZO_MENU_LEAVE_GROUP_INSTANCE = "Abandonar grupo y salir de instancia",
    EZO_MENU_GROUP_ACTIVITIES     = "Actividades de grupo",
    EZO_MENU_GROUP_ACTIVITIES_TITLE = "Actividades de grupo",
    EZO_MENU_GROUP_ACTIVITY_PLAYER_STATUS = "Mi estado de actividad de grupo",
    EZO_MENU_DISBAND_GROUP        = "Disbandear grupo",
    EZO_MENU_INSTANCE_RESET       = "Resetear instancia",
    EZO_MENU_CANCEL_INSTANCE_RESET = "Cancelar reset de instancia",
    EZO_MENU_START_LAST_GROUP_ACTIVITY = "Iniciar último grupo e instancia",
    EZO_MENU_TRIAL_TRAVEL         = "Viajar a trials (Veterano)",
    EZO_MENU_TRIAL_TRAVEL_TITLE   = "Trials (Veterano)",
    EZO_MENU_TRIAL_TRAVEL_LAST    = "Última trial: <<1>>",
    EZO_MENU_TRIAL_TRAVEL_LAST_NONE = "Última trial: ninguna",
    EZO_MENU_DUNGEON_DIFFICULTY   = "Dificultad de instancia",
    EZO_MENU_DUNGEON_DIFFICULTY_TO = "Cambiar dificultad de instancia: <<1>>",
    EZO_MENU_REPAIR               = "Reparar equipo (<= <<1>>%)",
    EZO_MENU_RECHARGE             = "Recargar armas (<= <<1>>%)",
    EZO_MENU_RELOAD               = "Recargar interfaz",
    EZO_MENU_DEBUG_VIEWER         = "Abrir visor técnico",
    EZO_MENU_EXIT                 = "Salir",

    -- -------------------------------------------------------------------------
    -- Submenú de ajustes rápidos (gamepad_settings)
    -- -------------------------------------------------------------------------
    EZO_SETTINGS_RECHARGE_THRESHOLD = "Recarga de armas: <<1>>%",
    EZO_SETTINGS_REPAIR_THRESHOLD   = "Reparación de equipo: <<1>>%",
    EZO_SETTINGS_BACK               = "Volver",
    EZO_SETTINGS_CLOSE              = "Cerrar",

    -- -------------------------------------------------------------------------
    -- Overlay: etiqueta de guild
    -- -------------------------------------------------------------------------
    EZO_OVERLAY_NO_GUILD        = "Sin gremio",
    EZO_OVERLAY_TABARD          = "Tabardo",
    EZO_UTILITY_ENTRY_FOOD      = "Comida y bebida",
    EZO_UTILITY_ENTRY_MOUNT     = "Montura",
    EZO_UTILITY_ENTRY_PET       = "Mascota",
    EZO_UTILITY_ENTRY_COMPANION = "Compañero",
    EZO_UTILITY_ENTRY_ASSISTANT = "Asistente",
    EZO_UTILITY_ENTRY_HOUSES    = "Casas",
    EZO_UTILITY_ENTRY_OTHER_HOUSES = "Casas de otros",
    EZO_UTILITY_HOUSES_OPEN_COLLECTIONS = "Abrir colección de casas",
    EZO_UTILITY_HOUSES_HISTORY_EMPTY = "No hay casas propias guardadas todavía.|nVisita una casa propia distinta de tu casa principal para añadirla aquí.",
    EZO_UTILITY_HOUSES_VISIT_HINT = "Visita tus casas propias para memorizar las 10 últimas.",
    EZO_UTILITY_OTHER_HOUSES_HISTORY_EMPTY = "No hay casas de otros jugadores guardadas todavía.|nSe memorizarán conforme visites casas concretas de otros jugadores.",
    EZO_UTILITY_OTHER_HOUSES_VISIT_HINT = "Visita casas de otros jugadores para memorizar las 20 últimas.",
    EZO_UTILITY_HOUSES_FALLBACK_NAME = "Casa",

    -- -------------------------------------------------------------------------
    -- Mensajes de chat: viajes
    -- -------------------------------------------------------------------------
    EZO_MSG_NO_PRIMARY_HOUSE    = "No hay casa principal configurada.",
    EZO_MSG_NO_CRAFTING_HALL    = "Configura una casa de artesanía en los ajustes.",
    EZO_MSG_NO_SECONDARY_HALL   = "Configura una casa secundaria en los ajustes.",

    -- -------------------------------------------------------------------------
    -- Mensajes de chat: grupo
    -- -------------------------------------------------------------------------
    EZO_MSG_NOT_IN_GROUP        = "No estás en un grupo.",
    EZO_MSG_CANT_JUMP_LEADER    = "No se puede saltar al líder desde aquí.",
    EZO_MSG_DUNGEON_DIFFICULTY_CANT_CHANGE = "No puedes cambiar la dificultad de instancia desde aquí.",
    EZO_MSG_DUNGEON_DIFFICULTY_CANT_CHANGE_REASON = "No puedes cambiar la dificultad de instancia desde aquí: <<1>>",
    EZO_MSG_DUNGEON_DIFFICULTY_CHANGED = "Dificultad de instancia cambiada a <<1>>.",
    EZO_MSG_TRIAL_TRAVEL_START = "Viajando a <<1>>.",
    EZO_MSG_TRIAL_TRAVEL_NODE_MISSING = "No se encontró el nodo de viaje rápido para <<1>>. Descúbrelo primero o añade su nombre como alias tras comprobarlo en juego.",
    EZO_MSG_TRIAL_TRAVEL_UNAVAILABLE = "El viaje rápido no está disponible desde este contexto.",
    EZO_MSG_TRIAL_TRAVEL_LAST_NONE = "No hay disponible ningún viaje anterior a una trial.",
    EZO_MSG_TRIAL_TRAVEL_VETERAN_BLOCKED = "No se pudo activar el modo veterano. Se canceló el viaje.",
    EZO_MSG_TRIAL_TRAVEL_VETERAN_BLOCKED_REASON = "No se pudo activar el modo veterano: <<1>>. Se canceló el viaje.",
    EZO_MSG_TRIAL_TRAVEL_DIFFICULTY_BLOCKED = "No se pudo confirmar el modo <<1>>. Se canceló el viaje.",
    EZO_MSG_TRIAL_TRAVEL_DIFFICULTY_BLOCKED_REASON = "No se pudo activar el modo <<1>>: <<2>>. Se canceló el viaje.",

    -- -------------------------------------------------------------------------
    -- Mensajes de chat: mantenimiento
    -- -------------------------------------------------------------------------
    EZO_MSG_CANT_REPAIR_COMBAT  = "No se puede reparar en combate.",
    EZO_MSG_NO_REPAIR_KITS      = "No hay kits de reparación.",
    EZO_MSG_REPAIR_DONE         = "Reparación ejecutada.",
    EZO_MSG_CANT_RECHARGE_COMBAT= "No se puede recargar en combate.",
    EZO_MSG_NO_SOUL_GEMS        = "No hay gemas de alma cargadas.",
    EZO_MSG_RECHARGE_DONE       = "Recarga ejecutada.",

    -- -------------------------------------------------------------------------
    -- Mensajes de chat: errores / sistema
    -- -------------------------------------------------------------------------
    EZO_MSG_ACTION_FAILED       = "Error en acción: <<1>>",
    EZO_MSG_CANT_OPEN_COMBAT    = "No se pueden abrir ajustes en combate.",
    EZO_MSG_CMD_PANEL_MISSING   = "Panel de comandos no disponible.",
    EZO_MSG_UTILITY_PANEL_MISSING = "Panel de utilidades no disponible.",
    EZO_MSG_GROUP_ACTIVITIES_PANEL_MISSING = "Panel de actividades de grupo no disponible.",
    EZO_MSG_GROUP_DISBAND_STARTED = "Disband de grupo solicitado.",
    EZO_MSG_GROUP_DISBAND_CONFIRMED = "Disband de grupo confirmado.",
    EZO_MSG_GROUP_DISBAND_NOT_CONFIRMED = "ESO no confirmó el disband del grupo.",
    EZO_MSG_GROUP_DISBAND_UNAVAILABLE = "No se puede disbandear el grupo desde aquí.",
    EZO_MSG_INSTANCE_RESET_STARTED = "Reset de instancia iniciado. Miembros de grupo capturados: <<1>>.",
    EZO_MSG_INSTANCE_RESET_UNAVAILABLE = "El reset requiere ser líder de grupo y estar dentro de una trial reconocida.",
    EZO_MSG_INSTANCE_RESET_DISABLED = "Reset de instancia está desactivado en los ajustes de EZOTools.",
    EZO_MSG_INSTANCE_RESET_UNSUPPORTED_TARGET = "No se detectó una trial compatible. El grupo no se ha disbandeado.",
    EZO_MSG_INSTANCE_RESET_ALREADY_RUNNING = "Ya hay un reset de instancia en curso.",
    EZO_MSG_INSTANCE_RESET_DESTINATION_UNAVAILABLE = "El destino puente configurado para reset no está disponible.",
    EZO_MSG_INSTANCE_RESET_WAITING = "Destino puente alcanzado. Esperando <<1>> segundos antes de volver.",
    EZO_MSG_INSTANCE_RESET_STAGING_NOT_CONFIRMED = "No se pudo confirmar el destino puente seleccionado. El reset se ha interrumpido.",
    EZO_MSG_INSTANCE_RESET_TRAVEL_FAILED = "ESO rechazó la solicitud de viaje. El reset puede reanudarse.",
    EZO_MSG_INSTANCE_RESET_RETURNING = "Volviendo a <<1>>.",
    EZO_MSG_INSTANCE_RESET_NO_INSTANCE_TARGET = "No se capturó una trial conocida. Se omite el viaje de vuelta.",
    EZO_MSG_INSTANCE_RESET_INVITES_UNAVAILABLE = "Las invitaciones de grupo no están disponibles desde aquí.",
    EZO_MSG_INSTANCE_RESET_INVITES_SENT = "Solicitudes de invitación emitidas: <<1>> (intento <<2>>).",
    EZO_MSG_INSTANCE_RESET_INTERRUPTED = "Reset de instancia interrumpido. Ejecuta Resetear instancia otra vez para reanudarlo.",
    EZO_MSG_LAST_GROUP_ACTIVITY_UNAVAILABLE = "El grupo y la instancia guardados no pueden iniciarse desde el estado actual.",
    EZO_MSG_INSTANCE_RESET_RETURN_CANCELLED = "El viaje de regreso a la instancia se canceló. Detente y vuelve a ejecutar Resetear instancia para reintentarlo.",
    EZO_MSG_INSTANCE_RESET_RESUMED = "Reanudando el reset de instancia interrumpido.",
    EZO_MSG_INSTANCE_RESET_RESUME_UNAVAILABLE = "No hay ningún reset de instancia interrumpido para reanudar.",
    EZO_MSG_RAID_ACTION_CONFIRM_UNAVAILABLE = "La ventana de confirmación no está disponible; no se ha ejecutado la acción.",
    EZO_MSG_RAID_ACTION_CONFIRM_ALREADY_OPEN = "Ya hay abierta otra confirmación de reset o disband.",
    EZO_MSG_TRIAL_PANEL_MISSING = "Panel de viaje a trials no disponible.",
    EZO_MSG_MENU_CALLBACK_FAILED = "Debug menú: error al ejecutar una opción: <<1>>",
    EZO_MSG_DEBUG_VIEWER_UNAVAILABLE = "Visor técnico no disponible.",
    EZO_MSG_DEBUG_LOGGER_UNAVAILABLE = "Diagnóstico técnico no disponible; no se ha generado reporte.",
    EZO_MSG_DEBUG_REPORT_SENT = "Diagnóstico generado: <<1>>",
    EZO_MSG_DEBUG_REPORT_LOGGED_VIEWER_MISSING = "Diagnóstico generado: <<1>>. Visor técnico no disponible.",
    -- -------------------------------------------------------------------------
    -- Salida de comandos slash
    -- -------------------------------------------------------------------------
    EZO_CMD_BANNER              = "E|cB040FFZ|rOTools v<<1>> — @Zuriplayer",
    EZO_CMD_REGISTERED          = "Comandos registrados: /ezo, /ezotools",
    EZO_CMD_HELP_TITLE          = "Comandos disponibles:",
    EZO_CMD_HELP_STATUS         = "  /ezo status   — estado de ejecución del addon",
    EZO_CMD_HELP_DEBUG          = "  /ezo debug    — lista comandos de diagnóstico",
    EZO_CMD_HELP_HELP           = "  /ezo help",
    EZO_CMD_HELP_DETAIL_STATUS  = "    status muestra versión cargada, idioma activo y disponibilidad de módulos principales.",
    EZO_CMD_HELP_DETAIL_DEBUG   = "    debug agrupa herramientas técnicas de soporte y desarrollo; no son comandos de uso normal.",
    EZO_CMD_HELP_CONTACT        = "    Para incidencias, dudas o feedback del addon, puedes contactar con @Zuriplayer.",
    EZO_CMD_HELP_ABOUT          = "  /ezo about    — autor y contacto",
    EZO_CMD_ABOUT_AUTHOR        = "Autor: @Zuriplayer — correo del juego bienvenido (EU y NA).",
    EZO_CMD_ABOUT_DISCORD       = "Discord: <<1>>",
    EZO_MENU_ABOUT              = "Acerca de EZOTools",
    EZO_CONTACT_GUILD_ACTIVE    = "Pack de gremio activo. ¿Casas o imagen desactualizadas? Escribe a @Zuriplayer por correo del juego o en nuestro Discord (/ezo about).",
    EZO_CONTACT_GUILD_LOCKED    = "¿Quieres un pack personalizado para tu gremio (imagen y casas de artesanía)? Contacta con @Zuriplayer por correo del juego o en nuestro Discord (/ezo about).",

    EZO_CMD_DEBUG_TITLE         = "Comandos de diagnóstico",
    EZO_CMD_DEBUG_INFO          = "  /ezo debug info     — diagnóstico: zona, grupo, mantenimiento y gremio",
    EZO_CMD_DEBUG_GUILDS        = "  /ezo debug guilds   — lista tus gremios y cuál está representado",
    EZO_CMD_DEBUG_TEX           = "  /ezo debug tex      — estado de iconos del overlay",
    EZO_CMD_DEBUG_TEXLOAD       = "  /ezo debug texload  — prueba de carga de texturas",
    EZO_CMD_DEBUG_DOTS          = "  /ezo debug dots     — estado de iconos de mascota y aliados",
    EZO_CMD_DEBUG_LAYOUT        = "  /ezo debug layout   — alterna la vista previa de los iconos laterales",
    EZO_CMD_DEBUG_RESET_PANEL   = "  /ezo debug resetpanel [420-620|off] — previsualiza el panel de reset con 11 miembros",
    EZO_CMD_DEBUG_GROUP_ACTIVITY = "  /ezo debug groupactivity [staging|returning|complete|off] — previsualiza el panel de Actividades de grupo del miembro",
    EZO_CMD_DEBUG_HOUSE         = "  /ezo debug house    — diagnóstico de vivienda actual",
    EZO_CMD_DEBUG_GROUP_ACTIVITY_USAGE = "Uso: /ezo debug groupactivity [staging|returning|complete|off]",
    EZO_DEBUG_RESET_PANEL_SHOWN = "Vista previa del panel de reset: <<1>> px de ancho con 11 miembros capturados.",
    EZO_DEBUG_RESET_PANEL_HIDDEN = "Vista previa del panel de reset oculta.",
    EZO_DEBUG_GROUP_ACTIVITY_PANEL_SHOWN = "Simulación del panel de actividad de grupo para miembro mostrada.",
    EZO_DEBUG_GROUP_ACTIVITY_PANEL_HIDDEN = "Simulación del panel de actividad de grupo para miembro oculta.",

    EZO_CMD_GUILDS_NONE         = "No perteneces a ningún gremio.",
    EZO_CMD_GUILDS_HEADER       = "Gremios (<<1>>):",
    EZO_CMD_GUILDS_ROW          = "  [<<1>>] <<2>> (<<3>> mbr) id=<<4>><<5>>",
    EZO_CMD_GUILDS_REPRESENTED  = " < REPRESENTADA",
    EZO_CMD_GUILDS_NONE_REP     = "Ningún gremio representado actualmente.",

    EZO_CMD_INFO_HEADER         = "=== Diagnóstico ===",
    EZO_CMD_INFO_FOOTER         = "===================",
    EZO_CMD_INFO_ZONE           = "  Zona: <<1>>",
    EZO_CMD_INFO_GROUP          = "  Grupo: <<1>> miembros",
    EZO_CMD_INFO_LEADER         = "  Líder: <<1>>",
    EZO_CMD_INFO_NO_GROUP       = "  Grupo: ninguno",
    EZO_CMD_INFO_REPAIR         = "  Reparación (umbral <<1>>%): <<2>>",
    EZO_CMD_INFO_RECHARGE       = "  Recarga armas (umbral <<1>>%): <<2>>",
    EZO_CMD_INFO_NEEDED         = "NECESARIA",
    EZO_CMD_INFO_OK             = "OK",
    EZO_CMD_INFO_GUILD          = "  Gremio representado: <<1>> (id=<<2>>)",
    EZO_CMD_INFO_NO_GUILD       = "  Gremio representado: ninguno",
    EZO_STATUS_YES              = "sí",
    EZO_STATUS_NO               = "no",
    EZO_DEBUG_GROUP_STATUS_TITLE = "Estado de grupo EZOTools",
    EZO_DEBUG_GROUP_ACTIVITIES_TITLE = "Actividades de grupo EZOTools",
    EZO_DEBUG_GROUP_AUTOINVITE_TITLE = "Autoinvitación de grupo EZOTools",
    EZO_DEBUG_TRIAL_TRAVEL_TITLE = "Viaje a trial EZOTools",
    EZO_DEBUG_INSTANCE_RESET_TITLE = "Reset de instancia EZOTools",
    EZO_DEBUG_LAST_GROUP_ACTIVITY_TITLE = "Última actividad de grupo EZOTools",
    EZO_DEBUG_STATUS_PANEL_CALLBACK_FAILED = "Falló una acción del panel de estado: <<1>>",
    EZO_GROUP_ACTIVITY_PEER_PANEL_TITLE = "Actividad de grupo",
    EZO_GROUP_ACTIVITY_PEER_PHASE_LOCAL = "LOCAL",
    EZO_GROUP_ACTIVITY_PEER_PHASE_REMOTE = "REMOTO",
    EZO_GROUP_ACTIVITY_PEER_STATUS_WAITING = "Esperando estado de actividad del líder",
    EZO_GROUP_ACTIVITY_PEER_STATUS_REMOTE = "Estado de actividad del líder recibido",
    EZO_GROUP_ACTIVITY_PEER_PROGRESS_WAITING = "esperando",
    EZO_GROUP_ACTIVITY_PEER_ROWS_TITLE = "TU ESTADO",
    EZO_GROUP_ACTIVITY_PEER_METRIC_GROUP = "Grupo",
    EZO_GROUP_ACTIVITY_PEER_METRIC_EZOCORE = "EZOCore",
    EZO_GROUP_ACTIVITY_PEER_METRIC_LEADER = "Líder",
    EZO_GROUP_ACTIVITY_PEER_ROLE_MEMBER = "miembro",
    EZO_GROUP_ACTIVITY_PEER_ROLE_LEADER = "líder",
    EZO_GROUP_ACTIVITY_PEER_LOCATION_INSTANCE = "en instancia",
    EZO_GROUP_ACTIVITY_PEER_LOCATION_NOT_INSTANCE = "fuera de instancia",
    EZO_GROUP_ACTIVITY_PEER_TRANSPORT_ACTIVE = "La presencia de grupo de EZOCore está activa. Se podrá recibir estado del líder cuando el líder lo envíe.",
    EZO_GROUP_ACTIVITY_PEER_TRANSPORT_PENDING = "La presencia de grupo de EZOCore está instalada, pero el protocolo LibGroupBroadcast aún espera IDs oficiales.",
    EZO_GROUP_ACTIVITY_PEER_TRANSPORT_LIB_MISSING = "LibGroupBroadcast no está instalado, así que la presencia de grupo de EZOCore no puede intercambiar datos.",
    EZO_GROUP_ACTIVITY_PEER_TRANSPORT_SERVICE_MISSING = "EZOCore está instalado, pero su servicio de presencia de grupo no está disponible.",
    EZO_GROUP_ACTIVITY_PEER_TRANSPORT_CORE_MISSING = "EZOCore no está instalado. EZOTools continúa con herramientas de grupo solo locales.",
    EZO_GROUP_ACTIVITY_PEER_TRANSPORT_UNKNOWN = "El estado de presencia de grupo de EZOCore es desconocido.",
    EZO_GROUP_ACTIVITY_PEER_SIMULATION_ACTIVE = "Simulación debug: este panel usa datos locales de prueba, no tráfico de grupo recibido.",
    EZO_GROUP_ACTIVITY_PEER_COMPATIBLE = "compatible",
    EZO_GROUP_ACTIVITY_PEER_INCOMPATIBLE = "incompatible",
    EZO_GROUP_ACTIVITY_PEER_UNKNOWN = "desconocido",
    EZO_INSTANCE_RESET_STATUS_TITLE = "Reset de instancia",
    EZO_INSTANCE_RESET_STATUS_PHASE = "Fase <<1>>/<<2>>: <<3>>",
    EZO_INSTANCE_RESET_STATUS_PHASE_SHORT = "FASE <<1>>/<<2>>",
    EZO_INSTANCE_RESET_STATUS_COMPLETE = "RESET COMPLETADO",
    EZO_INSTANCE_RESET_STATUS_ELAPSED = "Tiempo transcurrido: <<1>>",
    EZO_INSTANCE_RESET_STATUS_PHASE_ELAPSED = "Tiempo en la fase: <<1>>",
    EZO_INSTANCE_RESET_STATUS_RESUME_HINT = "Ejecuta Resetear instancia otra vez para reanudar esta sesión guardada.",
    EZO_INSTANCE_RESET_STATUS_RETRY_RETURN_HINT = "Detente y vuelve a ejecutar Resetear instancia para reintentar el viaje de regreso.",
    EZO_INSTANCE_RESET_STATUS_REMAINING = "Espera restante: <<1>>",
    EZO_INSTANCE_RESET_STATUS_TARGET = "Objetivo: <<1>>",
    EZO_INSTANCE_RESET_STATUS_MODE = "Modo: <<1>>",
    EZO_INSTANCE_RESET_STATUS_CAPTURED = "Miembros capturados: <<1>>",
    EZO_INSTANCE_RESET_STATUS_INVITED = "Solicitudes de invitación: <<1>> (intento <<2>>)",
    EZO_INSTANCE_RESET_STATUS_PENDING = "Pendientes: <<1>> - <<2>>",
    EZO_INSTANCE_RESET_STATUS_MEMBERS = "MIEMBROS",
    EZO_INSTANCE_RESET_STATUS_MEMBERS_COUNT = "MIEMBROS (<<1>>)",
    EZO_INSTANCE_RESET_STATUS_MEMBER_ROW = "<<1>> - solicitudes de invitación: <<2>> - <<3>>",
    EZO_INSTANCE_RESET_MEMBER_STATUS_PENDING = "pendiente",
    EZO_INSTANCE_RESET_MEMBER_STATUS_INVITED = "invitado",
    EZO_INSTANCE_RESET_MEMBER_STATUS_ACCEPTED = "aceptado",
    EZO_INSTANCE_RESET_MEMBER_STATUS_DECLINED = "rechazado",
    EZO_INSTANCE_RESET_MEMBER_STATUS_IGNORED = "ignorado",
    EZO_INSTANCE_RESET_MEMBER_STATUS_JOINED = "en grupo",
    EZO_INSTANCE_RESET_MEMBER_STATUS_ERROR = "error de solicitud",
    EZO_INSTANCE_RESET_STATUS_TARGET_UNKNOWN = "desconocido / omitido",
    EZO_INSTANCE_RESET_STATUS_NONE = "ninguno",
    EZO_INSTANCE_RESET_STATUS_MORE = "+<<1>> más",
    EZO_INSTANCE_RESET_STATUS_TIMES = "Total <<1>>  |  fase <<2>>",
    EZO_INSTANCE_RESET_STATUS_SECTION_ACTIVITY = "ACTIVIDAD",
    EZO_INSTANCE_RESET_STATUS_SECTION_GROUP = "GRUPO",
    EZO_INSTANCE_RESET_STATUS_SECTION_ACTION = "ACCIÓN NECESARIA",
    EZO_INSTANCE_RESET_STATUS_ACTIVITY = "<<1>>  |  <<2>>",
    EZO_INSTANCE_RESET_STATUS_GROUP_SUMMARY = "Capturados: <<1>>  |  actualmente en grupo: <<2>>",
    EZO_INSTANCE_RESET_STATUS_GROUP_PENDING_SUMMARY = "Pendientes: <<1>>  |  no capturados: <<2>>",
    EZO_INSTANCE_RESET_STATUS_INVITES_COMPACT = "Invitaciones: <<1>>  |  solicitudes: <<2>>  |  intento: <<3>>",
    EZO_INSTANCE_RESET_STATUS_ADDITIONAL = "No capturados en el reset: <<1>>",
    EZO_INSTANCE_RESET_STATUS_MEMBER_ROW_COMPACT = "- <<1>>  |  <<2>>  |  sol.: <<3>>",
    EZO_INSTANCE_RESET_STATUS_PROGRESS = "<<1>> / <<2>>",
    EZO_INSTANCE_RESET_STATUS_METRIC_CAPTURED = "Capturados",
    EZO_INSTANCE_RESET_STATUS_METRIC_IN_GROUP = "En grupo",
    EZO_INSTANCE_RESET_STATUS_METRIC_PENDING = "Pendientes",
    EZO_INSTANCE_RESET_STATUS_METRIC_INVITES = "Solicitudes",
    EZO_INSTANCE_RESET_STATUS_MEMBER_STATE_REQUESTS = "<<1>> · invitaciones enviadas: <<2>>",
    EZO_INSTANCE_RESET_MEMBER_STATUS_LEFT = "salió",
    EZO_INSTANCE_RESET_MEMBER_STATUS_KICKED = "expulsado",
    EZO_INSTANCE_RESET_MEMBER_LOCATION_SAME = "misma instancia que el líder",
    EZO_INSTANCE_RESET_MEMBER_LOCATION_DIFFERENT = "otra instancia",
    EZO_INSTANCE_RESET_MEMBER_LOCATION_UNKNOWN = "ubicación desconocida",
    EZO_INSTANCE_RESET_STAGE_STARTING = "iniciando",
    EZO_INSTANCE_RESET_STAGE_DISBANDING = "disbandeando grupo",
    EZO_INSTANCE_RESET_STAGE_WAITING_COMBAT = "esperando a salir de combate",
    EZO_INSTANCE_RESET_STAGE_TRAVELING_HOME = "viajando a casa puente",
    EZO_INSTANCE_RESET_STAGE_LEAVING_INSTANCE = "saliendo de la instancia capturada",
    EZO_INSTANCE_RESET_STAGE_TRAVEL_FAILED = "acción interrumpida: ESO rechazó la solicitud de viaje",
    EZO_INSTANCE_RESET_STAGE_WAITING_HOME = "esperando en casa puente",
    EZO_INSTANCE_RESET_STAGE_WAITING_OUTSIDE_INSTANCE = "esperando fuera de la instancia capturada",
    EZO_INSTANCE_RESET_STAGE_HOME_NOT_REACHED = "acción interrumpida: no se alcanzó la casa puente",
    EZO_INSTANCE_RESET_STAGE_INSTANCE_NOT_LEFT = "acción interrumpida: no se abandonó la instancia capturada",
    EZO_INSTANCE_RESET_STAGE_DISBAND_NOT_CONFIRMED = "acción interrumpida: disband del grupo no confirmado",
    EZO_INSTANCE_RESET_STAGE_RETURNING = "volviendo a la instancia",
    EZO_INSTANCE_RESET_STAGE_RETURN_CANCELLED_MOVEMENT = "Viaje de regreso cancelado porque el líder se movió.",
    EZO_INSTANCE_RESET_STAGE_RETURN_CANCELLED = "El viaje de regreso no llegó a iniciarse y se canceló.",
    EZO_INSTANCE_RESET_STAGE_TARGET_NOT_CONFIRMED = "acción interrumpida: no se alcanzó la instancia objetivo",
    EZO_INSTANCE_RESET_STAGE_RETURN_UNAVAILABLE = "acción interrumpida: viaje de vuelta no disponible",
    EZO_INSTANCE_RESET_STAGE_RETURNED = "vuelta / preparando invitaciones",
    EZO_INSTANCE_RESET_STAGE_NO_TARGET = "sin trial objetivo detectada",
    EZO_INSTANCE_RESET_STAGE_WAITING_INVITES = "esperando para invitar",
    EZO_INSTANCE_RESET_STAGE_INVITING = "invitando miembros capturados",
    EZO_INSTANCE_RESET_STAGE_WAITING_MEMBERS = "esperando a miembros pendientes",
    EZO_INSTANCE_RESET_STAGE_WAITING_TRIAL_ENTRY = "esperando la entrada real en la trial",
    EZO_INSTANCE_RESET_STAGE_READY_FOR_ENTRY = "Acciones del reset completadas. Esperando a entrar en la trial.",
    EZO_INSTANCE_RESET_STAGE_INVITES_UNAVAILABLE = "API de invitación de grupo no disponible",
    EZO_INSTANCE_RESET_STAGE_RESUME_INVALID = "acción interrumpida: fase guardada no válida",
    EZO_INSTANCE_RESET_STAGE_COMPLETE = "completado",
    EZO_INSTANCE_RESET_STAGE_FAILED = "fallido",
    EZO_CONFIRM_RAID_ACTION_TITLE = "Confirmar acción",
    EZO_CONFIRM_RAID_ACTION_CONFIRM = "Confirmar",
    EZO_CONFIRM_DISBAND_GROUP_TITLE = "¿Disbandear grupo?",
    EZO_CONFIRM_DISBAND_GROUP_TEXT = "Esto disbandeará el grupo actual. Continúa solo si quieres romper el grupo intencionadamente.",
    EZO_CONFIRM_DISBAND_GROUP_CONFIRM = "Disbandear",
    EZO_CONFIRM_INSTANCE_RESET_TITLE = "¿Resetear instancia?",
    EZO_CONFIRM_INSTANCE_RESET_TEXT = "Esto capturará el grupo, la trial y el modo, disbandeará el grupo, viajará a la casa puente configurada, esperará, volverá cuando sea posible e invitará a los miembros capturados.",
    EZO_CONFIRM_INSTANCE_RESET_CONFIRM = "Iniciar reset",
    EZO_CONFIRM_INSTANCE_RESET_RESUME_TITLE = "¿Reanudar reset de instancia?",
    EZO_CONFIRM_INSTANCE_RESET_RESUME_TEXT = "Esto continúa el reset guardado desde la fase interrumpida sin volver a capturar ni disbandear el grupo, salvo que esa fase no se hubiera completado.",
    EZO_CONFIRM_INSTANCE_RESET_RESUME_CONFIRM = "Reanudar reset",
    EZO_CONFIRM_INSTANCE_RESET_CANCEL_TITLE = "¿Cancelar reset de instancia?",
    EZO_CONFIRM_INSTANCE_RESET_CANCEL_TEXT = "Esto detiene el seguimiento del reset de EZOTools y borra la sesión actual. No puede retirar invitaciones ya enviadas ni un viaje que ESO ya haya aceptado.",
    EZO_CONFIRM_INSTANCE_RESET_CANCEL_CONFIRM = "Cancelar reset",
    EZO_CONFIRM_LAST_GROUP_ACTIVITY_TITLE = "¿Iniciar último grupo e instancia?",
    EZO_CONFIRM_LAST_GROUP_ACTIVITY_TEXT = "Esto invita a los <<2>> miembros guardados del último grupo de reset y después viaja a <<1>> con la dificultad memorizada. Siguen aplicándose las restricciones de grupo y viaje.",
    EZO_CONFIRM_LAST_GROUP_ACTIVITY_CONFIRM = "Invitar y viajar",

    EZO_CMD_VERSION_HEADER      = "=== EZOTools v<<1>> ===",
    EZO_CMD_VERSION_API         = "  API ESO: <<1>>",
    EZO_CMD_VERSION_LANGUAGE    = "  Idioma: <<1>>",
    EZO_CMD_VERSION_LAM         = "  LibAddonMenu: <<1>>",
    EZO_CMD_VERSION_OVERLAY     = "  Módulo overlay: <<1>>",
    EZO_CMD_VERSION_GAMEPAD     = "  Diálogo gamepad: <<1>>",
    EZO_CMD_LAYOUT_ON           = "Previsualización del diseño: ACTIVADA",
    EZO_CMD_LAYOUT_OFF          = "Previsualización del diseño: DESACTIVADA",
    EZO_CMD_LAYOUT_NA           = "La previsualización del diseño no está disponible.",
    EZO_SIDE_WIDGET_LEFT        = "Izquierda",
    EZO_SIDE_WIDGET_RIGHT       = "Derecha",
    EZO_SIDE_WIDGET_PREVIEW_TOOLTIP = "Vista previa del icono: <<1>> #<<2>>",
    EZO_SIDE_WIDGET_SOUL_GEMS_TOOLTIP = "Gemas de alma cargadas bajas: <<1>> disponibles (umbral <<2>>). Clic para abrir ajustes.",
    EZO_SIDE_WIDGET_REPAIR_KITS_TOOLTIP = "Kits de reparación bajos: <<1>> disponibles (umbral <<2>>). Clic para abrir ajustes.",
}
EZO_STRINGS_ES["EZO_OPTION_LOW_STOCK_ALERTS_NOTE"] = "Estas alertas controlan los iconos laterales. Las gemas de alma se cuentan como gemas cargadas utilizables. Los kits de reparación se cuentan por unidades detectadas y, por ahora, no se diferencian los kits de una pieza y los de reparación completa."
EZO_STRINGS_ES["EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE"] = "Usar imagen propia del gremio representado"
EZO_STRINGS_ES["EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE_TOOLTIP"] = "Si está activado y el gremio representado tiene una imagen registrada en el addon, el logo central se sustituye por esa imagen. Si no hay imagen válida, se mantiene el logo normal de EZOTools."
EZO_STRINGS_ES["EZO_OPTION_REPAIR_KIT_ALERT_ENABLE"] = "Mostrar alerta de kits bajos"
EZO_STRINGS_ES["EZO_OPTION_REPAIR_KIT_ALERT_ENABLE_TOOLTIP"] = "Muestra u oculta el widget lateral cuando los kits de reparación estén bajos."
EZO_STRINGS_ES["EZO_OPTION_REPAIR_KIT_ALERT_THRESHOLD"] = "Umbral alerta kits reparación"
EZO_STRINGS_ES["EZO_OPTION_REPAIR_KIT_ALERT_THRESHOLD_TOOLTIP"] = "Muestra la alerta de kits cuando la cantidad detectada de kits de reparación sea igual o inferior a este valor."
EZO_STRINGS_ES["EZO_OPTION_SOUL_GEM_ALERT_ENABLE"] = "Mostrar alerta de gemas bajas"
EZO_STRINGS_ES["EZO_OPTION_SOUL_GEM_ALERT_ENABLE_TOOLTIP"] = "Muestra u oculta el widget lateral cuando las gemas de alma cargadas estén bajas."
EZO_STRINGS_ES["EZO_OPTION_SOUL_GEM_ALERT_THRESHOLD"] = "Umbral alerta gemas de alma"
EZO_STRINGS_ES["EZO_OPTION_SOUL_GEM_ALERT_THRESHOLD_TOOLTIP"] = "Muestra la alerta de gemas cuando la cantidad detectada de gemas de alma cargadas sea igual o inferior a este valor."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_REPAIR_EQUIPPED_TOOLTIP"] = "Se necesita reparar armadura (umbral <<1>>%). Clic izquierdo repara el equipo equipado. Clic derecho abre ajustes."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_RECHARGE_WEAPONS_TOOLTIP"] = "Se necesita recargar armas (umbral <<1>>%). Clic izquierdo recarga las armas. Clic derecho abre ajustes."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_NONE_TOOLTIP"] = "No tienes comida o bebida activa.|nUsa una comida o bebida para guardarla aquí.|nClic derecho: últimas comidas y bebidas."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_ACTIVE_TOOLTIP"] = "Comida o bebida activa: <<1>>. Tiempo restante: <<2>>.|nClic derecho: últimas comidas y bebidas."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_ACTIVE_NO_TIME_TOOLTIP"] = "Comida o bebida activa: <<1>>.|nClic derecho: últimas comidas y bebidas."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_ALERT_REUSE_TOOLTIP"] = "<<1>>|nClic izquierdo para volver a consumirla.|nClic derecho: últimas comidas y bebidas."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_ALERT_REUSE_LEGENDARY_TOOLTIP"] = "<<1>>|nClic izquierdo para volver a consumirla.|nClic derecho: últimas comidas y bebidas."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_RECALL_TOOLTIP"] = "No tienes comida o bebida activa.|nClic izquierdo para volver a consumir <<1>>.|nClic derecho: últimas comidas y bebidas."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_RECALL_LEGENDARY_TOOLTIP"] = "No tienes comida o bebida activa.|nClic izquierdo para volver a consumir <<1>>.|nClic derecho: últimas comidas y bebidas."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_ACTIVE_REUSE_TOOLTIP"] = "Comida o bebida activa: <<1>>. Tiempo restante: <<2>>.|nClic izquierdo para volver a consumirla.|nClic derecho: últimas comidas y bebidas."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_ACTIVE_REUSE_LEGENDARY_TOOLTIP"] = "Comida o bebida activa: <<1>>. Tiempo restante: <<2>>.|nClic izquierdo para volver a consumirla.|nClic derecho: últimas comidas y bebidas."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_CONFIRM_TITLE"] = "Confirmar consumo"
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_CONFIRM_TEXT"] = "Vas a consumir <<1>>."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_CONFIRM_TEXT_WITH_TIME"] = "Vas a consumir <<1>>.|n|nTiempo restante del efecto actual: |cC8A95A<<2>>|r."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_CONFIRM_TEXT_WITH_EFFECT"] = "Vas a consumir <<1>>.|n|nEfecto: <<2>>"
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_CONFIRM_TEXT_WITH_EFFECT_AND_TIME"] = "Vas a consumir <<1>>.|n|nEfecto: <<2>>|n|nTiempo restante del efecto actual: |cC8A95A<<3>>|r."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_HISTORY_EMPTY"] = "No hay comida o bebida guardada todavía.|nAbre el inventario del juego y usa una para añadirla aquí."
EZO_STRINGS_ES["EZO_TIME_REMAINING_HM"] = "<<1>>h <<2>>m"
EZO_STRINGS_ES["EZO_TIME_REMAINING_MS"] = "<<1>>m <<2>>s"
EZO_STRINGS_ES["EZO_TIME_REMAINING_S"] = "<<1>>s"
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_PREVIEW_TOOLTIP"] = "Vista previa: estado de comida o bebida."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_REPAIR_EQUIPPED_PREVIEW_TOOLTIP"] = "Vista previa: reparación de armadura."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_REPAIR_KITS_PREVIEW_TOOLTIP"] = "Vista previa: stock bajo de kits de reparación."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_RECHARGE_WEAPONS_PREVIEW_TOOLTIP"] = "Vista previa: recarga de armas."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_SOUL_GEMS_PREVIEW_TOOLTIP"] = "Vista previa: stock bajo de gemas de alma."
EZO_STRINGS_ES["EZO_DOT_MOUNT_ACTIVE_TOOLTIP"] = "<<1>>|nClic izquierdo para seleccionarla.|nClic derecho: últimas monturas."
EZO_STRINGS_ES["EZO_DOT_MOUNT_INACTIVE_TOOLTIP"] = "<<1>>|nClic izquierdo para seleccionarla.|nClic derecho: últimas monturas."
EZO_STRINGS_ES["EZO_DOT_MOUNT_EMPTY_TOOLTIP"] = "No hay monturas guardadas todavía.|nSelecciona una montura para añadirla aquí.|nClic derecho: últimas monturas."
EZO_STRINGS_ES["EZO_DOT_PET_ACTIVE_TOOLTIP"] = "<<1>>|nClic izquierdo para ocultarla.|nClic derecho: últimas mascotas."
EZO_STRINGS_ES["EZO_DOT_PET_INACTIVE_TOOLTIP"] = "<<1>>|nClic izquierdo para invocarla.|nClic derecho: últimas mascotas."
EZO_STRINGS_ES["EZO_DOT_PET_EMPTY_TOOLTIP"] = "No hay mascotas guardadas todavía.|nInvoca una mascota para añadirla aquí.|nClic derecho: últimas mascotas."
EZO_STRINGS_ES["EZO_DOT_COMPANION_ACTIVE_TOOLTIP"] = "<<1>>|nClic izquierdo para ocultarlo.|nClic derecho: últimos compañeros."
EZO_STRINGS_ES["EZO_DOT_COMPANION_INACTIVE_TOOLTIP"] = "<<1>>|nClic izquierdo para invocarlo.|nClic derecho: últimos compañeros."
EZO_STRINGS_ES["EZO_DOT_COMPANION_EMPTY_TOOLTIP"] = "No hay compañeros guardados todavía.|nInvoca un compañero para añadirlo aquí.|nClic derecho: últimos compañeros."
EZO_STRINGS_ES["EZO_DOT_ASSISTANT_ACTIVE_TOOLTIP"] = "<<1>>|nClic izquierdo para ocultarlo.|nClic derecho: últimos asistentes."
EZO_STRINGS_ES["EZO_DOT_ASSISTANT_INACTIVE_TOOLTIP"] = "<<1>>|nClic izquierdo para invocarlo.|nClic derecho: últimos asistentes."
EZO_STRINGS_ES["EZO_DOT_ASSISTANT_EMPTY_TOOLTIP"] = "No hay asistentes guardados todavía.|nInvoca un asistente para añadirlo aquí.|nClic derecho: últimos asistentes."
EZO_STRINGS_ES["EZO_DOT_MOUNT_FALLBACK_NAME"] = "Montura"
EZO_STRINGS_ES["EZO_DOT_PET_FALLBACK_NAME"] = "Mascota"
EZO_STRINGS_ES["EZO_DOT_COMPANION_FALLBACK_NAME"] = "Compañero"
EZO_STRINGS_ES["EZO_DOT_ASSISTANT_FALLBACK_NAME"] = "Asistente"
EZO_STRINGS_ES["EZO_DOT_MOUNT_HISTORY_EMPTY"] = "No hay monturas guardadas todavía.|nSelecciona una montura para añadirla aquí."
EZO_STRINGS_ES["EZO_DOT_PET_HISTORY_EMPTY"] = "No hay mascotas guardadas todavía.|nInvoca una mascota para añadirla aquí."
EZO_STRINGS_ES["EZO_DOT_COMPANION_HISTORY_EMPTY"] = "No hay compañeros guardados todavía.|nInvoca un compañero para añadirlo aquí."
EZO_STRINGS_ES["EZO_DOT_ASSISTANT_HISTORY_EMPTY"] = "No hay asistentes guardados todavía.|nInvoca un asistente para añadirlo aquí."
EZO_STRINGS_ES["EZO_UTILITY_EMPTY_OPEN_MOUNT_COLLECTIONS"] = "Abrir colecciones de monturas"
EZO_STRINGS_ES["EZO_UTILITY_EMPTY_OPEN_PET_COLLECTIONS"] = "Abrir colecciones de mascotas"
EZO_STRINGS_ES["EZO_UTILITY_EMPTY_OPEN_COMPANION_COLLECTIONS"] = "Abrir pantalla de compañeros"
EZO_STRINGS_ES["EZO_UTILITY_EMPTY_OPEN_ASSISTANT_COLLECTIONS"] = "Abrir colecciones de asistentes"
EZO_STRINGS_ES["EZO_CMD_DEBUG_FOOD"] = "/ezo debug food green|yellow|red|auto - fuerza el estado del icono de comida"
EZO_STRINGS_ES["EZO_CMD_DEBUG_FOOD_USAGE"] = "Uso: /ezo debug food green|yellow|red|auto"
EZO_STRINGS_ES["EZO_CMD_DEBUG_FOOD_SET"] = "Estado debug de comida: <<1>>"
EZO_STRINGS_ES["EZO_DEBUG_FOOD_NAME"] = "Comida de prueba"
