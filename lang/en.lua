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
    SI_BINDING_NAME_EZO_TRAVEL_PRIMARY_HOUSE    = "Travel to Primary House",
    SI_BINDING_NAME_EZO_TRAVEL_CRAFTING_HALL    = "Visit Crafting Hall",
    SI_BINDING_NAME_EZO_TRAVEL_SECONDARY_HALL   = "Visit Secondary Hall",
    SI_BINDING_NAME_EZO_LEAVE_GROUP             = "Leave Group",
    SI_BINDING_NAME_EZO_LEAVE_INSTANCE          = "Leave Instance",
    SI_BINDING_NAME_EZO_LEAVE_GROUP_INSTANCE    = "Leave Group and Instance",
    SI_BINDING_NAME_EZO_RELOAD_UI               = "Reload UI",

    -- -------------------------------------------------------------------------
    -- General addon messages
    -- -------------------------------------------------------------------------
    EZO_MSG_INIT                = "E|cB040FFZ|rOTools initialized.",
    EZO_MSG_SLASH               = "/ezo command received",
    EZO_MSG_HIDE_PET            = "Hiding pet",
    EZO_MSG_HIDE_COMPANION      = "Hiding companion",
    EZO_MSG_HIDE_ASSISTANT      = "Hiding assistant",
    EZO_MSG_SUMMON_PET          = "Summoning pet",
    EZO_MSG_SUMMON_COMPANION    = "Summoning companion",
    EZO_MSG_SUMMON_ASSISTANT    = "Summoning assistant",

    -- -------------------------------------------------------------------------
    -- LAM panel: General section
    -- -------------------------------------------------------------------------
    EZO_OPTION_GENERAL                  = "General",
    EZO_OPTION_LANGUAGE                 = "Language",
    EZO_OPTION_LANGUAGE_TOOLTIP         = "Changes addon texts immediately. Keybind names in the controls screen may require /reloadui.",

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
    EZO_OPTION_OVERLAY_PLAYER_TEXT_COLOR = "Player name color",
    EZO_OPTION_OVERLAY_PLAYER_TEXT_SIZE = "Player name size",
    EZO_OPTION_OVERLAY_TEXT             = "Overlay text",
    EZO_OPTION_OVERLAY_RESET_POS        = "Reset overlay position",
    EZO_OPTION_GUILD_OVERLAY            = "Guild Image",
    EZO_OPTION_GUILD_LABEL_COLOR        = "Represented guild name color",
    EZO_OPTION_GUILD_LABEL_COLOR_TOOLTIP = "Applied only when a represented guild is selected and no tabard is equipped. Tabard and no-guild states keep their current colors.",

    -- -------------------------------------------------------------------------
    -- LAM panel: Friend Houses section
    -- -------------------------------------------------------------------------
    EZO_OPTION_FRIENDS          = "Friend Houses",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN = "Auto-assign houses from selected guild",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_TOOLTIP = "If enabled, the addon automatically fills the crafting and secondary house fields using the guild chosen in the selector, as long as you belong to a guild supported by the addon.",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD = "Guild for auto-assignment",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD_TOOLTIP = "Choose one of your guilds supported by the addon. Auto-assignment will use your saved configuration for that guild first and fall back to the addon's internal assignment if no saved configuration exists.",
    EZO_OPTION_FRIENDS_SAVE_SELECTED = "Save houses for selected guild",
    EZO_OPTION_FRIENDS_SAVE_SELECTED_TOOLTIP = "Save the current Crafting Hall and Secondary Hall values for the selected guild. Auto-assignment will use this saved configuration before the internal one.",
    EZO_OPTION_FRIENDS_CRAFTING = "Crafting Hall (account name @...)",
    EZO_OPTION_FRIENDS_SECONDARY= "Secondary Hall (account name @...)",

    -- -------------------------------------------------------------------------
    -- LAM panel: Maintenance section
    -- -------------------------------------------------------------------------
    EZO_OPTION_MAINTENANCE                = "Maintenance",
    EZO_OPTION_STOCK_ALERTS               = "Stock Alerts",
    EZO_OPTION_REPAIR_THRESHOLD           = "Repair equipped threshold (%)",
    EZO_OPTION_REPAIR_THRESHOLD_TOOLTIP   = "The 'Repair equipped' option appears in the menu only if any equipped item is below this durability percentage.",
    EZO_OPTION_RECHARGE_THRESHOLD         = "Recharge weapons threshold (%)",
    EZO_OPTION_RECHARGE_THRESHOLD_TOOLTIP = "The 'Recharge weapons' option appears in the menu only if any equipped weapon is below this enchant charge percentage.",

    -- -------------------------------------------------------------------------
    -- Command panel menu entries
    -- -------------------------------------------------------------------------
    EZO_MENU_TITLE                = "EZOTools",
    EZO_MENU_DIALOG_SUBTITLE      = "<<1>>  ·  v<<2>>",
    EZO_MENU_SETTINGS             = "Quick settings",
    EZO_MENU_ADDON_SETTINGS       = "Full settings (LAM)",
    EZO_MENU_TRAVEL_PRIMARY       = "Go to my house",
    EZO_MENU_TRAVEL_CRAFTING      = "Travel to Crafting House",
    EZO_MENU_TRAVEL_SECONDARY     = "Travel to Secondary House",
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
    EZO_CMD_HELP_VERSION        = "  /ezo version  — loaded addon version and runtime state",
    EZO_CMD_HELP_DEBUG          = "  /ezo debug    — list diagnostic commands",
    EZO_CMD_HELP_HELP           = "  /ezo help",

    EZO_CMD_DEBUG_TITLE         = "Diagnostic commands:",
    EZO_CMD_DEBUG_INFO          = "  /ezo debug info     — diagnostic: zone, group, maintenance, guild",
    EZO_CMD_DEBUG_GUILDS        = "  /ezo debug guilds   — list your guilds and which is represented",
    EZO_CMD_DEBUG_TEX           = "  /ezo debug tex      — overlay icon state",
    EZO_CMD_DEBUG_TEXLOAD       = "  /ezo debug texload  — texture loading test",
    EZO_CMD_DEBUG_DOTS          = "  /ezo debug dots     — pet/ally icon state",
    EZO_CMD_DEBUG_LAYOUT        = "  /ezo debug layout   — toggle side icon preview",

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
    EZO_CMD_LAYOUT_ON           = "Layout preview: ON",
    EZO_CMD_LAYOUT_OFF          = "Layout preview: OFF",
    EZO_CMD_LAYOUT_NA           = "Layout preview is not available.",
    EZO_SIDE_WIDGET_LEFT        = "Left",
    EZO_SIDE_WIDGET_RIGHT       = "Right",
    EZO_SIDE_WIDGET_PREVIEW_TOOLTIP = "Icon preview: <<1>> #<<2>>",
    EZO_SIDE_WIDGET_SOUL_GEMS_TOOLTIP = "Filled Soul Gems low: <<1>> left (threshold <<2>>). Click to open settings.",
    EZO_SIDE_WIDGET_REPAIR_KITS_TOOLTIP = "Repair Kits low: <<1>> left (threshold <<2>>). Click to open settings.",
}

EZO_STRINGS_EN["EZO_OVERLAY_TABARD"] = "Tabard"
EZO_STRINGS_EN["EZO_OPTION_LOW_STOCK_ALERTS_NOTE"] = "Low stock alerts drive the side widgets. Soul gems are counted by usable filled gems. Repair kits are currently counted by item units, without distinguishing single-piece kits from full-repair kits yet."
EZO_STRINGS_EN["EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE"] = "Use custom image for represented guild"
EZO_STRINGS_EN["EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE_TOOLTIP"] = "If enabled and the represented guild has an image registered in the addon, the central logo is replaced by that image. If anything is missing or unclear, the normal EZOTools logo stays in place."
EZO_STRINGS_EN["EZO_OPTION_REPAIR_KIT_ALERT_ENABLE"] = "Show low repair kit alert"
EZO_STRINGS_EN["EZO_OPTION_REPAIR_KIT_ALERT_ENABLE_TOOLTIP"] = "Show or hide the side alert widget when repair kits are low."
EZO_STRINGS_EN["EZO_OPTION_REPAIR_KIT_ALERT_THRESHOLD"] = "Repair kit alert threshold"
EZO_STRINGS_EN["EZO_OPTION_REPAIR_KIT_ALERT_THRESHOLD_TOOLTIP"] = "Show the repair kit alert when the detected repair kit count is at or below this value."
EZO_STRINGS_EN["EZO_OPTION_SOUL_GEM_ALERT_ENABLE"] = "Show low soul gem alert"
EZO_STRINGS_EN["EZO_OPTION_SOUL_GEM_ALERT_ENABLE_TOOLTIP"] = "Show or hide the side alert widget when filled soul gems are low."
EZO_STRINGS_EN["EZO_OPTION_SOUL_GEM_ALERT_THRESHOLD"] = "Soul gem alert threshold"
EZO_STRINGS_EN["EZO_OPTION_SOUL_GEM_ALERT_THRESHOLD_TOOLTIP"] = "Show the soul gem alert when the detected filled soul gem count is at or below this value."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_REPAIR_EQUIPPED_TOOLTIP"] = "Armor repair needed (threshold <<1>>%). Left click repairs equipped gear. Right click opens settings."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_RECHARGE_WEAPONS_TOOLTIP"] = "Weapon recharge needed (threshold <<1>>%). Left click opens the overlay menu. Right click opens settings."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_NONE_TOOLTIP"] = "No food or drink buff is active."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_ACTIVE_TOOLTIP"] = "Active food or drink: <<1>>. Time remaining: <<2>>."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_ACTIVE_NO_TIME_TOOLTIP"] = "Active food or drink: <<1>>."
EZO_STRINGS_EN["EZO_TIME_REMAINING_HM"] = "<<1>>h <<2>>m"
EZO_STRINGS_EN["EZO_TIME_REMAINING_MS"] = "<<1>>m <<2>>s"
EZO_STRINGS_EN["EZO_TIME_REMAINING_S"] = "<<1>>s"
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_PREVIEW_TOOLTIP"] = "Preview: food or drink status."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_REPAIR_EQUIPPED_PREVIEW_TOOLTIP"] = "Preview: armor repair state."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_REPAIR_KITS_PREVIEW_TOOLTIP"] = "Preview: low repair kit stock."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_RECHARGE_WEAPONS_PREVIEW_TOOLTIP"] = "Preview: weapon recharge state."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_SOUL_GEMS_PREVIEW_TOOLTIP"] = "Preview: low soul gem stock."
EZO_STRINGS_EN["EZO_DOT_PET_ACTIVE_TOOLTIP"] = "<<1>>|nLeft click to hide it. Summon another pet to replace it in memory."
EZO_STRINGS_EN["EZO_DOT_PET_INACTIVE_TOOLTIP"] = "<<1>>|nLeft click to summon it. Summon another pet to replace it in memory."
EZO_STRINGS_EN["EZO_DOT_COMPANION_ACTIVE_TOOLTIP"] = "<<1>>|nLeft click to hide it. Summon another companion to replace it in memory."
EZO_STRINGS_EN["EZO_DOT_COMPANION_INACTIVE_TOOLTIP"] = "<<1>>|nLeft click to summon it. Summon another companion to replace it in memory."
EZO_STRINGS_EN["EZO_DOT_ASSISTANT_ACTIVE_TOOLTIP"] = "<<1>>|nLeft click to hide it. Summon another assistant to replace it in memory."
EZO_STRINGS_EN["EZO_DOT_ASSISTANT_INACTIVE_TOOLTIP"] = "<<1>>|nLeft click to summon it. Summon another assistant to replace it in memory."
EZO_STRINGS_EN["EZO_DOT_PET_FALLBACK_NAME"] = "Pet"
EZO_STRINGS_EN["EZO_DOT_COMPANION_FALLBACK_NAME"] = "Companion"
EZO_STRINGS_EN["EZO_DOT_ASSISTANT_FALLBACK_NAME"] = "Assistant"
EZO_STRINGS_EN["EZO_CMD_DEBUG_FOOD"] = "/ezo debug food green|yellow|red|auto - force the food icon state"
EZO_STRINGS_EN["EZO_CMD_DEBUG_FOOD_USAGE"] = "Usage: /ezo debug food green|yellow|red|auto"
EZO_STRINGS_EN["EZO_CMD_DEBUG_FOOD_SET"] = "Food debug state: <<1>>"
EZO_STRINGS_EN["EZO_DEBUG_FOOD_NAME"] = "Debug food"
