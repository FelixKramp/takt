# Architektur: Heute-Screen

Leitidee: Takt ist ein dünner Fork. Neuer Code liegt möglichst in neuen Dateien, bestehende
Upstream-Dateien werden nur an wenigen, klar benannten Stellen angefasst, damit Updates von
OpenStrap ohne große Konflikte hineinlaufen.

## Bestandteile

| Teil | Art | Zweck |
|---|---|---|
| `lib/takt/today/takt_today_screen.dart` | neu | Der neue Heute-Tab: Ringe, Puls, Karten, Aktivitäten |
| `lib/takt/today/dial_ring.dart` | neu | Ring als Drehregler mit Teilstrichen, inklusive Kalibrier-Zustand |
| `lib/takt/today/pulse_display.dart` | neu | Puls-Display, nutzt den Live-Strom von `AppState`, zeigt letzten Wert grau |
| `lib/takt/today/activity_list.dart` | neu | Eine Liste aus erkannten, gestarteten und nachgetragenen Workouts |
| `lib/takt/today/auto_confirm.dart` | neu | Bestätigt erkannte Workouts automatisch und merkt sich „erkannt" |
| `lib/takt/brand.dart` | neu | Name, Links, Quellcode-Adresse an einer Stelle |
| `lib/takt/update_check.dart` | neu | Fragt einmal täglich die GitHub-Releases von Takt ab (A25) |
| `lib/ui2/theme.dart` | geändert | Pult-Farben, Schriften Doto und Archivo |
| `lib/ui2/app_shell.dart` beziehungsweise `lib/app.dart` | geändert | Heute-Tab zeigt den neuen Screen |
| `lib/ui2/screens/health_screen.dart` | geändert | Eintrag zum alten Heute-Screen (Plan, Hinweise, Wecker), erfüllt A5 |
| `android/app/build.gradle.kts`, Manifest, Icons | geändert | Eigene `applicationId`, Name Takt, eigenes Icon. Der Kotlin-Paketname bleibt, das hält den Fork dünn |
| `lib/l10n/*.arb` | geändert | App-Name in den Texten, Herkunftshinweis bleibt |

Bestehend und unverändert genutzt: `protocol`, `analytics`, Bluetooth-Engine, Sync und Berechnung,
`LiveHrCard`-Logik (`AppState.retainLiveHrView`), `MetricDetail`, `ReadinessDetail`, `SleepDetail`,
`DayStrainDetail`, `log_workout.dart`, Datenbank-Export und -Import.

Der alte `HomeScreen` wird nicht gelöscht, er wandert hinter den Eintrag im Gesundheit-Tab. So
bleiben Plan, Hinweise und Wecker erreichbar, und Upstream-Änderungen daran mergen weiter sauber.

## Datenmodell und Rechte

| Objekt | Felder | Wer darf lesen | Wer darf schreiben |
|---|---|---|---|
| Workout (bestehend) | wie Upstream | nur die App auf dem Handy | die App |
| Merkliste „erkannt" (neu) | Workout-IDs, die aus einer Erkennung entstanden sind | nur die App | `auto_confirm.dart` |

Keine Konten, kein Server. Alle Daten bleiben auf dem Handy.

## Verhalten und Fehlerfälle
- Erkanntes Workout → wird beim Laden des Heute-Tabs und nach jeder Berechnung bestätigt und ist
  damit ein normales Workout mit Strain. Nickerchen bleiben im bisherigen Ablauf.
- Bestätigen scheitert, etwa wegen Überlappung → das Workout steht weiter in der Liste, ohne
  Strain-Wert, und bleibt per Antippen bearbeitbar.
- Verwerfen → das Workout wird gelöscht, die Erkennung bleibt als bearbeitet markiert und kommt
  nicht zurück.
- Band getrennt → `AppState.liveHr` liefert nichts, das Display zeigt den letzten Wert grau mit
  Uhrzeit und Grund.
- Weniger als 14 Nächte → `need_baseline`-Hinweis steuert den Kalibrier-Zustand des Rings.

## Entscheidungen

| Entscheidung | Verworfen | Warum |
|---|---|---|
| Neue Dateien unter `lib/takt/` | `home_screen.dart` umschreiben (2.700 Zeilen) | Ein Umbau dort würde bei jedem Upstream-Update Konflikte erzeugen |
| Workouts automatisch bestätigen | Vorschläge nur anzeigen | Nur bestätigte Workouts haben Strain und zählen in Verläufen |
| `applicationId` ändern, Kotlin-Paket lassen | Paket umbenennen | Takt läuft neben Edge, ohne dass 17 Kotlin-Dateien vom Original abweichen |
| Update-Prüfung gegen GitHub-Releases von FelixKramp/takt, Fehlerberichte an OpenStrap aus | Weiter deren Server ansprechen | Der OpenStrap-Hinweis würde Edge anbieten, Fehler von Takt gehören nicht zu OpenStrap |
| Kein Firebase | Eigenes Firebase-Projekt | Upstream baut ohne `google-services.json`, kein Dienst nötig |
| Bestehender Hintergrundbetrieb für A14 | Eigener Hintergrund-Job | Android hält die Verbindung schon per Vordergrunddienst offen, wird auf dem Gerät geprüft |

## Manuelle Aufgaben für Felix
- **🙋 Band umziehen** — vor dem Test in OpenStrap Edge die Datenbank exportieren, Edge schließen,
  Takt installieren, Datenbank importieren, Band koppeln. Nur eine App kann das Band gleichzeitig nutzen.
- **🙋 Gerätetest** — A6, A12 und A14 lassen sich nur mit Band und Handy prüfen.

## Freigabe
2026-11-06, freigegeben von Felix
