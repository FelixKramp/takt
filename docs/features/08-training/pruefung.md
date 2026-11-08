---
feature: 08-training
geprueft: 2026-11-08
stand: 6c49e65d
pruefer: unabhängiger Prüfer-Agent (Phase 5, Runde 2)
---
# Prüfung: Training und „Workout nachtragen“ im Takt-Design (08), Runde 2

## Grundlage
- Gelesen: `CLAUDE.md`, `docs/features/08-training/spec.md` (mit Abschnitt „Änderungen“), `architektur.md` des Features (eine `docs/architektur.md` gibt es nicht), Bericht der Runde 1, `git show HEAD` (6c49e65d). `plan.md` bewusst nicht.
- Geändert seit Runde 1: `lib/takt/header.dart` (neues `sub`), `lib/takt/detail/value_card.dart`, `lib/takt/today/takt_today_screen.dart` (Sperre `_opening`), `lib/ui2/activity/summary.dart` (Datum als `sub`, Reiterfarbe, Fußnote in `taktDodge`), `test/takt/workout_takt_test.dart` (+6 Tests). `log_workout.dart`, `workout_screen.dart` und der Rest sind unverändert.
- `flutter test test/takt/`: **191 Tests, alle grün** (ohne eigene Prüftests gelaufen).
- `flutter test test/log_workout_test.dart test/score_imported_workout_test.dart test/ui2_activity_test.dart test/ui2_gallery_test.dart test/ui2_tokens_test.dart`: **140 Tests, alle grün.**
- `flutter analyze` auf die fünf geänderten Dart-Dateien: keine Befunde.
- Bildschirmfotos `TAKT_SHOTS=1 flutter test test/takt/shots_test.dart` (3 Tests grün): `schlaf_tab`, `hrv`, `strain`, `erholung`, `training`, `nachtragen` neu erzeugt, zugeschnitten und angesehen.
- Eigene Wegwerf-Tests unter `test/takt/` (danach gelöscht, ebenso die eigenen Fotos in `build/shots/`). Mit echten Schriften (`loadRealFonts`): alle 78 Sportarten aus `allActivities` × drei Daten (8. Nov. 2026, 16:57 · 28. Sept. 2026, 23:59 · 28. März 2026, 10:05) × 320/360/390 px × Textgröße 1,0 und 1,3; Textgröße 2,0 mit dem längsten Namen; Streifen über der Datumszeile; privates Training bei 320/360/390 × 1,0/1,3 und mit Distanz; `TaktValueCard` alt (HEAD~1) gegen neu mit den echten Erholungswörtern; Reiter dunkel; Fußnote gegen den Streifen; B5-Hüllen der ganzen Übersicht; Randfall ohne Puls bei 320/1,3. Mit echter Datenbank: Doppeltipp und Dreifachtipp auf Heute.
- Hinweis: `git status` zeigt `pubspec.yaml` geändert (Version 0.3.0+7 → 0.3.1+8). Das stammt nicht von der Prüfung, vermutlich vom parallel laufenden Release-Build.

## Ergebnis
✅ 12 · ❌ 1 · ⚪ 0

| ID | Ergebnis | Begründung |
|---|---|---|
| T1 | ✅ | Code wie in Runde 1 geprüft, nur in `_openWorkoutOnce` verschoben. Test A9/T1/T3 (echte DB: Tipp → `ActivitySummary` in `TaktLook`, kein Picker) und Unit-Test T1 grün. |
| T2 | ✅ | Unverändert: `item.suggestion != null` → `_pickSport`. Unit-Test T2 und „A9: Auch eine offene Erkennung bekommt ihre Sportart“ grün. |
| T3 | ✅ | `_changeType` unverändert, Stift sitzt weiter in `trailing` (Key `takt-workout-edit`). A9/T1/T3 grün; DB-Wert und Rücksprung wurden in Runde 1 geprüft. |
| T4 | ❌ | Datum steht jetzt unter dem Namen, Stift und Teilen rechts, Wert-Karte mit „55:00“ in Doto und „Gesamtzeit“, keine NavBar und keine 48-pt-Zahl. **Bei normaler Textgröße sind Tag und Uhrzeit jetzt überall ganz sichtbar:** 78 Sportarten × 3 Daten × 320/360/390 px, kein einziger Fall gekürzt (vorher war bei 360 px schon „handball“ abgeschnitten). Bei 360 und 390 px mit Textgröße 1,3 ebenfalls alle ganz. **Bei 320 px und Textgröße 1,3 wird die Uhrzeit bei allen 78 Sportarten abgeschnitten**, unabhängig vom Namen: Die Spalte unter dem Namen ist bei 320 px fest 144 px breit (Pfeil, Abstand, Stift und Teilen nehmen 176 px). „8. Nov. 2026, 16:57“ braucht bei 1,3 147 px, „28. Sept. 2026, 23:59“ 169 px; zu sehen ist „28. Sept. 2026, …“. Ab etwa 345 px Breite oder bis Textgröße 1,1 passt es. **Reproduktion:** `ActivitySummary(handball())` in `TaktLook`, `physicalSize` 320 × 1600, `devicePixelRatio` 1, `textScaleFactorTestValue = 1.3`, `loadRealFonts`; `RenderParagraph` von `ValueKey('takt-workout-when')`: `didExceedMaxLines == true`, Breite 144 < `getMaxIntrinsicWidth` 147. Die neuen Tests „T4: Tag und Uhrzeit ganz sichtbar bei 320/360/390 px“ laufen nur mit Textgröße 1,0 und prüfen nur „General workout“ mit dem 8. Nov., deshalb sind sie grün. Kein Überlauf, kein Absturz (auch bei 2,0 nicht; der Kopf wächst dann auf 92 px). Hinweis: Das Jahr „2026“ kostet allein etwa 35 px. |
| T5 | ✅ | Unverändert, Pulslinie `Pult.orangeFor(p.dark)`; Foto `training`: orange Linie mit oranger Fläche wie bei `strain`. Test T5 grün. |
| T6 | ✅ | Unverändert. Foto: fünf Zeilen, Name links, Doto-Zahl rechts, keine runden Symbole. Eigener B5-Test über die ganze Übersicht mit Streifen bei 50 %: keine Zahl ohne Hülle. |
| T7 | ✅ | Reiter, Zonen und Fußnote in flachen Takt-Karten (Foto). Aktiver Reiter jetzt Takt-Orange, siehe Hinweise. |
| T8 | ✅ | `log_workout.dart` unverändert. Test T8 grün, Foto `nachtragen`: Kopf „training nachtragen“, fünf schlichte Zeilen, 17:00/18:00/60 in Doto. |
| T9 | ✅ | Unverändert. Foto: grauer Hinweis, flacher oranger Knopf „Speichern“. Test T9 (ausgegraut, Grund darüber) grün. |
| T10 | ✅ | Unverändert, Test T10 grün. |
| T11 | ✅ | Unverändert (`_save` wie OpenStrap). `log_workout_test.dart` grün; der DB-Test „Nachtragen von Heute speichert“ aus Runde 1 betrifft unveränderten Code. Weiterhin gibt es im Repo keinen Takt-spezifischen Test für T11. |

### Randfälle
| Randfall | Ergebnis | Begründung |
|---|---|---|
| Training ohne Pulsaufzeichnung | ✅ | Eigener Test bei 320 px und Textgröße 1,3: `hr` leer, keine Ausnahme, „Keine Herzfrequenz …“ steht da, Datum unter dem Namen „8. Nov. 2026, 16:57“. |
| Training lässt sich nicht laden | ✅ | `taktWorkoutTarget` unverändert, Unit-Tests (null und Ausnahme → Sportart-Wahl) grün. Die neue Sperre gibt per `finally` auch bei einer Ausnahme wieder frei. |

## Hinweise aus Runde 1
| Hinweis | Ergebnis | Begründung |
|---|---|---|
| Doppeltipp öffnet zwei Übersichten | ✅ behoben | `_opening` sperrt `_openWorkout`, bis die Übersicht wieder zu ist und Heute neu geladen hat. Eigener DB-Test: drei Tipps im Abstand von 1 ms, während die Datenbank noch lädt → genau eine `ActivitySummary`, kein Picker; zurück, erneut antippen → öffnet wieder. Im Repo gibt es dafür keinen Test (die neuen Tests in `workout_takt_test.dart` decken T4, privat, Fußnote und Reiter ab, den Doppeltipp nicht). Weiterhin keine Ladeanzeige während des Ladens; die Spec verlangt keine. |
| Privat schrumpft „55:00“ | ✅ behoben | Wert und Einheit stehen jetzt in einem `Expanded`, das Wort daneben in natürlicher Breite. Gemessen: „55:00“ bei 320/360/390 px mit 1,0 und bei 360/390 px mit 1,3 in voller Größe (169 bzw. 220 px). Nur bei 320 px und 1,3 schrumpft die Zahl auf 84 %, weil Zahl (220 px) und „Privat“ (62 px) dort zusammen nicht in die Karte passen. Das ist echter Platzmangel, nicht mehr die Halbierung durch den `Spacer`. Laufen mit „10.02 km“ und „Privat“ bei 320/1,3: alles ganz, nichts überlappt. Der neue Repo-Test misst bei 390 px. |
| MET-Fußnote ohne Streifen-Hülle | ✅ behoben | `_basisNote` steht in `taktDodge(…, line: true)`, greift also nur unter `TaktLook`. Eigener Test: Streifen bei 10 % bis 90 % der Breite, keine Ziffer von „12.0“ liegt darauf. B5 über die ganze Übersicht: keine Zahl ohne Hülle. Nebenbei unverändert: „12.0“ mit Punkt kommt aus OpenStrap. |
| Aktiver Reiter in Sportfarbe | ✅ behoben | `SubTabs(color: takt ? Pult.orange : a.color)`, dieselbe Farbe wie HRV/Strain (`withColor(Pult.orange)`). Hell (Repo-Test) und dunkel (eigener Test, Foto) orange. Ohne Takt-Haut bleibt die Sportfarbe. |

## Regressionen
- **`TaktHeader` (`sub`, Name in `Expanded`):** `sub` nutzt nur die Trainings-Übersicht. Für alle anderen Aufrufer (Schlaf-Tab mit `center`, HRV/Ruhepuls/Schritte/Strain/Erholung über `metric_detail`, Nachtragen) ist der Baum mit `sub == null` identisch zu vorher. Fotos `schlaf_tab` (Name links, Nacht in der Mitte, Profilbild), `hrv`, `strain`, `erholung`, `nachtragen`: Kopf unverändert, nichts gekürzt. Alle Takt-Tests grün.
- **`TaktValueCard` (Features 06/07):** Verglichen mit der Fassung aus HEAD~1 bei den echten Erholungswörtern („Startklar“, „Stabil“, „Locker angehen“, „Heute ausruhen“), 320/360 px, Textgröße 1,0/1,3/1,5/2,0: Die Zahl ist in jedem Fall gleich groß oder größer als vorher, nie kleiner (z. B. „Locker angehen“ 320/1,0: vorher 77 %, jetzt 100 %; „Startklar“ 320/1,3: 77 % → 100 %). Ohne Wort (HRV, Strain) ist das Bild gleich (Fotos). Bei Textgröße 2,0 mit „Locker angehen“ oder „Heute ausruhen“ läuft die Zeile über und die Zahl verschwindet. **Das war vorher genauso**, also keine Regression, aber ein offener Rand bei sehr großer Schrift.
- **Aktivität-Tab:** Ohne `TaktLook` unverändert (Reiter in Sportfarbe, Fußnote ohne Hülle, NavBar). Upstream-Tests 140 grün.
- **Heute:** Die Sperre `_opening` hält, solange die Übersicht offen ist, und während `_load()` nach dem Zurück. In dieser kurzen Ladezeit nach dem Zurück wird ein Tipp auf ein Training verschluckt. Kaum spürbar, nur der Vollständigkeit halber.

## Weitere Beobachtungen (nicht von der Spec verlangt)
- **Lange Namen werden weiter gekürzt.** Der Name hat jetzt die ganze Breite, wird aber bei 320 px/1,0 bei 10 von 78 Sportarten gekürzt (z. B. „functional training“, „stand-up-paddling“, „kinderbetreuung“), bei 360 px/1,0 bei 3, bei 390 px/1,0 bei keiner; mit Textgröße 1,3 bei 34 / 11 / 5. Bei 320/1,3 steht „allgemei…“. Die Spec verlangt die Ganzlesbarkeit nur für Tag und Uhrzeit.
- Die Reiter der Übersicht stehen mittig (Foto `training`: „Übersicht“ beginnt bei etwa 80 px), bei HRV und Strain linksbündig. Das kommt aus OpenStrap (`Column` ohne `stretch`) und war schon in Runde 1 so.

## Sicherheit
Keine neuen Eingaben, Datenwege oder Berechtigungen gegenüber Runde 1. Die Änderungen betreffen nur Layout, eine Farbe und eine Sperrvariable im State.

## Zusammenfassung der offenen Punkte
1. ❌ **T4:** Bei 320 px und Textgröße 1,3 wird die Uhrzeit unter dem Namen bei jeder Sportart gekürzt („28. Sept. 2026, …“), weil die Spalte dort nur 144 px breit ist. Bei Textgröße 1,0 auf allen Breiten und bei 1,3 ab 360 px ist alles ganz. Die neuen T4-Tests prüfen nur Textgröße 1,0.
2. Hinweis: Für den Doppeltipp gibt es keinen Test im Repo.
3. Hinweis: `TaktValueCard` läuft bei Textgröße 2,0 mit langen Erholungswörtern über (schon vor diesem Commit so).

## Runde 3 (2026-11-08, eng gefasst: nur T4)

### Grundlage
- Stand: HEAD 6c49e65d plus Arbeitskopie. Geändert seit Runde 2: `lib/ui2/activity/summary.dart` (`takt-workout-when` mit `maxLines: 2` statt 1) und ein neuer Test in `test/takt/workout_takt_test.dart` („T4: Tag und Uhrzeit ganz sichtbar bei 320 px und Textgröße 1,3“, mit 28. Sept. 2026, 23:59). `pubspec.yaml` (0.3.1+8) stammt weiter nicht von der Prüfung.
- `flutter test test/takt/`: **192 Tests, alle grün** (191 aus Runde 2 plus der neue; ohne eigene Prüftests gelaufen).
- Eigener Wegwerf-Test unter `test/takt/` (danach gelöscht, ebenso die eigenen Fotos in `build/shots/`), mit `loadRealFonts`, `TaktLook`, deutscher Sprache, 24-h-Uhr. Alle 78 Sportarten aus `allActivities` × drei Daten (28. Sept. 2026, 23:59 · 8. Nov. 2026, 16:57 · 28. März 2026, 10:05) × 320/360/390 px × Textgröße 1,0/1,3/1,5/2,0, also 2808 Fälle. Je Fall geprüft: `didExceedMaxLines` des `RenderParagraph` von `takt-workout-when`, Höhe nicht kleiner als die nötige Höhe, keine Exception, Kopf endet über den Reitern, Datum innerhalb des Kopfs, nicht unter Pfeil oder Stift, Name nicht über dem Datum, Stift und Teilen ohne Überlappung. Dazu Fotos mit `TAKT_SHOTS=1` und `shot()` (320/1,3, 320/2,0, 360/1,0, längster Name „Allgemeines Training“, 28. Sept. 23:59), angesehen.

### Ergebnis T4: ❌ (nur noch 320 px bei Textgröße 2,0)

| Breite | 1,0 | 1,3 | 1,5 | 2,0 |
|---|---|---|---|---|
| 320 px | ✅ 1 Zeile | ✅ 2 Zeilen | ✅ 2 Zeilen | ❌ September gekürzt (78 von 234), sonst ✅ |
| 360 px | ✅ 1 Zeile | ✅ 1 Zeile | ✅ 1–2 Zeilen | ✅ 2 Zeilen |
| 390 px | ✅ 1 Zeile | ✅ 1 Zeile | ✅ 1 Zeile | ✅ 2 Zeilen |

- **Der Befund aus Runde 2 ist behoben:** Bei 320 px und Textgröße 1,3 bricht „28. Sept. 2026, / 23:59“ jetzt bei allen 78 Sportarten in die zweite Zeile um und steht ganz da (Foto). Auch 1,5 ist überall ganz. Der Kopf wächst mit, die Reiter rutschen nach unten, nichts wird überdeckt, Stift und Teilen bleiben rechts frei. Keine Exception, kein Überlauf in irgendeinem der 2808 Fälle.
- **Neu gefunden: 320 px, Textgröße 2,0, Datum im September.** Die Spalte unter dem Namen ist weiter fest 144 px breit. Bei 2,0 ist „28. Sept.“ 107 px breit, „2026, 23:59“ aber 145 px, also 1 px zu viel für die zweite Zeile. Der Text bräuchte drei Zeilen, `maxLines: 2` kürzt: Zu sehen ist „28. Sept. / 2026, 23:…“ (Foto), die Uhrzeit fehlt. Betroffen sind alle 78 Sportarten, sobald der Monat „Sept.“ heißt; mit „Nov.“ und „März“ passt es in zwei Zeilen. Bis Textgröße 1,9 passt auch September, ab etwa 330 px Breite auch bei 2,0. Auf Englisch („Sep 28, 2026, 23:59“) dasselbe bei 320/2,0.
- **Reproduktion:** `ActivitySummary` mit `handball()`, aber `start: DateTime(2026, 9, 28, 23, 59)`, in `TaktLook`, Locale `de`, `loadRealFonts`, `physicalSize` 320 × 1600, `devicePixelRatio` 1, `textScaleFactorTestValue = 2.0`; `RenderParagraph` von `ValueKey('takt-workout-when')`: `didExceedMaxLines == true`, Breite 144. Der neue Repo-Test prüft nur Textgröße 1,3 und ist deshalb grün.
- Nebenbei, nicht T4: Der Name selbst wird bei 320 px schon ab 1,3 gekürzt („allgemei…“, bei 2,0 „allge…“). Die Spec verlangt die Ganzlesbarkeit nur für Tag und Uhrzeit (siehe Runde 2, Weitere Beobachtungen).

### Offener Punkt
1. ❌ **T4:** 320 px mit Textgröße 2,0 und einem Datum im September: Die Uhrzeit wird abgeschnitten („2026, 23:…“), weil „2026, 23:59“ mit 145 px die 144-px-Spalte um 1 px überschreitet und `maxLines: 2` keine dritte Zeile erlaubt. Alle anderen geprüften Kombinationen sind ganz sichtbar.
