-- ============================================================
-- Modules/ProfessionHelper.lua
-- Modul 4: Berufe-Helfer.
--
--   * /ww berufe – deine Berufe mit Skill/Limit, Art (Sammeln/Herstellen),
--     passender Partner-Beruf, Tipps für die Klasse, Nebenberufe
--   * automatisch: kurz vor dem Limit eines Rangs (z. B. 70/75) und beim
--     Erreichen des Limits -> "zum Lehrer für den nächsten Rang"
--     (sonst sammeln/herstellen Anfänger weiter, ohne dass der Skill steigt)
--   * einmalig ab Level 5 ohne Hauptberuf: freundlicher Hinweis
--
-- Skill und Limit kommen direkt aus dem Spiel (C_SkillInfo, geprüft im
-- Forever-UI-Quellcode). Empfehlungen aus Data/Professions.lua (Quelle,
-- verified = false). Level-Voraussetzungen der Ränge zeigen wir bewusst
-- NICHT an – die Quellen widersprechen sich; der Lehrer sagt es dir im Spiel.
-- ============================================================

local _, ns = ...
local L = ns.L

local PH = {}
ns.modules.ProfessionHelper = PH

local function settings()
    return ns.db and ns.db.settings or ns.defaults.settings
end

-- ------------------------------------------------------------
-- Berufe aus dem Spiel lesen
-- ------------------------------------------------------------

-- Liefert eine Liste { id, name, rank, maxRank, kind } der gelernten Berufe.
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

-- Name eines Berufs in Spielsprache (auch wenn nicht gelernt), sonst englisch
local function profName(id)
    if C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID then
        local ok, info = pcall(C_SkillInfo.GetSkillLineInfoByID, id)
        if ok and info and info.name and info.name ~= "" then return info.name end
    end
    return L["PROF_NAME_" .. id]   -- Namen stehen in Locales/
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
            local color = (p.rank >= p.maxRank and p.maxRank < 300) and "|cffff5555"
                or (p.rank >= p.maxRank - ns.ProfessionCapWarning.value and p.maxRank < 300) and "|cffffd100"
                or "|cffffffff"
            ns:Print("   %s%s %d/%d|r  |cff999999(%s, #%d)|r", color, p.name, p.rank, p.maxRank,
                L["PROF_KIND_" .. p.kind], p.id)
            -- Partner-Beruf für Herstellungsberufe
            local data = ns.Professions[p.id]
            if data.uses and not have[data.uses] then
                ns:Print("      " .. L.PROF_NEEDS, profName(data.uses))
            end
        end
    end

    -- Weniger als 2 Hauptberufe: Vorschläge
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

    -- Nebenberufe, die man noch nicht hat
    if not have[185] then ns:Print("   " .. L.PROF_TIP_COOKING) end
    if not have[129] then ns:Print("   " .. L.PROF_TIP_FIRSTAID) end
    ns:Print("|cff999999" .. L.PROF_SOURCE_NOTE .. "|r")
end

-- ------------------------------------------------------------
-- Automatische Hinweise
-- ------------------------------------------------------------

local warned = {}     -- id:maxRank:stufe -> true (pro Sitzung einmal)
local checkPending = false

function PH:CheckCaps()
    if not settings().profHelper then return end
    local margin = ns.ProfessionCapWarning.value
    for _, p in ipairs(self:GetMyProfessions()) do
        if p.maxRank < 300 then
            local stage
            if p.rank >= p.maxRank then stage = "AT"
            elseif p.rank >= p.maxRank - margin then stage = "NEAR" end
            if stage then
                local key = p.id .. ":" .. p.maxRank .. ":" .. stage
                if not warned[key] then
                    warned[key] = true
                    if stage == "AT" then
                        ns:Notify(L.PROF_AT_CAP, p.name, p.rank, p.maxRank)
                    else
                        ns:Print(L.PROF_NEAR_CAP, p.name, p.rank, p.maxRank)
                    end
                end
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
            ns:RunOutOfCombat(function() PH:CheckNoProfession() end, true)
        end)
    end)
end
