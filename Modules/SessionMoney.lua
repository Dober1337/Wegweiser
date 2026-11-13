-- ============================================================
-- Modules/SessionMoney.lua
-- Gold-Bilanz der Sitzung unten links in der Tasche: "+2g 3s 7k" (grün)
-- oder "-80s 15k" (rot). Sitzung = seit dem Einloggen; ein /reload
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

-- 20307 -> "2g 3s 7k"  (Nullen weglassen, 0 -> "0k")
function SM:Format(copper)
    copper = math.abs(copper)
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
        update()
    end)
    ns:RegisterEvent("PLAYER_MONEY", update)
end

-- /ww gold – Bilanz im Chat, "/ww gold neu" startet die Zählung neu
function SM:Command(rest)
    if (rest or ""):lower():match("neu") or (rest or ""):lower():match("reset") then
        charData().sessionStart = GetMoney()
        ns:Print(L.SM_RESET)
        update()
        return
    end
    local delta = self:Delta() or 0
    local sign = delta > 0 and "+" or (delta < 0 and "-" or "±")
    ns:Print(L.SM_CHAT, sign .. self:Format(delta))
end
