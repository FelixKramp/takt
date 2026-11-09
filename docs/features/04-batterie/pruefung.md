---
feature: 04-batterie
geprueft: 2026-11-09
pruefer: unabhängiger Prüfer-Agent
stand: af3e096 (HEAD)
---
# Prüfung: Batterie statt Erholung (Feature 04)

## Kurzfassung
Formel, Ring, Detail, Wochenkarte und Displaystreifen erfüllen die Spec. Die Navigation
Ring → Batterie → „So entsteht die Ladung“ → Erholung läuft auch mit echter Datenbank. Zwei
Befunde sind ❌:

1. **Heute in der Woche zeigt eine Ladung, obwohl der Ring „–“ zeigt** (D5/D6).
2. **Die Tageskurve kann wieder steigen.** Die Batterie lädt sich im Detail sichtbar auf, das ist
   laut Spec ein Nicht-Ziel.

Dazu kommen einige Hinweise, keiner davon blockiert.

## Was gelaufen ist
- `flutter test test/takt`: **238 Tests grün** (17:23 Uhr, außerhalb des bekannten Fensters 00:00–00:35).
- `flutter analyze lib test/takt`: 1 Info in `test/takt/workout_takt_test.dart:159` (geschweifte
  Klammern). Nicht von diesem Feature, in `lib/` und in den Dateien von 04 nichts.
- Fotos: `TAKT_SHOTS=1 flutter test test/takt/shots_test.dart --plain-name "Feature 04"` →
  `build/shots/batterie.png` und `batterie_woche.png`, ausgeschnitten und angesehen.
- Eigene Wegwerf-Tests (wieder gelöscht, ebenso die Test-Datenbank):
  - `zz_pruefung04_test.dart`: 22 Fälle, Formel, Tageszuordnung, Ringzustände, kaputte Daten,
    Streifen-Sweep, 320 px, Schrift 2,0, dunkel.
  - `zz_pruefung04_db_test.dart`: echter Heute-Tab mit sqflite ffi, `metric_series` mit sieben
    Tagen `readiness` und `strain`, dann Ring → Detail → Erholung.

## Kriterien

| ID | Ergebnis | Befund |
|---|---|---|
| D1 Ladung am Morgen | ✅ | Strain 0 → Ladung unverändert. Vor dem Aufwachen ist die Kurve leer (null), sie beginnt mit dem ersten Wach-Minutenpunkt. |
| D2 Verbrauch, Formel, Rundung | ✅ | Nachgerechnet: 78 → 66 / 36 / 26 bei Strain 6 / 14 / 16, 0 bei 21, Gegenrechnung 62 % mit 13,8 von Hand. Strain > 21 → 0, Strain < 0 → voll, Ladung > 100 wird auf 100 begrenzt. Die Rechnung steht im Detail (Zeilen und Satz mit der Formel). |
| D3 Ring | ✅ | Erster Ring heißt „Batterie“, Mitte zeigt den Stand, darunter „von 62 %“. Kein „Erholung“ mehr auf Heute. Siehe Hinweis H6 zum %-Zeichen. |
| D4 Detail | ✅ (Mechanik) / ❌ siehe B2 | Wertkarte, Kurve „Verlauf heute“, Rechnung, Knopf „So entsteht die Ladung“ → `ReadinessDetail` in `TaktLook`. Mit echtem Repo nachgestellt. Die Kurve selbst: siehe B2 und H1. |
| D5 Ohne Erholung | ✅ Ring / ❌ Woche, siehe B1 | Ring: ohne Wert „–“ und derselbe Grund wie der Erholungsring. Bei `night_in_progress` gilt das auch, wenn ein Wert vorliegt (Mitte „–“, Grund „Die Erholung wird nach dem Aufwachen bewertet.“). Kalibrierung „6/14“, darunter „6 von 14 Nächten“ wie vorher. Vorläufig: Batteriewert grau. |
| D6 Wochenkarte | ✅ mit Ausnahme B1 | Sieben Säulen, Rest über der Säule, Wochentag darunter, heute fett, Tage ohne Erholung leer mit „–“. Tageszuordnung: `getChart` stempelt jeden Tag auf 12:00 Ortszeit, ein Punkt pro Tag. Über die Umstellungen 25.10.2026 und 29.03.2026 stimmt die Zuordnung, ebenso für Punkte um 23:59 und 00:01. Heute nimmt die frischen Werte aus `HomeData`. Die Woche lädt beim Öffnen von Heute, nach jedem Sync oder jeder Rechnung (`_wasBusy`), nach Rückkehr aus einem Detail und um Mitternacht. Erscheint nur, wenn mindestens ein Tag eine Ladung hat (leer, `[]` und „nur Strain“ geprüft). |
| D7 Zu viel gemacht | ✅ | Rest < 20 → Säule und Ziffer rot, Satz „Mehr belastet als erholt: Fr“. Grenze strikt „unter 20“ auf den gerundeten Rest. |
| D8 Displaystreifen | ✅ | Streifen von 5 % bis 95 % in Schritten von 2,5 % über Heute mit Wochenkarte und über das Detail mit Kurve gefahren. Geprüft bei 390 px/Schrift 1,0 und 320 px/Schrift 2,0, hell und dunkel: keine Ziffer im Streifen, keine Zahl ohne `StripeDodge` (auch Achsen der Kurve). |
| Randfall: kein Strain | ✅ | Ring voll mit „Belastung noch nicht berechnet“ (Zeile unter den Ringen), im Detail derselbe Hinweis, Rechnung mit „–“. |
| Randfall: Nickerchen laden nicht | ⚪ | Keine eigene Nickerchen-Logik vorhanden, also auch kein Aufladen dadurch. Aber siehe B2: Die Kurve kann aus einem anderen Grund steigen. |
| Nicht-Ziel: Aufladen während des Tages | ❌ | Siehe B2. |
| 320 px, Schrift 2,0 | ✅ | Heute mit Woche und Detail ohne Überlauf und ohne Exception. |
| Dunkelmodus | ✅ | Ohne Exception, Farben über `P`/`Pult.orangeFor(p.dark)`/`ScoreBand`. Nur im Test gerendert, kein dunkles Foto angesehen. |
| Navigation | ✅ | Erster Ring meldet `recovery` → `BatteryDetail`. Im echten Heute-Tab: Ring antippen öffnet `BatteryDetail`, das über das Repo lädt. „So entsteht die Ladung“ öffnet `ReadinessDetail`, ohne Exception. |
| Robustheit | ✅ | Keine Abstürze bei leerer Woche, Kurve nur aus null, Kurvenwerten −4 und 50, Strain 30 oder −1, Ladung 150 oder −5, NaN (ergibt Unsinn, aber keine Exception), ohne Repo (Strich und „noch kein Wert“). Fehler beim Laden der Strain-Kurve werden abgefangen. |

## Befunde ❌

### B1 – Heute in der Woche hat eine Ladung, der Ring sagt „–“ (D5, D6)
`batteryWeek` nimmt für heute `todayMorning ?? on(recovery, heute)`. Fehlt die frische Erholung
(Nacht läuft, Nacht wird noch gerechnet, keine bewertete Nacht), fällt die Säule auf den Verlauf
`getChart('recovery')` zurück. Der hat für heute einen Punkt, sobald ein Derive heute eine
`readiness` in `metric_series` geschrieben hat. Laut Kommentar in `getChart` (#448) tut das jeder
Derive, auch bei einer Teilnacht. Ausgeblendet wird er dort nur im Recheck-Fenster
(`overnight_recheck_at`).

**Reproduktion (echte DB):** `metric_series` mit `readiness` für die letzten sieben Tage
einschließlich heute (heute 50), Strain heute 10, `day_result` für heute mit `payload_json '{}'`.
Heute-Tab öffnen.
- Ring: „Batterie“, Mitte „–“, Grund „There is no scored night to read this from.“
- Woche: heute „34“ (= 50 × (1 − (10/21)^1,5)) und eine gefüllte Säule.

Die Spec verlangt: „Tage ohne Erholung bleiben leer mit –“, und der Ring zeigt bei fehlender
Erholung „–“. Ring und Woche widersprechen sich auf demselben Screen. Naheliegend: Für heute nur
`todayMorning` nehmen, ohne Rückfall auf den Verlauf, oder bei `recoveryState != final/provisional`
leer lassen. (Nur Befund, nicht repariert.)

### B2 – Die Tageskurve steigt wieder, die Batterie „lädt auf“ (D4, Nicht-Ziel)
`series.strain_curve` ist laut `strainCurveFromSeries` (openstrap_analytics, `load_trimp.dart`)
der kumulierte 0–21-Strain, aber **ausdrücklich nicht monoton**: Ein ruhiger Abend unter dem
Ruhe-Niveau nettet Belastung vom Tag wieder heraus. Das Beispiel dort fällt von 10,74 auf 9,38.
Das Upstream-Strain-Detail sagt das selbst in der Fußnote („It can ease later …“).
`batteryCurve` setzt die Werte eins zu eins um.

**Reproduktion:** `batteryCurve(78, [10.74, 9.38])` → `[49, 55]`. Im Detail steigt die Linie
abends also von 49 % auf 55 %.

Die Spec sagt „wird über den Tag mit der Belastung leerer“ und führt „Aufladen während des Tages“
als Nicht-Ziel. Felix sieht abends eine Batterie, die ohne Schlaf wieder voller wird. Das muss
Felix entscheiden, zwei Wege:
- Laufendes Minimum der Batterie zeichnen (Ratsche). Dann stimmt das Kurvenende nicht mehr mit
  „Stand jetzt“ überein, wenn der Strain zurückging.
- Die Spec um den Satz ergänzen, dass Strain am Abend sinken kann und die Batterie dann leicht
  steigt.

## Hinweise (kein ❌)

- **H1 – Kurvenende und „Stand jetzt“ können auseinanderlaufen.** Die Kurve kommt aus dem Bundle
  von `getDayStrain`. „Stand jetzt“ und der Ring kommen aus `HomeData.strain`, und das ist,
  solange `activity_state` nicht `ready` ist, der Zwischenwert aus `wake_day_features`. Bis zum
  nächsten Derive endet die Linie dann woanders als die Zahl darüber. Im Foto
  `batterie.png` sieht man das auch: Linie endet bei 50, darüber steht 47. Das sind synthetische
  Testdaten, das Muster ist aber dasselbe.
- **H2 – Tag der Kurve wird nicht geprüft.** `getDayStrain(heute)` fällt auf das letzte fertige
  Bundle zurück (gestern), wenn es für heute noch keins gibt. `DayStrainData.day` sagt das,
  `BatteryDetailData.load` ignoriert es. Nach den Pfaden in `getToday` gibt es heute aber nur dann
  eine Erholung, wenn auch ein heutiges Bundle existiert. Ohne Erholung wird keine Kurve gezeichnet.
  Gestern-Kurve mit Heute-Ladung ist also nur durch diese Daten-Invariante ausgeschlossen, nicht
  durch den Code. Empfehlung: Kurve nur zeichnen, wenn `day` heute ist.
- **H3 – Vorläufige Erholung im Detail nicht gekennzeichnet.** Der Ring zeigt den Wert bei
  `provisional` grau. Das Detail zeigt dieselbe Zahl ohne Hinweis, dass sie sich noch ändern kann.
  Das Detail prüft auch `recoveryState` nicht (bei `night_in_progress` ist `readiness.value` nach
  `getToday` aber praktisch null).
- **H4 – Grund im Detail auf Englisch.** `BatteryDetailData.why` nimmt `ringViewOf(...).why`
  roh. Mit echter DB steht in der deutschen App „There is no scored night to read this from.“,
  obwohl es in `app_localizations_de.dart` eine Übersetzung gibt (über `uiText`/`display_text.dart`).
  Dieselbe rohe Zeile steht schon vorher unter den Ringen auf Heute (Feature 01), die Batterie
  übernimmt das.
- **H5 – Ein Ladefehler nimmt zu viel mit.** `_loadLastValues` liest HRV, Ruhepuls, Erholung und
  Strain in einem `try`. Wirft `getChart('recovery')` oder `getChart('strain')`, gehen auch
  `_hrvLast`/`_rhrLast` verloren (Feature 01, G2), und umgekehrt. Vorher hing G2 nur an zwei
  Lesungen.
- **H6 – Ring ohne „%“.** D3 sagt „zeigt den aktuellen Stand in Prozent“. In der Mitte steht nur
  die Zahl (wie vorher beim Erholungsring), das % steht nur in „von 78 %“. Vermutlich gewollt, der
  Platz ist knapp.
- **H7 – Verlauf ohne Strain zählt als voll.** Ein vergangener Tag mit Erholung, aber ohne
  Strain-Punkt (Band nicht getragen, Strain neu skaliert), steht in der Woche als „nichts
  verbraucht“ mit voller Säule und ohne Hinweis. Für heute gibt es den Hinweis, für Vortage nicht.
- **H8 – Werte außerhalb 0–100.** Bei Erholung 120 steht „0“ oder „100 von 120 %“, bei −5
  „von -5 %“. Im Detail steht bei Strain −1 „Belastung bisher −1,0“. Upstream liefert solche Werte
  nicht, deshalb nur der Vollständigkeit halber.
- **H9 – Rohe Größen.** `battery_week.dart` (Säulenbreite 18, Höhe 88, Ziffern 15, Alpha .22) und
  `battery_detail.dart` (Zeilenhöhe 44, Ziffern 22, Kurvenhöhe 140) setzen Zahlen direkt statt
  über `theme.dart`/`pult_tokens.dart`. Die Konvention in `CLAUDE.md` verbietet das.
- **H10 – Lückenzeile unter den Ringen.** Fehlt der Strain, zeigt die Zeile unter den Ringen
  (nur der erste Grund) jetzt „Belastung noch nicht berechnet“ von der Batterie. Den eigenen Grund
  des Strain-Rings (z. B. Band nicht getragen) sieht man dann nicht mehr. Gewollt laut Randfall,
  aber der genauere Grund geht verloren.
- **H11 – Doku nachziehen.** `CLAUDE.md` nennt unter „Nicht im MVP“ noch „Batterie statt
  Erholung“. 01/A3 und 07/H9 sprechen vom „Erholungsring“. Der Ring ist jetzt die Batterie, und die
  Erholung liegt einen Tipp tiefer. Das ist durch D4 gedeckt, die alten Texte stimmen aber nicht
  mehr wörtlich.

## Regressionen (Stichproben)

| Bezug | Ergebnis | Befund |
|---|---|---|
| 01/A1 Reihenfolge, ohne Scrollen | ✅ | Ringe, Puls, Karten, Aktivitäten in dieser Reihenfolge. Die Wochenkarte steht nach den Aktivitäten. Die Aktivitäten stehen mit und ohne Woche an derselben Stelle (y = 434 bei 390×844), der Puls ist ohne Scrollen sichtbar. |
| 01/A2 Drei Ringe | ✅ | Batterie, Strain, Schlaf. Der angepasste Test in `today_view_test.dart` prüft jetzt Stand und „von 62 %“, legitim nach D3. |
| 01/A3 Ringe führen weiter | ✅ (geändert durch D4) | Der erste Ring öffnet die Batterie statt der Erholung. Strain und Schlaf unverändert. |
| 01/A20 Kalibrierung | ✅ | „6/14“ und „6 von 14 Nächten“ wie vorher, grau, kein erfundener Wert. |
| 01/A24 Große Schrift | ✅ | 320 px, Schrift 2,0, ohne Überlauf. |
| 07/H9 Erholungs-Screen erreichbar | ✅ | Über „So entsteht die Ladung“, mit echter DB geöffnet. Alle bestehenden Tests von 07 grün. |
