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
    menu = { deDE = "Heal – Leveling-Hybrid", enUS = "Healer – leveling hybrid" },
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
    menu  = { deDE = "Tierherrschaft – Leveling", enUS = "Beast Mastery – leveling" },
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
-- ------------------------------------------------------------
-- SCHAMANE – Spellhancer (Leveling)
-- QUELLE: Wowhead, Elementar-Leveling-Guide, "Spellhance 31-60":
--   https://www.wowhead.com/forever/guide/classes/shaman/elemental/dps-leveling-tips#best-leveling-builds-spellhance-31-60
-- Kein reiner Elementar-Build: zuerst Verstärkung, dann Wiederherstellung (Mana),
-- dann Elementar. nodeID/Reihe/Spalte/maxRank aus dem Schamanen-Talentdump
-- (2026-11-11), Positionen mit Wowhead-Grafik abgeglichen (18/25/8).
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "SHAMAN_SPELLHANCE_LEVELING",
    class     = "SHAMAN",
    spec      = "ELEMENTAL",
    buildType = "LEVELING",
    variant   = "SPELLHANCE",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/shaman/elemental/dps-leveling-tips#best-leveling-builds-spellhance-31-60",
    structureVerified = true,          -- Positionen = Talentdump, Grafik abgeglichen
    positionsVerified = true,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Spellhancer (Leveling-Build)", enUS = "Spellhancer (leveling build)" },
    menu  = { deDE = "Spellhancer – Leveling", enUS = "Spellhancer – leveling" },
    summary = {
        deDE = "Wowheads Leveling-Empfehlung im Elementar-Guide. Kein reiner Elementar-Build: erst Verstärkung, dann Mana-Talente, dann Elementar für Schocks und Blitze.",
        enUS = "Wowhead's leveling pick in the Elemental guide. Not a pure Elemental build: Enhancement first, then mana talents, then Elemental for shocks and lightning.",
    },
    distribution = { 18, 25, 8 },
    phases = {
        A = { deDE = "Phase A – Verstärkung (Questen)",       enUS = "Phase A – Enhancement (questing)" },
        B = { deDE = "Phase B – Wiederherstellung (Mana)",    enUS = "Phase B – Restoration (mana)" },
        C = { deDE = "Phase C – Elementar (Schocks & Blitze)", enUS = "Phase C – Elemental (shocks & lightning)" },
    },
    steps = {
        { phase = "A", nodeID = 104753, tree = 2, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Thundering Strikes / Donnernde Stöße
        { phase = "A", nodeID = 104755, tree = 2, tier = 2, column = 2, maxRank = 3, ranks = 3 }, -- Mental Dexterity / Geistige Gewandtheit
        { phase = "A", nodeID = 104751, tree = 2, tier = 2, column = 3, maxRank = 3, ranks = 2 }, -- Improved Lightning Shield / Verbesserter Blitzschlagschild
        { phase = "A", nodeID = 104749, tree = 2, tier = 3, column = 3, maxRank = 1, ranks = 1 }, -- Shamanistic Focus / Schamanistischer Fokus
        { phase = "A", nodeID = 104750, tree = 2, tier = 3, column = 1, maxRank = 3, ranks = 3 }, -- Elemental Weapons / Elementarwaffen
        { phase = "A", nodeID = 104751, tree = 2, tier = 2, column = 3, maxRank = 3, ranks = 1 }, -- Improved Lightning Shield / Verbesserter Blitzschlagschild
        { phase = "A", nodeID = 104752, tree = 2, tier = 4, column = 4, maxRank = 2, ranks = 2 }, -- Improved Ghost Wolf / Verbesserter Geisterwolf
        { phase = "A", nodeID = 104743, tree = 2, tier = 4, column = 3, maxRank = 1, ranks = 1 }, -- Stormstrike / Sturmschlag
        { phase = "A", nodeID = 104747, tree = 2, tier = 4, column = 2, maxRank = 5, ranks = 2 }, -- Flurry / Schlaghagel
        { phase = "A", nodeID = 104742, tree = 2, tier = 5, column = 3, maxRank = 2, ranks = 2 }, -- Improved Stormstrike / Verbesserter Sturmschlag
        { phase = "A", nodeID = 104744, tree = 2, tier = 5, column = 2, maxRank = 2, ranks = 2 }, -- Mental Quickness / Geistige Schnelligkeit
        { phase = "A", nodeID = 104745, tree = 2, tier = 5, column = 1, maxRank = 1, ranks = 1 }, -- Spirit Weapons / Waffen der Geister
        { phase = "B", nodeID = 104729, tree = 3, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Tidal Focus / Gezeitenfokus
        { phase = "B", nodeID = 104734, tree = 3, tier = 2, column = 1, maxRank = 3, ranks = 3 }, -- Mindfulness / Achtsamkeit
        { phase = "C", nodeID = 104772, tree = 1, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Concussion / Erschütterung
        { phase = "C", nodeID = 104770, tree = 1, tier = 2, column = 4, maxRank = 3, ranks = 3 }, -- Call of Flame / Ruf der Flamme
        { phase = "C", nodeID = 104769, tree = 1, tier = 2, column = 1, maxRank = 3, ranks = 2 }, -- Elemental Devastation / Elementarverwüstung
        { phase = "C", nodeID = 104768, tree = 1, tier = 3, column = 1, maxRank = 1, ranks = 1 }, -- Elemental Focus / Elementarfokus
        { phase = "C", nodeID = 104769, tree = 1, tier = 2, column = 1, maxRank = 3, ranks = 1 }, -- Elemental Devastation / Elementarverwüstung
        { phase = "C", nodeID = 104773, tree = 1, tier = 1, column = 2, maxRank = 5, ranks = 3 }, -- Convection / Konvektion
        { phase = "C", nodeID = 104764, tree = 1, tier = 4, column = 1, maxRank = 2, ranks = 2 }, -- Trial by Fire / Feuerprobe
        { phase = "C", nodeID = 104762, tree = 1, tier = 4, column = 4, maxRank = 1, ranks = 1 }, -- Earthbound / Erdgebunden
    },
    notes = {
        { deDE = "Für reines Elementar (Fernkampf-Zauberer) ist dieser Build nicht gedacht – ein eigener Build kann später folgen.",
          enUS = "Not meant for pure Elemental (ranged caster) – a separate build may follow later." },
    },
})

-- ------------------------------------------------------------
-- SCHAMANE – Verstärkung (Leveling)
-- QUELLE: Wowhead, Verstärkungs-Leveling-Guide:
--   https://www.wowhead.com/forever/guide/classes/shaman/enhancement/dps-leveling-tips
-- nodeID/Reihe/Spalte/maxRank aus dem Schamanen-Talentdump (2026-11-11),
-- Positionen mit Wowhead-Grafik abgeglichen (18/25/8).
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "SHAMAN_ENHANCEMENT_LEVELING",
    class     = "SHAMAN",
    spec      = "ENHANCEMENT",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/shaman/enhancement/dps-leveling-tips",
    structureVerified = true,
    positionsVerified = true,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Verstärkung (Leveling-Build)", enUS = "Enhancement (leveling build)" },
    menu  = { deDE = "Verstärkung – Leveling", enUS = "Enhancement – leveling" },
    summary = {
        deDE = "Wowheads Leveling-Empfehlung für Verstärkung: Nahkampf mit Sturmschlag, später Mana- und Elementar-Talente.",
        enUS = "Wowhead's leveling pick for Enhancement: melee with Stormstrike, later mana and Elemental talents.",
    },
    distribution = { 18, 25, 8 },
    phases = {
        A = { deDE = "Phase A – Verstärkung (Questen)",       enUS = "Phase A – Enhancement (questing)" },
        B = { deDE = "Phase B – Wiederherstellung (Mana)",    enUS = "Phase B – Restoration (mana)" },
        C = { deDE = "Phase C – Elementar (Schocks & Blitze)", enUS = "Phase C – Elemental (shocks & lightning)" },
    },
    steps = {
        { phase = "A", nodeID = 104753, tree = 2, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Thundering Strikes / Donnernde Stöße
        { phase = "A", nodeID = 104755, tree = 2, tier = 2, column = 2, maxRank = 3, ranks = 3 }, -- Mental Dexterity / Geistige Gewandtheit
        { phase = "A", nodeID = 104756, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 2 }, -- Ancestral Knowledge / Wissen der Ahnen
        { phase = "A", nodeID = 104749, tree = 2, tier = 3, column = 3, maxRank = 1, ranks = 1 }, -- Shamanistic Focus / Schamanistischer Fokus
        { phase = "A", nodeID = 104750, tree = 2, tier = 3, column = 1, maxRank = 3, ranks = 3 }, -- Elemental Weapons / Elementarwaffen
        { phase = "A", nodeID = 104748, tree = 2, tier = 3, column = 4, maxRank = 3, ranks = 1 }, -- Anticipation / Vorahnung
        { phase = "A", nodeID = 104752, tree = 2, tier = 4, column = 4, maxRank = 2, ranks = 1 }, -- Improved Ghost Wolf / Verbesserter Geisterwolf
        { phase = "A", nodeID = 104743, tree = 2, tier = 4, column = 3, maxRank = 1, ranks = 1 }, -- Stormstrike / Sturmschlag
        { phase = "A", nodeID = 104752, tree = 2, tier = 4, column = 4, maxRank = 2, ranks = 1 }, -- Improved Ghost Wolf / Verbesserter Geisterwolf
        { phase = "A", nodeID = 104747, tree = 2, tier = 4, column = 2, maxRank = 5, ranks = 2 }, -- Flurry / Schlaghagel
        { phase = "A", nodeID = 104742, tree = 2, tier = 5, column = 3, maxRank = 2, ranks = 2 }, -- Improved Stormstrike / Verbesserter Sturmschlag
        { phase = "A", nodeID = 104744, tree = 2, tier = 5, column = 2, maxRank = 2, ranks = 2 }, -- Mental Quickness / Geistige Schnelligkeit
        { phase = "A", nodeID = 104745, tree = 2, tier = 5, column = 1, maxRank = 1, ranks = 1 }, -- Spirit Weapons / Waffen der Geister
        { phase = "B", nodeID = 104729, tree = 3, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Tidal Focus / Gezeitenfokus
        { phase = "B", nodeID = 104734, tree = 3, tier = 2, column = 1, maxRank = 3, ranks = 3 }, -- Mindfulness / Achtsamkeit
        { phase = "C", nodeID = 104772, tree = 1, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Concussion / Erschütterung
        { phase = "C", nodeID = 104770, tree = 1, tier = 2, column = 4, maxRank = 3, ranks = 3 }, -- Call of Flame / Ruf der Flamme
        { phase = "C", nodeID = 104769, tree = 1, tier = 2, column = 1, maxRank = 3, ranks = 2 }, -- Elemental Devastation / Elementarverwüstung
        { phase = "C", nodeID = 104768, tree = 1, tier = 3, column = 1, maxRank = 1, ranks = 1 }, -- Elemental Focus / Elementarfokus
        { phase = "C", nodeID = 104769, tree = 1, tier = 2, column = 1, maxRank = 3, ranks = 1 }, -- Elemental Devastation / Elementarverwüstung
        { phase = "C", nodeID = 104767, tree = 1, tier = 2, column = 2, maxRank = 5, ranks = 3 }, -- Reverberation / Nachklingen
        { phase = "C", nodeID = 104764, tree = 1, tier = 4, column = 1, maxRank = 2, ranks = 2 }, -- Trial by Fire / Feuerprobe
        { phase = "C", nodeID = 104762, tree = 1, tier = 4, column = 4, maxRank = 1, ranks = 1 }, -- Earthbound / Erdgebunden
    },
    notes = {},
})

-- ------------------------------------------------------------
-- JÄGER – Treffsicherheit (Leveling)
-- QUELLE: Wowhead, Treffsicherheit-Leveling-Guide:
--   https://www.wowhead.com/forever/guide/classes/hunter/marksmanship/dps-leveling-tips
-- Reihenfolge laut Spieler (Liste + Grafik, 15/36/0).
-- nodeID/Reihe/Spalte/maxRank aus dem Talentdump aller Klassen (2026-11-12).
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "HUNTER_MARKSMANSHIP_LEVELING",
    class     = "HUNTER",
    spec      = "MARKSMANSHIP",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/hunter/marksmanship/dps-leveling-tips",
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Treffsicherheit (Leveling-Build)", enUS = "Marksmanship (leveling build)" },
    menu  = { deDE = "Treffsicherheit – Leveling", enUS = "Marksmanship – leveling" },
    summary = {
        deDE = "Wowheads Leveling-Empfehlung für Treffsicherheit: Fernkampfschaden zuerst, danach Begleiter-Talente aus Tierherrschaft.",
        enUS = "Wowhead's leveling pick for Marksmanship: ranged damage first, then pet talents from Beast Mastery.",
    },
    distribution = { 15, 36, 0 },
    phases = {
        A = { deDE = "Phase A – Treffsicherheit",                         enUS = "Phase A – Marksmanship" },
        B = { deDE = "Phase B – Tierherrschaft & restliche Treffsicherheit", enUS = "Phase B – Beast Mastery & remaining Marksmanship" },
    },
    steps = {
        { phase = "A", nodeID = 105011, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lethal Attacks / Tödliche Angriffe
        { phase = "A", nodeID = 105008, tree = 2, tier = 2, column = 3, maxRank = 5, ranks = 5 }, -- Careful Aim / Sorgfältiges Zielen
        { phase = "A", nodeID = 105005, tree = 2, tier = 3, column = 1, maxRank = 2, ranks = 2 }, -- Rapid Killing / Schneller Tod
        { phase = "A", nodeID = 105009, tree = 2, tier = 2, column = 2, maxRank = 5, ranks = 3 }, -- Efficiency / Effizienz
        { phase = "A", nodeID = 105004, tree = 2, tier = 4, column = 2, maxRank = 1, ranks = 1 }, -- Trueshot Aura / Aura des Volltreffers
        { phase = "A", nodeID = 105002, tree = 2, tier = 4, column = 3, maxRank = 5, ranks = 4 }, -- Mortal Shots / Todbringende Schüsse
        { phase = "A", nodeID = 104999, tree = 2, tier = 5, column = 1, maxRank = 2, ranks = 2 }, -- Rapid Recuperation / Rasche Erholung
        { phase = "A", nodeID = 105002, tree = 2, tier = 4, column = 3, maxRank = 5, ranks = 1 }, -- Mortal Shots / Todbringende Schüsse
        { phase = "A", nodeID = 105009, tree = 2, tier = 2, column = 2, maxRank = 5, ranks = 2 }, -- Efficiency / Effizienz
        { phase = "B", nodeID = 104998, tree = 2, tier = 6, column = 3, maxRank = 5, ranks = 5 }, -- Ranged Weapon Specialization / Distanzwaffen-Spezialisierung
        { phase = "B", nodeID = 104960, tree = 1, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Deadly Aspects / Tödliche Aspekte
        { phase = "B", nodeID = 104975, tree = 1, tier = 2, column = 1, maxRank = 2, ranks = 2 }, -- Focused Fire / Konzentriertes Feuer
        { phase = "B", nodeID = 104976, tree = 1, tier = 1, column = 3, maxRank = 5, ranks = 3 }, -- Endurance Training / Belastbarkeit-Ausbildung
        { phase = "B", nodeID = 104970, tree = 1, tier = 3, column = 2, maxRank = 1, ranks = 1 }, -- Bestial Swiftness / Erhöhte Tiergeschwindigkeit
        { phase = "B", nodeID = 105000, tree = 2, tier = 5, column = 4, maxRank = 1, ranks = 1 }, -- Scatter Shot / Streuschuss
        { phase = "B", nodeID = 104969, tree = 1, tier = 3, column = 3, maxRank = 5, ranks = 4 }, -- Unleashed Fury / Entfesselter Zorn
        { phase = "B", nodeID = 105006, tree = 2, tier = 3, column = 2, maxRank = 5, ranks = 5 }, -- Improved Arcane Shot / Verbesserter arkaner Schuss
    },
    notes = {},
})

-- ------------------------------------------------------------
-- JÄGER – Überleben (Leveling)
-- QUELLE: Wowhead, Überleben-Leveling-Guide:
--   https://www.wowhead.com/forever/guide/classes/hunter/survival/dps-leveling-tips
-- Reihenfolge laut Spieler (Liste + Grafik, 16/9/26).
-- nodeID/Reihe/Spalte/maxRank aus dem Talentdump aller Klassen (2026-11-12).
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "HUNTER_SURVIVAL_LEVELING",
    class     = "HUNTER",
    spec      = "SURVIVAL",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/hunter/survival/dps-leveling-tips",
    structureVerified = true,
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Überleben (Leveling-Build)", enUS = "Survival (leveling build)" },
    menu  = { deDE = "Überleben – Leveling", enUS = "Survival – leveling" },
    summary = {
        deDE = "Wowheads Leveling-Empfehlung für Überleben: zuerst Überleben, dann Begleiter-Talente, zum Schluss Treffsicherheit.",
        enUS = "Wowhead's leveling pick for Survival: Survival first, then pet talents, Marksmanship last.",
    },
    distribution = { 16, 9, 26 },
    phases = {
        A = { deDE = "Phase A – Überleben",       enUS = "Phase A – Survival" },
        B = { deDE = "Phase B – Tierherrschaft",  enUS = "Phase B – Beast Mastery" },
        C = { deDE = "Phase C – Treffsicherheit", enUS = "Phase C – Marksmanship" },
    },
    steps = {
        { phase = "A", nodeID = 104996, tree = 3, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Improved Tracking / Verbessertes Fährtenlesen
        { phase = "A", nodeID = 104993, tree = 3, tier = 2, column = 2, maxRank = 2, ranks = 2 }, -- Savage Strikes / Wilde Schläge
        { phase = "A", nodeID = 104992, tree = 3, tier = 2, column = 3, maxRank = 5, ranks = 3 }, -- Survivalist / Überlebenskünstler
        { phase = "A", nodeID = 104986, tree = 3, tier = 3, column = 3, maxRank = 1, ranks = 1 }, -- Deterrence / Abschreckung
        { phase = "A", nodeID = 104987, tree = 3, tier = 3, column = 2, maxRank = 3, ranks = 3 }, -- Surefooted / Sicherer Stand
        { phase = "A", nodeID = 104991, tree = 3, tier = 3, column = 1, maxRank = 2, ranks = 1 }, -- Clever Traps / Falleneffizienz
        { phase = "A", nodeID = 104989, tree = 3, tier = 4, column = 3, maxRank = 1, ranks = 1 }, -- Counterattack / Gegenangriff
        { phase = "A", nodeID = 110861, tree = 3, tier = 4, column = 2, maxRank = 5, ranks = 4 }, -- Predator's Edge / Vorteil des Raubtiers
        { phase = "A", nodeID = 104981, tree = 3, tier = 5, column = 4, maxRank = 1, ranks = 1 }, -- Strider Kick / Streichertritt
        { phase = "A", nodeID = 104983, tree = 3, tier = 5, column = 1, maxRank = 2, ranks = 2 }, -- Resourcefulness / Einfallsreichtum
        { phase = "A", nodeID = 110861, tree = 3, tier = 4, column = 2, maxRank = 5, ranks = 1 }, -- Predator's Edge / Vorteil des Raubtiers
        { phase = "A", nodeID = 104985, tree = 3, tier = 5, column = 2, maxRank = 2, ranks = 2 }, -- Expose Prey / Beute aufspüren
        { phase = "B", nodeID = 104960, tree = 1, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Deadly Aspects / Tödliche Aspekte
        { phase = "B", nodeID = 104975, tree = 1, tier = 2, column = 1, maxRank = 2, ranks = 2 }, -- Focused Fire / Konzentriertes Feuer
        { phase = "B", nodeID = 104976, tree = 1, tier = 1, column = 3, maxRank = 5, ranks = 3 }, -- Endurance Training / Belastbarkeit-Ausbildung
        { phase = "B", nodeID = 104970, tree = 1, tier = 3, column = 2, maxRank = 1, ranks = 1 }, -- Bestial Swiftness / Erhöhte Tiergeschwindigkeit
        { phase = "B", nodeID = 104969, tree = 1, tier = 3, column = 3, maxRank = 5, ranks = 4 }, -- Unleashed Fury / Entfesselter Zorn
        { phase = "B", nodeID = 104966, tree = 1, tier = 4, column = 4, maxRank = 1, ranks = 1 }, -- Summon Hawk / Falke beschwören
        { phase = "C", nodeID = 105011, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lethal Attacks / Tödliche Angriffe
        { phase = "C", nodeID = 105008, tree = 2, tier = 2, column = 3, maxRank = 5, ranks = 4 }, -- Careful Aim / Sorgfältiges Zielen
    },
    notes = {},
})

-- ------------------------------------------------------------
-- DRUIDE – Wilder Kampf, Katze (Leveling)
-- QUELLE: Wowhead:
--   https://www.wowhead.com/forever/guide/classes/druid/feral/dps-leveling-tips
-- Reihenfolge laut Spieler (Liste + Grafik, 9/32/10).
-- nodeID/Reihe/Spalte/maxRank aus dem Druiden-Talentdump (2026-11-12).
-- Englisch -> Deutsch über die Position im Baum zugeordnet (Wowhead-Grafik).
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "DRUID_FERAL_LEVELING",
    class     = "DRUID",
    spec      = "FERAL",
    buildType = "LEVELING",
    variant   = "CAT",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/druid/feral/dps-leveling-tips",
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Wilder Kampf – Katze (Leveling-Build)", enUS = "Feral – Cat (leveling build)" },
    menu  = { deDE = "Katze – Leveling", enUS = "Cat – leveling" },
    summary = {
        deDE = "Wowheads Leveling-Empfehlung für Wilder Kampf (Schaden): erst Katzen-Talente, dann Wiederherstellung, zum Schluss Gleichgewicht.",
        enUS = "Wowhead's leveling pick for Feral damage: cat talents first, then Restoration, Balance last.",
    },
    distribution = { 9, 32, 10 },
    phases = {
        A = { deDE = "Phase A – Wilder Kampf", enUS = "Phase A – Feral Combat" },
        B = { deDE = "Phase B – Wiederherstellung", enUS = "Phase B – Restoration" },
        C = { deDE = "Phase C – Gleichgewicht", enUS = "Phase C – Balance" },
    },
    steps = {
        { phase = "A", nodeID = 104938, tree = 2, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 10: Ferocity / Wildheit
        { phase = "A", nodeID = 104939, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 3 }, -- Lvl 15: Furor / Ingrimm
        { phase = "A", nodeID = 104943, tree = 2, tier = 2, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 18: Feral Swiftness / Schnelligkeit der Wildnis
        { phase = "A", nodeID = 104944, tree = 2, tier = 3, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 20: Feral Charge / Wilde Attacke
        { phase = "A", nodeID = 104948, tree = 2, tier = 3, column = 2, maxRank = 2, ranks = 2 }, -- Lvl 21: Savage Fury / Ungezähmte Wut
        { phase = "A", nodeID = 104946, tree = 2, tier = 3, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 23: Sharpened Claws / Geschärfte Klauen
        { phase = "A", nodeID = 104951, tree = 2, tier = 4, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 25: Predatory Discipline / Disziplin des Raubtiers
        { phase = "A", nodeID = 104947, tree = 2, tier = 4, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 26: Blood Frenzy / Blutraserei
        { phase = "A", nodeID = 104949, tree = 2, tier = 4, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 28: Lacerate / Aufschlitzen
        { phase = "A", nodeID = 104952, tree = 2, tier = 4, column = 1, maxRank = 3, ranks = 1 }, -- Lvl 29: Predatory Strikes / Raubtierschläge
        { phase = "A", nodeID = 104955, tree = 2, tier = 5, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 30: Leader of the Pack / Rudelführer
        { phase = "A", nodeID = 104950, tree = 2, tier = 5, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 31: Natural Instinct / Instinkt der Natur
        { phase = "A", nodeID = 104952, tree = 2, tier = 4, column = 1, maxRank = 3, ranks = 2 }, -- Lvl 33: Predatory Strikes / Raubtierschläge
        { phase = "A", nodeID = 104953, tree = 2, tier = 6, column = 1, maxRank = 5, ranks = 5 }, -- Lvl 35: Rend and Tear / Beißen und Reißen
        { phase = "A", nodeID = 104956, tree = 2, tier = 7, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 40: Primal Bite / Urtümlicher Biss
        { phase = "A", nodeID = 113563, tree = 2, tier = 7, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 41: Shifting Power / Machtverschiebung
        { phase = "B", nodeID = 104958, tree = 3, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 42: Heart of the Wild / Herz der Wildnis
        { phase = "B", nodeID = 104922, tree = 3, tier = 2, column = 1, maxRank = 5, ranks = 5 }, -- Lvl 47: Naturalist / Naturalist
        { phase = "C", nodeID = 104924, tree = 1, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 52: Genesis / Genesis
        { phase = "C", nodeID = 104929, tree = 1, tier = 2, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 57: Nature's Reach / Reichweite der Natur
        { phase = "C", nodeID = 104927, tree = 1, tier = 2, column = 3, maxRank = 2, ranks = 2 }, -- Lvl 59: Nature's Majesty / Erhabenheit der Natur
    },
    notes = {},
})

-- ------------------------------------------------------------
-- DRUIDE – Wilder Kampf, Bär/Tank (Leveling, "Open World Feral Reflection")
-- QUELLE: Wowhead:
--   https://www.wowhead.com/forever/guide/classes/druid/feral/tank-leveling-tips#open-world-feral-reflection
-- Reihenfolge laut Spieler (Liste + Grafik, 0/34/17).
-- nodeID/Reihe/Spalte/maxRank aus dem Druiden-Talentdump (2026-11-12).
-- Englisch -> Deutsch über die Position im Baum zugeordnet (Wowhead-Grafik).
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "DRUID_FERAL_TANK_LEVELING",
    class     = "DRUID",
    spec      = "FERAL",
    buildType = "LEVELING",
    variant   = "BEAR",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/druid/feral/tank-leveling-tips#open-world-feral-reflection",
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Wilder Kampf – Bär (Tank-Leveling-Build)", enUS = "Feral – Bear (tank leveling build)" },
    menu  = { deDE = "Bär (Tank) – Leveling", enUS = "Bear (tank) – leveling" },
    summary = {
        deDE = "Wowheads Tank-Leveling-Empfehlung für Wilder Kampf: Bär und Katze, dann Wiederherstellung für Reflexion und Rasche Heilung.",
        enUS = "Wowhead's tank leveling pick for Feral: bear and cat, then Restoration for Reflection and Swiftmend.",
    },
    distribution = { 0, 34, 17 },
    phases = {
        A = { deDE = "Phase A – Wilder Kampf", enUS = "Phase A – Feral Combat" },
        B = { deDE = "Phase B – Wiederherstellung", enUS = "Phase B – Restoration" },
        C = { deDE = "Phase C – restlicher Wilder Kampf", enUS = "Phase C – remaining Feral Combat" },
    },
    steps = {
        { phase = "A", nodeID = 104938, tree = 2, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 10: Ferocity / Wildheit
        { phase = "A", nodeID = 104939, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 3 }, -- Lvl 15: Furor / Ingrimm
        { phase = "A", nodeID = 104943, tree = 2, tier = 2, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 18: Feral Swiftness / Schnelligkeit der Wildnis
        { phase = "A", nodeID = 104944, tree = 2, tier = 3, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 20: Feral Charge / Wilde Attacke
        { phase = "A", nodeID = 104948, tree = 2, tier = 3, column = 2, maxRank = 2, ranks = 2 }, -- Lvl 21: Savage Fury / Ungezähmte Wut
        { phase = "A", nodeID = 104946, tree = 2, tier = 3, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 23: Sharpened Claws / Geschärfte Klauen
        { phase = "A", nodeID = 104949, tree = 2, tier = 4, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 25: Lacerate / Aufschlitzen
        { phase = "A", nodeID = 104951, tree = 2, tier = 4, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 26: Predatory Discipline / Disziplin des Raubtiers
        { phase = "A", nodeID = 104952, tree = 2, tier = 4, column = 1, maxRank = 3, ranks = 3 }, -- Lvl 27: Predatory Strikes / Raubtierschläge
        { phase = "A", nodeID = 104955, tree = 2, tier = 5, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 30: Leader of the Pack / Rudelführer
        { phase = "A", nodeID = 104950, tree = 2, tier = 5, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 31: Natural Instinct / Instinkt der Natur
        { phase = "A", nodeID = 104947, tree = 2, tier = 4, column = 4, maxRank = 2, ranks = 1 }, -- Lvl 33: Blood Frenzy / Blutraserei
        { phase = "A", nodeID = 104939, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 1 }, -- Lvl 34: Furor / Ingrimm
        { phase = "A", nodeID = 104953, tree = 2, tier = 6, column = 1, maxRank = 5, ranks = 4 }, -- Lvl 35: Rend and Tear / Beißen und Reißen
        { phase = "A", nodeID = 104939, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 1 }, -- Lvl 39: Furor / Ingrimm
        { phase = "A", nodeID = 104956, tree = 2, tier = 7, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 40: Primal Bite / Urtümlicher Biss
        { phase = "A", nodeID = 113563, tree = 2, tier = 7, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 41: Shifting Power / Machtverschiebung
        { phase = "B", nodeID = 104958, tree = 3, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 42: Heart of the Wild / Herz der Wildnis
        { phase = "B", nodeID = 104922, tree = 3, tier = 2, column = 1, maxRank = 5, ranks = 5 }, -- Lvl 47: Naturalist / Naturalist
        { phase = "B", nodeID = 104919, tree = 3, tier = 2, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 52: Natural Shapeshifter / Schnellwandlung
        { phase = "B", nodeID = 104920, tree = 3, tier = 2, column = 2, maxRank = 3, ranks = 3 }, -- Lvl 55: Reflection / Reflexion
        { phase = "B", nodeID = 104912, tree = 3, tier = 4, column = 4, maxRank = 1, ranks = 1 }, -- Lvl 58: Swiftmend / Rasche Heilung
        { phase = "C", nodeID = 104953, tree = 2, tier = 6, column = 1, maxRank = 5, ranks = 1 }, -- Lvl 59: Rend and Tear / Beißen und Reißen
        { phase = "C", nodeID = 104947, tree = 2, tier = 4, column = 4, maxRank = 2, ranks = 1 }, -- Lvl 60: Blood Frenzy / Blutraserei
    },
    notes = {},
})

-- ------------------------------------------------------------
-- DRUIDE – Gleichgewicht (Leveling)
-- QUELLE: Wowhead:
--   https://www.wowhead.com/forever/guide/classes/druid/balance/dps-leveling-tips
-- Reihenfolge laut Spieler (Liste + Grafik, 38/0/13).
-- nodeID/Reihe/Spalte/maxRank aus dem Druiden-Talentdump (2026-11-12).
-- Englisch -> Deutsch über die Position im Baum zugeordnet (Wowhead-Grafik).
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "DRUID_BALANCE_LEVELING",
    class     = "DRUID",
    spec      = "BALANCE",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/druid/balance/dps-leveling-tips",
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Gleichgewicht (Leveling-Build)", enUS = "Balance (leveling build)" },
    menu  = { deDE = "Gleichgewicht – Leveling", enUS = "Balance – leveling" },
    summary = {
        deDE = "Wowheads Leveling-Empfehlung für Gleichgewicht: Zauberschaden bis Moonkingestalt, dann Mana aus Wiederherstellung.",
        enUS = "Wowhead's leveling pick for Balance: spell damage up to Moonkin Form, then mana from Restoration.",
    },
    distribution = { 38, 0, 13 },
    phases = {
        A = { deDE = "Phase A – Gleichgewicht", enUS = "Phase A – Balance" },
        B = { deDE = "Phase B – Wiederherstellung (Mana)", enUS = "Phase B – Restoration (mana)" },
        C = { deDE = "Phase C – restliches Gleichgewicht", enUS = "Phase C – remaining Balance" },
    },
    steps = {
        { phase = "A", nodeID = 104923, tree = 1, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 10: Improved Wrath / Verbesserter Zorn
        { phase = "A", nodeID = 104925, tree = 1, tier = 2, column = 1, maxRank = 3, ranks = 3 }, -- Lvl 15: Moonglow / Mondschein
        { phase = "A", nodeID = 104927, tree = 1, tier = 2, column = 3, maxRank = 2, ranks = 2 }, -- Lvl 18: Nature's Majesty / Erhabenheit der Natur
        { phase = "A", nodeID = 104929, tree = 1, tier = 2, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 20: Nature's Reach / Reichweite der Natur
        { phase = "A", nodeID = 104931, tree = 1, tier = 2, column = 2, maxRank = 2, ranks = 2 }, -- Lvl 22: Improved Moonfire / Verbessertes Mondfeuer
        { phase = "A", nodeID = 104928, tree = 1, tier = 3, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 24: Nature's Splendor / Pracht der Natur
        { phase = "A", nodeID = 104930, tree = 1, tier = 4, column = 1, maxRank = 1, ranks = 1 }, -- Lvl 25: Insect Swarm / Insektenschwarm
        { phase = "A", nodeID = 104933, tree = 1, tier = 4, column = 3, maxRank = 5, ranks = 4 }, -- Lvl 26: Improved Starfire / Verbessertes Sternenfeuer
        { phase = "A", nodeID = 104935, tree = 1, tier = 5, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 30: Eclipse / Finsternis
        { phase = "A", nodeID = 104933, tree = 1, tier = 4, column = 3, maxRank = 5, ranks = 1 }, -- Lvl 33: Improved Starfire / Verbessertes Sternenfeuer
        { phase = "A", nodeID = 104934, tree = 1, tier = 5, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 34: Nature's Grace / Anmut der Natur
        { phase = "A", nodeID = 104936, tree = 1, tier = 6, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 35: Moonfury / Mondfuror
        { phase = "A", nodeID = 104937, tree = 1, tier = 7, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 40: Moonkin Form / Moonkingestalt
        { phase = "B", nodeID = 104957, tree = 3, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 41: Nature's Focus / Naturfokus
        { phase = "B", nodeID = 104920, tree = 3, tier = 2, column = 2, maxRank = 3, ranks = 3 }, -- Lvl 46: Reflection / Reflexion
        { phase = "B", nodeID = 104922, tree = 3, tier = 2, column = 1, maxRank = 5, ranks = 5 }, -- Lvl 49: Naturalist / Naturalist
        { phase = "C", nodeID = 104924, tree = 1, tier = 1, column = 3, maxRank = 5, ranks = 2 }, -- Lvl 54: Genesis / Genesis
        { phase = "C", nodeID = 104932, tree = 1, tier = 4, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 56: Vengeance / Rache
    },
    notes = {},
})

-- ------------------------------------------------------------
-- DRUIDE – Wiederherstellung, Heiler (Leveling)
-- QUELLE: Wowhead:
--   https://www.wowhead.com/forever/guide/classes/druid/restoration/healer-leveling-tips
-- Reihenfolge laut Spieler (Liste + Grafik, 23/0/28).
-- nodeID/Reihe/Spalte/maxRank aus dem Druiden-Talentdump (2026-11-12).
-- Englisch -> Deutsch über die Position im Baum zugeordnet (Wowhead-Grafik).
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "DRUID_RESTORATION_LEVELING",
    class     = "DRUID",
    spec      = "RESTORATION",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/druid/restoration/healer-leveling-tips",
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Wiederherstellung – Heiler (Leveling-Build)", enUS = "Restoration – healer (leveling build)" },
    menu  = { deDE = "Heal – Leveling", enUS = "Healer – leveling" },
    summary = {
        deDE = "Wowheads Heiler-Leveling-Empfehlung: Zorn und erste Heilertalente, dann Gleichgewicht zum Questen, ab Level 44 Wiederherstellung.",
        enUS = "Wowhead's healer leveling pick: Wrath and first healing talents, then Balance for questing, Restoration from level 44.",
    },
    distribution = { 23, 0, 28 },
    phases = {
        A = { deDE = "Phase A – Zorn & erste Heilertalente", enUS = "Phase A – Wrath & first healing talents" },
        B = { deDE = "Phase B – Gleichgewicht (Questen)", enUS = "Phase B – Balance (questing)" },
        C = { deDE = "Phase C – Wiederherstellung (Heilen)", enUS = "Phase C – Restoration (healing)" },
    },
    steps = {
        { phase = "A", nodeID = 104923, tree = 1, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 10: Improved Wrath / Verbesserter Zorn
        { phase = "A", nodeID = 104957, tree = 3, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 15: Nature's Focus / Naturfokus
        { phase = "A", nodeID = 104920, tree = 3, tier = 2, column = 2, maxRank = 3, ranks = 3 }, -- Lvl 20: Reflection / Reflexion
        { phase = "A", nodeID = 104922, tree = 3, tier = 2, column = 1, maxRank = 5, ranks = 2 }, -- Lvl 23: Naturalist / Naturalist
        { phase = "A", nodeID = 104918, tree = 3, tier = 3, column = 4, maxRank = 1, ranks = 1 }, -- Lvl 25: Bloom / Blüte
        { phase = "B", nodeID = 104927, tree = 1, tier = 2, column = 3, maxRank = 2, ranks = 2 }, -- Lvl 26: Nature's Majesty / Erhabenheit der Natur
        { phase = "B", nodeID = 104924, tree = 1, tier = 1, column = 3, maxRank = 5, ranks = 3 }, -- Lvl 28: Genesis / Genesis
        { phase = "B", nodeID = 104928, tree = 1, tier = 3, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 31: Nature's Splendor / Pracht der Natur
        { phase = "B", nodeID = 104926, tree = 1, tier = 3, column = 1, maxRank = 3, ranks = 3 }, -- Lvl 32: Improved Entangling Roots / Verbesserte Wucherwurzeln
        { phase = "B", nodeID = 104924, tree = 1, tier = 1, column = 3, maxRank = 5, ranks = 1 }, -- Lvl 35: Genesis / Genesis
        { phase = "B", nodeID = 104930, tree = 1, tier = 4, column = 1, maxRank = 1, ranks = 1 }, -- Lvl 36: Insect Swarm / Insektenschwarm
        { phase = "B", nodeID = 104924, tree = 1, tier = 1, column = 3, maxRank = 5, ranks = 1 }, -- Lvl 37: Genesis / Genesis
        { phase = "B", nodeID = 104925, tree = 1, tier = 2, column = 1, maxRank = 3, ranks = 3 }, -- Lvl 38: Moonglow / Mondschein
        { phase = "B", nodeID = 104934, tree = 1, tier = 5, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 41: Nature's Grace / Anmut der Natur
        { phase = "B", nodeID = 110844, tree = 1, tier = 5, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 42: Overgrowth / Wildes Wachstum
        { phase = "C", nodeID = 104916, tree = 3, tier = 3, column = 3, maxRank = 5, ranks = 4 }, -- Lvl 44: Gift of Nature / Geschenk der Natur
        { phase = "C", nodeID = 104912, tree = 3, tier = 4, column = 4, maxRank = 1, ranks = 1 }, -- Lvl 48: Swiftmend / Rasche Heilung
        { phase = "C", nodeID = 104916, tree = 3, tier = 3, column = 3, maxRank = 5, ranks = 1 }, -- Lvl 49: Gift of Nature / Geschenk der Natur
        { phase = "C", nodeID = 104922, tree = 3, tier = 2, column = 1, maxRank = 5, ranks = 3 }, -- Lvl 50: Naturalist / Naturalist
        { phase = "C", nodeID = 104921, tree = 3, tier = 5, column = 1, maxRank = 1, ranks = 1 }, -- Lvl 53: Nature's Swiftness / Schnelligkeit der Natur
        { phase = "C", nodeID = 104914, tree = 3, tier = 4, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 54: Improved Rejuvenation / Verbesserte Verjüngung
        { phase = "C", nodeID = 104911, tree = 3, tier = 5, column = 2, maxRank = 3, ranks = 1 }, -- Lvl 57: Living Spirit / Geist des Lebens
        { phase = "C", nodeID = 104913, tree = 3, tier = 6, column = 3, maxRank = 5, ranks = 3 }, -- Lvl 58: Improved Regrowth / Verbessertes Nachwachsen
    },
    notes = {},
})

-- ------------------------------------------------------------
-- MAGIER – Arkan (Leveling)
-- QUELLE: Wowhead:
--   https://www.wowhead.com/forever/guide/classes/mage/arcane/dps-leveling-tips
-- Reihenfolge laut Spieler (Liste + Grafik, 36/12/3).
-- nodeID/Reihe/Spalte/maxRank aus dem Magier-Talentdump (2026-11-12),
-- Zuordnung über die Position auf der Wowhead-Grafik ("Verbrennung" gibt es zweimal).
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "MAGE_ARCANE_LEVELING",
    class     = "MAGE",
    spec      = "ARCANE",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/mage/arcane/dps-leveling-tips",
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Arkan (Leveling-Build)", enUS = "Arcane (leveling build)" },
    menu  = { deDE = "Arkan – Leveling", enUS = "Arcane – leveling" },
    summary = {
        deDE = "Wowheads Leveling-Empfehlung für Arkan: Arkane Geschosse und Arkanschlag bis Arkane Instabilität, dann Feuer-Grundtalente, zum Schluss Arkane Macht.",
        enUS = "Wowhead's leveling pick for Arcane: Arcane Missiles and Arcane Blast up to Arcane Instability, then basic Fire talents, Arcane Power last.",
    },
    distribution = { 36, 12, 3 },
    phases = {
        A = { deDE = "Phase A – Arkan", enUS = "Phase A – Arcane" },
        B = { deDE = "Phase B – Feuer", enUS = "Phase B – Fire" },
        C = { deDE = "Phase C – Arkane Macht & Rest", enUS = "Phase C – Arcane Power & rest" },
    },
    steps = {
        { phase = "A", nodeID = 105815, tree = 1, tier = 1, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 10: Wand Specialization / Zauberstab-Spezialisierung
        { phase = "A", nodeID = 105778, tree = 3, tier = 1, column = 3, maxRank = 3, ranks = 1 }, -- Lvl 12: Precision / Präzision
        { phase = "A", nodeID = 105813, tree = 1, tier = 1, column = 2, maxRank = 5, ranks = 3 }, -- Lvl 13: Improved Channeling / Verbesserte Kanalisierung
        { phase = "A", nodeID = 105809, tree = 1, tier = 2, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 16: Missile Barrage / Geschosssalve
        { phase = "A", nodeID = 105812, tree = 1, tier = 2, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 18: Arcane Subtlety / Arkanes Feingefühl
        { phase = "A", nodeID = 105813, tree = 1, tier = 1, column = 2, maxRank = 5, ranks = 1 }, -- Lvl 20: Improved Channeling / Verbesserte Kanalisierung
        { phase = "A", nodeID = 105806, tree = 1, tier = 3, column = 4, maxRank = 1, ranks = 1 }, -- Lvl 21: Arcane Blast / Arkanschlag
        { phase = "A", nodeID = 105813, tree = 1, tier = 1, column = 2, maxRank = 5, ranks = 1 }, -- Lvl 22: Improved Channeling / Verbesserte Kanalisierung
        { phase = "A", nodeID = 105810, tree = 1, tier = 2, column = 3, maxRank = 5, ranks = 3 }, -- Lvl 23: Arcane Concentration / Arkane Konzentration
        { phase = "A", nodeID = 113627, tree = 1, tier = 4, column = 4, maxRank = 1, ranks = 1 }, -- Lvl 26: Arcane Wrath / Arkaner Zorn
        { phase = "A", nodeID = 105810, tree = 1, tier = 2, column = 3, maxRank = 5, ranks = 2 }, -- Lvl 27: Arcane Concentration / Arkane Konzentration
        { phase = "A", nodeID = 105803, tree = 1, tier = 4, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 29: Arcane Meditation / Arkane Meditation
        { phase = "A", nodeID = 105778, tree = 3, tier = 1, column = 3, maxRank = 3, ranks = 1 }, -- Lvl 32: Precision / Präzision
        { phase = "A", nodeID = 105800, tree = 1, tier = 5, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 33: Arcane Mind / Arkaner Geist
        { phase = "A", nodeID = 105801, tree = 1, tier = 5, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 38: Presence of Mind / Geistesgegenwart
        { phase = "A", nodeID = 105807, tree = 1, tier = 3, column = 2, maxRank = 3, ranks = 3 }, -- Lvl 39: Arcane Impact / Arkaner Einschlag
        { phase = "A", nodeID = 105799, tree = 1, tier = 6, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 42: Arcane Instability / Arkane Instabilität
        { phase = "B", nodeID = 105795, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 45: Accelerant / Beschleuniger
        { phase = "B", nodeID = 105796, tree = 2, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 50: Incineration / Verbrennung
        { phase = "C", nodeID = 105798, tree = 1, tier = 7, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 55: Arcane Power / Arkane Macht
        { phase = "C", nodeID = 105778, tree = 3, tier = 1, column = 3, maxRank = 3, ranks = 1 }, -- Lvl 56: Precision / Präzision
        { phase = "C", nodeID = 105808, tree = 1, tier = 3, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 57: Arcane Geometry / Arkane Geometrie
        { phase = "C", nodeID = 105797, tree = 2, tier = 3, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 59: Improved Fire Blast / Verbesserter Feuerschlag
    },
    notes = {},
})

-- ------------------------------------------------------------
-- MAGIER – Feuer (Leveling)
-- QUELLE: Wowhead:
--   https://www.wowhead.com/forever/guide/classes/mage/fire/dps-leveling-tips
-- Reihenfolge laut Spieler (Liste + Grafik, 18/31/2).
-- nodeID/Reihe/Spalte/maxRank aus dem Magier-Talentdump (2026-11-12),
-- Zuordnung über die Position auf der Wowhead-Grafik ("Verbrennung" gibt es zweimal).
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "MAGE_FIRE_LEVELING",
    class     = "MAGE",
    spec      = "FIRE",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/mage/fire/dps-leveling-tips",
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Feuer (Leveling-Build)", enUS = "Fire (leveling build)" },
    menu  = { deDE = "Feuer – Leveling", enUS = "Fire – leveling" },
    summary = {
        deDE = "Wowheads Leveling-Empfehlung für Feuer: Feuer-Grundlagen und Pyroschlag, dann Arkan für Mana, danach Feuer bis Verbrennung.",
        enUS = "Wowhead's leveling pick for Fire: Fire basics and Pyroblast, then Arcane for mana, then Fire up to Combustion.",
    },
    distribution = { 18, 31, 2 },
    phases = {
        A = { deDE = "Phase A – Feuer", enUS = "Phase A – Fire" },
        B = { deDE = "Phase B – Arkan (Kanalisierung & Salve)", enUS = "Phase B – Arcane (channeling & barrage)" },
        C = { deDE = "Phase C – Feuer bis Verbrennung", enUS = "Phase C – Fire up to Combustion" },
        D = { deDE = "Phase D – Arkan & Präzision", enUS = "Phase D – Arcane & Precision" },
    },
    steps = {
        { phase = "A", nodeID = 105795, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 10: Accelerant / Beschleuniger
        { phase = "A", nodeID = 105778, tree = 3, tier = 1, column = 3, maxRank = 3, ranks = 1 }, -- Lvl 15: Precision / Präzision
        { phase = "A", nodeID = 105796, tree = 2, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 16: Incineration / Verbrennung
        { phase = "A", nodeID = 105790, tree = 2, tier = 3, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 21: Pyroblast / Pyroschlag
        { phase = "A", nodeID = 105797, tree = 2, tier = 3, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 22: Improved Fire Blast / Verbesserter Feuerschlag
        { phase = "A", nodeID = 105794, tree = 2, tier = 2, column = 1, maxRank = 5, ranks = 2 }, -- Lvl 24: Ignite / Entzünden
        { phase = "A", nodeID = 105786, tree = 2, tier = 4, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 26: Heating Up / Aufwärmen
        { phase = "A", nodeID = 105794, tree = 2, tier = 2, column = 1, maxRank = 5, ranks = 3 }, -- Lvl 27: Ignite / Entzünden
        { phase = "B", nodeID = 105813, tree = 1, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 30: Improved Channeling / Verbesserte Kanalisierung
        { phase = "B", nodeID = 105809, tree = 1, tier = 2, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 35: Missile Barrage / Geschosssalve
        { phase = "B", nodeID = 105812, tree = 1, tier = 2, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 37: Arcane Subtlety / Arkanes Feingefühl
        { phase = "C", nodeID = 105793, tree = 2, tier = 2, column = 2, maxRank = 2, ranks = 2 }, -- Lvl 39: Flame Throwing / Flammenwerfen
        { phase = "C", nodeID = 105784, tree = 2, tier = 5, column = 2, maxRank = 3, ranks = 3 }, -- Lvl 41: Critical Mass / Kritische Masse
        { phase = "C", nodeID = 105789, tree = 2, tier = 3, column = 1, maxRank = 3, ranks = 1 }, -- Lvl 44: Burning Soul / Brennende Seele
        { phase = "C", nodeID = 105782, tree = 2, tier = 6, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 45: Fire Power / Feuermacht
        { phase = "C", nodeID = 105789, tree = 2, tier = 3, column = 1, maxRank = 3, ranks = 2 }, -- Lvl 48: Burning Soul / Brennende Seele
        { phase = "C", nodeID = 105781, tree = 2, tier = 7, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 50: Combustion / Verbrennung
        { phase = "D", nodeID = 105778, tree = 3, tier = 1, column = 3, maxRank = 3, ranks = 1 }, -- Lvl 51: Precision / Präzision
        { phase = "D", nodeID = 105810, tree = 1, tier = 2, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 52: Arcane Concentration / Arkane Konzentration
        { phase = "D", nodeID = 105806, tree = 1, tier = 3, column = 4, maxRank = 1, ranks = 1 }, -- Lvl 57: Arcane Blast / Arkanschlag
        { phase = "D", nodeID = 105803, tree = 1, tier = 4, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 58: Arcane Meditation / Arkane Meditation
    },
    notes = {},
})

-- ------------------------------------------------------------
-- MAGIER – Frost (Leveling)
-- QUELLE: Wowhead:
--   https://www.wowhead.com/forever/guide/classes/mage/frost/dps-leveling-tips
-- Reihenfolge laut Spieler (Liste + Grafik, 7/0/44).
-- nodeID/Reihe/Spalte/maxRank aus dem Magier-Talentdump (2026-11-12),
-- Zuordnung über die Position auf der Wowhead-Grafik ("Verbrennung" gibt es zweimal).
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "MAGE_FROST_LEVELING",
    class     = "MAGE",
    spec      = "FROST",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/mage/frost/dps-leveling-tips",
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Frost (Leveling-Build)", enUS = "Frost (leveling build)" },
    menu  = { deDE = "Frost – Leveling", enUS = "Frost – leveling" },
    summary = {
        deDE = "Wowheads Leveling-Empfehlung für Frost: Frostblitz, Eislanze und Zertrümmern bis Eisbarriere, zum Schluss etwas Arkan.",
        enUS = "Wowhead's leveling pick for Frost: Frostbolt, Ice Lance and Shatter up to Ice Barrier, a little Arcane last.",
    },
    distribution = { 7, 0, 44 },
    phases = {
        A = { deDE = "Phase A – Frost", enUS = "Phase A – Frost" },
        B = { deDE = "Phase B – Arkan", enUS = "Phase B – Arcane" },
    },
    steps = {
        { phase = "A", nodeID = 105815, tree = 1, tier = 1, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 10: Wand Specialization / Zauberstab-Spezialisierung
        { phase = "A", nodeID = 105779, tree = 3, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 12: Improved Frostbolt / Verbesserter Frostblitz
        { phase = "A", nodeID = 105774, tree = 3, tier = 2, column = 2, maxRank = 3, ranks = 3 }, -- Lvl 17: Frostbite / Erfrierung
        { phase = "A", nodeID = 105778, tree = 3, tier = 1, column = 3, maxRank = 3, ranks = 2 }, -- Lvl 20: Precision / Präzision
        { phase = "A", nodeID = 105767, tree = 3, tier = 3, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 22: Ice Lance / Eislanze
        { phase = "A", nodeID = 105771, tree = 3, tier = 3, column = 2, maxRank = 3, ranks = 1 }, -- Lvl 23: Improved Blizzard / Verbesserter Blizzard
        { phase = "A", nodeID = 105777, tree = 3, tier = 2, column = 1, maxRank = 5, ranks = 3 }, -- Lvl 24: Ice Shards / Eissplitter
        { phase = "A", nodeID = 105768, tree = 3, tier = 4, column = 4, maxRank = 3, ranks = 3 }, -- Lvl 27: Shatter / Zertrümmern
        { phase = "A", nodeID = 105777, tree = 3, tier = 2, column = 1, maxRank = 5, ranks = 2 }, -- Lvl 30: Ice Shards / Eissplitter
        { phase = "A", nodeID = 105764, tree = 3, tier = 5, column = 3, maxRank = 2, ranks = 2 }, -- Lvl 32: Fingers of Frost / Eisige Finger
        { phase = "A", nodeID = 105766, tree = 3, tier = 5, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 34: Cold Snap / Kälteeinbruch
        { phase = "A", nodeID = 105765, tree = 3, tier = 5, column = 1, maxRank = 3, ranks = 2 }, -- Lvl 35: Improved Cone of Cold / Verbesserter Kältekegel
        { phase = "A", nodeID = 105763, tree = 3, tier = 6, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 37: Winter's Chill / Winterkälte
        { phase = "A", nodeID = 105762, tree = 3, tier = 7, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 42: Ice Barrier / Eisbarriere
        { phase = "A", nodeID = 105769, tree = 3, tier = 4, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 43: Ice Block / Eisblock
        { phase = "A", nodeID = 105765, tree = 3, tier = 5, column = 1, maxRank = 3, ranks = 1 }, -- Lvl 44: Improved Cone of Cold / Verbesserter Kältekegel
        { phase = "A", nodeID = 105778, tree = 3, tier = 1, column = 3, maxRank = 3, ranks = 1 }, -- Lvl 45: Precision / Präzision
        { phase = "A", nodeID = 105771, tree = 3, tier = 3, column = 2, maxRank = 3, ranks = 2 }, -- Lvl 46: Improved Blizzard / Verbesserter Blizzard
        { phase = "A", nodeID = 105772, tree = 3, tier = 3, column = 1, maxRank = 3, ranks = 3 }, -- Lvl 48: Frost Channeling / Frost-Kanalisierung
        { phase = "A", nodeID = 105776, tree = 3, tier = 2, column = 4, maxRank = 3, ranks = 3 }, -- Lvl 51: Permafrost / Dauerfrost
        { phase = "A", nodeID = 105770, tree = 3, tier = 4, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 54: Arctic Reach / Arktische Reichweite
        { phase = "B", nodeID = 105802, tree = 1, tier = 1, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 56: Arcane Resilience / Arkane Widerstandsfähigkeit
        { phase = "B", nodeID = 105812, tree = 1, tier = 2, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 59: Arcane Subtlety / Arkanes Feingefühl
    },
    notes = {},
})

-- ------------------------------------------------------------
-- PALADIN – Vergeltung (Leveling)
-- QUELLE: Wowhead
--   https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-leveling-tips
-- Reihenfolge laut Spieler (Liste + Grafik, 14/6/31).
-- nodeID/Reihe/Spalte/maxRank aus dem Paladin-Talentdump (2026-11-12),
-- Zuordnung über die Position auf der Wowhead-Grafik.
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "PALADIN_RETRIBUTION_LEVELING",
    class     = "PALADIN",
    spec      = "RETRIBUTION",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-leveling-tips",
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Vergeltung (Leveling-Build)", enUS = "Retribution (leveling build)" },
    menu  = { deDE = "Vergeltung – Leveling", enUS = "Retribution – leveling" },
    summary = {
        deDE = "Wowheads Leveling-Empfehlung für Vergeltung: Zweihand-Nahkampf bis Entfesselter Zorn, danach Stärke, Siegel und Mana.",
        enUS = "Wowhead's leveling pick for Retribution: two-handed melee up to Unsealed Wrath, then strength, seals and mana.",
    },
    distribution = { 14, 6, 31 },
    phases = {
        A = { deDE = "Phase A – Vergeltung", enUS = "Phase A – Retribution" },
        B = { deDE = "Phase B – Heilig & Schutz (Stärke, Siegel, Mana)", enUS = "Phase B – Holy & Protection (strength, seals, mana)" },
    },
    steps = {
        { phase = "A", nodeID = 105706, tree = 3, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 10: Benediction / Segnung
        { phase = "A", nodeID = 105705, tree = 3, tier = 2, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 15: Improved Judgement / Verbessertes Richturteil
        { phase = "A", nodeID = 105701, tree = 3, tier = 2, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 17: Sanctified Judgement / Gesegnetes Richturteil
        { phase = "A", nodeID = 105696, tree = 3, tier = 3, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 20: Seal of Command / Siegel des Befehls
        { phase = "A", nodeID = 105699, tree = 3, tier = 3, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 21: Pursuit of Justice / Streben nach Gerechtigkeit
        { phase = "A", nodeID = 105703, tree = 3, tier = 2, column = 2, maxRank = 3, ranks = 2 }, -- Lvl 23: Conviction / Überzeugung
        { phase = "A", nodeID = 105700, tree = 3, tier = 4, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 25: Sacred Arbiter / Heiliger Richter
        { phase = "A", nodeID = 105697, tree = 3, tier = 4, column = 4, maxRank = 3, ranks = 3 }, -- Lvl 26: Two-Handed Weapon Specialization / Zweihandwaffen-Spezialisierung
        { phase = "A", nodeID = 105703, tree = 3, tier = 2, column = 2, maxRank = 3, ranks = 1 }, -- Lvl 29: Conviction / Überzeugung
        { phase = "A", nodeID = 105693, tree = 3, tier = 5, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 30: Vengeance / Rache
        { phase = "A", nodeID = 105694, tree = 3, tier = 5, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 33: Repentance / Buße
        { phase = "A", nodeID = 105331, tree = 3, tier = 3, column = 2, maxRank = 2, ranks = 1 }, -- Lvl 34: Unyielding Faith / Unumstößlicher Glaube
        { phase = "A", nodeID = 110882, tree = 3, tier = 6, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 35: Champion of the Light / Champion des Lichts
        { phase = "A", nodeID = 105692, tree = 3, tier = 7, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 40: Unsealed Wrath / Entfesselter Zorn
        { phase = "B", nodeID = 113630, tree = 1, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 41: Divine Strength / Göttliche Stärke
        { phase = "B", nodeID = 105334, tree = 1, tier = 2, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 46: Improved Seals / Verbesserte Siegel
        { phase = "B", nodeID = 105332, tree = 2, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 51: Divine Intellect / Göttliche Weisheit
        { phase = "B", nodeID = 105638, tree = 2, tier = 2, column = 1, maxRank = 3, ranks = 1 }, -- Lvl 56: Precision / Präzision
        { phase = "B", nodeID = 105704, tree = 1, tier = 3, column = 3, maxRank = 2, ranks = 2 }, -- Lvl 57: Holy Conduit / Heiliges Medium
        { phase = "B", nodeID = 110871, tree = 1, tier = 2, column = 2, maxRank = 2, ranks = 2 }, -- Lvl 59: Reverence / Andacht
    },
    notes = {},
})

-- ------------------------------------------------------------
-- PALADIN – Schutz, Tank (Leveling)
-- QUELLE: Wowhead
--   https://www.wowhead.com/forever/guide/classes/paladin/protection/tank-leveling-tips
-- Reihenfolge laut Spieler (Liste + Grafik, 0/32/19).
-- nodeID/Reihe/Spalte/maxRank aus dem Paladin-Talentdump (2026-11-12),
-- Zuordnung über die Position auf der Wowhead-Grafik.
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "PALADIN_PROTECTION_TANK_LEVELING",
    class     = "PALADIN",
    spec      = "PROTECTION",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/paladin/protection/tank-leveling-tips",
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Schutz – Tank (Leveling-Build)", enUS = "Protection – tank (leveling build)" },
    menu  = { deDE = "Schutz (Tank) – Leveling", enUS = "Protection (tank) – leveling" },
    summary = {
        deDE = "Wowheads Tank-Leveling-Empfehlung für Schutz: erst Vergeltungs-Grundlagen, dann Schutz bis Schildgeschworen.",
        enUS = "Wowhead's tank leveling pick for Protection: Retribution basics first, then Protection up to Shieldsworn.",
    },
    distribution = { 0, 32, 19 },
    phases = {
        A = { deDE = "Phase A – Vergeltung (Grundlage)", enUS = "Phase A – Retribution (basics)" },
        B = { deDE = "Phase B – Schutz", enUS = "Phase B – Protection" },
        C = { deDE = "Phase C – restliche Punkte", enUS = "Phase C – remaining points" },
    },
    steps = {
        { phase = "A", nodeID = 105706, tree = 3, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 10: Benediction / Segnung
        { phase = "A", nodeID = 105701, tree = 3, tier = 2, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 15: Sanctified Judgement / Gesegnetes Richturteil
        { phase = "A", nodeID = 105703, tree = 3, tier = 2, column = 2, maxRank = 3, ranks = 2 }, -- Lvl 18: Conviction / Überzeugung
        { phase = "A", nodeID = 105699, tree = 3, tier = 3, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 20: Pursuit of Justice / Streben nach Gerechtigkeit
        { phase = "B", nodeID = 105626, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 22: Redoubt / Verschanzen
        { phase = "B", nodeID = 105638, tree = 2, tier = 2, column = 1, maxRank = 3, ranks = 3 }, -- Lvl 27: Precision / Präzision
        { phase = "B", nodeID = 105637, tree = 2, tier = 2, column = 2, maxRank = 2, ranks = 2 }, -- Lvl 30: Guardian's Favor / Gunst des Hüters
        { phase = "B", nodeID = 105625, tree = 2, tier = 3, column = 1, maxRank = 1, ranks = 1 }, -- Lvl 32: Templar's Bulwark / Bollwerk des Templers
        { phase = "B", nodeID = 110874, tree = 2, tier = 3, column = 3, maxRank = 2, ranks = 2 }, -- Lvl 33: Shield Specialization / Schild-Spezialisierung
        { phase = "B", nodeID = 105630, tree = 2, tier = 3, column = 4, maxRank = 5, ranks = 2 }, -- Lvl 35: Toughness / Zähigkeit
        { phase = "B", nodeID = 110878, tree = 2, tier = 4, column = 1, maxRank = 1, ranks = 1 }, -- Lvl 37: Swift Judgement / Schnelles Richturteil
        { phase = "B", nodeID = 105634, tree = 2, tier = 4, column = 2, maxRank = 3, ranks = 3 }, -- Lvl 38: Improved Righteous Fury / Verbesserter Zorn der Gerechtigkeit
        { phase = "B", nodeID = 105630, tree = 2, tier = 3, column = 4, maxRank = 5, ranks = 1 }, -- Lvl 41: Toughness / Zähigkeit
        { phase = "B", nodeID = 105628, tree = 2, tier = 5, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 42: Holy Shield / Heiliger Schild
        { phase = "B", nodeID = 105627, tree = 2, tier = 5, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 43: Reckoning / Abrechnung
        { phase = "B", nodeID = 110879, tree = 2, tier = 6, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 48: Iron Creed / Eiserner Glaube
        { phase = "B", nodeID = 105632, tree = 2, tier = 2, column = 4, maxRank = 2, ranks = 1 }, -- Lvl 51: Sacred Duty / Heilige Pflicht
        { phase = "B", nodeID = 110875, tree = 2, tier = 7, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 52: Shieldsworn / Schildgeschworen
        { phase = "C", nodeID = 105705, tree = 3, tier = 2, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 53: Improved Judgement / Verbessertes Richturteil
        { phase = "C", nodeID = 105702, tree = 3, tier = 3, column = 1, maxRank = 3, ranks = 1 }, -- Lvl 55: Vindication / Rechtschaffene Schwächung
        { phase = "C", nodeID = 105700, tree = 3, tier = 4, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 56: Sacred Arbiter / Heiliger Richter
        { phase = "C", nodeID = 105702, tree = 3, tier = 3, column = 1, maxRank = 3, ranks = 2 }, -- Lvl 57: Vindication / Rechtschaffene Schwächung
        { phase = "C", nodeID = 105703, tree = 3, tier = 2, column = 2, maxRank = 3, ranks = 1 }, -- Lvl 59: Conviction / Überzeugung
        { phase = "C", nodeID = 105632, tree = 2, tier = 2, column = 4, maxRank = 2, ranks = 1 }, -- Lvl 60: Sacred Duty / Heilige Pflicht
    },
    notes = {},
})

-- ------------------------------------------------------------
-- PALADIN – Heilig, Heiler (Leveling)
-- QUELLE: Wowhead
-- Link zum Guide fehlt noch (Spieler schickt ihn nach).
-- Die Liste des Spielers begann erst bei Level 15. Level 10–14 = Göttliche
-- Weisheit 5/5: das einzige Talent auf der Grafik, das in der Liste fehlt
-- (Schutz Reihe 1, 5/5), und genau 5 fehlende Punkte.
-- Reihenfolge laut Spieler (Liste + Grafik, 34/5/12).
-- nodeID/Reihe/Spalte/maxRank aus dem Paladin-Talentdump (2026-11-12),
-- Zuordnung über die Position auf der Wowhead-Grafik.
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "PALADIN_HOLY_LEVELING",
    class     = "PALADIN",
    spec      = "HOLY",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = nil,      -- Link folgt
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Heilig – Heiler (Leveling-Build)", enUS = "Holy – healer (leveling build)" },
    menu  = { deDE = "Heal – Leveling", enUS = "Healer – leveling" },
    summary = {
        deDE = "Wowheads Heiler-Leveling-Empfehlung: Mana und Heilfokus, dann Vergeltung zum Questen, ab Level 34 Heilig bis Lichtwacht.",
        enUS = "Wowhead's healer leveling pick: mana and healing focus, then Retribution for questing, Holy up to Light's Vigil from level 34.",
    },
    distribution = { 34, 5, 12 },
    phases = {
        A = { deDE = "Phase A – Grundlage (Weisheit, Fokus, Andacht)", enUS = "Phase A – basics (wisdom, focus, reverence)" },
        B = { deDE = "Phase B – Vergeltung (Questen)", enUS = "Phase B – Retribution (questing)" },
        C = { deDE = "Phase C – Heilig (Heilen)", enUS = "Phase C – Holy (healing)" },
    },
    steps = {
        { phase = "A", nodeID = 105332, tree = 2, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 10: Divine Intellect / Göttliche Weisheit
        { phase = "A", nodeID = 105335, tree = 1, tier = 1, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 15: Spiritual Focus / Spiritueller Fokus
        { phase = "A", nodeID = 110871, tree = 1, tier = 2, column = 2, maxRank = 2, ranks = 2 }, -- Lvl 20: Reverence / Andacht
        { phase = "B", nodeID = 105706, tree = 3, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 22: Benediction / Segnung
        { phase = "B", nodeID = 105705, tree = 3, tier = 2, column = 1, maxRank = 2, ranks = 2 }, -- Lvl 27: Improved Judgement / Verbessertes Richturteil
        { phase = "B", nodeID = 105703, tree = 3, tier = 2, column = 2, maxRank = 3, ranks = 3 }, -- Lvl 29: Conviction / Überzeugung
        { phase = "B", nodeID = 105699, tree = 3, tier = 3, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 32: Pursuit of Justice / Streben nach Gerechtigkeit
        { phase = "C", nodeID = 105333, tree = 1, tier = 2, column = 1, maxRank = 3, ranks = 3 }, -- Lvl 34: Healing Light / Heilendes Licht
        { phase = "C", nodeID = 105329, tree = 1, tier = 3, column = 2, maxRank = 5, ranks = 5 }, -- Lvl 37: Illumination / Illumination
        { phase = "C", nodeID = 105325, tree = 1, tier = 3, column = 1, maxRank = 1, ranks = 1 }, -- Lvl 42: Divine Favor / Göttliche Gunst
        { phase = "C", nodeID = 110873, tree = 1, tier = 4, column = 2, maxRank = 2, ranks = 2 }, -- Lvl 43: Infusion of Light / Lichtinfusion
        { phase = "C", nodeID = 105330, tree = 1, tier = 4, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 45: Oath of Light / Eid des Lichts
        { phase = "C", nodeID = 105324, tree = 1, tier = 4, column = 1, maxRank = 2, ranks = 1 }, -- Lvl 46: Divine Precision / Göttliche Präzision
        { phase = "C", nodeID = 105323, tree = 1, tier = 5, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 47: Holy Shock / Heiliger Schock
        { phase = "C", nodeID = 113631, tree = 1, tier = 5, column = 3, maxRank = 2, ranks = 2 }, -- Lvl 48: Boundless Light / Grenzenloses Licht
        { phase = "C", nodeID = 105324, tree = 1, tier = 4, column = 1, maxRank = 2, ranks = 1 }, -- Lvl 50: Divine Precision / Göttliche Präzision
        { phase = "C", nodeID = 110872, tree = 1, tier = 5, column = 1, maxRank = 2, ranks = 1 }, -- Lvl 51: Consecrated Ground / Geweihter Boden
        { phase = "C", nodeID = 105321, tree = 1, tier = 6, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 52: Holy Power / Heilige Kraft
        { phase = "C", nodeID = 105320, tree = 1, tier = 7, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 57: Light's Vigil / Lichtwacht
        { phase = "C", nodeID = 110872, tree = 1, tier = 5, column = 1, maxRank = 2, ranks = 1 }, -- Lvl 58: Consecrated Ground / Geweihter Boden
        { phase = "C", nodeID = 105704, tree = 1, tier = 3, column = 3, maxRank = 2, ranks = 2 }, -- Lvl 59: Holy Conduit / Heiliges Medium
    },
    notes = {},
})

-- ------------------------------------------------------------
-- PRIESTER – Schatten (Leveling)
-- QUELLE: Wowhead
--   https://www.wowhead.com/forever/guide/classes/priest/shadow/dps-leveling-tips
-- Reihenfolge laut Spieler (Liste + Grafik, 16/3/32).
-- nodeID/Reihe/Spalte/maxRank aus dem Priester-Talentdump (2026-11-12),
-- Zuordnung über die Position auf der Wowhead-Grafik.
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "PRIEST_SHADOW_LEVELING",
    class     = "PRIEST",
    spec      = "SHADOW",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/priest/shadow/dps-leveling-tips",
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Schatten (Leveling-Build)", enUS = "Shadow (leveling build)" },
    menu  = { deDE = "Schatten – Leveling", enUS = "Shadow – leveling" },
    summary = {
        deDE = "Wowheads Leveling-Empfehlung für Schatten: Willensentzug und Gedankenschinden bis Schattengestalt, danach Mana und Haltbarkeit aus Disziplin.",
        enUS = "Wowhead's leveling pick for Shadow: Spirit Tap and Mind Flay up to Shadowform, then mana and durability from Discipline.",
    },
    distribution = { 16, 3, 32 },
    phases = {
        A = { deDE = "Phase A – Schatten", enUS = "Phase A – Shadow" },
        B = { deDE = "Phase B – Disziplin & Rest (Mana)", enUS = "Phase B – Discipline & rest (mana)" },
    },
    steps = {
        { phase = "A", nodeID = 105850, tree = 1, tier = 1, column = 2, maxRank = 2, ranks = 2 }, -- Lvl 10: Wand Specialization / Zauberstab-Spezialisierung
        { phase = "A", nodeID = 105833, tree = 3, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 12: Spirit Tap / Willensentzug
        { phase = "A", nodeID = 105830, tree = 3, tier = 2, column = 3, maxRank = 2, ranks = 2 }, -- Lvl 17: Improved Shadow Word: Pain / Verbessertes Schattenwort: Schmerz
        { phase = "A", nodeID = 105829, tree = 3, tier = 2, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 19: Shadow Reach / Schattenreichweite
        { phase = "A", nodeID = 110851, tree = 3, tier = 1, column = 1, maxRank = 5, ranks = 1 }, -- Lvl 21: Shadow Focus / Schattenfokus
        { phase = "A", nodeID = 105826, tree = 3, tier = 3, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 22: Mind Flay / Gedankenschinden
        { phase = "A", nodeID = 105825, tree = 3, tier = 3, column = 4, maxRank = 2, ranks = 2 }, -- Lvl 23: Improved Mind Flay / Verbessertes Gedankenschinden
        { phase = "A", nodeID = 110851, tree = 3, tier = 1, column = 1, maxRank = 5, ranks = 2 }, -- Lvl 25: Shadow Focus / Schattenfokus
        { phase = "A", nodeID = 105821, tree = 3, tier = 4, column = 3, maxRank = 3, ranks = 3 }, -- Lvl 27: Shadow Weaving / Schattenwirken
        { phase = "A", nodeID = 105820, tree = 3, tier = 4, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 30: Vampiric Embrace / Vampirumarmung
        { phase = "A", nodeID = 105831, tree = 3, tier = 2, column = 1, maxRank = 5, ranks = 1 }, -- Lvl 31: Improved Mind Blast / Verbesserter Gedankenschlag
        { phase = "A", nodeID = 105819, tree = 3, tier = 5, column = 3, maxRank = 2, ranks = 2 }, -- Lvl 32: Devouring Contagion / Verschlingende Ansteckung
        { phase = "A", nodeID = 105831, tree = 3, tier = 2, column = 1, maxRank = 5, ranks = 3 }, -- Lvl 34: Improved Mind Blast / Verbesserter Gedankenschlag
        { phase = "A", nodeID = 105818, tree = 3, tier = 6, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 37: Darkness / Dunkelheit
        { phase = "A", nodeID = 105817, tree = 3, tier = 7, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 42: Shadowform / Schattengestalt
        { phase = "B", nodeID = 105849, tree = 1, tier = 1, column = 3, maxRank = 5, ranks = 3 }, -- Lvl 43: Twin Disciplines / Zwillingsdisziplinen
        { phase = "B", nodeID = 105848, tree = 1, tier = 2, column = 1, maxRank = 3, ranks = 3 }, -- Lvl 46: Silent Resolve / Schweigsame Entschlossenheit
        { phase = "B", nodeID = 105837, tree = 1, tier = 2, column = 3, maxRank = 5, ranks = 2 }, -- Lvl 49: Mental Strength / Mentale Stärke
        { phase = "B", nodeID = 105843, tree = 1, tier = 3, column = 4, maxRank = 3, ranks = 3 }, -- Lvl 51: Meditation / Meditation
        { phase = "B", nodeID = 105867, tree = 2, tier = 1, column = 1, maxRank = 3, ranks = 3 }, -- Lvl 54: Twilight Focus / Zwielichtfokus
        { phase = "B", nodeID = 105824, tree = 3, tier = 5, column = 1, maxRank = 1, ranks = 1 }, -- Lvl 57: Silence / Stille
        { phase = "B", nodeID = 105837, tree = 1, tier = 2, column = 3, maxRank = 5, ranks = 3 }, -- Lvl 58: Mental Strength / Mentale Stärke
    },
    notes = {},
})

-- ------------------------------------------------------------
-- PRIESTER – Disziplin, Heiler (Leveling)
-- QUELLE: Wowhead
--   https://www.wowhead.com/forever/guide/classes/priest/discipline/healer-leveling-tips
-- Reihenfolge laut Spieler (Liste + Grafik, 28/18/5).
-- nodeID/Reihe/Spalte/maxRank aus dem Priester-Talentdump (2026-11-12),
-- Zuordnung über die Position auf der Wowhead-Grafik.
-- ------------------------------------------------------------
table.insert(ns.TalentBuilds, {
    key       = "PRIEST_DISCIPLINE_LEVELING",
    class     = "PRIEST",
    spec      = "DISCIPLINE",
    buildType = "LEVELING",
    variant   = "STANDARD",
    source    = "WOWHEAD",
    sourceUrl = "https://www.wowhead.com/forever/guide/classes/priest/discipline/healer-leveling-tips",
    structureVerified = true,    -- alle Talente im Dump gefunden
    positionsVerified = false,
    orderVerified     = false,
    verified          = false,
    title = { deDE = "Disziplin – Heiler (Leveling-Build)", enUS = "Discipline – healer (leveling build)" },
    menu  = { deDE = "Disziplin (Heal) – Leveling", enUS = "Discipline (healer) – leveling" },
    summary = {
        deDE = "Wowheads Heiler-Leveling-Empfehlung für Disziplin: Schild und Mana bis Sühne, dann Heilig-Schaden bis Heilige Nova, danach Willensentzug.",
        enUS = "Wowhead's healer leveling pick for Discipline: shield and mana up to Penance, then Holy damage up to Holy Nova, then Spirit Tap.",
    },
    distribution = { 28, 18, 5 },
    phases = {
        A = { deDE = "Phase A – Disziplin", enUS = "Phase A – Discipline" },
        B = { deDE = "Phase B – Heilig (Schaden)", enUS = "Phase B – Holy (damage)" },
        C = { deDE = "Phase C – Willensentzug & Rest", enUS = "Phase C – Spirit Tap & rest" },
    },
    steps = {
        { phase = "A", nodeID = 105850, tree = 1, tier = 1, column = 2, maxRank = 2, ranks = 2 }, -- Lvl 10: Wand Specialization / Zauberstab-Spezialisierung
        { phase = "A", nodeID = 110853, tree = 1, tier = 1, column = 1, maxRank = 5, ranks = 3 }, -- Lvl 12: Power in Light / Macht im Licht
        { phase = "A", nodeID = 110852, tree = 1, tier = 2, column = 2, maxRank = 3, ranks = 1 }, -- Lvl 15: Holy Precision / Heilige Präzision
        { phase = "A", nodeID = 105837, tree = 1, tier = 2, column = 3, maxRank = 5, ranks = 4 }, -- Lvl 16: Mental Strength / Mentale Stärke
        { phase = "A", nodeID = 105843, tree = 1, tier = 3, column = 4, maxRank = 3, ranks = 3 }, -- Lvl 20: Meditation / Meditation
        { phase = "A", nodeID = 105844, tree = 1, tier = 3, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 23: Inner Focus / Innerer Fokus
        { phase = "A", nodeID = 105846, tree = 1, tier = 3, column = 3, maxRank = 3, ranks = 1 }, -- Lvl 24: Improved Power Word: Shield / Verbessertes Machtwort: Schild
        { phase = "A", nodeID = 105841, tree = 1, tier = 4, column = 1, maxRank = 3, ranks = 3 }, -- Lvl 25: Improved Inner Fire / Verbessertes inneres Feuer
        { phase = "A", nodeID = 105846, tree = 1, tier = 3, column = 3, maxRank = 3, ranks = 2 }, -- Lvl 28: Improved Power Word: Shield / Verbessertes Machtwort: Schild
        { phase = "A", nodeID = 105834, tree = 1, tier = 5, column = 2, maxRank = 1, ranks = 1 }, -- Lvl 30: Penance / Sühne
        { phase = "A", nodeID = 105839, tree = 1, tier = 4, column = 3, maxRank = 1, ranks = 1 }, -- Lvl 31: Soul Warding / Seelenwehr
        { phase = "B", nodeID = 105867, tree = 2, tier = 1, column = 1, maxRank = 3, ranks = 3 }, -- Lvl 32: Twilight Focus / Zwielichtfokus
        { phase = "B", nodeID = 110855, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 2 }, -- Lvl 35: Holy Specialization / Heiligspezialisierung
        { phase = "B", nodeID = 105863, tree = 2, tier = 2, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 37: Divine Fury / Göttlicher Furor
        { phase = "B", nodeID = 105862, tree = 2, tier = 3, column = 1, maxRank = 1, ranks = 1 }, -- Lvl 42: Holy Nova / Heilige Nova
        { phase = "C", nodeID = 105833, tree = 3, tier = 1, column = 3, maxRank = 5, ranks = 5 }, -- Lvl 43: Spirit Tap / Willensentzug
        { phase = "C", nodeID = 105842, tree = 1, tier = 3, column = 1, maxRank = 3, ranks = 3 }, -- Lvl 48: Mental Agility / Mentale Beweglichkeit
        { phase = "C", nodeID = 110853, tree = 1, tier = 1, column = 1, maxRank = 5, ranks = 2 }, -- Lvl 51: Power in Light / Macht im Licht
        { phase = "C", nodeID = 110855, tree = 2, tier = 1, column = 3, maxRank = 5, ranks = 3 }, -- Lvl 53: Holy Specialization / Heiligspezialisierung
        { phase = "C", nodeID = 105861, tree = 2, tier = 3, column = 2, maxRank = 3, ranks = 1 }, -- Lvl 56: Blessed Recovery / Gesegnete Erholung
        { phase = "C", nodeID = 105857, tree = 2, tier = 4, column = 3, maxRank = 2, ranks = 2 }, -- Lvl 57: Searing Light / Sengendes Licht
        { phase = "C", nodeID = 105837, tree = 1, tier = 2, column = 3, maxRank = 5, ranks = 1 }, -- Lvl 59: Mental Strength / Mentale Stärke
        { phase = "C", nodeID = 105859, tree = 2, tier = 4, column = 1, maxRank = 2, ranks = 1 }, -- Lvl 60: Holy Reach / Heilige Reichweite
    },
    notes = {},
})

-- Endgame-Builds bekommen buildType = "ENDGAME" und dieselbe Struktur.
