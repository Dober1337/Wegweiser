-- ============================================================
-- Locales/enUS.lua
-- Englische Texte. Sie sind gleichzeitig die "Grundsprache":
-- Wenn ein deutscher Text fehlt, wird der englische verwendet.
-- Platzhalter: %d = Zahl, %s = Text.
-- ============================================================

local _, ns = ...
local L = ns.L

-- Allgemein
L.ADDON_LOADED          = "Version %s loaded. Type /ww for help."
L.IN_COMBAT_QUEUED      = "You are in combat – this will run as soon as combat ends."
L.UNKNOWN_COMMAND       = "Unknown command: %s"

-- Hilfe (/ww)
L.HELP_HEADER           = "Commands:"
L.HELP_CONFIG           = "/ww config – open settings"
L.HELP_POINTS           = "/ww points – show your talent points"
L.HELP_TALENTDUMP       = "/ww talentdump – read the talent tree and save it (for the developer)"
L.HELP_TEST             = "/ww test – show a sample level-up message"

-- Level-Up-Modul
L.LEVELUP_CONGRATS      = "Congratulations on reaching level %d!"
L.LEVELUP_TRAINER       = "Tip: visit your class trainer – you may be able to learn new abilities or ranks."
L.LEVELUP_FIRST_TALENT  = "From now on you get talent points! Each point makes your character a bit stronger."
L.TALENT_UNSPENT_ONE    = "You have 1 unspent talent point. Open the talent window (%s) to spend it."
L.TALENT_UNSPENT_MANY   = "You have %d unspent talent points. Open the talent window (%s) to spend them."
L.TALENT_KEY_UNKNOWN    = "talent key"
L.TALENT_API_MISSING    = "The talent interface could not be read (API not available)."

-- /ww points
L.POINTS_STATUS         = "Talent points: %d spent, %d unspent."
L.POINTS_TREE           = "  %s: %d"

-- /ww talentdump
L.DUMP_DONE             = "Talent tree saved: %d trees, %d talents. Type /reload so the file is written."
L.DUMP_FILE_HINT        = "File: WTF\\Account\\<ACCOUNT>\\SavedVariables\\Wegweiser.lua"
L.DUMP_FAILED           = "Talent dump failed: %s"
L.DUMP_NO_CONFIG        = "no active talent configuration found"
L.DUMP_NO_TREE          = "no talent tree found"

-- Einstellungen
L.SETTINGS_TITLE        = "Wegweiser"
L.OPT_LEVELUP           = "Level-up tips"
L.OPT_LEVELUP_TT        = "Shows a short tip in chat when you level up."
L.OPT_TRAINER           = "Trainer reminder"
L.OPT_TRAINER_TT        = "Reminds you to visit your class trainer after a level-up."
L.OPT_TALENT            = "Talent point reminder"
L.OPT_TALENT_TT         = "Tells you when you have unspent talent points."
L.OPT_LOGIN             = "Remind at login"
L.OPT_LOGIN_TT          = "Also reminds you of unspent talent points right after logging in."
L.OPT_ONSCREEN          = "Show tips on screen"
L.OPT_ONSCREEN_TT       = "Also shows tips in large text in the middle of the screen, not only in chat."

-- Test
L.TEST_HEADER           = "This is what a level-up tip looks like:"
