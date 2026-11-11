# Wegweiser – Testanleitung

## Einmalig einrichten

1. Lua-Fehler sichtbar machen – im Spiel in den Chat eingeben:
   `/console scriptErrors 1`
   (Alternativ BugGrabber + BugSack installieren. Falls sie nicht als
   „Forever“ markiert sind: im AddOns-Menü „Veraltete AddOns laden“ anhaken.)
2. Der Addon-Ordner muss genau so heißen:
   `World of Warcraft\_forever_\Interface\AddOns\Wegweiser\Wegweiser.toc`

## Wann /reload, wann Neustart?

- Code in einer bestehenden Datei geändert → `/reload` reicht.
- Neue Datei dazugekommen oder `.toc` geändert → Spiel komplett neu starten.

## Phase 1 – Checkliste

| # | Test | Erwartung |
|---|------|-----------|
| 1 | Einloggen | Chat: „Wegweiser: Version 0.1.0 geladen …“, keine Fehlermeldung |
| 2 | `/ww` | Liste der Befehle (deutsch) |
| 3 | `/ww quatsch` | „Unbekannter Befehl: quatsch“ + Hilfe |
| 4 | `/ww config` | Optionen öffnen sich bei „Wegweiser“ mit 5 Häkchen |
| 5 | `/ww test` | Glückwunsch + Klassenlehrer-Tipp (+ Talentpunkte, falls frei) |
| 6 | Häkchen „Erinnerung: Klassenlehrer“ aus, `/ww test` | Lehrer-Tipp fehlt |
| 7 | Häkchen „Hinweise auf dem Bildschirm“ an, `/ww test` | Text zusätzlich gelb in der Bildschirmmitte |
| 8 | `/ww punkte` (ab Level 10) | „Talentpunkte: X verteilt, Y frei“ + die drei Baumnamen mit Punkten |
| 9 | `/ww talentdump`, dann `/reload` | Chat: „Talentbaum gespeichert: 3 Bäume, … Talente“ |
| 10 | Im Kampf `/ww talentdump` | „wird nach dem Kampf ausgeführt“, danach automatisch Dump |
| 11 | Echter Levelaufstieg | Glückwunsch; Lehrer-Hinweis nur auf geraden Leveln; ab Level 10 Hinweis auf freie Talentpunkte |
| 12 | `/reload` mit freien Talentpunkten | nach ~5 Sekunden Erinnerung |

## Talentdump an die Entwicklung schicken

Nach `/ww talentdump` und `/reload` die Datei öffnen:
`World of Warcraft\_forever_\WTF\Account\<KONTONAME>\SavedVariables\Wegweiser.lua`

Den Abschnitt `["talentDump"]` komplett kopieren und schicken.
Am besten mit dem Schamanen machen, der schon Punkte verteilt hat – dann
sind auch die aktuellen Ränge drin.

## Phase 2 – Talent-Leitfaden (Version 0.2.0)

**Neue Dateien → WoW komplett neu starten (nicht nur /reload).**

| # | Test | Erwartung |
|---|------|-----------|
| 1 | Einloggen | „Version 0.2.0 geladen“, KEINE rote Meldung „Talentbaum hat sich geändert“ |
| 2 | `/ww build` | Titel „Heal-Reiter (Leveling-Build)“, Fortschritt „X von 51“, nächster Punkt mit Begründung |
| 3 | `/ww build liste` | 4 Phasen, alle Talentnamen auf Deutsch, Häkchen bei erledigten Schritten, `>` beim aktuellen |
| 4 | `/ww build hinweise` | 4 Kompromiss-Hinweise |
| 5 | `/ww config` | neues Häkchen „Talent-Leitfaden“ |
| 6 | Nächster Levelaufstieg | nach „Du hast 1 freien Talentpunkt …“ kommt „Als Nächstes: …“ |
| 7 | Punkt wie empfohlen verteilen, `/ww build` | Fortschritt +1, nächster Punkt rückt weiter |
| 8 | (optional) Punkt woanders hinsetzen, `/ww build` | gelber Hinweis „… steht auf 1, der Build sieht 0 vor“ |
