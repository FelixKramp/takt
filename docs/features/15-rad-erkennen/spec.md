---
feature: 15-rad-erkennen
freigegeben: offen (erster Versuch zurückgenommen, neuer Weg wartet auf Felix)
---
# Spec: Radfahren automatisch erkennen

## Nutzer und Nutzen
Felix wünscht, dass Radfahren wie Gehen automatisch erkannt wird und eine Fahrt nicht als
„Gehen“ gespeichert wird.

## Erster Versuch (Build 36, zurückgenommen in Build 37)
Annahme war: Am Rad steht der Schrittzähler still, der Puls ist erhöht. Beides falsch für Felix'
Band:
- **Der Gen5-Zähler zählt beim Treten Schritte**, in einer bestätigten Fahrt 100–120 pro Minute,
  genauso viele wie beim Gehen. Die Fahrt landete deshalb als „Gehen“.
- Abschnitte mit erhöhtem Puls und 0 Schritten waren Sitzen, etwa nach dem Training. Daraus
  wurden in drei Tagen 15 Fehlalarme, sechs davon automatisch gespeichert.

## Befund aus allen Schritt-Abschnitten seit Beginn der Banddaten
Geprüft je Minute: Schritte, Puls, Drehung des Handgelenks (Streuung des Schwerkraftvektors bei
1 Hz).
- Schritte trennen nicht (beide 100–120/min).
- Die Drehung ist am Lenker meist klein (Median 0,08), beim Gehen oft größer (0,15–0,25), aber
  mehrere vermutliche Gänge liegen genauso tief (Hände in der Jacke). Kein sicherer Schnitt.
- Puls hängt am Tempo, nicht an der Sportart.
- Die Spalten `step_cadence` und `activity_class` des Bands trennen auch nicht.

Folgerung: Aus den 1-Hz-Banddaten allein lässt sich Gehen nicht verlässlich von Radfahren trennen.

## Umsetzung (Build 38, freigegeben von Felix am 15.11.)
Die Aktivitätserkennung des Handys (Android Activity Recognition, Transition API) liefert diese
Unterscheidung aus Handy-Sensoren.
- `TaktMotion.kt` meldet Wechsel für zu Fuß, Laufen, Fahrrad, Fahrzeug und still an, bei jedem
  Engine-Start neu (nach Neustart und Update nötig). Ein Broadcast-Empfänger schreibt sie auch
  ohne laufendes Dart in eigene SharedPreferences, 14 Tage lang.
- `lib/takt/walk/phone_motion.dart`: `motionSpans` macht aus den Wechseln Spannen (eine Spanne
  endet am Ende der Aktivität, am nächsten Beginn oder spätestens nach 3 Stunden).
  `phoneSportFor` gibt `cycling`, wenn mindestens die Hälfte eines Gangs Fahrrad war.
- Heute (`sportOf`): Ein erkannter Gang wird Radfahren, wenn das Handy es sagt. Die eigene
  Sportart-Wahl geht vor. Gespeichert wird mit dieser Sportart.
- Berechtigung „Körperliche Aktivitäten“ kommt von den Handy-Schritten; ohne sie bleibt alles
  wie vorher. Das Handy muss bei Felix sein.

## Akzeptanzkriterien
- **R1–R9** in `test/takt/phone_motion_test.dart` (ganze Fahrt, Gehen bleibt Gehen, Hälfte als
  Grenze, Ende beendet, fehlendes Ende höchstens 3 h, offene Fahrt nicht über jetzt, ohne Daten
  nichts, native Liste lesen, Katalog).
- **R10** – Anmeldung auf dem Pixel: Wechsel kommen an (geprüft, Build 38).
- **R11** – Nach einer echten Fahrt steht „Radfahren“ statt „Gehen“ auf Heute. *Noch offen.*
