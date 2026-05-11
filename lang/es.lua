-- Cadenas en español para EZOTools.
-- REGLA: mismas claves que en.lua, mismo orden.
EZO_STRINGS_ES = {

    -- -------------------------------------------------------------------------
    -- Categoría de keybind
    -- -------------------------------------------------------------------------
    SI_BINDING_CATEGORY_EZOTools                = "E|cB040FFZ|rOTools",
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

    -- -------------------------------------------------------------------------
    -- Mensajes generales del addon
    -- -------------------------------------------------------------------------
    EZO_MSG_INIT                = "E|cB040FFZ|rOTools inicializado.",
    EZO_MSG_SLASH               = "Comando /ezo recibido",
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
    EZO_OPTION_LANGUAGE                 = "Idioma",
    EZO_OPTION_LANGUAGE_TOOLTIP         = "Cambia los textos del addon al momento. Los nombres de keybind en la pantalla de controles pueden requerir /reloadui.",

    -- -------------------------------------------------------------------------
    -- Panel LAM: sección Overlay
    -- -------------------------------------------------------------------------
    EZO_OPTION_OVERLAY                  = "Overlay",
    EZO_OPTION_OVERLAY_ENABLE           = "Activar overlay",
    EZO_OPTION_OVERLAY_LOCK             = "Bloquear posición del overlay",
    EZO_OPTION_OVERLAY_SIMULATE_GAMEPAD = "Simular estilo Gamepad (solo overlay)",
    EZO_OPTION_OVERLAY_HIDE_COMBAT      = "Ocultar en combate",
    EZO_OPTION_OVERLAY_HIDE_MENUS       = "Ocultar en menús",
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
    EZO_OPTION_GUILD_LABEL_COLOR_TOOLTIP = "Sólo se aplica cuando hay un gremio representado seleccionado y no llevas tabardo. Los estados de tabardo y sin gremio mantienen sus colores actuales.",
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
    EZO_OPTION_FRIENDS_EDIT_PROFILE_NOTE = "Las casillas de abajo solo editan el perfil seleccionado. No cambian las casas activas hasta guardar y aplicar el perfil correspondiente.",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD = "Perfil que estás editando",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD_TOOLTIP = "Elige Valores propios o un gremio de tu lista para editar sus casas guardadas. Esto no cambia qué perfil está autoasignado; la autoasignación usa siempre el gremio representado en C.",
    EZO_OPTION_FRIENDS_PROFILE_MANUAL = "Valores propios",
    EZO_OPTION_FRIENDS_SAVE_SELECTED = "Guardar perfil editado",
    EZO_OPTION_FRIENDS_SAVE_SELECTED_TOOLTIP = "Guarda las casas escritas para el perfil seleccionado. Si ese perfil coincide con el gremio autoasignado actual, se actualizarán también las casas activas.",
    EZO_OPTION_FRIENDS_CRAFTING = "Editar casa de artesanía (@jugador)",
    EZO_OPTION_FRIENDS_SECONDARY= "Editar casa secundaria (@jugador)",

    -- -------------------------------------------------------------------------
    -- Panel LAM: sección Mantenimiento
    -- -------------------------------------------------------------------------
    EZO_OPTION_MAINTENANCE                = "Mantenimiento",
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
    EZO_MENU_REPAIR               = "Reparar equipo (<= <<1>>%)",
    EZO_MENU_RECHARGE             = "Recargar armas (<= <<1>>%)",
    EZO_MENU_RELOAD               = "Recargar interfaz",
    EZO_MENU_OPEN_GAMEPAD_CHAT_EXPERIMENTAL = "Abrir chat (experimental)",
    EZO_MENU_DEBUG_VIEWER         = "Abrir visor técnico",
    EZO_MENU_EXIT                 = "Cerrar",

    -- -------------------------------------------------------------------------
    -- Submenú de ajustes rápidos (gamepad_settings)
    -- -------------------------------------------------------------------------
    EZO_SETTINGS_TITLE              = "Ajustes",
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
    EZO_MSG_MENU_CALLBACK_FAILED = "Debug menú: error al ejecutar una opción: <<1>>",
    EZO_MSG_DEBUG_VIEWER_UNAVAILABLE = "Visor técnico no disponible.",
    EZO_MSG_DEBUG_LOGGER_UNAVAILABLE = "Diagnóstico técnico no disponible; no se ha generado reporte.",
    EZO_MSG_DEBUG_REPORT_SENT = "Diagnóstico generado: <<1>>",
    EZO_MSG_DEBUG_REPORT_LOGGED_VIEWER_MISSING = "Diagnóstico generado: <<1>>. Visor técnico no disponible.",
    EZO_MSG_INPUT_MODE_SET      = "Modo de entrada: <<1>>",
    EZO_MSG_INPUT_MODE_NA       = "Ajuste de modo de entrada no disponible.",

    -- -------------------------------------------------------------------------
    -- Salida de comandos slash
    -- -------------------------------------------------------------------------
    EZO_CMD_BANNER              = "E|cB040FFZ|rOTools v<<1>> — @Zuriplayer",
    EZO_CMD_REGISTERED          = "Comandos registrados: /ezo, /ezotools",
    EZO_CMD_HELP_TITLE          = "Comandos disponibles:",
    EZO_CMD_HELP_STATUS         = "  /ezo status   — estado runtime del addon",
    EZO_CMD_HELP_DEBUG          = "  /ezo debug    — lista comandos de diagnóstico",
    EZO_CMD_HELP_HELP           = "  /ezo help",
    EZO_CMD_HELP_DETAIL_STATUS  = "    status muestra versión cargada, idioma activo y disponibilidad de módulos principales.",
    EZO_CMD_HELP_DETAIL_DEBUG   = "    debug agrupa herramientas técnicas de soporte y desarrollo; no son comandos de uso normal.",
    EZO_CMD_HELP_CONTACT        = "    Para incidencias, dudas o feedback del addon, puedes contactar con @Zuriplayer.",

    EZO_CMD_DEBUG_TITLE         = "Comandos de diagnóstico",
    EZO_CMD_DEBUG_INFO          = "  /ezo debug info     — diagnóstico: zona, grupo, mantenimiento y gremio",
    EZO_CMD_DEBUG_GUILDS        = "  /ezo debug guilds   — lista tus gremios y cuál está representado",
    EZO_CMD_DEBUG_TEX           = "  /ezo debug tex      — estado de iconos del overlay",
    EZO_CMD_DEBUG_TEXLOAD       = "  /ezo debug texload  — prueba de carga de texturas",
    EZO_CMD_DEBUG_DOTS          = "  /ezo debug dots     — estado de iconos de mascota y aliados",
    EZO_CMD_DEBUG_LAYOUT        = "  /ezo debug layout   — alterna preview de slots laterales",
    EZO_CMD_DEBUG_HOUSE         = "  /ezo debug house    — diagnóstico de vivienda actual",

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
    EZO_CMD_INFO_NO_GROUP       = "  Grupo: sin grupo",
    EZO_CMD_INFO_REPAIR         = "  Reparación (umbral <<1>>%): <<2>>",
    EZO_CMD_INFO_RECHARGE       = "  Recarga armas (umbral <<1>>%): <<2>>",
    EZO_CMD_INFO_NEEDED         = "NECESARIA",
    EZO_CMD_INFO_OK             = "OK",
    EZO_CMD_INFO_GUILD          = "  Gremio representado: <<1>> (id=<<2>>)",
    EZO_CMD_INFO_NO_GUILD       = "  Gremio representado: ninguno",

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
EZO_STRINGS_ES["EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE"] = "Usar imagen propia del gremio"
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
EZO_STRINGS_ES["EZO_SIDE_WIDGET_RECHARGE_WEAPONS_TOOLTIP"] = "Se necesita recargar armas (umbral <<1>>%). Clic izquierdo abre el menú del overlay. Clic derecho abre ajustes."
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
