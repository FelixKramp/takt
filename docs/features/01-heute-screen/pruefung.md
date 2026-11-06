---
feature: 01-heute-screen
geprueft: 2026-11-06
stand: 0f2b5517
---
# Zweite Prüfung: Heute-Screen

**Ergebnis: nicht freigabefähig.** 5 von 25 Kriterien sind nicht bestanden (A1, A8, A9, A15, A25), 4 sind nur am Gerät prüfbar (A6, A12, A14, A17), 16 sind bestanden. Die zwei schwersten Fehler: Ein laufendes Training kann weiterhin dauerhaft abgeschnitten werden (N1), und die App öffnet im Normalfall nicht auf Heute, weil die Engine auf Android weiterlebt (N2).

Die Befunde F3 und F5 der ersten Prüfung sind behoben, S1 ebenfalls im Code. F1 und F4 sind nur teilweise behoben. F2 ist im Hauptweg behoben, die neue Sportwahl hat aber eigene Fehler mitgebracht.

## Grundlage

- `flutter test test/takt --timeout 90s`: 43 Tests bestanden. `flutter analyze lib/takt lib/app.dart`: keine Funde. Die volle Suite und der APK-Build liefen parallel und sind nicht Teil dieser Prüfung.
- Eigene Prüftests liegen außerhalb des Repos in einer Kopie ohne `.env*`, `android/key.properties` und `*.jks`: `/private/tmp/claude-501/-Users-felix-Documents-Obsidian-Felix/80747e21-fb4f-4587-8a43-73278d290795/scratchpad/p2/takt/test/p2/p2_test.dart`. Sie laufen gegen die echte SQLite-Datenbank (ffi) und `TaktTodayScreen`. Die Prüftests der ersten Prüfung liefen dort ebenfalls erneut. Zwei davon scheitern an der Testumgebung beziehungsweise am geänderten Ablauf, nicht am Code: `LogWorkout` beim Antippen ist bewusst dem Picker gewichen, und ein Test baut ohne `ThemeController`.
- `.env`, `.env.*`, `android/key.properties` und `*.jks` habe ich nicht gelesen, auch nicht indirekt. Das APK habe ich nicht untersucht, weil die Werte aus `.env` darin stehen und der Build parallel lief. Deshalb bleibt ein Punkt offen, siehe Sicherheit.
- Ein Handy und ein Band gab es nicht. A1 und alle Aussagen zur Lebensdauer der Engine stammen aus dem Code.
- Der fehlende Push ist bekannt und kein Befund.

## Stand der Befunde aus der ersten Prüfung

| Befund | Stand | Nachweis |
|---|---|---|
| A1 immer auf Heute | ❌ nur beim Kaltstart | N2 |
| A2 Assertion im Debug-Build | ✅ behoben | Erster Load läuft post-frame. Alter Prüftest: `ERSTER LOAD exception=null`. Token und `try/catch` sind drin. |
| A8 Abschneiden | ❌ nur für den Fall ohne Datenlücke behoben | N1 |
| A8 offen sichtbar | ✅ behoben | Test `A8: Laufendes Training steht offen …`, Prüftest N1 |
| A8 Name „Training" | ✅ behoben | `activity_list.dart:93`, gilt für den Heute-Tab |
| A8 Speichern nach 30 Minuten | ❌ für den Tag behoben, nicht über Mitternacht | Test `A8: Abgeschlossenes Training wird gespeichert`, N3 |
| A9 Sportwahl per Tipp, Handball | ✅ Hauptweg behoben | Gespeichert: Test im Repo. Offen: Prüftest `OFFEN NAME handball=1 sessions=0`, danach `GESPEICHERT [suggestion:d:… handball]`. |
| A9 Verwerfen zieht andere Tabs nach | ❌ nur die Listen | N4 |
| A13 Frische bleibt nicht stehen | ✅ behoben | Prüftest ohne Einfluss von außen: `TICK vorher=gerade eben`, `TICK nachher=vor 1 Min` |
| A13 Rückkehr lädt neu | ✅ behoben | Prüftest: `VOR RESUME sichtbar=1`, `NACH RESUME sichtbar=2` |
| A13 Tageswechsel | ✅ nur gelesen | `_onTick` vergleicht `_day` mit `todayLabel()`. Liegt der Kopf außerhalb des ListView-Puffers, tickt `MinuteTick` nicht. Dann greift das Neuladen beim Zurückkehren. |
| A15 Reste und Bitten | ❌ Rest bleibt | Community-Gruppe und Nudges sind aus. Es bleiben die Punkte unter N6. |
| A16 Herkunft, Lizenz, Copyright, Haftung | ✅ behoben | `about.dart:27-32`, `takt_text.dart:51-53`, bei 200 % auf 360 px ohne Fehler gerendert |
| A16 Änderungshinweis | ✅ behoben | `NOTICE.md`, mit Datum und Urheber |
| Kein Firebase | ✅ im Code | Siehe Sicherheit |
| Keine Abflüsse an OpenStrap | ✅ im Code | Siehe Sicherheit |
| Keine Platzhalter-URLs | ⚪ | Im Code keine. `.env` per Auftrag nicht gelesen. |
| Import bestätigt keine alten Vorschläge | ✅ behoben | Vorschlag von gestern: `pending=1`, `sessions=0`. Der Preis dafür ist N3. |

## Neue und offene Funde, nach Schwere

### N1 (hoch): Ein laufendes Training wird weiter abgeschnitten (A8)
`takt_today_screen.dart:106` nimmt `AppState.lastRecordAt` als Maß für „die Daten reichen 30 Minuten über das Ende hinaus". `lastRecordAt` läuft aber mit dem Sync, das Ende der Erkennung erst mit der Ableitung. `isSettled` (`auto_confirm.dart:11`) vergleicht also frische Daten mit einer alten Erkennung.

Der sichere Weg dorthin ist Herunterziehen: `_refresh` wartet auf `syncNow` und ruft sofort `_load` (`takt_today_screen.dart:184-194`). `syncNow` fordert die Ableitung nur an und wartet nicht auf sie (`sync_controller.dart:1006`, `markStoredData` und `requestHeavy` sind `unawaited`). Dasselbe Fenster gibt es bei `resumed` während eines laufenden Abrufs und beim Zurückkehren aus einem Detail-Screen.

Das ist Felix' Normalfall: Das Handy liegt beim Handball in der Tasche oder der Kabine, die App hat nach 12 bis 30 Minuten eine Erkennung, dann fehlt die Verbindung, und nach dem Training landet der ganze Rest auf einmal. Reproduktion mit der echten Datenbank: 29 Minuten erkannt, Training bis Minute 90, Rückstand bis Minute 95, dann Herunterziehen, danach die Ableitung mit dem ganzen Training:
```
VOR SYNC offen: 1
NACH PULL sessions: [suggestion:d:1793919900 29 min]
PENDING NACH ABLEITUNG: 0
NACH ABLEITUNG sessions: [suggestion:d:1793919900 29 min]
```
Die 61 fehlenden Minuten kommen nicht zurück, weil die Entscheidung gilt (`activity_store.dart:190-192`). Der Bruchteil wird außerdem nach Health Connect exportiert, wenn der Export an ist (`local_repository_impl.dart:91`). Die Spec sagt „nie abgeschnitten". Der Maßstab muss die letzte abgeschlossene Ableitung sein, nicht der Datenstand. Die Takt-Tests sehen das nicht, weil sie `lastRecordAt` und Erkennung immer passend zueinander setzen.

### N2 (hoch): Die App öffnet im Normalfall nicht auf Heute (A1, A6, A12)
`app.dart:520` setzt den Tab nur beim Erzeugen von `_ShellState`. Auf Android überlebt dieser State aber das Schließen: `MainActivity.kt:33` hält die Engine mit `shouldDestroyEngineWithHost() = false`, der Kommentar in `MainActivity.kt:12-14` nennt ausdrücklich das Wegwischen aus den letzten Apps, und der Vordergrunddienst hält den Prozess am Leben. `_ShellState` hat keinen Lifecycle-Beobachter. `didChangeAppLifecycleState` gibt es nur in `_OpenStrapAppState` (`app.dart:93`), und dort wird kein Tab gesetzt.

Reproduktion aus dem Code, am Gerät in 20 Sekunden zu bestätigen: Gesundheit-Tab wählen, Home-Taste oder Wegwischen, App öffnen. Es erscheint Gesundheit, und der Puls läuft nicht, weil `taktTodayVisible` falsch bleibt. Ein echter Kaltstart kommt mit gekoppeltem Band fast nur nach einem Neustart oder Absturz vor. Der Fix berührt eine Entscheidung: Soll auch eine kurze Rückkehr nach zehn Sekunden auf Heute springen, oder erst nach einer Mindestzeit im Hintergrund?

### N3 (mittel): Abendtraining wird nicht gespeichert, wenn die Daten erst nach Mitternacht reichen (A8)
`auto_confirm.dart:26` überspringt alles, was vor Mitternacht begann, und gibt es auch nicht mehr als offen zurück. Damit ist der Import geschützt, aber auch ein Training von gestern Abend. Reproduktion, Training 21 bis 22 Uhr gestern, Daten bis jetzt:
```
GESTERN pending=1
GESTERN sessions=0
```
Es wird nicht gespeichert, hat keinen Strain und steht nicht in der Liste von Heute. Es liegt nur noch unter „Mehr zu heute" zur Handbestätigung. Das trifft jedes Training, nach dessen Ende bis Mitternacht kein `_load` mit genug Daten lief, etwa weil das Band erst morgens wieder Kontakt hat oder ein Training kurz vor Mitternacht beginnt. Die Grenze trennt Import und Alltag am falschen Merkmal. Der Import ist an seinem eigenen Zeitpunkt erkennbar, `suppressImportedAlerts` macht das bereits für Benachrichtigungen.

### N4 (mittel): Sportwahl und Verwerfen sind an den Rändern unsauber (A9)
1. **Doppeltipp im Picker führt zu einem leeren Bildschirm, wenn die Datenbank kurz belegt ist.** `_pickSport` (`takt_today_screen.dart:149-159`) hat den `busy`-Schutz nicht, den das Original an derselben Stelle hat und begründet (`summary.dart:948-952`). Zwei Tipps, bevor `setSessionType` fertig ist, poppen zweimal. Prüftest: `DOPPELTIPP exception=null heute=0 picker=0`, der Heute-Screen ist weg. Auf dem Gerät braucht das eine laufende Ableitung oder einen Abruf, der den Schreibvorgang verzögert.
2. **Verwerfen scheitert still.** `_discard` hat keinen Fehlerpfad. Ändert eine Ableitung die Erkennung, bevor die Liste neu geladen ist, wirft `discardActivity` wegen der Revision (`activity_store.dart:416`). Prüftest: `ActivityReviewException`, danach `pending=1`. Der Tipp bewirkt für Felix nichts, und die Ausnahme geht verloren. Das gilt gerade für wachsende offene Erkennungen.
3. **Verworfen, aber der Tages-Strain bleibt.** Ein schon gespeichertes Workout läuft über `deleteWorkout`. `LocalDb.deleteSession` (`db.dart:14908`) markiert den Tag nicht als geändert, anders als `confirm` und `discard` im `ActivityStore`. Die Listen ziehen über `bumpInsights` nach, der angehobene Tageswert (`strainFlooredAtSessions`, `derivation_engine.dart:8318`) erst mit der nächsten Ableitung. Ohne Band bleibt er stehen. Nur gelesen.
4. **Verworfen, aber in Health Connect bleibt es.** `confirmActivity` exportiert das Workout (`local_repository_impl.dart:91`), `deleteWorkout` entfernt den Eintrag dort nicht. Im Original hat Felix vorher selbst bestätigt. In Takt landen Fehlerkennungen ohne Klick dort und bleiben nach dem Verwerfen stehen. Gilt nur bei eingeschaltetem Export. Nur gelesen, am Gerät zu prüfen.
5. **Die Wahl geht verloren, wenn das Speichern dazwischenkommt.** Bestätigt ein Reload im Hintergrund die Erkennung, während der Picker offen ist, schreibt `_pickSport` nur noch in die Einstellungen. Prüftest: `RENNEN [suggestion:d:… other] handball sichtbar=0 training=1`. Selten, das Fenster ist klein.

### N5 (niedrig): Der Update-Hinweis wird im Dauerbetrieb nicht aktualisiert (A25)
`refreshTaktUpdate` läuft nur in `initState` von `TaktTodayScreen` (`takt_today_screen.dart:60`). Aus demselben Grund wie bei N2 entsteht dieser State selten neu. Ein Release, das erscheint, während die Engine läuft, zeigt die App erst nach dem nächsten Neustart des Prozesses, also womöglich wochenlang nicht. „Höchstens einmal am Tag" ist eingehalten, dass der Hinweis dasteht, nicht.

### N6 (niedrig): OpenStrap ist noch sichtbar (A15)
- `coach_prompt.dart:12`: „You are the OpenStrap coach". Der Coach stellt sich so vor, sobald Felix ihn danach fragt.
- `exercise_picker.dart:232`: Der wger-Hinweis führt weiter auf `openstrap.github.io/edge/notice.html`. Die Einstellungen sind umgestellt, diese Stelle nicht, obwohl `NOTICE.md` den Text selbst enthält.
- Dateinamen im Teilen-Dialog und im Backup-Ordner: `openstrap_export_*.db` (`db.dart:10740`), `openstrap_*.csv` (`csv_export.dart:426, 521`), `openstrap-<Datum>.db` (`auto_backup.dart:144`). Die Muster hängen an Aufräum- und Importlogik, sie sind also nicht einfach zu tauschen.
- `db.dart:11617`: Fehlermeldung „not an OpenStrap database".

Grenzfälle, die zu entscheiden sind: „OpenStrap-Backup" in `app_de.arb:129, 322` stimmt für den Import aus Edge, gilt aber auch für Takts eigene Sicherung. Die Maskottchen in `assets/images/mascot_*.png` stammen von OpenStrap, und `TRADEMARKS.md` verlangt, „other branding" zu ersetzen. Ob sie dazu zählen, ist offen.

### N7 (niedrig): Der CI-Build ist noch der von OpenStrap
Der Workflow startet bei einem Tag `v*`, also genau dann, wenn A25 ein Release braucht. `build.yml:199` setzt `ENABLE_HEALTH_DATA_CONTRIBUTION=true`. Im so gebauten APK erscheint „Gesundheitsdaten spenden" wieder (`settings.dart:226`). Ohne `COMPANION_URL`-Secret geht nichts raus, die Zeile steht aber da. `build.yml:230-235` nennt das Ergebnis `openstrap-edge-*.apk`.

### N8 (niedrig): Lokale Fehlerberichte sind nicht mehr erreichbar
Der Kommentar in `report_issue.dart:92` sagt „Das lokale Teilen bleibt". `ReportIssueScreen` hat aber nur den einen Einstieg in `settings.dart:874`, und der ist jetzt ausgeblendet. Felix kann also auch keinen Diagnosebericht mehr für sich selbst teilen.

### Offenes Risiko, nicht belegt
`app.dart:614` setzt `taktTodayVisible` weiter im `build`. Neu ist, dass daran über `_onVisible` jetzt ein Sync hängt. Springt eine Benachrichtigung bei getrenntem Band von einem anderen Tab auf Heute, laufen `syncNow`, `openSession` und `refreshActivityReviews` samt `bumpInsights` synchron im Build an. Ob das eine Assertion auslöst, habe ich nicht nachgestellt, `_Shell` ist privat und braucht die ganze App.

## Anforderungen

| ID | Ergebnis | Befund |
|---|---|---|
| A1 | ❌ | N2. Die Reihenfolge stimmt. Ringe und Puls passen ohne Scrollen, erneut gemessen auf 360×640: Pulsunterkante bei 364 px. |
| A2 | ✅ | Lädt ohne Assertion, der Test im Repo baut jetzt den echten Screen. |
| A3 | ✅ | Unverändert. Dieselben Detail-Screens. |
| A4 | ✅ | Genau drei Karten. Die HRV läuft jetzt durch `overnightMetric`, der Mangel aus der ersten Prüfung ist weg. |
| A5 | ✅ | Prüftest: `MORE exception=null`. Krankheitswarnung nur bei Anschlag. Keine Community-Nudges mehr im alten Screen. |
| A6 | ⚪ | Die 5 Sekunden und der laufende Wert brauchen ein Band. Vor dem ersten Wert steht jetzt „Warte auf den Puls …". Betroffen von N2. |
| A7 | ✅ | Alter Prüftest erneut bestanden: Der Zähler fällt bei Push, Tabwechsel, Hintergrund und `dispose`. Das tatsächliche Ende des Stroms am Band zeigt nur das Gerät. |
| A8 | ❌ | N1 und N3. Sichtbarkeit, Felder und Name stimmen. `avg_bpm` kommt so aus dem Detektor (`derivation_engine.dart:10740`). Strain nur gelesen, die Prüftests laufen ohne Herzfrequenz-Daten. |
| A9 | ❌ | N4. Der Hauptweg funktioniert: Handball wählbar, auch für offene Erkennungen, die Wahl überlebt das Speichern. Verworfenes kommt nicht zurück (`pending=0` nach Ableitung mit dem ganzen Training). Der Repo-Test deckt nur gespeicherte Workouts ab. |
| A10 | ✅ | Eine Liste, neueste oben. |
| A11 | ✅ | Prüftest: `manual:… handball 60`. |
| A12 | ⚪ | Braucht Band. `_syncIfDue` läuft jetzt auch bei `resumed` und Tabwechsel, gedrosselt auf fünf Minuten. Betroffen von N2. |
| A13 | ✅ | Siehe Tabelle oben. |
| A14 | ⚪ | Braucht Band und eine Stunde. Das Risiko aus der ersten Prüfung besteht unverändert: Die schwere Ableitung läuft im Hintergrund höchstens alle 30 Minuten (`sync_controller.dart:885-890`). |
| A15 | ❌ | N6. Benachrichtigung, Widget, Health-Connect-Titel, User-Agents und ChatGPT-Name sind umgestellt, die Community-Bitten sind aus. Nebeneinander-Installieren bleibt ⚪, das braucht ein Gerät. |
| A16 | ✅ | Die Links führen erst nach dem bekannten Push zum Inhalt. |
| A17 | ⚪ | Braucht eine echte Edge-Datenbank. Alte Vorschläge bleiben unbestätigt. Heutige offene Edge-Vorschläge werden beim ersten Load gespeichert, sobald die Daten reichen. |
| A18 | ✅ | Unverändert. Die Uhrzeit trägt weiter kein Datum, ein Wert von gestern steht als „zuletzt um 14:32" da. |
| A19 | ✅ | Der Mangel aus der ersten Prüfung ist weg: Gekoppelt ohne Messwert zeigt nicht mehr „Band koppeln". |
| A20 | ✅ | Tests bestanden. |
| A21 | ✅ | Tests bestanden. |
| A22 | ✅ | Tests bestanden. |
| A23 | ✅ | Nur gelesen, unverändert. |
| A24 | ✅ | Prüftest bei 360×640 und 390×844 mit 200 %: `errors=[]`. Doto ist im Test nicht geladen. |
| A25 | ❌ | N5. Nur GitHub, keine Parameter, Stempel für 24 Stunden. Der Upstream-Hinweis bleibt tot. |

## Sicherheit und Datenschutz

| Punkt | Ergebnis | Befund |
|---|---|---|
| Firebase im Code | ✅ | `firebase_options.dart` ist entfernt, `FirebaseBridge.initialize` wirft, `main.dart:40-44` fängt das ab. Die Aufrufe in `telemetry_service.dart` hängen an `isInitialized`. Keine `google-services.json`, die Gradle-Plugins werden dann nicht angewendet. Die Projekt-ID steht im Code nirgends mehr. Der Schalter „Absturzberichte" ist weg. |
| Firebase zur Laufzeit | ⚪ | Die Pakete stecken weiter im APK. Dass ohne App-ID kein Verkehr entsteht, zeigt nur ein Mitschnitt am Gerät. |
| Fehlerberichte an OpenStrap | ✅ | `reports.openstrap.site` ist nur über `sendReport` und `deleteReport` aus `ReportIssueScreen` erreichbar. `_send` bricht ab, der Einstieg ist ausgeblendet. |
| Sonstige Abflüsse an OpenStrap | ✅ | Alle Adressen in `lib` und Kotlin durchgesehen. Sonst nur OpenAI und selbst gewählte Coach-Anbieter, Open Food Facts, OpenStreetMap, GitHub (Takt) und Links, die Felix selbst antippt. |
| Update-Prüfung | ✅ | GET ohne Parameter auf das Takt-Repo. |
| Platzhalter-URLs im Code | ✅ | Keine Treffer in `lib`, `android`, `pubspec.yaml`. Die Standardwerte für `COMPANION_URL` und `BACKEND_URL` sind leer. |
| Platzhalter-URLs im Build | ⚪ | `.env` per Auftrag nicht gelesen, das APK deshalb nicht durchsucht. Zu bestätigen: `COMPANION_URL` und `BACKEND_URL` sind in `.env` leer oder fehlen. |

## Reihenfolge der Korrekturen

1. N1: Gegen den Stand der letzten Ableitung prüfen statt gegen `lastRecordAt`.
2. N2: Heute auch beim Zurückkehren. Vorher von Felix entscheiden lassen, ab welcher Zeit im Hintergrund.
3. N3: Die Grenze für den Import am Import festmachen, nicht an Mitternacht.
4. N4: `busy`-Schutz und Fehlerpfad, Tag als geändert markieren, Health-Connect-Eintrag beim Verwerfen entfernen.
5. N5 bis N8, die Grenzfälle aus N6 mit Felix klären.
6. Tests: einer für N1 mit veralteter Erkennung, einer für die Sportwahl auf offener Erkennung, einer für den Doppeltipp.
