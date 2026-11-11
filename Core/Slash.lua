-- ============================================================
-- Core/Slash.lua
-- Chat-Befehl /ww (und /wegweiser).
--
--   /ww              -> Hilfe
--   /ww config       -> Einstellungen
--   /ww punkte       -> Talentpunkte anzeigen (auch: /ww points)
--   /ww build        -> Talent-Leitfaden: Fortschritt + nächster Punkt
--   /ww build liste  -> alle Schritte des Builds mit Häkchen
--   /ww build hinweise -> bekannte Kompromisse des Builds
--   /ww quests       -> Quest-Berater: alle Quests im Log bewertet
--   /ww talentdump   -> Talentbaum auslesen und speichern
--   /ww test         -> Beispiel-Hinweis zum Levelaufstieg
-- ============================================================

local _, ns = ...
local L = ns.L

local function showHelp()
    ns:Print(L.HELP_HEADER)
    ns:Print(L.HELP_CONFIG)
    ns:Print(L.HELP_POINTS)
    ns:Print(L.HELP_BUILD)
    ns:Print(L.HELP_BUILD_LIST)
    ns:Print(L.HELP_BUILD_NOTES)
    ns:Print(L.HELP_QUESTS)
    ns:Print(L.HELP_TALENTDUMP)
    ns:Print(L.HELP_TEST)
end

local function showPoints()
    ns:RunOutOfCombat(function()
        local spent, unspent = ns.TalentAPI:GetPoints()
        if not spent then
            ns:Print(L.TALENT_API_MISSING)
            return
        end
        ns:Print(L.POINTS_STATUS, spent, unspent)
        local trees = ns.TalentAPI:GetTrees()
        for _, tree in ipairs(trees or {}) do
            ns:Print(L.POINTS_TREE, tree.name or "?", tree.spent or 0)
        end
    end)
end

-- /ww build [liste|hinweise]
local function buildCommand(arg)
    local guide = ns.modules.TalentGuide
    ns:RunOutOfCombat(function()
        if arg == "liste" or arg == "list" then
            guide:PrintList()
        elseif arg == "hinweise" or arg == "notes" then
            guide:PrintNotes()
        else
            guide:PrintSummary()
        end
    end)
end

-- Befehl -> Funktion. Mehrere Namen für denselben Befehl sind erlaubt.
local commands = {
    config     = function() ns:OpenSettings() end,
    optionen   = function() ns:OpenSettings() end,
    punkte     = showPoints,
    points     = showPoints,
    talentdump = function() ns.modules.TalentDump:Start() end,
    build      = buildCommand,
    questinfo  = function() ns.modules.QuestAdvisor:PrintOfferDebug() end,
    quests     = function() ns:RunOutOfCombat(function() ns.modules.QuestAdvisor:PrintOverview() end) end,
    debug      = function() ns:RunOutOfCombat(function() ns.modules.TalentHighlight:Diagnose() end) end,
    test       = function()
        ns:Print(L.TEST_HEADER)
        ns.modules.LevelUp:ShowLevelUpMessages(UnitLevel("player"), true)
        ns:RunOutOfCombat(function() ns.modules.LevelUp:CheckTalentPoints() end, true)
    end,
    help       = showHelp,
    hilfe      = showHelp,
}

SLASH_WEGWEISER1 = "/ww"
SLASH_WEGWEISER2 = "/wegweiser"
SlashCmdList.WEGWEISER = function(msg)
    -- Erstes Wort = Befehl, zweites Wort = Zusatz (beides klein geschrieben)
    local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(%S*)")
    cmd, arg = cmd:lower(), arg:lower()
    if cmd == "" then
        showHelp()
        return
    end
    local handler = commands[cmd]
    if handler then
        handler(arg)
    else
        ns:Print(L.UNKNOWN_COMMAND, cmd)
        showHelp()
    end
end
