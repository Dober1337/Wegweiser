-- ============================================================
-- Modules/DungeonFinder.lua
-- "Welcher Dungeon passt zu meiner Stufe?"
--
--   * Eigener Seitenreiter im Gruppenfinder ("Suche nach Gruppe") unter Blizzards
--     drei Reitern. Er zeigt alle Dungeons mit Stufenbereich: passt jetzt (grün),
--     bald (gelb), noch zu hoch / schon zu niedrig (grau).
--   * Beim Levelaufstieg: Hinweis, wenn ein Dungeon neu in deinen Bereich kommt.
--   * /ww dungeons im Chat.
--
-- Keine eigenen Spieldaten: Name und empfohlener Stufenbereich kommen aus
-- Blizzards Gruppenfinder (C_LFGList.GetAvailableActivities(2) – Kategorie 2 =
-- Dungeons – und GetActivityInfoTable: minLevelSuggestion/maxLevelSuggestion).
-- Dieselben Werte nutzt Blizzard selbst als Stufenfilter im Gruppenfinder
-- (Blizzard_GroupFinder_VanillaStyle/Blizzard_LFGVanilla_ParentFrame.lua).
-- Fensteraufbau geprüft im Forever-UI-Quellcode: LFGParentFrame mit den
-- Seitenreitern ListingTab / BrowsingTab / WhoListingTab
-- (LargeSideTabButtonTemplate, SidePanelTabButtonMixin).
-- Wir verändern Blizzards Fenster nicht: unser Kasten legt sich nur darüber.
-- ============================================================

local _, ns = ...
local L = ns.L

local DF = {}
ns.modules.DungeonFinder = DF

local DUNGEON_CATEGORY = 2       -- LFGLISTING_DUNGEON_CATEGORY_ID (LFGVanilla_Constants.lua)
local SOON = 3                   -- "bald": bis zu 3 Stufen unter dem Mindestwert

local tab, panel

local function setting(key) return ns.db and ns.db.settings[key] end

local function isSecret(v) return issecretvalue and issecretvalue(v) end

-- Alle Dungeons: { name, min, max } sortiert nach Mindeststufe
function DF:GetDungeons()
    if not (C_LFGList and C_LFGList.GetAvailableActivities and C_LFGList.GetActivityInfoTable) then return nil end
    local ok, ids = pcall(C_LFGList.GetAvailableActivities, DUNGEON_CATEGORY, nil, 0)
    if not ok or type(ids) ~= "table" then return nil end
    local list, seen = {}, {}
    for _, id in ipairs(ids) do
        local info = C_LFGList.GetActivityInfoTable(id)
        if info and info.fullName and not isSecret(info.fullName) and not seen[info.fullName] then
            seen[info.fullName] = true
            local lo = info.minLevelSuggestion or 0
            local hi = info.maxLevelSuggestion or 0
            if lo == 0 then lo = info.minLevel or 0 end
            table.insert(list, { name = info.fullName, min = lo, max = hi })
        end
    end
    table.sort(list, function(a, b)
        if a.min ~= b.min then return a.min < b.min end
        return a.name < b.name
    end)
    return list
end

-- "now" | "soon" | "later" | "past"
local function state(d, level)
    if d.min > 0 and level < d.min then
        return (d.min - level <= SOON) and "soon" or "later"
    end
    if d.max > 0 and level > d.max then return "past" end
    return "now"
end

local COLORS = {
    now   = { 0.3, 1, 0.3 },
    soon  = { 1, 0.82, 0 },
    later = { 0.55, 0.55, 0.55 },
    past  = { 0.45, 0.45, 0.45 },
}

local function rangeText(d)
    if d.max > 0 then return string.format("%d–%d", d.min, d.max) end
    return string.format(L.DF_FROM, d.min)
end

-- ------------------------------------------------------------
-- Chat: /ww dungeons
-- ------------------------------------------------------------
function DF:Command()
    local list = self:GetDungeons()
    if not list or #list == 0 then ns:Print(L.DF_NODATA) return end
    local level = UnitLevel("player")
    local now, soon = {}, {}
    for _, d in ipairs(list) do
        local st = state(d, level)
        if st == "now" then table.insert(now, d) elseif st == "soon" then table.insert(soon, d) end
    end
    ns:Print(L.DF_HEADER, level)
    if #now == 0 then ns:Print("   " .. L.DF_NONE_NOW) end
    for _, d in ipairs(now) do ns:Print("   |cff55ff55%s|r (%s)", d.name, rangeText(d)) end
    for _, d in ipairs(soon) do ns:Print("   |cffffd100" .. L.DF_SOON_LINE .. "|r", d.name, rangeText(d)) end
    ns:Print("|cff999999" .. L.DF_SOURCE .. "|r")
end

-- Levelaufstieg: Dungeon kommt neu in den Bereich
function DF:LevelHint(level)
    if not setting("dungeonHint") then return end
    local list = self:GetDungeons()
    if not list then return end
    local new = {}
    for _, d in ipairs(list) do
        if d.min == level then table.insert(new, d.name .. " (" .. rangeText(d) .. ")") end
    end
    if #new > 0 then
        ns:Print(L.DF_NEW, table.concat(new, ", "))
    end
end

-- ------------------------------------------------------------
-- Kasten im Gruppenfinder
-- ------------------------------------------------------------

local ROW_H = 16

local function fillPanel()
    if not panel then return end
    local list = DF:GetDungeons() or {}
    local level = UnitLevel("player")
    panel.title:SetText(string.format(L.DF_HEADER, level))
    for _, row in ipairs(panel.rows) do row:Hide() end
    if #list == 0 then
        panel.empty:Show()
        panel.content:SetHeight(1)
        return
    end
    panel.empty:Hide()
    -- Reihenfolge: passt jetzt, bald, später, schon zu niedrig
    local order = { now = 1, soon = 2, later = 3, past = 4 }
    local sorted = {}
    for _, d in ipairs(list) do
        d._st = state(d, level)
        table.insert(sorted, d)
    end
    table.sort(sorted, function(a, b)
        if order[a._st] ~= order[b._st] then return order[a._st] < order[b._st] end
        if a.min ~= b.min then return a.min < b.min end
        return a.name < b.name
    end)
    local lastSt
    local y, i = 0, 0
    for _, d in ipairs(sorted) do
        i = i + 1
        local row = panel.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, panel.content)
            row:SetHeight(ROW_H)
            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.name:SetPoint("LEFT", 6, 0)
            row.name:SetJustifyH("LEFT")
            row.range = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.range:SetPoint("RIGHT", -6, 0)
            row.head = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.head:SetPoint("LEFT", 2, 0)
            panel.rows[i] = row
        end
        row:ClearAllPoints()
        if d._st ~= lastSt then
            -- Zwischenüberschrift
            y = y + (lastSt and 6 or 0)
            lastSt = d._st
            row:SetPoint("TOPLEFT", 0, -y)
            row:SetPoint("RIGHT", panel.content, "RIGHT", 0, 0)
            row.head:SetText(L["DF_SECTION_" .. d._st:upper()])
            row.head:Show(); row.name:Hide(); row.range:Hide()
            row:Show()
            y = y + ROW_H
            i = i + 1
            row = panel.rows[i]
            if not row then
                row = CreateFrame("Frame", nil, panel.content)
                row:SetHeight(ROW_H)
                row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.name:SetPoint("LEFT", 6, 0)
                row.name:SetJustifyH("LEFT")
                row.range = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.range:SetPoint("RIGHT", -6, 0)
                row.head = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.head:SetPoint("LEFT", 2, 0)
                panel.rows[i] = row
            end
            row:ClearAllPoints()
        end
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", panel.content, "RIGHT", 0, 0)
        local c = COLORS[d._st]
        row.head:Hide()
        row.name:SetText(d.name); row.name:SetTextColor(c[1], c[2], c[3]); row.name:Show()
        row.range:SetText(rangeText(d)); row.range:SetTextColor(c[1], c[2], c[3]); row.range:Show()
        row:Show()
        y = y + ROW_H
    end
    panel.content:SetHeight(math.max(y, 1))
end

local function blizzTabs()
    local f = LFGParentFrame
    return { f.ListingTab, f.BrowsingTab, f.WhoListingTab }
end

local function showPanel(show)
    if not panel then return end
    panel:SetShown(show)
    if tab then tab:SetChecked(show) end
    if show then
        for _, t in ipairs(blizzTabs()) do if t and t.SetChecked then t:SetChecked(false) end end
        fillPanel()
    else
        -- Blizzards Reiter-Markierung selbst wiederherstellen (keine Blizzard-Funktion
        -- aufrufen, damit der Gruppenfinder nicht "verunreinigt" wird)
        local sel = LFGParentFrame and LFGParentFrame.selectedTab or 1
        for i, t in ipairs(blizzTabs()) do if t and t.SetChecked then t:SetChecked(i == sel) end end
    end
end

local function setup()
    if tab or not LFGParentFrame or not LFGParentFrame.WhoListingTab then return end
    if not setting("dungeonTab") then return end
    local parent = LFGParentFrame

    -- Seitenreiter wie Blizzards eigene
    tab = CreateFrame("Frame", nil, parent, "LargeSideTabButtonTemplate")
    tab:SetPoint("TOPLEFT", parent.WhoListingTab, "BOTTOMLEFT", 0, -2)
    tab.tooltipText = L.DF_TAB
    tab.Icon:SetTexture("Interface\\ICONS\\INV_Misc_Map_01")
    tab.Icon:SetSize(30, 30)
    tab.Icon:SetTexCoord(0.03125, 0.96875, 0.03125, 0.96875)
    tab:SetChecked(false)
    tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
        if button == "LeftButton" and upInside then showPanel(not panel:IsShown()) end
    end)

    -- Kasten über dem Fensterinhalt
    panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -60)
    panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 30)
    panel:SetFrameLevel(parent:GetFrameLevel() + 50)
    panel:EnableMouse(true)
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    panel:SetBackdropColor(0.05, 0.05, 0.05, 0.97)
    panel:Hide()

    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panel.title:SetPoint("TOPLEFT", 12, -10)
    panel.legend = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.legend:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -4)
    panel.legend:SetPoint("RIGHT", panel, "RIGHT", -12, 0)
    panel.legend:SetJustifyH("LEFT")
    panel.legend:SetText(L.DF_LEGEND)

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel.legend, "BOTTOMLEFT", 0, -8)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 26)
    panel.content = CreateFrame("Frame", nil, scroll)
    panel.content:SetSize(1, 1)
    scroll:SetScrollChild(panel.content)
    scroll:SetScript("OnSizeChanged", function(self, w) panel.content:SetWidth(w) end)
    panel.rows = {}

    panel.empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.empty:SetPoint("CENTER")
    panel.empty:SetWidth(300)
    panel.empty:SetText(L.DF_NODATA)
    panel.empty:Hide()

    panel.source = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.source:SetPoint("BOTTOMLEFT", 12, 9)
    panel.source:SetText(L.DF_SOURCE)

    -- Blizzards Reiter: unseren Kasten schließen
    for _, t in ipairs(blizzTabs()) do
        if t then t:HookScript("OnMouseUp", function() if panel:IsShown() then showPanel(false) end end) end
    end
    parent:HookScript("OnHide", function() if panel:IsShown() then panel:Hide(); tab:SetChecked(false) end end)
end

function DF:OnInitialize()
    if LFGParentFrame then setup() end
    ns:RegisterEvent("ADDON_LOADED", function(_, name)
        if name == "Blizzard_GroupFinder_VanillaStyle" then
            C_Timer.After(0, setup)
        end
    end)
    ns:RegisterEvent("PLAYER_LEVEL_UP", function(_, level)
        C_Timer.After(6, function()
            ns:RunOutOfCombat(function() DF:LevelHint(tonumber(level) or UnitLevel("player")) end, true)
        end)
    end)
    ns:RegisterEvent("LFG_LIST_AVAILABILITY_UPDATE", function()
        if panel and panel:IsShown() then fillPanel() end
    end)
end
