---
feature: 04-batterie
freigegeben: 2026-11-09 (Felix: „Ja, sanftere Kurve“, vorher „dann kannst du die Battery auch schon umsetzen“)
---
# Spec: Batterie statt Erholung

## Nutzer und Nutzen
Felix will auf einen Blick sehen, wie viel Energie er heute noch hat. Der Erholungsring zeigt nur
den Stand vom Morgen. Die Batterie startet morgens bei der Erholung und wird über den Tag mit der
Belastung leerer. Dazu kommt ein Wochenverlauf, der zeigt, an welchen Tagen die Belastung über
der Erholung lag.

## Akzeptanzkriterien

### Batterie
- **D1** – Ladung am Morgen
  Ausgangslage: Die Erholung des Tages ist berechnet · Handlung: Heute-Tab öffnen · Ergebnis: Die
  Batterie startet beim Aufwachen mit dem Erholungswert (0 bis 100 %).
- **D2** – Verbrauch über den Tag
  Ausgangslage: Seit dem Aufwachen ist Belastung (Strain) angefallen · Handlung: Heute-Tab ansehen ·
  Ergebnis: Stand = Ladung am Morgen × (1 − (Strain / 21)^1,5), auf ganze Prozent gerundet. Bei
  Strain 0 bleibt sie voll, bei Strain 21 ist sie leer. Kleine Belastung zieht wenig ab, hohe
  überproportional mehr: Bei 78 % am Morgen bleiben nach Strain 6 noch 66 %, nach 14 noch 36 %,
  nach 16 noch 26 %. Die Rechnung steht in der Detailansicht.
- **D3** – Ring
  Ausgangslage: Batterie berechnet · Handlung: Heute-Tab öffnen · Ergebnis: Der erste Ring heißt
  „Batterie“ statt „Erholung“, zeigt den aktuellen Stand in Prozent und darunter die Ladung vom
  Morgen („von 78 %“).
- **D4** – Detail
  Ausgangslage: Heute-Tab offen · Handlung: Batterie-Ring antippen · Ergebnis: Eine Kurve zeigt
  den Stand über den Tag, aus dem Strain-Verlauf. Darunter steht, wie die Ladung zustande kam (der
  bisherige Erholungs-Detailscreen, erreichbar über „So entsteht die Ladung“).
- **D5** – Ohne Erholung
  Ausgangslage: Die Erholung fehlt (noch keine Nacht, Kalibrierung) · Handlung: Heute-Tab ansehen ·
  Ergebnis: Der Ring zeigt „–“ und denselben Grund wie bisher der Erholungsring.

### Wochenverlauf
- **D6** – Belastung gegen Batterie
  Ausgangslage: Mehrere Tage berechnet · Handlung: Heute-Tab nach unten scrollen · Ergebnis: Unter
  den Karten zeigt eine Karte die letzten sieben Tage als sieben Batterie-Säulen. Die helle Säule
  ist die Ladung am Morgen, der volle Teil darin, was am Abend übrig war. Was dazwischen fehlt,
  hat die Belastung verbraucht. Über jeder Säule steht der Rest in Prozent, darunter der Wochentag,
  heute hervorgehoben. Tage ohne Erholung bleiben leer mit „–“.
- **D7** – Zu viel gemacht
  Ausgangslage: An einem Tag hat die Belastung die Batterie unter 20 % gezogen · Handlung:
  Diagramm ansehen · Ergebnis: Dieser Tag ist hervorgehoben, mit dem Satz „Mehr belastet als
  erholt“.
- **D8** – Displaystreifen
  Ausgangslage: Streifen eingestellt · Handlung: Heute-Tab ansehen · Ergebnis: Keine Ziffer von
  Ring und Diagramm liegt auf dem Streifen (Regel B5).

## Randfälle
- Ein Tag ohne Strain-Wert: Die Batterie bleibt bei der Ladung vom Morgen, mit dem Hinweis
  „Belastung noch nicht berechnet“.
- Nickerchen laden die Batterie nicht auf. Das wäre eine eigene Rechnung und kommt später.

## Nicht-Ziele
- Stress, Puls in Ruhe oder Schritte im Verbrauch. Strain enthält die Herz-Kreislauf-Belastung
  schon.
- Die Erholungsrechnung selbst ändern. Die Ladung ist OpenStraps Erholung.
- Aufladen während des Tages.

## Daten
Aus vorhandenen Werten berechnet (Erholung, Strain, Strain-Verlauf), nichts Neues gespeichert.

## Änderungen
2026-11-09 · D2 · Felix: sanftere Kurve statt linear. Linear wäre fast jeder Handballtag unter 20 % gefallen (Strain 16 bei 78 % ergäbe 19 %), und D7 hätte nichts mehr ausgesagt.
2026-11-09 · D6 · Bau: sieben Batterie-Säulen statt zwei Linien. Zwei Linien mit verschiedenen Skalen (0 bis 100 % und 0 bis 21) lassen sich nicht gegeneinander lesen. In der Säule sieht man Ladung, Rest und Verbrauch direkt.
