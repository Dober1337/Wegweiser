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

-- Hilfe für Spieler: nur die Befehle, die man im Alltag braucht
local function showHelp()
    ns:Print(L.HELP_HEADER)
    ns:Print(L.HELP_LEARN)
    ns:Print(L.HELP_QUESTS)
    ns:Print(L.HELP_ZONES)
    ns:Print(L.HELP_DUNGEONS)
    ns:Print(L.HELP_FLIGHT)
    ns:Print(L.HELP_HEARTH)
    ns:Print(L.HELP_GOLD)
    ns:Print(L.HELP_RIDING)
    ns:Print(L.HELP_LEGACY)
    ns:Print(L.HELP_PROF)
    ns:Print(L.HELP_TRAINER)
    ns:Print(L.HELP_GUIDE)
    ns:Print(L.HELP_BUILD)
    ns:Print(L.HELP_BUILD_LIST)
    ns:Print(L.HELP_BUILD_NOTES)
    ns:Print(L.HELP_BUILD_CHECK)
    ns:Print(L.HELP_POINTS)
    if WegweiserRecorder then ns:Print(L.HELP_ROUTE) end
    ns:Print(L.HELP_CONFIG)
    ns:Print(L.HELP_DEV_HINT)
end

-- Prüf-Befehle für die Entwicklung (Ausgaben teils nur auf Deutsch)
local function showDevHelp()
    ns:Print(L.HELP_DEV_HEADER)
    ns:Print(L.HELP_TEST)
    ns:Print(L.HELP_TALENTDUMP)
    ns:Print("/ww debug – Talentfenster-Markierung prüfen")
    ns:Print("/ww questinfo – Rohdaten der angebotenen Quest")
    ns:Print("/ww zoneinfo – Rohdaten der aktuellen Zone")
    ns:Print("/ww zonecheck – Karten-Nummern gegen das Spiel prüfen")
    ns:Print("/ww flugdebug – Flugpunkt-Daten des Spiels prüfen")
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

-- /ww build [liste|hinweise|wahl [Nummer]]
local function buildCommand(arg, rest)
    local guide = ns.modules.TalentGuide
    ns:RunOutOfCombat(function()
        if arg == "wahl" or arg == "choose" then
            -- "/ww build wahl 2" wählt den 2. Build (geht auch unter Level 10)
            local number = tonumber((rest or ""):match("^%S+%s+(%d+)"))
            if number then guide:SelectByIndex(number) end
            guide:PrintChoices()
        elseif arg == "prüfen" or arg == "pruefen" or arg == "check" then
            ns.modules.BuildCheck:Command()
        elseif arg == "zeigen" or arg == "show" then
            ns.modules.TalentHighlight:ToggleFull()
        elseif arg == "liste" or arg == "list" then
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
    -- Aufzeichnung macht das eigene Addon "WegweiserRecorder" (falls installiert)
    route      = function(arg, rest)
        if WegweiserRecorder and WegweiserRecorder.Command then
            WegweiserRecorder:Command(arg, rest)
        else
            ns:Print(L.REC_NOT_INSTALLED)
        end
    end,
    guide      = function(_, rest) ns.modules.ProfessionHelper:GuideCommand(rest) end,
    flug       = function(_, rest) ns:RunOutOfCombat(function() ns.modules.Travel:FlightCommand(rest) end) end,
    flight     = function(_, rest) ns:RunOutOfCombat(function() ns.modules.Travel:FlightCommand(rest) end) end,
    ruhestein  = function() ns.modules.Travel:HearthCommand() end,
    hearth     = function() ns.modules.Travel:HearthCommand() end,
    gold       = function(_, rest) ns.modules.SessionMoney:Command(rest) end,
    dungeons   = function() ns.modules.DungeonFinder:Command() end,
    dungeon    = function() ns.modules.DungeonFinder:Command() end,
    instanzen  = function() ns.modules.DungeonFinder:Command() end,
    reiten     = function() ns:RunOutOfCombat(function() ns.modules.Milestones:RidingCommand() end) end,
    riding     = function() ns:RunOutOfCombat(function() ns.modules.Milestones:RidingCommand() end) end,
    ["vermächtnis"] = function() ns.modules.Milestones:LegacyCommand() end,
    vermaechtnis = function() ns.modules.Milestones:LegacyCommand() end,
    legacy     = function() ns.modules.Milestones:LegacyCommand() end,
    flugdebug  = function() ns:RunOutOfCombat(function() ns.modules.Travel:Debug() end) end,
    lehrer     = function(_, rest) ns:RunOutOfCombat(function() ns.modules.ProfessionHelper:TrainerCommand(rest) end) end,
    trainer    = function(_, rest) ns:RunOutOfCombat(function() ns.modules.ProfessionHelper:TrainerCommand(rest) end) end,
    lernen     = function() ns:RunOutOfCombat(function() ns.modules.TrainerSpells:PrintOverview() end) end,
    learn      = function() ns:RunOutOfCombat(function() ns.modules.TrainerSpells:PrintOverview() end) end,
    berufe     = function() ns:RunOutOfCombat(function() ns.modules.ProfessionHelper:PrintOverview() end) end,
    professions = function() ns:RunOutOfCombat(function() ns.modules.ProfessionHelper:PrintOverview() end) end,
    zonen      = function() ns:RunOutOfCombat(function() ns.modules.ZoneGuide:PrintAdvice() end) end,
    zones      = function() ns:RunOutOfCombat(function() ns.modules.ZoneGuide:PrintAdvice() end) end,
    zonecheck  = function() ns:RunOutOfCombat(function() ns.modules.ZoneGuide:CheckMapIDs() end) end,
    zoneinfo   = function() ns:RunOutOfCombat(function() ns.modules.ZoneGuide:Probe() end) end,
    questinfo  = function() ns.modules.QuestAdvisor:PrintOfferDebug() end,
    quests     = function() ns:RunOutOfCombat(function() ns.modules.QuestAdvisor:PrintOverview() end) end,
    debug      = function() ns:RunOutOfCombat(function() ns.modules.TalentHighlight:Diagnose() end) end,
    test       = function()
        ns:Print(L.TEST_HEADER)
        ns.modules.LevelUp:ShowLevelUpMessages(UnitLevel("player"), true)
        ns:RunOutOfCombat(function() ns.modules.LevelUp:CheckTalentPoints() end, true)
    end,
    help       = showHelp,
    dev        = showDevHelp,
    hilfe      = showHelp,
}

SLASH_WEGWEISER1 = "/ww"
SLASH_WEGWEISER2 = "/wegweiser"
SlashCmdList.WEGWEISER = function(msg)
    -- Erstes Wort = Befehl, zweites Wort = Zusatz (beides klein geschrieben),
    -- rest = alles nach dem Befehl in Originalschreibweise (z. B. für Notizen)
    local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    local arg = (rest:match("^(%S*)") or ""):lower()
    cmd = cmd:lower()
    if cmd == "" then
        showHelp()
        return
    end
    local handler = commands[cmd]
    if handler then
        handler(arg, rest)
    else
        ns:Print(L.UNKNOWN_COMMAND, cmd)
        showHelp()
    end
end
