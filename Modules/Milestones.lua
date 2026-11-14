-- ============================================================
-- Modules/Milestones.lua
-- Meilensteine, die Einsteiger leicht verpassen:
--
--  1) Reiten: ab Stufe 30 Spar-Hinweise (Gold bis zur Ausbildung auf Stufe 40),
--     auf Stufe 40 der Hinweis zum Reitlehrer des eigenen Volkes, auf 60 das
--     schnelle Reiten. /ww reiten zeigt den Stand und setzt einen Wegpunkt.
--     Daten: Data/Milestones.lua (goldgoblin, Beta-Stand).
--
--  2) Vermächtnis: Sobald das Vermächtnissystem freigeschaltet ist und freie
--     Punkte da sind, ein Hinweis mit der Taste zum Öffnen. Die Punkte liest
--     Wegweiser genauso wie Blizzards Vermächtnisfenster (geprüft im Forever-
--     UI-Quellcode, Blizzard_LegacySystem/Blizzard_LegacySystemUtil.lua):
--       Freischaltung: C_MajorFactions.GetCurrentRenownLevel(LEGACY_REWARD_TRACK_FACTION_ID) > 0
--       Punkte:        C_Traits.GetTreeCurrencyInfo(configID, LEGACY_TREE_PROFESSIONS_ID)[1].quantity
--       Taste:         Tastenbelegung "TOGGLELEGACYSYSTEM" (Bindings_Camelot.xml)
-- ============================================================

local _, ns = ...
local L = ns.L

local MS = {}
ns.modules.Milestones = MS

local function setting(key) return ns.db and ns.db.settings[key] end

local function money(copper)
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        return C_CurrencyInfo.GetCoinTextureString(copper)
    end
    return tostring(math.floor(copper / 10000)) .. "g"
end

-- ------------------------------------------------------------
-- Reiten
-- ------------------------------------------------------------

local function myTrainer()
    local _, raceFile = UnitRace("player")
    return raceFile and ns.Riding.trainers[raceFile]
end

local function trainerLine()
    local t = myTrainer()
    if not t then return L.MS_RIDE_TRAINER_UNKNOWN end
    local info = C_Map.GetMapInfo(t.map)
    return string.format(L.MS_RIDE_TRAINER, t.name, info and info.name or ("#" .. t.map), t.x, t.y)
end

function MS:RidingHint(level)
    if not setting("ridingHint") or not ns.Riding then return end
    local R = ns.Riding
    local have = GetMoney()
    if level == R.normal.level then
        ns:Notify(L.MS_RIDE_NOW)
        ns:Print("   " .. trainerLine())
        if have < R.normal.cost then
            ns:Print("   " .. L.MS_RIDE_MISSING, money(R.normal.cost - have))
        end
        ns:Print("   " .. L.MS_RIDE_CMD)
    elseif level == R.fast.level then
        ns:Print(L.MS_RIDE_FAST, money(R.fast.cost), money(R.fast.mount))
    else
        for _, l in ipairs(R.saveFrom) do
            if level == l then
                if have >= R.normal.cost then
                    ns:Print(L.MS_RIDE_ENOUGH, R.normal.level)
                else
                    ns:Print(L.MS_RIDE_SAVE, R.normal.level, money(R.normal.cost), money(have), money(R.normal.cost - have))
                end
            end
        end
    end
end

-- /ww reiten
function MS:RidingCommand()
    local R = ns.Riding
    local level, have = UnitLevel("player"), GetMoney()
    ns:Print(L.MS_RIDE_HEADER, R.normal.level, money(R.normal.cost))
    if level < R.normal.level then
        ns:Print("   " .. L.MS_RIDE_LEVEL_LEFT, R.normal.level - level)
    end
    if have >= R.normal.cost then
        ns:Print("   " .. L.MS_RIDE_HAVE_ENOUGH, money(have))
    else
        ns:Print("   " .. L.MS_RIDE_HAVE, money(have), money(R.normal.cost - have))
    end
    ns:Print("   " .. L.MS_RIDE_FAST_SHORT, R.fast.level, money(R.fast.cost))
    local t = myTrainer()
    if t then
        ns:Print("   " .. trainerLine())
        local ok = C_Map.CanSetUserWaypointOnMap == nil or C_Map.CanSetUserWaypointOnMap(t.map)
        if ok and C_Map.SetUserWaypoint and CreateVector2D then
            C_Map.SetUserWaypoint({ uiMapID = t.map, position = CreateVector2D(t.x / 100, t.y / 100) })
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
            ns:Print("   " .. L.MS_RIDE_WAY)
        end
    else
        ns:Print("   " .. L.MS_RIDE_TRAINER_UNKNOWN)
    end
    ns:Print("|cff999999" .. L.MS_RIDE_SOURCE .. "|r")
end

-- ------------------------------------------------------------
-- Vermächtnis
-- ------------------------------------------------------------

-- Rückgabe: freigeschaltet (bool), freie Punkte (Zahl) – oder nil, wenn nicht lesbar
function MS:LegacyPoints()
    local LC = Constants and Constants.LegacyConsts
    if not (LC and C_MajorFactions and C_MajorFactions.GetCurrentRenownLevel and C_Traits
            and C_Traits.GetConfigIDByTreeID and C_Traits.GetTreeCurrencyInfo) then
        return nil
    end
    local ok, renown = pcall(C_MajorFactions.GetCurrentRenownLevel, LC.LEGACY_REWARD_TRACK_FACTION_ID)
    if not ok or type(renown) ~= "number" then return nil end
    local unlocked = renown > 0
    if not unlocked then return false, 0 end
    local treeID = LC.LEGACY_TREE_PROFESSIONS_ID
    local configID = C_Traits.GetConfigIDByTreeID(treeID)
    if not configID then return true, nil end
    local ok2, info = pcall(C_Traits.GetTreeCurrencyInfo, configID, treeID, false)
    local c = ok2 and info and info[1]
    return true, c and c.quantity or nil
end

local function legacyKey()
    local key = GetBindingKey and GetBindingKey("TOGGLELEGACYSYSTEM")
    if key and GetBindingText then return GetBindingText(key) end
    return nil
end

local lastHinted = 0

function MS:LegacyCheck()
    if not setting("legacyHint") then return end
    local unlocked, points = self:LegacyPoints()
    if not unlocked then return end
    -- Erste Freischaltung (accountweit gemerkt)
    if not ns.db.legacyUnlockedSeen then
        ns.db.legacyUnlockedSeen = true
        ns:Notify(L.MS_LEG_UNLOCKED)
        ns:Print("   " .. L.MS_LEG_EXPLAIN)
    end
    if points and points > 0 and points > lastHinted then
        lastHinted = points
        ns:Notify(L.MS_LEG_POINTS, points)
        local key = legacyKey()
        ns:Print("   " .. (key and string.format(L.MS_LEG_OPEN_KEY, key) or L.MS_LEG_OPEN_MENU))
    elseif points == 0 then
        lastHinted = 0
    end
end

-- /ww vermächtnis
function MS:LegacyCommand()
    local unlocked, points = self:LegacyPoints()
    if unlocked == nil then ns:Print(L.MS_LEG_NOAPI) return end
    if not unlocked then ns:Print(L.MS_LEG_LOCKED) return end
    ns:Print(L.MS_LEG_STATUS, points or 0)
    local key = legacyKey()
    if (points or 0) > 0 then
        ns:Print("   " .. (key and string.format(L.MS_LEG_OPEN_KEY, key) or L.MS_LEG_OPEN_MENU))
    else
        ns:Print("   " .. (key and string.format(L.MS_LEG_OPEN_KEY0, key) or L.MS_LEG_OPEN_MENU0))
    end
end

-- ------------------------------------------------------------

function MS:OnInitialize()
    ns:RegisterEvent("PLAYER_LEVEL_UP", function(_, level)
        C_Timer.After(4, function()
            ns:RunOutOfCombat(function()
                MS:RidingHint(tonumber(level) or UnitLevel("player"))
                MS:LegacyCheck()
            end, true)
        end)
    end)
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
        if not (isInitialLogin or isReloadingUi) then return end
        C_Timer.After(15, function() ns:RunOutOfCombat(function() MS:LegacyCheck() end, true) end)
    end)
    for _, e in ipairs({ "TRAIT_TREE_CURRENCY_INFO_UPDATED", "ACHIEVEMENT_EARNED", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" }) do
        ns:RegisterEvent(e, function()
            C_Timer.After(3, function() ns:RunOutOfCombat(function() MS:LegacyCheck() end, true) end)
        end)
    end
end
