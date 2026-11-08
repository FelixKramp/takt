---
feature: 03-schlafscore
freigegeben: 2026-11-08
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
  Entwurf: [Canvas, Board „A+“](https://claude.ai/artifact/2WBkgmZ3R9En5JE1mm6mSS).
- **C5** – Sieben Nächte
  Ausgangslage: Mehrere Nächte ausgewertet · Handlung: Schlaf-Tab ansehen · Ergebnis: Unter dem
  Score steht eine Balkenreihe der letzten sieben Nächte mit dem Score jeder Nacht. Nächte ohne
  Score bleiben als Lücke sichtbar.
- **C6** – Dauer und Bedarf
  Ausgangslage: Bedarf berechnet · Handlung: unter die sieben Nächte scrollen · Ergebnis: Zwei
  Balken zeigen Geschlafen gegen Bedarf. Darunter steht, woraus sich der Bedarf zusammensetzt:
  Grundbedarf, Zuschlag für die Belastung des Tages, Schlafschuld, abzüglich Nickerchen. Teile ohne
  Wert fallen weg.
- **C7** – Regelmäßigkeit
  Ausgangslage: Mehrere Nächte ausgewertet · Handlung: weiter scrollen · Ergebnis: Ein Diagramm
  zeigt für die letzten sechs Nächte je einen Balken von der Einschlaf- bis zur Aufwachzeit.
  Gestrichelte Linien zeigen die empfohlene Bett- und Aufstehzeit, für jeden Tag die Empfehlung,
  die OpenStrap an diesem Tag berechnet hat. Darüber steht der Regelmäßigkeitswert, darunter die
  Empfehlung für heute Nacht. Tage ohne gespeicherte Empfehlung lassen die Linie dort aus.
- **C8** – Effizienz
  Ausgangslage: Letzte Nacht ausgewertet · Handlung: weiter scrollen · Ergebnis: Der Anteil der
  Zeit im Bett, in der geschlafen wurde. Darunter zwei Streifen über die Nacht, oben geschlafen,
  unten die Wachphasen. Dazu die Wachzeit und die Zahl der Aufwachereignisse.
- **C9** – Der Rest bleibt
  Ausgangslage: Schlaf-Tab offen · Handlung: ganz nach unten scrollen · Ergebnis: Hypnogramm,
  Vergleich mit den eigenen Nächten, Signale der Nacht, Schlafplan, Wecker und Körperuhr stehen wie
  bisher darunter. Der bisherige Kopf mit der Gesamtschlafzeit fällt weg, weil C4 ihn ersetzt.
- **C10** – Korrektur
  Ausgangslage: Schlafzeiten werden über „Zeiten ändern“ korrigiert · Handlung: speichern ·
  Ergebnis: Der Score rechnet mit den korrigierten Werten neu.

### Heute-Screen
- **C11** – Schlafring zeigt den Score
  Ausgangslage: Score berechnet · Handlung: Heute-Tab öffnen · Ergebnis: Der Schlafring zeigt den
  Score (0 bis 100) und füllt sich entsprechend, darunter steht die Schlafdauer. Ohne Score zeigt
  er wie bisher Dauer zu Bedarf. Das ändert A2 aus Feature 01 für den Schlafring.
- **C12** – Farbe nach Score
  Ausgangslage: Score berechnet · Handlung: Schlaf-Tab und Heute-Tab ansehen · Ergebnis: Ring,
  Balken, die markierte Nacht und der Schlaf-Tab in der Leiste tragen die Farbe der Stufe: gut
  Blau, okay Takt-Orange, knapp Rot. Als Text dunklere Töne, damit sie lesbar bleiben. Das Wort
  „gut", „okay" oder „knapp" steht immer dabei, die Farbe ist nie die einzige Information.
- **C13** – Displaystreifen
  Ausgangslage: Displaystreifen eingestellt · Handlung: Schlaf-Tab ansehen · Ergebnis: Keine
  Ziffer im neuen Schlaf-Tab liegt auf dem Streifen (Regel B5).

## Randfälle
- Nickerchen zählen nicht, nur die Hauptschlafphase der Nacht.
- Keine Nacht ausgewertet: Der Kopf sagt, dass das Band über Nacht getragen werden muss.
- Effizienz über 95 % zählt voll, unter 70 % mit 0.

## Nicht-Ziele
- Schlafphasen im Score. Tief- und REM-Schlaf schätzt das Band am Handgelenk nur grob.
- Ruhepuls im Score. Er zeigt Erholung, nicht Schlafqualität, und gehört zur Batterie (Feature 04).
- Hypnogramm, Vergleich und Signale im Takt-Design. Das kommt später als eigenes Feature.
- Optik oder Begriffe von WHOOP kopieren. Übernommen werden nur die Inhalte (Bedarf, Regelmäßigkeit,
  Effizienz), gezeichnet im Takt-Design.
- Score für vergangene Nächte über die sieben hinaus.

## Daten
Der Score wird aus den gespeicherten Schlafwerten berechnet und nicht zusätzlich gespeichert. Er
verlässt das Handy nicht.
