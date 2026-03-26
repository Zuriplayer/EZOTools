-- Cadenas en inglés para EZOTools.
-- REGLA: cada clave aquí debe existir también en es.lua con el mismo nombre.
-- Para strings con parámetros usar formato ESO: <<1>>, <<2>>, etc. (zo_strformat)
EZO_STRINGS_EN = {

    -- -------------------------------------------------------------------------
    -- Keybind category
    -- -------------------------------------------------------------------------
    SI_BINDING_CATEGORY_EZOTools                = "E|cB040FFZ|rOTools",
    SI_BINDING_CATEGORY_EZOTOOLS                = "E|cB040FFZ|rOTools",

    -- -------------------------------------------------------------------------
    -- Keybind names (shown in Controls screen)
    -- -------------------------------------------------------------------------
    SI_BINDING_NAME_EZO_TOGGLE_COMMAND_PANEL    = "Open Command Panel",
    SI_BINDING_NAME_EZO_COMMAND_PANEL_SELECT    = "Command Panel: Execute Selected",
    SI_BINDING_NAME_EZO_TRAVEL_PRIMARY_HOUSE    = "Travel to Primary House",
    SI_BINDING_NAME_EZO_TRAVEL_CRAFTING_HALL    = "Visit Crafting Hall",
    SI_BINDING_NAME_EZO_TRAVEL_SECONDARY_HALL   = "Visit Secondary Hall",
    SI_BINDING_NAME_EZO_LEAVE_GROUP             = "Leave Group",
    SI_BINDING_NAME_EZO_LEAVE_INSTANCE          = "Leave Instance",
    SI_BINDING_NAME_EZO_LEAVE_GROUP_INSTANCE    = "Leave Group and Instance",
    SI_BINDING_NAME_EZO_RELOAD_UI               = "Reload UI",
    SI_BINDING_NAME_EZO_TOGGLE_OVERLAY          = "Show/Hide Overlay",

    -- -------------------------------------------------------------------------
    -- General addon messages
    -- -------------------------------------------------------------------------
    EZO_MSG_INIT                = "E|cB040FFZ|rOTools initialized.",
    EZO_MSG_SLASH               = "/ezo command received",

    -- -------------------------------------------------------------------------
    -- LAM panel: General section
    -- -------------------------------------------------------------------------
    EZO_OPTION_GENERAL                  = "General",
    EZO_OPTION_LANGUAGE                 = "Language",
    EZO_OPTION_LANGUAGE_TOOLTIP         = "Changing the language updates all addon texts immediately. Keybind names may require /reloadui.",

    -- -------------------------------------------------------------------------
    -- LAM panel: Overlay section
    -- -------------------------------------------------------------------------
    EZO_OPTION_OVERLAY                  = "Overlay",
    EZO_OPTION_OVERLAY_ENABLE           = "Enable overlay",
    EZO_OPTION_OVERLAY_LOCK             = "Lock overlay position",
    EZO_OPTION_OVERLAY_SIMULATE_GAMEPAD = "Simulate Gamepad style (overlay only)",
    EZO_OPTION_OVERLAY_HIDE_COMBAT      = "Hide during combat",
    EZO_OPTION_OVERLAY_HIDE_MENUS       = "Hide in menus",
    EZO_OPTION_OVERLAY_ALPHA            = "Overlay opacity",
    EZO_OPTION_OVERLAY_SCALE            = "Overlay scale",
    EZO_OPTION_OVERLAY_TEXT             = "Overlay text",
    EZO_OPTION_OVERLAY_RESET_POS        = "Reset overlay position",

    -- -------------------------------------------------------------------------
    -- LAM panel: Friend Houses section
    -- -------------------------------------------------------------------------
    EZO_OPTION_FRIENDS          = "Friend Houses",
    EZO_OPTION_FRIENDS_CRAFTING = "Crafting Hall (account name @...)",
    EZO_OPTION_FRIENDS_SECONDARY= "Secondary Hall (account name @...)",

    -- -------------------------------------------------------------------------
    -- LAM panel: Maintenance section
    -- -------------------------------------------------------------------------
    EZO_OPTION_MAINTENANCE                = "Maintenance",
    EZO_OPTION_REPAIR_THRESHOLD           = "Repair equipped threshold (%)",
    EZO_OPTION_REPAIR_THRESHOLD_TOOLTIP   = "The 'Repair equipped' option appears in the menu only if any equipped item is below this durability percentage.",
    EZO_OPTION_RECHARGE_THRESHOLD         = "Recharge weapons threshold (%)",
    EZO_OPTION_RECHARGE_THRESHOLD_TOOLTIP = "The 'Recharge weapons' option appears in the menu only if any equipped weapon is below this enchant charge percentage.",

    -- -------------------------------------------------------------------------
    -- Command panel menu entries
    -- -------------------------------------------------------------------------
    EZO_MENU_TITLE                = "EZOTools",
    EZO_MENU_SETTINGS             = "Quick settings",
    EZO_MENU_ADDON_SETTINGS       = "Full settings (LAM)",
    EZO_MENU_TRAVEL_PRIMARY       = "Go to my house",
    EZO_MENU_TRAVEL_CRAFTING      = "Go to crafting house",
    EZO_MENU_TRAVEL_SECONDARY     = "Go to secondary house",
    EZO_MENU_JUMP_LEADER          = "Jump to Leader",
    EZO_MENU_LEAVE_GROUP          = "Leave group",
    EZO_MENU_LEAVE_INSTANCE       = "Leave instance",
    EZO_MENU_LEAVE_GROUP_INSTANCE = "Leave group & instance",
    EZO_MENU_REPAIR               = "Repair equipped (<= <<1>>%)",
    EZO_MENU_RECHARGE             = "Recharge weapons (<= <<1>>%)",
    EZO_MENU_RELOAD               = "Reload UI",
    EZO_MENU_EXIT                 = "Exit",

    -- -------------------------------------------------------------------------
    -- Quick settings submenu (gamepad_settings)
    -- -------------------------------------------------------------------------
    EZO_SETTINGS_TITLE              = "Settings",
    EZO_SETTINGS_RECHARGE_THRESHOLD = "Recharge weapons: <<1>>%",
    EZO_SETTINGS_REPAIR_THRESHOLD   = "Repair equipped: <<1>>%",
    EZO_SETTINGS_BACK               = "Back",
    EZO_SETTINGS_CLOSE              = "Close",

    -- -------------------------------------------------------------------------
    -- Overlay: guild label
    -- -------------------------------------------------------------------------
    EZO_OVERLAY_NO_GUILD        = "No guild",
    EZO_OVERLAY_TABARD          = "Tabard",

    -- -------------------------------------------------------------------------
    -- Chat messages: travel
    -- -------------------------------------------------------------------------
    EZO_MSG_NO_PRIMARY_HOUSE    = "No primary house configured.",
    EZO_MSG_NO_CRAFTING_HALL    = "Set a Crafting Hall in settings.",
    EZO_MSG_NO_SECONDARY_HALL   = "Set a Secondary Hall in settings.",

    -- -------------------------------------------------------------------------
    -- Chat messages: group
    -- -------------------------------------------------------------------------
    EZO_MSG_NOT_IN_GROUP        = "You are not in a group.",
    EZO_MSG_CANT_JUMP_LEADER    = "Cannot jump to group leader from here.",

    -- -------------------------------------------------------------------------
    -- Chat messages: maintenance
    -- -------------------------------------------------------------------------
    EZO_MSG_CANT_REPAIR_COMBAT  = "Cannot repair while in combat.",
    EZO_MSG_NO_REPAIR_KITS      = "No repair kits available.",
    EZO_MSG_REPAIR_DONE         = "Repair executed.",
    EZO_MSG_CANT_RECHARGE_COMBAT= "Cannot recharge while in combat.",
    EZO_MSG_NO_SOUL_GEMS        = "No filled Soul Gems available.",
    EZO_MSG_RECHARGE_DONE       = "Recharge executed.",

    -- -------------------------------------------------------------------------
    -- Chat messages: errors / system
    -- -------------------------------------------------------------------------
    EZO_MSG_ACTION_FAILED       = "Action failed: <<1>>",
    EZO_MSG_CANT_OPEN_COMBAT    = "Cannot open settings while in combat.",
    EZO_MSG_CMD_PANEL_MISSING   = "Command Panel not available.",
    EZO_MSG_INPUT_MODE_SET      = "Input mode: <<1>>",
    EZO_MSG_INPUT_MODE_NA       = "Input mode setting not available.",

    -- -------------------------------------------------------------------------
    -- Slash command output
    -- -------------------------------------------------------------------------
    EZO_CMD_BANNER              = "E|cB040FFZ|rOTools v<<1>> — @Zuriplayer",
    EZO_CMD_REGISTERED          = "Commands registered: /ezo, /ezotools",
    EZO_CMD_HELP_TITLE          = "Available commands:",
    EZO_CMD_HELP_GUILDS         = "  /ezo guilds   — list your guilds and which is represented",
    EZO_CMD_HELP_INFO           = "  /ezo info     — diagnostic: zone, group, maintenance, guild",
    EZO_CMD_HELP_VERSION        = "  /ezo version  — loaded addon version and runtime state",
    EZO_CMD_HELP_HELP           = "  /ezo help",

    EZO_CMD_GUILDS_NONE         = "You do not belong to any guild.",
    EZO_CMD_GUILDS_HEADER       = "Guilds (<<1>>):",
    EZO_CMD_GUILDS_ROW          = "  [<<1>>] <<2>> (<<3>> mbr) id=<<4>><<5>>",
    EZO_CMD_GUILDS_REPRESENTED  = " < REPRESENTED",
    EZO_CMD_GUILDS_NONE_REP     = "No guild currently represented.",

    EZO_CMD_INFO_HEADER         = "=== Diagnostic ===",
    EZO_CMD_INFO_FOOTER         = "==================",
    EZO_CMD_INFO_ZONE           = "  Zone: <<1>>",
    EZO_CMD_INFO_GROUP          = "  Group: <<1>> members",
    EZO_CMD_INFO_LEADER         = "  Leader: <<1>>",
    EZO_CMD_INFO_NO_GROUP       = "  Group: none",
    EZO_CMD_INFO_REPAIR         = "  Repair (threshold <<1>>%): <<2>>",
    EZO_CMD_INFO_RECHARGE       = "  Recharge (threshold <<1>>%): <<2>>",
    EZO_CMD_INFO_NEEDED         = "NEEDED",
    EZO_CMD_INFO_OK             = "OK",
    EZO_CMD_INFO_GUILD          = "  Represented guild: <<1>> (id=<<2>>)",
    EZO_CMD_INFO_NO_GUILD       = "  Represented guild: none",

    EZO_CMD_VERSION_HEADER      = "=== EZOTools v<<1>> ===",
    EZO_CMD_VERSION_LANGUAGE    = "  Language: <<1>>",
    EZO_CMD_VERSION_LAM         = "  LibAddonMenu: <<1>>",
    EZO_CMD_VERSION_OVERLAY     = "  Overlay module: <<1>>",
    EZO_CMD_VERSION_GAMEPAD     = "  Gamepad dialog: <<1>>",
}

-- NOTE: appended by patch -- tabard indicator
-- (add inside EZO_STRINGS_EN table manually if regenerating)
EZO_STRINGS_EN["EZO_OVERLAY_TABARD"] = "Tabard"
-- Food buff indicator (added v3.5.0)
-- No new strings needed: food dot is visual only, no LAM option yet
