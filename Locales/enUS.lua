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
L.LEVELUP_TRAINER       = "New abilities! Visit your class trainer to learn new abilities or ranks."
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
L.OPT_TRAINER_TT        = "Reminds you every 2 levels (2, 4, 6, ...) to visit your class trainer."
L.OPT_TALENT            = "Talent point reminder"
L.OPT_TALENT_TT         = "Tells you when you have unspent talent points."
L.OPT_LOGIN             = "Remind at login"
L.OPT_LOGIN_TT          = "Also reminds you of unspent talent points right after logging in."
L.OPT_ONSCREEN          = "Show tips on screen"
L.OPT_ONSCREEN_TT       = "Also shows tips in large text in the middle of the screen, not only in chat."

-- Test
L.TEST_HEADER           = "This is what a level-up tip looks like:"

-- Talent-Leitfaden
L.HELP_BUILD            = "/ww build – talent guide: progress and next point"
L.HELP_BUILD_LIST       = "/ww build list – all steps of the build"
L.HELP_BUILD_NOTES      = "/ww build notes – known trade-offs of the build"
L.OPT_GUIDE             = "Talent guide"
L.OPT_GUIDE_TT          = "Recommends which talent to pick next, based on a leveling build."
L.GUIDE_NO_BUILD        = "There is no talent build for your class yet."
L.GUIDE_TREE_CHANGED    = "|cffff5555The talent tree has changed – please check the build.|r"
L.GUIDE_SEE_BUILD       = "Details: /ww build"
L.GUIDE_PROGRESS        = "Progress: %d of %d points as planned."
L.GUIDE_NEXT            = "Next: %s"
L.GUIDE_POINT_LINE      = "point %d (level %d): %s %d/%d"
L.GUIDE_COMPLETE        = "All points of the build are spent. Well done!"
L.GUIDE_DEVIATION       = "|cffffff00Note:|r %s is at %d, the build plans %d. That's fine – it's your choice."
L.GUIDE_MORE            = "More: /ww build liste, /ww build hinweise"
L.GUIDE_LIST_LINE       = "%s Lvl %s: %s %d/%d"
L.GUIDE_NOTES_HEADER    = "Known trade-offs of this build:"
L.CHECK_NODE_MISSING    = "Step %d: talent #%d no longer exists."
L.CHECK_MAXRANK         = "%s: max rank should be %d, game says %d."
L.CHECK_POSITION        = "%s: expected tree %d row %d column %d, game says tree %d row %d column %d."
L.CHECK_GATE            = "Point %d (%s): needs %d points in the tree, only %d at that time."
L.CHECK_ARROW           = "Point %d (%s): requires %s at rank %d first."
L.CHECK_TOO_MANY        = "%s: build plans rank %d, but the maximum is %d."

-- Markierungen im Talentfenster
L.OPT_HIGHLIGHT         = "Highlight in talent window"
L.OPT_HIGHLIGHT_TT      = "Marks the talent that is up next with its target rank – with a gold frame when you have a free point."
L.GUIDE_HIGHLIGHT_HINT  = "It is marked with a gold frame in the talent window."
L.HL_TT_NOW             = "Wegweiser: pick now – %s"
L.HL_TT_DONE            = "Wegweiser: done as planned."
L.HL_TT_NEXT            = "Wegweiser: next in the build – target %d/%d (from level %d)"
L.HL_TT_LATER           = "Wegweiser: later in the build – target %d/%d (from level %d)"
L.HL_TT_DEVIATION       = "Wegweiser: the build plans %d point(s) here, you have %d. No problem – just a note."

-- Quest-Berater
L.HELP_QUESTS           = "/ww quests – rates all quests in your quest log"
L.OPT_QUESTS            = "Quest advisor"
L.OPT_QUESTS_TT         = "Rates your quests: doable, needs a group, too hard, or skip. Also shown in the quest log tooltip."
L.OPT_QACCEPT           = "Rate new quests"
L.OPT_QACCEPT_TT        = "Shows a short rating in chat when you accept a quest."
L.QA_EMPTY              = "Your quest log is empty."
L.QA_HEADER             = "Your %d quests at a glance:"
L.QA_ACCEPTED           = "New quest %s: %s"
L.QA_NOW_DOABLE         = "Now doable: %s"
L.QA_NOW_GREY           = "Now grey (little or no XP left) – you can abandon it: %s"
L.QA_QUESTIE_YES        = "Questie detected: quest givers and objectives are shown on your map and minimap."
L.QA_QUESTIE_NO         = "Tip: the free addon Questie shows quest givers and objectives on the map (optional)."
L.QA_DONE               = "ready to turn in"
L.QA_DONE_TT            = "All objectives done – return to the quest giver for your reward."
L.QA_SKIP               = "skip"
L.QA_SKIP_TT            = "Grey quest: far below your level, gives little or no experience."
L.QA_GROUP              = "group needed"
L.QA_GROUP_TT           = "Elite, dungeon or group quest – hard to do alone. Look for a group."
L.QA_TOO_HARD           = "too hard for now"
L.QA_TOO_HARD_TT        = "Orange/red quest: enemies are clearly above your level. Come back later."
L.QA_GOOD               = "good to do"
L.QA_GOOD_TT            = "Yellow quest: right at your level – good experience at fair difficulty."
L.QA_STILL_WORTH        = "still worth it"
L.QA_STILL_WORTH_TT     = "Green quest: a bit below your level, easy and still gives experience."
L.OPT_QOFFER            = "Hint at the quest giver"
L.OPT_QOFFER_TT         = "Shows a rating below the quest window before you accept a quest."
L.OPT_QICONS            = "Symbols in the quest log"
L.OPT_QICONS_TT         = "Shows a small symbol next to each quest title. Hover over the quest for an explanation."
L.QA_DEBUG_NO_OFFER      = "Open a quest at a quest giver first (the text with the Accept button)."
