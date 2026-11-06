---
feature: 01-heute-screen
geprueft: 2026-11-06
stand: 4d51296f
---
# Dritte Prüfung: Heute-Screen

**Ergebnis: nicht freigabefähig, aber kein Blocker für den Gerätetest.** 5 von 25 Kriterien sind nicht bestanden (A1, A8, A9, A15, A25), 4 sind nur am Gerät prüfbar (A6, A12, A14, A17), 16 sind bestanden. Die Zahl ist dieselbe wie in der zweiten Prüfung, die Schwere nicht: Die Reproduktion von N1 (Backlog nach Lücke, Abschneiden bei 29 Minuten) ist behoben, N2 im Hauptweg ebenfalls.

Der neue schwerste Fund: Aus einer laufenden Berechnung heraus wird nie gespeichert, und nach ihrem Ende lädt niemand neu (D1). Bei offener App bleibt das Training deshalb ohne Strain stehen, obwohl alle Bedingungen erfüllt sind. Das verfälscht den Gerätetest von A8. Zweiter neuer Fund: Nach mindestens 5 Minuten im Hintergrund überschreibt die Rückkehr auf Heute das Ziel eines Benachrichtigungs-Tipps (D2).

## Grundlage

- `flutter test test/takt --timeout 90s`: 49 Tests bestanden. `flutter analyze lib/takt lib/app.dart lib/data/export_retention.dart`: keine Funde. `test/export_retention_test.dart`, `test/auto_backup_test.dart`, `test/issue_report_test.dart`: bestanden. Die Gesamtsuite lief nicht, wie beauftragt.
- Während der Prüfung kam Commit `4d51296f` dazu (Aufräumliste `_healthCopyName` kennt die Takt-Namen). Geprüft ist dieser Stand. Die Änderung betrifft nur `export_retention.dart` und den zugehörigen Test, beide liefen danach erneut.
- Eigene Prüftests liegen außerhalb des Repos in einer Kopie ohne `.env*`, `android/key.properties` und `*.jks`: `/private/tmp/claude-501/-Users-felix-Documents-Obsidian-Felix/80747e21-fb4f-4587-8a43-73278d290795/scratchpad/p3/takt/test/p3/p3_test.dart` (R1 bis R12, echte SQLite-Datenbank und echter `TaktTodayScreen`) und `shell_test.dart` daneben (S1 bis S6, echter `_Shell`).
- Für die S-Tests ist die Kopie an zwei Stellen geändert: `_Shell` ist über `debugShell()` erreichbar, und `kBackToTodayAfter` steht auf 1 Sekunde. Im Repo habe ich nur diese Datei geändert.
- S3 bis S6 lieferten ihre Ausgabe, hängen danach aber beim Abbau des Tests. Die Ergebnisse stehen vor dem Hänger und sind davon nicht berührt.
- `.env`, `.env.*`, `android/key.properties` und `*.jks` habe ich nicht gelesen, auch nicht indirekt. `plan.md` habe ich nicht gelesen.

## Stand der Befunde aus der zweiten Prüfung

| Befund | Stand | Nachweis |
|---|---|---|
| N1 Abschneiden nach Datenlücke | ✅ Reproduktion behoben | R1: `NACH PULL sessions=[] pending=1`, nach der Berechnung mit 5 Minuten Nachlauf weiter offen, später `other 90min`. Restlücken: D3 bis D5. |
| N2 App öffnet nicht auf Heute | ✅ Hauptweg behoben | S3: `nach resumed heuteVorn=true`. Neue Nebenwirkungen: D2, D6. |
| N3 Abendtraining über Mitternacht | ✅ behoben | Grenze ist jetzt 36 Stunden. Restlücke: D4. Die empfohlene Kopplung an den Import fehlt, siehe D10. |
| N4.1 Doppeltipp im Picker | ✅ behoben | R12: `heute=1 picker=0`, `handball 29min`. Doppeltipp auf die Zeile öffnet nur einen Picker (R6). |
| N4.2 Verwerfen scheitert still | ⚠️ teilweise | R8: Die Liste lädt neu, der zweite Tipp wirkt. Der erste Tipp bewirkt weiter nichts, ein Hinweis fehlt. |
| N4.3 Tages-Strain nach Verwerfen | ❌ offen | Unverändert, D7. |
| N4.4 Health Connect nach Verwerfen | ❌ offen | Unverändert, D7. |
| N4.5 Wahl geht beim Speichern verloren | ⚠️ teilweise | Das Fenster ist kleiner, aber nicht zu. R9, D8. |
| N5 Update-Hinweis im Dauerbetrieb | ✅ behoben | `refreshTaktUpdate` läuft auch bei `resumed` (`takt_today_screen.dart:80`). Neue Folge: D9. |
| N6 OpenStrap sichtbar | ⚠️ teilweise | Coach, wger-Link, Fehlermeldung und `openstrap_export_*` sind umgestellt. Offen: D11. |
| N7 CI-Build | ✅ behoben | `build.yml` ist entfernt. |
| N8 Lokale Berichte | ✅ erreichbar | Der Eintrag ist zurück. Rest: D12. |
| Risiko `taktTodayVisible` im Build | ✅ erledigt | Wird jetzt in `_go`, `onSelect` und `initState` gesetzt, nicht mehr im `build`. |

## Prüfung der neuen Bedingung in `isSettled`

| Frage | Ergebnis |
|---|---|
| Schreitet `computed_at` für heute fort? | Ja. `_dayInputFingerprint` gibt für heute `null` zurück (`derivation_engine.dart:3343`), heute wird also nie als unverändert übersprungen. Ein leichter Lauf nimmt heute zuerst (`selectLightDeriveDays`, Zeile 2496). |
| Wird `computed_at` in der richtigen Einheit gelesen? | Ja, Millisekunden an allen Schreibstellen. `_kComputedAtToMs = 1` ist nur eine überflüssige Konstante. |
| Können die zwei Uhren dauerhaftes Warten erzeugen? | Nein. `lastRecordAt` ist Bandzeit, `computed_at` Handyzeit, aber das Band wird beim Verbinden ab 2 Sekunden Abweichung gestellt (`ble_engine.dart:3706-3734`), und die Rechnung läuft mindestens 2 bis 8 Sekunden nach dem Sync. |
| Bleibt ein Workout dauerhaft ungespeichert? | Nicht dauerhaft, aber ohne Eingriff unbegrenzt lange: D1. Echt dauerhaft nur, wenn binnen 36 Stunden ab Start nie genug Daten kommen, dann liegt es unter „Mehr zu heute". |
| Fenster zwischen Sync-Ende und Einreihen | Für die Reproduktion der zweiten Prüfung harmlos, weil `computed_at` dort älter ist als der Datenstand und die Bedingung auch ohne `busy` greift (R1). `busy` allein schützt dieses Fenster nicht: `syncNow` reiht unawaited ein, `_refresh` liest danach sofort (`sync_controller.dart:1020`, `takt_today_screen.dart:220`). Offen bleibt der Fall D3. |

## Neue Funde, nach Schwere

### D1 (mittel, verfälscht den Gerätetest): Das Ende der Berechnung löst kein Speichern aus (A8)
`bumpInsights` läuft in `afterDrain` (`derive_coordinator.dart:135`), also solange `DeriveScheduler._running` wahr ist. `_load` liest genau dann `busy = true` (`takt_today_screen.dart:110`) und speichert nichts. Nach dem Ende ruft der Scheduler nur `onChanged` auf (`derive_scheduler.dart:255-259`), das ist `notifyListeners`, kein Revisionswechsel. Damit kann eine Berechnung das Speichern nie auslösen. Gespeichert wird nur bei Rückkehr aus dem Hintergrund, Herunterziehen, Rückkehr aus einem Detail-Screen, Sportwahl, Verwerfen oder Tageswechsel. Ein Tabwechsel lädt ebenfalls nicht neu.

```
R2 WAEHREND ABLEITUNG sessions=0
R2 NACH ENDE DER ABLEITUNG sessions=0 pending=1
R2 NACH RUECKKEHR sessions=[suggestion:d:1793919900 other 90min]
```
So sieht es für Felix aus: Er öffnet die App nach dem Training, der Sync läuft, die Berechnung ist fertig, das Training bleibt „erkannt" ohne Strain. Einmal Herunterziehen reicht meist auch nicht, weil dann wieder `busy` gilt. Erst das zweite Herunterziehen oder App zu und wieder auf speichert. Daten gehen nicht verloren. Die Takt-Tests sehen das nicht, weil ihr `AppState` nie `deriving` meldet. Korrektur: beim Wechsel von `busy` auf frei einmal neu laden.

### D2 (mittel): Die Rückkehr auf Heute überschreibt Benachrichtigungen (A1)
Android liefert den Tipp vor `onResume`: `onNewIntent` schickt `didReceiveNotificationResponse` (`FlutterLocalNotificationsPlugin.java:1907-1922`), `onResume` schickt danach `appIsResumed` (`FlutterActivityAndFragmentDelegate.java:570-575`). `_consume` öffnet also erst das Ziel, dann schließt `app.dart:534-535` es wieder.

```
S1 nach resumed heuteVorn=true detected=0        (Tipp vor resumed, Ziel ist weg)
S2 heuteVorn=true detected=1                     (Tipp nach resumed, Gegenprobe)
S3 nach Tipp heuteVorn=false
S3 nach resumed heuteVorn=true                   (Tab-Ziel überschrieben)
```
Betroffen ist jeder Tipp nach mindestens 5 Minuten Hintergrund, also der Normalfall für Benachrichtigungen: „Did you nap?", Erholung bereit, Wecker-Hinweise, Rückblick. Die Reihenfolge ist aus den Quellen abgeleitet und im Test nachgestellt, am Gerät in einer Minute zu bestätigen. Korrektur: eine offene oder gerade verbrauchte Anfrage hat Vorrang vor der Rückkehr.

### D3 (niedrig): Zwei Uhren lassen eine fremde Rechnung als passend durchgehen (A8)
`isSettled` vergleicht die Handyzeit der Rechnung mit der Bandzeit der Daten. Rückstand trägt alte Zeitstempel. Lief eine Rechnung, nachdem diese Zeit verstrichen war, aber bevor die Daten ankamen, gilt sie als aktuell, obwohl sie die Daten nie gesehen hat:
```
R3 sessions=[suggestion:d:1793919900 other 29min] pending=0
```
Das Beispiel: Rechnung um Minute 95 ohne neue Daten, gelandet sind nur Daten bis Minute 70, das Training lief bis 90. Dazu muss ein Abruf vor der Gegenwart abbrechen, eine Rechnung in der Lücke gelaufen sein und ein Reload genau in die wenigen Sekunden vor dem Einreihen fallen. Felix' Normalfall trifft das nicht: Die Rechnung nach Verbindungsverlust läuft rund 20 Minuten nach dem letzten Datensatz, das liegt vor der 30-Minuten-Schwelle. Auch Nap-Änderungen setzen `computed_at` (`db.dart:14294`). Treffer wären dauerhaft. Korrektur: den Datenstand vergleichen, den die Rechnung tatsächlich gesehen hat, statt ihrer Uhrzeit.

### D4 (niedrig): Vor Mitternacht begonnen, aber nur der heutige Tag gerechnet (A8)
`_derivedAt` liest nur die Zeile von heute. Ein leichter Lauf rechnet nach Mitternacht nur heute, gestern nicht:
```
R5 leichter Lauf rechnet: [2026-11-06] (today-priority), Training liegt in 2026-11-05
R5 sessions=[suggestion:d:1793914200 other 29min] pending=0
```
Trifft nur Trainings, deren Rückstand nach Mitternacht ankommt und bei denen kein schwerer Lauf vorausgeht, etwa beim gedrosselten Wiederverbinden im Hintergrund (`sync_controller.dart:885-888`). Korrektur: die Zeile des Tages prüfen, zu dem das Training gehört.

### D5 (niedrig): Gescheiterte Berechnung zählt als Berechnung (A8)
Scheitert die zweite Hälfte der Ableitung, läuft `reconcile` nicht (`derivation_engine.dart:6445`, `6469`), die Zeile wird trotzdem als `partial` mit frischem `computed_at` geschrieben. `_derivedAt` prüft weder `partial` noch `skipped`:
```
R4 partial sessions=[suggestion:d:1793919900 other 29min] pending=0
```
Selten, die Korrektur ist eine Zeile.

### D6 (niedrig): Rückkehr auf Heute setzt die Scrollposition nicht zurück, und sie schließt alles (A1)
1. Steht Heute schon vorne, tut `_go` nichts. Heruntergescrollt bleibt heruntergescrollt: `S6 Scroll vorher=218.0 nachher=218.0 ringe_y=-150.0` auf 360×640. A1 verlangt Ringe und Puls ohne Scrollen, die Änderung vom 06.11. wertet diese Rückkehr als Öffnen.
2. `popUntil` schließt jede Route. Dialoge gehen mit `null` zu (S4: `zu:null`, ohne Ausnahme). Halb ausgefüllte Formulare wie „Workout nachtragen" oder Journal sind weg, ebenso eine offene Atemübung, denn die Ausnahme gilt nur für `activeWorkout`. Das deckt die Spec-Änderung formal ab. Dialoge mit `barrierDismissible: false` gibt es nicht, ein Hänger durch verwaiste Fortschrittsdialoge ist also ausgeschlossen.
3. Nur gelesen: Wer länger als 5 Minuten in der Dateiauswahl, im Teilen-Dialog oder in den Health-Connect-Rechten bleibt, kommt zurück auf Heute, der aufrufende Screen ist weg. Pairing läuft ohne längeren Hintergrund, dort sehe ich kein Risiko.

Laufendes Workout: Die Ausnahme greift, gelesen und per Einheitentest. Doppelte Syncs entstehen beim Neuaufbau nicht (S5: von 1 auf 2).

### D7 (niedrig, aus N4 offen): Verwerfen eines gespeicherten Workouts räumt nicht nach (A9)
`deleteWorkout` führt zu `LocalDb.deleteSession` (`db.dart:14908`), ohne den Tag als geändert zu markieren und ohne `HealthExporter.deleteWorkoutWindow` (`health_export.dart:608`). Der angehobene Tages-Strain bleibt bis zur nächsten Berechnung, ohne Band also stehen. Bei eingeschaltetem Export bleibt die Fehlerkennung in Health Connect. Nur gelesen.

### D8 (niedrig): Sportwahl während des Speicherns geht verloren (A9)
Liegt das Speichern gerade im Schreibvorgang, wenn die Wahl fällt, findet `setSessionType` keine Zeile, und die Session landet als `other`:
```
R9 nach Wahl, Aufrufe=[other, handball, handball]
R9 ERGEBNIS sessions=[suggestion:d:1793919900 other 29min] pending=0 handball=0 training=1
```
Felix sieht „Training" und kann neu wählen. Parallele Reloads sind sonst unkritisch: R10 ergibt genau eine Session.

### D9 (niedrig): Die Update-Prüfung kann zweimal am selben Tag fragen (A25)
Der Stempel wird erst nach der Antwort gesetzt (`update_check.dart:54`). `R11 Abfragen=2` bei zwei parallelen Aufrufen. Genau das passiert bei Rückkehr von einem anderen Tab: Der alte Screen ruft bei `resumed`, der neu aufgebaute in `initState`. Ohne Gesundheitsdaten, aber das Kriterium sagt „höchstens einmal". Korrektur: Stempel vor dem Abruf setzen.

### D10 (niedrig): Importierte Vorschläge der letzten 36 Stunden werden ohne Nachfrage gespeichert (A17)
Die 36-Stunden-Grenze trennt Import und Alltag weiter nur über das Alter. Offene Edge-Vorschläge von gestern werden nach dem Import als „Training" gespeichert und bei eingeschaltetem Export nach Health Connect geschrieben. Die Spec schließt das nicht aus, die vorige Fassung tat es nicht. Nur gelesen, am Gerät beim Band-Umzug anzusehen.

### D11 (niedrig): OpenStrap bleibt in Dateinamen sichtbar (A15)
Der Commit nennt die Exportnamen einheitlich, das stimmt nicht ganz:
- `auto_backup.dart:144`: `openstrap-<Datum>.db.gz` im selbst gewählten Backup-Ordner.
- `csv_export.dart:426, 521`: `openstrap_*.csv` im Teilen-Dialog.

Durch die Umbenennung bricht nichts. Alle Muster und Schreibstellen passen zusammen (`takt_export_`, `takt_report_`, `takt_days_`, `_healthCopyName` seit `4d51296f`). Der Import erkennt Dateien am Inhalt und an der Endung, nicht am Namen, die Edge-Datei `openstrap_export_*.db` lässt sich also weiter importieren. Wer den Backup-Namen ändert, muss `_backupNamePattern` (`auto_backup.dart:164`) so erweitern, dass vorhandene Dateien weiter erkannt werden.

Weiter von Felix zu entscheiden: „OpenStrap-Backup" in `app_de.arb:129, 322`, die Maskottchen in `assets/images/mascot_*.png`. Neu dazu, aber vertretbar: `settings.dart:2001` nennt die Aktion `wtf.openstrap.openstrap_edge.BUZZ_STRAP`, das ist ein technischer Bezeichner, den der Text korrekt angibt.

### D12 (Schönheitsfehler)
- `report_issue.dart:346-350`: „Bericht senden" steht ausgegraut da, `reportIncludedNote` beschreibt weiter eine Übertragung an die Entwickler.
- `takt_today_screen.dart:174-176`: Scheitert das Schreiben im Picker, bleibt er kommentarlos offen.
- `takt_today_screen.dart:39`: `_kComputedAtToMs = 1` ist wirkungslos.
- `takt.sport.<id>` wird nach dem Speichern nie aus den Einstellungen entfernt.
- Der Sammelersatz hat Pfade in Upstream-Tests mitgenommen (`test/real_export_m5_gate_test.dart:35`, Rig-Tests). Das ändert nichts am Verhalten, erzeugt aber Merge-Konflikte gegen die Konvention „Upstream punktuell".

## Anforderungen

| ID | Ergebnis | Befund |
|---|---|---|
| A1 | ❌ | D2, D6. Die Rückkehr selbst funktioniert, die Reihenfolge stimmt. Ein Benachrichtigungs-Tipp verliert sein Ziel, der Screen bleibt heruntergescrollt. |
| A2 | ✅ | Tests bestanden, seit der zweiten Prüfung unverändert. |
| A3 | ✅ | Unverändert. |
| A4 | ✅ | Unverändert. |
| A5 | ✅ | Unverändert. |
| A6 | ⚪ | Braucht Band. Der Weg zum Heute-Tab ist jetzt da. |
| A7 | ✅ | Tests bestanden. Das Ende des Stroms am Band zeigt nur das Gerät. |
| A8 | ❌ | D1 (Speichern bleibt aus), D3 bis D5 (enge Restfälle von Abschneiden). Der Normalfall aus der zweiten Prüfung ist behoben. Strain nur gelesen, die Prüftests laufen ohne Herzfrequenz-Daten. |
| A9 | ❌ | D7, D8, erster Tipp bei veralteter Erkennung ohne Hinweis. Doppeltipp behoben, Verworfenes kommt nicht wieder (R7: `Wiedererkennung pending=0`, auch für gespeicherte). |
| A10 | ✅ | Unverändert. |
| A11 | ✅ | Unverändert. |
| A12 | ⚪ | Braucht Band. `_syncIfDue` läuft bei `resumed`, Neuaufbau und Tabwechsel. |
| A13 | ✅ | Unverändert. |
| A14 | ⚪ | Braucht Band und eine Stunde. Im Hintergrund drosselt `DeriveDebouncer` auf 20 bis 45 Minuten (`ble_state.dart`), das Risiko aus den Vorprüfungen besteht unverändert. |
| A15 | ❌ | D11. Nebeneinander-Installieren bleibt ⚪. |
| A16 | ✅ | Der wger-Link zeigt auf eine vorhandene Überschrift in `NOTICE.md`. Inhalte erst nach dem bekannten Push erreichbar. |
| A17 | ⚪ | Braucht eine echte Edge-Datenbank. Der Dateiname ist kein Hindernis. D10. |
| A18 | ✅ | Unverändert. |
| A19 | ✅ | Unverändert. |
| A20 | ✅ | Tests bestanden. |
| A21 | ✅ | Tests bestanden. |
| A22 | ✅ | Tests bestanden. |
| A23 | ✅ | Gelesen. Die Rückkehr auf Heute lässt ein laufendes Workout in Ruhe. |
| A24 | ✅ | Unverändert, nicht erneut gemessen. |
| A25 | ❌ | D9. Hinweis, Link, Quelle und Aktualisierung im Dauerbetrieb stimmen. Der Upstream-Hinweis bleibt aus (`update_service.dart:67`). |

## Sicherheit und Datenschutz

Keine neuen Abflüsse. Die Aufräumliste für „Alles löschen" erfasst seit `4d51296f` die neuen Namen. In `bbc3be49` war das eine Lücke, unverschlüsselte Kopien wären liegen geblieben. Die offenen Punkte der zweiten Prüfung bleiben ⚪: Firebase zur Laufzeit (nur per Mitschnitt am Gerät) sowie `COMPANION_URL` und `BACKEND_URL` in `.env`, die ich per Auftrag nicht gelesen habe.

## Einordnung für den Gerätetest

**Blocker: keiner.** Nichts stürzt ab oder verhindert den Test.

**Vor dem Test beheben oder Felix sagen:**
1. D1: Sonst sieht A8 am Gerät wie gescheitert aus. Ohne Korrektur gilt: nach dem Training App schließen und wieder öffnen, dann erst bewerten.
2. D2: Sonst wirkt jeder Benachrichtigungs-Tipp kaputt.

**Vor der Freigabe, aber nach dem Gerätetest:** D3 bis D5 (Treffer wären dauerhaft, deshalb trotz Seltenheit zu schließen), D6, D7, D8, D9.

**Schönheitsfehler:** D10 bis D12, soweit Felix bei den Grenzfällen nichts anderes entscheidet.

**Am Gerät gezielt ansehen:** Reihenfolge von Tipp und `resumed` (D2), Heute nach Rückkehr von einem anderen Tab, Band-Umzug mit offenen Edge-Vorschlägen (D10), A6, A12, A14, A17.

## Tests, die fehlen

- D1: `AppState` meldet `deriving` beim Revisionswechsel und danach frei.
- D2: `_Shell` mit Tipp vor `resumed`. `shouldReturnToToday` ist bisher nur als reine Funktion getestet, der Shell-Weg gar nicht.
- D3 bis D5: `computed_at` nach Wanduhr jünger als der Datenstand, Zeile `partial`, Workout von gestern.
