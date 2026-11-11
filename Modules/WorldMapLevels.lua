-- ============================================================
-- Modules/WorldMapLevels.lua
-- Levelbereiche auf der Weltkarte.
--
-- Blizzards Weltkarte zeigt beim Drüberfahren über eine Zone schon von
-- selbst "Name (10-25)" – aber nur, wenn das Spiel einen Levelbereich kennt
-- (C_Map.GetMapLevels). In Forever ist der leer. Deshalb zeigen wir unsere
-- Werte aus Data/Zones.lua in einer eigenen Zeile unter Blizzards Zonennamen –
-- gleiche Farblogik wie Blizzard (grau/grün/gelb/orange/rot je nach deinem Level).
--
--   * Maus über einer Zone (z. B. auf der Kalimdor-Karte): deren Bereich
--   * Karte einer Zone geöffnet, Maus nicht über einer Unterzone: deren Bereich
--
-- Technik (geprüft im Forever-UI-Quellcode, AreaLabelDataProvider.lua):
-- C_Map.GetMapInfoAtPosition + WorldMapFrame:GetNormalizedCursorPosition –
-- dasselbe, was Blizzards Zonen-Beschriftung benutzt. Wir verändern
-- Blizzards Karte nicht, wir legen nur eine eigene Textzeile darüber.
-- Im Kampf ausgeblendet.
-- ============================================================

local _, ns = ...
local L = ns.L

local WML = {}
ns.modules.WorldMapLevels = WML

local label, updater
local elapsed = 0

local function settings()
    return ns.db and ns.db.settings or ns.defaults.settings
end

-- Farbe wie bei Blizzard: unter dem Bereich -> rot/orange, darüber -> grün/grau,
-- mittendrin -> gelb
local function rangeColor(minL, maxL)
    local playerLevel = UnitLevel("player")
    local color
    if playerLevel < minL then
        color = GetQuestDifficultyColor(minL)
    elseif playerLevel > maxL then
        color = GetQuestDifficultyColor(maxL - 2)
    else
        color = QuestDifficultyColors and QuestDifficultyColors["difficult"] or { r = 1, g = 0.82, b = 0 }
    end
    return color
end

-- Text für eine Zone oder nil.
-- withName = false: nur "Stufe 10–25" (wenn Blizzard den Namen schon darüber zeigt)
function WML:TextFor(mapID, withName)
    local z = ns.Zones and ns.Zones[mapID]
    if not z then return nil end
    local range = (z.min == z.max) and tostring(z.min) or (z.min .. "–" .. z.max)
    if withName == false then
        return string.format(L.WML_RANGE, range), rangeColor(z.min, z.max)
    end
    local info = C_Map.GetMapInfo(mapID)
    local name = info and info.name or "?"
    return string.format(L.WML_LABEL, name, range), rangeColor(z.min, z.max)
end

local function update()
    label:Hide()
    if not settings().zoneMapLevels or ns:InCombat() then return end
    local map = WorldMapFrame
    local mapID = map:GetMapID()
    if not mapID then return end

    local shownID, hovering
    if map:IsCanvasMouseFocus() then
        local x, y = map:GetNormalizedCursorPosition()
        local info = x and C_Map.GetMapInfoAtPosition(mapID, x, y)
        if info and info.mapID ~= mapID then
            shownID = info.mapID          -- Maus über einer Zone
            hovering = true               -- Blizzard zeigt den Namen schon darüber
        end
    end
    if not shownID then
        local info = C_Map.GetMapInfo(mapID)
        if info and info.mapType == Enum.UIMapType.Zone then
            shownID = mapID               -- Zonenkarte ist geöffnet
        end
    end
    if not shownID then return end

    local text, color = WML:TextFor(shownID, not hovering)
    if text then
        label:SetText(text)
        label:SetTextColor(color.r, color.g, color.b)
        label:Show()
    end
end

local function setup()
    if updater or not WorldMapFrame or not WorldMapFrame.ScrollContainer then return end
    -- Eigene Textzeile, oben mittig auf der Karte (unter Blizzards Zonennamen)
    updater = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer)
    updater:SetAllPoints()
    updater:SetFrameLevel(WorldMapFrame.ScrollContainer:GetFrameLevel() + 50)
    updater:EnableMouse(false)
    label = updater:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("TOP", updater, "TOP", 0, -52)
    label:SetShadowOffset(1, -1)
    label:Hide()
    -- Nur solange die Karte offen ist, 10x pro Sekunde aktualisieren
    updater:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed < 0.1 then return end
        elapsed = 0
        update()
    end)
end

function WML:OnInitialize()
    setup()
    -- Falls die Weltkarte erst später geladen wird
    ns:RegisterEvent("ADDON_LOADED", function(_, name)
        if name == "Blizzard_WorldMap" then setup() end
    end)
end
