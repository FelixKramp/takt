---
feature: 03-schlafscore
freigegeben: 2026-11-08 (mit der Spec und Board A+)
---
# Architektur: Schlafscore und Schlaf-Tab

## Bestandteile (alles unter `lib/takt/sleep/`)
- `sleep_score.dart`, reine Rechnung (C1–C3, C12)
  - `scoreNight(durationMin, needMin, efficiencyPct, regularity)` liefert den Score und die drei Teile.
  - `ScoreBand` gut/okay/knapp mit Farbe (Fläche und Text).
- `night_log.dart`, die Tagesnotiz. OpenStrap hält Bedarf, Bedarfsteile und Bett-/Aufstehempfehlung nur als aktuellen Wert, nicht pro Tag. Takt schreibt sie deshalb bei jedem Laden unter dem heutigen Datum in die Prefs (`takt.night_log`, höchstens 30 Tage). Der letzte Stand eines Tages bleibt stehen.
  - Der Score einer Nacht nutzt den Bedarf, den Takt am Vortag notiert hat.
  - Fehlt diese Notiz, etwa in der ersten Woche, rechnet er mit Grundbedarf plus Schlafschuld, ohne den Zuschlag für die Belastung des laufenden Tags. Sonst würde der Score der letzten Nacht über den Tag wandern.
- `sleep_tab_data.dart`, der Lader. Er nutzt `SleepData.load` (Upstream) für Nacht, Bedarf und Schuld. Dazu liest er:
  - `getChart('sleep')` und `getChart('efficiency')` für sieben Nächte
  - `sleepWindows(7)` für die Bett- und Aufwachzeiten
  - `getInsights()` für `regularity` und `sleep_coach`
- `sleep_head.dart`, die Widgets: Zifferblatt, Teile, sieben Nächte, Dauer und Bedarf, Regelmäßigkeit, Effizienz. Jede Zahl steht in `StripeDodge` (C13).
- Einhängen:
  - `SleepDetail` bekommt den optionalen Parameter `head`. Ist er gesetzt, ersetzt er Abschnitt 1 („The answer“). Das ist ein Eingriff von einer Zeile in die Upstream-Datei.
  - `SleepTab` übergibt den Takt-Kopf (C4–C9). Die übrigen Abschnitte bleiben unverändert.
  - Heute: `TaktTodayView` bekommt `sleep` (Score und Stufe) und zeichnet den Schlafring damit (C11).

## Entscheidungen
- **Regelmäßigkeit pro Nacht** kommt aus OpenStraps SRI-Paaren (`regularity.value.pairs[].sri`, Datum je Paar). SRI läuft von −100 bis 100. Für den Score wird er auf 0 bis 100 begrenzt. Fehlt das Paar einer Nacht, gilt der Gesamtwert, fehlt auch der, greift C2.
- **Effizienz** der letzten Nacht aus dem Nachtdatensatz (0 bis 1, mal 100). Frühere Nächte aus `getChart('efficiency')` (ganze Prozent).
- **Wachphasen** für C8 aus dem Hypnogramm der Nacht (Stufe `wake`). Aufwachereignisse aus der Reihe `awakenings`.
- **Empfehlungslinie (C7):** Die Bett- und Aufstehempfehlung stehen in der Tagesnotiz. Tage ohne Notiz lassen die Linie dort aus.
- **Farben:** blau `#2F62C9` (Text ebenso), Takt-Orange `#F0560A` (Text `#A63A00`), rot `#B3261E`. Die Kontraste prüft ein Test gegen die Kartenfläche.
- Verworfen:
  - Scores pro Nacht in OpenStraps Datenbank schreiben. Das wäre ein Eingriff in die Berechnung und würde Upstream-Merges erschweren.
  - Den heutigen Bedarf für alle sieben Nächte nehmen. Er enthält die Belastung von heute und würde alte Nächte schlechter machen.

## Daten
Nur die Tagesnotiz in den lokalen Prefs. Sie wird nicht exportiert.
