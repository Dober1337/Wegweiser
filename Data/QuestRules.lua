-- ============================================================
-- Data/QuestRules.lua
-- Bewertungsregeln für den Quest-Berater (Modul 3).
--
-- KEINE Quest-Datenbank: Bewertet wird nur, was das Spiel zu jeder Quest
-- im Questlog selbst liefert. Quelle für alle API-Werte: Blizzard-UI-
-- Quellcode, Forever-Build 1.60.1.70888 (github.com/Gethe/wow-ui-source,
-- Branch "forever"). verified = false, bis im Spiel bestätigt.
-- ============================================================

local _, ns = ...

ns.QuestRules = {
    -- Blizzards Schwierigkeit relativ zum Spieler:
    -- C_PlayerInfo.GetContentDifficultyQuestForPlayer(questID) -> Enum.RelativeContentDifficulty
    -- Das ist dieselbe Funktion, mit der Blizzard die Questtitel einfärbt.
    difficulty = {
        [0] = "SKIP",         -- Trivial    = grau   -> überspringen (keine/kaum EP)
        [1] = "STILL_WORTH",  -- Easy       = grün   -> lohnt sich gerade noch
        [2] = "GOOD",         -- Fair       = gelb   -> gut machbar
        [3] = "TOO_HARD",     -- Difficult  = orange -> noch zu schwer
        [4] = "TOO_HARD",     -- Impossible = rot    -> noch zu schwer
        verified = false,
    },

    -- Quest-Tags, die "Gruppe nötig" bedeuten (Constants.QuestConsts):
    groupTags = {
        [1]  = true,   -- QUEST_INFO_ELITE_ID   (Elite)
        [81] = true,   -- QUEST_INFO_DUNGEON_ID (Dungeon)
        [62] = true,   -- QUEST_INFO_RAID_ID    (Schlachtzug)
        verified = false,
    },
    -- Ab dieser empfohlenen Gruppengröße (QuestInfo.suggestedGroup) gilt "Gruppe nötig".
    minSuggestedGroup = { value = 2, verified = false },

    -- Reihenfolge der Prüfung: die erste passende Kategorie gewinnt.
    --   DONE   – fertig, nur noch abgeben
    --   SKIP   – grau: steht VOR "Gruppe", weil eine graue Gruppenquest keine EP mehr bringt
    --            (Reihenfolge vom Spieler bestätigt, Nov 2026)
    --   GROUP  – Elite/Dungeon/Schlachtzug oder empfohlene Gruppe
    --   danach die Farbe (TOO_HARD, GOOD, STILL_WORTH)
    order = { "DONE", "SKIP", "GROUP", "TOO_HARD", "GOOD", "STILL_WORTH" },

    -- Anzeige je Kategorie: Farbe (r, g, b), Text-Schlüssel in Locales/ und
    -- Symbol im Questlog (Blizzard-Grafiken; erste Wahl, nach Screenshot anpassen)
    categories = {
        DONE        = { color = { 0.3, 1.0, 0.3 },   label = "QA_DONE",        explain = "QA_DONE_TT",
                        icon = "Interface\\RaidFrame\\ReadyCheck-Ready" },
        SKIP        = { color = { 0.6, 0.6, 0.6 },   label = "QA_SKIP",        explain = "QA_SKIP_TT",
                        icon = "Interface\\COMMON\\Indicator-Gray" },
        GROUP       = { color = { 1.0, 0.5, 0.25 },  label = "QA_GROUP",       explain = "QA_GROUP_TT",
                        icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon" },
        TOO_HARD    = { color = { 1.0, 0.25, 0.25 }, label = "QA_TOO_HARD",    explain = "QA_TOO_HARD_TT",
                        icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8" },
        GOOD        = { color = { 1.0, 0.82, 0.0 },  label = "QA_GOOD",        explain = "QA_GOOD_TT",
                        icon = "Interface\\COMMON\\Indicator-Yellow" },
        STILL_WORTH = { color = { 0.25, 0.75, 0.25 },label = "QA_STILL_WORTH", explain = "QA_STILL_WORTH_TT",
                        icon = "Interface\\COMMON\\Indicator-Green" },
    },
}
