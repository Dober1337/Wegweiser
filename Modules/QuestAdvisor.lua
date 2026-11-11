-- ============================================================
-- Modules/QuestAdvisor.lua
-- Modul 3: Quest-Berater.
--
-- Bewertet jede Quest im Questlog nach Data/QuestRules.lua:
--   fertig / überspringen / Gruppe nötig / noch zu schwer / gut machbar /
--   lohnt sich gerade noch
--
-- Anzeige:
--   * /ww quests       – Übersicht aller Quests, nach Bewertung sortiert
--   * Questlog-Tooltip – Zeile "Wegweiser: ..." beim Drüberfahren
--     (offizieller Haken: EventRegistry "QuestMapLogTitleButton.OnEnter")
--   * Neue Quest angenommen -> kurze Bewertung im Chat
--   * Levelaufstieg -> Hinweis, wenn Quests grau oder machbar geworden sind
--
-- Questie: wird erkannt, falls installiert (keine Pflicht). Dann weisen wir
-- auf dessen Karten-Markierungen hin. Questies interne Daten nutzen wir
-- (noch) nicht – das kommt erst mit der Routenplanung.
-- ============================================================

local _, ns = ...
local L = ns.L

local QA = {}
ns.modules.QuestAdvisor = QA

local function settings()
    return ns.db and ns.db.settings or ns.defaults.settings
end

local function rules() return ns.QuestRules end

-- Farbcode für Chat-Texte, z. B. "|cffffd100"
local function colorCode(c)
    return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end

function QA:HasQuestie()
    return C_AddOns.IsAddOnLoaded("Questie")
end

-- ------------------------------------------------------------
-- Bewertung einer Quest
-- ------------------------------------------------------------

-- Liefert Kategorie-Schlüssel (z. B. "GOOD") und eine Info-Tabelle.
function QA:Evaluate(questID)
    local r = rules()
    local q = { questID = questID }

    local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    local info = logIndex and C_QuestLog.GetInfo(logIndex)
    if info then
        q.title          = info.title
        q.level          = info.difficultyLevel or info.level
        q.suggestedGroup = info.suggestedGroup or 0
    else
        q.title = C_QuestLog.GetTitleForQuestID(questID)
    end

    q.isComplete = C_QuestLog.IsComplete(questID) or C_QuestLog.ReadyForTurnIn(questID)
    q.isElite    = C_QuestLog.IsEliteQuest and C_QuestLog.IsEliteQuest(questID)
    local tag    = C_QuestLog.GetQuestTagInfo(questID)
    q.tagID      = tag and tag.tagID
    q.tagName    = tag and tag.tagName
    q.difficulty = C_PlayerInfo.GetContentDifficultyQuestForPlayer(questID)

    -- Welche Kategorien treffen zu?
    local matches = {}
    matches.DONE  = q.isComplete
    matches.GROUP = q.isElite
        or (q.tagID and r.groupTags[q.tagID])
        or ((q.suggestedGroup or 0) >= r.minSuggestedGroup.value)
    local byColor = q.difficulty and r.difficulty[q.difficulty]
    if byColor then matches[byColor] = true end

    for _, key in ipairs(r.order) do
        if matches[key] then
            q.category = key
            return key, q
        end
    end
    q.category = byColor or "GOOD"
    return q.category, q
end

-- Alle Quests im Log (ohne Überschriften und versteckte Einträge)
function QA:GetAllQuests()
    local list = {}
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and not info.isHidden and info.questID and info.questID > 0 then
            local _, q = self:Evaluate(info.questID)
            table.insert(list, q)
        end
    end
    return list
end

-- Kurzer Text "[12] Questname"
local function questLabel(q)
    return string.format("[%s%s] %s", tostring(q.level or "?"), q.isElite and "+" or "", q.title or "?")
end

-- ------------------------------------------------------------
-- /ww quests
-- ------------------------------------------------------------

function QA:PrintOverview()
    local r = rules()
    local quests = self:GetAllQuests()
    if #quests == 0 then
        ns:Print(L.QA_EMPTY)
        return
    end
    ns:Print(L.QA_HEADER, #quests)
    -- Nach Kategorie gruppiert, in sinnvoller Reihenfolge
    local displayOrder = { "DONE", "GOOD", "STILL_WORTH", "GROUP", "TOO_HARD", "SKIP" }
    for _, key in ipairs(displayOrder) do
        local cat = r.categories[key]
        local inCat = {}
        for _, q in ipairs(quests) do
            if q.category == key then table.insert(inCat, q) end
        end
        if #inCat > 0 then
            table.sort(inCat, function(a, b) return (a.level or 0) < (b.level or 0) end)
            ns:Print("%s%s (%d)|r – %s", colorCode(cat.color), L[cat.label], #inCat, L[cat.explain])
            for _, q in ipairs(inCat) do
                ns:Print("   " .. questLabel(q))
            end
        end
    end
    ns:Print(self:HasQuestie() and L.QA_QUESTIE_YES or L.QA_QUESTIE_NO)
end

-- ------------------------------------------------------------
-- Tooltip im Questlog
-- ------------------------------------------------------------

local function onQuestLogEnter(_, button, questID)
    if not settings().questAdvisor then return end
    questID = questID or (button and button.questID)
    if not questID or not GameTooltip:IsOwned(button) then return end
    local key = QA:Evaluate(questID)
    local cat = rules().categories[key]
    if not cat then return end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Wegweiser: " .. L[cat.label], cat.color[1], cat.color[2], cat.color[3])
    GameTooltip:AddLine(L[cat.explain], 0.85, 0.85, 0.85, true)
    GameTooltip:Show()
end

-- ------------------------------------------------------------
-- Ereignisse: neue Quest, Levelaufstieg
-- ------------------------------------------------------------

-- Merkt sich die Kategorien, um Änderungen beim Levelaufstieg zu erkennen
local lastCategory = {}

local function snapshot()
    wipe(lastCategory)
    for _, q in ipairs(QA:GetAllQuests()) do
        lastCategory[q.questID] = q.category
    end
end

function QA:OnLevelUp()
    local nowGrey, nowDoable = {}, {}
    for _, q in ipairs(self:GetAllQuests()) do
        local before = lastCategory[q.questID]
        if before and before ~= q.category then
            if q.category == "SKIP" then
                table.insert(nowGrey, q)
            elseif before == "TOO_HARD" and (q.category == "GOOD" or q.category == "STILL_WORTH") then
                table.insert(nowDoable, q)
            end
        end
    end
    for _, q in ipairs(nowDoable) do ns:Print(L.QA_NOW_DOABLE, questLabel(q)) end
    for _, q in ipairs(nowGrey) do ns:Print(L.QA_NOW_GREY, questLabel(q)) end
    snapshot()
end

function QA:OnInitialize()
    if EventRegistry then
        EventRegistry:RegisterCallback("QuestMapLogTitleButton.OnEnter", onQuestLogEnter, QA)
    end

    ns:RegisterEvent("QUEST_ACCEPTED", function(_, questID)
        if not settings().questAdvisor or not settings().questAcceptHint then return end
        -- Questdaten sind manchmal erst einen Moment später vollständig
        C_Timer.After(0.5, function()
            local key, q = QA:Evaluate(questID)
            local cat = rules().categories[key]
            if cat and q.title then
                ns:Print(L.QA_ACCEPTED, questLabel(q), colorCode(cat.color) .. L[cat.label] .. "|r")
            end
            lastCategory[questID] = key
        end)
    end)

    ns:RegisterEvent("PLAYER_LEVEL_UP", function()
        if not settings().questAdvisor then return end
        -- Schwierigkeiten werden nach dem Levelaufstieg neu berechnet -> kurz warten
        C_Timer.After(2.5, function()
            ns:RunOutOfCombat(function() QA:OnLevelUp() end, true)
        end)
    end)

    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        C_Timer.After(3, snapshot)
    end)
end
