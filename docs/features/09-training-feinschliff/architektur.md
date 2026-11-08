# Architektur: Training, Feinschliff (Feature 09)

Gleiches Muster wie Feature 06 bis 08: Die Takt-Haut (`TaktLook`) entscheidet in den
OpenStrap-Dateien, welcher Zweig zeichnet. Logik und Daten bleiben OpenStraps.

## Bestandteile
- **`lib/takt/detail/hr_scrub.dart` (neu), `TaktHrScrub`:** Pulskurve mit Ablesezeile. Sie
  nutzt OpenStraps `Scrubber` (Antippen, Wischen, Screenreader-Schritte), `ChartFrame` und
  `LineChart.selectedX`. Optional gibt es einen hinterlegten Zeitraum und die Knöpfe
  „Beginn hier“ und „Ende hier“. Die gewählte Minute bleibt nach dem Loslassen stehen. Sie wird
  zurückgesetzt, wenn eine neue Kurve kommt.
- **`summary.dart`:**
  - `_hrFrame` zeichnet unter der Takt-Haut `TaktHrScrub` (W4, W5).
  - `_taktStats` benennt „HR recovery“ als „Pulsabfall nach 1 Min.“ mit Erklärung (W9).
  - `_changeType` legt die Takt-Haut über die Sportart-Wahl und lädt die zuletzt gemachten
    Sportarten (W1).
- **`picker.dart`:** `_taktBuild` mit Takt-Kopf, Suchzeile, Zeilen ohne bunte Symbole und
  Kalorien-Hinweis als Zeile (W1, W2). Die Tastatur öffnet sich nicht von selbst.
- **`takt_today_screen.dart`:** `_pickSport` wie oben (W3).
- **`workout_screen.dart`:** `taktRecentSports(app)` hat dieselbe Regel wie die Kacheln im
  Aktivität-Tab: Monatsliste, nur Trainings vom Band, höchstens sechs.
- **`log_workout.dart`:**
  - `_loadHr` liest `LocalDb.hrSamplesInRange` von Beginn −30 bis Ende +30 Minuten und mittelt
    pro Minute.
  - Bei jeder Zeitänderung wird neu geladen. Veraltete Antworten werden über einen Zähler
    verworfen.
  - Über zwölf Stunden wird nichts gelesen.
  - Für Tests lässt sich der Lesezugriff über `hrSamples` einsetzen.
  - Die Knöpfe setzen nur die jeweilige Zeit. Gültigkeit prüft wie bisher
    `validateManualWindow`.

## Fehlerfälle
- Ein Lesefehler oder keine Daten zeigen die graue Zeile (W8). Speichern bleibt möglich.
- Lädt die Liste der zuletzt gemachten Sportarten nicht, erscheinen die häufigen Sportarten.

## Verworfen
- Den Zeitraum direkt auf der Kurve ziehen: Das ist fummelig auf dem Handy und braucht mehr
  Gestenlogik. Die Knöpfe sind ein Tipp.
- Ein eigener Uhrzeit-Wähler: Felix will das vorerst nicht.
