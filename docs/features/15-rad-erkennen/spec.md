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

## Vorschlag (wartet auf Freigabe)
Die Aktivitätserkennung des Handys (Android Activity Recognition: zu Fuß, Fahrrad, Fahrzeug)
liefert genau diese Unterscheidung aus Handy-Sensoren. Takt merkt sich ihre Übergänge und gibt
einem erkannten Gang die Sportart `cycling`, wenn das Handy in dieser Zeit überwiegend „Fahrrad“
gemeldet hat. Braucht die Berechtigung „Körperliche Aktivitäten“ und ein Handy am Körper.
