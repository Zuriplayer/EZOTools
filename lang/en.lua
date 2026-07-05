-- Cadenas en inglés para EZOTools.
-- REGLA: cada clave aquí debe existir también en es.lua con el mismo nombre.
-- Para strings con parámetros usar formato ESO: <<1>>, <<2>>, etc. (zo_strformat)
EZO_STRINGS_EN = {

    -- -------------------------------------------------------------------------
    -- Keybind category
    -- -------------------------------------------------------------------------
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
    SI_BINDING_NAME_EZO_TOGGLE_UTILITY_PANEL    = "Open Utility Panel",

    -- -------------------------------------------------------------------------
    -- General addon messages
    -- -------------------------------------------------------------------------
    EZO_MSG_INIT                = "E|cB040FFZ|rOTools initialized.",
    EZO_MSG_HIDE_PET            = "Hiding pet",
    EZO_MSG_HIDE_COMPANION      = "Hiding companion",
    EZO_MSG_HIDE_ASSISTANT      = "Hiding assistant",
    EZO_MSG_USE_MOUNT           = "Selecting mount",
    EZO_MSG_SUMMON_PET          = "Summoning pet",
    EZO_MSG_SUMMON_COMPANION    = "Summoning companion",
    EZO_MSG_SUMMON_ASSISTANT    = "Summoning assistant",
    EZO_MSG_DEBUG_FOOD_CONSUME_ATTEMPT = "Trying to consume <<1>>",
    EZO_MSG_DEBUG_FOOD_CONSUME_FAILED = "Food debug: consumption was not confirmed or the buff did not refresh.",
    EZO_MSG_DEBUG_FOOD_NO_RECORDED = "Food debug: no remembered food or drink is available.",
    EZO_MSG_DEBUG_MODE_DISABLED = "Debug mode is disabled. Enable it in the addon settings to use /ezo debug.",

    -- -------------------------------------------------------------------------
    -- LAM panel: General section
    -- -------------------------------------------------------------------------
    EZO_OPTION_GENERAL                  = "General",
    EZO_OPTION_LANGUAGE                 = "Language",
    EZO_OPTION_LANGUAGE_AUTO            = "Automatic",
    EZO_OPTION_LANGUAGE_TOOLTIP         = "Automatic follows the ESO client language. Forcing a different language can mix addon text with ESO system names.",
    EZO_MSG_LANGUAGE_FORCED_WARNING     = "Forced language: ESO names may use the game language.",

    -- -------------------------------------------------------------------------
    -- LAM panel: Overlay section
    -- -------------------------------------------------------------------------
    EZO_OPTION_OVERLAY                  = "Overlay",
    EZO_OPTION_OVERLAY_ENABLE           = "Enable overlay",
    EZO_OPTION_OVERLAY_LOCK             = "Lock overlay position",
    EZO_OPTION_OVERLAY_SIMULATE_GAMEPAD = "Simulate Gamepad style (overlay only)",
    EZO_OPTION_OVERLAY_HIDE_COMBAT      = "Hide during combat",
    EZO_OPTION_OVERLAY_CONTEXTUAL_TOOLTIPS = "Show contextual icon tooltips",
    EZO_OPTION_OVERLAY_CONTEXTUAL_TOOLTIPS_TOOLTIP = "Shows contextual information when hovering the overlay icons and the addon's side icons.",
    EZO_OPTION_OVERLAY_SCALE            = "Overlay scale",
    EZO_OPTION_OVERLAY_PLAYER_TEXT_COLOR = "Player name color",
    EZO_OPTION_OVERLAY_PLAYER_TEXT_SIZE = "Player name size",
    EZO_OPTION_OVERLAY_TEXT             = "Overlay text",
    EZO_OPTION_OVERLAY_RESET_POS        = "Reset position",
    EZO_OPTION_OVERLAY_RESET_POS_TOOLTIP = "Return the overlay to its default on-screen position.",
    EZO_OPTION_GUILD_OVERLAY            = "Guild Image",
    EZO_OPTION_GUILD_LABEL_COLOR        = "Represented guild name color",
    EZO_OPTION_GUILD_LABEL_COLOR_TOOLTIP = "Applied only when a represented guild is selected and no tabard is equipped. Tabard and no-guild states keep their current colors.",
    EZO_OPTION_GUILD_HIDE_NO_GUILD      = "Hide 'No guild' label",
    EZO_OPTION_GUILD_HIDE_NO_GUILD_TOOLTIP = "If enabled, the overlay hides the 'No guild' text when no guild is represented in the C selector.",

    -- -------------------------------------------------------------------------
    -- LAM panel: Friend Houses section
    -- -------------------------------------------------------------------------
    EZO_OPTION_FRIENDS          = "Guild Houses",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN = "Auto-assign houses from guild",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_TOOLTIP = "If enabled, the addon uses the guild represented in C only when it has a saved or internal profile. If there is no valid guild in C, it uses Own values.",
    EZO_OPTION_FRIENDS_ACTIVE_VALUES = "Active Crafting/Secondary: |cC8A95A<<1>>|r / |cC8A95A<<2>>|r",
    EZO_OPTION_FRIENDS_ACTIVE_EMPTY = "(empty)",
    EZO_OPTION_FRIENDS_MANUAL_ACTIVE_PROFILE = "Manual active profile",
    EZO_OPTION_FRIENDS_MANUAL_ACTIVE_PROFILE_TOOLTIP = "When auto-assignment is disabled, this profile defines the houses the addon uses for travel. It defaults to Own values until you change it.",
    EZO_OPTION_FRIENDS_EDIT_PROFILE_NOTE = "The fields below only edit the selected profile. They do not change active houses until you save and apply the matching profile.",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD = "Profile being edited",
    EZO_OPTION_FRIENDS_AUTO_ASSIGN_GUILD_TOOLTIP = "Choose Own values or one of your guilds to edit its saved houses. This does not change the auto-assigned profile; auto-assignment always uses the guild represented in C.",
    EZO_OPTION_FRIENDS_PROFILE_MANUAL = "Own values",
    EZO_OPTION_FRIENDS_SAVE_SELECTED = "Save edited profile",
    EZO_OPTION_FRIENDS_SAVE_SELECTED_TOOLTIP = "Save the written houses for the selected profile. If that profile matches the current auto-assigned guild, the active houses are updated too.",
    EZO_OPTION_FRIENDS_CRAFTING = "Edit Crafting Hall (@player)",
    EZO_OPTION_FRIENDS_SECONDARY= "Edit Secondary Hall (@player)",

    -- -------------------------------------------------------------------------
    -- LAM panel: Maintenance section
    -- -------------------------------------------------------------------------
    EZO_OPTION_MAINTENANCE                = "Maintenance",
    EZO_OPTION_STOCK_ALERTS               = "Stock Alerts",
    EZO_OPTION_REPAIR_THRESHOLD           = "Repair equipped threshold (%)",
    EZO_OPTION_REPAIR_THRESHOLD_TOOLTIP   = "The 'Repair equipped' option appears in the menu only if any equipped item is below this durability percentage.",
    EZO_OPTION_RECHARGE_THRESHOLD         = "Recharge weapons threshold (%)",
    EZO_OPTION_RECHARGE_THRESHOLD_TOOLTIP = "The 'Recharge weapons' option appears in the menu only if any equipped weapon is below this enchant charge percentage.",
    EZO_OPTION_DEBUG                      = "Debug",
    EZO_OPTION_DEBUG_MODE                 = "Enable debug mode",
    EZO_OPTION_DEBUG_MODE_TOOLTIP         = "Enables the addon's debug features persistently, including /ezo debug and debug-only inspection rows in blocked menus.",

    -- -------------------------------------------------------------------------
    -- Command panel menu entries
    -- -------------------------------------------------------------------------
    EZO_MENU_TITLE                = "EZOTools",
    EZO_UTILITY_MENU_TITLE        = "Quick Utilities",
    EZO_MENU_DIALOG_SUBTITLE      = "<<1>>  ·  v<<2>>",
    EZO_MENU_SETTINGS             = "Quick settings",
    EZO_MENU_ADDON_SETTINGS       = "Full settings (LAM)",
    EZO_MENU_TRAVEL_PRIMARY       = "Go to my house",
    EZO_MENU_TRAVEL_CRAFTING      = "Travel to Crafting House",
    EZO_MENU_TRAVEL_SECONDARY     = "Travel to Secondary House",
    EZO_MENU_JUMP_LEADER          = "Jump to Leader",
    EZO_MENU_JUMP_LEADER_PLAYER   = "Jump to Leader: <<1>>",
    EZO_MENU_JUMP_LEADER_ZONE     = "Jump to Leader: <<1>>",
    EZO_MENU_JUMP_LEADER_WITH_LOCATION = "Jump to Leader: <<1>> - <<2>>",
    EZO_MENU_LEAVE_GROUP          = "Leave group",
    EZO_MENU_LEAVE_INSTANCE       = "Leave instance",
    EZO_MENU_LEAVE_GROUP_INSTANCE = "Leave group & instance",
    EZO_MENU_DUNGEON_DIFFICULTY   = "Instance difficulty",
    EZO_MENU_DUNGEON_DIFFICULTY_TO = "Set instance difficulty: <<1>>",
    EZO_MENU_REPAIR               = "Repair equipped (<= <<1>>%)",
    EZO_MENU_RECHARGE             = "Recharge weapons (<= <<1>>%)",
    EZO_MENU_RELOAD               = "Reload UI",
    EZO_MENU_DEBUG_VIEWER         = "Open technical viewer",
    EZO_MENU_EXIT                 = "Exit",

    -- -------------------------------------------------------------------------
    -- Quick settings submenu (gamepad_settings)
    -- -------------------------------------------------------------------------
    EZO_SETTINGS_RECHARGE_THRESHOLD = "Recharge weapons: <<1>>%",
    EZO_SETTINGS_REPAIR_THRESHOLD   = "Repair equipped: <<1>>%",
    EZO_SETTINGS_BACK               = "Back",
    EZO_SETTINGS_CLOSE              = "Close",

    -- -------------------------------------------------------------------------
    -- Overlay: guild label
    -- -------------------------------------------------------------------------
    EZO_OVERLAY_NO_GUILD        = "No guild",
    EZO_OVERLAY_TABARD          = "Tabard",
    EZO_UTILITY_ENTRY_FOOD      = "Food and drink",
    EZO_UTILITY_ENTRY_MOUNT     = "Mount",
    EZO_UTILITY_ENTRY_PET       = "Pet",
    EZO_UTILITY_ENTRY_COMPANION = "Companion",
    EZO_UTILITY_ENTRY_ASSISTANT = "Assistant",
    EZO_UTILITY_ENTRY_HOUSES    = "Houses",
    EZO_UTILITY_ENTRY_OTHER_HOUSES = "Other players' houses",
    EZO_UTILITY_HOUSES_OPEN_COLLECTIONS = "Open houses collection",
    EZO_UTILITY_HOUSES_HISTORY_EMPTY = "No owned houses are saved yet.|nVisit an owned house different from your primary house to add it here.",
    EZO_UTILITY_HOUSES_VISIT_HINT = "Visit your owned houses to remember the last 10.",
    EZO_UTILITY_OTHER_HOUSES_HISTORY_EMPTY = "No other players' houses are saved yet.|nThey will be remembered as you visit specific houses owned by other players.",
    EZO_UTILITY_OTHER_HOUSES_VISIT_HINT = "Visit other players' houses to remember the last 20.",
    EZO_UTILITY_HOUSES_FALLBACK_NAME = "House",

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
    EZO_MSG_DUNGEON_DIFFICULTY_CANT_CHANGE = "You cannot change instance difficulty from here.",
    EZO_MSG_DUNGEON_DIFFICULTY_CANT_CHANGE_REASON = "You cannot change instance difficulty from here: <<1>>",
    EZO_MSG_DUNGEON_DIFFICULTY_CHANGED = "Instance difficulty set to <<1>>.",

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
    EZO_MSG_UTILITY_PANEL_MISSING = "Utility Panel not available.",
    EZO_MSG_MENU_CALLBACK_FAILED = "Menu debug: failed to run option: <<1>>",
    EZO_MSG_DEBUG_VIEWER_UNAVAILABLE = "Technical viewer is not available.",
    EZO_MSG_DEBUG_LOGGER_UNAVAILABLE = "Technical diagnostics are not available; no report was generated.",
    EZO_MSG_DEBUG_REPORT_SENT = "Diagnostic report generated: <<1>>",
    EZO_MSG_DEBUG_REPORT_LOGGED_VIEWER_MISSING = "Diagnostic report generated: <<1>>. Diagnostic viewer is not available.",
    -- -------------------------------------------------------------------------
    -- Slash command output
    -- -------------------------------------------------------------------------
    EZO_CMD_BANNER              = "E|cB040FFZ|rOTools v<<1>> — @Zuriplayer",
    EZO_CMD_REGISTERED          = "Commands registered: /ezo, /ezotools",
    EZO_CMD_HELP_TITLE          = "Available commands:",
    EZO_CMD_HELP_STATUS         = "  /ezo status   — addon runtime status",
    EZO_CMD_HELP_DEBUG          = "  /ezo debug    — list diagnostic commands",
    EZO_CMD_HELP_HELP           = "  /ezo help",
    EZO_CMD_HELP_DETAIL_STATUS  = "    status shows loaded version, active language, and availability of the main modules.",
    EZO_CMD_HELP_DETAIL_DEBUG   = "    debug groups technical support and development tools; they are not normal gameplay commands.",
    EZO_CMD_HELP_CONTACT        = "    For addon issues, questions, or feedback, you can contact @Zuriplayer.",
    EZO_CMD_HELP_ABOUT          = "  /ezo about    — author and contact info",
    EZO_CMD_ABOUT_AUTHOR        = "Author: @Zuriplayer — in-game mail welcome (EU and NA).",
    EZO_CMD_ABOUT_DISCORD       = "Discord: <<1>>",
    EZO_MENU_ABOUT              = "About EZOTools",
    EZO_CONTACT_GUILD_ACTIVE    = "Guild pack active. Outdated houses or image? Mail @Zuriplayer in game or reach us on Discord (/ezo about).",
    EZO_CONTACT_GUILD_LOCKED    = "Want a custom pack for your guild (guild image and crafting houses)? Mail @Zuriplayer in game or join our Discord (/ezo about).",

    EZO_CMD_DEBUG_TITLE         = "Diagnostic commands",
    EZO_CMD_DEBUG_INFO          = "  /ezo debug info     — diagnostic: zone, group, maintenance, guild",
    EZO_CMD_DEBUG_GUILDS        = "  /ezo debug guilds   — list your guilds and which is represented",
    EZO_CMD_DEBUG_TEX           = "  /ezo debug tex      — overlay icon state",
    EZO_CMD_DEBUG_TEXLOAD       = "  /ezo debug texload  — texture loading test",
    EZO_CMD_DEBUG_DOTS          = "  /ezo debug dots     — pet/ally icon state",
    EZO_CMD_DEBUG_LAYOUT        = "  /ezo debug layout   — toggle side icon preview",
    EZO_CMD_DEBUG_HOUSE         = "  /ezo debug house    — current housing diagnostic",

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
    EZO_CMD_VERSION_API         = "  ESO API: <<1>>",
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

EZO_STRINGS_EN["EZO_OPTION_LOW_STOCK_ALERTS_NOTE"] = "Low stock alerts drive the side widgets. Soul gems are counted by usable filled gems. Repair kits are currently counted by item units, without distinguishing single-piece kits from full-repair kits yet."
EZO_STRINGS_EN["EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE"] = "Use custom image for represented guild"
EZO_STRINGS_EN["EZO_OPTION_GUILD_CUSTOM_IMAGE_ENABLE_TOOLTIP"] = "If enabled and the represented guild has an image registered in the addon, the central logo is replaced by that image. If no valid image is available, the normal EZOTools logo stays in place."
EZO_STRINGS_EN["EZO_OPTION_REPAIR_KIT_ALERT_ENABLE"] = "Show low repair kit alert"
EZO_STRINGS_EN["EZO_OPTION_REPAIR_KIT_ALERT_ENABLE_TOOLTIP"] = "Show or hide the side alert widget when repair kits are low."
EZO_STRINGS_EN["EZO_OPTION_REPAIR_KIT_ALERT_THRESHOLD"] = "Repair kit alert threshold"
EZO_STRINGS_EN["EZO_OPTION_REPAIR_KIT_ALERT_THRESHOLD_TOOLTIP"] = "Show the repair kit alert when the detected repair kit count is at or below this value."
EZO_STRINGS_EN["EZO_OPTION_SOUL_GEM_ALERT_ENABLE"] = "Show low soul gem alert"
EZO_STRINGS_EN["EZO_OPTION_SOUL_GEM_ALERT_ENABLE_TOOLTIP"] = "Show or hide the side alert widget when filled soul gems are low."
EZO_STRINGS_EN["EZO_OPTION_SOUL_GEM_ALERT_THRESHOLD"] = "Soul gem alert threshold"
EZO_STRINGS_EN["EZO_OPTION_SOUL_GEM_ALERT_THRESHOLD_TOOLTIP"] = "Show the soul gem alert when the detected filled soul gem count is at or below this value."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_REPAIR_EQUIPPED_TOOLTIP"] = "Armor repair needed (threshold <<1>>%). Left click repairs equipped gear. Right click opens settings."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_RECHARGE_WEAPONS_TOOLTIP"] = "Weapon recharge needed (threshold <<1>>%). Left click recharges weapons. Right click opens settings."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_NONE_TOOLTIP"] = "No food or drink buff is active.|nUse a food or drink item to save it here.|nRight click: recent food and drinks."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_ACTIVE_TOOLTIP"] = "Active food or drink: <<1>>. Time remaining: <<2>>.|nRight click: recent food and drinks."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_ACTIVE_NO_TIME_TOOLTIP"] = "Active food or drink: <<1>>.|nRight click: recent food and drinks."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_ALERT_REUSE_TOOLTIP"] = "<<1>>|nLeft click to consume it again.|nRight click: recent food and drinks."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_ALERT_REUSE_LEGENDARY_TOOLTIP"] = "<<1>>|nLeft click to consume it again.|nRight click: recent food and drinks."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_RECALL_TOOLTIP"] = "No food or drink buff is active.|nLeft click to consume <<1>> again.|nRight click: recent food and drinks."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_RECALL_LEGENDARY_TOOLTIP"] = "No food or drink buff is active.|nLeft click to consume <<1>> again.|nRight click: recent food and drinks."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_ACTIVE_REUSE_TOOLTIP"] = "Active food or drink: <<1>>. Time remaining: <<2>>.|nLeft click to consume it again.|nRight click: recent food and drinks."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_ACTIVE_REUSE_LEGENDARY_TOOLTIP"] = "Active food or drink: <<1>>. Time remaining: <<2>>.|nLeft click to consume it again.|nRight click: recent food and drinks."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_CONFIRM_TITLE"] = "Confirm Consumption"
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_CONFIRM_TEXT"] = "You are about to consume <<1>>."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_CONFIRM_TEXT_WITH_TIME"] = "You are about to consume <<1>>.|n|nTime remaining on the current effect: |cC8A95A<<2>>|r."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_CONFIRM_TEXT_WITH_EFFECT"] = "You are about to consume <<1>>.|n|nEffect: <<2>>"
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_CONFIRM_TEXT_WITH_EFFECT_AND_TIME"] = "You are about to consume <<1>>.|n|nEffect: <<2>>|n|nTime remaining on the current effect: |cC8A95A<<3>>|r."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_HISTORY_EMPTY"] = "No food or drink is saved yet.|nOpen the game's inventory and use one to add it here."
EZO_STRINGS_EN["EZO_TIME_REMAINING_HM"] = "<<1>>h <<2>>m"
EZO_STRINGS_EN["EZO_TIME_REMAINING_MS"] = "<<1>>m <<2>>s"
EZO_STRINGS_EN["EZO_TIME_REMAINING_S"] = "<<1>>s"
EZO_STRINGS_EN["EZO_SIDE_WIDGET_FOOD_PREVIEW_TOOLTIP"] = "Preview: food or drink status."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_REPAIR_EQUIPPED_PREVIEW_TOOLTIP"] = "Preview: armor repair state."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_REPAIR_KITS_PREVIEW_TOOLTIP"] = "Preview: low repair kit stock."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_RECHARGE_WEAPONS_PREVIEW_TOOLTIP"] = "Preview: weapon recharge state."
EZO_STRINGS_EN["EZO_SIDE_WIDGET_SOUL_GEMS_PREVIEW_TOOLTIP"] = "Preview: low soul gem stock."
EZO_STRINGS_EN["EZO_DOT_MOUNT_ACTIVE_TOOLTIP"] = "<<1>>|nLeft click to select it.|nRight click: recent mounts."
EZO_STRINGS_EN["EZO_DOT_MOUNT_INACTIVE_TOOLTIP"] = "<<1>>|nLeft click to select it.|nRight click: recent mounts."
EZO_STRINGS_EN["EZO_DOT_MOUNT_EMPTY_TOOLTIP"] = "No mounts are saved yet.|nSelect a mount to add it here.|nRight click: recent mounts."
EZO_STRINGS_EN["EZO_DOT_PET_ACTIVE_TOOLTIP"] = "<<1>>|nLeft click to hide it.|nRight click: recent pets."
EZO_STRINGS_EN["EZO_DOT_PET_INACTIVE_TOOLTIP"] = "<<1>>|nLeft click to summon it.|nRight click: recent pets."
EZO_STRINGS_EN["EZO_DOT_PET_EMPTY_TOOLTIP"] = "No pets are saved yet.|nSummon a pet to add it here.|nRight click: recent pets."
EZO_STRINGS_EN["EZO_DOT_COMPANION_ACTIVE_TOOLTIP"] = "<<1>>|nLeft click to hide it.|nRight click: recent companions."
EZO_STRINGS_EN["EZO_DOT_COMPANION_INACTIVE_TOOLTIP"] = "<<1>>|nLeft click to summon it.|nRight click: recent companions."
EZO_STRINGS_EN["EZO_DOT_COMPANION_EMPTY_TOOLTIP"] = "No companions are saved yet.|nSummon a companion to add it here.|nRight click: recent companions."
EZO_STRINGS_EN["EZO_DOT_ASSISTANT_ACTIVE_TOOLTIP"] = "<<1>>|nLeft click to hide it.|nRight click: recent assistants."
EZO_STRINGS_EN["EZO_DOT_ASSISTANT_INACTIVE_TOOLTIP"] = "<<1>>|nLeft click to summon it.|nRight click: recent assistants."
EZO_STRINGS_EN["EZO_DOT_ASSISTANT_EMPTY_TOOLTIP"] = "No assistants are saved yet.|nSummon an assistant to add it here.|nRight click: recent assistants."
EZO_STRINGS_EN["EZO_DOT_MOUNT_FALLBACK_NAME"] = "Mount"
EZO_STRINGS_EN["EZO_DOT_PET_FALLBACK_NAME"] = "Pet"
EZO_STRINGS_EN["EZO_DOT_COMPANION_FALLBACK_NAME"] = "Companion"
EZO_STRINGS_EN["EZO_DOT_ASSISTANT_FALLBACK_NAME"] = "Assistant"
EZO_STRINGS_EN["EZO_DOT_MOUNT_HISTORY_EMPTY"] = "No mounts are saved yet.|nSelect a mount to add it here."
EZO_STRINGS_EN["EZO_DOT_PET_HISTORY_EMPTY"] = "No pets are saved yet.|nSummon a pet to add it here."
EZO_STRINGS_EN["EZO_DOT_COMPANION_HISTORY_EMPTY"] = "No companions are saved yet.|nSummon a companion to add it here."
EZO_STRINGS_EN["EZO_DOT_ASSISTANT_HISTORY_EMPTY"] = "No assistants are saved yet.|nSummon an assistant to add it here."
EZO_STRINGS_EN["EZO_UTILITY_EMPTY_OPEN_MOUNT_COLLECTIONS"] = "Open mount collections"
EZO_STRINGS_EN["EZO_UTILITY_EMPTY_OPEN_PET_COLLECTIONS"] = "Open pet collections"
EZO_STRINGS_EN["EZO_UTILITY_EMPTY_OPEN_COMPANION_COLLECTIONS"] = "Open companion screen"
EZO_STRINGS_EN["EZO_UTILITY_EMPTY_OPEN_ASSISTANT_COLLECTIONS"] = "Open assistant collections"
EZO_STRINGS_EN["EZO_CMD_DEBUG_FOOD"] = "/ezo debug food green|yellow|red|auto - force the food icon state"
EZO_STRINGS_EN["EZO_CMD_DEBUG_FOOD_USAGE"] = "Usage: /ezo debug food green|yellow|red|auto"
EZO_STRINGS_EN["EZO_CMD_DEBUG_FOOD_SET"] = "Food debug state: <<1>>"
EZO_STRINGS_EN["EZO_DEBUG_FOOD_NAME"] = "Debug food"
