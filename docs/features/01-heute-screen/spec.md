---
feature: 01-heute-screen
freigegeben: 2026-11-06
---
# Spec: Heute-Screen

## Nutzer und Nutzen
Felix trägt ein WHOOP 5.0 und nutzt OpenStrap Edge auf Android. Er will beim Öffnen sofort sehen,
wie es ihm geht, wie sein Puls gerade ist und was er heute gemacht hat, ohne erst in einen anderen
Tab zu gehen. Takt ist ein dünner Fork von OpenStrap Edge: gleiche Bluetooth-Anbindung und gleiche
Algorithmen, aber ein neuer Heute-Screen, eigener Name und eigenes Logo.

## Akzeptanzkriterien

### Aufbau
- **A1** – Reihenfolge
  Ausgangslage: Band verbunden, Daten vorhanden · Handlung: App öffnen · Ergebnis: Der Heute-Tab
  zeigt von oben nach unten die drei Ringe, den Live-Puls, die Karten, die Aktivitäten. Ringe und
  Puls sind ohne Scrollen sichtbar.
- **A2** – Drei Ringe
  Ausgangslage: Erholung, Strain und Schlaf sind berechnet · Handlung: Heute-Tab ansehen ·
  Ergebnis: Jeder Ring zeigt seinen Wert mit den Zahlen aus den OpenStrap-Algorithmen.
- **A3** – Ringe führen weiter
  Ausgangslage: Heute-Tab offen · Handlung: Ring antippen · Ergebnis: Der bestehende Detail-Screen
  für Erholung, Strain oder Schlaf öffnet sich.
- **A4** – Karten
  Ausgangslage: Heute-Tab offen · Handlung: Karte antippen · Ergebnis: Unter dem Puls stehen genau
  drei Karten (HRV, Ruhepuls, Schritte), jede öffnet ihren Detail-Screen.
- **A5** – Aufgeräumt
  Ausgangslage: OpenStrap zeigte auf Heute weitere Karten (Plan, Hinweise, Wecker und andere) ·
  Handlung: Heute-Tab und Gesundheit-Tab ansehen · Ergebnis: Auf Heute stehen sie nicht mehr, im
  Gesundheit-Tab sind sie erreichbar. Die Krankheitswarnung bleibt auf Heute, aber nur, wenn sie
  anschlägt.

### Live-Puls
- **A6** – Puls beim Öffnen
  Ausgangslage: Band angelegt und verbunden · Handlung: App öffnen · Ergebnis: Innerhalb von
  5 Sekunden steht der aktuelle Puls da und aktualisiert sich laufend, darunter oder daneben eine
  Verlaufslinie der letzten Messwerte.
- **A7** – Puls stoppt beim Verlassen
  Ausgangslage: Puls läuft · Handlung: Heute-Tab verlassen oder App in den Hintergrund legen ·
  Ergebnis: Der Live-Datenstrom wird beendet, damit kein Akku verschwendet wird.

### Aktivitäten
- **A8** – Erkannte Workouts sofort sichtbar
  Ausgangslage: Die App hat heute ein Workout erkannt · Handlung: Heute-Tab ansehen · Ergebnis: Es
  steht ohne Bestätigung in der Liste, mit Startzeit, Dauer, Durchschnittspuls und der Markierung
  „erkannt". Ohne gewählte Sportart heißt es „Training". Reichen die Daten 30 Minuten über sein Ende
  hinaus, wird es gespeichert und zeigt auch seinen Strain. Ein laufendes Training wird dabei nie
  abgeschnitten.
- **A9** – Erkanntes ändern oder löschen
  Ausgangslage: Ein erkanntes Workout steht in der Liste · Handlung: Antippen und Sportart wählen,
  auch Handball, oder verwerfen · Ergebnis: Die Änderung gilt sofort, ein verworfenes Workout verschwindet und kommt
  nicht wieder.
- **A10** – Alle Aktivitäten in einer Liste
  Ausgangslage: Es gibt erkannte, selbst gestartete und nachgetragene Workouts · Handlung:
  Heute-Tab ansehen · Ergebnis: Alle stehen in derselben Liste, das neueste oben.
- **A11** – Workout nachtragen
  Ausgangslage: Ein Training wurde nicht erkannt · Handlung: „Workout nachtragen" antippen, Art und
  Zeit angeben · Ergebnis: Das Workout steht danach in der Liste.

### Direkt verarbeitet
- **A12** – Sync beim Öffnen
  Ausgangslage: Band in Reichweite, neue Daten liegen auf dem Band · Handlung: App öffnen ·
  Ergebnis: Die App synchronisiert von selbst, Ringe, Karten und Aktivitäten aktualisieren sich
  ohne Herunterziehen.
- **A13** – Frische sichtbar
  Ausgangslage: Heute-Tab offen · Handlung: oben nachsehen · Ergebnis: Dort steht, wie alt die
  Daten sind, zum Beispiel „vor 2 Min", und während eines Syncs ein Hinweis darauf.
- **A14** – Im Hintergrund
  Ausgangslage: App im Hintergrund, Band verbunden · Handlung: nach mindestens einer Stunde die App
  öffnen · Ergebnis: Die Werte sind schon beim Öffnen höchstens 30 Minuten alt.

### Eigene App
- **A15** – Eigene Identität
  Ausgangslage: Takt ist installiert · Handlung: App-Liste und Einstellungen ansehen · Ergebnis:
  Name, Logo und App-Icon sind Takt, nirgends steht OpenStrap als Name dieser App. Takt lässt sich
  neben OpenStrap Edge installieren.
- **A16** – Herkunft und Quellcode
  Ausgangslage: Takt ist installiert · Handlung: „Über diese App" öffnen · Ergebnis: Dort steht
  „basiert auf OpenStrap" mit Link, die Lizenz AGPL-3.0 und ein Link zum Quellcode von Takt.
- **A17** – Daten mitnehmen
  Ausgangslage: OpenStrap Edge hat mehrere Nächte gespeichert · Handlung: Datenbank in Edge
  exportieren und in Takt importieren · Ergebnis: Takt zeigt den Verlauf, und die bisherigen Nächte
  zählen für die Kalibrierung.

- **A25** – Update-Hinweis
  Ausgangslage: Auf GitHub gibt es ein neueres Release von Takt · Handlung: Einstellungen öffnen ·
  Ergebnis: Dort steht „Neue Version verfügbar" mit Link zum Release. Die App fragt höchstens einmal
  am Tag nach, sendet dabei keine Gesundheitsdaten und zeigt nie Updates von OpenStrap Edge an.

## Randfälle
- **A18** – Band nicht verbunden oder nicht angelegt
  Ausgangslage: Es gibt einen letzten Messwert, aber keine Live-Daten · Handlung: Heute-Tab ansehen
  · Ergebnis: Der letzte Wert steht grau mit Uhrzeit da, daneben der Grund, zum Beispiel „Band
  nicht verbunden". Der Bereich ändert seine Höhe nicht.
- **A19** – Noch nie gemessen
  Ausgangslage: Frische Installation ohne Band · Handlung: App öffnen · Ergebnis: Keine Zahl, stattdessen
  ein Hinweis und ein Weg zum Koppeln.
- **A20** – Noch in Kalibrierung
  Ausgangslage: Weniger als 14 Nächte · Handlung: Heute-Tab ansehen · Ergebnis: Der Erholungsring
  zeigt den Fortschritt, zum Beispiel „6 von 14 Nächten", und keinen erfundenen Wert. Solange kein
  Schlafbedarf berechnet ist, zeigt der Schlafring die Stunden ohne Füllstand.
- **A21** – Keine Aktivitäten
  Ausgangslage: Heute nichts erkannt oder eingetragen · Handlung: Heute-Tab ansehen · Ergebnis: Ein
  kurzer Hinweis und der Knopf „Workout nachtragen".
- **A22** – Viele Aktivitäten
  Ausgangslage: Mehr als fünf Aktivitäten heute · Handlung: Heute-Tab ansehen · Ergebnis: Die
  neuesten fünf stehen da, dazu ein Eintrag, der alle zeigt.
- **A23** – Laufendes Workout
  Ausgangslage: Ein selbst gestartetes Workout läuft · Handlung: Heute-Tab öffnen · Ergebnis: Der
  Live-Puls läuft weiter, ein Hinweis zeigt das Workout und führt zurück hinein.
- **A24** – Große Schrift
  Ausgangslage: Systemschrift auf 200 % · Handlung: Heute-Tab ansehen · Ergebnis: Nichts wird
  abgeschnitten oder überlagert.

## Nicht-Ziele
- Die Batterie, die über den Tag leerläuft (Feature 2).
- Neugestaltung von Schlaf, Aktivität und Gesundheit über das hinaus, was A5 braucht.
- Änderungen an Algorithmen und Bluetooth-Protokoll (bleiben bei OpenStrap).
- Früheres Freischalten von Erholung oder Schlafscore.
- iOS-Build, Play Store, Website.

## Entscheidungen
- Dünner Fork — Updates von OpenStrap sollen weiter einfließen, Felix pflegt nur die Oberfläche.
- Nur Heute-Screen im ersten Feature — kleinster sichtbarer Schnitt.
- Ringe zuerst, dann Puls — Felix' Wunsch nach den ersten Entwürfen.
- Erkannte Workouts ohne Bestätigung — Felix will sein Training ohne Klick sehen, Fehlerkennungen
  fliegen mit einem Tipp raus.
- Design Pult (Hardware-Anmutung: Ringe als Drehregler, Puls auf einem Display) — passt zu Felix' TP-7 und zur Musik, sieht nach keiner anderen Tracker-App aus.
- Name Takt als Arbeitsname — Namenskonflikte werden vor dem ersten öffentlichen Release geprüft.
- Öffentliches Repo ohne Ankündigung, APK erst nach einer Woche Eigennutzung — hält den Einsatz
  klein, bis die App sich bewährt hat.

## Offene Fragen
—

## Änderungen
<!-- Nur über den Änderungsweg. Format: Datum · welche Kriterien · warum -->
2026-11-06 · A1 · Android hält die App oft am Leben, deshalb gilt auch die Rückkehr nach mindestens 5 Minuten im Hintergrund als Öffnen, außer ein Workout läuft.
2026-11-06 · A8, A9 · Prüfung: sofortiges Speichern schnitt laufende Trainings ab, und OpenStrap erkennt keine Sportart. Felix hat beides freigegeben, Handball kommt in den Katalog.
2026-11-06 · A25 neu · Der Update-Hinweis von OpenStrap würde Edge anbieten, Felix will trotzdem von neuen Takt-Versionen erfahren.
