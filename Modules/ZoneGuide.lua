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

-- ============================================================
-- STUFE 1: Zonen-Wegweiser
--
--   * /ww zonen   – aktuelle Zone mit Levelbereich + passende Zonen für dein Level
--   * automatisch (nach Levelaufstieg oder Zonenwechsel, außerhalb des Kampfes):
--       - Zone ist für dich zu niedrig geworden -> passende Zonen vorschlagen
--       - kaum noch machbare Quests im Log (Quest-Berater) -> Hinweis
--   * /ww zonecheck – prüft die uiMapIDs aus Data/Zones.lua gegen das Spiel
-- Daten: Data/Zones.lua (Quelle mobalytics, verified = false).
-- ============================================================

local function settings()
    return ns.db and ns.db.settings or ns.defaults.settings
end

-- Farbcode wie auf der Weltkarte (Blizzard-Logik)
local function rangeColorCode(minL, maxL)
    local playerLevel = UnitLevel("player")
    local c
    if playerLevel < minL then
        c = GetQuestDifficultyColor(minL)
    elseif playerLevel > maxL then
        c = GetQuestDifficultyColor(maxL - 2)
    else
        c = QuestDifficultyColors and QuestDifficultyColors["difficult"] or { r = 1, g = 0.82, b = 0 }
    end
    return string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
end

-- "Das Brachland (10–25)" in passender Farbe
function ZG:ZoneLabel(mapID)
    local z = ns.Zones[mapID]
    local info = C_Map.GetMapInfo(mapID)
    local name = info and info.name or (z and z.en) or ("#" .. mapID)
    if not z then return name end
    return string.format("%s%s (%d–%d)|r", rangeColorCode(z.min, z.max), name, z.min, z.max)
end

-- Aktuelle Zone mit Daten: bei Unterkarten (Höhlen, Städte) nach oben gehen
function ZG:GetCurrentZone()
    local mapID = C_Map.GetBestMapForUnit("player")
    local guard = 0
    while mapID and not ns.Zones[mapID] and guard < 6 do
        local info = C_Map.GetMapInfo(mapID)
        mapID = info and info.parentMapID
        guard = guard + 1
    end
    if mapID and ns.Zones[mapID] then return mapID, ns.Zones[mapID] end
    return nil
end

-- Empfohlene Zonen für ein Level (Horde-Liste). Rückgabe: Eintrag oder nil
function ZG:GetRecommendation(level)
    local faction = UnitFactionGroup("player")
    local list = ns.ZoneRecommendations[faction == "Horde" and "HORDE" or ""]
    if not list then return nil end
    for _, entry in ipairs(list) do
        if level >= entry.min and level < entry.max then return entry end
    end
    -- genau auf der Obergrenze des letzten Eintrags (z. B. 60)
    local last = list[#list]
    if last and level >= last.min then return last end
    return nil
end

-- Wie viele Quests im Log sind gerade "gut machbar" oder "lohnt sich noch"?
function ZG:CountDoableQuests()
    local qa = ns.modules.QuestAdvisor
    if not qa then return nil end
    local n = 0
    for _, q in ipairs(qa:GetAllQuests()) do
        if q.category == "GOOD" or q.category == "STILL_WORTH" or q.category == "DONE" then n = n + 1 end
    end
    return n
end

function ZG:PrintRecommendation(level, currentID)
    local rec = self:GetRecommendation(level)
    if not rec then
        ns:Print(UnitFactionGroup("player") == "Horde" and L.ZG_NO_REC or L.ZG_NO_REC_FACTION)
        return
    end
    local parts = {}
    for _, id in ipairs(rec.zones) do
        local label = self:ZoneLabel(id)
        if id == currentID then label = label .. L.ZG_YOU_ARE_HERE end
        table.insert(parts, label)
    end
    ns:Print(L.ZG_REC_HEADER, rec.min, rec.max, table.concat(parts, ", "))
    for _, key in ipairs(rec.notes or {}) do
        ns:Print("   " .. L[key])
    end
end

-- /ww zonen
function ZG:PrintAdvice()
    local level = UnitLevel("player")
    local mapID, z = self:GetCurrentZone()
    if mapID then
        local state
        if level > z.max then state = L.ZG_STATE_TOO_LOW
        elseif level < z.min then state = L.ZG_STATE_TOO_HIGH
        else state = L.ZG_STATE_OK end
        ns:Print(L.ZG_CURRENT, self:ZoneLabel(mapID), state)
    else
        ns:Print(L.ZG_CURRENT_UNKNOWN)
    end
    local doable = self:CountDoableQuests()
    if doable then ns:Print(L.ZG_DOABLE, doable) end
    self:PrintRecommendation(level, mapID)
    ns:Print(L.ZG_SOURCE_NOTE)
end

-- Automatischer Hinweis – höchstens einmal pro Zone und Level
local lastHintKey
function ZG:AutoHint(reason)
    if not settings().zoneAdvice then return end
    local level = UnitLevel("player")
    local mapID, z = self:GetCurrentZone()
    if not mapID then return end
    local key = mapID .. ":" .. level
    if key == lastHintKey then return end

    if level > z.max then
        lastHintKey = key
        ns:Notify(L.ZG_HINT_TOO_LOW, self:ZoneLabel(mapID))
        self:PrintRecommendation(level, mapID)
    elseif reason == "LEVEL" and level >= z.min then
        local doable = self:CountDoableQuests()
        if doable and doable <= 1 then
            lastHintKey = key
            ns:Print(L.ZG_HINT_FEW_QUESTS, doable)
            self:PrintRecommendation(level, mapID)
        end
    end
end

-- /ww zonecheck – uiMapIDs gegen das Spiel prüfen
function ZG:CheckMapIDs()
    local ids = {}
    for id in pairs(ns.Zones) do table.insert(ids, id) end
    table.sort(ids)
    ns:Print(L.ZG_CHECK_HEADER)
    local missing = 0
    for _, id in ipairs(ids) do
        local z = ns.Zones[id]
        local info = C_Map.GetMapInfo(id)
        local parent = info and info.parentMapID and C_Map.GetMapInfo(info.parentMapID)
        if info then
            ns:Print("   %d: %s  |cff999999(%s, über %s)|r", id, info.name, z.en or "?", parent and parent.name or "?")
        else
            missing = missing + 1
            ns:Print("   |cffff5555%d: FEHLT im Spiel|r (%s)", id, z.en or "?")
        end
    end
    ns:Print(L.ZG_CHECK_DONE, #ids, missing)
end

function ZG:OnInitialize()
    ns:RegisterEvent("PLAYER_LEVEL_UP", function()
        C_Timer.After(3, function()
            ns:RunOutOfCombat(function() ZG:AutoHint("LEVEL") end, true)
        end)
    end)
    ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        C_Timer.After(2, function()
            ns:RunOutOfCombat(function() ZG:AutoHint("ZONE") end, true)
        end)
    end)
end
