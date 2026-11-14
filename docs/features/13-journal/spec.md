---
feature: 13-journal
freigegeben: 2026-11-12
---
# Spec: Journal im Takt-Design mit Morgenblatt und Auswertung

## Nutzer und Nutzen
Felix will jeden Morgen in unter einer Minute festhalten, was am Vortag war (Vitamin D, gelesen,
Fleisch gegessen, Selbstbefriedigung) und wie er sich heute fühlt, und eigene Ja/Nein-Fragen
anlegen, was WHOOP nicht kann. Der Sinn dahinter: sehen, **welche Gewohnheit ihm gut tut und was er
lieber lassen sollte**, gemessen an der Batterie am Morgen danach (dazu HRV, Ruhepuls,
Schlafeffizienz). Alle Antworten bleiben auf seinem Gerät.

Das Journal gibt es in der App schon (Stimmung, Energie, Mengen, feste Tags) und eine Rechnung, die
Tage mit und ohne Gewohnheit vergleicht und Zufallstreffer herausrechnet. Dieses Feature zieht das
Journal in die Takt-Haut, ergänzt Ja/Nein-Fragen und eine 4-stufige Skala, macht daraus ein kurzes
Blatt, das morgens von selbst kommt, und zeigt das Ergebnis der Rechnung im Takt-Stil.

## Akzeptanzkriterien

### Morgenblatt
- **J1** – Blatt kommt von selbst
  Ausgangslage: Es ist nach 5 Uhr (oder die Nacht ist schon berechnet), für diesen Kalendertag
  wurde das Blatt noch nicht beantwortet oder weggewischt · Handlung: App öffnen oder zurückholen · Ergebnis: Von unten schiebt sich ein Blatt im Takt-Design mit den Morgenfragen.
  Der volle Journal-Bildschirm öffnet sich nicht.
- **J2** – Fragen zu gestern
  Ausgangslage: Blatt offen · Handlung: ansehen · Ergebnis: Unter der Überschrift „Gestern“ (mit
  Tag, etwa „Mi 11.11.“) stehen die Ja/Nein-Fragen „Vitamin D genommen“, „Gelesen“, „Fleisch
  gegessen“ und „Private Frage“, je mit zwei Tasten Ja und Nein.
- **J3** – Frage zu heute
  Ausgangslage: Blatt offen · Handlung: ansehen · Ergebnis: Unter „Heute“ steht „Wie fühlst du
  dich?“ mit vier Stufen: schlecht, geht so, gut, sehr gut, als vier Punkte nebeneinander.
- **J4** – Ein Tipp pro Antwort
  Ausgangslage: Blatt offen · Handlung: bei jeder Frage eine Antwort antippen · Ergebnis: Die Antwort
  ist markiert, ein zweiter Tipp auf dieselbe Antwort nimmt sie zurück. Es gibt kein Textfeld im
  Blatt.
- **J5** – Speichern
  Ausgangslage: Mindestens eine Antwort gegeben · Handlung: „Fertig“ tippen · Ergebnis: Das Blatt
  schließt. Gestern-Antworten stehen im Journal von gestern, die Antwort zu heute im Journal von
  heute.
- **J6** – Unbeantwortet bleibt unbeantwortet
  Ausgangslage: Nur ein Teil der Fragen beantwortet · Handlung: „Fertig“ · Ergebnis: Nur das
  Beantwortete wird gespeichert. Eine nicht beantwortete Frage gilt nie als „Nein“.
- **J7** – Wegwischen
  Ausgangslage: Blatt offen · Handlung: Blatt wegwischen oder „Später“ tippen · Ergebnis: Nichts wird
  gespeichert, das Blatt kommt an diesem Tag nicht wieder. Am nächsten Morgen kommt es wieder. Über
  einen Link „Journal öffnen“ im Blatt und aus Heute bleibt der volle Bildschirm erreichbar.
- **J8** – Schon beantwortet
  Ausgangslage: Alle Fragen des Blatts sind für diesen Tag im Journal beantwortet · Handlung:
  Heute-Tab öffnen · Ergebnis: Das Blatt kommt nicht. Ist nur ein Teil beantwortet, kommt es mit den
  vorbefüllten Antworten.

### Eigene Fragen
- **J9** – Eigene Ja/Nein-Frage anlegen
  Ausgangslage: Journal-Bildschirm offen · Handlung: „Eigene Frage“ wählen, Name eingeben, wählen,
  ob sie sich auf gestern oder heute bezieht, speichern · Ergebnis: Die Frage steht im Journal und
  im Morgenblatt, in dem Abschnitt, den Felix gewählt hat. Sie kann ohne weiteres Zutun ausgewertet
  werden (J12).
- **J10** – Anzeigename für jede Frage
  Ausgangslage: Beliebige Frage, eigene oder eingebaute · Handlung: einen Anzeigenamen eintragen ·
  Ergebnis: Im Blatt und im Journal steht der Anzeigename. Gezählt und ausgewertet wird unter der
  Frage selbst, ein Anzeigename ändert keine Antworten.
- **J11** – Ein-/Ausschalten, Umbenennen, Löschen
  Ausgangslage: Frage mit Antworten · Handlung: „im Morgenblatt zeigen“ ausschalten, umbenennen oder
  löschen · Ergebnis: Ausschalten nimmt die Frage ab dem nächsten Morgen aus dem Blatt, sie bleibt im
  Journal. Umbenennen lässt alle bisherigen Antworten zum neuen Namen gehören. Löschen blendet die
  Frage aus, die Antworten bleiben gespeichert und lassen sich wieder einblenden.

### Auswertung „Was tut mir gut“
- **J12** – Wirkung je Gewohnheit
  Ausgangslage: Eine Ja/Nein-Frage hat an mindestens 5 Tagen Ja und an mindestens 5 Tagen Nein
  beantwortet, jeweils mit gemessener Nacht danach · Handlung: in Gesundheit den Tab „Journal“
  öffnen · Ergebnis: Pro Gewohnheit steht eine Zeile mit der Batterie am Morgen danach: Durchschnitt
  bei Ja gegen Durchschnitt bei Nein, die Differenz in Prozentpunkten und die Zahl der Tage je Seite.
  Darunter kleiner dieselbe Gegenüberstellung für HRV, Ruhepuls und Schlafeffizienz.
- **J13** – Zu wenig Tage
  Ausgangslage: Eine Frage hat weniger als 5 Ja-Tage oder weniger als 5 Nein-Tage · Handlung:
  in Gesundheit den Tab „Journal“ öffnen · Ergebnis: Statt Zahlen steht der Zählstand („Ja 3 von 5, Nein 8 von
  5“). Es gibt keinen Durchschnitt und keine Differenz.
- **J14** – Nur Belastbares heißt „hilft“ oder „kostet“
  Ausgangslage: Eine Frage erfüllt J12 · Handlung: Tab „Journal“ öffnen · Ergebnis: „Hilft“ oder
  „Kostet“ steht nur dort, wo die Rechnung der App den Unterschied als belastbar einstuft (sie rechnet
  Zufall heraus). Sonst steht „Kein Unterschied erkennbar“. Die Texte sagen „geht zusammen mit“,
  nie „verursacht“, und nennen, dass an einem Tag viele Dinge zusammenkommen.
- **J15** – Reihenfolge
  Ausgangslage: Mehrere Fragen ausgewertet · Handlung: ansehen · Ergebnis: Oben „Hilft“, nach Größe
  der Differenz geordnet, dann „Kostet“, dann „Kein Unterschied erkennbar“, dann „Zu wenig Tage“.
- **J16** – Zeitbezug
  Ausgangslage: Eine Gewohnheit ist für den Tag D beantwortet · Handlung: Auswertung öffnen ·
  Ergebnis: Sie wird mit der Batterie am Morgen **nach** der Nacht auf D verglichen, also mit der
  Ladung des Tages D+1, nicht mit der Ladung desselben Morgens.
- **J17** – Nur eigene Nächte
  Ausgangslage: Tage aus dem WHOOP-Import und Tage ohne gemessene Nacht · Handlung: Auswertung
  öffnen · Ergebnis: Diese Tage zählen in der Auswertung nicht mit, auch nicht für den Zählstand
  aus J13.

### Tab „Journal“ in Gesundheit
- **J26** – Tab-Leiste in Gesundheit
  Ausgangslage: Gesundheit-Tab in der Takt-Haut · Handlung: ansehen · Ergebnis: Die Tab-Leiste hat
  drei Tabs: Übersicht, Vitalwerte, Journal. „Erkunden“ und „Labore“ stehen nicht mehr darin. Sie
  sind nicht gelöscht, nur in der Takt-Haut nicht erreichbar, wie der Aktivität-Tab.
- **J27** – Inhalt des Tabs
  Ausgangslage: Tab „Journal“ offen · Handlung: ansehen · Ergebnis: Ganz oben „Heute eintragen“ (öffnet
  den vollen Journal-Bildschirm), darunter die Auswertung „Was tut mir gut“ (J12 bis J17), darunter die
  Fragen mit Anzeigename, Ein-/Ausschalten und „Eigene Frage“ (J9 bis J11).

### Takt-Design
- **J18** – Journal-Bildschirm in der Takt-Haut
  Ausgangslage: Journal-Bildschirm offen · Handlung: ansehen · Ergebnis: Karten, Ziffern und Knöpfe
  stehen im Takt-Stil wie die anderen Bildschirme. Keine rohen Farben, Texte über TaktText oder
  .arb.
- **J19** – Displaystreifen
  Ausgangslage: Displaystreifen eingestellt · Handlung: Blatt, Journal-Bildschirm und Tab „Journal“
  ansehen · Ergebnis: Keine Ziffer liegt auf dem Streifen (Regel B5).

### Privat
- **J20** – Privates bleibt auf dem Gerät
  Ausgangslage: Die Frage „Private Frage“ (und jede Frage, die Felix als privat markiert) hat
  Antworten · Handlung: CSV-Export, KI-Journal-Chat und Benachrichtigungen nutzen · Ergebnis: Private
  Antworten tauchen dort nirgends auf. Privat ist für „Private Frage“ von Anfang an eingeschaltet, für
  eigene Fragen eine Wahl. In der Auswertung in der App steht sie wie die anderen, unter ihrem
  Anzeigenamen.

### Morgenbriefing-Link (Nachtrag 2026-11-13)
- **J28** – Link einrichten
  Ausgangslage: Journal-Tab offen, noch kein Link gespeichert · Handlung: „Morgenbriefing-Link
  einrichten“ antippen, einen Google-Drive-Link einfügen, speichern · Ergebnis: Der Link ist
  gespeichert. Angenommen werden nur https-Links auf drive.google.com. Alles andere zeigt „Das ist kein
  Google-Drive-Link“ und speichert nichts. Der Link steht nur auf dem Gerät.
- **J29** – Anhören im Journal-Tab
  Ausgangslage: Link gespeichert · Handlung: Tab „Journal“ öffnen, „Morgenbriefing anhören“ antippen ·
  Ergebnis: Die Zeile steht ganz oben unter „Heute eintragen“. Ein Tipp öffnet den Link außerhalb der
  App (Drive). Daneben ein Stift zum Ändern oder Entfernen des Links.
- **J30** – Anhören im Morgenblatt
  Ausgangslage: Link gespeichert, Morgenblatt offen · Handlung: „Morgenbriefing anhören“ antippen ·
  Ergebnis: Die Zeile steht im Kopf des Blatts, das Blatt bleibt offen und behält die Antworten.
  Ohne Link erscheint die Zeile im Blatt nicht (kein Hinweis, keine Lücke).
- **J31** – Link lässt sich nicht öffnen
  Ausgangslage: Link gespeichert, kein Drive und kein Browser erreichbar · Handlung: antippen ·
  Ergebnis: Meldung „Link konnte nicht geöffnet werden“. Kein Absturz, Antworten im Blatt bleiben.
- **J32** – Link bleibt privat
  Ausgangslage: Link gespeichert · Handlung: CSV-Export, Fehlerbericht und KI-Journal-Chat nutzen ·
  Ergebnis: Der Link taucht dort nirgends auf.

## Randfälle
- **J21** – Kein Band, Nacht nicht berechnet
  Ausgangslage: Es gibt (noch) keine berechnete Nacht · Handlung: App nach 5 Uhr öffnen · Ergebnis:
  Das Blatt kommt sofort, ohne auf die Berechnung zu warten, einmal pro Tag.
- **J22** – Nach Mitternacht
  Ausgangslage: Es ist 01:00 Uhr, keine fertige Nacht · Handlung: App öffnen ·
  Ergebnis: Das Blatt kommt nicht. „Gestern“ im Blatt ist immer der Kalendertag vor heute.
- **J23** – Speichern scheitert
  Ausgangslage: Schreiben in die Datenbank schlägt fehl · Handlung: „Fertig“ · Ergebnis: Eine
  Fehlermeldung mit „Nochmal“, das Blatt bleibt offen, die Antworten gehen nicht verloren.
- **J24** – Enges Display, große Schrift
  Ausgangslage: Display 320 px breit, Schrift 2,0, Deutsch und Englisch · Handlung: Blatt, Journal-
  Bildschirm und Tab „Journal“ ansehen · Ergebnis: Nichts läuft über, nichts wird abgeschnitten, alle
  Tasten bleiben mindestens so groß wie die übrigen Tasten der App. Die Prüfung läuft mit deutschen
  Texten und deutschen Dauern, nicht mit Kurzformen.
- **J25** – Neustart
  Ausgangslage: Blatt wurde beantwortet, App wird neu gestartet · Handlung: Heute-Tab öffnen ·
  Ergebnis: Das Blatt kommt nicht wieder (J8).

## Nicht-Ziele
- Keine Ursachenaussage und keine Wechselwirkung zwischen zwei Gewohnheiten, nur der Vergleich
  einer Gewohnheit mit Ja gegen Nein.
- Keine Auswertung des Gefühls (J3) und keine gegen Strain. Das Gefühl wird erfasst, nicht
  ausgewertet.
- Keine Erinnerung per Benachrichtigung. Das Blatt kommt nur beim Öffnen von Heute.
- Keine Zahlenfragen, kein Freitext und keine Uhrzeiten im Blatt. Die gibt es weiter im vollen
  Journal-Bildschirm.
- Kein Mehrfach-Eintrag pro Tag.
- Kein eigener Player für das Morgenbriefing in der App. Nur der Link nach Google Drive.
- Die Datei `Heute.m4a` legt die Briefing-Automatik an (briefing.py), nicht die App. Die App kennt nur den Link.

## Entscheidungen
- Blatt statt Vollbild — weil es unter einer Minute dauern soll.
- Vitamin D, Gelesen, Fleisch und Private Frage beziehen sich auf gestern, das Gefühl auf heute —
  Felix: Die Ja/Nein-Fragen betreffen immer den letzten Tag.
- Vier Stufen beim Gefühl — Felix' Wunsch.
- Eigene Fragen sind Ja/Nein — weil Felix freie Gewohnheiten tracken will und die App dafür bisher nur
  Mengen und Stufen kennt.
- Anzeigename für jede Frage — Felix: „für alles“.
- Auswertung gegen die Batterie am Morgen danach, mit der vorhandenen Rechnung der App — weil das der
  Sinn des Journals ist (bei WHOOP die Erholung) und die Rechnung Zufallstreffer schon herausrechnet.
- Mindestens 5 Ja-Tage und 5 Nein-Tage, bevor Zahlen erscheinen — weil mit zwei oder drei Tagen jeder
  Unterschied Zufall sein kann. Felix hat 5 und 5 bestätigt.
- Auswertung als neuer Tab „Journal“ in Gesundheit; Erkunden und Labore fallen aus der Takt-Leiste —
  Felix' Wunsch, weil er beide nicht braucht.

## Offene Fragen
- Keine.

## Änderungen
<!-- Nur über den Änderungsweg. Format: Datum · welche Kriterien · warum -->
- 2026-11-13 · J28–J32 neu · Felix will das Morgenbriefing aus Google Drive direkt im Journal anhören; ein Link reicht, kein eigener Player. Freigabe: 2026-11-13 („Ja, fang an“).
- 2026-11-14 · J1, J21, J22 · Gerätetest: Das Blatt kam morgens nicht. Ohne berechnete Nacht bleibt der Vortag bis 12 Uhr aktiv, J1 verlangte den Kalendertag. Neu: ab 5 Uhr beim ersten Öffnen der App, ohne auf die Berechnung zu warten, wie bei WHOOP. Felix' Auftrag per /goal.
- 2026-11-14 · J13 · Einträge, deren Nacht danach noch nicht gemessen ist, stehen als „wartet auf die Nacht danach“ da, damit ein Eintrag nicht verschwunden wirkt.
- 2026-11-14 · J13, J17 · Gerätetest auf dem Pixel: Readiness ist während der 14 Nächte Kalibrierung leer, deshalb zählte kein einziger Eintrag („Ja 0 von 5“). „Gemessene Nacht“ heißt jetzt: Readiness, HRV, Ruhepuls oder Effizienz liegt für D+1 vor. Der Vergleich der Batterie (J12, J16) erscheint erst, wenn es auf beiden Seiten Readiness gibt; bis dahin vergleicht die Karte die übrigen Werte.
