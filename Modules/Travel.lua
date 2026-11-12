-- ============================================================
-- Modules/Travel.lua
-- Reise-Hilfen für Einsteiger:
--   * Flugpunkte: Hinweis beim Betreten einer Zone, wenn es dort einen
--     Flugpunkt deiner Fraktion gibt, den du noch nicht kennst.
--     /ww flug zeigt sie und setzt einen Wegpunkt zum nächsten neuen.
--   * Ruhestein: /ww ruhestein zeigt, wo er gebunden ist; Bestätigung nach
--     dem Binden. (Den Ort im Tooltip zeigt Blizzard schon selbst.)
--
-- Keine eigenen Spieldaten. Im Spiel geprüft (Forever, Nov 2026):
--   * C_TaxiMap.GetTaxiNodesForMap(Karte) liefert ALLE Flugpunkte des
--     Kontinents (Name, Position, Fraktion 0/1/2), aber "isUndiscovered" ist
--     immer false -> taugt nicht für "kenne ich schon".
--   * Beim Flugmeister liefert die Flugkarte (NumTaxiNodes / TaxiNodeName /
--     TaxiNodeGetType) alle Flugpunkte der eigenen Fraktion: CURRENT und
--     REACHABLE = bekannt, DISTANT = noch nicht entdeckt.
--   -> Wegweiser merkt sich beim Flugmeister pro Charakter die bekannten
--      Flugpunkte und gleicht sie über den Namen ab.
-- Welche Flugpunkte in der aktuellen Zone liegen, ergibt
-- C_Map.GetMapInfoAtPosition auf der Kontinentkarte.
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

-- Gespeicherte Daten pro Charakter (bleibt lokal in der SavedVariables-Datei)
local function charData()
    local key = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
    ns.db.chars = ns.db.chars or {}
    ns.db.chars[key] = ns.db.chars[key] or {}
    return ns.db.chars[key]
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

-- Alte, nicht mehr genutzte Einträge (im Spiel z. B. "zzOLDPowderfuse Port")
local function isJunk(node)
    return not node.name or node.name:find("^zz") ~= nil
end

-- Karte auf Zonen-Ebene bringen (Stadtkarten/Unterkarten -> Zone)
local function zoneOf(info)
    local ZONE = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
    while info and info.mapType and info.mapType > ZONE and info.parentMapID and info.parentMapID > 0 do
        info = C_Map.GetMapInfo(info.parentMapID)
    end
    return info
end

local function continentOf(mapID)
    local CONT = Enum and Enum.UIMapType and Enum.UIMapType.Continent or 2
    local info = C_Map.GetMapInfo(mapID)
    while info do
        if info.mapType == CONT then return info.mapID end
        if not info.parentMapID or info.parentMapID == 0 then return nil end
        info = C_Map.GetMapInfo(info.parentMapID)
    end
end

-- Flugpunkte der aktuellen Zone (eigene Fraktion), Positionen auf der Zonenkarte.
-- Rückgabe: Liste oder nil + Grund
function Travel:GetZoneNodes(mapID)
    if not (C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap and C_Map.GetMapInfoAtPosition) then
        return nil, "NO_API"
    end
    local zoneInfo = zoneOf(C_Map.GetMapInfo(mapID))
    local continent = continentOf(mapID)
    if not zoneInfo or not continent then return nil, "NO_MAP" end

    local ok, contNodes = pcall(C_TaxiMap.GetTaxiNodesForMap, continent)
    if not ok or type(contNodes) ~= "table" or #contNodes == 0 then return nil, "NO_DATA" end
    local ok2, zoneNodes = pcall(C_TaxiMap.GetTaxiNodesForMap, zoneInfo.mapID)
    local zonePos = {}
    if ok2 and type(zoneNodes) == "table" then
        for _, node in ipairs(zoneNodes) do zonePos[node.nodeID] = node.position end
    end

    local result = {}
    for _, node in ipairs(contNodes) do
        if nodeForMyFaction(node) and not isJunk(node) then
            local cx, cy = node.position:GetXY()
            local at = zoneOf(C_Map.GetMapInfoAtPosition(continent, cx, cy))
            local pos = zonePos[node.nodeID]
            if at and at.mapID == zoneInfo.mapID and pos then
                table.insert(result, { name = node.name, position = pos, nodeID = node.nodeID })
            end
        end
    end
    return result, zoneInfo
end

-- Beim Flugmeister: bekannte Flugpunkte merken (CURRENT/REACHABLE)
local function rememberFlightMaster()
    if not (NumTaxiNodes and TaxiNodeName and TaxiNodeGetType) then return end
    local known, count = {}, 0
    for i = 1, NumTaxiNodes() do
        local kind = TaxiNodeGetType(i)
        if kind == "CURRENT" or kind == "REACHABLE" then
            known[TaxiNodeName(i)] = true
            count = count + 1
        end
    end
    if count > 0 then
        local data = charData()
        data.knownFlight = known
        data.knownFlightDate = date("%Y-%m-%d %H:%M")
    end
end

local function knownSet()
    return charData().knownFlight
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

    local nodes, zoneInfo = self:GetZoneNodes(mapID)
    if not nodes then
        ns:Print(L.TRAVEL_FP_NODATA, tostring(zoneInfo))
        return
    end
    local zone = zoneInfo.name or ("#" .. zoneInfo.mapID)
    if #nodes == 0 then
        ns:Print(L.TRAVEL_FP_NONE, zone)
        return
    end
    local known = knownSet()
    ns:Print(L.TRAVEL_FP_HEADER, zone)
    local new = {}
    for _, node in ipairs(nodes) do
        local x, y = coords(node)
        local label
        if not known then label = L.TRAVEL_FP_UNSURE
        elseif known[node.name] then label = L.TRAVEL_FP_KNOWN
        else label = L.TRAVEL_FP_NEW; table.insert(new, node) end
        ns:Print("   %s %s (%.0f, %.0f)", label, node.name, x, y)
    end
    if not known then
        ns:Print(L.TRAVEL_FP_ASKMASTER)
        return
    end
    if #new == 0 then
        ns:Print(L.TRAVEL_FP_ALLKNOWN)
        return
    end
    local target = nearest(zoneInfo.mapID, new)
    local x, y = coords(target)
    if setWaypoint(zoneInfo.mapID, target) then
        ns:Print(L.TRAVEL_FP_WAY, target.name, x, y)
    else
        ns:Print(L.TRAVEL_FP_WAYTEXT, target.name, x, y)
    end
end

-- /ww flugdebug – was liefert das Spiel? (für die Entwicklung)
function Travel:Debug()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then ns:Print(L.ZG_NO_MAP) return end
    local nodes, zoneInfo = self:GetZoneNodes(mapID)
    ns:Print("Karte %d, Zone: %s, Kontinent: %s", mapID,
        type(zoneInfo) == "table" and (zoneInfo.name .. " #" .. zoneInfo.mapID) or tostring(zoneInfo),
        tostring(continentOf(mapID)))
    for _, node in ipairs(nodes or {}) do
        local x, y = coords(node)
        ns:Print("   %s (%.1f, %.1f) nodeID %d", node.name, x, y, node.nodeID)
    end
    local data = charData()
    local n = 0
    for _ in pairs(data.knownFlight or {}) do n = n + 1 end
    ns:Print("Bekannte Flugpunkte gespeichert: %d (%s)", n, data.knownFlightDate or "noch nie beim Flugmeister")
end

-- Hinweis beim Betreten einer Zone (einmal pro Zone und Sitzung)
function Travel:ZoneHint()
    if not enabled() then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local nodes, zoneInfo = self:GetZoneNodes(mapID)
    if not nodes or hintedZones[zoneInfo.mapID] then return end
    hintedZones[zoneInfo.mapID] = true
    local known = knownSet()
    if not known then return end   -- ohne Flugmeister-Besuch nichts behaupten
    local names = {}
    for _, node in ipairs(nodes) do
        if not known[node.name] then table.insert(names, node.name) end
    end
    if #names == 0 then return end
    ns:Notify(L.TRAVEL_FP_HINT, table.concat(names, "; "))
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
        C_Timer.After(0.2, function()
            rememberFlightMaster()
            -- Nach dem Entdecken eines neuen Flugpunkts darf die Zone neu gemeldet werden
            wipe(hintedZones)
        end)
    end)
    ns:RegisterEvent("HEARTHSTONE_BOUND", function()
        if not enabled() then return end
        C_Timer.After(0.5, function()
            local where = bindLocation()
            if where then ns:Notify(L.TRAVEL_HS_NOW, where) end
        end)
    end)
end
