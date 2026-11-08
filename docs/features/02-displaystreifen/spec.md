---
feature: 02-displaystreifen
freigegeben: offen
---
# Spec: Displaystreifen

## Nutzer und Nutzen
Felix' Handy hat einen Displayfehler: Ein weißer senkrechter Strich läuft im rechten Drittel von
oben nach unten über den Bildschirm. In Takt 0.1.2 verdeckt er in der Schritte-Karte die erste
Ziffer, aus 1468 wird „468". Takt soll Zahlen so setzen, dass der Strich keine Ziffer verdeckt.
Für alle anderen Nutzer ist die Einstellung aus und ändert nichts.

## Akzeptanzkriterien

- **B1** – Streifen einstellen
  Ausgangslage: Einstellungen offen · Handlung: „Displaystreifen" öffnen, eine farbige senkrechte
  Linie per Schieberegler auf den weißen Strich schieben, speichern · Ergebnis: Die Position bleibt
  gespeichert, auch nach einem Neustart der App. „Entfernen" schaltet die Funktion wieder aus.
- **B2** – Zahlen weichen aus
  Ausgangslage: Streifen gesetzt · Handlung: Heute-Tab ansehen · Ergebnis: Keine Ziffer in den
  Ringen, im Live-Puls, in den drei Karten und in der Aktivitätsliste liegt auf dem Streifen. Jede
  Zahl rückt innerhalb ihres Platzes ganz nach links oder ganz nach rechts vom Streifen.
- **B3** – Kein Platz zum Ausweichen
  Ausgangslage: Streifen gesetzt, eine Zahl passt auf keiner Seite des Streifens in ihren Platz ·
  Handlung: Heute-Tab ansehen · Ergebnis: Die Zahl wird so weit verkleinert, dass sie auf die
  größere Seite passt. Sie wird nie abgeschnitten und nie verdeckt.
- **B4** – Aus heißt unverändert
  Ausgangslage: Kein Streifen eingestellt · Handlung: Heute-Tab ansehen · Ergebnis: Alles steht
  genau wie in Version 0.1.2.
- **B5** – Designregel für neue Screens
  Ausgangslage: Ein weiterer Screen wird ins Takt-Design übertragen · Handlung: Zahlen setzen ·
  Ergebnis: Jede Zahl im Takt-Design läuft über dieselbe Ausweich-Komponente, sodass B2 und B3 dort
  ohne Zusatzarbeit gelten.

## Randfälle
- Querformat: Der Streifen sitzt dann an einer anderen Stelle. Takt rechnet die Position nur im
  Hochformat um und weicht im Querformat nicht aus.
- Schriftgröße des Systems vergrößert: B2 und B3 gelten weiter.

## Nicht-Ziele
- Fließtext und Beschriftungen weichen nicht aus. Ein verdeckter Buchstabe lässt sich aus dem Wort
  erraten, eine verdeckte Ziffer nicht.
- Waagerechte Streifen und mehrere Streifen.
- Upstream-Screens, die noch nicht im Takt-Design sind. Sie bekommen B2 mit ihrer Umstellung (B5).

## Daten
Nur eine Zahl auf dem Gerät: die Position des Streifens als Anteil der Bildschirmbreite. Sie
verlässt das Handy nicht.
