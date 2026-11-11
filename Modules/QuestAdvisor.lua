-- ============================================================
-- Modules/QuestAdvisor.lua
-- Modul 3: Quest-Berater.
--
-- Bewertet jede Quest im Questlog nach Data/QuestRules.lua:
--   fertig / überspringen / Gruppe nötig / noch zu schwer / gut machbar /
--   lohnt sich gerade noch
--
-- Anzeige:
--   * Beim Questgeber (Questtext mit "Annehmen"-Knopf): Wegweiser-Kasten
--     unter dem Questfenster mit Bewertung – schon VOR dem Annehmen
--   * Questlog: kleines Symbol rechts, neben Blizzards Verfolgen-Häkchen
--     (nachträglicher Haken an Blizzards QuestLogQuests_Update; wir nutzen
--      nur einen freien Platz, Blizzards Texte und Symbole bleiben unverändert)
--   * Questlog-Tooltip – Zeile "Wegweiser: ..." beim Drüberfahren
--     (offizieller Haken: EventRegistry "QuestMapLogTitleButton.OnEnter")
--   * /ww quests       – Übersicht aller Quests, nach Bewertung sortiert
--   * Neue Quest angenommen -> kurze Bewertung im Chat
--   * Levelaufstieg -> Hinweis, wenn Quests grau oder machbar geworden sind
--
-- Questie: wird erkannt, falls installiert (keine Pflicht). Läuft in Forever
-- laut Spieler einwandfrei (Nov 2026). Dann weisen wir
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

-- Ruft eine API-Funktion geschützt auf (bei angebotenen, noch nicht
-- angenommenen Quests liefern manche Funktionen evtl. nichts oder Fehler).
local function safe(func, ...)
    if not func then return nil end
    local ok, result = pcall(func, ...)
    if ok then return result end
    return nil
end

-- Liefert Kategorie-Schlüssel (z. B. "GOOD") und eine Info-Tabelle.
-- Funktioniert für Quests im Questlog UND für angebotene Quests beim Questgeber.
function QA:Evaluate(questID)
    local r = rules()
    local q = { questID = questID }

    local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    local info = logIndex and C_QuestLog.GetInfo(logIndex)
    q.inLog = info ~= nil
    if info then
        q.title          = info.title
        q.level          = info.difficultyLevel or info.level
        q.suggestedGroup = info.suggestedGroup or 0
    else
        q.title          = safe(C_QuestLog.GetTitleForQuestID, questID)
        q.level          = safe(C_QuestLog.GetQuestDifficultyLevel, questID)
        q.suggestedGroup = safe(C_QuestLog.GetSuggestedGroupSize, questID) or 0
    end

    q.isComplete = q.inLog and (C_QuestLog.IsComplete(questID) or C_QuestLog.ReadyForTurnIn(questID))
    q.isElite    = safe(C_QuestLog.IsEliteQuest, questID)
    local tag    = safe(C_QuestLog.GetQuestTagInfo, questID)
    q.tagID      = tag and tag.tagID
    q.tagName    = tag and tag.tagName
    q.difficulty = safe(C_PlayerInfo.GetContentDifficultyQuestForPlayer, questID)
    -- Ersatz, falls das Spiel für eine angebotene Quest keine Schwierigkeit liefert
    if q.difficulty == nil and safe(C_QuestLog.IsQuestTrivial, questID) then
        q.difficulty = 0
    end

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
    -- Keine Schwierigkeit bekannt und nichts Besonderes: lieber nichts behaupten
    q.category = nil
    return nil, q
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
    local cat = key and rules().categories[key]
    if not cat then return end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Wegweiser: " .. L[cat.label], cat.color[1], cat.color[2], cat.color[3])
    GameTooltip:AddLine(L[cat.explain], 0.85, 0.85, 0.85, true)
    GameTooltip:Show()
end

-- ------------------------------------------------------------
-- Symbole im Questlog
-- ------------------------------------------------------------

local logIcons = setmetatable({}, { __mode = "k" })  -- Blizzard-Titelknopf -> unser Symbol
local decoratePending = false

function QA:DecorateQuestLog()
    for _, icon in pairs(logIcons) do icon:Hide() end
    if not settings().questAdvisor or not settings().questLogIcons then return end
    if not QuestScrollFrame or not QuestScrollFrame.titleFramePool then return end
    -- Regel: Frames nur außerhalb des Kampfes verändern -> nach dem Kampf nachholen
    if ns:InCombat() then
        if not decoratePending then
            decoratePending = true
            ns:RunOutOfCombat(function()
                decoratePending = false
                QA:DecorateQuestLog()
            end, true)
        end
        return
    end
    for button in QuestScrollFrame.titleFramePool:EnumerateActive() do
        local questID = button.questID
        local key = questID and self:Evaluate(questID)
        local cat = key and rules().categories[key]
        if cat and button.Text then
            local icon = logIcons[button]
            if not icon then
                icon = button:CreateTexture(nil, "OVERLAY")
                icon:SetSize(16, 16)
                logIcons[button] = icon
            end
            icon:ClearAllPoints()
            -- Rechts, direkt links neben Blizzards Verfolgen-Häkchen. Dort sitzt
            -- normalerweise das Questtyp-Symbol (TagTexture), das Forever aber
            -- nie zeigt (Questtyp steht als Text da) – der Platz ist also frei.
            -- Links neben dem Titel zeigt Forever eigene Symbole ("…", "?").
            if button.Checkbox then
                icon:SetPoint("RIGHT", button.Checkbox, "LEFT", -4, 0)
            else
                icon:SetPoint("TOPLEFT", button.Text, "TOPRIGHT", 4, 1)
            end
            icon:SetTexture(cat.icon)
            icon:Show()
        end
    end
end

-- ------------------------------------------------------------
-- Hinweis beim Questgeber (vor dem Annehmen)
-- ------------------------------------------------------------

local offerBox

local function createOfferBox()
    local box = CreateFrame("Frame", nil, QuestFrame, "BackdropTemplate")
    box:SetPoint("TOPLEFT", QuestFrame, "BOTTOMLEFT", 0, -2)
    box:SetPoint("TOPRIGHT", QuestFrame, "BOTTOMRIGHT", 0, -2)
    box:SetHeight(52)
    box:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    box:SetBackdropColor(0, 0, 0, 0.85)

    box.icon = box:CreateTexture(nil, "ARTWORK")
    box.icon:SetSize(18, 18)
    box.icon:SetPoint("TOPLEFT", 10, -9)

    box.title = box:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    box.title:SetPoint("LEFT", box.icon, "RIGHT", 6, 0)
    box.title:SetPoint("RIGHT", box, "RIGHT", -10, 0)
    box.title:SetJustifyH("LEFT")

    box.text = box:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    box.text:SetPoint("TOPLEFT", box.icon, "BOTTOMLEFT", 0, -4)
    box.text:SetPoint("RIGHT", box, "RIGHT", -10, 0)
    box.text:SetJustifyH("LEFT")
    box.text:SetWordWrap(true)
    box:Hide()
    return box
end

function QA:ShowOfferHint()
    if offerBox then offerBox:Hide() end
    if not settings().questAdvisor or not settings().questOfferHint then return end
    if not QuestFrame or not GetQuestID then return end
    local questID = GetQuestID()
    if not questID or questID == 0 then return end

    local key = self:Evaluate(questID)
    local cat = key and rules().categories[key]
    if not cat then return end

    offerBox = offerBox or createOfferBox()
    offerBox.icon:SetTexture(cat.icon)
    offerBox.title:SetText("Wegweiser: " .. L[cat.label])
    offerBox.title:SetTextColor(cat.color[1], cat.color[2], cat.color[3])
    offerBox.text:SetText(L[cat.explain])
    -- Höhe an den Text anpassen
    offerBox:SetHeight(36 + (offerBox.text:GetStringHeight() or 14))
    offerBox:Show()
end

-- /ww questinfo – Rohdaten der gerade angebotenen Quest (zum Prüfen im Spiel)
function QA:PrintOfferDebug()
    local questID = GetQuestID and GetQuestID()
    if not questID or questID == 0 then
        ns:Print(L.QA_DEBUG_NO_OFFER)
        return
    end
    local key, q = self:Evaluate(questID)
    ns:Print("questID=%s, Titel=%s, im Log=%s", tostring(questID), tostring(q.title), tostring(q.inLog))
    ns:Print("Level=%s, Schwierigkeit=%s (0 grau,1 grün,2 gelb,3 orange,4 rot)", tostring(q.level), tostring(q.difficulty))
    ns:Print("Elite=%s, Tag=%s, Gruppe=%s, Bewertung=%s", tostring(q.isElite), tostring(q.tagID), tostring(q.suggestedGroup), tostring(key))
end

function QA:HideOfferHint()
    if offerBox then offerBox:Hide() end
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

    -- Questlog: nach jedem Neuaufbau der Liste unsere Symbole setzen.
    -- hooksecurefunc = nachträglicher Haken; Blizzards Funktion läuft unverändert.
    if QuestLogQuests_Update then
        hooksecurefunc("QuestLogQuests_Update", function() QA:DecorateQuestLog() end)
    end

    -- Questgeber: Questtext mit "Annehmen" wird angezeigt
    ns:RegisterEvent("QUEST_DETAIL", function()
        -- kurz warten, bis das Spiel die Questdaten bereitgestellt hat
        C_Timer.After(0.1, function()
            ns:RunOutOfCombat(function() QA:ShowOfferHint() end, true)
        end)
    end)
    -- Andere Questfenster-Seiten oder Schließen -> Kasten weg
    for _, event in ipairs({ "QUEST_FINISHED", "QUEST_PROGRESS", "QUEST_COMPLETE",
                             "QUEST_GREETING", "GOSSIP_SHOW", "GOSSIP_CLOSED" }) do
        ns:RegisterEvent(event, function() QA:HideOfferHint() end)
    end

    ns:RegisterEvent("QUEST_ACCEPTED", function(_, questID)
        if not settings().questAdvisor or not settings().questAcceptHint then return end
        -- Questdaten sind manchmal erst einen Moment später vollständig
        C_Timer.After(0.5, function()
            QA:HideOfferHint()
            local key, q = QA:Evaluate(questID)
            local cat = key and rules().categories[key]
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
