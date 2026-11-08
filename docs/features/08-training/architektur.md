# Architektur: Feature 08, Training im Takt-Design

Gleiches Muster wie Feature 06/07: Die OpenStrap-Screens bekommen einen Zweig `TAKT (Feature 08)`,
der nur unter `TaktLook` greift. Ohne Takt-Haut (Aktivität-Tab, Live-Training) bleibt alles wie bei
OpenStrap. Daten und Rechnung sind unverändert.

## Bestandteile
- `takt_today_screen.dart`: `taktWorkoutTarget(item, load)` entscheidet T1 oder T2 (reine Funktion,
  ohne Datenbank testbar). `_openWorkout` lädt dafür das Gewicht und das Training und öffnet die
  Übersicht über `_push`, also in TaktLook. Bei null bleibt es bei `_pickSport`.
- `workout_screen.dart`: `taktWorkoutResult(app, id)` sucht die Zeile in `getWorkouts('month')`
  und baut über dieselben Wege wie der Aktivität-Tab (`_pastFromRow`, `_detailOf`) das
  `ActivityResult`. `_pastFromRow` ist aus der Listenschleife herausgezogen, damit beide Wege
  dieselbe Umwandlung nutzen.
- `summary.dart`: `_taktHead` (TaktHeader mit Tag und Uhrzeit, Stift, Teilen), TaktValueCard
  statt Hero, Pulskurve in `Pult.orangeFor(dark)`, `SessionStats._taktStats` (Zeilen, führende Zahl
  in Doto, Rest als Einheit).
- `log_workout.dart`: `_taktBuild` mit `_TaktLogRow` (Keys `takt-log-row-0…4`, feste Indizes auch
  beim Ändern der Zeiten ohne Aktivitätszeile), Hinweis `takt-log-note`, Knopf `takt-log-save`.
  Die Sportart-Liste ist eine eigene Route und bekommt TaktLook mit (`TaktLook.peek`).
- `header.dart`: Der Name kürzt mit „…“. Ohne Mitte nimmt er die freie Breite, mit Mitte höchstens
  zwei Fünftel.

## Entscheidungen
- Die Übersicht wird aus `getWorkouts('month')` geladen statt aus der Zeile von Heute. Verworfen
  wurde, das ActivityItem zu erweitern. Dann gäbe es zwei Umwandlungen derselben Zeile, und die
  Übersicht wiche vom Aktivität-Tab ab.
- Die Sportart-Wahl von Heute aus (A9) geht jetzt über den Stift der Übersicht, der OpenStrap schon
  hatte (`_changeType`). Er speichert die Sportart, schließt die Übersicht, und Heute lädt über
  `_push` neu.

## Fehlerfälle
- Training nicht im Monat, Lesefehler oder gelöscht: `taktWorkoutTarget` gibt null zurück, dann
  öffnet die Sportart-Wahl wie bisher.
