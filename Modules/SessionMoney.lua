-- ============================================================
-- Modules/SessionMoney.lua
-- Gold-Bilanz der Sitzung unten links in der Tasche: "+" (grün) oder
-- "-" (rot) mit den Münzsymbolen des Spiels. Sitzung = seit dem Einloggen; ein /reload
-- zählt weiter (Startwert pro Charakter gespeichert).
--
-- Geprüft im Forever-UI-Quellcode (Blizzard_UIPanels_Game/Mainline/
-- ContainerFrame.xml/.lua): ContainerFrameCombinedBags.MoneyFrame und
-- ContainerFrame1.MoneyFrame (einzelne Taschen) liegen unten in der Tasche
-- über die ganze Breite, das Gold steht rechts – links ist Platz.
-- GetMoney, PLAYER_MONEY, PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi).
-- ============================================================

local _, ns = ...
local L = ns.L

local SM = {}
ns.modules.SessionMoney = SM

local labels = {}

local function enabled()
    return ns.db and ns.db.settings.sessionMoney
end

local function charData()
    local key = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
    ns.db.chars = ns.db.chars or {}
    ns.db.chars[key] = ns.db.chars[key] or {}
    return ns.db.chars[key]
end

-- 20307 -> Münzsymbole aus dem Spiel (wie Blizzards Goldanzeige).
-- Ersatz ohne die Funktion: "2g 3s 7k" (Nullen weglassen).
function SM:Format(copper)
    copper = math.abs(copper)
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        return C_CurrencyInfo.GetCoinTextureString(copper)
    end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local parts = {}
    if g > 0 then table.insert(parts, g .. L.SM_G) end
    if s > 0 then table.insert(parts, s .. L.SM_S) end
    if c > 0 or #parts == 0 then table.insert(parts, c .. L.SM_C) end
    return table.concat(parts, " ")
end

function SM:Delta()
    local start = charData().sessionStart
    if not start then return nil end
    return GetMoney() - start
end

-- "+1g 2s" grün / "-3s" rot / "±0"
function SM:Signed(delta)
    if not delta then return "|cff999999–|r" end
    if delta > 0 then return "|cff40ff40+" .. self:Format(delta) .. "|r" end
    if delta < 0 then return "|cffff4040-" .. self:Format(delta) .. "|r" end
    return "|cffbbbbbb±0|r"
end

-- Stand des Charakters merken (für Tag, Gesamt und "alle Charaktere")
local function remember()
    local data = charData()
    local money = GetMoney()
    local today = date("%Y-%m-%d")
    data.money = money
    data.name = UnitName("player")
    data.realm = GetRealmName()
    data.class = select(2, UnitClass("player"))
    data.faction = UnitFactionGroup("player")
    if data.dayDate ~= today then data.dayDate, data.dayStart = today, money end
    if not data.trackStart then data.trackStart, data.trackDate = money, today end
end

-- Alle Charaktere dieses Realms (gemerkt, sobald man sich einmal mit ihnen einloggt)
function SM:Characters()
    local list, total = {}, 0
    local realm = GetRealmName()
    for _, c in pairs(ns.db.chars or {}) do
        if c.money and c.name and c.realm == realm then
            table.insert(list, c)
            total = total + c.money
        end
    end
    table.sort(list, function(a, b) return a.money > b.money end)
    return list, total
end

-- "2026-11-16" -> "16.11.2026" (deutsch) bzw. unverändert
local function showDate(iso)
    if not iso then return "?" end
    if ns.locale ~= "deDE" then return iso end
    local y, m, d = iso:match("(%d+)-(%d+)-(%d+)")
    return y and (d .. "." .. m .. "." .. y) or iso
end

function SM:FillTooltip(tt)
    local data = charData()
    local money = GetMoney()
    tt:AddLine(L.SM_TT_TITLE, 1, 0.82, 0)
    tt:AddDoubleLine(L.SM_TT_SESSION, self:Signed(self:Delta()), 1, 1, 1)
    tt:AddDoubleLine(L.SM_TT_TODAY, self:Signed(data.dayStart and (money - data.dayStart)), 1, 1, 1)
    tt:AddDoubleLine(string.format(L.SM_TT_SINCE, showDate(data.trackDate)),
        self:Signed(data.trackStart and (money - data.trackStart)), 1, 1, 1)
    local list, total = self:Characters()
    if #list > 1 then
        tt:AddLine(" ")
        tt:AddLine(string.format(L.SM_TT_CHARS, GetRealmName() or ""), 1, 0.82, 0)
        for _, c in ipairs(list) do
            local col = RAID_CLASS_COLORS and c.class and RAID_CLASS_COLORS[c.class]
            local r, g, b = 1, 1, 1
            if col then r, g, b = col.r, col.g, col.b end
            tt:AddDoubleLine(c.name, self:Format(c.money), r, g, b, 1, 1, 1)
        end
        tt:AddDoubleLine(L.SM_TT_TOTAL, self:Format(total), 1, 0.82, 0, 1, 1, 1)
    end
end

local function update()
    local show = enabled()
    local delta = show and SM:Delta()
    local text
    if delta then
        if delta > 0 then
            text = "|cff40ff40+" .. SM:Format(delta) .. "|r"
        elseif delta < 0 then
            text = "|cffff4040-" .. SM:Format(delta) .. "|r"
        else
            text = "|cffbbbbbb±0|r"
        end
        text = L.SM_LABEL .. " " .. text
    end
    for _, fs in ipairs(labels) do
        fs:SetText(text or "")
        fs:SetShown(text ~= nil)
        if fs.hover then
            fs.hover:SetWidth(math.max((fs:GetStringWidth() or 0) + 4, 10))
            fs.hover:SetShown(text ~= nil)
        end
    end
end

local function attach(moneyFrame)
    if not moneyFrame then return end
    local holder = CreateFrame("Frame", nil, moneyFrame)
    holder:SetAllPoints(moneyFrame)
    holder:SetFrameLevel(moneyFrame:GetFrameLevel() + 2)
    local fs = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", moneyFrame, "LEFT", 6, 0)
    fs:SetJustifyH("LEFT")
    -- Maus-Fläche nur über unserem Text (Blizzards Goldanzeige rechts bleibt frei)
    local hover = CreateFrame("Frame", nil, holder)
    hover:SetPoint("LEFT", fs, "LEFT", -2, 0)
    hover:SetHeight(16)
    hover:EnableMouse(true)
    hover:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        SM:FillTooltip(GameTooltip)
        GameTooltip:Show()
    end)
    hover:SetScript("OnLeave", function() GameTooltip:Hide() end)
    fs.hover = hover
    table.insert(labels, fs)
    moneyFrame:HookScript("OnShow", update)
end

function SM:OnInitialize()
    attach(ContainerFrameCombinedBags and ContainerFrameCombinedBags.MoneyFrame)
    attach(ContainerFrame1 and ContainerFrame1.MoneyFrame)

    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
        local data = charData()
        -- Neues Einloggen = neue Sitzung; /reload und Ladebildschirme zählen weiter
        if isInitialLogin or not data.sessionStart then
            data.sessionStart = GetMoney()
        end
        remember()
        update()
    end)
    ns:RegisterEvent("PLAYER_MONEY", function() remember(); update() end)
end

-- /ww gold – Bilanz im Chat, "/ww gold neu" startet die Zählung neu
function SM:Command(rest)
    if (rest or ""):lower():match("neu") or (rest or ""):lower():match("reset") then
        charData().sessionStart = GetMoney()
        ns:Print(L.SM_RESET)
        update()
        return
    end
    remember()
    local data, money = charData(), GetMoney()
    ns:Print(L.SM_CHAT, self:Signed(self:Delta() or 0))
    ns:Print("   " .. L.SM_TT_TODAY .. ": " .. self:Signed(data.dayStart and (money - data.dayStart)))
    ns:Print("   " .. string.format(L.SM_TT_SINCE, showDate(data.trackDate)) .. ": "
        .. self:Signed(data.trackStart and (money - data.trackStart)))
    local list, total = self:Characters()
    if #list > 1 then
        ns:Print("   " .. string.format(L.SM_TT_CHARS, GetRealmName() or "") .. " " .. self:Format(total))
    end
end
