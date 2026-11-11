-- ============================================================
-- Data/Talents.lua
-- Talent-Builds als GEORDNETE LISTE VON PUNKTEN.
--
-- Aufbau eines Builds:
--   steps = Liste von Schritten. Jeder Schritt sagt: "Die nächsten <ranks>
--   Punkte kommen in dieses Talent". Das Addon macht daraus automatisch
--   die Punkte 1, 2, 3 ... 51. Level wird NICHT gespeichert, sondern
--   berechnet: Level = FIRST_TALENT_LEVEL + (Punkt - 1).
--
-- Ein Talent wird sprachunabhängig referenziert über:
--   nodeID       = feste Talent-ID aus dem Spiel (aus /ww talentdump)
--   tree/tier/column = Baum (1 Elementarkampf, 2 Verstärkung,
--                  3 Wiederherstellung), Reihe, Spalte – zur Kontrolle
--   maxRank      = maximaler Rang laut Spiel – zur Kontrolle
-- Beim Laden prüft das Addon, ob das alles noch zum Baum im Spiel passt,
-- und warnt sonst ("Talentbaum hat sich geändert – Build prüfen").
-- Der englische Talentname steht nur als Kommentar; angezeigt wird
-- immer der Name aus dem Spiel (also auf Deutsch im deutschen Client).
--
-- Positionen/nodeIDs: aus talentdump vom 2026-11-11, Build 1.60.1.70888,
-- deutscher Client, Schamane Level 12.
-- ============================================================

local _, ns = ...

ns.TalentBuilds = ns.TalentBuilds or {}

-- ------------------------------------------------------------
-- SCHAMANE – Heal-Reiter (Leveling-Hybrid Verstärkung/Wiederherstellung)
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "SHAMAN_RESTORATION_LEVELING_HYBRID",
    class     = "SHAMAN",
    spec      = "RESTORATION",
    buildType = "LEVELING",            -- "ENDGAME" folgt später als eigener Build
    variant   = "HYBRID_ENH_RESTO",
    source    = "PLAYER",

    structureVerified = true,          -- Baum vom Spieler abgeglichen, Nov 2026
    positionsVerified = true,          -- nodeID/Reihe/Spalte/maxRank aus talentdump 2026-11-11
    orderVerified     = false,         -- noch nicht durchgelevelt
    verified          = false,

    title = {
        deDE = "Heal-Reiter (Leveling-Build)",
        enUS = "Healer Rider (leveling build)",
    },
    summary = {
        deDE = "Leveling-Hybrid: Questen + Dungeon-Heilen. Reiner Heil-Build folgt für Endgame.",
        enUS = "Leveling hybrid: questing + dungeon healing. A pure healing build for endgame will follow.",
    },
    -- Endverteilung: Elementarkampf / Verstärkung / Wiederherstellung
    distribution = { 0, 22, 29 },

    phases = {
        A = { deDE = "Phase A – Questen",          enUS = "Phase A – Questing" },
        B = { deDE = "Phase B – Dungeon-Heilen",   enUS = "Phase B – Dungeon healing" },
        C = { deDE = "Phase C – Hybrid-Kern",      enUS = "Phase C – Hybrid core" },
        D = { deDE = "Phase D – Heiler ausbauen",  enUS = "Phase D – Expand healing" },
    },

    steps = {
        -- ===== PHASE A – Questen (Verstärkung), Punkte 1–18 =====
        { phase = "A", nodeID = 104753, tree = 2, tier = 1, column = 2, maxRank = 5, ranks = 5, -- Thundering Strikes
          reason = { deDE = "+1 % kritische Trefferchance pro Rang für alle Angriffe und Zauber.",
                     enUS = "+1% critical strike chance per rank for all attacks and spells." } },
        { phase = "A", nodeID = 104755, tree = 2, tier = 2, column = 2, maxRank = 3, ranks = 3, -- Mental Dexterity
          reason = { deDE = "Intelligenz gibt Angriffskraft – und es ist die Voraussetzung für Schlaghagel.",
                     enUS = "Intelligence grants attack power – and it is required for Flurry." } },
        { phase = "A", nodeID = 104756, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 2, -- Ancestral Knowledge
          reason = { deDE = "Mehr Intelligenz – stärkt Nahkampf und Heilung gleichzeitig.",
                     enUS = "More Intelligence – boosts melee and healing at the same time." } },
        { phase = "A", nodeID = 104749, tree = 2, tier = 3, column = 3, maxRank = 1, ranks = 1, -- Shamanistic Focus
          reason = { deDE = "Schocks und Blitzschlagschild werden deutlich billiger.",
                     enUS = "Shocks and Lightning Shield become much cheaper." } },
        { phase = "A", nodeID = 104750, tree = 2, tier = 3, column = 1, maxRank = 3, ranks = 3, -- Elemental Weapons
          reason = { deDE = "Mehr Schaden durch deine Waffenverzauberungen.",
                     enUS = "More damage from your weapon imbues." } },
        { phase = "A", nodeID = 104756, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 1, -- Ancestral Knowledge (3/5)
          reason = { deDE = "Füllpunkt für die nächste Reihe – und noch etwas mehr Intelligenz.",
                     enUS = "Filler point for the next row – plus a bit more Intelligence." } },
        { phase = "A", nodeID = 104743, tree = 2, tier = 4, column = 3, maxRank = 1, ranks = 1, -- Stormstrike
          reason = { deDE = "Dein neuer Hauptangriff im Nahkampf.",
                     enUS = "Your new main melee attack." } },
        { phase = "A", nodeID = 104752, tree = 2, tier = 4, column = 4, maxRank = 2, ranks = 2, -- Improved Ghost Wolf
          reason = { deDE = "Schnellerer Geisterwolf, auch in Gebäuden – spart beim Questen viel Laufzeit.",
                     enUS = "Faster Ghost Wolf, even indoors – saves a lot of travel time while questing." } },

        -- ===== PHASE B – Dungeon-Heilen (Wiederherstellung), Punkte 19–29 =====
        { phase = "B", nodeID = 104729, tree = 3, tier = 1, column = 3, maxRank = 5, ranks = 5, -- Tidal Focus
          reason = { deDE = "Heilzauber kosten weniger Mana.",
                     enUS = "Healing spells cost less mana." } },
        { phase = "B", nodeID = 104734, tree = 3, tier = 2, column = 1, maxRank = 3, ranks = 3, -- Mindfulness
          reason = { deDE = "Deine Manaregeneration läuft auch beim Zaubern weiter.",
                     enUS = "Your mana regeneration continues while casting." } },
        { phase = "B", nodeID = 104735, tree = 3, tier = 2, column = 3, maxRank = 5, ranks = 2, -- Totemic Focus
          reason = { deDE = "Günstigere Totems.",
                     enUS = "Cheaper totems." } },
        { phase = "B", nodeID = 104732, tree = 3, tier = 3, column = 3, maxRank = 1, ranks = 1, -- Water Shield
          reason = { deDE = "Gibt dir Mana zurück, wenn du getroffen wirst oder kritisch heilst.",
                     enUS = "Returns mana when you are hit or land a critical heal." } },

        -- ===== PHASE C – Hybrid-Kern (Verstärkung), Punkte 30–33 =====
        { phase = "C", nodeID = 104747, tree = 2, tier = 4, column = 2, maxRank = 5, ranks = 2, -- Flurry
          reason = { deDE = "Schnellere Angriffe nach einem kritischen Treffer.",
                     enUS = "Faster attacks after a critical strike." } },
        { phase = "C", nodeID = 104744, tree = 2, tier = 5, column = 2, maxRank = 2, ranks = 2, -- Mental Quickness
          reason = { deDE = "Intelligenz verstärkt Heilung und Zauberschaden.",
                     enUS = "Intelligence increases healing and spell damage." } },

        -- ===== PHASE D – Heiler ausbauen (Wiederherstellung), Punkte 34–51 =====
        -- Hinweis: Diese Begründungen beschreiben die Talente so, wie sie aus
        -- Classic bekannt sind. Im Forever-Tooltip prüfen (verified = false).
        { phase = "D", nodeID = 104739, tree = 3, tier = 1, column = 2, maxRank = 5, ranks = 5, -- Improved Healing Wave
          reason = { deDE = "Welle der Heilung wird schneller gewirkt.",
                     enUS = "Healing Wave casts faster." } },
        { phase = "D", nodeID = 104728, tree = 3, tier = 4, column = 3, maxRank = 1, ranks = 1, -- Mana Tide Totem
          reason = { deDE = "Totem, das der Gruppe Mana zurückgibt – Notfall-Knopf für lange Kämpfe.",
                     enUS = "Totem that restores mana to your group – emergency button for long fights." } },
        { phase = "D", nodeID = 104738, tree = 3, tier = 4, column = 1, maxRank = 5, ranks = 4, -- Tidal Mastery
          reason = { deDE = "Höhere kritische Chance für Heil- und Blitzzauber.",
                     enUS = "Higher critical chance for healing and lightning spells." } },
        { phase = "D", nodeID = 104727, tree = 3, tier = 5, column = 2, maxRank = 3, ranks = 3, -- Healing Way
          reason = { deDE = "Welle der Heilung heilt dasselbe Ziel bei wiederholtem Einsatz stärker.",
                     enUS = "Healing Wave heals the same target more on repeated casts." } },
        { phase = "D", nodeID = 104726, tree = 3, tier = 5, column = 3, maxRank = 1, ranks = 1, -- Nature's Swiftness
          reason = { deDE = "Macht den nächsten Zauber sofort – rettet Leben in Notfällen.",
                     enUS = "Makes your next spell instant – saves lives in emergencies." } },
        { phase = "D", nodeID = 104725, tree = 3, tier = 6, column = 3, maxRank = 5, ranks = 4, -- Purification
          reason = { deDE = "Alle deine Heilzauber heilen mehr.",
                     enUS = "All your healing spells heal more." } },
    },

    -- Bekannte Kompromisse – werden im Addon als Hinweis angezeigt
    notes = {
        { deDE = "Schlaghagel nur 2/5: Die Punkte werden für Verbesserten Geisterwolf und den Heil-Ausbau gebraucht.",
          enUS = "Flurry only 2/5: the points are needed for Improved Ghost Wolf and the healing expansion." },
        { deDE = "Springflut ist bewusst nicht im Build: Sie bräuchte 30 Punkte in Wiederherstellung, Geistige Schnelligkeit ist für den Hybrid wertvoller.",
          enUS = "Riptide is intentionally left out: it needs 30 points in Restoration, and Mental Quickness is more valuable for the hybrid." },
        { deDE = "Legacy-Bonuspunkte sind noch nicht eingeplant.",
          enUS = "Legacy bonus points are not planned in yet." },
        { deDE = "Ein reiner Heil-Build (für Spieler, die hauptsächlich in Gruppen leveln) folgt später.",
          enUS = "A pure healing build (for players who mostly level in groups) will follow later." },
    },
})

-- ------------------------------------------------------------
-- JÄGER – Tierherrschaft (Leveling)
-- QUELLE: Wowhead (Leveling-Talentbuild Jäger, WoW Forever), vom Spieler
-- übernommen, Nov 2026:
--   https://www.wowhead.com/forever/de/guide/classes/hunter/beast-mastery/dps-leveling-tips
-- Verteilung 31 Tierherrschaft / 16 Treffsicherheit / 4 Überleben.
-- STATUS: planned = true -> noch NICHT aktiv. Es fehlen nodeID, Reihe,
-- Spalte und maxRank – die kommen aus /ww talentdump eines Jägers.
-- Bis dahin stehen nur die englischen Namen der Quelle (en) drin.
-- Baum-Nummern 1/2/3 = Reihenfolge im Talentfenster (laut Grafik:
-- Tierherrschaft, Treffsicherheit, Überleben) – im Dump prüfen.
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "HUNTER_BEASTMASTERY_LEVELING",
    class     = "HUNTER",
    spec      = "BEASTMASTERY",
    buildType = "LEVELING",
    variant   = "BM_MM",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/de/guide/classes/hunter/beast-mastery/dps-leveling-tips",
    resolveByName = true,        -- Talente über den Namen im Spiel-Baum finden
    structureVerified = true,    -- im Spiel bestätigt: alle 19 Namen im deutschen Client gefunden,
                                 -- Reihen/Pfeile passen (Spieler, Nov 2026, Version 0.19.4)
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,

    title = { deDE = "Tierherrschaft (Leveling-Build)", enUS = "Beast Mastery (leveling build)" },
    summary = {
        deDE = "Leveling mit starkem Begleiter: erst Tierherrschaft bis Zorn des Wildtiers, dann Treffsicherheit.",
        enUS = "Leveling with a strong pet: Beast Mastery up to Bestial Wrath first, then Marksmanship.",
    },
    distribution = { 31, 16, 4 },

    phases = {
        A = { deDE = "Phase A – Tierherrschaft",  enUS = "Phase A – Beast Mastery" },
        B = { deDE = "Phase B – Treffsicherheit", enUS = "Phase B – Marksmanship" },
        C = { deDE = "Phase C – Überleben",       enUS = "Phase C – Survival" },
    },

    -- Reihenfolge laut Spieler (Punkt 1 = Level 10 … Punkt 51 = Level 60)
    steps = {
        { phase = "A", tree = 1, en = "Deadly Aspects", de = "Tödliche Aspekte", ranks = 5 },  -- Lvl 10–14
        { phase = "A", tree = 1, en = "Focused Fire", de = "Konzentriertes Feuer", ranks = 2 },  -- 15–16
        { phase = "A", tree = 1, en = "Endurance Training", de = "Belastbarkeit-Ausbildung", ranks = 3 },  -- 17–19
        { phase = "A", tree = 1, en = "Bestial Swiftness", de = "Erhöhte Tiergeschwindigkeit", ranks = 1 },  -- 20
        { phase = "A", tree = 1, en = "Unleashed Fury", de = "Entfesselter Zorn", ranks = 4 },  -- 21–24
        { phase = "A", tree = 1, en = "Summon Hawk", de = "Falke beschwören", ranks = 1 },  -- 25
        { phase = "A", tree = 1, en = "Unleashed Fury", de = "Entfesselter Zorn", ranks = 1 },  -- 26 (5/5)
        { phase = "A", tree = 1, en = "Ferocity", de = "Wildheit",        ranks = 3 },  -- 27–29
        { phase = "A", tree = 1, en = "Intimidation", de = "Einschüchterung", ranks = 1 },  -- 30
        { phase = "A", tree = 1, en = "Bestial Discipline", de = "Wildtierdisziplin", ranks = 2 },  -- 31–32
        { phase = "A", tree = 1, en = "Ferocity", de = "Wildheit",        ranks = 2 },  -- 33–34 (5/5)
        { phase = "A", tree = 1, en = "Frenzy", de = "Raserei",           ranks = 5 },  -- 35–39
        { phase = "A", tree = 1, en = "Bestial Wrath", de = "Zorn des Wildtiers", ranks = 1 },  -- 40
        { phase = "B", tree = 2, en = "Lethal Attacks", de = "Tödliche Angriffe", ranks = 5 },  -- 41–45
        { phase = "B", tree = 2, en = "Careful Aim", de = "Sorgfältiges Zielen", ranks = 5 },  -- 46–50
        { phase = "B", tree = 2, en = "Improved Stings", de = "Verbesserte Stiche und Bisse", ranks = 3 },  -- 51–53
        { phase = "B", tree = 2, en = "Rapid Killing", de = "Schneller Tod", ranks = 2 },  -- 54–55
        { phase = "B", tree = 2, en = "Trueshot Aura", de = "Aura des Volltreffers", ranks = 1 },  -- 56
        { phase = "C", tree = 3, en = "Improved Tracking", de = "Verbessertes Fährtenlesen", ranks = 4 },  -- 57–60
    },
    notes = {},
})

-- ------------------------------------------------------------
-- Vorbereitet, noch ohne Daten (NICHTS erfinden – folgt später):
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key = "SHAMAN_ELEMENTAL_LEVELING", class = "SHAMAN", spec = "ELEMENTAL",
    buildType = "LEVELING", variant = nil, source = nil, planned = true,
    structureVerified = false, orderVerified = false, verified = false,
    title = { deDE = "Elementar (Leveling-Build)", enUS = "Elemental (leveling build)" },
    steps = {},
})
table.insert(ns.TalentBuilds, {
    key = "SHAMAN_ENHANCEMENT_LEVELING", class = "SHAMAN", spec = "ENHANCEMENT",
    buildType = "LEVELING", variant = nil, source = nil, planned = true,
    structureVerified = false, orderVerified = false, verified = false,
    title = { deDE = "Verstärkung (Leveling-Build)", enUS = "Enhancement (leveling build)" },
    steps = {},
})
-- Endgame-Builds bekommen buildType = "ENDGAME" und dieselbe Struktur.
