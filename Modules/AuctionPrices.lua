-- ============================================================
-- Modules/AuctionPrices.lua
-- Auktionshauspreise im Tooltip.
--
--   * Am Auktionshaus: Knopf "Wegweiser: Preise scannen" (über dem Fenster).
--     Fragt einmal das ganze Auktionshaus ab (C_AuctionHouse.ReplicateItems,
--     laut Blizzard höchstens alle 15 Minuten) und merkt sich pro Gegenstand den
--     günstigsten Sofortkaufpreis pro Stück.
--   * Nebenbei: Jede normale Suche im Auktionshaus aktualisiert die Preise der
--     gefundenen Gegenstände (C_AuctionHouse.GetBrowseResults, minPrice).
--   * Tooltip jedes Gegenstands: "Auktionshaus: 1g 20s pro Stück (vor 2 Std.)".
--   * Ist Auctionator oder TradeSkillMaster geladen, zeigt Wegweiser keine eigene
--     Zeile – die zeigen ihre Preise selbst.
--
-- Geprüft im Forever-UI-Quellcode: Forever nutzt Blizzards modernes Auktionshaus
-- (Blizzard_AuctionHouseUI, Camelot-Dateien); C_AuctionHouse.ReplicateItems,
-- GetNumReplicateItems, GetReplicateItemInfo (buyoutPrice, count, itemID),
-- GetBrowseResults (itemKey.itemID, minPrice), Ereignisse REPLICATE_ITEM_LIST_UPDATE,
-- AUCTION_HOUSE_BROWSE_RESULTS_UPDATED, AUCTION_HOUSE_SHOW/CLOSED.
-- Preise gelten pro Realm und Fraktion; gespeichert in WegweiserDB.ahPrices.
-- ============================================================

local _, ns = ...
local L = ns.L

local AP = {}
ns.modules.AuctionPrices = AP

local SCAN_COOLDOWN = 15 * 60
local CHUNK = 2000          -- Einträge pro Bild (Spiel soll nicht stocken)

local button, scanning, processing, ticker

local function setting() return ns.db and ns.db.settings.ahPrices end
local function isSecret(v) return issecretvalue and issecretvalue(v) end

local function otherAddon()
    if not (C_AddOns and C_AddOns.IsAddOnLoaded) then return false end
    return C_AddOns.IsAddOnLoaded("Auctionator") or C_AddOns.IsAddOnLoaded("TradeSkillMaster")
end

local function store()
    local key = (GetRealmName() or "?") .. "-" .. (UnitFactionGroup("player") or "?")
    ns.db.ahPrices = ns.db.ahPrices or {}
    ns.db.ahPrices[key] = ns.db.ahPrices[key] or { items = {} }
    return ns.db.ahPrices[key]
end

local function money(copper)
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        return C_CurrencyInfo.GetCoinTextureString(copper)
    end
    return tostring(copper)
end

local function ago(t)
    local d = time() - (t or 0)
    if d < 3600 then return string.format(L.AP_MIN, math.max(1, math.floor(d / 60))) end
    if d < 86400 then return string.format(L.AP_HOURS, math.floor(d / 3600)) end
    return string.format(L.AP_DAYS, math.floor(d / 86400))
end

-- ------------------------------------------------------------
-- Vollständiger Scan
-- ------------------------------------------------------------

local function setButtonState()
    if not button then return end
    local s = store()
    local left = (s.lastRequest or 0) + SCAN_COOLDOWN - time()
    if scanning then
        button:SetText(L.AP_SCANNING); button:Disable()
    elseif left > 0 then
        button:SetText(string.format(L.AP_WAIT, math.ceil(left / 60))); button:Disable()
    else
        button:SetText(L.AP_SCAN); button:Enable()
    end
end

local function processReplicate()
    if processing then return end
    processing = true
    local n = C_AuctionHouse.GetNumReplicateItems() or 0
    local fresh, i = {}, 0
    local function step()
        if not scanning then processing = false return end
        local last = math.min(i + CHUNK, n - 1)
        for idx = i, last do
            local info = { C_AuctionHouse.GetReplicateItemInfo(idx) }
            local count, buyout, itemID = info[3], info[10], info[17]
            if itemID and buyout and count and buyout > 0 and count > 0
               and not isSecret(itemID) and not isSecret(buyout) then
                local unit = math.floor(buyout / count)
                if not fresh[itemID] or unit < fresh[itemID] then fresh[itemID] = unit end
            end
        end
        i = last + 1
        if i < n then
            C_Timer.After(0, step)
        else
            local s, now, count = store(), time(), 0
            for id, p in pairs(fresh) do s.items[id] = { p = p, t = now }; count = count + 1 end
            s.lastScan = now
            scanning, processing = false, false
            ns:Print(L.AP_DONE, count, n)
            setButtonState()
        end
    end
    step()
end

function AP:Scan(auto)
    if scanning or not (C_AuctionHouse and C_AuctionHouse.ReplicateItems) then return end
    local s = store()
    if ((s.lastRequest or 0) + SCAN_COOLDOWN) > time() then setButtonState() return end
    s.lastRequest = time()
    scanning = true
    setButtonState()
    ns:Print(auto and L.AP_START_AUTO or L.AP_START)
    C_AuctionHouse.ReplicateItems()
end

-- ------------------------------------------------------------
-- Nebenbei: Suchergebnisse merken
-- ------------------------------------------------------------

local function onBrowse()
    if not (C_AuctionHouse and C_AuctionHouse.GetBrowseResults) then return end
    local ok, results = pcall(C_AuctionHouse.GetBrowseResults)
    if not ok or type(results) ~= "table" then return end
    local s, now = store(), time()
    for _, r in ipairs(results) do
        local id = r.itemKey and r.itemKey.itemID
        local p = r.minPrice
        if id and p and p > 0 and not isSecret(id) and not isSecret(p) then
            s.items[id] = { p = p, t = now }
        end
    end
end

-- ------------------------------------------------------------
-- Tooltip
-- ------------------------------------------------------------

local function onTooltip(tooltip, data)
    if not setting() or otherAddon() or not data or not data.id or isSecret(data.id) then return end
    local e = store().items[data.id]
    if not e then return end
    tooltip:AddDoubleLine(L.AP_TT, money(e.p) .. " |cff999999" .. string.format(L.AP_TT_AGE, ago(e.t)) .. "|r",
        0.4, 0.8, 1.0, 1, 1, 1)
end

-- /ww ah – Stand der gespeicherten Preise
function AP:Command()
    local s, n = store(), 0
    for _ in pairs(s.items) do n = n + 1 end
    if otherAddon() then ns:Print(L.AP_OTHER) end
    if n == 0 then ns:Print(L.AP_NONE) return end
    ns:Print(L.AP_STATUS, n, s.lastScan and ago(s.lastScan) or L.AP_NEVER)
end

-- ------------------------------------------------------------

local function createButton()
    if button or not AuctionHouseFrame then return end
    button = CreateFrame("Button", nil, AuctionHouseFrame, "UIPanelButtonTemplate")
    button:SetSize(200, 22)
    button:SetPoint("BOTTOMRIGHT", AuctionHouseFrame, "TOPRIGHT", -8, 2)
    button:SetScript("OnClick", function() AP:Scan() end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Wegweiser", 1, 0.82, 0)
        GameTooltip:AddLine(L.AP_BTN_TT, 1, 1, 1, true)
        local s = store()
        if s.lastScan then GameTooltip:AddLine(string.format(L.AP_LAST, ago(s.lastScan)), 0.7, 0.7, 0.7) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function AP:OnInitialize()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType
       and Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onTooltip)
    end
    ns:RegisterEvent("AUCTION_HOUSE_SHOW", function()
        if not setting() then
            if button then button:Hide() end
            return
        end
        createButton()
        if button then button:SetShown(not otherAddon()); setButtonState() end
        if otherAddon() then return end
        -- Automatik (wie bei Auctionator): beim Öffnen scannen, wenn die
        -- 15 Minuten um sind, und solange das Fenster offen ist alle 15 Minuten
        -- erneut. Geht nur am Auktionator – ohne offenes Auktionshaus liefert der
        -- Server keine Daten. ReplicateItems ist laut API-Doku ohne
        -- Einschränkung (kein Klick nötig).
        local function tick()
            setButtonState()
            if ns.db.settings.ahAutoScan and not scanning then AP:Scan(true) end
        end
        C_Timer.After(2, tick)
        if ticker then ticker:Cancel() end
        ticker = C_Timer.NewTicker and C_Timer.NewTicker(30, tick)
    end)
    ns:RegisterEvent("AUCTION_HOUSE_CLOSED", function()
        if ticker then ticker:Cancel(); ticker = nil end
        if scanning then scanning = false; ns:Print(L.AP_ABORT) end
    end)
    ns:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE", function()
        if scanning then processReplicate() end
    end)
    ns:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", function()
        if setting() then onBrowse() end
    end)
end
