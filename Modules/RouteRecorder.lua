-- ============================================================
-- Modules/RouteRecorder.lua
-- Zonen-Wegweiser STUFE 2: Routen-Recorder.
--
-- Zeichnet beim normalen Spielen auf, was du tust – mit Ort:
--   ACCEPT    Quest angenommen (Quest-ID, Titel, Questlevel, NPC)
--   COMPLETE  alle Questziele erledigt (wo das passiert ist)
--   TURNIN    Quest abgegeben (NPC, Erfahrung)
--   ABANDON   Quest abgebrochen
--   LEVEL     Levelaufstieg
--   ZONE      neue Zone betreten
--   TAXI      Flug gestartet / gelandet
--   BIND      Ruhestein gebunden
--   TRAINER   Lehrer besucht (Klassen- oder Berufslehrer)
--   NOTE      eigene Notiz (/ww route notiz <Text>)
--
-- Gespeichert in der SavedVariable WegweiserRouteDB (eigene Variable,
-- damit die Einstellungen klein bleiben). Pro Charakter eine Aufzeichnung.
-- Daraus bauen wir später die Route (Stufe 3) – mit ECHTEN Forever-Daten.
--
-- Regel "nur außerhalb des Kampfes": Ort/Questdaten werden erst nach dem
-- Kampf gelesen (z. B. wenn der letzte Gegner für eine Quest stirbt).
-- ============================================================

local _, ns = ...
local L = ns.L

local Rec = {}
ns.modules.RouteRecorder = Rec

local RECORD_VERSION = 1

local function settings()
    return ns.db and ns.db.settings or ns.defaults.settings
end

-- ------------------------------------------------------------
-- Hilfsfunktionen
-- ------------------------------------------------------------

-- Wert ist in Midnight/Forever evtl. ein "Geheimwert" (Kampf-Einschränkung)?
local function isSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

-- Aktuelle Karte und Position (in Prozent, 1 Nachkommastelle)
local function where()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    local x, y
    if pos then
        x, y = pos:GetXY()
        if x and y and not isSecret(x) then
            x, y = math.floor(x * 1000 + 0.5) / 10, math.floor(y * 1000 + 0.5) / 10
        else
            x, y = nil, nil
        end
    end
    return mapID, x, y
end

-- NPC-ID und Name aus einer Einheit ("npc" = gerade angesprochener NPC)
local function npcInfo(unit)
    if not UnitExists(unit) then return nil end
    local ok, guid = pcall(UnitGUID, unit)
    if not ok or not guid or isSecret(guid) then return nil end
    local unitType, _, _, _, _, id = strsplit("-", guid)
    local name = UnitName(unit)
    if isSecret(name) then name = nil end
    if unitType == "Creature" then
        return { id = tonumber(id), name = name }
    elseif unitType == "GameObject" then
        return { id = tonumber(id), name = name, object = true }
    end
    return nil
end

local function questLevel(questID)
    local idx = C_QuestLog.GetLogIndexForQuestID(questID)
    local info = idx and C_QuestLog.GetInfo(idx)
    if info then return info.difficultyLevel or info.level end
    local ok, lvl = pcall(C_QuestLog.GetQuestDifficultyLevel, questID)
    return ok and lvl or nil
end

-- ------------------------------------------------------------
-- Aufzeichnung verwalten
-- ------------------------------------------------------------

local function charKey()
    return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
end

function Rec:GetRecording()
    WegweiserRouteDB = WegweiserRouteDB or {}
    WegweiserRouteDB.recordings = WegweiserRouteDB.recordings or {}
    local key = charKey()
    local rec = WegweiserRouteDB.recordings[key]
    if not rec then
        local _, classFile = UnitClass("player")
        local _, raceFile = UnitRace("player")
        rec = {
            version   = RECORD_VERSION,
            class     = classFile,
            race      = raceFile,
            faction   = UnitFactionGroup("player"),
            started   = date("%Y-%m-%d %H:%M"),
            startLevel = UnitLevel("player"),
            gameBuild = select(2, GetBuildInfo()),
            steps     = {},
        }
        WegweiserRouteDB.recordings[key] = rec
    end
    return rec
end

function Rec:IsActive()
    return settings().routeRecorder and not self.paused
end

-- Fügt einen Schritt hinzu. Ort und Level werden automatisch ergänzt.
function Rec:Add(stepType, data)
    if not self:IsActive() then return end
    local rec = self:GetRecording()
    local step = data or {}
    step.t   = stepType
    step.lvl = UnitLevel("player")
    step.at  = time()
    if not step.map then
        step.map, step.x, step.y = where()
    end
    table.insert(rec.steps, step)
    self.lastStep = step
    if settings().routeVerbose then
        ns:Print(L.REC_STEP, stepType, tostring(step.title or step.name or step.questID or ""))
    end
end

-- ------------------------------------------------------------
-- Questziele erledigt? (Vergleich mit dem letzten Stand)
-- ------------------------------------------------------------

local completeCache = {}
local checkPending = false

local function scanComplete(record)
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID and info.questID > 0 then
            local id = info.questID
            local done = C_QuestLog.IsComplete(id) and true or false
            if record and done and completeCache[id] == false then
                Rec:Add("COMPLETE", { questID = id, title = info.title })
            end
            completeCache[id] = done
        end
    end
end

local function scheduleCompleteCheck()
    if checkPending then return end
    checkPending = true
    C_Timer.After(0.5, function()
        ns:RunOutOfCombat(function()
            checkPending = false
            scanComplete(true)
        end, true)
    end)
end

-- ------------------------------------------------------------
-- Ereignisse
-- ------------------------------------------------------------

local recentlyTurnedIn = {}
local onTaxi = false

function Rec:OnInitialize()
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
        scanComplete(false)   -- Startzustand merken, nichts aufzeichnen
        if (isInitialLogin or isReloadingUi) and settings().routeRecorder then
            local rec = Rec:GetRecording()
            C_Timer.After(4, function() ns:Print(L.REC_ACTIVE, #rec.steps) end)
        end
        if not isInitialLogin and not isReloadingUi then
            -- Ladebildschirm (z. B. Dungeon, Kontinentwechsel)
            Rec:Add("ZONE", { name = GetZoneText() })
        end
    end)

    ns:RegisterEvent("QUEST_ACCEPTED", function(_, questID)
        local npc = npcInfo("npc")
        C_Timer.After(0.3, function()
            Rec:Add("ACCEPT", {
                questID = questID,
                title   = C_QuestLog.GetTitleForQuestID(questID),
                qlvl    = questLevel(questID),
                npc     = npc,
            })
            completeCache[questID] = C_QuestLog.IsComplete(questID) and true or false
        end)
    end)

    ns:RegisterEvent("QUEST_TURNED_IN", function(_, questID, xp, money)
        recentlyTurnedIn[questID] = true
        Rec:Add("TURNIN", {
            questID = questID,
            title   = C_QuestLog.GetTitleForQuestID(questID),
            npc     = npcInfo("npc"),
            xp      = xp,
            money   = money,
        })
        completeCache[questID] = nil
    end)

    ns:RegisterEvent("QUEST_REMOVED", function(_, questID)
        C_Timer.After(0.5, function()
            if recentlyTurnedIn[questID] then
                recentlyTurnedIn[questID] = nil
            else
                Rec:Add("ABANDON", { questID = questID, title = C_QuestLog.GetTitleForQuestID(questID) })
            end
            completeCache[questID] = nil
        end)
    end)

    ns:RegisterEvent("QUEST_LOG_UPDATE", scheduleCompleteCheck)

    ns:RegisterEvent("PLAYER_LEVEL_UP", function(_, newLevel)
        C_Timer.After(0.2, function() Rec:Add("LEVEL", { level = newLevel }) end)
    end)

    ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        C_Timer.After(1, function()
            if not onTaxi then Rec:Add("ZONE", { name = GetZoneText() }) end
        end)
    end)

    ns:RegisterEvent("PLAYER_CONTROL_LOST", function()
        C_Timer.After(0.5, function()
            if UnitOnTaxi("player") and not onTaxi then
                onTaxi = true
                Rec:Add("TAXI", { phase = "start", name = GetSubZoneText() or GetZoneText() })
            end
        end)
    end)
    ns:RegisterEvent("PLAYER_CONTROL_GAINED", function()
        if onTaxi then
            onTaxi = false
            C_Timer.After(0.5, function()
                Rec:Add("TAXI", { phase = "end", name = GetSubZoneText() or GetZoneText() })
            end)
        end
    end)

    ns:RegisterEvent("HEARTHSTONE_BOUND", function()
        Rec:Add("BIND", { name = GetBindLocation and GetBindLocation() })
    end)

    ns:RegisterEvent("TRAINER_SHOW", function()
        Rec:Add("TRAINER", { npc = npcInfo("npc") })
    end)
end

-- ------------------------------------------------------------
-- /ww route ...
-- ------------------------------------------------------------

function Rec:PrintStatus()
    local rec = self:GetRecording()
    local state = not settings().routeRecorder and L.REC_STATE_OFF
        or (self.paused and L.REC_STATE_PAUSED or L.REC_STATE_ON)
    ns:Print(L.REC_STATUS, state, #rec.steps, rec.started or "?")
    local counts = {}
    for _, s in ipairs(rec.steps) do counts[s.t] = (counts[s.t] or 0) + 1 end
    ns:Print(L.REC_COUNTS, counts.ACCEPT or 0, counts.TURNIN or 0, counts.COMPLETE or 0,
        counts.LEVEL or 0, counts.NOTE or 0)
    ns:Print(L.REC_LAST)
    for i = math.max(1, #rec.steps - 4), #rec.steps do
        local s = rec.steps[i]
        ns:Print("   %d. %s %s (Lvl %s, %s %s)", i, s.t, tostring(s.title or s.name or s.level or s.text or ""),
            tostring(s.lvl), tostring(s.x), tostring(s.y))
    end
    ns:Print(L.REC_HELP)
end

function Rec:Command(arg, rest)
    if arg == "pause" then
        self.paused = true
        ns:Print(L.REC_PAUSED)
    elseif arg == "start" or arg == "weiter" then
        self.paused = false
        settings().routeRecorder = true
        ns:Print(L.REC_RESUMED)
    elseif arg == "notiz" or arg == "note" then
        local text = rest and rest:match("^%S+%s+(.+)$")
        if not text or text == "" then
            ns:Print(L.REC_NOTE_USAGE)
            return
        end
        local wasPaused = self.paused
        self.paused = false
        self:Add("NOTE", { text = text })
        self.paused = wasPaused
        ns:Print(L.REC_NOTE_SAVED, text)
    else
        self:PrintStatus()
    end
end
