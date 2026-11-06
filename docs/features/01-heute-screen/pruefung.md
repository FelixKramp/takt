---
feature: 01-heute-screen
geprueft: 2026-11-06
stand: 683109b9
---
# Prüfung: Heute-Screen

**Ergebnis: nicht freigabefähig.** 7 von 25 Kriterien sind nicht bestanden, 4 sind nur am Gerät prüfbar. Die zwei schwersten Fehler: Erkannte Workouts werden beim ersten Erkennen eingefroren (ein 90-Minuten-Training bleibt bei 29 Minuten stehen), und jedes erkannte Workout heißt „Other", ohne dass sich die Art vom Heute-Tab aus ändern lässt.

## Grundlage

- `flutter test test/takt`: 33 Tests bestanden. `flutter analyze lib/takt`: keine Funde. Die volle Suite habe ich nicht laufen lassen.
- Die 33 Tests berühren `TaktTodayScreen`, `PulseDisplay`, `MoreForToday*`, `TaktAboutGroup` und `refreshTaktUpdate` nicht. Sie prüfen reine Funktionen und die Ansicht mit Callbacks. Dadurch blieben F1 bis F5 unentdeckt.
- Eigene Prüftests lagen außerhalb des Repos: `/private/tmp/claude-501/-Users-felix-Documents-Obsidian-Felix/80747e21-fb4f-4587-8a43-73278d290795/scratchpad/t/`. Sie laufen gegen die echte SQLite-Datenbank (ffi), den echten Detektor aus `openstrap_analytics` und `AppState.forTesting`. Zitierte Ausgaben stammen daraus.
- Das fertige `build/app/outputs/flutter-apk/app-release.apk` habe ich mit `aapt` und `strings` geprüft.
- `android/key.properties` und `*.jks` habe ich nicht gelesen. `.env` habe ich nicht angezeigt, nur per `cmp` mit `.env.example` verglichen: identisch. Der Platzhalter steht unabhängig davon im APK (S2).

## Hauptfunde

### F1: Auto-Bestätigen friert ein laufendes Training ein (A8)
`takt_today_screen.dart:89-93` bestätigt jeden offenen Vorschlag sofort. Der Detektor meldet aber schon nach 12 Minuten eine Einheit, die noch wächst. Nach dem Bestätigen gilt die Entscheidung (`activity_store.dart:190-192`), und der Detektor verwirft jedes Fenster, das ein gespeichertes Workout überlappt (`auto_detect.dart:344`).

Reproduktion mit 90 Minuten Puls 160 und einer Ableitung nach 30 Minuten:
```
BOUT1 [29 min sport=detected]
NACH 1 [suggestion:d:… other 29 min]
BOUT2 mit gespeichertem Fenster 0
NACH 2 [suggestion:d:… other 29 min]
```
Dauer, Durchschnittspuls und Strain bleiben dauerhaft die des Bruchstücks. Das trifft den Normalfall: `RevisionReload._onRevision` lädt auch geparkte Tabs neu, also bestätigt `_load` auch im Hintergrund, sobald eine Ableitung während des Trainings läuft. Upstream hat diesen Fall bewusst offen gehalten, Vorschläge wachsen dort bis zur Bestätigung (`revision`, „changed as more data arrived"). Die Architektur behandelt das nicht.

### F2: Jedes erkannte Workout ist „Other", die Art ist nicht änderbar (A8, A9)
`derivation_engine.dart:10716` ruft `autoDetectWorkouts` ohne Klassifikator auf, also ist `sport` immer `detected`. `takt_today_screen.dart:93` macht daraus `other`. `activityByName('other')` findet nichts, deshalb zeigt `activity_items.dart:90` das rohe Wort. Im deutschen Heute-Tab steht wörtlich:
```
Other, erkannt, 12:05 AM, 30 min
```
Antippen öffnet `LogWorkout(sessionId: …)`. Dort ist die Aktivitäts-Zeile im Retime-Modus ausgeblendet (`log_workout.dart:417`), und gespeichert wird nur das Zeitfenster (`log_workout.dart:323`). Prüftest: `A9 Aktivitaet-Zeile im Formular: 0`. Den funktionierenden Weg gibt es, er ist nur nicht angebunden: `LocalDb.setSessionType` über `ui2/activity/summary.dart:942`.

### F3: Der erste Load stirbt im Debug-Build (A2, A8, A10)
`takt_today_screen.dart:53` ruft `_load()` aus `initState`, Zeile 88 greift dort auf `AppLocalizations.of(context)` zu. Ergebnis im Test:
```
dependOnInheritedWidgetOfExactType<_LocalizationsScope>() … was called before _TaktTodayScreenState.initState() completed.
ERSTER LOAD … handball sichtbar=0
```
Das Workout liegt in der Datenbank, der Screen bleibt leer, bis die Revision sich bewegt. Ohne Band passiert das nie. `flutter build apk --debug` ist laut `CLAUDE.md` der Build-Befehl. Der Fehler ist eine Assertion, ein Release-Build sollte deshalb laden. Ausgeführt habe ich das nicht, `flutter test` hat keinen Schalter dafür.

Außerdem fehlt in `_load` jedes `try/catch` und der Schutz `beginRead`/`stillNewest`, den `revision.dart:48-69` ausdrücklich fordert. Ein älterer Read kann also einen neueren überschreiben, und ein Fehler bleibt unsichtbar.

### F4: Die App öffnet im zuletzt benutzten Tab (A1, A6, A12, A25)
`app.dart:421` und `app.dart:520` stellen den letzten Tab wieder her, `app_shell.dart:88` baut nur diesen. Reproduktion: Gesundheit-Tab wählen, App beenden, neu öffnen. Es erscheint Gesundheit. `TaktTodayScreen` existiert dann nicht, es gibt also keinen Puls, kein `_syncIfDue` von Takt, kein Auto-Bestätigen und keine Update-Prüfung. Das widerspricht dem Nutzen aus der Spec: „beim Öffnen sofort sehen … ohne erst in einen anderen Tab zu gehen".

### F5: Frische-Anzeige und Tageswechsel frieren ein (A13, Regression)
`takt_today_screen.dart:234` liest die Uhr im `build`. Es gibt keinen Timer, und `didChangeAppLifecycleState` (Zeile 66) ruft nur `_syncIfDue`, kein `setState` und kein `_load`. Reproduktion:
```
NACH RESUME age=64s status=gerade eben
```
Ohne Band bleibt „vor 2 Min" stundenlang stehen, also genau dann, wenn die Anzeige wichtig wäre. Dieselbe Lücke betrifft den Tageswechsel: Der alte Screen lädt nach dem Hintergrund neu, weil ein Tageswechsel keine Revision bewegt (`home_screen.dart`, `_onReturnFromBackground`). Takt tut das nicht. Ohne Band zeigt der Heute-Tab am Morgen also Ringe und Aktivitäten von gestern.

## Anforderungen

| ID | Ergebnis | Befund |
|---|---|---|
| A1 | ❌ | F4. Die Reihenfolge im Tab stimmt, Ringe und Puls passen auch auf 360×640 (Pulsunterkante bei 364 px). Beim Öffnen erscheint aber der letzte Tab. |
| A2 | ❌ | Nur Debug-Build: F3. Die Werte kommen unverändert aus `_ringOf`. Der Test prüft die Ansicht, nicht das Laden. |
| A3 | ✅ | Dieselben Detail-Screens wie der alte Home. Der Test prüft nur den Callback, das Öffnen selbst ist ungetestet. |
| A4 | ✅ | Genau drei Karten, die Schlüssel `hrv`, `resting_hr`, `steps` sind gültig. Test nur per Callback. Die HRV kommt ungefiltert aus `getToday`, Ruhepuls und Erholung laufen durch `overnightMetric`. Die Karten können also verschiedene Nächte zeigen. |
| A5 | ✅ | Eintrag „Mehr zu heute" in `health_screen.dart`, `MoreForTodayScreen` läuft als gepushte Route ohne Exception (Prüftest). Krankheitswarnung über `bodyWatchOf`, nur bei amber oder rot und frischem Datum. Kein einziger Takt-Test dazu. |
| A6 | ⚪ | Die 5 Sekunden und der laufende Wert brauchen ein Band. Die Logik stimmt, abgesehen von F4. Vor dem ersten Messwert steht kurz „Band nicht angelegt", auch wenn es angelegt ist (`pulse_state.dart:39-43`). |
| A7 | ✅ | Im Prüftest geprüft: Der Zähler fällt bei Route-Push, Tabwechsel, `paused` und `dispose` auf 0 und steigt danach wieder. Der Takt-Test prüft nur die Klasse `PulseStreamGate`, nicht die Verdrahtung. Ob der Strom am Band wirklich endet, zeigt erst das Gerät. |
| A8 | ❌ | F1 und F2. Die Felder sind vorhanden und `getWorkouts` liefert sie, aber Art, Dauer, Puls und Strain sind falsch bzw. Bruchstücke. |
| A9 | ❌ | Art ändern fehlt (F2). Verwerfen wirkt, und das Workout kommt nicht zurück: Prüftest mit erneuter Erkennung bestanden, Grund ist `status='confirmed'`. „Gilt sofort" stimmt aber nur halb: `_discard` nutzt `repo.deleteWorkout` (`takt_today_screen.dart:137`), das löst weder Revision noch Ableitung aus. Der Aktivität-Tab und der Strain-Boden aus den Sessions bleiben bis zur nächsten Ableitung alt. |
| A10 | ✅ | Eine Liste aus `getWorkouts` plus offenen Vorschlägen, neueste oben. Im Prüftest mit echter Datenbank gesehen. Betroffen von F3. |
| A11 | ✅ | `LogWorkout` mit Art-Auswahl, `_push` lädt danach neu. Prüftest: `manual:… handball 60`. Der Takt-Test prüft nur den Callback. |
| A12 | ⚪ | Braucht Band und Sync. Geprüft: Der Sync startet einmal nach dem Bau (`SYNCS=1`), danach reicht `requestHeavy` bis zur Revision. Der Takt-Test prüft nur `SyncOnOpenGate`. Bei F4 läuft nur der Upstream-Weg. |
| A13 | ❌ | F5. Der Test übergibt `now` von außen und kann das Einfrieren deshalb nicht sehen. |
| A14 | ⚪ | Braucht Band und mindestens eine Stunde. Risiko im Code: Im Hintergrund holt das Band nur alle 15 Minuten nach, die schwere Ableitung ist auf einmal pro 30 Minuten gedrosselt (`sync_controller.dart:887`). Eine Grenze von 30 Minuten für die Ringe ist nicht zugesichert. |
| A15 | ❌ | Label, Icon und `applicationId` stimmen, siehe aber die Liste unten. Das Nebeneinander-Installieren ist ⚪: Im APK stehen alle Authorities auf `de.felixkramp.takt`, der Beweis braucht ein Gerät. |
| A16 | ❌ | Der Code in `about.dart` stimmt. Der Link führt aber nicht zu Takt: `origin/main` steht auf `a9b765a7`, dem unveränderten Upstream-Stand, lokal ist `683109b9`. Kein Codefehler, ein `git push` fehlt. Vor jeder Weitergabe des APK ist das auch eine AGPL-Pflicht. |
| A17 | ⚪ | Braucht eine echte Edge-Datenbank. Der Import ist unveränderter Upstream-Code. Nebenwirkung: Beim ersten `_load` nach dem Import werden alle offenen Edge-Vorschläge der letzten 7 Tage ungefragt zu Workouts (`activity_store.dart`, `pendingShownForSec`). Upstream schreibt selbst, fast die Hälfte davon sei nie beantwortet worden. |
| A18 | ✅ | Grau, Uhrzeit, Grund, feste Höhe, getestet. Die Uhrzeit trägt kein Datum, ein Wert von gestern steht also als „zuletzt um 14:32" da. |
| A19 | ✅ | Keine Zahl, `MyDevices` erreichbar. Mangel: Gekoppelt, aber noch nie gemessen zeigt ebenfalls „Band koppeln" (im Prüftest gesehen: `--, Band nicht verbunden, Band koppeln`). |
| A20 | ✅ | „6/14" im Ring, „6 von 14 Nächten" darunter, Schlafring ohne Füllstand. |
| A21 | ✅ | Hinweis und Knopf vorhanden, getestet. |
| A22 | ✅ | Fünf plus Eintrag, klappt auf, getestet. `TaktText.allToday` ist toter Code. |
| A23 | ✅ | `_LiveSessionBar` im Shell führt zurück, `activeWorkout` hält den HR-Strom. Nur gelesen, ungetestet. |
| A24 | ✅ | Prüftest mit 360×640 und 390×844 bei 200 %, gescrollt, Stale-Puls, langer Sportname: keine Fehler. Der Takt-Test sieht nur den ersten Viewport. Doto ist im Test nicht geladen, die echte Breite zeigt erst das Gerät. |
| A25 | ✅ | Nur GitHub-GET auf das Takt-Repo, keine Parameter, 24-Stunden-Sperre. Die API liefert derzeit 404, es gibt noch kein Release. Der Upstream-Hinweis ist durch `kSideloadOtaEnabled=false` tot. Bei F4 läuft die Prüfung nicht, und fehlgeschlagene Anfragen stempeln nicht. Getestet sind nur die reinen Funktionen. |

### A15: Reste im Einzelnen
Für Felix sichtbar:
- `EdgeTrackingService.kt:254, 266`: Dauerbenachrichtigung und Kanal „Edge Tracking". Das ist der auffälligste Rest, er steht immer in der Statusleiste.
- `res/layout/widget_openstrap_nodata.xml:32`: „Open OpenStrap and sync your band."
- `lib/sync/background_sync.dart:584`: Benachrichtigung „Open OpenStrap to reconnect", nicht lokalisiert.
- `app_de.arb:2482, 2480` über `home_screen.dart:2151`: „Gefällt dir OpenStrap?" mit Sponsor-Link und Discord-Hinweis, in „Mehr zu heute".
- `ui2/profile/profile.dart:426-452`: Community-Gruppe mit GitHub „Please star", r/OpenStrap, Discord und Sponsor. Wirkt wie Support durch OpenStrap, `TRADEMARKS.md` schließt das aus.
- `HealthConnectSleepWriter.kt:161`: Titel „OpenStrap sleep" in Health Connect.
- `ui2/profile/settings.dart:938`: „Hinweise und Lizenzen" öffnet die Seite von OpenStrap.
- `coach_chatgpt.dart:41, 268, 617`: Bei OpenAI tritt die App als „OpenStrap Edge" auf.

Grenzfälle: „OpenStrap-Backup" (`app_de.arb:129, 322`) stimmt für den Edge-Import, heißt aber auch Takts eigene Sicherung so. Die Action `wtf.openstrap.openstrap_edge.BUZZ_STRAP` steht im Einstellungstext.

## Sicherheit und Datenschutz

| Punkt | Ergebnis | Befund |
|---|---|---|
| Fehlerberichte an OpenStrap | ✅ | `_send` bricht in `report_issue.dart:93` ab, der Knopf ist aus. Der Text in den Einstellungen sagt aber weiter „an die Maintainer", und der graue Knopf erklärt nichts. |
| Update-Hinweis von Upstream | ✅ | `fetchStatus` ist ohne `ENABLE_SIDELOAD_OTA` tot, auch `build.yml` setzt es nicht. |
| Update-Prüfung ohne Gesundheitsdaten | ✅ | GET ohne Parameter. GitHub sieht nur IP und Uhrzeit. |
| Secrets im Repo | ✅ | `key.properties`, `*.jks` und `.env` nicht getrackt, auch nicht in der Historie. Keine Treffer im Diff. |
| S1: Firebase | ❌ | Siehe unten. |
| S2: Platzhalter-Backend im APK | ❌ | Siehe unten. |
| Ohne Einwilligung | ⚪ | Crash-, Analytics- und Performance-Sammlung sind per Manifest und `enforceCollectionOffUntilConsent` aus. Ob `Firebase.initializeApp` trotzdem Netzverkehr auslöst, zeigt nur ein Mitschnitt am Gerät. |

**S1: Crash-Daten gingen an das Firebase-Projekt von OpenStrap.** Die Architektur sagt „Kein Firebase". Tatsächlich sind alle Firebase-Pakete da, und `lib/firebase_options.dart:52` enthält das echte Projekt `portofliowebsite-387909`, das auch im Release-APK steht. `FirebaseBridge.initialize` übergibt diese Optionen ausdrücklich. Die Aussage im Kommentar, ohne `google-services.json` scheitere die Initialisierung, gilt damit nicht sicher. Der Schalter „Absturzberichte" (`settings.dart:861-866`) ist immer sichtbar und schaltet die Sammlung ein. Das widerspricht direkt der Architektur: „Fehler von Takt gehören nicht zu OpenStrap". Ob Crashlytics ohne Gradle-Plugin startet, ist am Gerät zu prüfen. Der Schalter muss in jedem Fall aus der App oder ins Leere führen.

**S2: Das APK enthält `https://your-companion.example.workers.dev`.** `.env` ist eine Kopie von `.env.example`, der dokumentierte Build backt den Platzhalter ein, und `CompanionClient.configured` ist damit wahr. Ohne Einwilligung geht nichts raus (`_initCompanion` prüft das). Mit eingeschaltetem Schalter gehen Einwilligung und Telemetrie an diese Adresse, und `workers.dev` gehört weder Felix noch OpenStrap. Das Hochladen der ganzen Datenbank ist durch `kHealthDataContributionEnabled=false` zusätzlich gesperrt. Dasselbe gilt für `BACKEND_URL` beim Altkonto-Import. Abhilfe: leere Werte.

**Weitere Abflüsse:** `tiles.dart:93` und `off_lookup.dart:58` melden sich bei OpenStreetMap und Open Food Facts als `OpenStrap/1.0`. Takt tritt dort unter fremdem Namen auf.

## Regressionen und Lizenz

- **MoreForTodayScreen:** verträglich mit Live-Strom und Sync. Der alte Screen hält keinen HR-Strom, der Puls schließt beim Push, `syncNow` serialisiert über `_syncBurst`. Ein Doppeltitel aus AppBar und Home-Kopf bleibt. Risiko: Der Heute-Tab bleibt darunter gemountet und bestätigt weiter. Bearbeitet Felix einen Vorschlag über den alten Weg, während Auto-Bestätigen läuft, meldet `_check` „schon erledigt", und seine Änderung geht still verloren.
- **Benachrichtigung „Did you work out?":** Sie feuert weiter (`derivation_engine.dart:6456`, englisch, nicht lokalisiert), führt aber auf einen Vorschlag, der längst bestätigt ist. Das widerspricht „ohne Bestätigung".
- **`_Shell.build`** setzt `taktTodayVisible` im Build (`app.dart:614`) und löst damit Listener aus. Nur gelesen. Ein Fehler zeigte sich nicht, sauber ist es aber nicht.
- **AGPL:** `LICENSE` und `NOTICE` sind unverändert, Takt nennt Herkunft und Lizenz. Es fehlen ein Änderungshinweis mit Datum (§5a) und Copyright- sowie Haftungsausschluss-Hinweis in der App (§5d), die Hinweisseite liegt bei OpenStrap. Zur Quellcode-Pflicht siehe A16.
- **Marke, Repo statt App:** `README.md` bettet unterhalb des Takt-Blocks das Banner „OpenStrap Edge" ein. `PRIVACY.md`, `SECURITY.md`, `DONATE.md`, `.github/FUNDING.yml` und die Issue-Vorlagen sprechen weiter für OpenStrap. `TRADEMARKS.md` verlangt, Logo und Branding zu ersetzen.
- **Abweichung von der Architektur:** Die „Merkliste erkannt" gibt es nicht, „erkannt" hängt am ID-Präfix `suggestion:`. Das funktioniert, ist aber nicht dokumentiert. Archivo gibt es nicht. `pult_tokens.dart` hält rohe Farben außerhalb von `theme.dart`, entgegen der Konvention in `CLAUDE.md`. Der Heute-Tab nutzt `MaterialPageRoute` statt `go()`, Screens färben sich beim Themenwechsel daher nicht um.

## Reihenfolge der Korrekturen

1. F1: Vorschlag erst bestätigen, wenn die Einheit beendet ist, oder die Session beim Wachsen nachziehen. Das braucht eine Entscheidung von Felix, weil es „sofort sichtbar" berührt.
2. F2: Art-Auswahl aus dem Heute-Tab, zumindest über den bestehenden Weg `setSessionType`.
3. F3: `_load` aus `didChangeDependencies` oder post-frame, mit Token und Fehlerbehandlung.
4. F4 und F5: Start immer auf Heute, Neuladen und Rebuild beim Zurückkommen.
5. S1, S2 und die sichtbaren Reste aus A15.
6. `git push` vor jeder Weitergabe (A16).
7. Tests, die `TaktTodayScreen` wirklich bauen, damit F3 künftig auffällt.
