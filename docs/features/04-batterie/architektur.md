# Architektur: Batterie (Feature 04)

Die Batterie ist reine Darstellung aus vorhandenen Werten. Es wird nichts gespeichert und nichts
neu gerechnet, was OpenStrap rechnet.

## Bestandteile
- **`lib/takt/battery/battery.dart` (neu), reine Rechnung ohne Flutter-Abhängigkeit an Daten:**
  - `batteryLeft(morning, strain)`: Ladung × (1 − (Strain/21)^1,5), gerundet. Bei einem
    fehlenden Strain bleibt die Ladung voll stehen (D2, Randfall).
  - `batteryCurve(morning, strainCurve)`: der Stand pro Minute aus der kumulierten
    Strain-Kurve des Tages (D4).
  - `BatteryDay` und `batteryWeek(recovery, strain, today, …)`: sieben Tage aus
    `getChart('recovery')` und `getChart('strain')`. Heute kommt aus `HomeData`, weil der
    Verlauf erst nach der Rechnung des Tages einen Punkt hat (D6, D7).
  - `batteryRing(HomeData, l, t)`: Ring „Batterie“. Ohne Erholung oder während der Nacht nimmt
    er OpenStraps Erholungsring, nur mit neuem Namen (D3, D5).
- **`lib/takt/battery/battery_detail.dart` (neu):** Detailscreen hinter dem Ring.
  - Wertkarte, Tageskurve, die Rechnung als Zeilen und „So entsteht die Ladung“ →
    `ReadinessDetail` (D4).
  - Lädt `HomeData` und `DayStrainData`. Für Tests lassen sich die Daten einsetzen.
- **`lib/takt/battery/battery_week.dart` (neu):** Die Karte mit den sieben Säulen (D6–D8).
- **`takt_today_screen.dart`:**
  - Der erste Ring kommt aus `batteryRing`. Der Ring führt zu `BatteryDetail`.
  - `_loadLastValues` lädt zusätzlich die beiden Verläufe für die Woche.

## Fehlerfälle
- Ohne Verlauf erscheint keine Wochenkarte. Der Rest von Heute bleibt.
- Ohne Strain-Kurve zeigt das Detail nur Wertkarte und Rechnung.

## Verworfen
- Den Stand im Hintergrund speichern: Er ist aus Erholung und Strain jederzeit herleitbar.
- Zwei Linien für die Woche, siehe die Änderung an D6 in der Spec.
