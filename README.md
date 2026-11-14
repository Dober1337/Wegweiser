# Wegweiser

**Kostenloser Einsteiger-Helfer für World of Warcraft: Forever** (Horde, Level 1–60)
*Free beginner helper for World of Warcraft: Forever – English below.*

Wegweiser erklärt und hilft, statt nur einen Pfeil zu zeigen: Welche Quest lohnt sich gerade? Wohin als Nächstes? Welches Talent ist jetzt dran?

## [⬇ Download](https://github.com/Dober1337/Wegweiser/raw/main/dist/Wegweiser.zip)

Optional: [Recorder-Download](https://github.com/Dober1337/Wegweiser/raw/main/dist/WegweiserRecorder.zip) (zeichnet Questrouten auf, siehe unten)

Die ZIP entpacken und den Ordner `Wegweiser` nach `World of Warcraft\_forever_\Interface\AddOns\` legen. Bei einem Update den alten Ordner ersetzen und das Spiel neu starten.

## Empfohlenes Zusatz-Addon

**Dungeon Journal** (Autor: Exehn, kostenlos auf CurseForge, dort nach „Dungeon Journal“ suchen) zeigt Bosse, Beute und Quests aller Dungeons. Ist es installiert, öffnet ein Klick auf einen Dungeon in Wegweisers Gruppensuche-Reiter direkt dessen Seite. Wegweiser funktioniert auch ohne.

## Funktionen

**Quest-Berater**
- Symbol neben jeder Quest im Questlog: gut machbar, lohnt sich gerade noch, Gruppe nötig, noch zu schwer, überspringen, fertig – abgeben
- Hinweis direkt beim Questgeber, **bevor** du die Quest annimmst
- Erklärung im Tooltip, Übersicht mit `/ww quests`
- Nutzt Blizzards eigene Quest-Schwierigkeit – keine externe Datenbank nötig. Funktioniert mit und ohne Questie.

**Zonen-Wegweiser**
- Levelbereiche aller Zonen auf der Weltkarte („Stufe 10–25“), farbig passend zu deinem Level
- Hinweis, wenn deine Zone zu niedrig wird oder kaum lohnende Quests übrig sind – mit passenden nächsten Zonen
- `/ww zonen` zeigt deine Zone und gute Zonen für dein Level

**Talent-Leitfaden**
- 28 Leveling-Builds für alle 9 Klassen (Wowhead-Leveling-Guides), Auswahl im Talentfenster oder mit `/ww build wahl`
- Pro Klasse ein grün markierter **Einsteiger-Tipp**, ohne eigene Wahl voreingestellt
- Im Talentfenster: das Talent, das jetzt dran ist, wird golden umrandet; auf Wunsch der ganze Build
- Erkennt deine tatsächlich verteilten Punkte – Abweichungen sind erlaubt, nur ein Hinweis
- `/ww build`, `/ww build liste`, `/ww build hinweise`
- Nach jedem Spielpatch prüft Wegweiser automatisch, ob die Builds deiner Klasse noch zum Talentbaum passen (`/ww build prüfen`)

**Level-Up-Hinweise**
- Erinnerung an den Klassenlehrer mit den neuen Fähigkeiten (`/ww lernen`) und an freie Talentpunkte

**Berufe**
- Beim Lehrer und im Berufsfenster: womit du jetzt am besten skillst, Material, ob du das Rezept schon kennst
- `/ww berufe` mit Rang-Grenzen und Tipps, `/ww lehrer <Beruf>` setzt einen Wegpunkt zum passenden Lehrer
- Tooltip über Kraut, Erz und Tier: ab welcher Fertigkeit und welche Farbe es für dich hat

**Unterwegs**
- Flugpunkte: Hinweis auf noch unbekannte Flugpunkte in deiner Zone, `/ww flug` mit Wegpunkt
- `/ww ruhestein`: wo dein Ruhestein gebunden ist
- Taschen fast voll oder Ausrüstung kaputt: Hinweis; beim Händler „Graues verkaufen“ und „Reparieren“ auf Knopfdruck
- Gold dieser Sitzung unten links in der Tasche, `/ww gold`
- Reiten: ab Stufe 30 Spar-Hinweise, auf Stufe 40 der Weg zum Reitlehrer (`/ww reiten`)
- Vermächtnis: Hinweis auf freie Vermächtnispunkte mit der Taste zum Öffnen (`/ww vermächtnis`)
- Dungeons: eigener Reiter in der Gruppensuche „Dungeons für deine Stufe“ (Stufenbereiche aus Blizzards Gruppenfinder), Hinweis beim Levelaufstieg, `/ww dungeons`

Alles ist einzeln abschaltbar: `/ww config` (oder ESC → Optionen → AddOns → Wegweiser).
Fenster und Markierungen werden nur außerhalb des Kampfes verändert.

## Installation

1. Ordner `Wegweiser` nach `World of Warcraft\_forever_\Interface\AddOns\` kopieren
   (danach: `AddOns\Wegweiser\Wegweiser.toc`).
2. WoW neu starten. Im Chat erscheint „Wegweiser: Version … geladen“.
3. `/ww` zeigt alle Befehle.

## Wegweiser Recorder (optional, eigenes Addon)

Zeichnet beim normalen Spielen deine Questroute auf (Quests, Orte, Level) – als Grundlage für künftige Leveling-Routen. Speichert **keine** Charakternamen. Anleitung: `LIESMICH.txt` im Recorder-Paket.

## Sprachen

Deutsch und Englisch.

## Datenquellen

- Spieldaten zur Laufzeit direkt aus dem Spiel (Blizzard-API)
- Zonen-Levelbereiche und Zonen-Empfehlungen: [Mobalytics – Zone Map: Level Ranges](https://mobalytics.gg/wow-forever/guides/zone-map-level-ranges) (Stand 10.11.2026)
- Talent-Builds: Wowhead-Leveling-Guides für WoW Forever (Heilig-Priester: Endstand von Wowhead, Reihenfolge von Wegweiser vorgeschlagen); Schamanen-Heal-Hybrid von einem Spieler erstellt
- Berufe (Routen, Ränge, Lehrer, Sammel-Farben): [goldgoblin – Forever-Berufe](https://classic.goldgoblin.net/warcraft-forever-berufe-uebersicht/)
- Einsteiger-Tipps: Forever-Einsteigerlisten, Begründung in `docs/EINSTEIGER.md`

## Kostenlos

Wegweiser ist und bleibt kostenlos – keine Bezahlfunktionen, keine Werbung, keine Spendenaufrufe im Addon.

---

## English

**Wegweiser** ("signpost") is a free beginner helper for WoW: Forever (Horde, levels 1–60).

- **Quest advisor:** a symbol next to every quest in your quest log (good to do, still worth it, group needed, too hard, skip, ready to turn in), a hint at the quest giver **before** you accept, tooltip explanations, `/ww quests`.
- **Zone guide:** level ranges for every zone on the world map, a hint when your zone has become too low, suggestions for your next zones, `/ww zones`.
- **Talent guide:** 28 leveling builds for all 9 classes, one marked as the beginner tip; the talent to pick now is highlighted in the talent window.
- **Level-up tips:** reminders for the class trainer and unspent talent points.
- **Professions:** what to craft now at the trainer, `/ww professions`, `/ww trainer <profession>` waypoints, gathering skill in herb/ore/beast tooltips.
- **On the road:** unknown flight points in your zone, hearthstone location, bag/repair hints, "sell grey" and "repair" at merchants, session gold in your bags.

**[Download](https://github.com/Dober1337/Wegweiser/raw/main/dist/Wegweiser.zip)** – unzip and put the `Wegweiser` folder into `World of Warcraft\_forever_\Interface\AddOns\`.

Everything can be turned off in `/ww config`. Languages: English and German. Free – no paid features, no ads.
