# Stand

Übergabe zwischen Agenten (Claude Code, Antigravity). Diese Datei beschreibt nur
den **aktuellen** Stand und wird am Ende jeder Sitzung **neu geschrieben**, nicht
verlängert. Höchstens etwa 30 Zeilen. Was sich im Code geändert hat, steht in
`git log`; hier steht, was Git nicht weiß. Das Repo ist öffentlich: nichts
Privates (keine Schlafzeiten, Gesundheitswerte, Journalfragen).

**Aktualisiert:** 2026-11-15 · **Letzter Commit:** siehe `git log -1` · **Version:** 0.5.1+36

## Zuletzt dazugekommen
- Erkannte Workouts werden mit verbundenem Band wieder zeitnah gespeichert: Rechnung darf 10 Min hinter dem Datenstand liegen (`lib/takt/today/auto_confirm.dart`). Vorher blieb ein Training stundenlang „offen“: keine Belastung, Antippen öffnete nur die Sportart-Wahl
- Stressverlauf: Zoom mit zwei Fingern (rohe Zeiger über `Listener`, Wischen bleibt), „Ganzer Verlauf“ setzt zurück (`stressZoomView`)
- Radfahren erkennen (Feature 15, Spec-Entwurf): `lib/takt/walk/cycle_detect.dart`, eingehängt in `_computeWorkouts`
- Davor: Bettzeit-Karte, Heute anordnen, Belastung & Erholung, Stress mit Nacht, Gehen-Erkennung

## Auf dem Gerät geprüft
- Speichern erkannter Workouts: ja (Pixel, Build 36)
- Gehen-Erkennung: ja, echte Spaziergänge erkannt
- Zoom: nur Widget-Test (adb kann keine zwei Finger)
- Radfahren: nur synthetische Tests, noch keine echte Fahrt

## Entscheidungen
- Radfahren streng: Puls ≥ Ruhe + 30, ≤ 25 Schritte/Min, ≥ 10 Min, sichtbarer Anfang Pflicht (Gehen davor oder Pulsanstieg ≥ 12). Krafttraining kann als Radfahren erscheinen
- Schlaf zählt nicht in Stress-Durchschnitt und -Zonen, wird aber im Verlauf gezeigt
- Bekannt: Heute-Tests können in einem Lauf über Mitternacht hängen

## Offen
- Uncommittete Änderungen aus einer anderen Sitzung (Tageswechsel auf Heute, bestätigter Schlaf, u. a. `derivation_engine.dart`, `wake_day.dart`): nicht von Claude, getrennt committen
- iOS-Simulator-Build vorbereiten (CocoaPods, Bundle-ID in `ios/Config`)
