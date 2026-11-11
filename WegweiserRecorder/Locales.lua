-- ============================================================
-- WegweiserRecorder/Locales.lua
-- Texte auf Englisch (Grundsprache) und Deutsch.
-- ============================================================

local _, ns = ...

local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

-- Englisch
L.LOADED        = "Recording active (%d steps for this character). Details: /wwrec"
L.STEP          = "Recorded: %s %s"
L.STATUS        = "Route recording: %s – %d steps since %s (character no. %s, %s %s)."
L.STATE_ON      = "|cff55ff55running|r"
L.STATE_PAUSED  = "|cffffff00paused|r"
L.COUNTS        = "Accepted: %d, turned in: %d, objectives done: %d, level-ups: %d, notes: %d"
L.LAST          = "Last steps:"
L.HELP          = "/wwrec pause | start | note <text> | announce (toggle chat messages)"
L.PAUSED        = "Recording paused (until /wwrec start or /reload)."
L.RESUMED       = "Recording running."
L.NOTE_USAGE    = "Usage: /wwrec note <text>, e.g. /wwrec note Use Ghost Wolf here"
L.NOTE_SAVED    = "Note saved: %s"
L.VERBOSE_ON    = "Every recorded step will be announced in chat."
L.VERBOSE_OFF   = "Recorded steps are no longer announced."
L.MIGRATED      = "Took over %d steps from the Wegweiser addon."
L.FILE_HINT     = "Data file: WTF\\Account\\<ACCOUNT>\\SavedVariables\\WegweiserRecorder.lua"

if GetLocale() == "deDE" then
    L.LOADED        = "Aufzeichnung aktiv (%d Schritte für diesen Charakter). Details: /wwrec"
    L.STEP          = "Aufgezeichnet: %s %s"
    L.STATUS        = "Routen-Aufzeichnung: %s – %d Schritte seit %s (Charakter-Nr. %s, %s %s)."
    L.STATE_ON      = "|cff55ff55läuft|r"
    L.STATE_PAUSED  = "|cffffff00pausiert|r"
    L.COUNTS        = "Angenommen: %d, abgegeben: %d, Ziele erledigt: %d, Levelaufstiege: %d, Notizen: %d"
    L.LAST          = "Letzte Schritte:"
    L.HELP          = "/wwrec pause | start | notiz <Text> | melden (Chat-Meldungen an/aus)"
    L.PAUSED        = "Aufzeichnung pausiert (bis /wwrec start oder /reload)."
    L.RESUMED       = "Aufzeichnung läuft."
    L.NOTE_USAGE    = "So geht's: /wwrec notiz <Text>, z. B. /wwrec notiz Hier Geisterwolf nutzen"
    L.NOTE_SAVED    = "Notiz gespeichert: %s"
    L.VERBOSE_ON    = "Jeder aufgezeichnete Schritt wird im Chat gemeldet."
    L.VERBOSE_OFF   = "Aufgezeichnete Schritte werden nicht mehr gemeldet."
    L.MIGRATED      = "%d Schritte aus dem Wegweiser-Addon übernommen."
    L.FILE_HINT     = "Datendatei: WTF\\Account\\<KONTONAME>\\SavedVariables\\WegweiserRecorder.lua"
end
