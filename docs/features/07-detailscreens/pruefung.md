---
feature: 07-detailscreens
geprueft: 2026-11-08
stand: b7fde943
pruefer: unabhängiger Prüfer-Agent (Phase 5, Runde 2)
---
# Prüfung: Detailscreens von Heute im Takt-Design (07)

Runde 2, 2026-11-08

## Grundlage Runde 2
- Spec, beide Berichte der Runde 1 und `git show b7fde943` gelesen, `plan.md` bewusst nicht.
- `flutter test test/takt`: 167 Tests, alle grün. `flutter analyze lib/takt lib/ui2`: keine Befunde.
- Upstream-Tests zu `MetricDetail`, `ReadinessDetail`, `DayStrainDetail`, Shell, Tokens, Schrittziel und Komponenten-Sweep: 100 grün.
- Bildschirmfotos neu erzeugt (`erholung.png`, `hrv.png`, `strain.png`) und angesehen.
- Eigene Wegwerf-Tests unter `build/` (ignoriert, danach gelöscht): HRV, Ruhepuls und Schritte mit 200 Tagen in jedem Zeitraum (Heute, 7 Tage, 30 Tage, 6 Monate) mit Streifen bei 0,72; Bandfarbe je Zeitraum; alle Screens ohne Wert; Erholung und Strain ohne Wert mit Streifen; Erholung mit 90 Tagen Verlauf und fehlendem Baustein.

## Ergebnis Runde 2
✅ 12 · ❌ 0 · ⚪ 1

| ID | Ergebnis | Begründung |
|---|---|---|
| H1 | ✅ | Unverändert seit Runde 1. Einschränkung bleibt: Bei Erholung fehlt die Zeile „von wann“, wenn kein `recovery_update` kommt (Foto). |
| H2 | ✅ | Behoben. Im Takt-Zweig ist das Band `p.card2` (grau, #E2E2DD auf Karte #EDEDE9), upstream weiter `p.wash(spec.color)` (`metric_detail.dart:1419–1420`). Eigener Durchlauf: in 7 Tage, 30 Tage und 6 Monate ist `bandColor == p.card2`. Test H2 prüft das für „30 Tage“; er rendert ohne Basiswerte, also ohne gezeichnetes Band, und prüft nur die übergebene Farbe. Die Beschriftungen bleiben „7 Tage / 30 Tage / 6 Monate“ statt „Woche / Monat / Jahr“ (kosmetisch, wie Runde 1). |
| H3 | ✅ | Nicht berührt. Label „Typisch“ statt „üblich“ (kosmetisch). |
| H4 | ✅ | Nicht berührt. Der Test kann weiter nicht scheitern (siehe Runde 1), der Code ist richtig. |
| H5 | ✅ | Behoben. Im Takt-Zweig ist das Tagesziel ein Balken (`metric_detail.dart:1962–1992`, Schlüssel `takt-step-goal-bar`): graue Spur, Füllung in der Kennfarbe, Prozent darunter im `StripeDodge`. Bearbeiten über den unveränderten `Pressable`/`OsTextField` daneben. Upstream behält den Ring. Test H5 prüft nur, dass der Balken existiert. |
| H6 | ✅ | Nicht berührt. |
| H7 | ✅ | Nicht berührt. |
| H8 | ⚪ | Weiter nur am Gerät prüfbar: Mit `data:` gibt es kein Repo, das Blättern lässt sich im Test nicht auslösen. Am Gerät prüfen, ob Vortag und Folgetag laden. |
| H9 | ✅ | Nicht berührt, Foto „62 % Startklar“. |
| H10 | ✅ | Behoben. Bausteinnamen über `TaktText.driverName` (`takt_text.dart:38–44`) für alle vier Schlüssel hrv, rhr, resp, temp; der Grund über `needMessageFromNote` und `presentationText` (`readiness_detail.dart:239–240`). Foto und eigener Test: „Atmung“, „nicht verfügbar: Noch 5 Nächte nötig“, kein Englisch. Test H10 prüft „Atmung“ und das Fehlen von „Breathing rate“ und „Need“. Bleibt am Rand: Der Hinweis „relativ, unkalibriert“ bei Hauttemperatur fehlt im Takt-Zweig weiter; die Spec verlangt ihn nicht. |
| H11 | ✅ | Behoben. `_window` kürzt im Takt-Zweig auf die letzten 30 Tage (`readiness_detail.dart:464–469`). Eigener Test mit 90 Werten: Titel „Letzte 30 Tage“, Achse „vor 29 Tagen … Heute“. Balken in Stufenfarben wie upstream. Test H11 prüft den Titel. Hinweis zum Code: `_takt` wird als Nebenwirkung in `build` gesetzt (`:269`) und erst danach von `_window` gelesen; funktioniert, ist aber fragil. |
| H12 | ✅ | Behoben. „Tagesdurchschnitt · n von m Tagen“ steht jetzt in `taktDodge(line: true)` (`metric_detail.dart:1299–1305`), `StatusCard` ist geschützt (siehe 06 F13). Eigener Durchlauf: HRV, Ruhepuls und Schritte in allen vier Zeiträumen, Erholung ohne Wert, Strain ohne Wert: keine Ziffer ohne `RenderStripeDodge`-Vorfahr. Test H12 im Repo prüft nur HRV bei „7 Tage“. |
| H13 | ✅ | Behoben. Erholung ohne Wert zeigt im Takt-Zweig eine `TaktValueCard(value: null)` mit „–“, darunter dieselbe `StatusCard` mit dem Grund wie bisher („Keine Erholung berechnet“, „Noch 4 Nächte nötig“) (`readiness_detail.dart:285–289`). HRV, Ruhepuls, Schritte zeigen je einen Strich (eigener Test). Test H13 prüft Karte und Strich im Screen. |

### Zusatzbefund aus Runde 1
| Befund | Ergebnis | Begründung |
|---|---|---|
| Rohe Farbwerte in `band_row.dart` | ✅ | Behoben: `ScoreBand.okay.ink(p.dark)` und `Pult.orangeFor(p.dark)` (`band_row.dart:39`, `:113`). `grep "Color(0x" lib/takt` findet nur noch die Token-Definitionen in `pult_tokens.dart` und `sleep_score.dart`. |

### Regressionen Runde 2
- Alle Abzweigungen hängen an `TaktLook.on`; außerhalb der Haut bleiben Band, Schrittziel-Ring, Bausteinzeilen und 90-Tage-Verlauf wie upstream. 100 Upstream-Tests grün.
- Kein Kriterium mit ✅ aus Runde 1 ist durch die Korrekturen gekippt.

---

# Runde 1 (Stand 81e12048), zur Nachverfolgung

## Grundlage
- Spec und Architektur gelesen, `plan.md` bewusst nicht.
- `flutter test test/takt`: 156 Tests, alle grün. `flutter analyze lib/takt lib/ui2`: keine Befunde.
- Bildschirmfotos aus `shots_test.dart` (hrv, strain, erholung) angesehen.
- Zusätzlich eigene Wegwerf-Tests unter `build/` (ignoriert, danach gelöscht): HRV auf „7 Tage“ und „30 Tage“ mit Streifen-Prüfung, Schritte, HRV ohne Wert, Erholung ohne Wert, Erholung mit 90 Tagen Verlauf.

## Ergebnis
✅ 6 · ❌ 6 · ⚪ 1

| ID | Ergebnis | Begründung |
|---|---|---|
| H1 | ✅ | `detailScaffold` zeichnet in `TaktLook` den `TaktHeader` mit Zurück-Pfeil und kleinem Namen. Jeder Screen hat oben eine `TaktValueCard` mit Doto-Ziffern (Fotos: „hrv 68 ms heute“, „strain 12,4 heute“, „erholung 62 % Startklar“). Tests prüfen Gerüst und Karte. Einschränkung: Bei Erholung kommt die Zeile „von wann“ aus `recoveryStateLine` und fehlt, wenn die Pipeline kein `recovery_update` liefert (im Foto fehlt sie). Am Gerät ansehen. |
| H2 | ❌ | Zeiträume wechseln wie bisher. Das Band ist aber **nicht grau**: `bandColor: p.wash(spec.color)` (`metric_detail.dart:1419`). Im Takt-Zweig ist `spec.color` Takt-Orange, das Band also orange getönt (11 % bzw. 18 % Deckkraft). Der heutige Punkt ist farbig (Foto 7 Tage: offener Kreis am Ende). Kein Test für H2. Die Bezeichnungen sind „Heute / 7 Tage / 30 Tage / 6 Monate“, nicht „Woche, Monat, Jahr“ (Upstream-Stand, kosmetisch). |
| H3 | ✅ | Kopf, Verlauf bei Zeiträumen, „Niedrigster / Typisch / Höchster“ in Punktziffern (Test prüft Doto), „Was den Wert beeinflusst“ als `Surface` (in der Haut eine Takt-Karte), „Alle Messwerte“ als Link-Karte. Kleinigkeit: Das Label heißt „Typisch“, die Spec sagt „üblich“. „Was sie bewegt“ ist ungetestet, weil die Fixture keine `movers` hat. |
| H4 | ✅ | Kein `retainLiveHrView` und kein `LiveHrCard` bei `TaktLook.peek`/`on` (`metric_detail.dart`). Test prüft das Fehlen von `LiveHrCard`. Er läuft allerdings mit `data:` gesetzt, wo die Live-Karte auch upstream fehlt. Der Test kann also nicht scheitern; der Code ist trotzdem richtig. |
| H5 | ❌ | Das Tagesziel ist **kein Balken**, sondern weiter der Ring aus `_StepGoalGauge` (`metric_detail.dart:1968`, `Ring(...)`). Reproduktion: `MetricDetail('steps', data: …)` in `TaktLook` rendern: orange Ring „100%“ neben „Ziel 8,000 Schritte“. Das Ändern des Ziels funktioniert wie bisher. Der Test H5 prüft nur, dass es eine `TaktValueCard` gibt. |
| H6 | ✅ | Wert-Karte mit Tageswert, Kurve in Orange, Aktivitäten als Fläche (`_TaktActs`, Lage nach Wanduhr 00–24 Uhr wie die Kurve). Test und Foto bestätigen. Aktivitäten kommen aus `getWorkouts(range: 'month')`; beim Blättern über einen Monat zurück fehlen sie (Randnotiz). |
| H7 | ✅ | Fünf Zonenbalken mit Minuten, „Woraus sich der Wert zusammensetzt“ bleibt. Spitzenpuls und getragene Zeit stehen als Punktziffern, aber in der Kurvenkarte darüber, nicht direkt neben den Zonen, und der Tages-Strain steht dort ein zweites Mal. Inhaltlich erfüllt. Der Test prüft nur „171“. |
| H8 | ⚪ | `TaktDayStepper` über `availableDays()`, Tippen setzt `_day` und lädt neu (`day_strain.dart`). Der Test prüft nur, ob der Pfeil existiert. Mit `data:` gibt es kein Repo, also lässt sich das Blättern im Test nicht auslösen. Der Code ist plausibel. Am Gerät prüfen, ob Vortag und Folgetag laden. |
| H9 | ✅ | `TaktValueCard` mit „62 %“ und Stufenwort in Stufenfarbe (`p.on(band.color)`). Test und Foto bestätigen. |
| H10 | ❌ | Zeilen mit Wert, grauem Band, Punkt und Satz sind da (Test, Foto). **Ein fehlender Baustein steht aber auf Englisch.** Reproduktion: Foto `erholung.png`, dritte Zeile „Breathing rate“ und „nicht verfügbar: Need 5 more nights“ in der deutschen Oberfläche. Ursache: `uiText(c, f.label)` mit `f.label = driverLabel(key)` ohne Lokalisierung (`readiness_detail.dart:249`), und `whyFromNote(f.note)` liefert nur englischen Text (`:239`). Upstream (`_row`) zeigte „Atemfrequenz“ und „nicht verfügbar“. Für deutsche Nutzer ist das eine Regression. Außerdem fällt der Hinweis „relativ, unkalibriert“ bei Hauttemperatur im Takt-Zweig weg. |
| H11 | ❌ | Die Balken in Stufenfarben sind da (Upstream). Es sind aber **bis zu 90 Tage, nicht 30**: `denseDays(pointsOf(chart), 90)` (`readiness_detail.dart:100, 141`), im Takt-Zweig unverändert. Reproduktion: `ReadinessDetail` mit 90 Werten in `series` → Titel „Letzte 90 Tage“. Kein Test für H11. |
| H12 | ❌ | Die Tests prüfen nur den Zeitraum „Heute“, in dem der Verlauf im Takt-Zweig ausgeblendet ist. **Bei „7 Tage“ oder „30 Tage“ liegt „Tagesdurchschnitt · 7 von 7 Tagen“ ungeschützt** (`metric_detail.dart:1297–1305`, Text ohne `taktDodge`). Reproduktion: `MetricDetail('hrv', data: 30 Tage)` in `TaktLook`, `TaktStripe.fraction.value = .72`, „7 Tage“ antippen, `RenderParagraph` mit Ziffer ohne `RenderStripeDodge`-Vorfahr suchen. Ebenso ohne Schutz: jede `StatusCard` (`grammar.dart:1103 ff.`), z. B. Erholung ohne Wert „Noch 4 Nächte nötig“ und Strain „Das Band hat … % dieses Tages gesehen“. |
| H13 | ❌ | HRV, Ruhepuls, Schritte und Strain zeigen „–“ in der Wert-Karte (geprüft: HRV „–“, „Noch kein Wert.“, darunter die alte Begründung). **Erholung ohne Wert hat keine Wert-Karte und keinen Strich.** Der Takt-Zweig greift nur bei `v != null` (`readiness_detail.dart:341`), sonst kommt die alte `StatusCard` „Keine Erholung berechnet“. Reproduktion: `ReadinessDetail(data: ReadinessData(readiness: Metric.parse({'value': null, …})))` in `TaktLook`: 0 × `TaktValueCard`, 0 × „–“. Der Test H13 prüft nur `TaktValueCard` für sich, nicht die Screens. |

## Sicherheit
- Gleicher Diff wie 06 (`c1627e3f..HEAD`): keine Änderungen an Plattformdateien, `pubspec.yaml`, `.env*`, `protocol`, `analytics`.
- Neue Lesezugriffe `repo.availableDays()`, `repo.getWorkouts(range: 'month')`, `repo.getDayHeart(day)` gehen an die lokale Datenbank, nicht ins Netz. Keine Secrets, keine neuen Ziele, keine neuen Rechte.
- Ergebnis: unauffällig.

## Regressionen
- Gezielt ausgeführte Upstream-Tests zu `MetricDetail`, `ReadinessDetail`, `DayStrainDetail`, Shell, Tokens und Komponenten-Sweep: 96 grün.
- Die Abzweigungen in `metric_detail.dart`, `readiness_detail.dart`, `day_strain.dart` und `detailScaffold` hängen alle an `TaktLook.on`/`peek`. Erreicht man die Screens aus Aktivität oder Gesundheit, liegen sie außerhalb der Haut und verhalten sich wie upstream. `withColor` und der neue Parameter `center` sind abwärtskompatibel.
- H10 ist im Takt-Teilbaum eine sprachliche Regression gegenüber Upstream (englische Bausteinnamen und Gründe).
- Konvention: `lib/takt/detail/band_row.dart:38` und `:112` nutzen rohe Farbwerte (`0xFFFF9A5C`, `0xFFA63A00`), obwohl `Pult.orangeFor` und `ScoreBand.okay.ink` dafür existieren. Commit 81e12048 hat das nur in `lib/ui2` bereinigt.
- Feature 01 (A3, A4): Heute öffnet weiter dieselben Screens, `today_*`-Tests grün.
- Am Rand, nicht neu: In der deutschen Oberfläche stehen Tausendertrenner als Komma („8,008 Schritte“) und „Zuletzt 68 ms · Today“. Beides kommt aus Upstream-Formatierern, fällt in den Takt-Karten aber stärker auf.
