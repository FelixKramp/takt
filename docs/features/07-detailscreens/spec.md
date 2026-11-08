---
feature: 07-detailscreens
freigegeben: offen
---
# Spec: Detailscreens von Heute im Takt-Design

## Nutzer und Nutzen
Felix' Gerätetest von 0.2.1: Die Karten und Ringe auf Heute zeigen jetzt Werte, führen aber in
die alten OpenStrap-Screens. Beim Ruhepuls steht dort zusätzlich der Live-Puls, den Heute schon
zeigt. Ziel: Was man auf Heute antippt, öffnet einen Screen im Takt-Design. Es kommen keine
neuen Daten dazu.

## Akzeptanzkriterien

### Gemeinsamer Rahmen
- **H1** – Kopf
  Ausgangslage: eine Karte oder ein Ring auf Heute · Handlung: antippen · Ergebnis: Oben steht
  ein Zurück-Pfeil mit dem Namen klein geschrieben („hrv“, „ruhepuls“, „schritte“, „strain“,
  „erholung“). Darunter folgt eine Takt-Karte mit dem Wert in großen Punktziffern und einer Zeile,
  von wann er ist („heute“, „gestern“, Wochentag).
- **H2** – Zeitraum
  Ausgangslage: HRV, Ruhepuls oder Schritte offen · Handlung: „Woche“, „Monat“ oder „Jahr“
  antippen · Ergebnis: Der Verlauf darunter zeigt diesen Zeitraum. Ein graues Band zeigt den
  üblichen Bereich, der heutige Punkt ist farbig.

### HRV, Ruhepuls, Schritte
- **H3** – HRV
  Ausgangslage: HRV-Karte antippen · Ergebnis: Kopf (H1), Verlauf (H2), drei Ziffern „niedrigster,
  üblich, höchster“ und der bisherige Abschnitt „Was sie bewegt“ als Takt-Karte. Am Ende steht ein
  Link „Alle Messwerte“.
- **H4** – Ruhepuls
  Ausgangslage: Ruhepuls-Karte antippen · Ergebnis: Er ist aufgebaut wie HRV (H3). Der Live-Puls
  fällt hier weg.
- **H5** – Schritte
  Ausgangslage: Schritte-Karte antippen · Ergebnis: Er ist aufgebaut wie HRV (H3). Dazu kommt das
  Tagesziel als Balken, das sich wie bisher ändern lässt.

### Strain
- **H6** – Strain des Tages
  Ausgangslage: Strain-Ring antippen · Ergebnis: Kopf mit dem Tageswert. Darunter eine Kurve, wie
  der Strain über den Tag gestiegen ist, mit den Aktivitäten als Markierung.
- **H7** – Zeit in Zonen
  Ausgangslage: Strain offen · Handlung: nach unten scrollen · Ergebnis: Fünf waagerechte Balken
  zeigen die Minuten je Pulszone. Daneben stehen Spitzenpuls und getragene Zeit als Ziffern. Der
  Abschnitt „Woraus er besteht“ bleibt mit seinen Inhalten.
- **H8** – Tag wechseln
  Ausgangslage: Strain offen · Handlung: Pfeile neben dem Datum · Ergebnis: Er zeigt den Vortag
  oder den nächsten Tag wie bisher.

### Erholung
- **H9** – Erholung heute
  Ausgangslage: Erholungsring antippen · Ergebnis: Kopf mit dem Wert in Prozent und dem Wort der
  Stufe (wie bisher „Startklar“, „Ruhig angehen“ …).
- **H10** – Woraus sie besteht
  Ausgangslage: Erholung offen · Ergebnis: Jeder Baustein (HRV, Ruhepuls, Schlaf …) ist eine Zeile
  wie „Gegen deine Nächte“ im Schlaf-Tab (Spec 06, F8): Wert, graues Band „üblich bei dir“ mit
  Punkt, ein kurzer Satz. Fehlt ein Baustein, sagt die Zeile, was fehlt.
- **H11** – Verlauf
  Ausgangslage: Erholung offen · Ergebnis: Die letzten 30 Tage stehen als Balken in den Farben der
  Stufen.

### Für alle
- **H12** – Streifen
  Ausgangslage: Displaystreifen eingestellt · Handlung: jeden dieser Screens durchscrollen ·
  Ergebnis: Keine Ziffer liegt auf dem Streifen (Regel B5).
- **H13** – Ohne Wert
  Ausgangslage: noch kein Wert (neues Band, Kalibrierung) · Ergebnis: Der Kopf zeigt „–“ und
  denselben Grund wie bisher. Der Verlauf zeigt, was es gibt.

## Nicht-Ziele
- Neue Berechnungen oder neue Daten.
- Die Unterscreens „Alle Messwerte“, „Erweiterte Diagramme“ und „Aufschlüsselung“ umgestalten.
- Die Batterie (Spec 04). Später wird H9 bis H11 dort zu „So entsteht die Ladung“.
- Screens, die nur aus den Tabs Aktivität und Gesundheit erreichbar sind (Feature 05).

## Daten
Nur, was die bisherigen Screens lesen. Nichts Neues gespeichert.
