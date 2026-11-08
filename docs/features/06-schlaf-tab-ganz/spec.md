---
feature: 06-schlaf-tab-ganz
freigegeben: 2026-11-08
---
# Spec: Schlaf-Tab ganz im Takt-Design, Tab-Leiste

## Nutzer und Nutzen
Felix' Gerätetest von 0.2.0: Nur der Kopf des Schlaf-Tabs ist im neuen Design. Darunter folgt
der alte OpenStrap-Screen mit Phasen, Vergleich und Signalen. Diese Daten sind wichtig, sehen aber
anders aus als der Kopf. Auch Titelzeile und Tab-Leiste sind noch im alten Design. Ziel: Der
ganze Schlaf-Tab und die Tab-Leiste sehen aus wie Heute und der Schlaf-Kopf. Es kommen keine neuen
Daten dazu.

Entwurf: Board „Die Nacht“ auf dem Canvas (https://claude.ai/artifact/2WBkgmZ3R9En5JE1mm6mSS).

## Schon erledigt (Gerätetest 0.2.0)
- **E1** Der Schlafring auf Heute öffnet den Schlaf-Screen mit Takt-Kopf, nicht den alten.
- **E2** Der Takt-Kopf bleibt beim schnellen Weg- und Zurückscrollen stehen und wird nicht neu
  geladen.

## Akzeptanzkriterien

### Rahmen
- **F1** – Kopfzeile
  Ausgangslage: Schlaf-Tab offen · Handlung: ansehen · Ergebnis: Oben steht eine Zeile wie auf
  Heute: links „schlaf“ klein geschrieben, in der Mitte die Nacht mit Pfeilen zum Blättern
  („‹ Nacht auf Sa, 8. Nov. ›“), rechts das Profilbild. Der große Titel „Schlaf“ und die
  eigene Blätterzeile darunter fallen weg.
- **F2** – Tab-Leiste
  Ausgangslage: beliebiger Tab · Handlung: ansehen · Ergebnis: Die Leiste ist flach, in der
  Kartenfarbe, mit einer Linie oben. Der aktive Tab ist fett und farbig, ohne Pille dahinter:
  Schlaf in der Farbe des Schlafscores, die anderen in Takt-Orange. Die Beschriftungen sind
  deutsch. Das gilt für alle vier Tabs.

### Die Nacht
- **F3** – Hypnogramm
  Ausgangslage: Nacht mit Phasen · Handlung: Schlaf-Tab ansehen · Ergebnis: Unter dem Kopf zeigt
  eine Takt-Karte „Die Nacht“ vier Bahnen (Wach, REM, Leicht, Tief) über Uhrzeiten. Tief ist
  dunkel, REM und Leicht sind abgestufte Grautöne, Wach ist orange.
- **F4** – Zeitpunkt antippen
  Ausgangslage: Hypnogramm sichtbar · Handlung: hineintippen oder darüber ziehen · Ergebnis: Eine
  Linie markiert den Zeitpunkt. Darunter stehen Uhrzeit, Phase, Puls, HRV und Atmung zu diesem
  Moment. Das funktioniert wie bisher, nur im Takt-Design.
- **F5** – Fremdes Gerät
  Ausgangslage: Ein zweites Gerät hat die Nacht selbst in Phasen eingeteilt · Handlung: Auswahl
  „Takt / <Gerät>“ antippen · Ergebnis: Das Hypnogramm wechselt wie bisher.
- **F6** – Schlafzeiten korrigieren
  Ausgangslage: Nacht falsch erkannt · Handlung: „Zeiten stimmen“, „Zeiten ändern“, „War kein
  Schlaf“ oder „Ich habe geschlafen“ · Ergebnis: Diese Aktionen funktionieren wie bisher. Sie
  stehen als flache Takt-Knöpfe unter dem Hypnogramm. Die Hinweise zur Korrektur sind
  einzeilig.

### Phasen, Vergleich, Signale
- **F7** – Phasen
  Ausgangslage: Nacht mit Phasen · Handlung: ansehen · Ergebnis: Eine Karte zeigt einen
  durchgehenden Balken mit den vier Phasen in den Farben aus F3. Darunter stehen vier Zeilen mit
  Phase, Dauer und Anteil. Wo OpenStrap eine Spanne angibt, steht die Spanne („1:18 bis 1:42“).
- **F8** – Gegen deine Nächte
  Ausgangslage: genug Nächte zum Vergleich · Handlung: ansehen · Ergebnis: Jede bisherige
  Vergleichsfrage (genug geschlafen, Tiefschlaf, durchgeschlafen, pünktlich eingeschlafen) ist
  eine Zeile. Sie zeigt den Wert der Nacht, ein graues Band „üblich bei dir“ mit Punkt und einen
  kurzen Satz („24 Min kürzer als üblich“). Ohne genug Nächte steht eine Zeile mit diesem Hinweis.
- **F9** – Auffällig
  Ausgangslage: In der Nacht ist etwas aufgefallen (z. B. Schlafpuls hoch, unruhige Nacht) ·
  Handlung: ansehen · Ergebnis: Eine Karte mit orangem Rand links nennt es. Ist nichts
  aufgefallen, steht dort eine Zeile „Nichts aufgefallen“, keine Karte.
- **F10** – Signale in der Nacht
  Ausgangslage: Signale aufgezeichnet · Handlung: ansehen · Ergebnis: Drei große Ziffern zeigen
  Schlafpuls, tiefsten Puls und Atmung. Darunter liegen schmale Verläufe für Puls, HRV, Atmung und
  Hauttemperatur über dieselbe Zeitachse wie das Hypnogramm.

### Unten
- **F11** – Kein doppelter Schlafplan
  Ausgangslage: neueste Nacht · Handlung: ans Ende scrollen · Ergebnis: Der alte Abschnitt „Dein
  Schlafplan“ (Bedarf, Schuld, Bettzeit) entfällt. Der Kopf zeigt das schon unter „Dauer und
  Bedarf“ und „Regelmäßigkeit“.
- **F12** – Weiterführend
  Ausgangslage: Ende des Tabs · Handlung: ansehen · Ergebnis: Eine Takt-Karte mit vier Zeilen
  führt zu Wecker, Körperuhr, Nickerchen und „Alle Messwerte“ (bisher „Nerd stats“).

### Für alle
- **F13** – Streifen
  Ausgangslage: Displaystreifen eingestellt · Handlung: den ganzen Tab durchscrollen · Ergebnis:
  Keine Ziffer liegt auf dem Streifen (Regel B5).
- **F14** – Flüssig
  Ausgangslage: lange Nacht mit allen Abschnitten · Handlung: schnell nach unten und wieder nach
  oben scrollen · Ergebnis: Kein Abschnitt zeigt kurz eine leere Fläche oder lädt neu.
- **F15** – Schlafring auf Heute
  Ausgangslage: Heute offen · Handlung: Schlafring antippen · Ergebnis: Es öffnet sich derselbe
  Schlaf-Screen wie im Tab, mit F1 bis F12. Statt des Profilbilds steht dort ein Zurück-Pfeil.

## Randfälle
- Nacht ohne Phasen: Hypnogramm-Karte und Phasen-Karte zeigen je eine Zeile „Keine Phasen für
  diese Nacht“, der Rest bleibt.
- Keine Nacht: Der Kopf zeigt seinen Grund. Darunter steht nur „Ich habe geschlafen“, dazu der
  Link zu den Nickerchen.
- Lesefehler: Die Zeile „Nacht konnte nicht gelesen werden“ mit „Erneut versuchen“, die Pfeile
  bleiben bedienbar.
- Dunkles Design: Alle Farben haben eine dunkle Fassung mit mindestens 4,5:1 Kontrast für Text.

## Nicht-Ziele
- Neue Berechnungen oder neue Daten.
- Die Unterscreens Wecker, Körperuhr, Nickerchen und „Alle Messwerte“ selbst umgestalten.
- Aktivität und Gesundheit umgestalten (Feature 05). Hier ändert sich bei ihnen nur die
  Tab-Leiste.
- Batterie (Feature 04).

## Daten
Nur, was der Schlaf-Screen schon liest (`SleepData`). Nichts Neues gespeichert.
