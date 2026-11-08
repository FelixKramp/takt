---
feature: 08-training
geprueft: 2026-11-08
stand: 5675c98a
pruefer: unabhängiger Prüfer-Agent (Phase 5, Runde 1)
---
# Prüfung: Training und „Workout nachtragen“ im Takt-Design (08)

## Grundlage
- Gelesen: `CLAUDE.md`, `docs/features/08-training/spec.md`, `architektur.md` des Features (eine `docs/architektur.md` gibt es nicht), `git show HEAD` (5675c98a). `plan.md` bewusst nicht.
- `flutter test test/takt/workout_takt_test.dart test/takt/today_screen_test.dart test/log_workout_test.dart test/score_imported_workout_test.dart`: **40 Tests, alle grün.**
- `flutter test test/takt/`: **185 Tests, alle grün** (nach dem Löschen der eigenen Prüftests erneut gelaufen).
- Upstream-Tests, die die geänderten Dateien berühren (`ui2_gallery`, `ui2_activity`, `ui2_workout_first_load`, `ui2_tokens`, `manual_session`, `workout_calorie_anchors`, `session_score_reconcile`, `set_state_future`, `live_rescore_calorie_parity`): **196 Tests, alle grün.**
- `flutter analyze` auf alle geänderten Dateien: keine Befunde.
- Bildschirmfotos: `training.png`, `nachtragen.png`, `strain.png`, `hrv.png` neu erzeugt und angesehen.
- Eigene Wegwerf-Tests unter `test/takt/` (danach gelöscht, `git status` sauber): langer Sportname bei 390 und 320 px, Textgröße 1,3/1,5/2,0 mit echten Schriften, Datumsbreite im Kopf bei 360/393/412 px für mehrere Sportarten, Training ohne Puls, privat, Zeiten ändern (mit `sessionId`), dunkles Theme (Übersicht, Nachtragen, Liste), ungültiger Zeitraum, Streifen-Hüllen (B5) auf Übersicht, Grafiken und Nachtragen. Mit echter Datenbank: Stift → Sportart (DB-Wert und Rücksprung), gelöschte Zeile → Sportart-Wahl, Doppeltipp, Nachtragen von Heute speichern.

## Ergebnis
✅ 12 · ❌ 1 · ⚪ 0

| ID | Ergebnis | Begründung |
|---|---|---|
| T1 | ✅ | `_openWorkout` → `taktWorkoutTarget` → `taktWorkoutResult` lädt die Zeile aus `getWorkouts('month')` und baut sie über `_pastFromRow`/`_detailOf`, also denselben Weg wie `_HistoryRow._open` im Aktivität-Tab. Test A9/T1/T3 tippt in der echten DB eine gespeicherte Erkennung an und findet `ActivitySummary` in `TaktLook`, keinen Picker. Eigener DB-Test: `sessionId` `suggestion:d:…`, Dauer 30 min wie gespeichert. Der Unit-Test T1 würde scheitern, wenn die falsche ID geladen oder kein Summary gebaut würde. |
| T2 | ✅ | `item.suggestion != null` → null → `_pickSport`. Unit-Test prüft, dass dann gar nicht geladen wird; Integrationstest „A9: Auch eine offene Erkennung bekommt ihre Sportart“ (offene Erkennung antippen → Picker → Handball) ist grün. Eine gespeicherte Erkennung (ID mit `suggestion:`-Präfix, aber ohne `suggestion`) öffnet richtig die Übersicht. |
| T3 | ✅ | Stift ruft das unveränderte `_changeType`: `setSessionType`, Picker zu, Übersicht zu, `_push` lädt Heute neu. Der Repo-Test prüft am Ende nur `find.text('Handball')`, nicht DB und Rücksprung. Eigener DB-Test ergänzt: Typ in der DB `handball`, keine `ActivitySummary` und kein `ActivityPicker` mehr im Baum (auch offstage), `TaktTodayScreen` sichtbar. Der Picker selbst bleibt im OpenStrap-Design (eigene Route ohne `TaktLook`); die Spec verlangt dort nichts. |
| T4 | ❌ | Zurück-Pfeil, kleiner Name, Stift, Teilen, `TaktValueCard` mit „55:00“ in Doto und „Gesamtzeit“, keine NavBar und keine 48-pt-Zahl: erfüllt (Test T4, Foto). **Aber Tag und Uhrzeit in der Mitte gehen bei vielen Sportarten oder schmalen Geräten verloren.** Der Name darf 40 % der Bildschirmbreite nehmen, Stift und Teilen 80 px, der Rest bleibt für „8. Nov. 2026, 16:57“ (braucht 109 px). Gemessen mit echten Schriften: bei 360 px (übliche Android-Breite) ist selbst bei „handball“ nur 89 von 109 px sichtbar, die Uhrzeit ist abgeschnitten; bei „Krafttraining“ 50 px, bei „Allgemeines Training“ 32 px („8. N…“). Bei 393 px: Krafttraining 83, Allgemeines Training / Functional Training / Stand-up-Paddling / Kinderbetreuung je ca. 50 px („8. Nov…“). Bei 320 px und Textgröße 1,3 bleibt bei „handball“ nur „8…“, bei langem Namen gar nichts. **Reproduktion:** `ActivitySummary` mit `activityByName('Weight training')` oder `'General workout'` in `TaktLook`, Breite 390 oder 360, Breite von `ValueKey('takt-workout-when')` messen bzw. Foto. Kein Überlauf, nichts stürzt ab, der Text kürzt sauber mit „…“; es fehlt nur die Information. Hinweis: Das Jahr „2026“ kostet allein ca. 35 px. Der Test T4 prüft nur, dass der Schlüssel existiert, nicht dass der Text sichtbar ist. |
| T5 | ✅ | `LineChart` bekommt unter `TaktLook` `Pult.orangeFor(p.dark)`. Test T5 prüft hell (`Pult.orange`), eigener Test dunkel (`orangeFor(true)` = #FF9A5C). Fotos hell und dunkel: orange Linie mit oranger Fläche wie die Strain-Kurve. |
| T6 | ✅ | `SessionStats._taktStats`: Name links (`F.body`, ink2), führende Zahl in Doto 22, Rest als Einheit („16“ + „bpm in 60 s“), keine `PosterStatRow`. Jede Wertzeile und jedes Label in `StripeDodge`. Test T6 prüft fünf Zeilen, Doto und Hülle für alle fünf Zahlen, er würde bei runden Symbolen oder fehlender Hülle scheitern. Beschriftung „Ø HF“ statt „Ø Puls“ kommt aus der OpenStrap-Übersetzung (kosmetisch). |
| T7 | ✅ | Reiter (`SubTabs`), Zonen und Fußnote bleiben, in Takt-Karten (Foto). Test T7 prüft nur Reiter und „Zone 5“, die Fußnote nicht. Am Rand: Der aktive Reiter ist in der Farbe der Sportart hinterlegt (Handball braun-orange, eine Kraftsportart lila, Laufen grün), während HRV/Strain in Feature 07 orange hinterlegen. Nicht von der Spec verlangt, aber uneinheitlich. |
| T8 | ✅ | `_taktBuild`: `TaktHeader('training nachtragen', back: true)`, fünf `_TaktLogRow` ohne Symbolkästchen, Beginn/Ende/Dauer in Doto, Einheit „min“ klein, Chevron für antippbare Zeilen. Test T8 prüft Kopf, fehlende `SetRow`, Doto für 17:00/18:00/60 und dass Beginn den Zeit-Dialog öffnet. Hell und dunkel per Foto geprüft. |
| T9 | ✅ | Hinweis als graue Zeile (`takt-log-note`, in `StripeDodge`), Knopf flach `Pult.orange`, `R.rSm`, Text `C.n900`, identisch zum Knopf auf Heute (`activity_list.dart`). Ungültiger Zeitraum: Knopf `onTap == null`, Farbe Orange mit 35 % Deckkraft, `StatusCard` mit Grund steht über dem Knopf (eigener Test misst die Lage). Test T9 deckt beides ab. Am Rand: Der Grund lautet „That window hasn't happened yet.“ auf Englisch. Das ist eine Übersetzungslücke von OpenStrap (`ManualWindowError.message`), im OpenStrap-Zweig genauso, nicht Feature 08. |
| T10 | ✅ | `TaktLook.peek` vor `showModalBottomSheet`, das Blatt bekommt `TaktLook` mit; Zeilen nur mit Namen und Trennlinie, kleiner Radius oben. Test T10 tippt Aktivität, findet `takt-type-row-0`, keine `SetRow`, wählt Handball und prüft die Zeile. Foto hell und dunkel: ohne bunte Kästchen. |
| T11 | ✅ | Der Takt-Knopf ruft dasselbe `_save` wie OpenStrap. Eigener DB-Test: Heute → „Workout nachtragen“ → Speichern schreibt `manual:… running` in die DB. Ohne Herzfrequenz im Fenster bleibt der Screen wie bisher offen und meldet „ohne Puls gespeichert“; mit Herzfrequenz schließt `nav.pop(true)`, danach lädt `_push` Heute neu (Code unverändert, im Test nicht mit Pulsdaten durchgespielt). Einen Takt-spezifischen Test für T11 gibt es im Repo nicht, nur `log_workout_test.dart` für den OpenStrap-Zweig. |

### Randfälle
| Randfall | Ergebnis | Begründung |
|---|---|---|
| Training ohne Pulsaufzeichnung | ✅ | Eigener Test: `hr` leer, kein `avgHr`/`maxHr`: keine `LineChart`, stattdessen „Keine Herzfrequenz für dieses Training“ mit „Bandverbindung prüfen →“ in einer Takt-Karte; Messwerte zeigen nur Kalorien und Strain in Punktziffern; Fußnote passt („kam keine Herzfrequenz an“). Kein Fehler. Der blaue Textlink ist derselbe wie auf dem Strain-Screen aus Feature 07. |
| Training lässt sich nicht laden | ✅ | Unit-Test: Loader gibt null oder wirft → null → Sportart-Wahl. Eigener DB-Test: Heute geladen, danach `sessions` geleert, Antippen → `ActivityPicker`, keine Übersicht, keine Ausnahme. Ein fehlendes Gewicht wird abgefangen. |

### Zusätzlich geprüft (aus dem Auftrag)
| Prüfung | Ergebnis | Begründung |
|---|---|---|
| Lange Sportartnamen im Kopf | ✅ kein Überlauf, siehe T4 | Name kürzt mit „…“ (`maxLines: 1`), bei 320 px und Textgröße 1,3 kein RenderFlex-Fehler. Der Preis ist die abgeschnittene Uhrzeit (T4). |
| Training mit privat-Flag | ✅ mit Einschränkung | „Privat“ steht rechts in der Wert-Karte. `TaktValueCard` setzt den Wert in `Flexible` neben ein `Spacer`; dadurch bekommt „55:00“ nur die halbe Breite und wird auf ca. 82 % verkleinert (138 statt 169 px). Genau diesen Fehler beschreibt der Kommentar im OpenStrap-Zweig („A `Flexible` hero next to a `Spacer` split the row by flex“). Bei einer Distanz wie „10,02 km“ oder „1.500 m“ schrumpft die Zahl entsprechend stärker. Kein Abschneiden, nur kleiner. |
| Zeiten ändern (`sessionId`) | ✅ | Kopf „zeiten ändern“, keine Aktivitätszeile, Zeilen 1–4 vorhanden, erste ohne Trennlinie oben, Knopf „Neue Zeiten speichern“. Mit eigenem `title` kein Überlauf. Hinweis: `LogWorkout` mit `sessionId` wird nur aus dem Aktivität-Tab geöffnet, also ohne `TaktLook`; der Takt-Zweig dafür ist in der App derzeit nicht erreichbar. |
| Erkennung mit `suggestion` | ✅ | Siehe T2. |
| Dunkles Theme | ✅ | Übersicht, Nachtragen und Sportart-Liste: Karten, Linien, Doto-Ziffern hell, Pulslinie `orangeFor(true)`, kein Überlauf. Speichern-Knopf bleibt `Pult.orange` mit dunkler Schrift wie auf Heute. |
| Streifen-Hüllen (Konvention aus Feature 02, B5) | ⚠ Hinweis | Auf Nachtragen und im Reiter Grafiken steht jede Ziffer in `StripeDodge`. In der Übersicht steht die Fußnote „Geschätzt aus 12.0 MET, deinem Gewicht …“ ohne Hülle. Die Spec verlangt die Hülle in T6 nur für die Messwerte, deshalb kein ❌; die CLAUDE.md-Regel „jede Zahl“ ist aber verletzt. Ein Test wie `stripe_today_test.dart` für die Übersicht fehlt. Nebenbei: „12.0“ mit Punkt im deutschen Text kommt aus OpenStrap. |
| Doppeltipp auf ein Training | ⚠ Befund | `_openWorkout` lädt erst Gewicht, Monatsliste mit Pulsstatistik und das Einzeltraining und schiebt dann. Ein zweiter Tipp während des Ladens öffnet eine zweite Übersicht (eigener DB-Test: zwei schnelle Tipps → zwei `ActivitySummary` im Stapel). Vorher öffnete `_pickSport` sofort. Während des Ladens gibt es auch keine Rückmeldung. Nicht in der Spec, aber am Gerät spürbar, wenn der Monat viele Trainings hat. |

## Sicherheit
- Keine neuen Eingaben von außen: Die Trainings-ID kommt aus der eigenen Liste von Heute und wird nur als String mit `getWorkouts('month')` verglichen, kein SQL aus Nutzereingaben. Alle Lesezugriffe (`getProfile`, `getWorkouts`, `getWorkout`) und der Schreibzugriff (`setSessionType`, `logManualWorkout`) gehen an die lokale SQLite-DB über bestehende Repository-Methoden. Kein Netzwerk, keine neuen Berechtigungen, keine Secrets.
- Der neue reguläre Ausdruck in `_taktStats` (`^([0-9][0-9.,:]*)\s+(\S.*)$`) ist verankert und ohne verschachtelte Wiederholung, also ohne Backtracking-Risiko; er läuft nur auf App-eigenen Texten.
- Teilen öffnet das unveränderte `ShareSheet` (OpenStrap-Design, Nicht-Ziel). Nichts wird automatisch geteilt.
- Ein Nebeneffekt, der schon im Aktivität-Tab besteht: `getWorkout` bewertet das Training beim Öffnen neu (`_rescoreSessionFromSubstrate`). Das passiert jetzt auch beim Antippen auf Heute; gewollt und lokal.

## Regressionen
- **Aktivität-Tab:** `WorkoutScreen` steht nicht in `TaktLook` (nur Heute-`_push`, Schlaf-Tab und das Sportart-Blatt setzen sie). Die herausgezogene `_pastFromRow` ist Zeile für Zeile dieselbe Umwandlung wie vorher in `_loadWorkoutData` (verglichen im Diff). `ActivitySummary` und `LogWorkout` ohne Takt-Haut: NavBar, `PosterStatRow`, `SetRow`, `BigButton` bleiben (Tests „ohne Takt-Haut bleibt OpenStrap“). Upstream-Tests rund um Aktivität, Workout-Liste und Nachtragen: 196 grün.
- **`TaktHeader` (Feature 06/07):** Ohne `center` nimmt der Name jetzt per `Expanded` den freien Platz, vorher stand dort ein leeres `Expanded`; das Bild ist gleich (Fotos HRV, Strain). Mit `center` (Schlaf-Tab) ist der Name auf 40 % der Bildschirmbreite begrenzt; „schlaf“ braucht bei 320 px und Textgröße 1,3 81 px und wird nicht gekürzt. Alle Schlaf-Kopf- und Detailtests in `test/takt/` grün. Kleiner Haken: Die Grenze rechnet mit `MediaQuery.sizeOf(c).width`, nicht mit der Breite der Zeile; in einem schmaleren Elternteil (z. B. Tablet-Spalte) wäre sie zu großzügig.
- **Heute A9:** Der alte Test „Antippen wählt die Sportart“ ist durch A9/T1/T3 ersetzt; die Sportart-Wahl für offene Erkennungen bleibt unverändert und getestet.

## Zusammenfassung der offenen Punkte
1. ❌ **T4:** Tag und Uhrzeit im Kopf werden bei 360 px schon für Handball, bei 390 px für Sportarten wie Krafttraining, Allgemeines Training, Functional Training, Stand-up-Paddling, Kinderbetreuung auf „8. Nov…“ oder weniger gekürzt.
2. ⚠ Doppeltipp öffnet zwei Übersichten, keine Ladeanzeige.
3. ⚠ Privat: Hauptwert in der Wert-Karte schrumpft auf etwa 82 % (`Flexible` + `Spacer` in `TaktValueCard`).
4. ⚠ Fußnote „12.0 MET“ ohne Streifen-Hülle; kein B5-Test für die Übersicht.
5. ⚠ Aktiver Reiter in der Sportfarbe statt Takt-Orange.
