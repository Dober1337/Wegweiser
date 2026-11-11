-- ============================================================
-- Locales/deDE.lua
-- Deutsche Texte. Werden nur geladen, wenn der Client auf Deutsch läuft,
-- und überschreiben dann die englischen Texte gleichen Namens.
-- ============================================================

local _, ns = ...
if ns.locale ~= "deDE" then return end
local L = ns.L

-- Allgemein
L.ADDON_LOADED          = "Version %s geladen. Gib /ww für Hilfe ein."
L.IN_COMBAT_QUEUED      = "Du bist im Kampf – das wird ausgeführt, sobald der Kampf vorbei ist."
L.UNKNOWN_COMMAND       = "Unbekannter Befehl: %s"

-- Hilfe (/ww)
L.HELP_HEADER           = "Befehle:"
L.HELP_CONFIG           = "/ww config – Einstellungen öffnen"
L.HELP_POINTS           = "/ww punkte – zeigt deine Talentpunkte"
L.HELP_TALENTDUMP       = "/ww talentdump – liest den Talentbaum aus und speichert ihn (für die Entwicklung)"
L.HELP_TEST             = "/ww test – zeigt eine Beispiel-Nachricht zum Levelaufstieg"

-- Level-Up-Modul
L.LEVELUP_CONGRATS      = "Glückwunsch zu Level %d!"
L.LEVELUP_TRAINER       = "Neue Fähigkeiten! Bei deinem Klassenlehrer kannst du jetzt neue Fähigkeiten oder Ränge lernen."
L.LEVELUP_FIRST_TALENT  = "Ab jetzt bekommst du Talentpunkte! Jeder Punkt macht deinen Charakter ein Stück stärker."
L.TALENT_UNSPENT_ONE    = "Du hast 1 freien Talentpunkt. Öffne das Talentfenster (%s), um ihn zu verteilen."
L.TALENT_UNSPENT_MANY   = "Du hast %d freie Talentpunkte. Öffne das Talentfenster (%s), um sie zu verteilen."
L.TALENT_KEY_UNKNOWN    = "Talent-Taste"
L.TALENT_API_MISSING    = "Die Talent-Schnittstelle konnte nicht gelesen werden (API nicht verfügbar)."

-- /ww punkte
L.POINTS_STATUS         = "Talentpunkte: %d verteilt, %d frei."
L.POINTS_TREE           = "  %s: %d"

-- /ww talentdump
L.DUMP_DONE             = "Talentbaum gespeichert: %d Bäume, %d Talente. Gib /reload ein, damit die Datei geschrieben wird."
L.DUMP_FILE_HINT        = "Datei: WTF\\Account\\<KONTONAME>\\SavedVariables\\Wegweiser.lua"
L.DUMP_FAILED           = "Talent-Auslesen fehlgeschlagen: %s"
L.DUMP_NO_CONFIG        = "keine aktive Talent-Konfiguration gefunden"
L.DUMP_NO_TREE          = "kein Talentbaum gefunden"

-- Einstellungen
L.SETTINGS_TITLE        = "Wegweiser"
L.OPT_LEVELUP           = "Level-Up-Hinweise"
L.OPT_LEVELUP_TT        = "Zeigt beim Levelaufstieg einen kurzen Tipp im Chat."
L.OPT_TRAINER           = "Erinnerung: Klassenlehrer"
L.OPT_TRAINER_TT        = "Erinnert dich alle 2 Level (2, 4, 6, ...) an den Besuch beim Klassenlehrer."
L.OPT_TALENT            = "Erinnerung: Talentpunkte"
L.OPT_TALENT_TT         = "Sagt dir Bescheid, wenn du freie Talentpunkte hast."
L.OPT_LOGIN             = "Beim Einloggen erinnern"
L.OPT_LOGIN_TT          = "Erinnert dich auch direkt nach dem Einloggen an freie Talentpunkte."
L.OPT_ONSCREEN          = "Hinweise auf dem Bildschirm"
L.OPT_ONSCREEN_TT       = "Zeigt Hinweise zusätzlich groß in der Bildschirmmitte, nicht nur im Chat."

-- Test
L.TEST_HEADER           = "So sieht ein Level-Up-Hinweis aus:"

-- Talent-Leitfaden
L.HELP_BUILD            = "/ww build – Talent-Leitfaden: Fortschritt und nächster Punkt"
L.HELP_BUILD_LIST       = "/ww build liste – alle Schritte des Builds"
L.HELP_BUILD_NOTES      = "/ww build hinweise – bekannte Kompromisse des Builds"
L.OPT_GUIDE             = "Talent-Leitfaden"
L.OPT_GUIDE_TT          = "Empfiehlt anhand eines Leveling-Builds, welches Talent als Nächstes dran ist."
L.GUIDE_NO_BUILD        = "Für deine Klasse gibt es noch keinen Talent-Build."
L.GUIDE_TREE_CHANGED    = "|cffff5555Talentbaum hat sich geändert – Build prüfen.|r"
L.GUIDE_SEE_BUILD       = "Details: /ww build"
L.GUIDE_PROGRESS        = "Fortschritt: %d von %d Punkten wie geplant verteilt."
L.GUIDE_NEXT            = "Als Nächstes: %s"
L.GUIDE_POINT_LINE      = "Punkt %d (Level %d): %s %d/%d"
L.GUIDE_COMPLETE        = "Alle Punkte des Builds sind verteilt. Gut gemacht!"
L.GUIDE_DEVIATION       = "|cffffff00Hinweis:|r %s steht auf %d, der Build sieht %d vor. Das ist okay – deine Entscheidung."
L.GUIDE_MORE            = "Mehr: /ww build liste, /ww build hinweise"
L.GUIDE_LIST_LINE       = "%s Lvl %s: %s %d/%d"
L.GUIDE_NOTES_HEADER    = "Bekannte Kompromisse dieses Builds:"
L.CHECK_NODE_MISSING    = "Schritt %d: Talent #%d gibt es nicht mehr."
L.CHECK_MAXRANK         = "%s: maximaler Rang sollte %d sein, das Spiel sagt %d."
L.CHECK_POSITION        = "%s: erwartet Baum %d Reihe %d Spalte %d, das Spiel sagt Baum %d Reihe %d Spalte %d."
L.CHECK_GATE            = "Punkt %d (%s): braucht %d Punkte im Baum, zu diesem Zeitpunkt sind es erst %d."
L.CHECK_ARROW           = "Punkt %d (%s): setzt zuerst %s auf %d voraus."
L.CHECK_TOO_MANY        = "%s: Build plant Rang %d, Maximum ist %d."

-- Markierungen im Talentfenster
L.OPT_HIGHLIGHT         = "Markierung im Talentfenster"
L.OPT_HIGHLIGHT_TT      = "Markiert das Talent, das gerade dran ist, mit seinem Ziel-Rang – mit freiem Punkt zusätzlich golden umrandet."
L.GUIDE_HIGHLIGHT_HINT  = "Im Talentfenster ist es golden umrandet."
L.HL_TT_NOW             = "Wegweiser: jetzt skillen – %s"
L.HL_TT_DONE            = "Wegweiser: wie geplant verteilt."
L.HL_TT_NEXT            = "Wegweiser: als Nächstes im Build – Ziel %d/%d (ab Level %d)"
L.HL_TT_LATER           = "Wegweiser: später im Build – Ziel %d/%d (ab Level %d)"
L.HL_TT_DEVIATION       = "Wegweiser: Der Build sieht hier %d Punkt(e) vor, du hast %d. Kein Problem – nur ein Hinweis."

-- Quest-Berater
L.HELP_QUESTS           = "/ww quests – bewertet alle Quests in deinem Questlog"
L.OPT_QUESTS            = "Quest-Berater"
L.OPT_QUESTS_TT         = "Bewertet deine Quests: gut machbar, Gruppe nötig, zu schwer oder überspringen. Auch im Questlog-Tooltip."
L.OPT_QACCEPT           = "Neue Quests bewerten"
L.OPT_QACCEPT_TT        = "Zeigt eine kurze Bewertung im Chat, wenn du eine Quest annimmst."
L.QA_EMPTY              = "Dein Questlog ist leer."
L.QA_HEADER             = "Deine %d Quests im Überblick:"
L.QA_ACCEPTED           = "Neue Quest %s: %s"
L.QA_NOW_DOABLE         = "Jetzt machbar: %s"
L.QA_NOW_GREY           = "Jetzt grau (kaum noch EP) – kannst du abbrechen: %s"
L.QA_QUESTIE_YES        = "Questie erkannt: Questgeber und Questziele siehst du auf Karte und Minikarte."
L.QA_QUESTIE_NO         = "Tipp: Das kostenlose Addon Questie zeigt Questgeber und Questziele auf der Karte (optional)."
L.QA_DONE               = "fertig – abgeben"
L.QA_DONE_TT            = "Alle Ziele erledigt – geh zum Questgeber zurück und hol dir die Belohnung."
L.QA_SKIP               = "überspringen"
L.QA_SKIP_TT            = "Graue Quest: weit unter deinem Level, bringt kaum oder keine Erfahrung mehr."
L.QA_GROUP              = "Gruppe nötig"
L.QA_GROUP_TT           = "Elite-, Dungeon- oder Gruppenquest – allein sehr schwer. Such dir eine Gruppe."
L.QA_TOO_HARD           = "noch zu schwer"
L.QA_TOO_HARD_TT        = "Orange/rote Quest: Die Gegner sind deutlich über deinem Level. Komm später wieder."
L.QA_GOOD               = "gut machbar"
L.QA_GOOD_TT            = "Gelbe Quest: genau auf deinem Level – gute Erfahrung bei fairer Schwierigkeit."
L.QA_STILL_WORTH        = "lohnt sich gerade noch"
L.QA_STILL_WORTH_TT     = "Grüne Quest: etwas unter deinem Level, leicht und bringt noch Erfahrung."
L.OPT_QOFFER            = "Hinweis beim Questgeber"
L.OPT_QOFFER_TT         = "Zeigt unter dem Questfenster eine Bewertung, bevor du eine Quest annimmst."
L.OPT_QICONS            = "Symbole im Questlog"
L.OPT_QICONS_TT         = "Zeigt ein kleines Symbol neben jedem Questtitel. Maus drüber zeigt die Erklärung."
L.QA_DEBUG_NO_OFFER      = "Öffne zuerst eine Quest beim Questgeber (den Text mit dem „Annehmen“-Knopf)."
L.ZG_NO_MAP              = "Deine aktuelle Zone konnte nicht ermittelt werden."
L.ZG_PROBE_SAVED         = "Gespeichert. Gib /reload ein, damit es in die Datei geschrieben wird."

-- Routen-Recorder (eigenes Addon WegweiserRecorder)
L.HELP_ROUTE            = "/ww route – Routen-Aufzeichnung (braucht das Addon WegweiserRecorder)"
L.REC_NOT_INSTALLED     = "Die Routen-Aufzeichnung ist ein eigenes Addon: Leg den Ordner „WegweiserRecorder“ neben Wegweiser in deinen AddOns-Ordner."
