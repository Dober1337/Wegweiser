-- ============================================================
-- Modules/TalentHighlight.lua
-- Modul 5b: Markierungen direkt im Blizzard-Talentfenster.
--
--   * Talent, das JETZT dran ist (freier Punkt vorhanden):
--       pulsierender goldener Rahmen + Tooltip "Wegweiser: jetzt skillen – ..."
--   * Talente, die später im Build kommen: kleine Markierung mit Ziel-Rang ("» 3/5")
--   * Talente, die schon wie geplant verteilt sind: kleines Häkchen
--   * Abweichende Punkte: gelber Hinweis im Tooltip, kein Zwang
--
-- Technik (geprüft im Forever-UI-Quellcode, Build 1.60.1.70888):
--   * Das Talentfenster ist PlayerSpellsFrame.TalentsFrame aus dem Blizzard-Addon
--     "Blizzard_PlayerSpells". Es wird erst beim ersten Öffnen geladen –
--     deshalb setzen wir unsere Haken erst, wenn es geladen ist.
--   * TalentsFrame:GetTalentButtonByNodeID(nodeID) liefert den Knopf eines Talents.
--   * Blizzard meldet fertige Tooltips über EventRegistry
--     ("TalentDisplay.TooltipCreated") – dort hängen wir unsere Zeile an.
--   * Wir verändern KEINE Blizzard-Funktionen. Wir legen nur eigene, nicht
--     anklickbare Rahmen über die Knöpfe. Alles nur außerhalb des Kampfes.
-- ============================================================

local _, ns = ...
local L = ns.L

local Highlight = {}
ns.modules.TalentHighlight = Highlight

local GOLD = { 1.0, 0.82, 0.0 }
local CHECK_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-Ready"

local overlays = setmetatable({}, { __mode = "k" })  -- Knopf -> unser Rahmen
local nodeState = {}      -- nodeID -> Infos für Markierung und Tooltip
local talentsFrame        -- PlayerSpellsFrame.TalentsFrame, sobald geladen
local refreshPending = false

local function settings()
    return ns.db and ns.db.settings or ns.defaults.settings
end

local function isEnabled()
    return settings().talentGuide and settings().talentHighlight
end

-- ------------------------------------------------------------
-- Unser Rahmen über einem Talent-Knopf
-- ------------------------------------------------------------

local function createOverlay(button)
    local o = CreateFrame("Frame", nil, button)
    o:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
    o:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -4)
    o:SetFrameLevel(button:GetFrameLevel() + 10)
    -- Wichtig: Maus geht durch unseren Rahmen hindurch auf den Blizzard-Knopf.
    o:EnableMouse(false)

    -- Goldener Rahmen aus vier Kanten (je 3 Pixel dick)
    local glow = CreateFrame("Frame", nil, o)
    glow:SetAllPoints()
    local function edge(p1, p2, w, h)
        local t = glow:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
        t:SetPoint(p1)
        t:SetPoint(p2)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    edge("TOPLEFT", "TOPRIGHT", nil, 3)
    edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 3)
    edge("TOPLEFT", "BOTTOMLEFT", 3, nil)
    edge("TOPRIGHT", "BOTTOMRIGHT", 3, nil)
    -- Pulsieren, damit es auffällt
    local anim = glow:CreateAnimationGroup()
    anim:SetLooping("BOUNCE")
    local fade = anim:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0.35)
    fade:SetDuration(0.7)
    o.glow, o.glowAnim = glow, anim

    -- Ziel-Rang für spätere Punkte, z. B. "» 3/5"
    local target = o:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    target:SetPoint("BOTTOM", o, "TOP", 0, 0)
    target:SetTextColor(0.75, 0.85, 1.0)
    target:SetShadowOffset(1, -1)
    o.target = target

    -- Häkchen für erledigte Talente
    local check = o:CreateTexture(nil, "OVERLAY")
    check:SetTexture(CHECK_TEXTURE)
    check:SetSize(16, 16)
    check:SetPoint("TOPRIGHT", o, "TOPRIGHT", 4, 4)
    o.check = check

    return o
end

local function hideOverlay(o)
    o.glowAnim:Stop()
    o.glow:Hide()
    o.target:Hide()
    o.check:Hide()
    o:Hide()
end

local function hideAll()
    for _, o in pairs(overlays) do hideOverlay(o) end
end

local function getOverlay(button)
    local o = overlays[button]
    if not o then
        o = createOverlay(button)
        overlays[button] = o
    end
    return o
end

-- ------------------------------------------------------------
-- Berechnen, welches Talent welchen Zustand hat
-- ------------------------------------------------------------

-- Füllt nodeState neu. Rückgabe: true, wenn etwas anzuzeigen ist.
local function computeStates()
    wipe(nodeState)
    local guide = ns.modules.TalentGuide
    local build, tree = guide:Load()
    if not build then return false end
    if #guide:Validate(build, tree) > 0 then return false end  -- Warnung kommt schon beim Einloggen

    local points = guide:ExpandPoints(build)
    local progress = guide:GetProgress(build, tree)
    local _, unspent = ns.TalentAPI:GetPoints()
    unspent = unspent or 0

    -- Für jedes Talent im Build: nächster offener Punkt und Endrang
    for _, p in ipairs(points) do
        local nodeID = p.step.nodeID
        local live = tree.byNode[nodeID]
        local have = live and live.rank or 0
        local s = nodeState[nodeID]
        if not s then
            s = { have = have, want = build._finalRanks[nodeID], maxRank = p.step.maxRank }
            nodeState[nodeID] = s
        end
        if not s.nextPoint and have < p.targetRank then
            s.nextPoint = p
        end
    end
    for nodeID, s in pairs(nodeState) do
        if progress.nextPoint and progress.nextPoint.step.nodeID == nodeID and unspent > 0 then
            s.state = "NOW"
        elseif s.have >= s.want then
            s.state = "DONE"
        else
            s.state = "LATER"
        end
        if s.state ~= "NOW" and s.nextPoint and progress.nextPoint == s.nextPoint then
            s.isNextButNoPoint = true   -- ist als Nächstes dran, aber noch kein freier Punkt
        end
    end
    -- Abweichungen (Punkte, die der Build so nicht vorsieht) – nur für den Tooltip
    for _, d in ipairs(progress.deviations) do
        local s = nodeState[d.live.nodeID] or { have = d.have, want = d.want, maxRank = d.live.maxRank }
        s.deviation = true
        s.state = s.state or "NONE"
        nodeState[d.live.nodeID] = s
    end
    return true
end

-- ------------------------------------------------------------
-- Markierungen zeichnen
-- ------------------------------------------------------------

local function frameUsable()
    if not talentsFrame or not talentsFrame:IsShown() then return false end
    -- Nur eigene, aktive Talente markieren (nicht beim Betrachten anderer
    -- Spieler und nicht auf dem Reiter der inaktiven Zweitspezialisierung).
    if talentsFrame.IsInspecting and talentsFrame:IsInspecting() then return false end
    if talentsFrame.IsActiveTabSelected and not talentsFrame:IsActiveTabSelected() then return false end
    return true
end

function Highlight:Refresh()
    refreshPending = false
    hideAll()
    if not isEnabled() or not frameUsable() then return end
    if ns:InCombat() then
        ns:RunOutOfCombat(function() Highlight:Refresh() end, true)
        return
    end
    if not computeStates() then return end

    for nodeID, s in pairs(nodeState) do
        local button = talentsFrame:GetTalentButtonByNodeID(nodeID)
        if button and button:IsShown() and s.state ~= "NONE" then
            local o = getOverlay(button)
            o:Show()
            if s.state == "NOW" then
                o.glow:Show()
                o.glowAnim:Play()
            elseif s.state == "DONE" then
                o.check:Show()
            elseif s.state == "LATER" then
                o.target:SetText(string.format("» %d/%d", s.want, s.maxRank))
                o.target:Show()
            end
        end
    end
end

-- Mehrere Ereignisse kurz hintereinander -> nur einmal neu zeichnen
function Highlight:ScheduleRefresh()
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(0.15, function() Highlight:Refresh() end)
end

-- ------------------------------------------------------------
-- Tooltip-Zeile
-- ------------------------------------------------------------

local function onTooltip(_, button, tooltip)
    if not isEnabled() or not frameUsable() then return end
    if not button or not button.GetNodeID or not tooltip then return end
    local s = nodeState[button:GetNodeID()]
    if not s then return end
    local loc = ns.modules.TalentGuide.Loc

    tooltip:AddLine(" ")
    if s.state == "NOW" then
        local reason = s.nextPoint and loc(s.nextPoint.step.reason) or ""
        tooltip:AddLine(string.format(L.HL_TT_NOW, reason), GOLD[1], GOLD[2], GOLD[3], true)
    elseif s.state == "DONE" and not s.deviation then
        tooltip:AddLine(L.HL_TT_DONE, 0.3, 1.0, 0.3, true)
    elseif s.state == "LATER" and s.nextPoint then
        local text = s.isNextButNoPoint and L.HL_TT_NEXT or L.HL_TT_LATER
        tooltip:AddLine(string.format(text, s.want, s.maxRank, s.nextPoint.level), 0.75, 0.85, 1.0, true)
        tooltip:AddLine(loc(s.nextPoint.step.reason), 0.8, 0.8, 0.8, true)
    end
    if s.deviation then
        tooltip:AddLine(string.format(L.HL_TT_DEVIATION, s.want or 0, s.have or 0), 1.0, 1.0, 0.0, true)
    end
    tooltip:Show()   -- Größe des Tooltips an die neuen Zeilen anpassen
end

-- ------------------------------------------------------------
-- Einrichten, sobald das Talentfenster geladen ist
-- ------------------------------------------------------------

local function setup()
    if talentsFrame then return end
    talentsFrame = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    if not talentsFrame or not talentsFrame.GetTalentButtonByNodeID then
        talentsFrame = nil
        return
    end
    -- Nachträgliche Haken: Blizzards eigener Code läuft unverändert zuerst.
    talentsFrame:HookScript("OnShow", function() Highlight:ScheduleRefresh() end)
    talentsFrame:HookScript("OnHide", hideAll)
    if EventRegistry then
        EventRegistry:RegisterCallback("TalentDisplay.TooltipCreated", onTooltip, Highlight)
    end
    Highlight:ScheduleRefresh()
end

function Highlight:OnInitialize()
    if C_AddOns.IsAddOnLoaded("Blizzard_PlayerSpells") then
        setup()
    end
    ns:RegisterEvent("ADDON_LOADED", function(_, name)
        if name == "Blizzard_PlayerSpells" then setup() end
    end)
    -- Talente oder Punkte haben sich geändert -> neu zeichnen
    for _, event in ipairs({ "TRAIT_NODE_CHANGED", "TRAIT_CONFIG_UPDATED",
                             "TRAIT_TREE_CURRENCY_INFO_UPDATED", "PLAYER_LEVEL_UP" }) do
        ns:RegisterEvent(event, function()
            if talentsFrame and talentsFrame:IsShown() then Highlight:ScheduleRefresh() end
        end)
    end
end
