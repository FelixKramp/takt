---
feature: 15-rad-erkennen
freigegeben: offen (Entwurf, wartet auf Felix)
---
# Spec: Radfahren automatisch erkennen

## Nutzer und Nutzen
Felix wünscht, dass Radfahren wie Gehen automatisch erkannt wird. Bisher heißen Bouts der
Puls-Erkennung (`autoDetectWorkouts`, ≥ 45 % HRR, ≥ 12 Minuten) nur „detected“ ohne Sportart, und
gemütliches Fahren liegt unter dieser Schwelle und wird nie gefunden.

## Merkmal
Am Handgelenk: Puls deutlich über Ruhe, Schrittzähler fast still (Hand am Lenker). Gen5-Zähler aus
dem Substrat (`stepCount`), wie in Feature 14.

## Regel
1. **Bout der Puls-Erkennung** mit im Mittel höchstens **25 Schritten/Minute** heißt `cycling`.
   Ohne Zählerstand in mindestens der Hälfte der Minuten bleibt die Sportart, wie sie ist.
2. **Eigene Erkennung darunter:** Eine Minute zählt als Fahren bei Puls ≥ **Ruhepuls + 30** und
   ≤ 25 Schritten. Pausen bis **2 Minuten** werden überbrückt, eine Fahrt zählt ab **10 Minuten**
   und bis 180 Minuten.
3. **Sichtbarer Anfang ist Pflicht**, sonst wäre Sitzen mit hohem Puls (Prüfung, Aufregung) eine
   Fahrt: In den 3 Minuten davor wurde gegangen (≥ 60 Schritte/Minute), oder der Puls steigt vom
   Mittel der 3 Minuten davor zum Mittel der ersten 3 Minuten um ≥ 12 bpm.
4. Gesperrt sind gespeicherte Trainings, Bouts der Puls-Erkennung und erkannte Gänge.
5. Ohne Ruhepuls des Tages oder ohne Schrittzähler (Gen4) keine Erkennung.

Warum streng: Erkannte Workouts werden 30 Minuten nach dem Ende ohne Rückfrage gespeichert. Ein
Fehlalarm kostet mehr als eine verpasste Fahrt.

## Akzeptanzkriterien
- **R1** – Gehen zum Rad, dann 20 Minuten Fahrt: eine Fahrt über genau diese 20 Minuten.
- **R2** – Schneller Pulsanstieg ohne Gehen davor zählt als Anfang.
- **R3** – Langsam steigender Puls im Sitzen ist keine Fahrt.
- **R4** – 9 Minuten sind keine Fahrt, 10 Minuten sind eine.
- **R5** – Ampel bis 2 Minuten überbrückt, 3 Minuten trennen.
- **R6** – Puls unter Ruhe + 30 ist keine Fahrt.
- **R7** – Viele Schritte bei hohem Puls (Laufen, Handball) sind kein Radfahren.
- **R8** – Gesperrte Spannen unterbrechen.
- **R9** – Ohne Ruhepuls oder Schrittzähler keine Erkennung.
- **R10** – Ein „detected“-Bout mit kaum Schritten wird `cycling`, Handball nicht.
- **R11** – Vorschlag mit `sport: cycling`, passt auf den Katalog.
- **R12** – Auf dem Pixel nach einer echten Fahrt. *Noch offen.*

## Bekannte Grenze
Krafttraining hat auch wenig Schritte bei hohem Puls und kann als Radfahren vorgeschlagen werden.
Die Sportart lässt sich wie gewohnt ändern.

## Umsetzung
`lib/takt/walk/cycle_detect.dart` (rein), Aufruf in `_computeWorkouts` der
`derivation_engine.dart` (TAKT-Kommentar). Tests: `test/takt/cycle_detect_test.dart`.
