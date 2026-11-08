---
feature: 08-training
freigegeben: 2026-11-08 (Felix per /goal: „wenn man das Workout in Home anklickt, dieser Screen im neuen Design, und bei Workout nachtragen auch ein neuer Screen im neuen Design“)
---
# Spec: Training und „Workout nachtragen“ im Takt-Design

## Nutzer und Nutzen
Felix' Gerätetest von 0.3.0. Tippt man auf Heute ein Training an, öffnet sich nur die Wahl der
Sportart. Die Übersicht mit Puls, Zonen und Strain gibt es nur im Aktivität-Tab, und dort im alten
OpenStrap-Design. Auch „Workout nachtragen“ ist noch alt: bunte Symbolkästchen, grüner Knopf.
Ziel: Beides sieht aus wie die Detailscreens aus Feature 07, zum Beispiel Strain. Daten und
Rechnung bleiben die von OpenStrap.

## Akzeptanzkriterien

### Training öffnen
- **T1** – Antippen öffnet die Übersicht
  Ausgangslage: Ein gespeichertes Training steht auf Heute · Handlung: antippen · Ergebnis: Die
  Übersicht dieses Trainings öffnet sich (dieselben Daten wie im Aktivität-Tab). Sie ist nicht mehr
  die Sportart-Wahl.
- **T2** – Erkennung ohne Speicherung
  Ausgangslage: Eine Erkennung, die noch nicht gespeichert werden konnte · Handlung: antippen ·
  Ergebnis: Wie bisher öffnet sich die Sportart-Wahl, denn ohne gespeichertes Training gibt es keine
  Übersicht.
- **T3** – Sportart ändern
  Ausgangslage: Übersicht offen · Handlung: Stift oben rechts, Sportart wählen · Ergebnis: Die
  Sportart ist gespeichert, man ist zurück auf Heute, und dort steht die neue Sportart.

### Übersicht im Takt-Design
- **T4** – Kopf
  Ausgangslage: Übersicht offen · Ergebnis: Oben stehen der Zurück-Pfeil und der Name klein
  geschrieben („handball“), darunter klein Tag und Uhrzeit, ganz lesbar auch bei langen Sportarten
  und schmalen Handys. Rechts stehen Stift und Teilen. Darunter folgt
  eine Takt-Karte mit dem Hauptwert in großen Punktziffern, zum Beispiel „55:00“ mit „Gesamtzeit“.
  Es gibt keinen alten großen Titel und keine 48-pt-Zahl.
- **T5** – Pulskurve
  Ausgangslage: Übersicht offen · Ergebnis: Die Herzfrequenz ist eine orange Linie wie die
  Strain-Kurve, nicht mehr rosa.
- **T6** – Messwerte
  Ausgangslage: Übersicht offen · Ergebnis: Ø Puls, Max. Puls, Erholung nach 60 s, Kalorien und
  Strain sind Zeilen mit dem Namen links und dem Wert in Punktziffern rechts. Die runden Symbole
  entfallen. Jede Zahl weicht dem Displaystreifen aus.
- **T7** – Rest wie bisher
  Ausgangslage: Übersicht offen · Ergebnis: Die Reiter (Übersicht, Grafiken, bei manchen Sportarten
  Abschnitte), die Zonen und die Fußnote bleiben mit ihren Inhalten, in den flachen Takt-Karten.

### Workout nachtragen
- **T8** – Kopf und Zeilen
  Ausgangslage: Heute · Handlung: „Workout nachtragen“ · Ergebnis: Oben stehen der Zurück-Pfeil und
  „training nachtragen“. Darunter kommen Aktivität, Datum, Beginn, Ende und Dauer als schlichte
  Zeilen ohne bunte Symbolkästchen. Uhrzeiten und Dauer stehen in Punktziffern. Alles lässt sich wie
  bisher antippen und ändern.
- **T9** – Hinweis und Knopf
  Ausgangslage: Nachtragen offen · Ergebnis: Der Satz, woraus Strain und Kalorien kommen, steht als
  graue Zeile. Der Knopf „Speichern“ ist flach und orange wie „Workout nachtragen“ auf Heute.
  Bei einem ungültigen Zeitraum ist er ausgegraut, und der Grund steht darüber.
- **T10** – Sportart-Liste
  Ausgangslage: Nachtragen offen · Handlung: Aktivität antippen · Ergebnis: Die Liste zum Suchen
  öffnet sich im Takt-Design, ohne bunte Kästchen.
- **T11** – Speichern
  Ausgangslage: Nachtragen mit gültigem Zeitraum · Handlung: Speichern · Ergebnis: Wie bisher wird
  das Training gespeichert, der Screen schließt sich, und es steht auf Heute.

## Randfälle
- Training ohne Pulsaufzeichnung: Die Übersicht zeigt wie bisher den Hinweis ohne Kurve, im
  Takt-Design.
- Ein Training, das sich nicht laden lässt (gelöscht, Lesefehler): Antippen öffnet die
  Sportart-Wahl wie bisher, nichts stürzt ab.

## Nicht-Ziele
- Der Aktivität-Tab, das Live-Training und das Teilen-Bild bleiben im OpenStrap-Design.
- Keine neuen Werte, keine andere Rechnung.

## Änderungen
2026-11-08 · T4 · Prüfung: In der Mitte wurden Tag und Uhrzeit bei langen Sportarten und auf 360-px-Handys abgeschnitten. Sie stehen jetzt unter dem Namen.
2026-11-08 · T6 · Feature 09, W9: Die Zeile „Erholung nach 60 s“ heißt jetzt „Pulsabfall nach 1 Min.“, mit Erklärung darunter.
