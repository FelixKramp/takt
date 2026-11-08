---
feature: 03-schlafscore
freigegeben: offen
---
# Spec: Schlafscore und Schlaf-Tab

## Nutzer und Nutzen
Felix will morgens mit einer Zahl sehen, wie gut er geschlafen hat. OpenStrap zeigt nur die Dauer
und vergleicht sie mit den eigenen Nächten, einen Score gibt es dort bewusst nicht. Takt rechnet
einen Score aus Werten, die schon gemessen werden. Wie er entsteht, steht direkt darunter, damit
er keine Blackbox ist.

## Akzeptanzkriterien

### Score
- **C1** – Berechnung
  Ausgangslage: Eine Hauptschlafphase mit Dauer, Bedarf, Effizienz und Regelmäßigkeit liegt vor ·
  Handlung: Schlaf-Tab öffnen · Ergebnis: Der Score (0 bis 100, ganze Zahl) setzt sich so zusammen:
  - 50 %: Dauer im Verhältnis zum Bedarf, bei 100 gedeckelt
  - 25 %: Effizienz, linear von 70 % (0 Punkte) bis 95 % (100 Punkte)
  - 25 %: Regelmäßigkeit, so wie sie OpenStrap schon berechnet (0 bis 100)
- **C2** – Fehlende Teile
  Ausgangslage: Regelmäßigkeit oder Effizienz fehlt, etwa in der ersten Woche · Handlung:
  Schlaf-Tab öffnen · Ergebnis: Der Score rechnet mit den vorhandenen Teilen, ihre Gewichte werden
  anteilig hochgerechnet. Der fehlende Teil steht als „noch nicht genug Nächte“ da. Fehlen Dauer
  oder Bedarf, gibt es keinen Score, sondern einen Strich und den Grund.
- **C3** – Einordnung
  Ausgangslage: Score berechnet · Handlung: Schlaf-Tab ansehen · Ergebnis: Neben der Zahl steht
  „gut“ (ab 85), „okay“ (70 bis 84) oder „knapp“ (unter 70).

### Schlaf-Tab
- **C4** – Oben der Score
  Ausgangslage: Letzte Nacht ausgewertet · Handlung: Schlaf-Tab öffnen · Ergebnis: Ganz oben steht
  der Score groß in den Takt-Ziffern, dazu Einschlaf- und Aufwachzeit und die Schlafdauer.
  Darunter die drei Teile mit Wert und Balken. Darunter eine Zeile, wie sie gewichtet sind.
- **C5** – Sieben Nächte
  Ausgangslage: Mehrere Nächte ausgewertet · Handlung: Schlaf-Tab ansehen · Ergebnis: Unter dem
  Score steht eine Balkenreihe der letzten sieben Nächte mit dem Score jeder Nacht. Nächte ohne
  Score bleiben als Lücke sichtbar.
- **C6** – Der Rest bleibt
  Ausgangslage: Schlaf-Tab offen · Handlung: nach unten scrollen · Ergebnis: Hypnogramm, Vergleich
  mit den eigenen Nächten, Signale der Nacht, Schlafplan, Wecker und Körperuhr stehen wie bisher
  darunter. Nur der bisherige Kopf mit der Gesamtschlafzeit fällt weg, weil C4 ihn ersetzt.
- **C7** – Korrektur
  Ausgangslage: Schlafzeiten werden über „Zeiten ändern“ korrigiert · Handlung: speichern ·
  Ergebnis: Der Score rechnet mit den korrigierten Werten neu.

### Heute-Screen
- **C8** – Schlafring zeigt den Score
  Ausgangslage: Score berechnet · Handlung: Heute-Tab öffnen · Ergebnis: Der Schlafring zeigt den
  Score (0 bis 100) und füllt sich entsprechend, darunter steht die Schlafdauer. Ohne Score zeigt
  er wie bisher Dauer zu Bedarf. Das ändert A2 aus Feature 01 für den Schlafring.
- **C9** – Displaystreifen
  Ausgangslage: Displaystreifen eingestellt · Handlung: Schlaf-Tab ansehen · Ergebnis: Keine
  Ziffer im neuen Kopf liegt auf dem Streifen (Regel B5).

## Randfälle
- Nickerchen zählen nicht, nur die Hauptschlafphase der Nacht.
- Keine Nacht ausgewertet: Der Kopf sagt, dass das Band über Nacht getragen werden muss.
- Effizienz über 95 % zählt voll, unter 70 % mit 0.

## Nicht-Ziele
- Schlafphasen im Score. Tief- und REM-Schlaf schätzt das Band am Handgelenk nur grob.
- Ruhepuls im Score. Er zeigt Erholung, nicht Schlafqualität, und gehört zur Batterie (Feature 04).
- Hypnogramm, Vergleich und Signale im Takt-Design. Das kommt später als eigenes Feature.
- Score für vergangene Nächte über die sieben hinaus.

## Daten
Der Score wird aus den gespeicherten Schlafwerten berechnet und nicht zusätzlich gespeichert. Er
verlässt das Handy nicht.
