-- ============================================================
-- Data/Professions.lua
-- Berufe in WoW Forever: Arten, sinnvolle Kombinationen, Klassen-Tipps.
--
-- QUELLE (Forever, Stand Beta – Werte können sich geändert haben):
--   https://classic.goldgoblin.net/warcraft-forever-berufe-uebersicht/
--   (abgerufen 11.11.2026). Nur Fakten übernommen, Texte eigene Worte.
--
-- Was das Spiel selbst liefert (C_SkillInfo, geprüft im Forever-UI-Quellcode):
--   aktueller Skill (rank) und aktuelles Limit (maxRank) jedes Berufs.
-- Was NICHT bekannt ist: die Charakterlevel-Voraussetzung für den nächsten
--   Rang (Quellen widersprechen sich) -> wird bewusst NICHT angezeigt.
--
-- Schlüssel = skillLineID (sprachunabhängig). Die IDs stammen aus WoW Classic
-- (Classic-Fallback, ungeprüft) -> Prüfung im Spiel mit /ww berufe
-- (zeigt die Nummer hinter jedem gelernten Beruf).
-- ============================================================

local _, ns = ...

local SRC = "goldgoblin (Beta-Stand)"

ns.Professions = {
    -- kind: "GATHERING" (Sammeln), "CRAFTING" (Herstellen), "SECONDARY" (Nebenberuf)
    -- uses: welcher Sammelberuf die Rohstoffe liefert (nur Herstellungsberufe)
    [182] = { kind = "GATHERING", en = "Herbalism",      src = SRC, verified = false, idVerified = false },
    [186] = { kind = "GATHERING", en = "Mining",         src = SRC, verified = false, idVerified = false },
    [393] = { kind = "GATHERING", en = "Skinning",       src = SRC, verified = false, idVerified = false },
    [171] = { kind = "CRAFTING",  en = "Alchemy",        uses = 182, src = SRC, verified = false, idVerified = false },
    [164] = { kind = "CRAFTING",  en = "Blacksmithing",  uses = 186, src = SRC, verified = false, idVerified = false },
    [202] = { kind = "CRAFTING",  en = "Engineering",    uses = 186, src = SRC, verified = false, idVerified = false },
    [165] = { kind = "CRAFTING",  en = "Leatherworking", uses = 393, src = SRC, verified = false, idVerified = false },
    [197] = { kind = "CRAFTING",  en = "Tailoring",      src = SRC, verified = false, idVerified = false }, -- Stoff fällt von Gegnern
    [333] = { kind = "CRAFTING",  en = "Enchanting",     src = SRC, verified = false, idVerified = false }, -- Material durch Entzaubern
    [185] = { kind = "SECONDARY", en = "Cooking",        src = SRC, verified = false, idVerified = false },
    [129] = { kind = "SECONDARY", en = "First Aid",      src = SRC, verified = false, idVerified = false },
    [356] = { kind = "SECONDARY", en = "Fishing",        src = SRC, verified = false, idVerified = false },
}

-- Rang-Grenzen (Lehrling 75, Geselle 150, Experte 225, Fachmann 300).
-- In allen Quellen gleich; das Spiel liefert das aktuelle Limit ohnehin selbst.
ns.ProfessionCaps = { values = { 75, 150, 225, 300 }, src = SRC, verified = false }

-- Ab so vielen Punkten vor dem Limit kommt der Hinweis "bald zum Lehrer"
ns.ProfessionCapWarning = { value = 5, verified = false }

-- Sinnvolle Kombinationen (laut Quelle). Texte in Locales (PROF_PAIR_*).
ns.ProfessionPairs = {
    src = SRC, verified = false,
    { a = 171, b = 182, text = "PROF_PAIR_ALCH_HERB" },   -- Alchemie + Kräuterkunde
    { a = 164, b = 186, text = "PROF_PAIR_BS_MINING" },   -- Schmiedekunst + Bergbau
    { a = 202, b = 186, text = "PROF_PAIR_ENG_MINING" },  -- Ingenieurskunst + Bergbau
    { a = 165, b = 393, text = "PROF_PAIR_LW_SKIN" },     -- Lederverarbeitung + Kürschnerei
    { a = 197, b = 333, text = "PROF_PAIR_TAILOR_ENCH" }, -- Schneiderei + Verzauberkunst
}

-- Klassen-Tipps: zu welchen Klassen ein Herstellungsberuf laut Quelle gut passt.
-- (Quelle: "Schmiedekunst – gut für Krieger, Paladine", "Lederverarbeitung –
--  gut für Druiden, Schurken, Jäger, Schamanen", "Schneiderei – gut für Stoffklassen")
ns.ProfessionClassTips = {
    src = SRC, verified = false,
    WARRIOR = { 164 }, PALADIN = { 164 },
    DRUID = { 165 }, ROGUE = { 165 }, HUNTER = { 165 }, SHAMAN = { 165 },
    MAGE = { 197 }, PRIEST = { 197 }, WARLOCK = { 197 },   -- Stoffklassen
}

-- ============================================================
-- Ergänzt aus den goldgoblin-Einzelseiten (abgerufen 11.11.2026):
--   https://classic.goldgoblin.net/berufe/<beruf>-forever/
--   (bergbau, kraeuterkunde, kuerschnerei, alchemie, schmiedekunst,
--    ingenieurskunst, lederverarbeitung, schneiderei, verzauberkunst,
--    kochkunst, angeln, erste-hilfe)
-- Alles verified = false, bis im Spiel bestätigt.
-- ============================================================

local SRC2 = "goldgoblin Einzelseiten 2026-11-11"

-- Nächste Ränge: [2] Geselle (bis 150), [3] Experte (bis 225), [4] Fachmann (bis 300)
--   skill = ab diesem Skill lernbar, level = nötige Charakterstufe (nil = keine)
--   how   = "TRAINER" | "BOOK" (Buch kaufen) | "QUEST"
--   note  = Schlüssel in Locales für Besonderheiten
local GATHER = {
    [2] = { skill = 50,  how = "TRAINER" },
    [3] = { skill = 125, how = "TRAINER" },
    [4] = { skill = 200, how = "TRAINER" },
}
local CRAFT = {
    [2] = { skill = 50,  level = 10, how = "TRAINER" },
    [3] = { skill = 125, level = 20, how = "TRAINER" },
    [4] = { skill = 200, level = 35, how = "TRAINER" },
}
local function craft(note4)
    return { [2] = CRAFT[2], [3] = CRAFT[3], [4] = { skill = 200, level = 35, how = "TRAINER", note = note4 } }
end

ns.ProfessionRanks = {
    src = SRC2, verified = false,
    [186] = GATHER,   -- Bergbau: "Ab Skill 50/125/200 beim Lehrer"
    [182] = GATHER,   -- Kräuterkunde: gleich
    [393] = GATHER,   -- Kürschnerei: "Ab Fertigkeit 50/125/200"
    [171] = craft(nil),                    -- Alchemie: Fachmann ab 200, Stufe 35
    [164] = craft("PROF_ART_164"),         -- Schmiedekunst: Fachmann-Lehrer in Beutebucht
    [202] = craft("PROF_ART_202"),         -- Ingenieurskunst: Fachmann bei Buzzek Bracketswing, Gadgetzan
    [165] = craft("PROF_ART_165"),         -- Lederverarbeitung: Expertenlehrer in Donnerfels lehren Fachmann nicht
    [197] = craft(nil),                    -- Schneiderei: Geselle Skill 50 / Stufe 10
    [333] = craft("PROF_ART_333"),         -- Verzauberkunst: einziger Fachmann-Lehrer Annora in Uldaman
    [185] = { [2] = { skill = 50, level = 10, how = "TRAINER" },          -- Kochkunst
              [3] = { skill = 125, level = 20, how = "BOOK" },
              [4] = { skill = 225, level = 35, how = "QUEST" } },
    [356] = { [2] = { skill = 50, level = 10, how = "TRAINER" },          -- Angeln
              [3] = { skill = 125, level = 20, how = "BOOK" },
              [4] = { skill = 225, level = 35, how = "QUEST", note = "PROF_ART_356" } },
    [129] = { [2] = { skill = 50, level = 10, how = "TRAINER" },          -- Erste Hilfe
              [3] = { skill = 125, how = "BOOK", note = "PROF_EXP_129" },
              [4] = { skill = 225, level = 35, how = "QUEST", note = "PROF_ART_129" } },
}

-- Abbau-/Pflückbarkeit: ab Skill (min), gelb ab, grün ab, grau ab (Forever-Datenstand)
ns.GatherNodes = {
    src = SRC2, verified = false,
    [186] = {   -- Bergbau
        { de = "Kupfervorkommen",        en = "Copper Vein",          min = 1,   yellow = 25,  green = 50,  grey = 100 },
        { de = "Zinnvorkommen",          en = "Tin Vein",             min = 65,  yellow = 90,  green = 115, grey = 165 },
        { de = "Silbervorkommen",        en = "Silver Vein",          min = 75,  yellow = 100, green = 125, grey = 175 },
        { de = "Eisenvorkommen",         en = "Iron Deposit",         min = 125, yellow = 150, green = 175, grey = 225 },
        { de = "Goldvorkommen",          en = "Gold Vein",            min = 155, yellow = 180, green = 205, grey = 255 },
        { de = "Mithrilablagerung",      en = "Mithril Deposit",      min = 175, yellow = 200, green = 225, grey = 275 },
        { de = "Echtsilberablagerung",   en = "Truesilver Deposit",   min = 230, yellow = 255, green = 280, grey = 330 },
        { de = "Kleines Thoriumvorkommen", en = "Small Thorium Vein", min = 245, yellow = 270, green = 295, grey = 345 },
        { de = "Reiches Thoriumvorkommen", en = "Rich Thorium Vein",  min = 275, yellow = 300, green = 325, grey = 375 },
    },
    [182] = {   -- Kräuterkunde
        { de = "Friedensblume",       en = "Peacebloom",         min = 1,   yellow = 25,  green = 50,  grey = 100 },
        { de = "Silberblatt",         en = "Silverleaf",         min = 1,   yellow = 25,  green = 50,  grey = 100 },
        { de = "Erdwurzel",           en = "Earthroot",          min = 15,  yellow = 40,  green = 65,  grey = 115 },
        { de = "Maguskönigskraut",    en = "Mageroyal",          min = 50,  yellow = 75,  green = 100, grey = 150 },
        { de = "Wilddornrose",        en = "Briarthorn",         min = 70,  yellow = 95,  green = 120, grey = 170 },
        { de = "Würgetang",           en = "Stranglekelp",       min = 85,  yellow = 110, green = 135, grey = 185 },
        { de = "Beulengras",          en = "Bruiseweed",         min = 100, yellow = 125, green = 150, grey = 200 },
        { de = "Wildstahlblume",      en = "Wild Steelbloom",    min = 115, yellow = 140, green = 165, grey = 215 },
        { de = "Grabmoos",            en = "Grave Moss",         min = 120, yellow = 145, green = 170, grey = 220 },
        { de = "Königsblut",          en = "Kingsblood",         min = 125, yellow = 150, green = 175, grey = 225 },
        { de = "Lebenswurz",          en = "Liferoot",           min = 150, yellow = 175, green = 200, grey = 250 },
        { de = "Blassblatt",          en = "Fadeleaf",           min = 160, yellow = 185, green = 210, grey = 260 },
        { de = "Golddorn",            en = "Goldthorn",          min = 170, yellow = 195, green = 220, grey = 270 },
        { de = "Khadgars Schnurrbart", en = "Khadgar's Whisker", min = 185, yellow = 210, green = 235, grey = 285 },
        { de = "Winterbiss",          en = "Wintersbite",        min = 195, yellow = 220, green = 245, grey = 295 },
        { de = "Feuerblüte",          en = "Firebloom",          min = 205, yellow = 230, green = 255, grey = 305 },
    },
}

-- Horde-Lehrer mit Wegpunkt (nur Einträge MIT Koordinaten aus der Quelle).
--   map = uiMapID, x/y in Prozent, apprentice = true -> lehrt nur Lehrling (bis 75)
-- uiMapIDs der Hauptstädte (1454 Orgrimmar, 1456 Donnerfels, 1458 Unterstadt)
-- stammen aus Classic (ungeprüft) -> /ww zonecheck prüft sie mit.
ns.ProfessionTrainers = {
    src = SRC2, verified = false,
    HORDE = {
        [186] = {   -- Bergbau
            { name = "Norzsh",          map = 1411, x = 40.6, y = 68.0, apprentice = true },  -- Tal der Prüfungen
            { name = "Vartha Rockmane", map = 1412, x = 44.2, y = 78.2, apprentice = true },  -- Ebene der Roten Wolke
            { name = "Walter Mason",    map = 1420, x = 32.2, y = 65.8, apprentice = true },  -- Todesend
            { name = "Makaru",          map = 1454, x = 73.0, y = 26.4 },                     -- Orgrimmar
            { name = "Brek Stonehoof",  map = 1456, x = 34.6, y = 57.6 },                     -- Donnerfels
            { name = "Brom Killian",    map = 1458, x = 56.0, y = 37.0 },                     -- Unterstadt
            { name = "Krunn",           map = 1411, x = 51.8, y = 40.8 },                     -- Klingenhügel
            { name = "Johan Focht",     map = 1421, x = 43.4, y = 40.6 },                     -- Das Grabmal
        },
        [182] = {   -- Kräuterkunde
            { name = "Zor'la",             map = 1411, x = 42.6, y = 67.4, apprentice = true },
            { name = "Garan Sunstrider",   map = 1412, x = 44.2, y = 77.8, apprentice = true },
            { name = "Florence Nightshade", map = 1420, x = 32.4, y = 65.2, apprentice = true },
            { name = "Jandi",              map = 1454, x = 55.6, y = 39.6 },
            { name = "Komin Winterhoof",   map = 1456, x = 49.8, y = 39.8 },
            { name = "Martha Alliestar",   map = 1458, x = 54.8, y = 50.2 },
            { name = "Ruw",                map = 1444, x = 76.0, y = 43.4 },                  -- Camp Mojache
        },
        [393] = {   -- Kürschnerei
            { name = "Thuwd",           map = 1454, x = 63.2, y = 45.2 },
            { name = "Dranh",           map = 1413, x = 45.1, y = 59.1 },                     -- Camp Taurajo
            { name = "Kulleg Stonehorn", map = 1444, x = 74.5, y = 43.0 },                    -- Camp Mojache
        },
        [356] = {   -- Angeln
            { name = "Uthan Stillwater", map = 1412, x = 44.6, y = 60.6 },
            { name = "Lau'Tiki",         map = 1411, x = 53.2, y = 81.6 },
            { name = "Lumak",            map = 1454, x = 69.8, y = 29.6 },
            { name = "Armand Cromwell",  map = 1458, x = 80.8, y = 31.2 },
            { name = "Kah Mistrunner",   map = 1456, x = 56.0, y = 46.8 },
            { name = "Clyde Kellen",     map = 1420, x = 67.2, y = 51.0 },
            { name = "Katoom",           map = 1425, x = 80.2, y = 81.4 },
            { name = "Kil'Hiwana",       map = 1440, x = 10.8, y = 33.6 },
            { name = "Lui'Mala",         map = 1443, x = 22.6, y = 72.6 },
        },
        [185] = {   -- Kochkunst (nur Einträge mit Koordinaten)
            { name = "Mudduk",           map = 1434, x = 31.4, y = 28.0 },                    -- Grom'gol
            { name = "Slagg",            map = 1417, x = 74.0, y = 33.8 },                    -- Hammerfall
        },
        [129] = {   -- Erste Hilfe: Fachmann über die Triage-Quest
            { name = "Dr. Gregory Victor", map = 1417, x = 73.4, y = 36.8, artisanOnly = true }, -- Hammerfall
        },
    },
}

-- Händlergunst-Rezepthändler der Horde (neues Handelslager westlich vom Wegekreuz)
ns.ProfessionVendorCamp = { HORDE = { map = 1413, x = 49.8, y = 29.6 }, src = SRC2, verified = false }

-- Zusätzliche Karten für /ww zonecheck (Hauptstädte)
ns.ExtraMaps = {
    [1454] = "Orgrimmar", [1456] = "Thunder Bluff", [1458] = "Undercity",
}
