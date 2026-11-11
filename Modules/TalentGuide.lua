-- ============================================================
-- Modules/TalentGuide.lua
-- Modul 5: Talent-Leitfaden (Logik, noch ohne Talentfenster-Markierung).
--
-- Aufgaben:
--   1. Den passenden Build für die Klasse aus Data/Talents.lua holen.
--   2. Die Schritte in eine geordnete Punkteliste umwandeln (Punkt 1 ... 51).
--   3. Prüfen, ob der Build noch zum echten Talentbaum passt
--      (nodeID vorhanden? maxRank, Baum, Reihe, Spalte gleich?
--       Reihen-Voraussetzungen und Pfeile in dieser Reihenfolge erfüllbar?).
--   4. Mit den tatsächlich verteilten Punkten vergleichen:
--      erledigte Punkte, nächster Punkt, Abweichungen.
--
-- WICHTIG: "Welcher Punkt ist dran?" wird NICHT aus dem Level berechnet,
-- sondern aus den echt verteilten Punkten. So funktionieren auch
-- Legacy-Bonuspunkte, Umskillen und Abweichungen.
-- Das Level wird nur zur Anzeige berechnet (FIRST_TALENT_LEVEL + Punkt - 1).
-- ============================================================

local _, ns = ...
local L = ns.L

local Guide = {}
ns.modules.TalentGuide = Guide

local CHECK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t"
local CROSS = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t"
local ARROW = "|cffffd100>|r"

local function settings()
    return ns.db and ns.db.settings or ns.defaults.settings
end

-- Text in der passenden Sprache aus { deDE = ..., enUS = ... }
local function loc(tbl)
    if type(tbl) ~= "table" then return tbl or "" end
    return tbl[ns.locale] or tbl.enUS or ""
end
Guide.Loc = loc

-- ------------------------------------------------------------
-- Build auswählen und aufbereiten
-- ------------------------------------------------------------

-- Liefert den Build für die eigene Klasse (oder nil).
-- Später: Auswahl in den Einstellungen. Bis dahin: erster fertiger Leveling-Build.
function Guide:GetBuild()
    local _, classFile = UnitClass("player")
    local wanted = settings().talentBuild
    local fallback
    for _, build in ipairs(ns.TalentBuilds or {}) do
        if build.class == classFile and not build.planned and #(build.steps or {}) > 0 then
            if build.key == wanted then return build end
            if not fallback and build.buildType == "LEVELING" then fallback = build end
        end
    end
    return fallback
end

-- Wandelt die Schritte in eine Liste einzelner Punkte um.
-- points[k] = { index = k, level = ..., step = <Schritt>, targetRank = <Rang nach diesem Punkt> }
function Guide:ExpandPoints(build)
    if build._points then return build._points end
    local points, cumulative = {}, {}
    local firstLevel = ns:Const("FIRST_TALENT_LEVEL")
    for _, step in ipairs(build.steps) do
        for _ = 1, step.ranks do
            cumulative[step.nodeID] = (cumulative[step.nodeID] or 0) + 1
            local k = #points + 1
            points[k] = {
                index      = k,
                level      = firstLevel + k - 1,
                step       = step,
                targetRank = cumulative[step.nodeID],
            }
        end
    end
    build._points = points
    build._finalRanks = cumulative   -- Endrang je Talent laut Build
    return points
end

-- ------------------------------------------------------------
-- Prüfen gegen den echten Baum
-- ------------------------------------------------------------

-- Gibt eine Liste von Problemen zurück (leer = alles passt).
function Guide:Validate(build, tree)
    local problems = {}
    local function add(fmt, ...) table.insert(problems, string.format(fmt, ...)) end

    -- 1. Jeder Schritt: Talent vorhanden, Position und maxRank gleich?
    for i, step in ipairs(build.steps) do
        local live = step.nodeID and tree.byNode[step.nodeID]
        if step._missingName then
            add(L.CHECK_NAME_MISSING, i, step._missingName)
        elseif not live then
            add(L.CHECK_NODE_MISSING, i, step.nodeID or 0)
        else
            local name = live.name or ("#" .. step.nodeID)
            if live.maxRank ~= step.maxRank then
                add(L.CHECK_MAXRANK, name, step.maxRank, live.maxRank or 0)
            end
            if live.treeIndex ~= step.tree or live.tier ~= step.tier or live.column ~= step.column then
                add(L.CHECK_POSITION, name, step.tree, step.tier, step.column,
                    live.treeIndex or 0, live.tier or 0, live.column or 0)
            end
        end
    end
    if #problems > 0 then return problems end

    -- 2. Reihenfolge durchspielen: Reihen-Voraussetzung und Pfeile erfüllt?
    --    gateRequired = (Reihe-1) * 5 Punkte im selben Baum (Core/TalentAPI.lua).
    local spentInTree, rank = {}, {}
    local sources = {}   -- Ziel-nodeID -> Liste der Talente, deren Pfeil darauf zeigt
    for _, live in pairs(tree.byNode) do
        for _, target in ipairs(live.leadsTo or {}) do
            sources[target] = sources[target] or {}
            table.insert(sources[target], live)
        end
    end
    for _, p in ipairs(self:ExpandPoints(build)) do
        local step = p.step
        local live = tree.byNode[step.nodeID]
        local have = spentInTree[step.tree] or 0
        if have < (live.gateRequired or 0) then
            add(L.CHECK_GATE, p.index, live.name or "?", live.gateRequired, have)
        end
        for _, src in ipairs(sources[step.nodeID] or {}) do
            if (rank[src.nodeID] or 0) < (src.maxRank or 0) then
                add(L.CHECK_ARROW, p.index, live.name or "?", src.name or "?", src.maxRank or 0)
            end
        end
        if p.targetRank > (live.maxRank or 0) then
            add(L.CHECK_TOO_MANY, live.name or "?", p.targetRank, live.maxRank or 0)
        end
        spentInTree[step.tree] = have + 1
        rank[step.nodeID] = (rank[step.nodeID] or 0) + 1
    end
    return problems
end

-- ------------------------------------------------------------
-- Fortschritt: was ist erledigt, was kommt als Nächstes?
-- ------------------------------------------------------------

-- Rückgabe: { done = Anzahl erledigter Punkte, nextPoint = Punkt oder nil,
--             deviations = Liste { live, have, want } }
function Guide:GetProgress(build, tree)
    local points = self:ExpandPoints(build)
    local progress = { done = 0, deviations = {}, total = #points }

    for _, p in ipairs(points) do
        local live = tree.byNode[p.step.nodeID]
        local have = live and live.rank or 0
        if have >= p.targetRank then
            progress.done = progress.done + 1
        elseif not progress.nextPoint then
            progress.nextPoint = p
        end
    end

    -- Abweichungen: Punkte in Talenten, die der Build (so hoch) nicht vorsieht
    local final = build._finalRanks
    for nodeID, live in pairs(tree.byNode) do
        local want = final[nodeID] or 0
        if (live.rank or 0) > want then
            table.insert(progress.deviations, { live = live, have = live.rank, want = want })
        end
    end
    return progress
end

-- ------------------------------------------------------------
-- Ausgabe im Chat
-- ------------------------------------------------------------

local function pointLine(p, live)
    return string.format(L.GUIDE_POINT_LINE,
        p.index, p.level, live and live.name or ("#" .. p.step.nodeID),
        p.targetRank, p.step.maxRank)
end

-- Liest Baum + Build und gibt alles zurück, was die Anzeigen brauchen.
-- Bei Problemen: nil + Text.
function Guide:Load()
    local build = self:GetBuild()
    if not build then return nil, L.GUIDE_NO_BUILD end
    local tree = ns.TalentAPI:ReadTree()
    if not tree then return nil, L.TALENT_API_MISSING end
    self:ResolveByName(build, tree)
    return build, tree
end

-- Builds ohne nodeID (resolveByName): Talent über seinen Namen im echten Baum
-- suchen (deutscher Client: de, sonst en) und nodeID, Reihe, Spalte, maxRank
-- aus dem Spiel übernehmen. Nicht gefundene Schritte bekommen _missingName.
function Guide:ResolveByName(build, tree)
    if not build.resolveByName or build._resolved then return end
    local function norm(s) return s and s:lower():gsub("[%s%-]", "") end
    for _, step in ipairs(build.steps) do
        if not step.nodeID then
            local wanted = norm((ns.locale == "deDE" and step.de) or step.en)
            local found
            -- zuerst im angegebenen Baum, dann in allen Bäumen
            local searchTrees = { tree.trees[step.tree] }
            for _, t in ipairs(tree.trees) do table.insert(searchTrees, t) end
            for _, t in ipairs(searchTrees) do
                for _, live in ipairs(t and t.talents or {}) do
                    if norm(live.name) == wanted then found = live break end
                end
                if found then break end
            end
            if found then
                step.nodeID, step.tier, step.column, step.maxRank = found.nodeID, found.tier, found.column, found.maxRank
                step.tree = found.treeIndex
            else
                step._missingName = (ns.locale == "deDE" and step.de) or step.en
            end
        end
    end
    build._resolved = true
end

-- Kurzer Hinweis auf den nächsten Punkt (für Level-Up-Meldungen)
function Guide:PrintNext()
    if not settings().talentGuide then return end
    local build, tree = self:Load()
    if not build then return end
    if #self:Validate(build, tree) > 0 then return end
    local progress = self:GetProgress(build, tree)
    local p = progress.nextPoint
    if p then
        ns:Print(L.GUIDE_NEXT, pointLine(p, tree.byNode[p.step.nodeID]))
        local reason = loc(p.step.reason)
        if reason ~= "" then ns:Print("   " .. reason) end
        if settings().talentHighlight then
            ns:Print("   " .. L.GUIDE_HIGHLIGHT_HINT)
        end
    end
end

-- /ww build – Übersicht
function Guide:PrintSummary()
    local build, tree = self:Load()
    if not build then ns:Print(tree) return end

    ns:Print("|cffffd100%s|r – %s", loc(build.title), loc(build.summary))

    local problems = self:Validate(build, tree)
    if #problems > 0 then
        ns:Print(L.GUIDE_TREE_CHANGED)
        for _, text in ipairs(problems) do ns:Print("  " .. CROSS .. " " .. text) end
        return
    end

    local progress = self:GetProgress(build, tree)
    ns:Print(L.GUIDE_PROGRESS, progress.done, progress.total)
    local p = progress.nextPoint
    if p then
        ns:Print(L.GUIDE_NEXT, pointLine(p, tree.byNode[p.step.nodeID]))
        local reason = loc(p.step.reason)
        ns:Print("   " .. loc(build.phases[p.step.phase]) .. (reason ~= "" and (": " .. reason) or ""))
    else
        ns:Print(L.GUIDE_COMPLETE)
    end
    for _, d in ipairs(progress.deviations) do
        ns:Print(L.GUIDE_DEVIATION, d.live.name or "?", d.have, d.want)
    end
    ns:Print(L.GUIDE_MORE)
end

-- /ww build liste – alle Schritte mit Häkchen
function Guide:PrintList()
    local build, tree = self:Load()
    if not build then ns:Print(tree) return end
    local points = self:ExpandPoints(build)
    local nextPoint = self:GetProgress(build, tree).nextPoint

    -- Schritte mit ihren Punkt-Bereichen ausgeben, nach Phasen gruppiert
    local index, lastPhase = 1, nil
    for _, step in ipairs(build.steps) do
        if step.phase ~= lastPhase then
            ns:Print("|cffffd100%s|r", loc(build.phases[step.phase]))
            lastPhase = step.phase
        end
        local first, last = points[index], points[index + step.ranks - 1]
        index = index + step.ranks
        local live = tree.byNode[step.nodeID]
        local have = live and live.rank or 0
        local mark
        if have >= last.targetRank then
            mark = CHECK
        elseif nextPoint and nextPoint.step == step then
            mark = ARROW
        else
            mark = "  "
        end
        ns:Print(L.GUIDE_LIST_LINE, mark,
            first.level == last.level and tostring(first.level) or (first.level .. "–" .. last.level),
            live and live.name or ("#" .. step.nodeID), last.targetRank, step.maxRank)
    end
end

-- /ww build hinweise – bekannte Kompromisse
function Guide:PrintNotes()
    local build = self:GetBuild()
    if not build then ns:Print(L.GUIDE_NO_BUILD) return end
    ns:Print(L.GUIDE_NOTES_HEADER)
    for _, note in ipairs(build.notes or {}) do
        ns:Print("  - " .. loc(note))
    end
end

-- ------------------------------------------------------------
-- Automatische Prüfung nach dem Einloggen
-- ------------------------------------------------------------

function Guide:OnInitialize()
    local checked = false
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
        if checked or not (isInitialLogin or isReloadingUi) then return end
        checked = true
        C_Timer.After(6, function()
            ns:RunOutOfCombat(function()
                if not settings().talentGuide then return end
                local build, tree = Guide:Load()
                if build and #Guide:Validate(build, tree) > 0 then
                    ns:Print(L.GUIDE_TREE_CHANGED .. " " .. L.GUIDE_SEE_BUILD)
                end
            end, true)
        end)
    end)
end
