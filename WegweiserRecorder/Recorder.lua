-- ============================================================
-- WegweiserRecorder/Recorder.lua
-- Eigenständiges Addon: zeichnet die Questroute auf.
--
-- Was aufgezeichnet wird (jeweils mit Karte, Position, Spielerlevel, Zeit):
--   SESSION   Einloggen (Spielversion, Addon-Version)
--   ACCEPT    Quest angenommen (Quest-ID, Titel, Questlevel, NPC)
--   COMPLETE  alle Questziele erledigt (wo das passiert ist)
--   TURNIN    Quest abgegeben (NPC, Erfahrung, Geld)
--   ABANDON   Quest abgebrochen
--   LEVEL     Levelaufstieg
--   ZONE      neue Zone betreten
--   TAXI      Flug gestartet / gelandet
--   BIND      Ruhestein gebunden
--   TRAINER   Lehrer besucht
--   NOTE      eigene Notiz (/wwrec notiz <Text>)
--
-- Datenschutz: KEIN Charaktername, KEIN Realm. Jeder Charakter bekommt eine
-- zufällige Nummer (gespeichert pro Charakter). Dazu nur Klasse, Volk,
-- Fraktion – damit man die Datei bedenkenlos weitergeben kann.
--
-- Gespeichert in WegweiserRecorderDB ->
--   WTF\Account\<KONTONAME>\SavedVariables\WegweiserRecorder.lua
-- Diese Datei schicken Mitspieler an das Wegweiser-Team.
--
-- Regel: Ort/Questdaten werden erst nach dem Kampf gelesen.
-- ============================================================

local ADDON_NAME, ns = ...
local L = ns.L

local RECORD_VERSION = 1
local ADDON_VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"

local Rec = { paused = false }
-- Kleine öffentliche Schnittstelle, damit Wegweiser "/ww route" weiterleiten kann
WegweiserRecorder = Rec

-- ------------------------------------------------------------
-- Grundgerüst: Chat-Ausgabe, Events, Kampf-Warteschlange
-- ------------------------------------------------------------

local PREFIX = "|cffffd100Wegweiser Recorder:|r "
local function Print(text, ...)
    if select("#", ...) > 0 then text = string.format(text, ...) end
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(text))
end

local frame = CreateFrame("Frame")
local handlers = {}
local function On(event, callback)
    if not handlers[event] then
        handlers[event] = {}
        frame:RegisterEvent(event)
    end
    table.insert(handlers[event], callback)
end
frame:SetScript("OnEvent", function(_, event, ...)
    for _, callback in ipairs(handlers[event] or {}) do
        securecallfunction(callback, event, ...)
    end
end)

local combatQueue = {}
local function InCombat() return InCombatLockdown() or UnitAffectingCombat("player") end
local function RunOutOfCombat(func)
    if not InCombat() then func() else table.insert(combatQueue, func) end
end
On("PLAYER_REGEN_ENABLED", function()
    local pending = combatQueue
    combatQueue = {}
    for _, func in ipairs(pending) do securecallfunction(func) end
end)

-- ------------------------------------------------------------
-- Hilfsfunktionen
-- ------------------------------------------------------------

-- Wert ist in Midnight/Forever evtl. ein "Geheimwert" (Kampf-Einschränkung)?
local function isSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

-- Aktuelle Karte und Position (Prozent, 1 Nachkommastelle)
local function where()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then
        local x, y = pos:GetXY()
        if x and y and not isSecret(x) then
            return mapID, math.floor(x * 1000 + 0.5) / 10, math.floor(y * 1000 + 0.5) / 10
        end
    end
    return mapID
end

-- NPC-ID und Name der Einheit ("npc" = gerade angesprochener NPC)
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
-- Aufzeichnung
-- ------------------------------------------------------------

-- Zufällige Charakter-Nummer (statt Name), einmal pro Charakter
local function charID()
    WegweiserRecorderChar = WegweiserRecorderChar or {}
    if not WegweiserRecorderChar.id then
        WegweiserRecorderChar.id = string.format("%04x%04x", math.random(0, 0xffff), math.random(0, 0xffff))
    end
    return WegweiserRecorderChar.id
end

function Rec:GetRecording()
    WegweiserRecorderDB = WegweiserRecorderDB or {}
    WegweiserRecorderDB.recordings = WegweiserRecorderDB.recordings or {}
    local id = charID()
    local rec = WegweiserRecorderDB.recordings[id]
    if not rec then
        local _, classFile = UnitClass("player")
        local _, raceFile = UnitRace("player")
        rec = {
            version    = RECORD_VERSION,
            class      = classFile,
            race       = raceFile,
            faction    = UnitFactionGroup("player"),
            locale     = GetLocale(),
            started    = date("%Y-%m-%d %H:%M"),
            startLevel = UnitLevel("player"),
            steps      = {},
        }
        WegweiserRecorderDB.recordings[id] = rec
    end
    return rec
end

function Rec:Add(stepType, data)
    if self.paused then return end
    local rec = self:GetRecording()
    local step = data or {}
    step.t   = stepType
    step.lvl = UnitLevel("player")
    step.at  = time()
    if not step.map then
        step.map, step.x, step.y = where()
    end
    table.insert(rec.steps, step)
    rec.lastLevel = step.lvl
    if WegweiserRecorderDB.verbose then
        Print(L.STEP, stepType, tostring(step.title or step.name or step.text or step.questID or step.level or ""))
    end
end

-- Übernahme der Daten, die Wegweiser 0.7 selbst aufgezeichnet hat
-- (WegweiserRouteDB, damals noch mit "Name-Realm" als Schlüssel)
local function migrateFromWegweiser()
    if type(WegweiserRouteDB) ~= "table" or type(WegweiserRouteDB.recordings) ~= "table" then return end
    local oldKey = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
    local old = WegweiserRouteDB.recordings[oldKey]
    if not old or old.migrated or not old.steps or #old.steps == 0 then return end
    local rec = Rec:GetRecording()
    local merged = {}
    for _, s in ipairs(old.steps) do table.insert(merged, s) end
    for _, s in ipairs(rec.steps) do table.insert(merged, s) end
    rec.steps = merged
    rec.started = old.started or rec.started
    rec.startLevel = old.startLevel or rec.startLevel
    old.migrated = true
    Print(L.MIGRATED, #old.steps)
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
        RunOutOfCombat(function()
            checkPending = false
            scanComplete(true)
        end)
    end)
end

-- ------------------------------------------------------------
-- Ereignisse
-- ------------------------------------------------------------

local recentlyTurnedIn = {}
local onTaxi = false

On("ADDON_LOADED", function(_, name)
    if name ~= ADDON_NAME then return end
    WegweiserRecorderDB = WegweiserRecorderDB or {}
    WegweiserRecorderDB.addonVersion = ADDON_VERSION
end)

On("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
    scanComplete(false)   -- Startzustand merken, nichts aufzeichnen
    if isInitialLogin or isReloadingUi then
        migrateFromWegweiser()
        if isInitialLogin then
            Rec:Add("SESSION", { build = select(2, GetBuildInfo()), addon = ADDON_VERSION })
        end
        local rec = Rec:GetRecording()
        C_Timer.After(4, function() Print(L.LOADED, #rec.steps) end)
    else
        Rec:Add("ZONE", { name = GetZoneText() })   -- Ladebildschirm (Dungeon, Kontinent)
    end
end)

On("QUEST_ACCEPTED", function(_, questID)
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

On("QUEST_TURNED_IN", function(_, questID, xp, money)
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

On("QUEST_REMOVED", function(_, questID)
    C_Timer.After(0.5, function()
        if recentlyTurnedIn[questID] then
            recentlyTurnedIn[questID] = nil
        else
            Rec:Add("ABANDON", { questID = questID, title = C_QuestLog.GetTitleForQuestID(questID) })
        end
        completeCache[questID] = nil
    end)
end)

On("QUEST_LOG_UPDATE", scheduleCompleteCheck)

On("PLAYER_LEVEL_UP", function(_, newLevel)
    C_Timer.After(0.2, function() Rec:Add("LEVEL", { level = newLevel }) end)
end)

On("ZONE_CHANGED_NEW_AREA", function()
    C_Timer.After(1, function()
        if not onTaxi then Rec:Add("ZONE", { name = GetZoneText() }) end
    end)
end)

On("PLAYER_CONTROL_LOST", function()
    C_Timer.After(0.5, function()
        if UnitOnTaxi("player") and not onTaxi then
            onTaxi = true
            Rec:Add("TAXI", { phase = "start", name = GetSubZoneText() or GetZoneText() })
        end
    end)
end)
On("PLAYER_CONTROL_GAINED", function()
    if onTaxi then
        onTaxi = false
        C_Timer.After(0.5, function()
            Rec:Add("TAXI", { phase = "end", name = GetSubZoneText() or GetZoneText() })
        end)
    end
end)

On("HEARTHSTONE_BOUND", function()
    Rec:Add("BIND", { name = GetBindLocation and GetBindLocation() })
end)

On("TRAINER_SHOW", function()
    Rec:Add("TRAINER", { npc = npcInfo("npc") })
end)

-- ------------------------------------------------------------
-- Befehle: /wwrec (und /ww route im Wegweiser-Addon)
-- ------------------------------------------------------------

function Rec:PrintStatus()
    local rec = self:GetRecording()
    Print(L.STATUS, self.paused and L.STATE_PAUSED or L.STATE_ON, #rec.steps, rec.started or "?",
        charID(), tostring(rec.race), tostring(rec.class))
    local counts = {}
    for _, s in ipairs(rec.steps) do counts[s.t] = (counts[s.t] or 0) + 1 end
    Print(L.COUNTS, counts.ACCEPT or 0, counts.TURNIN or 0, counts.COMPLETE or 0, counts.LEVEL or 0, counts.NOTE or 0)
    Print(L.LAST)
    for i = math.max(1, #rec.steps - 4), #rec.steps do
        local s = rec.steps[i]
        Print("   %d. %s %s (Lvl %s, %s %s)", i, s.t,
            tostring(s.title or s.name or s.text or s.level or s.build or ""),
            tostring(s.lvl), tostring(s.x), tostring(s.y))
    end
    Print(L.FILE_HINT)
    Print(L.HELP)
end

-- arg = erstes Wort (klein), rest = alles nach dem Befehl (Originalschreibweise)
function Rec:Command(arg, rest)
    if arg == "pause" then
        self.paused = true
        Print(L.PAUSED)
    elseif arg == "start" or arg == "weiter" then
        self.paused = false
        Print(L.RESUMED)
    elseif arg == "melden" or arg == "announce" then
        WegweiserRecorderDB.verbose = not WegweiserRecorderDB.verbose
        Print(WegweiserRecorderDB.verbose and L.VERBOSE_ON or L.VERBOSE_OFF)
    elseif arg == "notiz" or arg == "note" then
        local text = rest and rest:match("^%S+%s+(.+)$")
        if not text or text == "" then
            Print(L.NOTE_USAGE)
            return
        end
        local wasPaused = self.paused
        self.paused = false
        self:Add("NOTE", { text = text })
        self.paused = wasPaused
        Print(L.NOTE_SAVED, text)
    else
        self:PrintStatus()
    end
end

SLASH_WEGWEISERREC1 = "/wwrec"
SlashCmdList.WEGWEISERREC = function(msg)
    local rest = (msg or ""):match("^%s*(.-)%s*$")
    local arg = (rest:match("^(%S*)") or ""):lower()
    Rec:Command(arg, rest)
end
