-- ============================================================
-- Modules/Travel.lua
-- Reise-Hilfen für Einsteiger:
--   * Flugpunkte: Hinweis beim Betreten einer Zone, wenn es dort einen
--     Flugpunkt deiner Fraktion gibt, den du noch nicht entdeckt hast.
--     /ww flug zeigt sie und setzt einen Wegpunkt zum nächsten.
--   * Ruhestein: /ww ruhestein zeigt, wo er gebunden ist; dieselbe Zeile
--     steht im Tooltip des Ruhesteins; Bestätigung nach dem Binden.
--
-- Keine eigenen Spieldaten: Flugpunkte (Name, Position, entdeckt ja/nein,
-- Fraktion) liefert das Spiel selbst über C_TaxiMap.GetTaxiNodesForMap –
-- dieselbe Quelle, die Blizzards Weltkarte für die Flugpunkt-Symbole nutzt.
-- Geprüft im Forever-UI-Quellcode (Branch "forever", Nov 2026):
--   C_TaxiMap.GetTaxiNodesForMap / ShouldMapShowTaxiNodes,
--   Enum.FlightPathFaction, MapTaxiNodeInfo.isUndiscovered,
--   GetBindLocation, C_Container.PlayerHasHearthstone, HEARTHSTONE_BOUND,
--   TooltipDataProcessor.AddTooltipPostCall.
-- OB Forever die Flugpunkte für die alten Zonen tatsächlich befüllt, ist
-- noch NICHT im Spiel bestätigt -> /ww flug zeigt es (sonst Hinweis).
-- ============================================================

local _, ns = ...
local L = ns.L

local Travel = {}
ns.modules.Travel = Travel

local hintedZones = {}   -- pro Sitzung: Zone schon gemeldet?

local function enabled()
    return ns.db and ns.db.settings.travelHints
end

local function isSecret(v)
    return issecretvalue and issecretvalue(v)
end

-- ------------------------------------------------------------
-- Flugpunkte
-- ------------------------------------------------------------

-- Gleiche Fraktions-Regel wie Blizzards FlightPointDataProvider
local function nodeForMyFaction(node)
    local faction = UnitFactionGroup("player")
    local FPF = Enum and Enum.FlightPathFaction
    if not FPF then return true end
    if node.faction == FPF.Horde then return faction == "Horde" end
    if node.faction == FPF.Alliance then return faction == "Alliance" end
    return true
end

-- Liefert: alle Flugpunkte der Zone (eigene Fraktion), die unentdeckten,
-- oder nil + Fehlergrund
function Travel:GetZoneNodes(mapID)
    if not (C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap) then return nil, "NO_API" end
    -- Hinweis: ShouldMapShowTaxiNodes meldet in Forever für Das Brachland "false"
    -- (Weltkarte zeigt dort keine Flugpunkte). Wir fragen trotzdem direkt ab.
    local ok, nodes = pcall(C_TaxiMap.GetTaxiNodesForMap, mapID)
    if not ok or type(nodes) ~= "table" or #nodes == 0 then return nil, "NO_DATA" end
    local mine, undiscovered = {}, {}
    for _, node in ipairs(nodes) do
        if nodeForMyFaction(node) then
            table.insert(mine, node)
            if node.isUndiscovered then table.insert(undiscovered, node) end
        end
    end
    return mine, undiscovered
end

local function playerPos(mapID)
    local pos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return nil end
    return pos:GetXY()
end

local function nearest(mapID, list)
    local px, py = playerPos(mapID)
    local best, bestDist
    for _, node in ipairs(list) do
        local x, y = node.position:GetXY()
        local d = px and ((x - px) ^ 2 + (y - py) ^ 2) or 0
        if not best or d < bestDist then best, bestDist = node, d end
    end
    return best
end

local function coords(node)
    local x, y = node.position:GetXY()
    return x * 100, y * 100
end

local function setWaypoint(mapID, node)
    local x, y = node.position:GetXY()
    local ok = C_Map.CanSetUserWaypointOnMap == nil or C_Map.CanSetUserWaypointOnMap(mapID)
    if ok and C_Map.SetUserWaypoint then
        C_Map.SetUserWaypoint({ uiMapID = mapID, position = CreateVector2D(x, y) })
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
        return true
    end
    return false
end

-- /ww flug [aus]
function Travel:FlightCommand(rest)
    local text = (rest or ""):lower()
    if text == "aus" or text == "off" then
        if C_Map.ClearUserWaypoint then C_Map.ClearUserWaypoint() end
        ns:Print(L.TRAVEL_WAY_CLEARED)
        return
    end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then ns:Print(L.ZG_NO_MAP) return end
    local info = C_Map.GetMapInfo(mapID)
    local zone = info and info.name or ("#" .. mapID)

    local mine, undiscovered = self:GetZoneNodes(mapID)
    if not mine then
        ns:Print(L.TRAVEL_FP_NODATA, zone, tostring(undiscovered))
        return
    end
    if #mine == 0 then
        ns:Print(L.TRAVEL_FP_NONE, zone)
        return
    end
    ns:Print(L.TRAVEL_FP_HEADER, zone)
    for _, node in ipairs(mine) do
        local x, y = coords(node)
        ns:Print("   %s %s (%.0f, %.0f)", node.isUndiscovered and L.TRAVEL_FP_NEW or L.TRAVEL_FP_KNOWN, node.name, x, y)
    end
    if #undiscovered == 0 then
        ns:Print(L.TRAVEL_FP_ALLKNOWN)
        return
    end
    local target = nearest(mapID, undiscovered)
    local x, y = coords(target)
    if setWaypoint(mapID, target) then
        ns:Print(L.TRAVEL_FP_WAY, target.name, x, y)
    else
        ns:Print(L.TRAVEL_FP_WAYTEXT, target.name, x, y)
    end
end

-- /ww flugdebug – was liefert das Spiel? (Zone, übergeordnete Karten, Flugmeister)
function Travel:Debug()
    local mapID = C_Map.GetBestMapForUnit("player")
    local probe = { date = date("%Y-%m-%d %H:%M"), maps = {} }
    local id = mapID
    while id and id > 0 do
        local info = C_Map.GetMapInfo(id)
        local show = C_TaxiMap.ShouldMapShowTaxiNodes and C_TaxiMap.ShouldMapShowTaxiNodes(id)
        local ok, nodes = pcall(C_TaxiMap.GetTaxiNodesForMap, id)
        local n, und = 0, 0
        local list = {}
        if ok and type(nodes) == "table" then
            for _, node in ipairs(nodes) do
                n = n + 1
                if node.isUndiscovered then und = und + 1 end
                local x, y = node.position:GetXY()
                table.insert(list, { name = node.name, faction = node.faction, undiscovered = node.isUndiscovered,
                                     x = math.floor(x * 1000) / 10, y = math.floor(y * 1000) / 10 })
            end
        end
        ns:Print("Karte %d (%s): show=%s, Flugpunkte=%d, davon unentdeckt=%d",
            id, info and info.name or "?", tostring(show), n, und)
        table.insert(probe.maps, { mapID = id, name = info and info.name, show = show, nodes = list })
        id = info and info.parentMapID
    end
    ns.db.taxiProbe = probe
    ns:Print("Gespeichert in WegweiserDB.taxiProbe (nach /reload in der SavedVariables-Datei).")
end

-- Beim Flugmeister: was meldet die Flugkarte? (für die Entwicklung gespeichert)
-- Forevers Flugkarte (Blizzard_UIPanels_Game/Shared/TaxiFrame.lua) nutzt die
-- klassischen Funktionen NumTaxiNodes / TaxiNodeName / TaxiNodeGetType.
local function probeFlightMaster()
    if not (NumTaxiNodes and TaxiNodeName and TaxiNodeGetType) then return end
    local list = {}
    for i = 1, NumTaxiNodes() do
        table.insert(list, { name = TaxiNodeName(i), type = TaxiNodeGetType(i) })
    end
    ns.db.taxiMasterProbe = { date = date("%Y-%m-%d %H:%M"), mapID = C_Map.GetBestMapForUnit("player"), nodes = list }
end

-- Hinweis beim Betreten einer Zone (einmal pro Zone und Sitzung)
function Travel:ZoneHint()
    if not enabled() then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID or hintedZones[mapID] then return end
    local mine, undiscovered = self:GetZoneNodes(mapID)
    if not mine then return end
    hintedZones[mapID] = true
    if #undiscovered == 0 then return end
    local names = {}
    for _, node in ipairs(undiscovered) do table.insert(names, node.name) end
    ns:Notify(L.TRAVEL_FP_HINT, table.concat(names, ", "))
    ns:Print("   " .. L.TRAVEL_FP_HINT2)
end

-- ------------------------------------------------------------
-- Ruhestein
-- ------------------------------------------------------------

local function bindLocation()
    if not GetBindLocation then return nil end
    local where = GetBindLocation()
    if isSecret(where) or where == nil or where == "" then return nil end
    return where
end

function Travel:HearthCommand()
    local where = bindLocation()
    if where then
        ns:Print(L.TRAVEL_HS_BOUND, where)
    else
        ns:Print(L.TRAVEL_HS_UNKNOWN)
    end
    -- HEARTHSTONE_ITEM_ID ist eine Blizzard-Konstante (Blizzard_FrameXMLBase/Constants.lua).
    -- C_Container.PlayerHasHearthstone meldete in Forever fälschlich "keiner da".
    if HEARTHSTONE_ITEM_ID and C_Item and C_Item.GetItemCount
       and C_Item.GetItemCount(HEARTHSTONE_ITEM_ID) == 0 then
        ns:Print("   " .. L.TRAVEL_HS_MISSING)
    end
    ns:Print("   " .. L.TRAVEL_HS_TIP)
end

local function hookTooltip()
    if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
            and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item) then
        return
    end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if not enabled() or not data or isSecret(data.id) then return end
        if not HEARTHSTONE_ITEM_ID or data.id ~= HEARTHSTONE_ITEM_ID then return end
        local where = bindLocation()
        if where then
            tooltip:AddLine(string.format(L.TRAVEL_HS_TOOLTIP, where), 0.4, 0.8, 1.0)
        end
    end)
end

function Travel:OnInitialize()
    ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        C_Timer.After(4, function()
            ns:RunOutOfCombat(function() Travel:ZoneHint() end, true)
        end)
    end)
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        C_Timer.After(6, function()
            ns:RunOutOfCombat(function() Travel:ZoneHint() end, true)
        end)
    end)
    ns:RegisterEvent("TAXIMAP_OPENED", function()
        C_Timer.After(0.2, probeFlightMaster)
    end)
    ns:RegisterEvent("HEARTHSTONE_BOUND", function()
        if not enabled() then return end
        C_Timer.After(0.5, function()
            local where = bindLocation()
            if where then ns:Notify(L.TRAVEL_HS_NOW, where) end
        end)
    end)
    hookTooltip()
end
