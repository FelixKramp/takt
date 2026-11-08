# Architektur: Detailscreens von Heute (07)

Baut auf der Takt-Haut aus Feature 06 auf (`TaktLook`, siehe
`docs/features/06-schlaf-tab-ganz/architektur.md`). Heute pusht jeden Screen schon in einer
`TaktLook`. Kein Neubau der Screens, damit ihre Logik (Zeiträume, Quellen-Auswahl, Ziele,
Abwesenheitsgründe) bei Upstream-Merges mitläuft.

- **Rahmen (H1):** `detailScaffold` (`metric_detail.dart`) zeichnet im Takt-Teilbaum die
  `TaktHeader` mit Zurück-Pfeil und kleinem Namen. Jeder Screen stellt oben eine
  `TaktValueCard` (`lib/takt/detail/value_card.dart`): Wert in Punktziffern, Zeile „von wann“.
- **HRV, Ruhepuls, Schritte (H2–H5):** `MetricDetail` zweigt an wenigen Stellen mit
  `TaktLook.on(c)` ab: Akzentfarbe Takt-Orange statt Kennzahlfarbe, kein Live-Puls beim Ruhepuls,
  „niedrigster, üblich, höchster“ in Punktziffern, „Alle Messwerte“ als Link-Karte.
- **Strain (H6–H8):** `DayStrainDetail` bekommt im Takt-Teilbaum Kurve in Orange, die
  Aktivitäten des Tages als Markierungen (aus `repo.getWorkouts`), und Tage zum Blättern
  (`TaktDayStepper` über `repo.availableDays()`).
- **Erholung (H9–H11):** `ReadinessDetail` zeigt die Bausteine als Vergleichszeilen wie F8. Die
  Werte kommen aus denselben Quellen wie der Treiber-Screen: `getInsights()` (Aufschlüsselung)
  und `getDayHeart(day)['baselines']` über `driverFacts`. Neu gelesen, nicht neu berechnet.

Verworfen: eigene Screens unter `lib/takt/detail/` (doppelte Logik).

## Manuelle Aufgaben für Felix
Keine.
