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

-- Endgame-Builds bekommen buildType = "ENDGAME" und dieselbe Struktur.
