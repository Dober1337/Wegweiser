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
