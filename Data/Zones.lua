-- ============================================================
-- Data/Zones.lua
-- Levelbereiche der Zonen (WoW Forever).
--
-- Warum eigene Daten? Der Forever-Client liefert über C_Map.GetMapLevels
-- für die Zonen nur 0 – 0 (im Spiel geprüft mit /ww zoneinfo, Brachland,
-- Nov 2026). Deshalb stehen die Bereiche hier.
--
-- Schlüssel = uiMapID der Zone (sprachunabhängig). Der Name steht nur
-- als Kommentar; angezeigt wird der Name aus dem Spiel.
--   min, max   Levelbereich
--   faction    "HORDE" | "ALLIANCE" | "CONTESTED"
--   verified   true erst, wenn im Spiel bestätigt
--   mapIDVerified  true, wenn die uiMapID im Spiel bestätigt ist
--
-- Hauptquelle (Forever): https://mobalytics.gg/wow-forever/guides/zone-map-level-ranges
-- ============================================================

local _, ns = ...

ns.Zones = {
    -- Kalimdor
    [1413] = { min = 10, max = 25, faction = "HORDE", verified = false, mapIDVerified = true,
               source = "mobalytics (vom Spieler zitiert)" },  -- The Barrens / Das Brachland
    -- Weitere Zonen folgen, sobald die Daten der Quelle vorliegen.
}
