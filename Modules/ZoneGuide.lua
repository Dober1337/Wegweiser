-- ============================================================
-- Modules/ZoneGuide.lua
-- Modul 2: Zonen-Wegweiser – STUFE 0: Prüf-Befehl /ww zoneinfo
--
-- Bevor wir den Zonen-Wegweiser (und später Routen) bauen, prüfen wir,
-- was der Forever-Client zur aktuellen Zone wirklich liefert:
--   * Zone (uiMapID, Name, Typ, übergeordnete Karte)
--   * Levelbereich der Zone direkt aus dem Spiel (C_Map.GetMapLevels)
--   * eigene Position (C_Map.GetPlayerMapPosition)
--   * verfügbare Quests mit Position (C_QuestLine.GetAvailableQuestLines)
--     – ob Forever das für Classic-Quests befüllt, ist UNKLAR -> prüfen
--   * ob Questie geladen ist
-- Ergebnis im Chat und in WegweiserDB.zoneProbe (nach /reload in der
-- SavedVariables-Datei).
-- Alle Funktionen geprüft im Forever-UI-Quellcode, Build 1.60.1.70888.
-- ============================================================

local _, ns = ...
local L = ns.L

local ZG = {}
ns.modules.ZoneGuide = ZG

local function safe(func, ...)
    if not func then return nil end
    local ok, a, b, c, d = pcall(func, ...)
    if ok then return a, b, c, d end
    return nil
end

function ZG:Probe()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        ns:Print(L.ZG_NO_MAP)
        return
    end
    local probe = { date = date("%Y-%m-%d %H:%M"), playerLevel = UnitLevel("player"), mapID = mapID }

    local info = safe(C_Map.GetMapInfo, mapID)
    probe.name      = info and info.name
    probe.mapType   = info and info.mapType
    probe.parentMap = info and info.parentMapID

    probe.minLevel, probe.maxLevel = safe(C_Map.GetMapLevels, mapID)

    local pos = safe(C_Map.GetPlayerMapPosition, mapID, "player")
    if pos then
        local x, y = pos:GetXY()
        probe.x, probe.y = x and math.floor(x * 1000) / 10, y and math.floor(y * 1000) / 10
    end

    probe.questie = C_AddOns.IsAddOnLoaded("Questie")
    probe.questieLoader = type(QuestieLoader)

    ns:Print("Zone: %s (uiMapID %d, Typ %s, über %s)", tostring(probe.name), mapID,
        tostring(probe.mapType), tostring(probe.parentMap))
    ns:Print("Levelbereich laut Spiel: %s – %s  |  Dein Level: %d",
        tostring(probe.minLevel), tostring(probe.maxLevel), probe.playerLevel)
    ns:Print("Position: %s, %s  |  Questie geladen: %s", tostring(probe.x), tostring(probe.y), tostring(probe.questie))

    ns.db.zoneProbe = ns.db.zoneProbe or {}
    ns.db.zoneProbe[mapID] = probe

    -- Verfügbare Quests: erst anfordern, dann kurz warten
    if C_QuestLine and C_QuestLine.RequestQuestLinesForMap then
        safe(C_QuestLine.RequestQuestLinesForMap, mapID)
    end
    C_Timer.After(1.5, function()
        local lines = (C_QuestLine and safe(C_QuestLine.GetAvailableQuestLines, mapID)) or {}
        probe.available = {}
        for _, l in ipairs(lines) do
            local key = ns.modules.QuestAdvisor:Evaluate(l.questID)
            table.insert(probe.available, {
                questID = l.questID, name = l.questName, line = l.questLineName,
                x = l.x and math.floor(l.x * 1000) / 10, y = l.y and math.floor(l.y * 1000) / 10,
                level = safe(C_QuestLog.GetQuestDifficultyLevel, l.questID),
                rating = key, hidden = l.isHidden,
            })
        end
        ns:Print("Verfügbare Quests laut Spiel (C_QuestLine): %d", #probe.available)
        for i = 1, math.min(8, #probe.available) do
            local a = probe.available[i]
            ns:Print("   [%s] %s – %s, %s  (%s)", tostring(a.level), tostring(a.name),
                tostring(a.x), tostring(a.y), tostring(a.rating))
        end
        ns:Print(L.ZG_PROBE_SAVED)
    end)
end
