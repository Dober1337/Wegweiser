-- ============================================================
-- Modules/BuildCheck.lua
-- Hält die Talent-Builds im Blick: Passen sie noch zum echten Talentbaum?
--
--   * Wegweiser merkt sich die Spielversion (GetBuildInfo). Nach einem Patch
--     prüft er beim Einloggen ALLE Leveling-Builds der eigenen Klasse gegen den
--     Baum im Spiel (gleiche Prüfung wie im Talentfenster: Talent vorhanden,
--     Rang, Reihe/Spalte, Reihen-Voraussetzung, Pfeile) und meldet das Ergebnis.
--   * Ohne Patch wird still geprüft; im Chat steht nur etwas, wenn ein Build
--     nicht mehr passt (einmal pro Sitzung).
--   * Ergebnis pro Klasse in WegweiserDB.buildCheck (SavedVariables) – so können
--     Spieler verschiedener Klassen es einschicken. Ein Charakter sieht nur den
--     Talentbaum der EIGENEN Klasse (Spiel-API).
--   * /ww build prüfen – sofort prüfen und alle Ergebnisse anzeigen.
-- ============================================================

local _, ns = ...
local L = ns.L

local BC = {}
ns.modules.BuildCheck = BC

local warnedThisSession = false
local CROSS = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t"
local CHECK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t"

local function store()
    ns.db.buildCheck = ns.db.buildCheck or { results = {} }
    ns.db.buildCheck.results = ns.db.buildCheck.results or {}
    return ns.db.buildCheck
end

local function gameBuild()
    local version, build = GetBuildInfo()
    return tostring(version) .. "." .. tostring(build)
end

local function loc(t)
    if type(t) ~= "table" then return t or "" end
    return t[ns.locale] or t.enUS or t.deDE or ""
end

-- Prüft alle Builds der Klasse. Rückgabe: Liste { build, problems } oder nil (Baum nicht lesbar)
function BC:Run()
    local G = ns.modules.TalentGuide
    if not G or not ns.TalentAPI then return nil end
    local tree = ns.TalentAPI:ReadTree()
    if not tree then return nil end
    local out = {}
    for _, b in ipairs(G:GetClassBuilds()) do
        if not b.planned and #(b.steps or {}) > 0 then
            G:ResolveByName(b, tree)
            local ok, problems = pcall(G.Validate, G, b, tree)
            if not ok then problems = { tostring(problems) } end
            table.insert(out, { build = b, problems = problems or {} })
        end
    end

    -- Ergebnis speichern (pro Klasse)
    local _, classFile = UnitClass("player")
    local data = { date = date("%Y-%m-%d %H:%M"), gameBuild = gameBuild(), addon = ns.version, builds = {} }
    for _, r in ipairs(out) do
        data.builds[r.build.key] = { ok = #r.problems == 0, problems = r.problems }
    end
    store().results[classFile] = data
    return out
end

local function failed(results)
    local list = {}
    for _, r in ipairs(results) do
        if #r.problems > 0 then table.insert(list, r) end
    end
    return list
end

-- Automatische Prüfung nach dem Einloggen
function BC:AutoCheck(attempt)
    local results = self:Run()
    if not results then
        -- Talentdaten evtl. noch nicht bereit: bis zu 3 Versuche
        if (attempt or 1) < 3 then
            C_Timer.After(10, function()
                ns:RunOutOfCombat(function() BC:AutoCheck((attempt or 1) + 1) end, true)
            end)
        end
        return
    end
    local s = store()
    local now = gameBuild()
    local patched = s.lastGameBuild and s.lastGameBuild ~= now
    s.lastGameBuild = now

    local bad = failed(results)
    if patched then
        ns:Notify(L.BC_PATCH, now)
        if #bad == 0 then
            ns:Print("   " .. L.BC_ALL_OK, #results)
        end
    end
    if #bad > 0 and (patched or not warnedThisSession) then
        warnedThisSession = true
        ns:Print(L.BC_BAD, #bad, #results)
        for _, r in ipairs(bad) do
            ns:Print("   " .. CROSS .. " %s", loc(r.build.menu or r.build.title))
        end
        ns:Print("   " .. L.BC_BAD_HINT)
    end
end

-- /ww build prüfen
function BC:Command()
    local results = self:Run()
    if not results then ns:Print(L.TALENT_API_MISSING) return end
    ns:Print(L.BC_HEADER, gameBuild())
    for _, r in ipairs(results) do
        if #r.problems == 0 then
            ns:Print("   " .. CHECK .. " %s", loc(r.build.menu or r.build.title))
        else
            ns:Print("   " .. CROSS .. " %s", loc(r.build.menu or r.build.title))
            for i, p in ipairs(r.problems) do
                if i > 3 then ns:Print("        … (%d)", #r.problems) break end
                ns:Print("        " .. p)
            end
        end
    end
    if #failed(results) > 0 then ns:Print(L.BC_BAD_HINT) end
end

function BC:OnInitialize()
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
        if not (isInitialLogin or isReloadingUi) then return end
        C_Timer.After(12, function()
            ns:RunOutOfCombat(function() BC:AutoCheck(1) end, true)
        end)
    end)
end
