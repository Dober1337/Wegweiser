-- ============================================================
-- Modules/XPTracker.lua
-- Kleines verschiebbares Fenster: Erfahrung pro Stunde und Zeit bis zum
-- nächsten Level. Ein- und ausschalten mit /ww xp oder in /ww config.
--
--   Zeile 1: "XP/h: 12.4k"
--   Zeile 2: "Level 23 in: 1 Std. 12 Min."
--   Tooltip: XP dieser Sitzung, Dauer, erholte XP, Bedienung.
--
-- Gerechnet wird über die ganze Sitzung (seit dem Einloggen, /reload zählt
-- weiter). Pausen (AFK, Stadt) drücken den Schnitt – Rechtsklick setzt zurück.
--
-- Geprüft im Forever-UI-Quellcode: UnitXP, UnitXPMax, GetXPExhaustion,
-- IsXPUserDisabled, PLAYER_XP_UPDATE (Blizzard_StatusTrackingBar/ExpBar.lua),
-- GameRulesUtil.IsPlayerAtEffectiveMaxLevel (Blizzard_SharedXML/GameRulesUtil.lua).
-- ============================================================

local _, ns = ...
local L = ns.L

local XT = {}
ns.modules.XPTracker = XT

local frame, ticker

local function enabled() return ns.db and ns.db.settings.xpTracker end

local function charData()
    local key = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
    ns.db.chars = ns.db.chars or {}
    ns.db.chars[key] = ns.db.chars[key] or {}
    return ns.db.chars[key]
end

local function atMaxLevel()
    if GameRulesUtil and GameRulesUtil.IsPlayerAtEffectiveMaxLevel then
        local ok, r = pcall(GameRulesUtil.IsPlayerAtEffectiveMaxLevel)
        if ok then return r end
    end
    return UnitLevel("player") >= 60
end

local function xpDisabled()
    return atMaxLevel() or (IsXPUserDisabled and IsXPUserDisabled())
end

-- 12345 -> "12.3k" (deutsch "12,3k")
local function short(n)
    local s
    if n >= 1000000 then s = string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then s = string.format("%.1fk", n / 1000)
    else s = tostring(math.floor(n)) end
    if ns.locale == "deDE" then s = s:gsub("%.", ",") end
    return s
end

local function duration(sec)
    sec = math.max(0, math.floor(sec))
    local h, m = math.floor(sec / 3600), math.floor((sec % 3600) / 60)
    if h > 0 then return string.format(L.XT_HM, h, m) end
    return string.format(L.XT_M, math.max(m, sec > 0 and 1 or 0))
end

-- ------------------------------------------------------------
-- Zählen
-- ------------------------------------------------------------

local function session()
    local d = charData()
    d.xpSession = d.xpSession or {}
    return d.xpSession
end

function XT:Reset()
    local s = session()
    s.start = time()
    s.gained = 0
    s.lastXP, s.lastMax, s.lastLevel = UnitXP("player"), UnitXPMax("player"), UnitLevel("player")
end

local function onXP()
    local s = session()
    if not s.start then XT:Reset() return end
    local cur, max, level = UnitXP("player"), UnitXPMax("player"), UnitLevel("player")
    local diff
    if level == s.lastLevel then
        diff = cur - (s.lastXP or cur)
    elseif level > (s.lastLevel or level) then
        -- Levelaufstieg: Rest des alten Levels + was schon im neuen steht
        diff = math.max(0, (s.lastMax or 0) - (s.lastXP or 0)) + cur
    else
        diff = 0
    end
    if diff > 0 then s.gained = (s.gained or 0) + diff end
    s.lastXP, s.lastMax, s.lastLevel = cur, max, level
end

-- Rückgabe: XP pro Stunde, Sekunden bis Level (nil, wenn noch nichts verdient)
function XT:Rate()
    local s = session()
    local elapsed = time() - (s.start or time())
    if elapsed < 60 or (s.gained or 0) <= 0 then return nil, nil end
    local perHour = s.gained / elapsed * 3600
    local left = UnitXPMax("player") - UnitXP("player")
    return perHour, left / perHour * 3600
end

-- ------------------------------------------------------------
-- Fenster
-- ------------------------------------------------------------

local function update()
    if not frame or not frame:IsShown() then return end
    local perHour, toLevel = XT:Rate()
    if perHour then
        frame.line1:SetText(string.format(L.XT_RATE, short(perHour)))
        frame.line2:SetText(string.format(L.XT_TOLEVEL, UnitLevel("player") + 1, duration(toLevel)))
    else
        frame.line1:SetText(string.format(L.XT_RATE, "–"))
        frame.line2:SetText(L.XT_WAITING)
    end
    local w = math.max(frame.line1:GetStringWidth(), frame.line2:GetStringWidth()) + 20
    frame:SetWidth(math.max(w, 120))
end

local function fillTooltip(tt)
    local s = session()
    tt:AddLine(L.XT_TT_TITLE, 1, 0.82, 0)
    tt:AddDoubleLine(L.XT_TT_GAINED, short(s.gained or 0), 1, 1, 1, 1, 1, 1)
    tt:AddDoubleLine(L.XT_TT_TIME, duration(time() - (s.start or time())), 1, 1, 1, 1, 1, 1)
    tt:AddDoubleLine(L.XT_TT_LEFT, short(UnitXPMax("player") - UnitXP("player")), 1, 1, 1, 1, 1, 1)
    local rested = GetXPExhaustion and GetXPExhaustion()
    if rested and rested > 0 then
        tt:AddDoubleLine(L.XT_TT_RESTED, short(rested), 1, 1, 1, 0.4, 0.6, 1)
    end
    tt:AddLine(" ")
    tt:AddLine(L.XT_TT_HELP, 0.7, 0.7, 0.7, true)
end

local function createFrame()
    if frame then return end
    frame = CreateFrame("Frame", "WegweiserXPFrame", UIParent, "BackdropTemplate")
    frame:SetSize(140, 40)
    frame:SetFrameStrata("MEDIUM")
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(0, 0, 0, 0.7)
        frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.9)
    end
    frame.line1 = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.line1:SetPoint("TOPLEFT", 10, -8)
    frame.line2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.line2:SetPoint("TOPLEFT", frame.line1, "BOTTOMLEFT", 0, -3)

    -- Verschieben mit gedrückter linker Maustaste, Position merken
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        ns.db.xpFramePos = { point, relPoint, x, y }
    end)
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            XT:Reset()
            ns:Print(L.XT_RESET)
            update()
        end
    end)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        fillTooltip(GameTooltip)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local p = ns.db.xpFramePos
    if p then
        frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
    end
    frame:Hide()
end

-- Fenster passend zur Einstellung zeigen oder verstecken (nur außerhalb des Kampfes)
function XT:Refresh()
    ns:RunOutOfCombat(function()
        local show = enabled() and not xpDisabled()
        if show then createFrame() end
        if frame then frame:SetShown(show) end
        if ticker then ticker:Cancel(); ticker = nil end
        if show then
            update()
            ticker = C_Timer.NewTicker and C_Timer.NewTicker(5, update)
        end
    end, true)
end

-- /ww xp        -> ein/aus
-- /ww xp neu    -> Sitzung neu starten
function XT:Command(rest)
    rest = (rest or ""):lower()
    if rest:match("neu") or rest:match("reset") then
        self:Reset(); ns:Print(L.XT_RESET); update()
        return
    end
    if xpDisabled() then ns:Print(L.XT_MAXLEVEL) return end
    ns.db.settings.xpTracker = not ns.db.settings.xpTracker
    ns:Print(ns.db.settings.xpTracker and L.XT_ON or L.XT_OFF)
    self:Refresh()
end

function XT:OnInitialize()
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin)
        -- Neues Einloggen = neue Sitzung; /reload zählt weiter
        if isInitialLogin or not session().start then XT:Reset() else onXP() end
        XT:Refresh()
    end)
    ns:RegisterEvent("PLAYER_XP_UPDATE", function() onXP(); update() end)
    ns:RegisterEvent("PLAYER_LEVEL_UP", function()
        C_Timer.After(1, function() onXP(); XT:Refresh() end)
    end)
    -- Häkchen in /ww config wirkt sofort
    if Settings and Settings.SetOnValueChangedCallback then
        Settings.SetOnValueChangedCallback("Wegweiser_xpTracker", function()
            C_Timer.After(0, function() XT:Refresh() end)
        end)
    end
end
