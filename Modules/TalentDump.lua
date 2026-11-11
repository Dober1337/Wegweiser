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
--   * pro Baum: Name, Symbol, verteilte Punkte, Punkte-Voraussetzung je Reihe
--   * pro Talent: nodeID, Name, Reihe (tier), Spalte (column), maxRank,
--     aktueller Rang, Symbol, Rohposition (posX/posY), Pfeile zu anderen
--     Talenten (leadsTo) und die Bedingungen (gateRequired = nötige Punkte im Baum)
--
-- Das eigentliche Auslesen macht ns.TalentAPI:ReadTree() (Core/TalentAPI.lua),
-- das auch der Talent-Leitfaden benutzt.
-- ============================================================

local _, ns = ...
local L = ns.L

local TalentDump = {}
ns.modules.TalentDump = TalentDump

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

local ERROR_TEXT = {
    NO_API    = "TALENT_API_MISSING",
    NO_CONFIG = "DUMP_NO_CONFIG",
    NO_TREE   = "DUMP_NO_TREE",
}

function TalentDump:Run()
    local _, classFile = UnitClass("player")
    local dump = {
        meta = {
            date             = date("%Y-%m-%d %H:%M"),
            build            = select(2, GetBuildInfo()),
            version          = (GetBuildInfo()),
            interface        = select(4, GetBuildInfo()),
            locale           = GetLocale(),
            class            = classFile,
            level            = UnitLevel("player"),
            addonVersion     = ns.version,
            firstTalentLevel = ns:Const("FIRST_TALENT_LEVEL"),
        },
        apiProbe = probeAPI(),
    }
    ns.db.talentDump[classFile] = dump

    local tree, err = ns.TalentAPI:ReadTree()
    if not tree then
        ns:Print(L.DUMP_FAILED, L[ERROR_TEXT[err] or "DUMP_NO_TREE"])
        return
    end

    local spent, unspent, maxPoints = ns.TalentAPI:GetPoints()
    dump.meta.configID = tree.configID
    dump.meta.treeID   = tree.treeID
    dump.meta.grid     = tree.grid
    dump.points        = { spent = spent, unspent = unspent, max = maxPoints }
    dump.trees         = tree.trees
    dump.ungrouped     = tree.ungrouped

    local count = 0
    for _, t in ipairs(tree.trees) do count = count + #t.talents end
    ns:Print(L.DUMP_DONE, #tree.trees, count)
    ns:Print(L.DUMP_FILE_HINT)
end

-- Einstiegspunkt für den Slash-Befehl: nur außerhalb des Kampfes.
function TalentDump:Start()
    ns:RunOutOfCombat(function() TalentDump:Run() end)
end
