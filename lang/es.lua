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

    -- -------------------------------------------------------------------------
    -- Mensajes generales del addon
    -- -------------------------------------------------------------------------
    EZO_MSG_INIT                = "E|cB040FFZ|rOTools inicializado.",
    EZO_MSG_SLASH               = "Comando /ezo recibido",
    EZO_MSG_HIDE_PET            = "Ocultando mascota",
    EZO_MSG_HIDE_COMPANION      = "Ocultando companion",
    EZO_MSG_HIDE_ASSISTANT      = "Ocultando asistente",

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
    EZO_OPTION_OVERLAY_ALPHA            = "Opacidad del overlay",
    EZO_OPTION_OVERLAY_SCALE            = "Escala del overlay",
    EZO_OPTION_OVERLAY_PLAYER_TEXT_COLOR = "Color del nombre del jugador",
    EZO_OPTION_OVERLAY_PLAYER_TEXT_SIZE = "Tamaño del nombre del jugador",
    EZO_OPTION_OVERLAY_TEXT             = "Texto del overlay",
    EZO_OPTION_OVERLAY_RESET_POS        = "Reiniciar posición del overlay",
    EZO_OPTION_GUILD_OVERLAY            = "Guild Overlay",
    EZO_OPTION_GUILD_LABEL_COLOR        = "Color del nombre de la guild representada",
    EZO_OPTION_GUILD_LABEL_COLOR_TOOLTIP = "Sólo se aplica cuando hay una guild representada seleccionada y no llevas tabardo. Los estados de tabardo y sin guild mantienen sus colores actuales.",

    -- -------------------------------------------------------------------------
    -- Panel LAM: sección Casas de amigos
    -- -------------------------------------------------------------------------
    EZO_OPTION_FRIENDS          = "Casas de amigos",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN = "Autoasignar casas desde guild seleccionada",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_TOOLTIP = "Si está activado, el addon rellena automáticamente la casa de artesanía y la secundaria usando la guild elegida en el selector, siempre que pertenezcas a una guild soportada por el addon.",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD = "Guild para autoasignación",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD_TOOLTIP = "Selecciona una de tus guilds soportadas por el addon. La autoasignación usará primero la configuración que hayas guardado para esa guild y, si no existe, la asignación interna del addon.",
    EZO_OPTION_FRIENDS_SAVE_SELECTED = "Guardar casas para la guild seleccionada",
    EZO_OPTION_FRIENDS_SAVE_SELECTED_TOOLTIP = "Guarda los valores actuales de Crafting Hall y Secondary Hall para la guild seleccionada. La autoasignación usará esta configuración guardada antes que la interna.",
    EZO_OPTION_FRIENDS_CRAFTING = "Crafting Hall (nombre de cuenta @...)",
    EZO_OPTION_FRIENDS_SECONDARY= "Secondary Hall (nombre de cuenta @...)",

    -- -------------------------------------------------------------------------
    -- Panel LAM: sección Mantenimiento
    -- -------------------------------------------------------------------------
    EZO_OPTION_MAINTENANCE                = "Mantenimiento",
    EZO_OPTION_STOCK_ALERTS               = "Alertas de stock",
    EZO_OPTION_REPAIR_THRESHOLD           = "Umbral de reparación de equipo (%)",
    EZO_OPTION_REPAIR_THRESHOLD_TOOLTIP   = "La opción 'Reparar equipo' aparece en el menú solo si alguna pieza está por debajo de este porcentaje de durabilidad.",
    EZO_OPTION_RECHARGE_THRESHOLD         = "Umbral de recarga de armas (%)",
    EZO_OPTION_RECHARGE_THRESHOLD_TOOLTIP = "La opción 'Recargar armas' aparece en el menú solo si algún arma está por debajo de este porcentaje de carga de encantamiento.",

    -- -------------------------------------------------------------------------
    -- Entradas del panel de comandos
    -- -------------------------------------------------------------------------
    EZO_MENU_TITLE                = "EZOTools",
    EZO_MENU_DIALOG_SUBTITLE      = "<<1>>  ·  v<<2>>",
    EZO_MENU_SETTINGS             = "Ajustes rápidos",
    EZO_MENU_ADDON_SETTINGS       = "Ajustes completos (LAM)",
    EZO_MENU_TRAVEL_PRIMARY       = "Ir a mi casa",
    EZO_MENU_TRAVEL_CRAFTING      = "Ir a la casa de artesanía",
    EZO_MENU_TRAVEL_SECONDARY     = "Ir a la casa secundaria",
    EZO_MENU_JUMP_LEADER          = "Saltar al líder",
    EZO_MENU_LEAVE_GROUP          = "Abandonar grupo",
    EZO_MENU_LEAVE_INSTANCE       = "Salir de instancia",
    EZO_MENU_LEAVE_GROUP_INSTANCE = "Abandonar grupo y salir de instancia",
    EZO_MENU_REPAIR               = "Reparar equipo (<= <<1>>%)",
    EZO_MENU_RECHARGE             = "Recargar armas (<= <<1>>%)",
    EZO_MENU_RELOAD               = "Recargar interfaz",
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
    EZO_OVERLAY_NO_GUILD        = "Sin hermandad",
    EZO_OVERLAY_TABARD          = "Tabardo",

    -- -------------------------------------------------------------------------
    -- Mensajes de chat: viajes
    -- -------------------------------------------------------------------------
    EZO_MSG_NO_PRIMARY_HOUSE    = "No hay casa principal configurada.",
    EZO_MSG_NO_CRAFTING_HALL    = "Configura una Crafting Hall en los ajustes.",
    EZO_MSG_NO_SECONDARY_HALL   = "Configura una Secondary Hall en los ajustes.",

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
    EZO_MSG_INPUT_MODE_SET      = "Modo de entrada: <<1>>",
    EZO_MSG_INPUT_MODE_NA       = "Ajuste de modo de entrada no disponible.",

    -- -------------------------------------------------------------------------
    -- Salida de comandos slash
    -- -------------------------------------------------------------------------
    EZO_CMD_BANNER              = "E|cB040FFZ|rOTools v<<1>> — @Zuriplayer",
    EZO_CMD_REGISTERED          = "Comandos registrados: /ezo, /ezotools",
    EZO_CMD_HELP_TITLE          = "Comandos disponibles:",
    EZO_CMD_HELP_VERSION        = "  /ezo version  — versión cargada y estado runtime",
    EZO_CMD_HELP_DEBUG          = "  /ezo debug    — lista comandos de diagnóstico",
    EZO_CMD_HELP_HELP           = "  /ezo help",

    EZO_CMD_DEBUG_TITLE         = "Comandos de diagnóstico:",
    EZO_CMD_DEBUG_INFO          = "  /ezo debug info     — diagnóstico: zona, grupo, mantenimiento, guild",
    EZO_CMD_DEBUG_GUILDS        = "  /ezo debug guilds   — lista tus guilds y cuál está representada",
    EZO_CMD_DEBUG_TEX           = "  /ezo debug tex      — estado de iconos del overlay",
    EZO_CMD_DEBUG_TEXLOAD       = "  /ezo debug texload  — prueba de carga de texturas",
    EZO_CMD_DEBUG_DOTS          = "  /ezo debug dots     — estado de dots pet/companion",
    EZO_CMD_DEBUG_LAYOUT        = "  /ezo debug layout   — alterna preview de slots laterales",
    EZO_CMD_DEBUG_REPAIRKITICON = "  /ezo debug repairkiticon — ruta del icono del primer repair kit",
    EZO_CMD_DEBUG_SOULGEMICON   = "  /ezo debug soulgemicon   — ruta del icono de la primera soul gem",

    EZO_CMD_GUILDS_NONE         = "No perteneces a ninguna hermandad.",
    EZO_CMD_GUILDS_HEADER       = "Hermandades (<<1>>):",
    EZO_CMD_GUILDS_ROW          = "  [<<1>>] <<2>> (<<3>> mbr) id=<<4>><<5>>",
    EZO_CMD_GUILDS_REPRESENTED  = " < REPRESENTADA",
    EZO_CMD_GUILDS_NONE_REP     = "Ninguna hermandad representada actualmente.",

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
    EZO_CMD_INFO_GUILD          = "  Hermandad representada: <<1>> (id=<<2>>)",
    EZO_CMD_INFO_NO_GUILD       = "  Hermandad representada: ninguna",

    EZO_CMD_VERSION_HEADER      = "=== EZOTools v<<1>> ===",
    EZO_CMD_VERSION_LANGUAGE    = "  Idioma: <<1>>",
    EZO_CMD_VERSION_LAM         = "  LibAddonMenu: <<1>>",
    EZO_CMD_VERSION_OVERLAY     = "  Módulo overlay: <<1>>",
    EZO_CMD_VERSION_GAMEPAD     = "  Diálogo gamepad: <<1>>",
    EZO_CMD_LAYOUT_ON           = "Preview layout: ON",
    EZO_CMD_LAYOUT_OFF          = "Preview layout: OFF",
    EZO_CMD_LAYOUT_NA           = "Preview layout no disponible.",
    EZO_SIDE_WIDGET_LEFT        = "Izquierda",
    EZO_SIDE_WIDGET_RIGHT       = "Derecha",
    EZO_SIDE_WIDGET_PREVIEW_TOOLTIP = "Widget preview: <<1>> #<<2>>",
    EZO_SIDE_WIDGET_SOUL_GEMS_TOOLTIP = "Gemas de alma cargadas bajas: <<1>> disponibles (umbral <<2>>). Clic para abrir ajustes.",
    EZO_SIDE_WIDGET_REPAIR_KITS_TOOLTIP = "Kits de reparación bajos: <<1>> disponibles (umbral <<2>>). Clic para abrir ajustes.",
}
EZO_STRINGS_ES["EZO_OPTION_LOW_STOCK_ALERTS_NOTE"] = "Las alertas de stock bajo controlan los widgets laterales. Las gemas se cuentan como gemas cargadas utilizables. Los kits de reparación se cuentan por unidades detectadas, sin distinguir todavía entre kits de una pieza y kits de reparación completa."
EZO_STRINGS_ES["EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE"] = "Usar imagen personalizada de la guild representada"
EZO_STRINGS_ES["EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE_TOOLTIP"] = "Si está activado y la guild representada tiene una imagen registrada en el addon, el logo central se sustituye por esa imagen. Si falta la imagen o hay cualquier duda, se mantiene el logo normal de EZOTools."
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
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_NONE_TOOLTIP"] = "No tienes comida o bebida activa."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_ACTIVE_TOOLTIP"] = "Comida o bebida activa: <<1>>. Tiempo restante: <<2>>."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_ACTIVE_NO_TIME_TOOLTIP"] = "Comida o bebida activa: <<1>>."
EZO_STRINGS_ES["EZO_TIME_REMAINING_HM"] = "<<1>>h <<2>>m"
EZO_STRINGS_ES["EZO_TIME_REMAINING_MS"] = "<<1>>m <<2>>s"
EZO_STRINGS_ES["EZO_TIME_REMAINING_S"] = "<<1>>s"
EZO_STRINGS_ES["EZO_SIDE_WIDGET_FOOD_PREVIEW_TOOLTIP"] = "Preview: estado de comida o bebida."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_REPAIR_EQUIPPED_PREVIEW_TOOLTIP"] = "Preview: reparación de armadura."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_REPAIR_KITS_PREVIEW_TOOLTIP"] = "Preview: stock bajo de kits de reparación."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_RECHARGE_WEAPONS_PREVIEW_TOOLTIP"] = "Preview: recarga de armas."
EZO_STRINGS_ES["EZO_SIDE_WIDGET_SOUL_GEMS_PREVIEW_TOOLTIP"] = "Preview: stock bajo de gemas de alma."
EZO_STRINGS_ES["EZO_CMD_DEBUG_FOOD"] = "/ezo debug food green|yellow|red|auto - fuerza el estado del icono de comida"
EZO_STRINGS_ES["EZO_CMD_DEBUG_FOOD_USAGE"] = "Uso: /ezo debug food green|yellow|red|auto"
EZO_STRINGS_ES["EZO_CMD_DEBUG_FOOD_SET"] = "Estado debug de comida: <<1>>"
EZO_STRINGS_ES["EZO_CMD_DEBUG_GUILDCOLOR"] = "  /ezo debug guildcolor — imprime el color leído para la guild representada"
EZO_STRINGS_ES["EZO_CMD_DEBUG_GUILDIMAGE"] = "  /ezo debug guildimage — imprime el estado de la imagen personalizada de guild"
EZO_STRINGS_ES["EZO_DEBUG_FOOD_NAME"] = "Comida de prueba"
