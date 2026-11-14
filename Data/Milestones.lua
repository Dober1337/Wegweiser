-- ============================================================
-- Data/Milestones.lua
-- Reiten: Stufen, Kosten, Reitlehrer pro Volk.
--
-- QUELLE: goldgoblin "Reiten lernen in WoW Forever"
--   https://classic.goldgoblin.net/wow-forever-reiten-lernen/  (Stand 2.11.2026)
--   Laut Quelle VORAB-/BETA-STAND: "Angaben entsprechen dem Beta- und Vorabstand."
--   Reitlehrer: "bekannte Classic-Anlaufstellen; ihr konkretes Forever-Lehrangebot
--   ist damit noch nicht für jeden NPC bestätigt." Koordinaten "ca.".
-- ============================================================

local _, ns = ...

ns.Riding = {
    src = "https://classic.goldgoblin.net/wow-forever-reiten-lernen/",
    verified = false,
    beta = true,
    normal = { level = 40, cost = 100 * 10000 },          -- 100 Gold, erstes Reittier enthalten
    fast   = { level = 60, cost = 1000 * 10000, mount = 200 * 10000 }, -- 1000 Gold + ca. 200 Gold Reittier
    saveFrom = { 30, 34, 37, 39 },                         -- Spar-Hinweise auf diesen Stufen (Wegweiser-Wahl)
    -- Reitlehrer nach Volk (UnitRace, zweiter Rückgabewert)
    trainers = {
        Orc      = { name = "Kildar",           map = 1454, x = 69, y = 13 },  -- Orgrimmar, Tal der Ehre
        Scourge  = { name = "Velma Warnam",     map = 1420, x = 60, y = 52 },  -- Tirisfal, Brill
        Tauren   = { name = "Kar Sturmsang",    map = 1412, x = 47, y = 58 },  -- Mulgore, Dorf der Bluthufe
        Troll    = { name = "Xar'Ti",           map = 1411, x = 55, y = 75 },  -- Durotar, Sen'jin
        Human    = { name = "Randal Weidmann",  map = 1429, x = 84, y = 65 },  -- Wald von Elwynn, Osttal
        Dwarf    = { name = "Ultham Eisenhorn", map = 1426, x = 64, y = 50 },  -- Dun Morogh, Gehöft Bernruh
        NightElf = { name = "Jartsam",          map = 1457, x = 38, y = 16 },  -- Darnassus
        Gnome    = { name = "Binjy Federpfiff", map = 1426, x = 49, y = 48 },  -- Dun Morogh, Kharanos
    },
}
