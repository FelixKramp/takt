# Stand

Übergabe zwischen Agenten (Claude Code, Antigravity). Diese Datei beschreibt nur
den **aktuellen** Stand und wird am Ende jeder Sitzung **neu geschrieben**, nicht
verlängert. Höchstens etwa 30 Zeilen. Was sich im Code geändert hat, steht in
`git log`; hier steht, was Git nicht weiß. Das Repo ist öffentlich: nichts
Privates (keine Schlafzeiten, Gesundheitswerte, Journalfragen).

**Aktualisiert:** 2026-11-15 · **Letzter Commit:** siehe `git log -1` · **Version:** 0.5.1+39

## Zuletzt dazugekommen
- Erkannte Workouts werden mit verbundenem Band wieder zeitnah gespeichert: Rechnung darf 10 Min hinter dem Datenstand liegen (`lib/takt/today/auto_confirm.dart`). Vorher blieb ein Training stundenlang „offen“: keine Belastung, Antippen öffnete nur die Sportart-Wahl
- Stressverlauf zeigt auch im Workout Werte (wie WHOOP); Durchschnitt, Zonen, Spitze ohne Workouts
- Stressverlauf: Zoom mit zwei Fingern (rohe Zeiger über `Listener`, Wischen bleibt), „Ganzer Verlauf“ setzt zurück (`stressZoomView`)
- Radfahr-Erkennung aus Build 36 zurückgenommen (15 Fehlalarme, Band zählt beim Treten Schritte). Befund und Vorschlag (Handy-Aktivitätserkennung) in `docs/features/15-rad-erkennen/spec.md`. Offene Vorschläge davon verwirft `ActivityStore.pending`
- Radfahren über die Aktivitätserkennung des Handys (Feature 15): `TaktMotion.kt` schreibt Wechsel mit, `phone_motion.dart` macht einen Gang mit ≥ 50 % Fahrrad zu Radfahren (in `sportOf` auf Heute)
- Davor: Bettzeit-Karte, Heute anordnen, Belastung & Erholung, Stress mit Nacht, Gehen-Erkennung

## Auf dem Gerät geprüft
- Speichern erkannter Workouts: ja (Pixel, Build 36)
- Gehen-Erkennung: ja, echte Spaziergänge erkannt
- Zoom: nur Widget-Test (adb kann keine zwei Finger)
- Fehlalarme verworfen und gespeicherte gelöscht: ja (Build 37)
- Handy-Wechsel kommen an: ja (Build 38). Echte Fahrt als Radfahren: noch offen

## Entscheidungen
- Gehen und Radfahren sind aus 1-Hz-Banddaten nicht trennbar, darum entscheidet das Handy; ohne Handy bleibt eine Fahrt Gehen
- Schlaf zählt nicht in Stress-Durchschnitt und -Zonen, wird aber im Verlauf gezeigt
- Bekannt: Heute-Tests können in einem Lauf über Mitternacht hängen

## Offen
- Uncommittete Änderungen aus einer anderen Sitzung (Tageswechsel auf Heute, bestätigter Schlaf, u. a. `derivation_engine.dart`, `wake_day.dart`): nicht von Claude, getrennt committen
- iOS-Simulator-Build vorbereiten (CocoaPods, Bundle-ID in `ios/Config`)
