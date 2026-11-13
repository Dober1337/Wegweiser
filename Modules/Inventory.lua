-- ============================================================
-- Modules/Inventory.lua
-- Taschen, Reparatur und graue Gegenstände – Alltagshilfe für Einsteiger:
--   * Hinweis, wenn die Taschen fast voll sind.
--   * Hinweis, wenn die Ausrüstung stark beschädigt oder kaputt ist.
--   * Beim Händler: kleiner Kasten mit "Graues verkaufen" und "Reparieren"
--     (nur auf Knopfdruck – es wird nichts automatisch verkauft).
--
-- Keine eigenen Spieldaten: alles kommt aus dem Spiel. Geprüft im
-- Forever-UI-Quellcode: C_Container.GetContainerNumFreeSlots /
-- GetContainerNumSlots / GetContainerItemInfo / UseContainerItem,
-- GetInventoryItemDurability (Camelot/PaperDollFrame.lua),
-- CanMerchantRepair / GetRepairAllCost (Mainline/MerchantFrame.lua),
-- RepairAllItems, C_CurrencyInfo.GetCoinTextureString, NUM_BAG_SLOTS.
-- Alles nur außerhalb des Kampfes.
-- ============================================================

local _, ns = ...
local L = ns.L

local Inv = {}
ns.modules.Inventory = Inv

local BAGS_LOW, BAGS_OK = 3, 6          -- Warnen bei <= 3 freien Plätzen, wieder scharf ab 6
local DUR_LOW, DUR_OK = 0.25, 0.5       -- Warnen unter 25 %, wieder scharf über 50 %

local warned = { bags = false, full = false, dur = false, broken = false }

local function setting(key) return ns.db and ns.db.settings[key] end

local function money(copper)
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        return C_CurrencyInfo.GetCoinTextureString(copper)
    end
    return tostring(copper)
end

-- ------------------------------------------------------------
-- Taschen
-- ------------------------------------------------------------

local function lastBag()
    return NUM_BAG_SLOTS or 4
end

-- Freie Plätze in normalen Taschen (Spezialtaschen wie Kräutertaschen zählen nicht)
function Inv:FreeSlots()
    local free = 0
    for bag = 0, lastBag() do
        local n, family = C_Container.GetContainerNumFreeSlots(bag)
        if n and (family == nil or family == 0) then free = free + n end
    end
    return free
end

function Inv:CheckBags()
    if not setting("invHints") then return end
    local free = self:FreeSlots()
    if free == 0 then
        if not warned.full then
            warned.full, warned.bags = true, true
            ns:Notify(L.INV_BAGS_FULL)
            ns:Print("   " .. L.INV_BAGS_TIP)
        end
    elseif free <= BAGS_LOW then
        if not warned.bags then
            warned.bags = true
            ns:Notify(L.INV_BAGS_LOW, free)
            ns:Print("   " .. L.INV_BAGS_TIP)
        end
    elseif free >= BAGS_OK then
        warned.bags, warned.full = false, false
    end
end

-- ------------------------------------------------------------
-- Haltbarkeit
-- ------------------------------------------------------------

function Inv:Durability()
    local lowest, broken = 1, 0
    for slot = 1, 19 do
        local cur, max = GetInventoryItemDurability(slot)
        if cur and max and max > 0 then
            local pct = cur / max
            if pct < lowest then lowest = pct end
            if cur == 0 then broken = broken + 1 end
        end
    end
    return lowest, broken
end

function Inv:CheckDurability()
    if not setting("invHints") then return end
    local lowest, broken = self:Durability()
    if broken > 0 then
        if not warned.broken then
            warned.broken, warned.dur = true, true
            ns:Notify(L.INV_DUR_BROKEN, broken)
            ns:Print("   " .. L.INV_DUR_TIP)
        end
    elseif lowest < DUR_LOW then
        if not warned.dur then
            warned.dur = true
            ns:Notify(L.INV_DUR_LOW, math.floor(lowest * 100 + 0.5))
            ns:Print("   " .. L.INV_DUR_TIP)
        end
    elseif lowest > DUR_OK then
        warned.dur, warned.broken = false, false
    end
end

-- ------------------------------------------------------------
-- Händler
-- ------------------------------------------------------------

-- Graue Gegenstände in den Taschen: Liste { bag, slot, value }
function Inv:GreyItems()
    local list, total, unknown = {}, 0, false
    local POOR = Enum and Enum.ItemQuality and Enum.ItemQuality.Poor or 0
    for bag = 0, lastBag() do
        for slot = 1, (C_Container.GetContainerNumSlots(bag) or 0) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == POOR and not info.hasNoValue and not info.isLocked then
                local price = select(11, C_Item.GetItemInfo(info.itemID))
                if price then
                    total = total + price * (info.stackCount or 1)
                else
                    unknown = true
                end
                table.insert(list, { bag = bag, slot = slot })
            end
        end
    end
    return list, total, unknown
end

local box, selling

local function updateBox()
    if not box or not box:IsShown() then return end
    local list, total, unknown = Inv:GreyItems()
    if #list > 0 then
        box.greyText:SetText(string.format(L.INV_GREY_LINE, #list, money(total) .. (unknown and " +" or "")))
        box.sellBtn:Enable()
    else
        box.greyText:SetText(L.INV_GREY_NONE)
        box.sellBtn:Disable()
    end

    local cost, canRepair = 0, false
    if CanMerchantRepair and CanMerchantRepair() then
        cost, canRepair = GetRepairAllCost()
    end
    if not (CanMerchantRepair and CanMerchantRepair()) then
        box.repairText:SetText(L.INV_REPAIR_NOTHERE)
        box.repairBtn:Disable()
    elseif canRepair and cost and cost > 0 then
        box.repairText:SetText(string.format(L.INV_REPAIR_LINE, money(cost)))
        box.repairBtn:SetEnabled(GetMoney() >= cost)
    else
        box.repairText:SetText(L.INV_REPAIR_NONE)
        box.repairBtn:Disable()
    end
end

function Inv:SellGrey()
    if selling or ns:InCombat() then return end
    local list, total, unknown = self:GreyItems()
    if #list == 0 then return end
    selling = true
    local i = 0
    local function step()
        i = i + 1
        local item = list[i]
        if not item or not (MerchantFrame and MerchantFrame:IsShown()) or ns:InCombat() then
            selling = false
            ns:Print(L.INV_SOLD, i - 1, money(total) .. (unknown and " +" or ""))
            C_Timer.After(0.3, updateBox)
            return
        end
        C_Container.UseContainerItem(item.bag, item.slot)
        C_Timer.After(0.15, step)
    end
    step()
end

function Inv:Repair()
    if ns:InCombat() or not (CanMerchantRepair and CanMerchantRepair()) then return end
    local cost, canRepair = GetRepairAllCost()
    if not canRepair or not cost or cost == 0 then return end
    if GetMoney() < cost then ns:Print(L.INV_REPAIR_NOMONEY) return end
    RepairAllItems()
    ns:Print(L.INV_REPAIRED, money(cost))
    C_Timer.After(0.3, updateBox)
end

local function makeButton(parent, text, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(120, 22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function createBox()
    box = CreateFrame("Frame", nil, MerchantFrame, "BackdropTemplate")
    box:SetSize(MerchantFrame:GetWidth(), 62)
    box:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    box:SetBackdropColor(0, 0, 0, 0.88)

    box.sellBtn = makeButton(box, L.INV_SELL_BTN, function() Inv:SellGrey() end)
    box.sellBtn:SetPoint("TOPRIGHT", box, "TOPRIGHT", -8, -7)
    box.greyText = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    box.greyText:SetPoint("LEFT", box, "TOPLEFT", 10, -18)
    box.greyText:SetPoint("RIGHT", box.sellBtn, "LEFT", -6, 0)
    box.greyText:SetJustifyH("LEFT")

    box.repairBtn = makeButton(box, L.INV_REPAIR_BTN, function() Inv:Repair() end)
    box.repairBtn:SetPoint("TOPRIGHT", box.sellBtn, "BOTTOMRIGHT", 0, -4)
    box.repairText = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    box.repairText:SetPoint("LEFT", box, "TOPLEFT", 10, -44)
    box.repairText:SetPoint("RIGHT", box.repairBtn, "LEFT", -6, 0)
    box.repairText:SetJustifyH("LEFT")
end

-- Unter die Reiter "Händler"/"Rückkauf" setzen: die hängen in Forever unter
-- dem Fenster heraus (im Spiel gesehen). Abstand wird beim Öffnen gemessen.
local function placeBox()
    local dy = -2
    local tab = MerchantFrameTab1
    if tab and tab:IsShown() and tab:GetBottom() and MerchantFrame:GetBottom() then
        local below = MerchantFrame:GetBottom() - tab:GetBottom()
        if below > 0 then dy = -(below + 2) end
    end
    box:ClearAllPoints()
    box:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMLEFT", 0, dy)
end

local function onMerchantShow()
    if not setting("merchantHelper") or not MerchantFrame then
        if box then box:Hide() end
        return
    end
    if not box then createBox() end
    box:Show()
    placeBox()
    C_Timer.After(0, placeBox)   -- nach dem ersten Zeichnen stimmen die Positionen sicher
    updateBox()
    -- Preise kommen evtl. erst nach dem Laden der Gegenstandsdaten
    C_Timer.After(0.5, updateBox)
end

-- ------------------------------------------------------------

function Inv:OnInitialize()
    local pending = false
    ns:RegisterEvent("BAG_UPDATE_DELAYED", function()
        if pending then return end
        pending = true
        C_Timer.After(1, function()
            pending = false
            ns:RunOutOfCombat(function() Inv:CheckBags(); updateBox() end, true)
        end)
    end)
    ns:RegisterEvent("UPDATE_INVENTORY_DURABILITY", function()
        C_Timer.After(1, function()
            ns:RunOutOfCombat(function() Inv:CheckDurability(); updateBox() end, true)
        end)
    end)
    ns:RegisterEvent("MERCHANT_SHOW", function()
        ns:RunOutOfCombat(onMerchantShow, true)
    end)
    ns:RegisterEvent("MERCHANT_CLOSED", function()
        selling = false
        if box then box:Hide() end
    end)
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        C_Timer.After(8, function()
            ns:RunOutOfCombat(function() Inv:CheckBags(); Inv:CheckDurability() end, true)
        end)
    end)
end
