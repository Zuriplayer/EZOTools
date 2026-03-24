-- Cadenas en español para EZOTools.
-- REGLA: mismas claves que en.lua, mismo orden.
EZO_STRINGS_ES = {

    -- -------------------------------------------------------------------------
    -- Categoría de keybind
    -- -------------------------------------------------------------------------
    SI_BINDING_CATEGORY_EZOTools                = "E|cB040FFZ|rOTools",

    -- -------------------------------------------------------------------------
    -- Nombres de keybinds (aparecen en la pantalla de controles)
    -- -------------------------------------------------------------------------
    SI_BINDING_NAME_EZO_TOGGLE_COMMAND_PANEL    = "Abrir panel de comandos",
    SI_BINDING_NAME_EZO_COMMAND_PANEL_SELECT    = "Panel de comandos: Ejecutar selección",
    SI_BINDING_NAME_EZO_TRAVEL_PRIMARY_HOUSE    = "Viajar a casa principal",
    SI_BINDING_NAME_EZO_TRAVEL_CRAFTING_HALL    = "Visitar sala de artesanía",
    SI_BINDING_NAME_EZO_TRAVEL_SECONDARY_HALL   = "Visitar sala secundaria",
    SI_BINDING_NAME_EZO_LEAVE_GROUP             = "Abandonar grupo",
    SI_BINDING_NAME_EZO_LEAVE_INSTANCE          = "Salir de instancia",
    SI_BINDING_NAME_EZO_LEAVE_GROUP_INSTANCE    = "Salir del grupo y de la instancia",
    SI_BINDING_NAME_EZO_RELOAD_UI               = "Recargar interfaz",
    SI_BINDING_NAME_EZO_TOGGLE_OVERLAY          = "Mostrar/Ocultar overlay",

    -- -------------------------------------------------------------------------
    -- Mensajes generales del addon
    -- -------------------------------------------------------------------------
    EZO_MSG_INIT                = "E|cB040FFZ|rOTools inicializado.",
    EZO_MSG_SLASH               = "Comando /ezo recibido",

    -- -------------------------------------------------------------------------
    -- Panel LAM: sección General
    -- -------------------------------------------------------------------------
    EZO_OPTION_GENERAL                  = "General",
    EZO_OPTION_LANGUAGE                 = "Idioma",
    EZO_OPTION_LANGUAGE_TOOLTIP         = "Cambiar el idioma actualiza todos los textos del addon de inmediato. Los nombres de keybind pueden requerir /reloadui.",

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
    EZO_OPTION_OVERLAY_TEXT             = "Texto del overlay",
    EZO_OPTION_OVERLAY_RESET_POS        = "Reiniciar posición del overlay",

    -- -------------------------------------------------------------------------
    -- Panel LAM: sección Casas de amigos
    -- -------------------------------------------------------------------------
    EZO_OPTION_FRIENDS          = "Casas de amigos",
    EZO_OPTION_FRIENDS_CRAFTING = "Crafting Hall (nombre de cuenta @...)",
    EZO_OPTION_FRIENDS_SECONDARY= "Secondary Hall (nombre de cuenta @...)",

    -- -------------------------------------------------------------------------
    -- Panel LAM: sección Mantenimiento
    -- -------------------------------------------------------------------------
    EZO_OPTION_MAINTENANCE                = "Mantenimiento",
    EZO_OPTION_REPAIR_THRESHOLD           = "Umbral de reparación de equipo (%)",
    EZO_OPTION_REPAIR_THRESHOLD_TOOLTIP   = "La opción 'Reparar equipo' aparece en el menú solo si alguna pieza está por debajo de este porcentaje de durabilidad.",
    EZO_OPTION_RECHARGE_THRESHOLD         = "Umbral de recarga de armas (%)",
    EZO_OPTION_RECHARGE_THRESHOLD_TOOLTIP = "La opción 'Recargar armas' aparece en el menú solo si algún arma está por debajo de este porcentaje de carga de encantamiento.",

    -- -------------------------------------------------------------------------
    -- Entradas del panel de comandos
    -- -------------------------------------------------------------------------
    EZO_MENU_TITLE                = "EZOTools",
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
    EZO_CMD_HELP_GUILDS         = "  /ezo guilds   — lista tus guilds y cuál está representada",
    EZO_CMD_HELP_INFO           = "  /ezo info     — diagnóstico: zona, grupo, mantenimiento, guild",
    EZO_CMD_HELP_HELP           = "  /ezo help",

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
}
