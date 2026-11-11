-- ============================================================
-- Modules/TalentDump.lua
-- Prüf-Befehl /ww talentdump
--
-- Liest den ECHTEN Talentbaum aus dem Spiel und speichert ihn in
--   WegweiserDB.talentDump[<KLASSE>]
-- Nach /reload steht er in WTF\Account\<KONTONAME>\SavedVariables\Wegweiser.lua
--
-- Gespeichert wird u. a.:
--   * welche Talent-Funktionen der Client überhaupt hat (apiProbe)
--   * Talentpunkte gesamt (verteilt / frei / maximal)
--   * pro Baum: Name, Symbol, verteilte Punkte
--   * pro Talent: nodeID, Name, Reihe (tier), Spalte (column), maxRank,
--     aktueller Rang, Symbol, Rohposition (posX/posY), Pfeile zu anderen
--     Talenten und die Bedingungen (z. B. "5 Punkte im Baum nötig").
--
-- Reihe/Spalte: Die API liefert nur Pixel-Positionen. Wir rechnen sie in
-- Reihe/Spalte um. Zur Kontrolle speichern wir zusätzlich die Reihe, die
-- sich aus der Punkte-Bedingung ergibt (tierFromGate). Stimmen beide
-- überein, ist die Umrechnung richtig.
-- ============================================================

local _, ns = ...
local L = ns.L

local TalentDump = {}
ns.modules.TalentDump = TalentDump

-- ------------------------------------------------------------
-- Hilfsfunktionen
-- ------------------------------------------------------------

-- Welche Talent-Funktionen gibt es im Client? (Antwort: "function" oder "nil")
local function probeAPI()
    local function t(v) return type(v) end
    return {
        -- alte Classic-API
        GetTalentInfo            = t(GetTalentInfo),
        GetNumTalentTabs         = t(GetNumTalentTabs),
        GetTalentTabInfo         = t(GetTalentTabInfo),
        GetUnspentTalentPoints   = t(GetUnspentTalentPoints),
        -- moderne API
        C_Traits                 = t(C_Traits),
        C_ClassTalents           = t(C_ClassTalents),
        C_SpecializationInfo     = t(C_SpecializationInfo),
        ["C_SpecializationInfo.GetTalentInfo"] =
            t(C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo),
        ["C_Traits.GetGroupDisplayInfoByTreeID"] =
            t(C_Traits and C_Traits.GetGroupDisplayInfoByTreeID),
        -- Talentfenster (wird erst beim Öffnen geladen)
        PlayerSpellsFrame        = t(PlayerSpellsFrame),
        PlayerSpellsLoaded       = C_AddOns and C_AddOns.IsAddOnLoaded("Blizzard_PlayerSpells") and "yes" or "no",
    }
end

-- Sortierte Liste der unterschiedlichen Werte
local function distinctSorted(values)
    local seen, list = {}, {}
    for _, v in ipairs(values) do
        local r = math.floor(v + 0.5)
        if not seen[r] then
            seen[r] = true
            table.insert(list, r)
        end
    end
    table.sort(list)
    return list
end

-- Kleinster Abstand zwischen zwei benachbarten Werten (= Rasterabstand)
local function gridStep(sortedList)
    local step
    for i = 2, #sortedList do
        local d = sortedList[i] - sortedList[i - 1]
        if d > 5 and (not step or d < step) then
            step = d
        end
    end
    return step
end

-- Name und Symbol eines Talents über Eintrag -> Definition -> Zauber
local function readEntry(configID, entryID)
    local result = { entryID = entryID }
    local entry = C_Traits.GetEntryInfo(configID, entryID)
    if not entry then return result end
    result.maxRanks = entry.maxRanks
    local def = entry.definitionID and C_Traits.GetDefinitionInfo(entry.definitionID)
    if def then
        result.spellID = def.spellID
        result.name = def.overrideName
        if (not result.name or result.name == "") and def.spellID and C_Spell then
            result.name = C_Spell.GetSpellName(def.spellID)
        end
        result.icon = def.overrideIcon
        if (not result.icon or result.icon == 0) and def.spellID and C_Spell then
            result.icon = C_Spell.GetSpellTexture(def.spellID)
        end
    end
    return result
end

-- Bedingungen eines Talents (z. B. "X Punkte im Baum" oder "Level Y")
local function readConditions(configID, conditionIDs)
    local list = {}
    for _, condID in ipairs(conditionIDs or {}) do
        local c = C_Traits.GetConditionInfo(configID, condID)
        if c then
            table.insert(list, {
                condID              = condID,
                isGate              = c.isGate,
                isMet               = c.isMet,
                type                = c.type,
                spentAmountRequired = c.spentAmountRequired,
                playerLevel         = c.playerLevel,
                traitCurrencyID     = c.traitCurrencyID,
            })
        end
    end
    return list
end

-- ------------------------------------------------------------
-- Hauptfunktion
-- ------------------------------------------------------------

function TalentDump:Run()
    local _, classFile = UnitClass("player")
    local dump = {
        meta = {
            date          = date("%Y-%m-%d %H:%M"),
            build         = select(2, GetBuildInfo()),
            version       = (GetBuildInfo()),
            interface     = select(4, GetBuildInfo()),
            locale        = GetLocale(),
            class         = classFile,
            level         = UnitLevel("player"),
            addonVersion  = ns.version,
            firstTalentLevel = ns:Const("FIRST_TALENT_LEVEL"),
        },
        apiProbe = probeAPI(),
    }

    -- Ohne moderne Talent-API: nur die Prüfung speichern und abbrechen.
    if not ns.TalentAPI:IsAvailable() then
        ns.db.talentDump[classFile] = dump
        ns:Print(L.DUMP_FAILED, L.TALENT_API_MISSING)
        return
    end

    local trees, configID, treeID = ns.TalentAPI:GetTrees()
    if not configID then
        ns.db.talentDump[classFile] = dump
        ns:Print(L.DUMP_FAILED, L.DUMP_NO_CONFIG)
        return
    end
    if not trees then
        ns.db.talentDump[classFile] = dump
        ns:Print(L.DUMP_FAILED, L.DUMP_NO_TREE)
        return
    end

    local spent, unspent, maxPoints = ns.TalentAPI:GetPoints()
    dump.meta.configID = configID
    dump.meta.treeID   = treeID
    dump.points = { spent = spent, unspent = unspent, max = maxPoints }

    -- Schnellzugriff groupID -> Baum
    local treeByGroup = {}
    for _, tree in ipairs(trees) do
        tree.talents = {}
        treeByGroup[tree.groupID] = tree
    end
    dump.ungrouped = {}  -- Knoten, die keinem der drei Bäume zugeordnet sind

    -- 1. Alle sichtbaren Knoten einsammeln
    local nodeIDs = C_Traits.GetTreeNodes(treeID) or {}
    for _, nodeID in ipairs(nodeIDs) do
        local node = C_Traits.GetNodeInfo(configID, nodeID)
        if node and node.ID and node.ID ~= 0 and node.isVisible then
            local talent = {
                nodeID      = nodeID,
                posX        = node.posX,
                posY        = node.posY,
                maxRank     = node.maxRanks,
                rank        = node.ranksPurchased,
                activeRank  = node.activeRank,
                nodeType    = node.type,
                groupIDs    = node.groupIDs,
                leadsTo     = {},
                conditions  = readConditions(configID, node.conditionIDs),
                entries     = {},
            }
            for _, edge in ipairs(node.visibleEdges or {}) do
                table.insert(talent.leadsTo, edge.targetNode)
            end
            for _, entryID in ipairs(node.entryIDs or {}) do
                table.insert(talent.entries, readEntry(configID, entryID))
            end
            -- Name/Symbol/Zauber vom ersten Eintrag direkt am Talent ablegen
            local first = talent.entries[1]
            if first then
                talent.name    = first.name
                talent.icon    = first.icon
                talent.spellID = first.spellID
            end

            -- Welchem Baum gehört der Knoten?
            local owner
            for _, gid in ipairs(node.groupIDs or {}) do
                if treeByGroup[gid] then owner = treeByGroup[gid] break end
            end
            if owner then
                table.insert(owner.talents, talent)
            else
                table.insert(dump.ungrouped, talent)
            end
        end
    end

    -- 2. Rasterabstände über ALLE Bäume bestimmen
    local allX, allY = {}, {}
    for _, tree in ipairs(trees) do
        for _, t in ipairs(tree.talents) do
            table.insert(allX, t.posX)
            table.insert(allY, t.posY)
        end
    end
    local ys = distinctSorted(allY)
    local stepY = gridStep(ys)
    local stepX = gridStep(distinctSorted(allX))
    local minY = ys[1]
    dump.meta.grid = { stepX = stepX, stepY = stepY, minY = minY }

    -- 3. Reihe/Spalte je Baum berechnen und gegen Bedingungen prüfen
    local tierPoints = ns:Const("POINTS_PER_TIER")
    local talentCount = 0
    for _, tree in ipairs(trees) do
        local minX
        for _, t in ipairs(tree.talents) do
            if not minX or t.posX < minX then minX = t.posX end
        end
        local maxColumn = 0
        for _, t in ipairs(tree.talents) do
            talentCount = talentCount + 1
            if stepY and minY then
                t.tier = math.floor((t.posY - minY) / stepY + 0.5) + 1
            end
            if stepX and minX then
                t.column = math.floor((t.posX - minX) / stepX + 0.5) + 1
                if t.column > maxColumn then maxColumn = t.column end
            end
            -- Kontrolle über die Punkte-Bedingung ("Reihe n braucht (n-1)*5")
            for _, c in ipairs(t.conditions) do
                if c.spentAmountRequired and c.spentAmountRequired > 0 then
                    t.tierFromGate = c.spentAmountRequired / tierPoints + 1
                end
            end
            if t.tierFromGate and t.tier and t.tierFromGate ~= t.tier then
                t.tierMismatch = true
            end
        end
        -- Wenn ein Baum keine 4 Spalten belegt, ist die Spalten-Zählung
        -- evtl. verschoben (z. B. wenn Spalte 1 komplett leer ist).
        tree.columnsUsed = maxColumn
        tree.columnsCertain = (maxColumn == 4)

        -- Lesbare Reihenfolge: nach Reihe, dann Spalte
        table.sort(tree.talents, function(a, b)
            if (a.tier or 0) ~= (b.tier or 0) then return (a.tier or 0) < (b.tier or 0) end
            return (a.column or 0) < (b.column or 0)
        end)
    end

    dump.trees = trees
    ns.db.talentDump[classFile] = dump

    ns:Print(L.DUMP_DONE, #trees, talentCount)
    ns:Print(L.DUMP_FILE_HINT)
end

-- Einstiegspunkt für den Slash-Befehl: nur außerhalb des Kampfes.
function TalentDump:Start()
    ns:RunOutOfCombat(function() TalentDump:Run() end)
end
