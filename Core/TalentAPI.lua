-- ============================================================
-- Core/TalentAPI.lua
-- Kleine Hilfsschicht über die Talent-Schnittstelle von WoW Forever.
--
-- WICHTIG (geprüft im Blizzard-UI-Quellcode, Forever-Build 1.60.1.70888):
-- Forever benutzt NICHT mehr die alten Classic-Funktionen
-- (GetTalentInfo, GetNumTalentTabs, ...). Stattdessen läuft alles über das
-- moderne "Trait"-System (C_Traits / C_ClassTalents):
--   * Pro Klasse gibt es EINEN Talentbaum ("treeID").
--   * Die drei klassischen Bäume (z. B. Elementar/Verstärkung/Wiederherstellung)
--     sind darin "Gruppen" (groupID) mit eigenem Namen und Symbol.
--   * Jedes Talent ist ein "Knoten" (nodeID) mit Pixel-Position (posX/posY),
--     NICHT mit Reihe/Spalte. Reihe/Spalte rechnen wir selbst aus.
--   * Talentpunkte sind eine "Währung" (currency) des Baums.
--
-- Alle Funktionen hier geben bei Problemen nil zurück, statt einen
-- Lua-Fehler zu werfen. So bleibt das Spiel stabil, falls Blizzard
-- etwas ändert.
-- ============================================================

local _, ns = ...

local TalentAPI = {}
ns.TalentAPI = TalentAPI

-- Gibt es die moderne Talent-Schnittstelle überhaupt?
function TalentAPI:IsAvailable()
    return C_ClassTalents ~= nil
        and C_ClassTalents.GetActiveConfigID ~= nil
        and C_Traits ~= nil
        and C_Traits.GetConfigInfo ~= nil
end

-- Die aktive Talent-Konfiguration des Spielers (eine Zahl) oder nil.
-- Bei Dualspec gibt es zwei Konfigurationen; das ist immer die gerade aktive.
function TalentAPI:GetConfigID()
    if not self:IsAvailable() then return nil end
    return C_ClassTalents.GetActiveConfigID()
end

-- Die Baum-ID der eigenen Klasse oder nil.
function TalentAPI:GetTreeID(configID)
    configID = configID or self:GetConfigID()
    if not configID then return nil end
    local info = C_Traits.GetConfigInfo(configID)
    if info and info.treeIDs and info.treeIDs[1] then
        return info.treeIDs[1]
    end
    return nil
end

-- Talentpunkte gesamt: liefert verteilt, frei, (maximal) oder nil.
-- "frei" kommt direkt aus der API – so werden später auch
-- Legacy-Bonuspunkte automatisch mitgezählt.
function TalentAPI:GetPoints()
    local configID = self:GetConfigID()
    local treeID = self:GetTreeID(configID)
    if not treeID then return nil end

    local infos = C_Traits.GetTreeCurrencyInfo(configID, treeID, false)
    local info = infos and infos[1]
    if not info then return nil end
    return info.spent or 0, info.quantity or 0, info.maxQuantity
end

-- Die drei Talentbäume (Gruppen) in Anzeige-Reihenfolge, jeweils mit
-- Name, Symbol und verteilten Punkten. Rückgabe: Liste oder nil.
--   { { index = 1, groupID = ..., name = "Elementar", icon = ..., spent = 0 }, ... }
function TalentAPI:GetTrees()
    local configID = self:GetConfigID()
    local treeID = self:GetTreeID(configID)
    if not treeID or not C_Traits.GetGroupDisplayInfoByTreeID then return nil end

    local displayInfos = C_Traits.GetGroupDisplayInfoByTreeID(treeID)
    if not displayInfos or #displayInfos == 0 then return nil end

    -- Nach Blizzards Anzeige-Reihenfolge sortieren (links -> rechts).
    local sorted = {}
    for _, d in ipairs(displayInfos) do table.insert(sorted, d) end
    table.sort(sorted, function(a, b) return (a.orderIndex or 0) < (b.orderIndex or 0) end)

    local groupIDs, trees = {}, {}
    for i, d in ipairs(sorted) do
        groupIDs[i] = d.groupID
        trees[i] = {
            index       = i,
            groupID     = d.groupID,
            name        = d.displayName,
            icon        = d.icon,
            orderIndex  = d.orderIndex,
            skillLineID = d.skillLineID,
            spent       = 0,
        }
    end

    -- Verteilte Punkte pro Baum
    if C_Traits.GetGroupCurrencyInfo then
        local groupInfos = C_Traits.GetGroupCurrencyInfo(configID, groupIDs) or {}
        for _, gi in ipairs(groupInfos) do
            for _, tree in ipairs(trees) do
                if tree.groupID == gi.traitNodeGroupID then
                    local c = gi.currencyInfos and gi.currencyInfos[1]
                    tree.spent = c and (c.spentInTree or c.spent) or 0
                end
            end
        end
    end

    return trees, configID, treeID
end

-- ------------------------------------------------------------
-- Kompletten Baum mit allen Talenten auslesen
-- ------------------------------------------------------------

-- Name, Symbol und Zauber eines Talent-Eintrags
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

-- Bedingungen eines Talents (z. B. "X Punkte im Baum nötig")
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

-- Sortierte Liste unterschiedlicher (gerundeter) Werte
-- Werte zu "Rasterlinien" zusammenfassen: Talente, die nur ein paar Pixel
-- versetzt liegen, gehören zur selben Reihe/Spalte. (Beim Jäger liegt mindestens
-- ein Talent leicht neben dem Raster – ohne das hier entstanden "Reihe 181".)
-- Toleranz: ein Viertel des TYPISCHEN Abstands (Median der echten Lücken).
-- Nicht der größte Abstand: Einzelne "Geister-Talente" weit außerhalb des Baums
-- (z. B. beim Jäger y = 39300) würden die Toleranz sonst riesig machen.
local function distinctSorted(values)
    local sorted = {}
    for _, v in ipairs(values) do table.insert(sorted, v) end
    table.sort(sorted)
    if #sorted == 0 then return sorted end
    local gaps = {}
    for i = 2, #sorted do
        local d = sorted[i] - sorted[i - 1]
        if d > 5 then table.insert(gaps, d) end
    end
    table.sort(gaps)
    local typical = gaps[math.floor((#gaps + 1) / 2)] or 0
    local tol = typical * 0.25
    local centers, sum, count, start = {}, sorted[1], 1, sorted[1]
    for i = 2, #sorted do
        local v = sorted[i]
        if v - start <= tol then
            sum, count = sum + v, count + 1
        else
            table.insert(centers, sum / count)
            sum, count, start = v, 1, v
        end
    end
    table.insert(centers, sum / count)
    return centers
end

-- Kleinster Abstand zwischen benachbarten Werten (= Rasterabstand)
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

-- Liest den kompletten Talentbaum. Rückgabe: Tabelle oder nil, Fehlercode.
--   result.trees[i].talents  = Liste der Talente des Baums i
--   result.byNode[nodeID]    = Talent (mit .treeIndex)
-- Jedes Talent hat: nodeID, name, icon, spellID, tier, column, maxRank,
-- rank, posX, posY, leadsTo,
--   gateRequired  = Punkte, die im Baum INSGESAMT nötig sind ((Reihe-1) * 5)
--   gateRemaining = Punkte, die laut Spiel NOCH fehlen (Rohwert der API)
-- Achtung: Die API (spentAmountRequired) liefert die RESTLICHEN Punkte,
-- nicht die Gesamtzahl – bestätigt per Tooltip "Gebt noch 2 Punkte ... aus"
-- bei 3 verteilten Punkten (Spieler, Nov 2026).
-- Reihe/Spalte werden aus der Pixel-Position berechnet (Raster).
function TalentAPI:ReadTree()
    if not self:IsAvailable() then return nil, "NO_API" end
    local trees, configID, treeID = self:GetTrees()
    if not configID then return nil, "NO_CONFIG" end
    if not trees then return nil, "NO_TREE" end

    local treeByGroup = {}
    for _, tree in ipairs(trees) do
        tree.talents = {}
        treeByGroup[tree.groupID] = tree
    end
    local result = { trees = trees, configID = configID, treeID = treeID,
                     byNode = {}, ungrouped = {} }

    -- 1. Alle sichtbaren Knoten einsammeln
    for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
        local node = C_Traits.GetNodeInfo(configID, nodeID)
        if node and node.ID and node.ID ~= 0 and node.isVisible then
            local talent = {
                nodeID     = nodeID,
                posX       = node.posX,
                posY       = node.posY,
                maxRank    = node.maxRanks,
                rank       = node.ranksPurchased,
                activeRank = node.activeRank,
                nodeType   = node.type,
                groupIDs   = node.groupIDs,
                leadsTo    = {},
                conditions = readConditions(configID, node.conditionIDs),
                entries    = {},
            }
            for _, edge in ipairs(node.visibleEdges or {}) do
                table.insert(talent.leadsTo, edge.targetNode)
                -- Art der Verbindung merken (Enum.TraitEdgeType: 0 nur optisch,
                -- 2 ausreichend, 3 erforderlich, …) – nur 3 ist eine echte Voraussetzung
                talent.edgeTypes = talent.edgeTypes or {}
                talent.edgeTypes[edge.targetNode] = edge.type
            end
            for _, entryID in ipairs(node.entryIDs or {}) do
                table.insert(talent.entries, readEntry(configID, entryID))
            end
            local first = talent.entries[1]
            if first then
                talent.name, talent.icon, talent.spellID = first.name, first.icon, first.spellID
            end
            -- Noch fehlende Punkte für diese Reihe (Rohwert, nur zur Info)
            for _, c in ipairs(talent.conditions) do
                if c.spentAmountRequired and c.spentAmountRequired > 0 then
                    talent.gateRemaining = c.spentAmountRequired
                end
            end

            local owner
            for _, gid in ipairs(node.groupIDs or {}) do
                if treeByGroup[gid] then owner = treeByGroup[gid] break end
            end
            if owner then
                talent.treeIndex = owner.index
                table.insert(owner.talents, talent)
                result.byNode[nodeID] = talent
            else
                table.insert(result.ungrouped, talent)
            end
        end
    end

    -- 2. Raster über alle Bäume bestimmen
    local allX, allY = {}, {}
    for _, tree in ipairs(trees) do
        for _, t in ipairs(tree.talents) do
            table.insert(allX, t.posX)
            table.insert(allY, t.posY)
        end
    end
    local ys = distinctSorted(allY)
    -- Spaltenabstand je Baum ermitteln (Bäume liegen nebeneinander), kleinsten nehmen
    local stepX
    for _, tree in ipairs(trees) do
        local xs = {}
        for _, t in ipairs(tree.talents) do table.insert(xs, t.posX) end
        local s = gridStep(distinctSorted(xs))
        if s and (not stepX or s < stepX) then stepX = s end
    end
    local stepY, minY = gridStep(ys), ys[1]
    result.grid = { stepX = stepX, stepY = stepY, minY = minY }

    -- 3. Reihe/Spalte je Baum berechnen
    for _, tree in ipairs(trees) do
        -- linke Kante des Baums: kleinste x-Position (Ausreißer liegen bisher rechts/unten,
        -- werden unten über "Spalte > 4" aussortiert)
        local minX
        for _, t in ipairs(tree.talents) do
            if not minX or t.posX < minX then minX = t.posX end
        end
        local maxColumn = 0
        local perTier = ns:Const("POINTS_PER_TIER") or 5
        for _, t in ipairs(tree.talents) do
            if stepY and minY then
                t.tier = math.floor((t.posY - minY) / stepY + 0.5) + 1
            end
            if stepX and minX then
                t.column = math.floor((t.posX - minX) / stepX + 0.5) + 1
                if t.column > maxColumn then maxColumn = t.column end
            end
            if t.tier then
                t.gateRequired = (t.tier - 1) * perTier
                -- Gegenprobe: verteilt + noch fehlend = Gesamtbedarf?
                if t.gateRemaining then
                    t.gateConsistent = ((tree.spent or 0) + t.gateRemaining == t.gateRequired)
                end
            end
        end
        -- Talente außerhalb des Rasters (Reihe > 7 oder Spalte > 4) sind alte,
        -- unsichtbare Einträge (im Jäger-/Priester-Dump gefunden) -> ignorieren
        local kept = {}
        maxColumn = 0
        for _, t in ipairs(tree.talents) do
            if t.tier and t.column and t.tier >= 1 and t.tier <= 7 and t.column >= 1 and t.column <= 4 then
                table.insert(kept, t)
                if t.column > maxColumn then maxColumn = t.column end
            else
                result.byNode[t.nodeID] = nil
                result.offGrid = result.offGrid or {}
                table.insert(result.offGrid, t)
            end
        end
        tree.talents = kept
        -- Belegt ein Baum keine 4 Spalten, kann die Spaltenzählung verschoben sein.
        tree.columnsUsed = maxColumn
        tree.columnsCertain = (maxColumn == 4)
        table.sort(tree.talents, function(a, b)
            if (a.tier or 0) ~= (b.tier or 0) then return (a.tier or 0) < (b.tier or 0) end
            return (a.column or 0) < (b.column or 0)
        end)
    end

    return result
end

-- Darf man im Talentfenster selbst zurücksetzen? true / false / nil (unbekannt)
-- (TraitTreeInfo.cannotRefund – geprüft im Forever-UI-Quellcode; ist es gesetzt,
--  zeigt Blizzard keinen Zurücksetzen-Knopf, dann gilt "Talente verlernen" beim Lehrer)
function TalentAPI:CanRefundInFrame()
    local configID = self:GetConfigID()
    local treeID = self:GetTreeID(configID)
    if not treeID or not C_Traits.GetTreeInfo then return nil end
    local ok, info = pcall(C_Traits.GetTreeInfo, configID, treeID)
    if not ok or not info then return nil end
    return not info.cannotRefund
end

-- Tastenbelegung für das Talentfenster als Text (z. B. "N"), sonst nil.
function TalentAPI:GetTalentKeyText()
    local key = GetBindingKey and GetBindingKey("TOGGLETALENTS")
    if key and GetBindingText then
        return GetBindingText(key)
    end
    return key
end
