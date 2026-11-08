---
feature: 09-training-feinschliff
freigegeben: 2026-11-08 (Felix nach Gerätetest 0.3.1: „der Stift … ist immer noch das alte Menü“, „bei Workout nachtragen den Pulsverlauf drin haben“, „bei der Herzfrequenz drüber hovern … wie bei Whoop“, „Herzfrequenz-Erholung … 16 bpm in 60 Sekunden verstehe ich nicht“, „setz das andere schon mal um“)
---
# Spec: Training, Feinschliff nach dem Gerätetest

## Nutzer und Nutzen
Felix hat 0.3.1 am Handy getestet. Die Übersicht und das Nachtragen passen. Vier Dinge fehlen noch:
- Der Stift öffnet die alte, bunte Sportart-Liste.
- Die Pulskurve lässt sich nicht ablesen.
- Beim Nachtragen sieht man nicht, wann der Puls hoch war. Felix kennt seine Trainingszeiten nur ungefähr.
- „16 bpm in 60 s“ versteht niemand ohne Erklärung.

## Akzeptanzkriterien

### Sportart-Wahl
- **W1** – Liste im Takt-Design
  Ausgangslage: Trainingsübersicht von Heute aus offen · Handlung: Stift antippen · Ergebnis: Die
  Sportart-Wahl hat einen Takt-Kopf („sportart wählen“ mit Zurück-Pfeil). Suche, zuletzt genutzte
  Sportarten und die Gruppen sind schlichte Zeilen ohne bunte Kästchen und Symbole. Die
  Kalorien-Erklärung steht als graue Zeile.
- **W2** – Gleiche Wirkung
  Ausgangslage: Sportart-Wahl offen · Handlung: Suchen oder eine Gruppe aufklappen, Sportart
  antippen · Ergebnis: Wie bisher wird sie gespeichert, und man ist zurück auf Heute.
- **W3** – Auch ohne gespeichertes Training
  Ausgangslage: Erkennung auf Heute, die noch nicht gespeichert ist · Handlung: antippen · Ergebnis:
  Dieselbe Sportart-Wahl im Takt-Design.

### Pulskurve ablesen
- **W4** – Antippen und Wischen
  Ausgangslage: Trainingsübersicht mit Pulskurve · Handlung: Finger auf die Kurve legen und
  seitlich wischen · Ergebnis: Eine senkrechte Linie folgt dem Finger. Darüber stehen die Uhrzeit
  dieser Minute und der Puls in Punktziffern („18:42“, „168 bpm“). Nach dem Loslassen bleibt der
  Wert stehen.
- **W5** – Vor dem ersten Antippen
  Ausgangslage: Übersicht frisch offen · Ergebnis: Statt eines Werts steht klein „Kurve antippen
  oder wischen“. Für eine Minute ohne Messung steht „–“ und „keine Messung“.

### Puls beim Nachtragen
- **W6** – Kurve mit Zeitraum
  Ausgangslage: „Workout nachtragen“ oder „Zeiten ändern“ offen · Ergebnis: Unter den Zeilen zeigt
  eine Karte den Puls von 30 Minuten vor Beginn bis 30 Minuten nach Ende. Der gewählte Zeitraum
  ist hinterlegt. Ändert man Beginn oder Ende, zieht die Karte mit.
- **W7** – Ablesen und übernehmen
  Ausgangslage: Kurve beim Nachtragen · Handlung: Kurve antippen oder wischen · Ergebnis: Uhrzeit
  und Puls stehen wie bei W4. Darunter stehen zwei Knöpfe, „Beginn hier“ und „Ende hier“. Sie
  setzen die jeweilige Zeit auf diese Minute und lassen die andere stehen.
- **W8** – Keine Aufzeichnung
  Ausgangslage: Für den Zeitraum hat das Band keinen Puls · Ergebnis: Statt der Kurve steht eine
  graue Zeile: „Für diese Zeit hat das Band keinen Puls aufgezeichnet.“ Speichern geht wie bisher.

### Erholung verständlich
- **W9** – Name, Wert und Erklärung
  Ausgangslage: Trainingsübersicht mit Erholungswert · Ergebnis: Die Zeile heißt „Pulsabfall nach
  1 Min.“, der Wert ist „16 bpm“. Darunter steht grau: „So weit ist dein Puls in der ersten Minute
  nach dem Training gefallen. Mehr ist besser, über 12 gilt als normal.“

## Randfälle
- „Beginn hier“ hinter dem Ende oder „Ende hier“ vor dem Beginn: Der Zeitraum ist ungültig, der
  Grund steht wie bisher über dem Knopf, Speichern ist ausgegraut.
- Ein Zeitraum über zwölf Stunden: keine Kurve, nur die graue Zeile aus W8, damit nichts hängt.
- Ohne Takt-Haut (Aktivität-Tab) bleiben Liste, Kurve und Zeile wie bei OpenStrap.

## Nicht-Ziele
- Kein eigener Uhrzeit-Wähler. Die Android-Uhr bleibt (Felix: „können wir erstmal so lassen“).
- Die Erholungsrechnung bleibt unverändert.
- Aktivität- und Gesundheit-Tab bleiben, wie sie sind.

## Daten
Nur vorhandene Pulsdaten des Bands, nichts Neues gespeichert.
