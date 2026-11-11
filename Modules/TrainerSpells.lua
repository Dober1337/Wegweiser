-- ============================================================
-- Modules/TrainerSpells.lua
-- "Was lerne ich als Nächstes?" – Fähigkeiten beim Klassenlehrer.
--
-- Beim Besuch eines KLASSENlehrers liest Wegweiser dessen komplette Liste
-- aus (auch die ausgegrauten Fähigkeiten für spätere Level) und merkt sie
-- sich pro Klasse. Danach:
--   * Levelaufstieg: "Neu beim Klassenlehrer: Blitzschlag (Rang 3), …"
--   * /ww lernen: was jetzt lernbar ist und was in den nächsten Leveln kommt
-- Keine fremden Daten: alles kommt aus dem Lehrerfenster (GetTrainerServiceInfo
-- liefert Name, Status, benötigte Stufe, Rang – geprüft im Forever-UI-Quellcode).
--
-- Filter: Ist im Lehrerfenster "Nicht verfügbar" ausgeblendet, fehlen die
-- zukünftigen Fähigkeiten. Wegweiser ändert den Filter NICHT, merkt sich aber,
-- ob die Liste vollständig war, und weist darauf hin.
-- ============================================================

local _, ns = ...
local L = ns.L

local TS = {}
ns.modules.TrainerSpells = TS

local function settings()
    return ns.db and ns.db.settings or ns.defaults.settings
end

local function classStore(create)
    local _, classFile = UnitClass("player")
    if not ns.db or not classFile then return nil end
    ns.db.trainerSpells = ns.db.trainerSpells or {}
    if create and not ns.db.trainerSpells[classFile] then
        ns.db.trainerSpells[classFile] = { spells = {} }
    end
    return ns.db.trainerSpells[classFile]
end

-- ------------------------------------------------------------
-- Lehrerliste einlesen
-- ------------------------------------------------------------

local hintedFilter, savedNoticeShown = false, false

function TS:Scan()
    if not GetNumTrainerServices or not GetTrainerServiceInfo then return end
    -- nur Klassenlehrer (keine Berufs- oder Tierlehrer)
    if IsTradeskillTrainer and IsTradeskillTrainer() then return end
    if C_Trainer and C_Trainer.GetTrainerType and Enum.TrainerType
        and C_Trainer.GetTrainerType() ~= Enum.TrainerType.General then return end

    local store = classStore(true)
    if not store then return end
    local complete = not GetTrainerServiceTypeFilter or GetTrainerServiceTypeFilter("unavailable")
    local count = 0
    for i = 1, GetNumTrainerServices() do
        local name, serviceType, icon, reqLevel, subText = GetTrainerServiceInfo(i)
        if name and serviceType and serviceType ~= "header" then
            local key = name .. "|" .. (subText or "")
            local e = store.spells[key] or {}
            e.name, e.rank, e.level, e.icon = name, subText ~= "" and subText or nil, reqLevel or 1, icon
            e.status = serviceType          -- "available" | "unavailable" | "used"
            store.spells[key] = e
            count = count + 1
        end
    end
    if count == 0 then return end
    store.scanned = date("%Y-%m-%d")
    store.complete = store.complete or complete
    if not savedNoticeShown then
        savedNoticeShown = true
        ns:Print(L.TS_SAVED, count)
    end
    if not complete and not hintedFilter then
        hintedFilter = true
        ns:Print(L.TS_FILTER_HINT)
    end
end

-- ------------------------------------------------------------
-- Auswertung
-- ------------------------------------------------------------

-- Fähigkeiten mit genau dieser Stufe (sortiert)
function TS:SpellsAtLevel(level)
    local store = classStore(false)
    if not store then return nil end
    local list = {}
    for _, e in pairs(store.spells) do
        if e.level == level then table.insert(list, e) end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list, store.complete
end

local function label(e)
    return e.rank and (e.name .. " (" .. e.rank .. ")") or e.name
end

-- Zeile für die Level-Up-Meldung oder nil (wenn nichts bekannt)
function TS:LevelUpText(level)
    local list, complete = self:SpellsAtLevel(level)
    if not list then return nil end
    if #list > 0 then
        local names = {}
        for _, e in ipairs(list) do table.insert(names, label(e)) end
        return string.format(L.TS_NEW_AT_LEVEL, table.concat(names, ", "))
    elseif complete then
        return false   -- Liste vollständig, auf diesem Level gibt es nichts Neues
    end
    return nil
end

-- /ww lernen
function TS:PrintOverview()
    local store = classStore(false)
    if not store or not next(store.spells) then
        ns:Print(L.TS_NO_DATA)
        return
    end
    local level = UnitLevel("player")
    -- jetzt lernbar (laut letztem Besuch), Stufe erreicht, noch nicht gelernt
    local now = {}
    for _, e in pairs(store.spells) do
        if e.status ~= "used" and e.level <= level then table.insert(now, e) end
    end
    table.sort(now, function(a, b) return a.level < b.level or (a.level == b.level and a.name < b.name) end)
    if #now > 0 then
        local names = {}
        for _, e in ipairs(now) do table.insert(names, label(e)) end
        ns:Print(L.TS_NOW, table.concat(names, ", "))
    else
        ns:Print(L.TS_NOTHING_NOW)
    end
    -- die nächsten Level
    local shown = 0
    for lvl = level + 1, level + 10 do
        local list = self:SpellsAtLevel(lvl)
        if list and #list > 0 then
            local names = {}
            for _, e in ipairs(list) do table.insert(names, label(e)) end
            ns:Print(L.TS_LEVEL_LINE, lvl, table.concat(names, ", "))
            shown = shown + 1
            if shown >= 5 then break end
        end
    end
    if shown == 0 then ns:Print(L.TS_NOTHING_SOON) end
    if not store.complete then ns:Print(L.TS_FILTER_HINT) end
    ns:Print("|cff999999" .. string.format(L.TS_SOURCE, store.scanned or "?") .. "|r")
end

-- Nach dem Lernen: Status beim nächsten Lehrerbesuch aktualisiert; bis dahin
-- per Zauberbuch prüfen wäre ohne Zauber-IDs unsicher -> bewusst nicht.

function TS:OnInitialize()
    local function scanLater()
        C_Timer.After(0.3, function() ns:RunOutOfCombat(function() TS:Scan() end, true) end)
    end
    ns:RegisterEvent("TRAINER_SHOW", scanLater)
    ns:RegisterEvent("TRAINER_UPDATE", scanLater)   -- z. B. nach Lernen oder Filterwechsel
end
