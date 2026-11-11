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

## Phase 3 – Markierung im Talentfenster (Version 0.3.0)

**Neue Datei → WoW komplett neu starten.**

| # | Test | Erwartung |
|---|------|-----------|
| 1 | Talentfenster öffnen (N), ohne freien Punkt | kein goldener Rahmen; NUR über Donnernde Stöße „» 5/5“ (gold) |
| 2 | Maus über Donnernde Stöße | unten im Tooltip: „Wegweiser: als Nächstes im Build – Ziel 5/5 (ab Level 13)“ + Begründung |
| 3 | Levelaufstieg auf 13, Talentfenster öffnen | Donnernde Stöße pulsiert golden; Tooltip „Wegweiser: jetzt skillen – …“ |
| 4 | Punkt in Donnernde Stöße setzen (+ ggf. Übernehmen) | Rahmen verschwindet (kein freier Punkt mehr) |
| 5 | Donnernde Stöße 5/5 erreicht | Markierung wandert zu Geistige Gewandtheit „» 3/3“ |
| 6 | `/ww config` → „Markierung im Talentfenster“ aus | keine Markierungen mehr |
| 7 | Im Kampf Talentfenster öffnen | keine Fehlermeldung; Markierungen kommen nach dem Kampf |

Bitte Screenshot vom Talentfenster schicken – dann passe ich Größe/Position der Markierungen an.

## Phase 4 – Quest-Berater (Version 0.4.0)

**Neue Dateien → WoW komplett neu starten.**

| # | Test | Erwartung |
|---|------|-----------|
| 1 | `/ww quests` | alle Quests, gruppiert: fertig / gut machbar / lohnt sich gerade noch / Gruppe nötig / noch zu schwer / überspringen |
| 2 | Vergleich mit Questlog-Farben | gelb = „gut machbar“, grün = „lohnt sich gerade noch“, grau = „überspringen“, orange/rot = „noch zu schwer“ |
| 3 | Questlog öffnen (L), Maus über eine Quest | unten im Tooltip „Wegweiser: …“ mit Erklärung |
| 4 | Neue Quest annehmen | Chat: „Neue Quest [x] Name: gut machbar“ (o. ä.) |
| 5 | Elite-Quest im Log (Titel mit „+“) | „Gruppe nötig“ |
| 6 | Quest fertig (alle Ziele) | „fertig – abgeben“ |
| 7 | Levelaufstieg | ggf. „Jetzt machbar: …“ / „Jetzt grau …“ |
| 8 | Mit Questie installiert: `/ww quests` | letzte Zeile „Questie erkannt …“ |
| 9 | `/ww config` | neue Häkchen „Quest-Berater“ und „Neue Quests bewerten“ |

## Phase 4b – Quest-Berater im Questlog und beim Questgeber (Version 0.5.0)

`/reload` reicht (keine neuen Dateien).

| # | Test | Erwartung |
|---|------|-----------|
| 1 | Questlog öffnen (L) | rechts, links neben dem Verfolgen-Häkchen, ein kleines Symbol (gelber/grüner/grauer Punkt, Totenkopf = zu schwer, Figur = Gruppe, Häkchen = fertig) |
| 2 | Maus über eine Quest | Tooltip erklärt das Symbol |
| 3 | Beim Questgeber eine Quest öffnen (Text mit „Annehmen“) | unter dem Questfenster ein Kasten „Wegweiser: gut machbar“ o. ä. |
| 4 | Dabei `/ww questinfo` | Rohdaten der Quest (Level, Schwierigkeit, Elite, Gruppe) – bitte Screenshot |
| 5 | Annehmen / Fenster schließen | Kasten verschwindet |
| 6 | Mit Questie | Symbole stören Questie nicht; nichts überlappt |

## Stufe 0 + 2 – Zonen-Prüfung und Routen-Recorder (Wegweiser 0.8.0 + WegweiserRecorder 1.0.0)

Der Recorder ist ein **eigenes Addon**. Installation:
- Ordner `Wegweiser` wie gewohnt nach `AddOns\Wegweiser`
- Ordner `WegweiserRecorder` (im ZIP von GitHub unter `Wegweiser-main\WegweiserRecorder`,
  oder `dist\WegweiserRecorder.zip`) **zusätzlich** nach `AddOns\WegweiserRecorder`
- WoW komplett neu starten

| # | Test | Erwartung |
|---|------|-----------|
| 1 | Einloggen | „Wegweiser Recorder: N Schritte aus dem Wegweiser-Addon übernommen“ (einmalig), dann „Aufzeichnung aktiv“ |
| 2 | `/ww zoneinfo` | Zone, Levelbereich laut Spiel, Position, Anzahl verfügbarer Quests – Screenshot schicken |
| 3 | `/wwrec melden` | ab jetzt jeder Schritt im Chat |
| 4 | Quest annehmen, erledigen, abgeben | „Aufgezeichnet: ACCEPT …“, „COMPLETE …“, „TURNIN …“ |
| 5 | Flugmeister benutzen | „TAXI“ beim Start und bei der Landung |
| 6 | `/wwrec notiz Hier Geisterwolf nutzen` | „Notiz gespeichert“ |
| 7 | `/wwrec` bzw. `/ww route` | Status, zufällige Charakter-Nr., letzte 5 Schritte |
| 8 | `/wwrec melden` | Meldungen wieder aus, Aufzeichnung läuft still weiter |

Daten: `WTF\Account\<KONTONAME>\SavedVariables\WegweiserRecorder.lua` – **ab und zu sichern**.

## Stufe 1 – Zonen-Wegweiser (Version 0.10.0)

`/reload` reicht (keine neuen Dateien).

| # | Test | Erwartung |
|---|------|-----------|
| 1 | `/ww zonecheck` | Liste aller Zonen: Nummer, deutscher Name im Spiel, (englischer Name, Kontinent). Kein „FEHLT“, und Namen passen zusammen – Screenshot schicken |
| 2 | `/ww zonen` | „Du bist in Das Brachland (10–25) – passt zu deinem Level“, Anzahl lohnender Quests, gute Zonen für dein Level |
| 3 | Weltkarte: Maus über andere Zonen (Durotar, Steinkrallengebirge, …) | „Stufe x–y“ in passender Farbe |
| 4 | Levelaufstieg mit kaum lohnenden Quests | „Nur noch N Quest(s), die sich lohnen – Zeit weiterzuziehen?“ + Vorschläge |
| 5 | (später) in eine zu niedrige Zone gehen, z. B. Durotar ab Level 11 | „Durotar (1–10) ist jetzt zu niedrig für dich …“ + Vorschläge |

## Berufe-Helfer (Version 0.12.0)

**Neue Dateien → WoW komplett neu starten.**

| # | Test | Erwartung |
|---|------|-----------|
| 1 | `/ww berufe` | deine Berufe mit Skill/Limit, Art und Nummer (#182 …) – Screenshot schicken (prüft die Nummern) |
| 2 | Beruf kurz vor dem Limit (z. B. 70–74/75) | gelber Hinweis „fast am Limit – geh bald zum Berufslehrer“ |
| 3 | Beruf genau am Limit (75/75) | Hinweis „Limit erreicht!“ (auch in der Bildschirmmitte, falls eingeschaltet) |
| 4 | Charakter ab Level 5 ohne Hauptberuf | einmal „Tipp: Du hast noch keinen Hauptberuf …“ |
| 5 | `/ww config` | neues Häkchen „Berufe-Helfer“ |

## Berufe-Helfer mit Rängen, Abbau-Tipps und Lehrer-Wegpunkt (Version 0.13.0)

`/reload` reicht (keine neuen Dateien).

| # | Test | Erwartung |
|---|------|-----------|
| 1 | `/ww berufe` | je Beruf: „Nächster Rang: Geselle ab Skill 50 (und Stufe 10) beim Lehrer“; bei Bergbau/Kräuterkunde: was gerade Punkte gibt bzw. „Als Nächstes: … ab Skill …“ |
| 2 | Beruf erreicht Skill 50 (bzw. 125/200) | „… du kannst jetzt den nächsten Rang lernen!“ + „Wegpunkt zum Lehrer: /ww lehrer …“ (kein Wegpunkt automatisch!) |
| 3 | `/ww lehrer bergbau` | Wegpunkt (Pfeil) zum nächsten passenden Lehrer, Chat nennt Name, Ort, Koordinaten |
| 4 | `/ww lehrer aus` | Wegpunkt verschwindet |
| 5 | Zum Lehrer gehen | stimmt der Name/Ort? Lehrt er den Rang? (bitte melden, falls nicht) |
| 6 | `/ww zonecheck` | jetzt auch Orgrimmar, Donnerfels, Unterstadt (1454/1456/1458) |
