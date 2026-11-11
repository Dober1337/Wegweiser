-- ============================================================
-- Data/Zones.lua
-- Levelbereiche der Zonen und Zonen-Empfehlungen (WoW Forever).
--
-- Warum eigene Daten? Der Forever-Client liefert über C_Map.GetMapLevels
-- für die Zonen nur 0 – 0 (im Spiel geprüft mit /ww zoneinfo, Brachland,
-- Nov 2026). Deshalb stehen die Bereiche hier.
--
-- QUELLE für alle Levelbereiche und Empfehlungen (Forever, Stand 10.11.2026):
--   https://mobalytics.gg/wow-forever/guides/zone-map-level-ranges
--   (Seiteninhalt vom Spieler kopiert, 11.11.2026)
--
-- Schlüssel = uiMapID der Zone (sprachunabhängig). Englischer Name nur als
-- Kommentar; angezeigt wird der Name aus dem Spiel.
--   min, max       Levelbereich laut Quelle
--   verified       true erst, wenn der Bereich im Spiel bestätigt ist
--   en             englischer Name – nur für den Prüfbefehl /ww zonecheck
--   mapIDVerified  true, wenn die uiMapID im Spiel bestätigt ist.
--                  Die uiMapIDs stammen aus WoW Classic (Classic-Fallback,
--                  ungeprüft) – Prüfung im Spiel mit /ww zonecheck.
-- ============================================================

local _, ns = ...

local SRC = "mobalytics 2026-11-10"

ns.Zones = {
    -- ===== Kalimdor (uiMapID 1414) =====
    [1411] = { min = 1,  max = 10, src = SRC, verified = false, mapIDVerified = false, en = "Durotar" }, -- Durotar
    [1412] = { min = 1,  max = 10, src = SRC, verified = false, mapIDVerified = false, en = "Mulgore" }, -- Mulgore
    [1438] = { min = 1,  max = 10, src = SRC, verified = false, mapIDVerified = false, en = "Teldrassil" }, -- Teldrassil
    [1439] = { min = 10, max = 20, src = SRC, verified = false, mapIDVerified = false, en = "Darkshore" }, -- Darkshore
    [1413] = { min = 10, max = 25, src = SRC, verified = false, mapIDVerified = true , en = "The Barrens" }, -- The Barrens (ID per /ww zoneinfo bestätigt)
    [1442] = { min = 15, max = 27, src = SRC, verified = false, mapIDVerified = false, en = "Stonetalon Mountains" }, -- Stonetalon Mountains
    [1440] = { min = 18, max = 30, src = SRC, verified = false, mapIDVerified = false, en = "Ashenvale" }, -- Ashenvale
    [1441] = { min = 25, max = 35, src = SRC, verified = false, mapIDVerified = false, en = "Thousand Needles" }, -- Thousand Needles
    [1443] = { min = 30, max = 40, src = SRC, verified = false, mapIDVerified = false, en = "Desolace" }, -- Desolace
    [1445] = { min = 35, max = 45, src = SRC, verified = false, mapIDVerified = false, en = "Dustwallow Marsh" }, -- Dustwallow Marsh
    [1444] = { min = 40, max = 50, src = SRC, verified = false, mapIDVerified = false, en = "Feralas" }, -- Feralas
    [1446] = { min = 40, max = 50, src = SRC, verified = false, mapIDVerified = false, en = "Tanaris" }, -- Tanaris
    [1447] = { min = 45, max = 55, src = SRC, verified = false, mapIDVerified = false, en = "Azshara" }, -- Azshara
    [1449] = { min = 48, max = 55, src = SRC, verified = false, mapIDVerified = false, en = "Un'Goro Crater" }, -- Un'Goro Crater
    [1448] = { min = 48, max = 55, src = SRC, verified = false, mapIDVerified = false, en = "Felwood" }, -- Felwood
    [1451] = { min = 55, max = 60, src = SRC, verified = false, mapIDVerified = false, en = "Silithus" }, -- Silithus
    [1452] = { min = 55, max = 60, src = SRC, verified = false, mapIDVerified = false, en = "Winterspring" }, -- Winterspring
    -- Moonglade: laut Quelle ohne Levelbereich
    -- Mount Hyjal (60), Riverglades, Shen'dralas, Zephras Isle: NEU in Forever,
    --   uiMapID unbekannt -> dort /ww zoneinfo eingeben und nachtragen.

    -- ===== Östliche Königreiche (uiMapID 1415) =====
    [1420] = { min = 1,  max = 10, src = SRC, verified = false, mapIDVerified = false, en = "Tirisfal Glades" }, -- Tirisfal Glades
    [1426] = { min = 1,  max = 10, src = SRC, verified = false, mapIDVerified = false, en = "Dun Morogh" }, -- Dun Morogh
    [1429] = { min = 1,  max = 10, src = SRC, verified = false, mapIDVerified = false, en = "Elwynn Forest" }, -- Elwynn Forest
    [1421] = { min = 10, max = 20, src = SRC, verified = false, mapIDVerified = false, en = "Silverpine Forest" }, -- Silverpine Forest
    [1432] = { min = 10, max = 20, src = SRC, verified = false, mapIDVerified = false, en = "Loch Modan" }, -- Loch Modan
    [1436] = { min = 10, max = 20, src = SRC, verified = false, mapIDVerified = false, en = "Westfall" }, -- Westfall
    [1433] = { min = 15, max = 25, src = SRC, verified = false, mapIDVerified = false, en = "Redridge Mountains" }, -- Redridge Mountains
    [1431] = { min = 18, max = 30, src = SRC, verified = false, mapIDVerified = false, en = "Duskwood" }, -- Duskwood
    [1437] = { min = 20, max = 30, src = SRC, verified = false, mapIDVerified = false, en = "Wetlands" }, -- Wetlands
    [1424] = { min = 20, max = 30, src = SRC, verified = false, mapIDVerified = false, en = "Hillsbrad Foothills" }, -- Hillsbrad Foothills
    [1416] = { min = 30, max = 40, src = SRC, verified = false, mapIDVerified = false, en = "Alterac Mountains" }, -- Alterac Mountains
    [1417] = { min = 30, max = 40, src = SRC, verified = false, mapIDVerified = false, en = "Arathi Highlands" }, -- Arathi Highlands
    [1434] = { min = 30, max = 45, src = SRC, verified = false, mapIDVerified = false, en = "Stranglethorn Vale" }, -- Stranglethorn Vale
    [1418] = { min = 35, max = 45, src = SRC, verified = false, mapIDVerified = false, en = "Badlands" }, -- Badlands
    [1435] = { min = 35, max = 45, src = SRC, verified = false, mapIDVerified = false, en = "Swamp of Sorrows" }, -- Swamp of Sorrows
    [1425] = { min = 40, max = 50, src = SRC, verified = false, mapIDVerified = false, en = "The Hinterlands" }, -- The Hinterlands
    [1427] = { min = 43, max = 50, src = SRC, verified = false, mapIDVerified = false, en = "Searing Gorge" }, -- Searing Gorge
    [1419] = { min = 45, max = 55, src = SRC, verified = false, mapIDVerified = false, en = "Blasted Lands" }, -- Blasted Lands
    [1430] = { min = 55, max = 60, src = SRC, verified = false, mapIDVerified = false, en = "Deadwind Pass" }, -- Deadwind Pass
    [1422] = { min = 51, max = 58, src = SRC, verified = false, mapIDVerified = false, en = "Western Plaguelands" }, -- Western Plaguelands
    [1423] = { min = 53, max = 60, src = SRC, verified = false, mapIDVerified = false, en = "Eastern Plaguelands" }, -- Eastern Plaguelands
    -- Burning Steppes (1428): laut Quelle ohne Levelbereich (aber für 51–52 empfohlen)
}

-- ------------------------------------------------------------
-- Empfohlene Zonen je Levelstufe (Horde), laut derselben Quelle.
-- zones = uiMapIDs; note = Hinweis auf ein Teilgebiet (Schlüssel in Locales).
-- Riverglades (neu, uiMapID unbekannt) ist als Hinweis vermerkt.
-- ------------------------------------------------------------
ns.ZoneRecommendations = {
    HORDE = {
        src = SRC, verified = false,
        { min = 10, max = 18, zones = { 1413, 1421 } },                       -- Barrens, Silverpine
        { min = 18, max = 22, zones = { 1413, 1442, 1440 } },                 -- Barrens, Stonetalon, Ashenvale
        { min = 22, max = 28, zones = { 1424, 1413, 1442, 1440 },             -- Hillsbrad, (Southern) Barrens, Stonetalon, Ashenvale
          notes = { "ZG_NOTE_SOUTHERN_BARRENS" } },
        { min = 28, max = 30, zones = { 1441, 1424 } },                       -- Thousand Needles, Hillsbrad
        { min = 30, max = 33, zones = { 1424, 1417 } },                       -- Hillsbrad, Arathi
        { min = 33, max = 35, zones = { 1441, 1443 },                         -- (Shimmering Flats), Desolace
          notes = { "ZG_NOTE_SHIMMERING_FLATS" } },
        { min = 35, max = 38, zones = { 1434, 1445 },                         -- (Northern) Stranglethorn, Dustwallow
          notes = { "ZG_NOTE_RIVERGLADES", "ZG_NOTE_NORTHERN_STV" } },
        { min = 38, max = 40, zones = { 1416, 1417, 1418 },                   -- Alterac, Arathi, Badlands
          notes = { "ZG_NOTE_RIVERGLADES" } },
        { min = 40, max = 42, zones = { 1434, 1435 } },                       -- Stranglethorn, Swamp of Sorrows
        { min = 42, max = 44, zones = { 1443, 1446, 1444 } },                 -- Desolace, Tanaris, Feralas
        { min = 44, max = 48, zones = { 1434, 1435, 1446 } },                 -- Stranglethorn, Swamp, Tanaris
        { min = 48, max = 50, zones = { 1425, 1444 } },                       -- Hinterlands, Feralas
        { min = 50, max = 51, zones = { 1434, 1419 } },                       -- Stranglethorn, Blasted Lands
        { min = 51, max = 52, zones = { 1427, 1428 } },                       -- Searing Gorge, Burning Steppes
        { min = 52, max = 55, zones = { 1447, 1448, 1449 } },                 -- Azshara, Felwood, Un'Goro
        { min = 55, max = 58, zones = { 1448, 1452, 1422, 1423 } },           -- Felwood, Winterspring, W/E Plaguelands
        { min = 58, max = 60, zones = { 1452, 1451 } },                       -- Winterspring, Silithus
    },
}
