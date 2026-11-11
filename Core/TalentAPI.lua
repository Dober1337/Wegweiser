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

-- Tastenbelegung für das Talentfenster als Text (z. B. "N"), sonst nil.
function TalentAPI:GetTalentKeyText()
    local key = GetBindingKey and GetBindingKey("TOGGLETALENTS")
    if key and GetBindingText then
        return GetBindingText(key)
    end
    return key
end
