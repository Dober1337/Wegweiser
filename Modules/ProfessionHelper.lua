-- ============================================================
-- Modules/ProfessionHelper.lua
-- Modul 4: Berufe-Helfer.
--
--   * /ww berufe – deine Berufe mit Skill/Limit, nächster Rang (ab welchem
--     Skill/Level, beim Lehrer/Buch/Quest), bei Sammelberufen: was gerade
--     Punkte gibt, Partner-Beruf, Tipps für die Klasse, Nebenberufe
--   * /ww lehrer <Beruf> – setzt EINEN Wegpunkt zum nächsten passenden
--     Horde-Lehrer (nur auf Anfrage, kein dauerhafter Marker);
--     /ww lehrer aus – Wegpunkt entfernen
--   * automatisch (nur Chat, nie ein Wegpunkt):
--       - nächster Rang ist lernbar (Skill + Level erreicht)
--       - Limit des aktuellen Rangs erreicht
--       - ab Level 5 ohne Hauptberuf: einmaliger Tipp
--
-- Skill und Limit direkt aus dem Spiel (C_SkillInfo). Ränge, Abbau-Farben,
-- Lehrer: Data/Professions.lua (goldgoblin, verified = false).
-- ============================================================

local _, ns = ...
local L = ns.L

local PH = {}
ns.modules.ProfessionHelper = PH

local RANK_BY_CAP = { [75] = 1, [150] = 2, [225] = 3, [300] = 4 }

local function settings()
    return ns.db and ns.db.settings or ns.defaults.settings
end

local function factionKey()
    return UnitFactionGroup("player") == "Horde" and "HORDE" or "ALLIANCE"
end

-- ------------------------------------------------------------
-- Berufe aus dem Spiel lesen
-- ------------------------------------------------------------

function PH:GetMyProfessions()
    local list = {}
    if not C_SkillInfo then return list end
    for id, data in pairs(ns.Professions) do
        local ok, info = pcall(C_SkillInfo.GetSkillLineInfoByID, id)
        if ok and info and (info.maxRank or 0) > 0 and not info.isHeader then
            table.insert(list, {
                id = id, name = info.name or data.en, rank = info.rank or 0,
                maxRank = info.maxRank, kind = data.kind,
            })
        end
    end
    table.sort(list, function(a, b)
        if a.kind ~= b.kind then return a.kind == "GATHERING" or (a.kind == "CRAFTING" and b.kind == "SECONDARY") end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

local function profName(id)
    if C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID then
        local ok, info = pcall(C_SkillInfo.GetSkillLineInfoByID, id)
        if ok and info and info.name and info.name ~= "" then return info.name end
    end
    return L["PROF_NAME_" .. id]
end

-- Nächster Rang eines Berufs: Index (2–4) und Daten, oder nil (schon Fachmann)
function PH:NextRank(p)
    local current = RANK_BY_CAP[p.maxRank]
    if not current or current >= 4 then return nil end
    local ranks = ns.ProfessionRanks[p.id]
    local r = ranks and ranks[current + 1]
    if not r then return nil end
    return current + 1, r
end

-- Text: "Geselle ab Skill 50 und Stufe 10 beim Lehrer"
function PH:RankText(index, r)
    local text = string.format(L.PROF_RANK_AT, L["PROF_RANK_" .. index], r.skill)
    if r.level then text = text .. string.format(L.PROF_RANK_LEVEL, r.level) end
    text = text .. " " .. L["PROF_HOW_" .. r.how]
    return text
end

-- Sammelberuf: welche Vorkommen geben bei diesem Skill (sicher/oft) Punkte?
function PH:GatherAdvice(p)
    local nodes = ns.GatherNodes[p.id]
    if not nodes then return nil end
    local orange, yellow, green, nextNode = {}, {}, {}, nil
    for _, n in ipairs(nodes) do
        local name = (ns.locale == "deDE") and n.de or n.en
        if not n.yellow then
            -- Nur Mindest-Skill bekannt (keine Farben in der Quelle)
            if p.rank < n.min and (not nextNode or n.min < nextNode.min) then
                nextNode = { name = name, min = n.min }
            end
        elseif p.rank >= n.min and p.rank < n.yellow then
            table.insert(orange, name)
        elseif p.rank >= n.yellow and p.rank < n.green then
            table.insert(yellow, name)
        elseif p.rank >= n.green and p.rank < n.grey then
            table.insert(green, name)
        elseif p.rank < n.min and (not nextNode or n.min < nextNode.min) then
            nextNode = { name = name, min = n.min }
        end
    end
    return orange, yellow, green, nextNode
end

-- ------------------------------------------------------------
-- /ww berufe
-- ------------------------------------------------------------

function PH:PrintOverview()
    local mine = self:GetMyProfessions()
    local primary, have = 0, {}
    for _, p in ipairs(mine) do
        have[p.id] = p
        if p.kind ~= "SECONDARY" then primary = primary + 1 end
    end

    if #mine == 0 then
        ns:Print(L.PROF_NONE)
    else
        ns:Print(L.PROF_HEADER)
        for _, p in ipairs(mine) do
            local atCap = p.rank >= p.maxRank and p.maxRank < 300
            ns:Print("   %s%s %d/%d|r  |cff999999(%s, #%d)|r", atCap and "|cffff5555" or "|cffffffff",
                p.name, p.rank, p.maxRank, L["PROF_KIND_" .. p.kind], p.id)
            -- nächster Rang
            local idx, r = self:NextRank(p)
            if idx then
                local ready = p.rank >= r.skill and (not r.level or UnitLevel("player") >= r.level)
                ns:Print("      %s%s|r", ready and "|cff55ff55" or "|cffcccccc", self:RankText(idx, r))
                if r.note then ns:Print("      |cffffd100" .. L[r.note] .. "|r") end
            end
            -- Herstellungs-/Nebenberufe: womit jetzt am besten skillen?
            local best, mats, status
            if ns.modules.ProfessionRoutes then best, mats, status = ns.modules.ProfessionRoutes:BestLine(p) end
            if best then
                ns:Print("      " .. best)
                if status then ns:Print("      " .. status) end
                if mats then ns:Print("      |cffcccccc" .. L.PRO_MATS:format(mats) .. "|r") end
            end
            if ns.ProfessionGuideLinks and ns.ProfessionGuideLinks[p.id] then
                ns:Print("      |cff999999" .. L.PRO_GUIDE_CMD:format(p.name:lower()) .. "|r")
            end
            -- Sammelberufe: was gibt gerade Punkte?
            local orange, yellow, green, nextNode = self:GatherAdvice(p)
            if orange and #orange > 0 then ns:Print("      " .. L.PROF_GATHER_ORANGE, table.concat(orange, ", ")) end
            if yellow and #yellow > 0 then ns:Print("      " .. L.PROF_GATHER_YELLOW, table.concat(yellow, ", ")) end
            if orange and #orange == 0 and #yellow == 0 and #green > 0 then
                ns:Print("      " .. L.PROF_GATHER_GREEN, table.concat(green, ", "))
            end
            if nextNode and (not orange or #orange == 0) then
                ns:Print("      " .. L.PROF_GATHER_NEXT, nextNode.name, nextNode.min)
            end
            -- Partner-Beruf
            local data = ns.Professions[p.id]
            if data.uses and not have[data.uses] then
                ns:Print("      " .. L.PROF_NEEDS, profName(data.uses))
            end
        end
        ns:Print("   " .. L.PROF_TRAINER_HINT)
    end

    if primary < 2 then
        ns:Print(L.PROF_FREE_SLOTS, 2 - primary)
        local _, classFile = UnitClass("player")
        local tips = ns.ProfessionClassTips[classFile]
        if tips then
            local names = {}
            for _, id in ipairs(tips) do table.insert(names, profName(id)) end
            ns:Print("   " .. L.PROF_CLASS_TIP, table.concat(names, ", "))
        end
        ns:Print("   " .. L.PROF_PAIRS_HEADER)
        for _, pair in ipairs(ns.ProfessionPairs) do
            ns:Print("     - %s + %s: %s", profName(pair.a), profName(pair.b), L[pair.text])
        end
        ns:Print("   " .. L.PROF_GOLD_TIP)
    end

    if not have[185] then ns:Print("   " .. L.PROF_TIP_COOKING) end
    if not have[129] then ns:Print("   " .. L.PROF_TIP_FIRSTAID) end
    if factionKey() == "HORDE" then ns:Print("   " .. L.PROF_VENDOR_CAMP) end
    ns:Print("|cff999999" .. L.PROF_SOURCE_NOTE .. "|r")
end

-- ------------------------------------------------------------
-- /ww lehrer <Beruf> – Wegpunkt nur auf Anfrage
-- ------------------------------------------------------------

-- Weltposition eines Kartenpunkts (für Entfernungen), oder nil
local function worldPos(mapID, x, y)
    if not C_Map.GetWorldPosFromMapPos or not CreateVector2D then return nil end
    local ok, continent, pos = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
    if ok and continent and pos then return continent, pos end
    return nil
end

local function playerWorldPos()
    local mapID = C_Map.GetBestMapForUnit("player")
    local p = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if not p then return nil end
    local x, y = p:GetXY()
    return worldPos(mapID, x, y)
end

-- Beruf aus Eingabe finden: Name im Spiel oder deutscher/englischer Name (Anfang reicht)
-- Kurzformen, die Spieler oft tippen ("/ww lehrer kochen")
local ALIASES = {
    kochen = 185, koch = 185, cook = 185, angel = 356, fish = 356,
    schmied = 164, schmieden = 164, leder = 165, schneider = 197, schneidern = 197,
    verzauber = 333, vz = 333, ingi = 202, ingenieur = 202, engi = 202,
    erste = 129, ["erste hilfe"] = 129, verband = 129, alchi = 171,
    kraeuter = 182, ["kräuter"] = 182, kuerschner = 393, ["kürschner"] = 393, ["häuten"] = 393,
    erz = 186, bergbau = 186,
}

local function findProfession(text)
    text = (text or ""):lower()
    if text == "" then return nil end
    if ALIASES[text] then return ALIASES[text] end
    for alias, id in pairs(ALIASES) do
        if #text >= 4 and text:sub(1, #alias) == alias then return id end
    end
    for id, data in pairs(ns.Professions) do
        for _, candidate in ipairs({ profName(id), L["PROF_NAME_" .. id], data.en }) do
            if candidate and candidate:lower():sub(1, #text) == text then return id end
        end
    end
    return nil
end

-- Bester Lehrer: lehrt den nötigen Rang, möglichst nah (gleicher Kontinent)
-- Von dir besuchte Lehrer (pro Fraktion und Beruf, accountweit gemerkt)
local function learnedTrainers(id, create)
    if not ns.db then return nil end
    ns.db.knownTrainers = ns.db.knownTrainers or {}
    local f = factionKey()
    ns.db.knownTrainers[f] = ns.db.knownTrainers[f] or {}
    if create and not ns.db.knownTrainers[f][id] then ns.db.knownTrainers[f][id] = {} end
    return ns.db.knownTrainers[f][id]
end

-- Wird beim Öffnen eines Berufslehrers aufgerufen (Modules/ProfessionRoutes.lua)
function PH:RememberTrainer(id)
    if not UnitExists("npc") then return end
    local name = UnitName("npc")
    if not name or (issecretvalue and issecretvalue(name)) then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return end
    local x, y = pos:GetXY()
    if not x or (issecretvalue and issecretvalue(x)) then return end
    local list = learnedTrainers(id, true)
    for _, t in ipairs(list) do
        if t.name == name then t.map, t.x, t.y = mapID, x * 100, y * 100 return end
    end
    table.insert(list, { name = name, map = mapID, x = x * 100, y = y * 100, learned = true })
    ns:Print(L.PROF_TRAINER_SAVED, name, profName(id))
end

function PH:FindTrainer(id)
    local list = {}
    local static = ns.ProfessionTrainers[factionKey()] and ns.ProfessionTrainers[factionKey()][id]
    for _, t in ipairs(static or {}) do table.insert(list, t) end
    for _, t in ipairs(learnedTrainers(id, false) or {}) do table.insert(list, t) end
    if #list == 0 then return nil end
    local nextIdx
    for _, p in ipairs(self:GetMyProfessions()) do
        if p.id == id then nextIdx = self:NextRank(p) end
    end
    local needsHigher = nextIdx and nextIdx >= 2
    local pc, pp = playerWorldPos()
    local best, bestDist
    for _, t in ipairs(list) do
        local fits = not (needsHigher and t.apprentice) and not (t.artisanOnly and nextIdx ~= 4)
        if fits and t.ranks then
            -- Lehrer lehrt nur bestimmte Ränge; ohne den Beruf = Lehrling (Rang 1)
            local want, ok = nextIdx or 1, false
            for _, r in ipairs(t.ranks) do if r == want then ok = true end end
            fits = ok
        end
        if fits then
            local tc, tp = worldPos(t.map, t.x / 100, t.y / 100)
            local dist = math.huge / 2
            if pc and tc and pc == tc then
                dist = math.sqrt((tp.x - pp.x) ^ 2 + (tp.y - pp.y) ^ 2)
            end
            if not best or dist < bestDist then best, bestDist = t, dist end
        end
    end
    return best
end

function PH:TrainerCommand(rest)
    local text = rest or ""   -- alles nach "lehrer", z. B. "bergbau"
    if text:lower() == "aus" or text:lower() == "off" then
        if C_Map.ClearUserWaypoint then C_Map.ClearUserWaypoint() end
        ns:Print(L.PROF_WAY_CLEARED)
        return
    end
    local id = findProfession(text)
    if not id then
        ns:Print(L.PROF_WAY_USAGE)
        return
    end
    local t = self:FindTrainer(id)
    if not t then
        ns:Print(L.PROF_WAY_NONE, profName(id))
        local names = ns.ProfessionTrainerNames[factionKey()] and ns.ProfessionTrainerNames[factionKey()][id]
        if names then ns:Print("   " .. L.PROF_WAY_NAMES, table.concat(names, ", ")) end
        ns:Print("   " .. L.PROF_WAY_LEARN)
        return
    end
    local info = C_Map.GetMapInfo(t.map)
    local mapName = info and info.name or ("#" .. t.map)
    local point = { uiMapID = t.map, position = CreateVector2D(t.x / 100, t.y / 100) }
    local ok = C_Map.CanSetUserWaypointOnMap == nil or C_Map.CanSetUserWaypointOnMap(t.map)
    if ok and C_Map.SetUserWaypoint then
        C_Map.SetUserWaypoint(point)
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
        ns:Print(L.PROF_WAY_SET, profName(id), t.name, mapName, t.x, t.y)
    else
        ns:Print(L.PROF_WAY_TEXT, profName(id), t.name, mapName, t.x, t.y)
    end
end

-- ------------------------------------------------------------
-- /ww guide <Beruf> – Link zum Kopieren (Chat-Links sind in WoW nicht klickbar)
-- ------------------------------------------------------------

StaticPopupDialogs["WEGWEISER_COPY_LINK"] = {
    text = "%s",
    button1 = OKAY,
    hasEditBox = 1,
    editBoxWidth = 320,
    OnShow = function(self, data)
        -- Forever: dialog:GetEditBox() (geprüft in Blizzard_StaticPopup/StaticPopup.lua)
        local eb = (self.GetEditBox and self:GetEditBox()) or self.editBox
        if eb then
            eb:SetText(data or "")
            eb:HighlightText()
            eb:SetFocus()
        end
    end,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
    EditBoxOnEnterPressed = function(editBox) editBox:GetParent():Hide() end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
}

function PH:GuideCommand(rest)
    local text = rest or ""
    local id = text ~= "" and findProfession(text)
    local link = id and ns.ProfessionGuideLinks[id] or (text == "" and ns.ProfessionGuideLinks.overview)
    if not link then
        ns:Print(L.PRO_GUIDE_USAGE)
        return
    end
    StaticPopup_Show("WEGWEISER_COPY_LINK", L.PRO_COPY_TEXT, nil, link)
end

-- ------------------------------------------------------------
-- Automatische Hinweise (nur Chat)
-- ------------------------------------------------------------

local warned = {}
local checkPending = false

function PH:CheckCaps()
    if not settings().profHelper then return end
    local level = UnitLevel("player")
    for _, p in ipairs(self:GetMyProfessions()) do
        local idx, r = self:NextRank(p)
        if idx then
            local key = p.id .. ":" .. p.maxRank
            local hasTrainer = r.how == "TRAINER" and ns.ProfessionTrainers[factionKey()]
                and ns.ProfessionTrainers[factionKey()][p.id]
            local levelOk = not r.level or level >= r.level
            local atCap = p.rank >= p.maxRank
            if p.rank >= r.skill and levelOk and not warned[key .. ":ready"] then
                warned[key .. ":ready"] = true
                -- Am Limit wichtiger (Skill steigt nicht mehr) -> zusätzlich groß anzeigen
                if atCap then
                    warned[key .. ":cap"] = true
                    ns:Notify(L.PROF_AT_CAP, p.name, p.rank, p.maxRank)
                    ns:Print("   " .. self:RankText(idx, r))
                else
                    ns:Print(L.PROF_CAN_LEARN, p.name, p.rank, p.maxRank, self:RankText(idx, r))
                end
                if hasTrainer then ns:Print("   " .. L.PROF_WAY_TIP, p.name:lower()) end
            elseif p.rank >= r.skill and not levelOk and not warned[key .. ":lvl"] then
                warned[key .. ":lvl"] = true
                ns:Print(L.PROF_NEED_LEVEL, p.name, L["PROF_RANK_" .. idx], r.level)
            end
            if atCap and not warned[key .. ":cap"] then
                warned[key .. ":cap"] = true
                ns:Notify(L.PROF_AT_CAP, p.name, p.rank, p.maxRank)
            end
        end
    end
end

local function scheduleCheck()
    if checkPending then return end
    checkPending = true
    C_Timer.After(1, function()
        ns:RunOutOfCombat(function()
            checkPending = false
            PH:CheckCaps()
        end, true)
    end)
end

local noProfHinted = false
function PH:CheckNoProfession()
    if noProfHinted or not settings().profHelper then return end
    if UnitLevel("player") < 5 then return end
    for _, p in ipairs(self:GetMyProfessions()) do
        if p.kind ~= "SECONDARY" then return end
    end
    noProfHinted = true
    ns:Print(L.PROF_HINT_NONE)
end

function PH:OnInitialize()
    ns:RegisterEvent("SKILL_LINES_CHANGED", scheduleCheck)
    ns:RegisterEvent("CHAT_MSG_SKILL", scheduleCheck)
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
        if isInitialLogin or isReloadingUi then
            C_Timer.After(8, function()
                ns:RunOutOfCombat(function()
                    PH:CheckCaps()
                    PH:CheckNoProfession()
                end, true)
            end)
        end
    end)
    ns:RegisterEvent("PLAYER_LEVEL_UP", function()
        C_Timer.After(4, function()
            ns:RunOutOfCombat(function()
                PH:CheckCaps()          -- evtl. jetzt hoch genug für den nächsten Rang
                PH:CheckNoProfession()
            end, true)
        end)
    end)
end
