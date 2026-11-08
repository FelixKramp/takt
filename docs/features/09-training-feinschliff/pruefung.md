---
feature: 09-training-feinschliff
geprueft: 2026-11-08
stand: HEAD adafc8f9 („09: Sportart-Wahl im Takt-Design, Pulskurve ablesen, Puls beim Nachtragen, Pulsabfall erklaert“)
pruefer: unabhängiger Prüfer-Agent (hat nichts davon gebaut, plan.md nicht gelesen)
---
# Prüfung: Training, Feinschliff (Feature 09)

## Grundlage
- Gelesen: `spec.md` und `architektur.md` von Feature 09, `CLAUDE.md`, Spec von Feature 02 (B5) und
  Feature 08. `docs/architektur.md` gibt es im Repo nicht. `plan.md` von 09 nicht gelesen.
- Code: `lib/takt/detail/hr_scrub.dart`, `lib/ui2/activity/picker.dart`, `summary.dart`,
  `log_workout.dart`, `workout_screen.dart` (`taktRecentSports`, `_denseMinutes`),
  `takt_today_screen.dart`, `takt_text.dart`, dazu `Scrubber` (`grammar.dart`),
  `LocalRepositoryImpl.getWorkout`/`_minuteHrCurve` und `validateManualWindow`.
- `flutter test test/takt`: **209 Tests, alle grün** (ohne eigene Prüftests).
- `flutter analyze`: in `lib/` keine Befunde. Ein `info` in `test/takt/workout_takt_test.dart:159`
  (geschweifte Klammern), stammt aus Commit e60f4b4b (Feature 08), nicht von 09.
- Gesamtlauf `flutter test`: siehe Abschnitt „Regressionen“.
- Bildschirmfotos `TAKT_SHOTS=1 flutter test test/takt/shots_test.dart --plain-name "Feature 09"`
  neu erzeugt (`sportart`, `training_ablesen`, `nachtragen_puls`), zugeschnitten und angesehen.
- Eigene Wegwerf-Tests unter `test/takt/` (danach gelöscht; die eigenen Fotos `build/shots/pz_*.png`
  liegen noch dort, weil das Löschen im Build-Ordner nicht erlaubt war), mit echten Schriften,
  deutscher Sprache und 24-h-Uhr:
  - Widget-Tests für Sportart-Wahl, Übersicht und Nachtragen: Breiten 320/360/390 px, Textgröße
    1,0/1,3/2,0, hell und dunkel; Streifen-Durchlauf (Bruchteil 0,05 bis 0,95 in 0,01-Schritten)
    über alle Hüllen und über Zifferntexte ohne Hülle; senkrechtes, waagerechtes, schräges und
    zitterndes Wischen auf der Kurve in der scrollenden Liste; veraltete Ladeantworten mit
    `Completer`; Mittelung pro Minute; Zeitraum 23:30 bis 00:30; „Beginn hier“ hinter dem Ende und
    „Ende hier“ vor dem Beginn; Ende in der Zukunft; Ladeantwort, die nie kommt; Schließen während
    des Ladens; kaputte Zeitstempel und Pulswerte; nur eine Minute Puls; Kurve ganz ohne Messung;
    nur zwei Werte; Übersicht ohne Erholungswert; Screenreader-Wert; Beginn über die Android-Uhr
    ändern (Eingabemodus des Zeitwählers).
  - Mit echter Datenbank (sqflite ffi, `TaktTodayScreen` wie `today_screen_test.dart`): Training,
    dessen Puls erst 5 Minuten nach dem Beginn einsetzt; offene Erkennung antippen; Gruppe „Sport“
    aufklappen, Handball wählen; Stift in der Übersicht, auch als Doppeltipp; `taktRecentSports`
    mit geschlossener Datenbank und ohne `AppState`.

## Ergebnis
✅ 10 · ❌ 3 · ⚪ 1

| ID | Ergebnis | Begründung |
|---|---|---|
| W1 | ❌ | Kopf „sportart wählen“ mit Zurück-Pfeil, Suchzeile, „Zuletzt“/„Häufig“ und Gruppen als schlichte Zeilen ohne bunte Kästchen und Sportsymbole: erfüllt (Foto `sportart`, echte DB: Stift → `ActivityPicker` unter `TaktLook`, „Zuletzt“ sichtbar). **Die Kalorien-Erklärung fehlt aber auf dem Weg, den W1 beschreibt.** Sie erscheint nur mit `weightKg`, und `_changeType` in `summary.dart` gibt das Gewicht nicht weiter (`ActivityPicker(recent: recent, onPick: …)`), obwohl `ActivitySummary.weightKg` vorliegt. Reproduktion: `ActivitySummary(handball(), weightKg: 75)` unter `TaktLook`, Stift (`takt-workout-edit`) antippen → `takt-pick-note` 0-mal gefunden. Mit echter DB ebenso. Der Repo-Test „W1: Takt-Kopf … Kalorien-Erklärung als Zeile“ baut den Picker direkt mit `weightKg: 75` und trifft den echten Weg deshalb nicht. |
| W2 | ✅ | Suche („handb“ → Handball) und Gruppe aufklappen → Sportart antippen rufen dasselbe `onPick` wie bisher. Echte DB: offene Erkennung → Gruppe „Sport“ → Handball → Liste zu, zurück auf Heute, „Handball“ steht dort. Suchlogik identisch zur alten Liste. Siehe Hinweis 3 (Doppeltipp). |
| W3 | ✅ | Echte DB, Erkennung noch nicht gespeichert, antippen: `ActivityPicker` mit „sportart wählen“, `takt-back`, „Häufig“, Gruppen. `_pickSport` legt `TaktLook` um die Route und liegt hinter der `_opening`-Sperre aus Feature 08. Kein Repo-Test prüft hier das Takt-Design (A9 sucht nur nach einem `TextField`). |
| W4 | ❌ | Antippen, Wischen, Loslassen funktionieren: senkrechte Linie folgt, Uhrzeit und Puls in Doto, Wert bleibt nach dem Loslassen (Repo-Test und eigener Gestentest). **Die Uhrzeit ist aber falsch, wenn der Puls des Trainings nicht in der ersten Minute beginnt.** `TaktHrScrub` rechnet `t0 = r.start` plus Index in Minuten. Die Kurve gespeicherter Trainings kommt aus `_denseMinutes` (`workout_screen.dart`), und dort ist Index 0 die Minute der **ersten Pulsmessung**, nicht der Trainingsbeginn; fehlende Minuten am Anfang werden nicht vorn, sondern hinten aufgefüllt. Reproduktion mit echter DB: Erkennung 00:05–00:35, Pulsdaten in `decoded_onehz` erst ab 00:10 (170 bpm bis 00:20, danach 110), nach dem automatischen Speichern antippen → Übersicht → ganz links tippen: Anzeige „00:05“ mit 170 bpm, richtig wäre 00:10. Index 12 zeigt „00:17, 110 bpm“, tatsächlich 00:22. Alle Zeiten sind um die Lücke am Anfang verschoben (hier 5 Min.). Das passiert, sobald das Band in den ersten Minuten nicht anliegt oder nichts liefert. Die Repo-Tests nutzen eine Kurve, die genau am Beginn startet, und können das nicht finden. |
| W5 | ✅ | Frisch offen: „Kurve antippen oder wischen“, `selectedX` null. Minute ohne Messung: „–“ und „keine Messung“. Screenreader: Wert „Nichts ausgewählt“, Schritt nach rechts „16:57, 118 bpm“. Kurve ganz ohne Messung oder mit zwei Werten: kein Absturz. Überlauf bei Textgröße 2,0 siehe Hinweis 1. |
| W6 | ✅ | Abfrage genau von Beginn −30 bis Ende +30 Min. (Test und eigene Prüfung, auch 23:30–00:30 → 23:00–01:00, 120 Punkte, Index 60 = „00:00“). Zeitraum hinterlegt (`takt-hr-window`, hell und dunkel sichtbar). Karte zieht mit: über die Knöpfe (Repo-Test), über die Android-Uhr (eigener Test: Beginn 17:15 → neue Abfrage 16:45–18:45) und über das Datum (Code: `_pickDate` lädt neu). Mittelung pro Minute: 100 und 140 in derselben Minute → 120; Werte ≤ 0 und Zeitstempel außerhalb werden verworfen. Veraltete Antworten: drei Anfragen, die neueste zuerst beantwortet, dann eine alte mit 50 bpm → die alte wird verworfen, Kurve und Zeiten bleiben richtig. |
| W7 | ✅ | Ablesen wie W4 (Uhrzeit hier richtig, weil die Kurve selbst ab Beginn −30 Min. aufgebaut wird). Knöpfe „Beginn hier“/„Ende hier“ erscheinen erst nach dem Antippen, setzen nur die eine Zeit, die andere bleibt (Repo-Test und eigener Test). Über Mitternacht: „Ende hier“ auf 00:10 → „00:10, am nächsten Morgen“, Dauer 40 min, Speichern aktiv. |
| W8 | ✅ | Keine Daten, Lesefehler und Zeitraum > 12 h zeigen die graue Zeile, Speichern bleibt aktiv. Ohne Abfrage bei > 12 h (auch beim Öffnen von „Zeiten ändern“ mit > 12 h kein Fehler). |
| W9 | ✅ | „Pulsabfall nach 1 Min.“, Wert „16“ in Doto mit „bpm“, Erklärung grau darunter, in Hülle. Ohne Erholungswert keine Zeile und keine Erklärung. Hell und dunkel angesehen. Siehe Hinweis 8. |
| Randfall ungültig | ✅ | „Beginn hier“ auf 19:15 bei Ende 19:00 und „Ende hier“ auf 17:45 bei Beginn 18:00: Speichern ausgegraut, Grund steht darüber. Danach „Ende hier“ hinter dem Beginn → wieder gültig. Ende in der Zukunft ebenso abgelehnt. Siehe Hinweis 4 (englischer Grund). |
| Randfall > 12 h | ✅ | Siehe W8, Repo-Test plus eigener Test. |
| Randfall ohne Takt-Haut | ✅ | Ohne `TaktLook`: Liste mit `NavBar` (OpenStrap), Übersicht ohne `takt-hr-scrub`, ohne Hinweiszeile, ohne „Pulsabfall“; Nachtragen ohne Pulskarte und **ohne** Datenbankabfrage. |
| Projektregel B5 (CLAUDE.md, Feature 02) | ❌ | „Jede Zahl im Takt-Design steht in einem `StripeDodge`.“ Die Anzahl je Gruppe in der neuen Sportart-Wahl (12, 9, 20, 8, 9, 7, 7, 6) steht ohne Hülle (`_TaktPickRow`, `Text('$count', …)` neben dem `StripeDodge` des Namens). Reproduktion: `ActivityPicker` unter `TaktLook`, `TaktStripe.fraction` von 0,81 bis 0,87 → die Zahlen bei x ≈ 321–337 px (390 px breit) liegen unter dem Streifen, 41 Treffer. Das ist genau das rechte Drittel, in dem Felix' Strich sitzt. Alle anderen neuen Zahlen (Uhrzeit, Puls, „16“, Achsen) stehen in Hüllen und weichen aus: 0 Treffer über den ganzen Durchlauf in Übersicht und Nachtragen. |
| Gefühl am Gerät | ⚪ | Wie sich Wischen in der scrollenden Liste mit dem echten Finger anfühlt, lässt sich nur am Handy beurteilen. Gemessen ist, was im Test messbar ist (Hinweis 2). |

## Hinweise (kein ❌, aber verbesserungswürdig)
1. **Überlauf der Ablesezeile bei Textgröße 2,0** (`hr_scrub.dart:120`, `Row` mit Uhrzeit, `Spacer`
   und Puls). Übersicht bei 320 px: normale Minute 17 px, Minute ohne Messung 93 px zu breit
   („keine Mes…“ abgeschnitten, Foto angesehen). Bei 360 px mit „keine Messung“ 53 px. Nachtragen bei
   320 px: 17 px. Bei Textgröße 1,0 und 1,3 auf 320/360/390 px kein Überlauf, hell und dunkel.
   Picker auf allen Größen ohne Überlauf.
2. **Wischen und Scrollen greifen ineinander.** `Scrubber` hört über einen `Listener` mit und nimmt
   nicht an der Gestenauswahl teil. Folgen, gemessen in der Übersicht (Höhe 700 px): Waagerechtes
   Wischen mit ±3–4 px Zittern scrollt nicht und die Minute folgt dem Finger (gut). Schräges Wischen
   (etwa 20°) scrollt die Seite um 100 px mit, die Minute folgt trotzdem. Umgekehrt setzt jedes
   Scrollen, das auf der Kurve beginnt, eine Minute; beim Nachtragen erscheinen dabei „Beginn hier“
   und „Ende hier“, und alles darunter springt nach unten (Zug von 150 px auf der Kurve: Liste
   scrollt 150 px, Knöpfe sichtbar). Ein waagerechter Drag-Erkenner, der das Wischen für sich
   beansprucht, würde beides trennen.
3. **Doppeltipp auf den Stift öffnet zwei Listen.** `_changeType` wartet jetzt vor dem `push` auf
   `taktRecentSports` (Datenbank), ohne Sperre. Echte DB, zwei Tipps im Abstand von 40 ms → zwei
   `ActivityPicker` übereinander. Wählt man dann eine Sportart, schließt der zweite Aufruf mit seinem
   `pop` die untere Liste statt der Übersicht: man landet auf der Übersicht, nicht auf Heute (W2).
   Im Test ist das Zeitfenster künstlich lang, am Gerät so lang wie die Abfrage. Heute (`_pickSport`)
   ist durch `_opening` geschützt.
4. **Der Grund bei „Ende hier“ vor dem Beginn ist englisch:** „The end time has to be after the start
   time.“ unter dem deutschen Titel „Dieser Zeitraum lässt sich nicht speichern“ (ebenso „That window
   hasn't happened yet.“). Der Text kommt unverändert aus `manual_session.dart`, die Spec sagt „wie
   bisher“. Neu ist, dass dieser Fall jetzt erreichbar ist: Über die Android-Uhr rollt ein Ende vor
   dem Beginn auf den nächsten Tag, über „Ende hier“ nicht.
5. **Rechte Achsbeschriftung beim Nachtragen** ist Ende +30 Min. (z. B. „19:30“, über Mitternacht
   „01:00“), der letzte Punkt der Kurve liegt eine Minute davor (19:29 bzw. 00:59).
6. **Ladezustand ohne Ende:** Kommt die Antwort der Datenbank nie, bleibt eine leere 60-px-Karte ohne
   Hinweis stehen. Speichern bleibt möglich, nichts stürzt ab. Schließen während des Ladens: kein
   Fehler.
7. **„Zuletzt“ enthält automatisch gespeicherte Erkennungen ohne Sportart** (echte DB:
   `taktRecentSports` → `[Other]`). Wer gerade eine solche Erkennung umbenennen will, sieht sie ganz
   oben. Fällt die Datenbank aus oder fehlt `AppState`, kommt sauber „Häufig“.
8. **W9 hängt an einem englischen Textvergleich** (`s.$1 == 'HR recovery'` in `_taktStats`). Ändert
   OpenStrap die Beschriftung, steht ohne Fehler wieder „bpm in 60 s“ da. Kein Test würde das
   melden, außer dem W9-Test über die Fixture.
9. **Doc-Kommentar verrutscht:** `taktRecentSports` wurde zwischen den Kommentar von
   `taktWorkoutResult` („TAKT (Feature 08, T1): die Übersicht eines gespeicherten Trainings …“) und
   die Funktion eingefügt. Der Kommentar steht jetzt über der falschen Funktion.
10. **Rohe Größen in `lib/ui2`:** `Icon(…, size: 16)` in `_TaktPickRow`, `SizedBox(height: 60)` und
    `height: 110` in `log_workout.dart`. Keine rohen Farben, keine ungegateten `Duration(` in
    `lib/ui2` (die Drehung nutzt `motion(c, Motion.base)`).
11. **Testlücken:** Der W1-Test trifft den echten Weg nicht (Gewicht direkt gesetzt). Für W3 prüft
    kein Test das Takt-Design. Die W4-Uhrzeit wird nur mit einer Kurve getestet, die am Beginn startet.
    Doppeltipp auf den Stift, Mittelung pro Minute, Mitternacht und veraltete Antworten haben keine
    Repo-Tests.

## Sicherheit und Robustheit
- Leere, kaputte oder fehlende Daten: keine Kurve, nur Nullen, ein Wert, zwei Werte, negative und
  ferne Zeitstempel, Puls ≤ 0 oder 300: kein Absturz, keine Ausnahme.
- Datenbankfehler: Lesefehler beim Nachtragen → graue Zeile (W8). `taktRecentSports` fängt Fehler
  und fällt auf „Häufig“ zurück.
- Keine Endlosschleife: Nachladen nur bei Zeitänderung, über einen Zähler entkoppelt; > 12 h fragt
  gar nicht erst.
- Tastatur und Fokus: Die Suche öffnet die Tastatur nicht von selbst (Fokus nach dem Öffnen auf dem
  Scope, nicht im Textfeld). Im Nachtragen gibt es kein Textfeld.
- `setState` nach `dispose`: durch `mounted`-Prüfung abgefangen (Test: Schließen während des Ladens).

## Regressionen
- Feature 08: Repo-Tests T1, T2, T4 bis T10 grün (`workout_takt_test.dart`, `today_screen_test.dart`).
  T5 (orange Kurve) gilt auch mit `TaktHrScrub` (`Pult.orangeFor`). T6 wurde mit Spec-Änderung auf
  „Pulsabfall nach 1 Min.“ umgestellt, die übrigen vier Zeilen unverändert (Foto). T9 Grund und
  ausgegrauter Knopf unverändert über der neuen Pulskarte. T11 (Speichern): Speicherweg unverändert,
  die Pulskarte greift nicht ein; mit echter DB wird nach der Sportart-Wahl gespeichert und Heute
  zeigt sie.
- Aktivität-Tab ohne Takt-Haut: `workout_screen.dart` öffnet `ActivityPicker` weiter ohne
  `TaktLook` → OpenStrap-Liste mit `NavBar` und Symbolen; `ActivitySummary` ohne `TaktLook` zeichnet
  die alte `ChartFrame`, keine Ablesezeile, „HR recovery“ wie bisher; `LogWorkout` ohne `TaktLook`
  fragt keinen Puls ab.
- Gesamtlauf `flutter test` (mit den Prüftests): 7293 grün, 28 übersprungen, 7 rot. Keiner der
  roten Tests bindet eine Datei von Feature 09 ein, und 09 hat keine `.arb`-Datei geändert:
  `health_workout_export_delete_gate_test.dart` (bekannt, auch auf altem Stand rot);
  `settings_report_l10n_test.dart` ×4 (es/fr/hi/zh: `reportContactLabel`, `reportContactHint`
  fehlen in den Übersetzungen); `month_grid_test.dart` „strain has no better side“ (30 erwartet,
  29 erhalten) und `compute_freshness_meta_test.dart` „no row for today“, beide einzeln
  reproduzierbar und vermutlich vom heutigen Datum abhängig. `ui2_wellness_meds_not_due_test.dart`
  war in diesem Lauf grün.

## Zusammenfassung der offenen Punkte
1. ❌ **W4:** Falsche Uhrzeit in der Ablesezeile, sobald der Puls nach dem Trainingsbeginn einsetzt
   (alle Minuten um die Anfangslücke verschoben). Ursache: `t0 = r.start`, aber `_denseMinutes`
   zählt ab der ersten Messung.
2. ❌ **W1:** Kalorien-Erklärung fehlt über den Stift, weil `_changeType` `weightKg` nicht an die
   Liste gibt.
3. ❌ **B5:** Gruppenzahlen in der Sportart-Wahl ohne `StripeDodge`, liegen bei Streifen im rechten
   Drittel unter dem Strich.
4. Hinweise 1 bis 3 (Überlauf bei Textgröße 2,0, Wischen gegen Scrollen, Doppeltipp auf den Stift)
   sind die wichtigsten der übrigen Punkte.

## Runde 2
geprüft: 2026-11-08 · stand: HEAD f18c8880 („09: Pruefbefunde behoben …“) · Prüfer: zweiter
unabhängiger Prüfer-Agent (hat nichts gebaut, `plan.md` nicht gelesen)

### Grundlage
- Gelesen: `spec.md` (09), Runde 1 oben, `CLAUDE.md`, Spec 08, Diff `git show HEAD`.
- `flutter test test/takt`: **219 Tests, alle grün**. `flutter analyze lib test/takt`: nur das
  bekannte `info` in `workout_takt_test.dart:159` (Feature 08).
- Fotos `sportart`, `training_ablesen`, `nachtragen_puls` neu erzeugt und angesehen: sauber, keine
  Abschnitte, Ablesezeile richtig ausgerichtet.
- Eigene Wegwerf-Tests unter `test/takt/` (danach gelöscht, `git status` sauber), echte Schriften,
  Deutsch, 24 h:
  - **Echte Datenbank** (sqflite ffi, `TaktTodayScreen` wie `today_screen_test.dart`, Profil mit
    75 kg): Erkennung 00:05–00:35, Puls in `decoded_onehz` erst ab 00:10 (170 bis 00:20, danach 110),
    automatisch gespeichert; direkt über `taktWorkoutResult` → `_detailOf` und über Antippen auf Heute.
    Dann Stift als Doppeltipp (40 ms), Suche „Handball“, Wahl, zurück auf Heute; `taktRecentSports`
    vor und nach der Wahl. Zweiter Fall: offene Erkennung antippen (W3).
  - Widgets: senkrecht, senkrecht mit Zittern, waagrecht mit ±4 px Zittern, schräg 20° und 45°,
    Tippen, Screenreader-Aktionen (increase/decrease/tap/scrollLeft/scrollRight), jeweils in
    scrollender Übersicht (Höhe 700) und im Nachtragen; Überlauf 320/360 px × Textgröße 1,0/1,3/2,0
    × hell/dunkel; Streifen-Durchlauf 0,05–0,95 in 0,01-Schritten über Übersicht, Nachtragen und
    Sportart-Wahl bei 320/390 px und Textgröße 1,0/2,0 plus Suche nach Zahlen ohne Hülle;
    hängende Abfrage (`Completer` ohne Antwort), Schließen währenddessen; Gründe Zukunft,
    Überschneidung, Ende vor Beginn, englische Sprache; alles ohne `TaktLook`.

### Die drei ❌ aus Runde 1
| ID | Ergebnis | Begründung |
|---|---|---|
| W4 Uhrzeit | ✅ | Echte DB: `taktWorkoutResult` liefert `hrFrom` = 00:10, 31 Punkte. In der Übersicht: ganz links „00:10“/170, Index 9 „00:19“/170, Index 10 „00:20“/110, Index 12 „00:22“/110 (Runde 1: 00:05 und 00:17). Siehe Hinweis 1 zum rechten Rand. |
| W1 Kalorien über den Stift | ✅ | Echte DB mit Gewicht im Profil: Stift → `takt-pick-note` da. Repo-Test geht jetzt über den Stift. |
| B5 Gruppenzahlen | ✅ | Alle Zahlen der Sportart-Wahl in einer Hülle (0 ohne Hülle). Durchlauf 320/390 px, Textgröße 1,0 und 2,0: 2730 Ziffern geprüft, 0 Treffer unter dem Streifen. |

### Behobene Hinweise aus Runde 1
| Punkt | Ergebnis | Begründung |
|---|---|---|
| Senkrecht scrollen über der Kurve | ✅ | Übersicht: Zug 150 px auf der Kurve scrollt die Seite um 130 px, Hinweis „Kurve antippen oder wischen“ bleibt, keine Minute gesetzt; auch langsam mit ±2 px Zittern. Nachtragen: Seite scrollt, „Beginn hier“/„Ende hier“ erscheinen nicht. |
| Waagrecht wischen, Tippen | ✅ | Waagrecht mit ±4 px Zittern: Minute folgt, Seite scrollt nicht (0 px). Schräg 20° und 45°: liest ab, Seite scrollt nicht. Tippen Mitte „17:24“/122, rechter Rand „17:51“. Nachtragen: Wischen setzt Minute, Knöpfe erscheinen. |
| Screenreader-Schritte | ✅ | Knoten „HERZFREQUENZ“, Wert „Nichts ausgewählt“, Schritt hoch → „16:57, 118 bpm“, nochmal → 16:58, runter → 16:57, am Anfang bleibt es bei 16:57. Siehe Hinweis 3. |
| Überlauf 320/360 px, Textgröße 2,0 | ✅ | Kein Überlauf in Übersicht (normale Minute und „keine Messung“, hell und dunkel, auch 1,0/1,3), Nachtragen (mit Knöpfen und Grund) und Sportart-Wahl. Bei 320 px/2,0 wird die Pulsziffer auf etwa 88 % verkleinert, lesbar. Alle Zahlen weiter in Hüllen, Streifen-Durchlauf 0 Treffer (Übersicht 22022, Nachtragen ~11000 Ziffern). |
| Doppeltipp auf den Stift | ✅ | Echte DB, zwei Tipps im Abstand von 40 ms: eine Liste; nach der Wahl zurück auf Heute, dort „Handball“. |
| Deutsche Fehlergründe | ✅ | „Das Ende muss nach dem Beginn liegen.“ (Ende hier vor Beginn, Speichern aus), „Dieser Zeitraum liegt noch in der Zukunft.“, „Das überschneidet sich mit einem gespeicherten Training.“. Englische Sprache behält „That window hasn't happened yet.“. |
| Timeout bei hängender Abfrage | ✅ | Nach 9 s noch leer, nach 11 s die graue Zeile aus W8, Speichern aktiv. Schließen während des Wartens: keine Ausnahme. |
| „Other“ nicht unter Zuletzt | ✅ | Echte DB: nach automatischem Speichern `taktRecentSports` → `[]`, Liste zeigt „Häufig“ statt „Zuletzt“; nach Wahl von Handball → `[Handball]`. |
| Doc-Kommentar `taktWorkoutResult` | ✅ | Steht wieder über der richtigen Funktion. |

### Regressionen W1–W9, Randfälle, Feature 08
| ID | Ergebnis | Begründung |
|---|---|---|
| W1 | ✅ | Siehe oben, Foto `sportart`. |
| W2 | ✅ | Repo-Tests Suche/Gruppe; echte DB: Wahl über den Stift landet auf Heute. |
| W3 | ❌ | Takt-Kopf, Suche, „Häufig“, Gruppen: erfüllt. **Die Kalorien-Erklärung fehlt aber**, obwohl W3 „dieselbe Sportart-Wahl“ verlangt und W1 die graue Zeile dazuzählt. `_pickSport` in `takt_today_screen.dart` baut `ActivityPicker(recent: recent, onPick: …)` ohne `weightKg`, obwohl `_open` das Gewicht direkt davor lädt (`weight`) und nur an `taktWorkoutTarget` gibt. Reproduktion: echte DB, Profil `weight_kg: 75`, offene Erkennung (lastRecordAt = Ende + 60 s) antippen → `takt-pick-note` 0-mal; über den Stift derselben Sitzung 1-mal. War in Runde 1 schon so und wurde dort übersehen (gleiche Art Befund wie W1 in Runde 1). |
| W4 | ✅ | Siehe oben. Hinweis 1. |
| W5 | ✅ | Hinweistext frisch offen, „–“/„keine Messung“, Screenreader „Nichts ausgewählt“. |
| W6 | ✅ | Repo-Tests (Abfrage −30/+30 Min., hinterlegter Zeitraum, Karte zieht mit), Foto `nachtragen_puls`. Mittelung pro Minute jetzt mit Repo-Test. |
| W7 | ✅ | Knöpfe erst nach Ablesen, setzen nur eine Zeit (Repo-Test, eigener Wisch-Test). |
| W8 | ✅ | Graue Zeile ohne Daten und jetzt auch nach Timeout. |
| W9 | ✅ | Foto `training_ablesen`: „Pulsabfall nach 1 Min.“, „16 bpm“, Erklärung grau. |
| Randfälle ungültig, > 12 h | ✅ | Repo-Tests grün, Grund jetzt deutsch. |
| Ohne Takt-Haut | ✅ | Übersicht ohne `takt-hr-scrub`, ohne Hinweis, ohne „Pulsabfall“; Liste mit `NavBar`; Nachtragen ohne Pulskarte und ohne Abfrage (0 Aufrufe). |
| Feature 08 | ✅ | Repo-Tests T1–T11 grün; echte DB T1/T3 (Antippen → Übersicht, Stift → Sportart → Heute). Fotos: Kopf, orange Kurve, Zeilen in Punktziffern, Zonen und Fußnote unverändert. |
| Gefühl am Gerät | ⚪ | Wischen gegen Scrollen mit echtem Finger nur am Handy beurteilbar; im Test ist die Trennung jetzt sauber. |

### Hinweise Runde 2
1. **Rechter Rand der Kurve nach einer Anfangslücke liegt hinter dem Trainingsende.** `_denseMinutes`
   füllt hinten auf Trainingslänge auf, gezählt ab der ersten Messung. Echte DB (00:05–00:35, Puls ab
   00:10): ganz rechts steht „00:40“ mit „–“, die Minuten 00:35 bis 00:40 lassen sich ablesen, obwohl
   das Training um 00:35 endet. Die Achse sagt links „Start“, dort ist es aber 00:10, und die
   fehlenden Minuten 00:05–00:09 sind gar nicht auf der Kurve (W5 würde dort „keine Messung“ zeigen).
   Die abgelesenen Uhrzeiten selbst stimmen. Vorn statt hinten auffüllen (Index 0 = Beginn) würde
   beides beheben.
2. **W3 ohne Gewicht** (siehe ❌): `weight` aus `_open` an `_pickSport` durchreichen.
3. **Screenreader-Nebenwirkung des `GestureDetector`:** Der Kurvenknoten bietet zusätzlich `tap`,
   `scrollLeft` und `scrollRight` an. `scrollLeft` und `scrollRight` springen beide auf dieselbe
   feste Minute (17:24 → 17:36), egal in welche Richtung. `increase`/`decrease` funktionieren
   richtig. Mit `excludeFromSemantics: true` am `GestureDetector` wären nur die Slider-Aktionen übrig.
4. **Zeitgrenze über `Motion.tick * 10`:** inhaltlich eine Ladezeitgrenze, keine Animation; ein
   eigener Wert in `theme.dart` wäre klarer. Funktioniert wie beschrieben.
5. Testlücke: Kein Repo-Test prüft W3 mit Kalorien-Erklärung, und der W4-Test mit `hrFrom` setzt das
   Feld von Hand statt über `_detailOf`.

### Zusammenfassung Runde 2
✅ alle drei ❌ aus Runde 1 behoben, alle behobenen Hinweise bestätigt. Neu: ❌ **W3** — Kalorien-
Erklärung fehlt auf dem Weg über eine offene Erkennung (`_pickSport` ohne `weightKg`). Wichtigster
Hinweis: Kurve nach einer Anfangslücke reicht bis hinter das Trainingsende (Hinweis 1).

## Runde 3
geprüft: 2026-11-08/09 · stand: HEAD bf9a7ea9 („09: Kurve beginnt beim Trainingsbeginn, Gewicht auch
fuer offene Erkennungen, Version 0.3.2“) · Prüfer: dritter unabhängiger Prüfer-Agent (hat nichts
gebaut, `plan.md` nicht gelesen)

### Grundlage
- Gelesen: `spec.md` (09), Runden 1 und 2 oben, Diff `git show HEAD`, dazu `_denseMinutes`,
  `_firstHrAt`, `_detailOf`, `taktWorkoutResult` (`workout_screen.dart`), `getWorkout`/
  `_minuteHrCurve` (`local_repository_impl.dart`), `TaktHrScrub`, `_openWorkoutOnce`/`_pickSport`.
- `flutter analyze lib`: **keine Befunde**.
- `flutter test test/takt`: **216 grün, 3 rot**, alle drei in `today_screen_test.dart` (A8 „Abgeschlossenes
  Training wird gespeichert“, A8 „Am Ende der Berechnung …“, A9/T1/T3). Ursache ist die Uhrzeit des
  Laufs (00:04 Uhr), nicht 09: Die Tests legen ein Training 00:05–00:35 *heute* an, das um 00:04 in der
  Zukunft liegt, `validateManualWindow` lehnt das Speichern ab (`inFuture`), also bleibt die Erkennung
  offen. Dieselben Wege liefen in meinen eigenen Tests mit echter Datenbank vor Mitternacht grün. Siehe
  Hinweis 4.
- Eigener Wegwerf-Test `test/takt/zz_pruef3_test.dart` (danach gelöscht, `git status` sauber), echte
  Schriften, Deutsch, 24 h, **echte Datenbank** (sqflite ffi, `TaktTodayScreen` wie
  `today_screen_test.dart`, Profil `weight_kg: 75`, Puls als 1-Hz-Zeilen in `decoded_onehz`: 170 bpm in
  den ersten 10 Minuten ab der ersten Messung, danach 110). Kurve über den echten Ladeweg:
  automatisch speichern → `getWorkouts` → `taktWorkoutResult` → `_detailOf` → `ActivitySummary` unter
  `TaktLook`, linker und rechter Rand angetippt; einmal zusätzlich über Antippen auf Heute.
- Foto `training_ablesen` neu erzeugt und angesehen: unverändert sauber.

### Die Punkte aus Runde 2
| ID | Ergebnis | Begründung |
|---|---|---|
| W3 Kalorien bei offener Erkennung | ✅ | Echte DB, Profil 75 kg, offene Erkennung (lastRecordAt = Ende + 60 s) antippen → `ActivityPicker` mit „sportart wählen“, `takt-pick-note` 1-mal: „Kalorien sind geschätzt: MET-Wert mal Gewicht, verfeinert mit dem Puls.“ Danach Suche „Handball“ → Wahl → zurück auf Heute, „Handball“ steht dort, Erkennung bleibt offen (W2). Ohne Gewicht im Profil: keine Zeile, kein Fehler. |
| Kurve ab Trainingsbeginn (Hinweis 1) | ❌ | **Bei minutengenauem Beginn alles richtig, bei Beginn mit Sekunden und Lücke am Anfang ist jede abgelesene Uhrzeit eine Minute zu früh.** Ergebnisse siehe Tabelle unten. Ursache: `lead = hrFrom.difference(r.start).inMinutes` rundet ab, und `t0 = r.start` behält die Sekunden; `hrFrom` ist aber auf die volle Minute gerundet (`_minuteHrCurve`, `t = bucket * 60`). Reproduktion echte DB: Erkennung 00:05:30–00:35:30, Puls ab 00:10:00 → `hrFrom` 00:10:00, `lead` = 4 (4:30), `t0` = 00:05:30. Die erste Messung (Minute 00:10) wird als „00:09 / 170“ abgelesen, die letzte (Minute 00:35) als „00:34 / 110“, ganz rechts „00:35 / –“, obwohl das Band dort gemessen hat. Der Wechsel 170 → 110 (Minute 00:21) steht bei „00:20“. Vor diesem Commit (`t0 = hrFrom`) stimmte die Uhrzeit in diesem Fall, es ist also eine neue Abweichung. Betroffen sind Trainings mit Sekunden im Beginn und mindestens etwa 1,5 Minuten ohne Puls am Anfang: live gestartete Workouts (`workout_controller.dart`: `start = DateTime.now()`) und Erkennungen (`autoDetectWorkouts` liefert Sekunden). Nachgetragene Trainings (Uhr in Minuten) sind nicht betroffen. Abhilfe: `r.start` auf die volle Minute abrunden und daraus `lead` und `t0` rechnen. Der Repo-Test „W4: Kurve beginnt nach dem Trainingsbeginn“ nutzt einen minutengenauen Beginn und findet das nicht. |
| Screenreader (Hinweis 3) | ✅ | Kurvenknoten „HERZFREQUENZ“ bietet nur noch `increase` und `decrease` an (kein `tap`, `scrollLeft`, `scrollRight`). Wert „Nichts ausgewählt“, hoch → „16:57, 118 bpm“, hoch/runter → wieder 16:57. Tippen mit dem Finger liest weiter ab (Mitte „17:24“). |

Kurve über den echten Ladeweg (Training 30 Min., Achse „Start … 30:00“, 31 Punkte = Beginn bis Ende):

| Fall | links | erste Messung | rechts | Ergebnis |
|---|---|---|---|---|
| Beginn 00:05:00, Puls ab 00:10 (Lücke vorn) | 00:05 / – | 00:10 / 170 ✓, Wechsel 110 bei 00:20 ✓ | 00:35 / 110 | ✅ |
| Beginn 00:05:00, Puls bis 00:25 (Lücke hinten) | 00:05 / 170 | 00:05 ✓, letzte 00:25 ✓ | 00:35 / – | ✅ |
| Beginn 00:05:00, ohne Lücke | 00:05 / 170 | 00:05 ✓ | 00:35 / 110 | ✅ |
| Beginn 00:05:00, Lücke vorn und hinten | 00:05 / – | 00:10 ✓, letzte 00:25 ✓ | 00:35 / – | ✅ |
| Beginn 00:05:00, Messungen bis 00:45 (nach dem Ende) | 00:05 / – | 00:10 ✓ | 00:35 / 110 | ✅ (DB liest nur bis `end_ts`) |
| über Heute antippen, Lücke vorn | 00:05 / – | 00:10 ✓ | 00:35 / 110 | ✅ |
| Beginn 00:05:30, ohne Lücke | 00:05 / 170 | 00:05 ✓ | 00:35 / 110 | ✅ |
| Beginn 00:05:30, Puls ab 00:10 | 00:05 / – | **00:09** / 170 (richtig 00:10) | 00:35 / – (Minute 00:35 hat Puls) | ❌ |
| Beginn 00:05:30, Puls 00:10–00:25 | 00:05 / – | **00:09** (richtig 00:10), letzte **00:24** (richtig 00:25) | 00:35 / – | ❌ |
| Beginn 00:05:50, Puls ab 00:06:10 | **00:06** / 170 | 00:06 ✓ | **00:36** / – | Uhrzeiten ✓, siehe Hinweis 1 |

Ohne Absturz (synthetisch, `ActivitySummary` direkt): leere Kurve und eine Minute (mit und ohne
`hrFrom`) zeigen keine ablesbare Kurve, keine Ausnahme; nur leere Minuten mit Lücke vorn: „–“ an beiden
Rändern; `hrFrom` vor dem Beginn: Kurve ab `hrFrom`, Zeiten stimmen; Dauer 0 mit Lücke: kein Fehler.

### Regressionen W1–W9 (Stichprobe)
| ID | Ergebnis | Begründung |
|---|---|---|
| W1 | ✅ | Repo-Tests grün (Kopf, schlichte Zeilen, Stift öffnet die Wahl, Erklärung). |
| W2 | ✅ | Echte DB: Suche „Handball“ → Wahl → zurück auf Heute. Repo-Tests Suche/Gruppe grün. |
| W3 | ✅ | Siehe oben. |
| W4 | ❌ | Bei minutengenauem Beginn richtig, bei Beginn mit Sekunden und Anfangslücke eine Minute zu früh (siehe oben). Antippen, Wischen, Loslassen unverändert (Repo-Tests). |
| W5 | ✅ | Linker Rand bei Lücke vorn „–“ (in der Ablesezeile mit „keine Messung“, Repo-Test), Hinweis vor dem Antippen (Repo-Test, Foto). |
| W6–W8 | ✅ | Repo-Tests grün; `log_workout.dart` von diesem Commit nicht berührt. |
| W9 | ✅ | Foto `training_ablesen`: „Pulsabfall nach 1 Min.“, „16 bpm“, Erklärung grau. |

### Hinweise Runde 3
1. **Beginn mit Sekunden, Puls weniger als eine Minute später, aber in der nächsten Minute** (Beginn
   00:05:50, Puls ab 00:06:10): `lead` = 0, die Kurve beginnt bei 00:06 statt bei der Minute des Beginns,
   rechts steht „00:36 / –“ hinter dem Ende 00:35:50. Die Uhrzeiten stimmen. Dieselbe Abhilfe wie beim ❌
   (Beginn auf die Minute abrunden) behebt auch das.
2. **Nur leere Minuten werden hinten gekürzt.** Echte Messwerte nach dem Ende blieben stehen (synthetisch:
   55-Min.-Training mit 70 Werten → Kurve bis 18:11 unter der Achse „55:00“). Über die Datenbank nicht
   erreichbar, weil `hrSamplesInRange` bei `end_ts` aufhört; nur relevant, falls ein anderer Ladeweg
   dazukommt.
3. **`hrFrom` mindestens 24 h nach dem Beginn:** keine Auffüllung, aber `t0 = r.start` (weil `lead > 0`),
   die Zeiten wären dann um die Lücke verschoben. Über die Datenbank nicht erreichbar, rein theoretisch.
4. **`today_screen_test.dart` hängt an der Uhrzeit:** Zwischen 00:00 und 00:35 Uhr schlagen A8 (zweimal)
   und A9/T1/T3 fehl, weil das angelegte Training 00:05–00:35 von heute in der Zukunft liegt. Nicht von 09
   verursacht, aber jeder Lauf kurz nach Mitternacht wirkt wie eine Regression. Beginn z. B. auf
   „gestern“ oder relativ zu `now` legen.
5. **Testlücken:** Kein Repo-Test prüft W3 mit Kalorien-Erklärung über Heute (der Commit fügt keinen
   hinzu). Der W4-Test zur Anfangslücke nutzt einen minutengenauen Beginn und geht nicht über
   `_detailOf`; ein Fall mit Sekunden im Beginn fehlt.

### Zusammenfassung Runde 3
✅ W3 (Kalorien-Erklärung bei offener Erkennung) und Screenreader (nur noch Schritte hoch/runter)
behoben. Kurve ab Trainingsbeginn: bei minutengenauem Beginn in allen Fällen richtig (Lücke vorn,
hinten, beides, keine, Messungen nach dem Ende, über Heute), „Start“ und „30:00“ passen zu 31 Punkten,
nichts stürzt ab. Neu: ❌ **W4** — bei einem Beginn mit Sekunden (live gestartet oder erkannt) und einer
Lücke am Anfang ist jede abgelesene Uhrzeit eine Minute zu früh, weil `t0 = r.start` die Sekunden
behält, `lead` abrundet und `hrFrom` auf der vollen Minute liegt. Abhilfe: Beginn auf die Minute
abrunden.
