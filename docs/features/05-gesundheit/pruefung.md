# Prüfung: Gesundheit-Tab, Stress-Tageskurve, Tab-Leiste und Rahmen (Feature 05, nachträglich)

Unabhängige Prüfung. Stand: Arbeitsverzeichnis auf `main`, nichts committet. Geprüft habe ich
`lib/takt/health/takt_health_views.dart`, `lib/takt/stress/*`, die Diffs in `app.dart`,
`app_shell.dart`, `profile.dart`, `settings.dart`, `theme_controller.dart`, `ui2/theme.dart`,
`grammar.dart`, `header.dart`, `health_screen.dart`, `wellness_screen.dart`, `investigate.dart`
und die drei Testdateien. Am Code habe ich nichts geändert. Meine Wegwerf-Tests
(`test/takt/zz_pruef_gesundheit_*.dart`) und Bildschirmfotos sind gelöscht.

**Vorab: Es gibt keine Spec.** Feature 05 steht in `CLAUDE.md` als „idee“, `docs/architektur.md`
existiert nicht. Der Blueprint-Ablauf wurde übersprungen. Die Erwartungen unten leite ich selbst ab
(Kopfkommentare, vorhandene Tests, Spec 01, 02, 07). Sie sind keine freigegebenen Anforderungen.

## Ampel

| Bereich | Urteil |
|---|---|
| Gesundheit (Vitalwerte, Trends) | **nicht reif** |
| Stress-Tageskurve | **nicht reif** |
| Tab-Leiste und Einstellungen | **mit Nacharbeit** |

- **Gesundheit: nicht reif.** Die neue Vitalwerte-Ansicht (`TaktVitalsView`) mit Tages-Schalter ist nirgends
  eingebaut: Im Takt-Look zeigt der Gesundheit-Tab nur noch die Übersicht, die Unterreiter sind
  ausgeblendet. Damit sind Vitalwerte, „Erkunden“ und „Labore“ in der App nicht mehr erreichbar. Die Trend-Karten
  zeigen veraltete Werte ohne Datum.
- **Stress: nicht reif.** Die Rechnung nimmt die Tageshöchstfrequenz als Sportgrenze, wodurch die
  stärkste Belastung eines Tages ohne Training als „Aktivität“ aus der Stress-Statistik fällt. Fehlende Basiswerte werden
  durch erfundene Zahlen ersetzt (55 bpm, 185 bpm, 45 ms). Die Zeitachse der Kurve stimmt nicht mit den Beschriftungen überein,
  Blättern hat einen Wettlauf und bleibt am 25. Oktober hängen. Die Detailansicht verletzt B5.
- **Tab-Leiste/Einstellungen: mit Nacharbeit.** Die Leiste selbst läuft sauber und stürzt nicht. Aber
  „Training starten“ und weitere Funktionen sind jetzt unerreichbar, die Deep-Links zu Wasser und
  „Training vergessen“ pausieren still den Live-Puls auf Heute, und 11 bestehende Tests sind rot (sechs davon durch die
  Änderungen in diesem Bereich: Router, Appearance-Zeile, Einstellungen-Länge). Die bestehenden Einstellungen funktionieren.

## Testlauf

- `flutter test test/takt`: **275 bestanden, 0 Fehler.** Die Tests dieser Bereiche sind grün, prüfen aber
  nur die Bausteine einzeln (siehe G1) und nur bei 390 px mit Textgröße 1,0 und kleinen Datenmengen.
- `flutter analyze lib test/takt`: **keine Probleme.**
- `flutter test` (alles): **7278 bestanden, 28 übersprungen, 12 Fehler** (davon 1 mein Wegwerf-Test, der den Fehler G14 belegt).
  Von den 11 übrigen gehören 6 zu den Änderungen in diesem Bereich:
  - `ui2_router_test.dart` (2 Tests): erwartet `domainForTab(4) == activity`, jetzt `today`. Test nicht angepasst.
  - `thai_l10n_test.dart`, `language_picker_sheet_test.dart`, `ui2_onboarding_profile_test.dart`:
    `ProfileHomeView` liest neuerdings `ThemeController` (neue Appearance-Zeile in `profile.dart`);
    ohne diesen Provider fliegt `ProviderNotFoundException`. In der echten App gibt es den Provider (`main.dart`),
    die Tests nicht.
  - `ui2_gallery_test.dart` („and offers one once it is“): Die Zeile „Developer“ ist nicht mehr gebaut.
    Vermutlich weil die neue Gruppe „Körperalter & Studien“ die Liste verlängert (Ursache nicht isoliert,
    Vergleich gegen HEAD nicht möglich).
  - Nicht aus diesem Bereich: `settings_report_l10n_test` (es, fr, hi, zh: `reportContactLabel`,
    `reportContactHint` fehlen) und `health_workout_export_delete_gate_test`.

## Abgeleitete Erwartungen und Befund

Alle Erwartungen G1 ff. sind **von mir abgeleitet**, nicht freigegeben. Legende: ✅ erfüllt, ❌ verletzt
(mit Reproduktionsweg), ⚪ nicht prüfbar.

### Gesundheit

- **G1 ❌ Vitalwerte (Tages-Schalter, Tagespuls-Bereich, Atemfrequenz, Hauttemperatur, Tragedauer, HRV-Analyse)
  sind in der App erreichbar.**
  Weg: `grep -rn "TaktVitalsView\|TaktSubTabBar" lib` findet nur die Definition. In `health_screen.dart`
  gilt im Takt-Look `else if (takt) _overview(c, d)`, die Unterreiter sind mit `if (!takt)` ausgeblendet,
  `_select` lädt Vitalwerte im Takt-Zweig nie. Meine Kontrolle mit `HealthScreen` unter `TaktLook`
  und leerem Repo: Es erscheinen nur Körperalter, Trends, Stress, Konsistenz und „Psyche“. Die ganze Vitalwerte-Ansicht
  ist toter Code, den nur `health_takt_test.dart` in Isolation baut.
- **G2 ❌ Erkunden und Labore (manuelle Laborwerte) bleiben erreichbar.**
  Weg: wie G1. `_tabsOf(takt: true)` listet beide, aber die Leiste wird im Takt-Look nicht gezeichnet. Eine andere Tür
  dorthin gibt es nicht (`grep LabsData lib` nur in `health_screen.dart`). Laborwerte eintragen und löschen ist
  in der App nicht mehr möglich.
- **G3 ❌ Trend-Karten sagen, von wann der Wert ist.**
  Weg: Der große Wert ist `s.last`, der neueste gespeicherte Punkt. Die Upstream-Karte
  schreibt bei Rückstand „· Stand <Tag>“ (`daysBehind`, `healthAsOf`). `TaktTrendCard` hat das nicht: Nach drei Tagen ohne
  Sync steht der Ruhepuls von vor drei Tagen ohne Datum da. Der Tag fehlt auch in der Hauptzeile.
- **G4 ❌ Vitalwerte beziehen sich auf den gewählten Tag.**
  Weg (Code): `skinTemp` und `tempDevC` kommen aus `health.today`, nicht aus dem gewählten Tag. Beim Zurückblättern bleibt
  die Hauttemperatur von heute stehen. Zusätzlich beschriftet `_DayStepperHeader` den neuesten abgeleiteten Tag
  immer mit „Heute“, auch wenn der Tag Tage alt ist (der Fehler, den `VitalsData` im Kommentar selbst beschreibt).
  Beides in totem Code (G1), würde aber mit dem Einbau live.
- **G5 ✅ Tages-Schalter vorwärts/rückwärts, Grenzen.** `TaktDayStepper` arbeitet auf der Liste der abgeleiteten
  Tage: kein Tag in der Zukunft, Tage ohne Daten fehlen in der Liste, Pfeile an den Enden deaktiviert
  (bestehende Tests `sleep_header_test`, `wake_day_test`).
- **G6 ✅ Tage ohne Daten.** Ohne `lo/hi/resp/Temp/worn` zeigt die Vitalwerte-Ansicht die Karte „Nichts gemessen für
  diesen Tag“, bei Lesefehler eine Karte mit „Erneut versuchen“. Kein Absturz.
- **G7 ✅ Zahlen und Einheiten der Vitalwerte** (bpm, br/min, °C relativ, h m, ms, %). Im Test
  mit 14,6 br/min, +0,3 °C, 23h 0m. Kleinigkeit: „br/min“ ist englisch, deutsch wäre „AF/min“ oder „Atemzüge/min“.
- **G8 ❌ (klein) Tragedauer erfindet 0 %.** `coveragePct?.clamp(0,100) ?? 0.0`: Fehlt `coverage_pct`, steht
  „0 % des Tages getragen“ und ein leerer Balken, obwohl `worn_min` da ist. Soll „—“ oder weggelassen sein.
- **G9 ⚪/✅ Trends: Ruhepuls, HRV, Schlafdauer, Konsistenz mit 30-Tage-Kurve und üblichem Bereich.** Karten
  rendern (Test, 390 px), Band und Referenz kommen aus `usualRangeFor`. Ohne Daten erscheint „Noch kein Trend“.
  Kleinigkeiten: Beim Halten steht „Vor 0 Tagen“ / „Vor 1 Tagen“ (deutsch: „Vor 1 Tag“, „Heute“); die englische
  Fassung beginnt mit einem Leerzeichen (` 3 days ago`); die englische Konsistenz-Zeile sagt „Days with a score“, die deutsche
  „Sensoraufzeichnung“.
- **G10 ✅ Konsistenz** zählt Tage der letzten 30 (`daysWithData`, im Lader nach `from` gefiltert).

### Stress-Tageskurve

- **G11 ✅ Skala 0,0 bis 3,0 und Zonengrenzen <1 / 1–2 / ≥2.** Rechnung und `zone`-Getter stimmen
  (Test: HR 50→0,00; 70→0,71; 80→1,43; 90→2,14; 110→3,00, Ruhepuls 50).
- **G12 ✅ 5-Minuten-Raster.** Bins `t ~/ 300` (UTC-Epoche, gleich für HR und HRV; alle Zeitzonen sind
  Vielfache von 5 Minuten). Sommerzeit stört die Rechnung nicht, weil sie keine Tageslänge annimmt (25-Stunden-Tag: 300 Bins, getestet).
- **G13 ❌ Sport wird nicht als mentaler Stress gewertet, auch nicht in der Anzeige.**
  Statistik und Spitze lassen Sport und Schlaf aus (✅). Aber die Kurve zeichnet Sport-Bins mit dem Wert
  **2,5**, einem festgesetzten Anzeigewert, in Rot („hoch“). Beim Scrubben steht
  „2,5 / 3,0“ mit Pille. Weg: `compute` mit Workout 17–18 Uhr; die Handball-Stunde erscheint als roter Plateau-Block
  (gesehen im Bildschirmfoto der Detailansicht). Erfundener Wert, widerspricht dem Infotext.
- **G14 ❌ Die Sportgrenze ist begründet.**
  `hrrCut = rhr + 0.65 * (maxHr − rhr)` mit `maxHr` = **Höchstwert des Tages** aus `getDayHeart('max_hr')`, nicht die
  Höchstfrequenz der Person. Damit gilt an jedem Tag ohne Training das obere Drittel des Tagesbereichs als „Aktivität“.
  Weg: Bürotag, 60 Minuten Stressphase bei 100 bpm, Tageshöchstwert 100, Ruhepuls 55 → `activityMin 60,
  highStressMin 0, peakStress 0,0`. Mit `maxHr 185` dasselbe: `highStressMin 60, peak 2,5`. Die stärkste Belastung eines Tages
  ohne Sport wird also systematisch als Sport aussortiert. Der Kommentar sagt „75 % HRR“, der Code rechnet 65 %.
- **G15 ❌ Die Basis ist die eigene Ruhebasis; nie erfundene Werte (AGENTS.md, Regel 3).**
  - Fehlen Ruhepuls, Maximalpuls oder Basis-HRV, rechnet der Code mit **55 bpm, 185 bpm, 45 ms**
    (`restingHr ?? 55.0` usw.) und zeigt Zahlen, als wären sie gemessen. Weg: `compute(hrCurve: …)` ohne Basis: `hasData true,
    avg 0,5`; mit Ruhepuls 50 für dieselben Daten 0,86.
  - Auch mit Daten ist es nicht die Basis: `resting_hr` ist der Ruhepuls **dieser Nacht**, `rmssd` der Nacht-RMSSD.
    Der gleitende persönliche Wert liegt in `heart['baselines']` und wird nicht benutzt.
  - Die HRV-Bins entstehen nur in ruhigen Minuten tagsüber und werden mit dem Schlaf-RMSSD verglichen. Tag-HRV ist
    systematisch niedriger: HRV 38 gegen Basis 55 hebt den Wert in ruhigem Sitzen von 0,21 auf 0,54. Ein Messunterschied, kein Stress.
  - Die Gewichte (0,55 / 0,45), die Schwelle „10 bpm über Ruhe“ und die Spanne 42 bpm sind erfunden und nirgends
    begründet. Der Infotext spricht von „deinen persönlichen Ruhewerten“ und nennt weder Schätzung noch Herkunft
    der Skala, die als „Whoop-Skala“ kommentiert ist (kein Hinweis in der App, dass es ein eigenes Modell ist).
- **G16 ❌ Heute zeigt Heute.**
  `getDayTimeline('heute')` fällt auf den letzten kompletten Tag zurück, solange heute nicht abgeleitet ist
  (`_bundleForDate`), und liefert `date` mit. `loadForDay` ignoriert das. Weg (Stub-Repo wie `LocalRepositoryImpl`):
  `analysis.date == heute`, `hasData true`, erstes Sample von gestern 06:02. Karte auf Heute und Gesundheit zeigen gestern als
  „Heute“, „Aktuell“ und „Spitze“.
- **G17 ✅ Verhalten bei fehlender HRV.** Ohne HRV-Bin zählt nur die Herzfrequenz (Wert 0,21 gegen 0,54 mit HRV).
- **G18 ❌ (mittel) Wenig Daten und Lücken.** Jeder Bin zählt 5 Minuten, auch mit **einer** Sekunde Messung
  (zwei Einzelwerte im Abstand von 5 Stunden ergeben „10 Min gemessen“, `lowMin 10`). Keine Mindestabdeckung, keine
  Lücken-Anzeige in der Kurve. „9h 0m gemessen“ kann deutlich übertrieben sein.
- **G19 ❌ Zeitachse der Kurve.** Die Kurve verteilt die vorhandenen Samples **nach Index** über die Breite, die Beschriftung sagt
  „00:00 … 24:00“. Beginnen die Daten um 06:30 und enden um 22:00, liegt 06:30 am linken Rand
  (unter „00:00“). Weg: Detailansicht mit HR 06:30–22:00; Tippen am linken Rand zeigt „ZEITPUNKT 06:32“. Bei Datenlücken
  wird die Kurve zusammengeschoben.
- **G20 ❌ Scrubbing erreicht den ganzen Tag.** `context.findRenderObject()` ist der ganze Bildschirm, nicht das
  Diagramm. Weg: 390 px Bildschirm, Diagramm 324 px breit; Tippen am rechten Rand zeigt „19:17“ statt des letzten
  Messwerts (22:00). Die letzten rund 16 % sind unerreichbar. Der Hinweis „Gedrückt halten zum Prüfen“ stimmt nicht
  (Wischen oder Tippen, kein Halten nötig).
- **G21 ❌ Schnelles Blättern (Wiederholung).** `_load` hat keinen Versions-Schutz. Weg: zwei Mal schnell „zurück“, der
  erste Tag (11.11.→10.11.) antwortet langsam und leer, der zweite (09.11.) schnell mit Daten: Die Anzeige zeigt
  „2026-11-09“, nach der späten Antwort aber „Keine Daten“.
- **G22 ❌ Tag-Schalter und Sommerzeit.** `_shiftDay` rechnet `DateTime.parse(date).add(Duration(days: 1))`. Mit `TZ=Europe/Berlin`:
  `2026-10-25 + 1 Tag = 2026-10-25 23:00`, `dayLabelOf` ergibt wieder den 25.10. Wer auf den 25.10. zurückblättert, kommt
  mit „vor“ nicht mehr weiter (die Detailansicht lädt denselben Tag erneut). Dasselbe tritt jedes Jahr am Ende der Sommerzeit auf.
  Rückwärts und im Frühjahr geht es.
- **G23 ❌ Lesefehler sind von „keine Daten“ unterscheidbar.** `loadForDay` fängt jeden Fehler und gibt
  `empty()` zurück („Für diesen Tag liegen noch keine Herzfrequenzdaten vor“); kein Fehlerzustand, kein „Erneut versuchen“.
  Die Heute-Karte verschwindet dann einfach. Der Vitalwerte-Teil macht das besser.
- **G24 ✅ Robustheit der Rechnung.** NaN-Herzfrequenz, negative Werte, `maxHr` unter Ruhepuls,
  HRV-Basis 0, 300 Bins: kein Absturz. Nicht-numerische `t`-Werte würden im Cast fliegen, aber `loadForDay` fängt das (siehe G23).
- **G25 ✅ Schlaf wird getrennt:** Schlaf-Bins werden aus Statistik und Spitze ausgenommen, Wert 0 bis 0,9.
- **G26 ❌ Zwei verschiedene „Stress“-Zahlen.** Die Wellness-Karte „Stress level 62/100“ (Baevsky, nächtlich)
  öffnet jetzt die Tagesansicht „0,5 / 3,0“ (Herzfrequenz-Modell, tagsüber). Dasselbe Wort, zwei Skalen und zwei Messungen,
  ohne Erklärung. Auch in `investigate.dart` steht eine Tür dazu.
- **G27 ❌ Rohe Farben und Sprache.** 13 `Color(0xFF…)` in `takt_stress_view.dart` (Teal, Rot) und weitere in `body_age_view.dart`.
  `CLAUDE.md`: „keine rohen Farben außerhalb von `theme.dart`“. `ui2_tokens_test` prüft nur `lib/ui2`, fängt es daher nicht. Teal und Rot
  sind nicht per Kontrast-Test gesichert. Texte fest an Deutsch/Englisch statt `AppLocalizations`;
  „/ 3,0“ und „(0,0 – 1,0)“ stehen auch im englischen Text mit Komma; `'${h}h ${m}m'` ist nicht lokalisiert.

### Displaystreifen B5 und Darstellung (320/360/390 px, Textgröße 1,0/1,3/2,0, hell und dunkel, mit echten Schriften)

Matrix: 72 Läufe (4 Ansichten × 3 Breiten × 3 Größen × 2 Themen), Streifen bei 20/35/50/72/90 %.

- **G28 ✅ Ziffern in Karten:** Stress-Karte, Trends und Vitalwerte-Ansicht: in allen Läufen **jede Ziffer in einem
  `StripeDodge`**, und keine Ziffer auf dem Streifen (0 Treffer).
- **G29 ❌ Stress-Detailansicht verletzt B5.** In allen 18 Läufen **25 ungeschützte Ziffern-Texte:** das Datum
  („2026-11-11“, ISO statt „Heute/gestern/Wochentag“ wie H1), „/ 3,0“, die Zeitachse „00:00 … 24:00“, „24-STUNDEN-VERLAUF“ und die drei Zonen-Beschriftungen
  mit „(0,0 – 1,0)“. Der Test `day_stress_test` prüft das nur an der Karte, nicht an der Detailansicht.
- **G30 ❌ Überläufe (RenderFlex).**
  - Detailansicht, Kopfzeile des Diagramms („24-STUNDEN-VERLAUF“ + „Gedrückt halten zum Prüfen“): überläuft bereits bei **390 px /
    1,0** (5,5 px), bei 360 px 36 px, bei 320 px 76 px. Im Bildschirmfoto überlappt der Text mit dem Streifen.
  - Stress-Karte: ab Textgröße 2,0 bei allen drei Breiten (Wertzeile bis 131 px, Legende bis 87 px, Kopfzeile bis 60 px);
    bei 320 px schon ab 1,3 (1,5 px).
  - Detailansicht ab 1,3 bei 360 und 390 px (Zonenzeilen, Diagramm-Kopf), bei 2,0 mehrere (bis 828 px).
  - Vitalwerte-Ansicht: bei 320 px schon bei 1,0 (5,8 px), bei 2,0 an vier Stellen; bei 360 px ab 1,3.
  - Trends: nur über die Stress-Karte.
  Die vorhandenen Tests laufen nur bei 390 px, Größe 1,0 und mit der Test-Schrift, deshalb sieht man nichts.
- **G31 ✅ Hell/dunkel** rendern ohne Fehler; Kontrasttests der Suite bestehen mit der neuen Palette.
- **G32 ⚪ Echtes Gerät/Band:** Streifen auf dem echten Display, echte Schrift „Doto“ auf dem Handy, Live-Daten: nicht prüfbar.

### Tab-Leiste und Rahmen

- **G33 ✅ Leiste zeigt Heute, Schlaf, Gesundheit; stürzt nicht.** `AppShell(initial: activity, domains: …)`
  fällt auf Heute zurück, Tippen und Zurück funktionieren (320 und 390 px, getestet).
- **G34 ❌ Was geht durch den abgeschalteten Aktivität-Tab verloren?** Der Tab ist die einzige Tür zu `WorkoutScreen`.
  Nicht mehr erreichbar (geprüft per `grep` auf Aufrufer; Heute hat nur `ActivityPicker` zum Sportart-Wählen, `LogWorkout`
  zum Nachtragen und `DayStrainDetail`):
  1. **Training starten** (Startkarte, Schnellstart-Kacheln, `ActivitySetup`, Live-Training). Es gibt auf Heute keinen Weg, ein
     Live-Training zu beginnen. Nur ein bereits laufendes erreicht man über die `_LiveSessionBar`.
  2. Aktivitäten-Katalog durchblättern, Verlauf-Reiter („History“: Einträge öffnen, Zeit ändern, löschen), außer über Tage-Schalter auf Heute.
  3. „Diese Woche“-Streifen, **Trainingslast** (ACWR), Überlastungs-Hinweis, mechanische Last (Tonnage).
  4. **Ernährung/Essen** (`NutritionScreen`): nur noch über die Wasser-Benachrichtigung.
  5. **Health-Connect-Workout-Import**: Schalter und „Jetzt importieren“ liegen nur dort. Ein früher eingeschalteter Auto-Import läuft weiter
     (`app_state.dart` ruft `maybeRun`), ein neuer lässt sich nicht einschalten.
  6. Eine Vorlagen-Funktion gibt es in dieser Codebasis nicht (nur Vorschläge „For you“).
  Schritte-Details bleiben über die Karte auf Heute erreichbar.
- **G35 ❌ Zuordnung auf `ShellDomain.today` macht nichts still kaputt.**
  - `domainForTab(4)` und `domainForSavedTab(2|3)` liefern jetzt Heute. Das ist gewollt, aber `ui2_router_test` ist rot (2 Tests).
  - `domainForRoute` liefert für **`kRouteWater`** und **`kRouteWorkoutIdle`** weiter `ShellDomain.activity`. `_Shell._go`
    setzt dann `taktTodayVisible.value = (d == today)` = **false**, obwohl `AppShell` auf Heute zurückfällt (und `onSelect` nicht
    feuert). Heute steht vorne, aber `PulseDisplay` schaltet den Live-Puls ab und das Auto-Sync auf Heute ist pausiert, bis jemand
    den Tab wechselt. Weg (aus dem Code, nicht als Test nachgestellt, `_Shell` ist privat): Benachrichtigung „Training vergessen“
    oder Wasser antippen, während Heute offen ist. `Prefs.shellTabV2` wird zudem auf den Index von `activity` geschrieben (harmlos, wegen Rückfall).
  - Die Wasser-Benachrichtigung öffnet weiter `NutritionScreen` (geschoben), sie funktioniert; „Training vergessen“ landet auf Heute ohne Aktivität-Tab, das
    Banner `_LiveSessionBar` bleibt als Zugang zum Beenden.
- **G36 ✅ Bestehende Einstellungen unverändert.** Der Diff in `settings.dart` ist reines Anfügen (neue Gruppe „Körperalter & Studien“, Geburtsdatum
  im Profil, `BodyAgeStudiesScreen`); die Gruppen davor und danach unverändert. `birthdate` wird mit den anderen Feldern gespeichert
  (leeren entfernt es), das Alter wird aus dem Geburtsdatum errechnet. Tests `settings_studies_test` grün.
- **G37 ❌ (klein) Einstellungen:** Die neue Appearance-Zeile in `profile.dart` schaltet bei jedem Tippen **zyklisch weiter** (System → Hell → Dunkel),
  statt eine Auswahl zu öffnen, und braucht `ThemeController` im Baum (siehe Testlauf). Neue Texte der Gruppe sind nicht in den `.arb`-Dateien
  (nur de/en, alle anderen Sprachen zeigen Englisch). Zwei Wege zum selben Schalter (Profil und Mehr-Einstellungen).
- **G38 ⚪/⚠ Theme.** `ui2/theme.dart`: Hell wechselt von „gebürstetes Aluminium“ (D8D8D3) auf weiß/kaltgrau (F7F8FA, Karte FFFFFF).
  Das gilt für **alle** Takt-Screens (Heute, Schlaf, …), nicht nur Gesundheit, und ist in keiner Spec festgehalten.
  Kontrasttests bestehen. Die Karten heben sich im hellen Modus nur noch wenig vom Hintergrund ab (Geschmack, Freigabe durch Felix nötig).
- **G39 ✅ Token-Regeln** (`ui2_tokens_test`): grün. Die Änderung ergänzt nur `BodyAgeStudiesScreen` in `_notComponents`. Keine
  ungegatete `Duration(`-Animation in den neuen Dateien außer dem Tab-Wechsel (150 ms, `AnimatedContainer`, ungegatet für reduzierte Bewegung, klein).
- **G40 ✅ Header/NavBar:** `NavBar` rendert im Takt-Look einen `TaktHeader` mit Zurück-Pfeil (`onBack` neu). Funktioniert. `profile.goto` hüllt jetzt alle
  geschobenen Profil-Seiten in `TaktLook`, d. h. auch Upstream-Screens (Daten, Alarm …) laufen im Takt-Stil; es gibt keinen Schalter dafür.

### Regressionen

- **G41 ❌ Ohne Takt-Look bleibt OpenStrap.** `health_screen.dart`: das Muster wurde von
  `case final note?` zu `case final note` geändert. Es passt jetzt auch bei `null`. Weg: `HealthScreen` ohne `TaktLook`
  mit leerem Repo, deutsch: Es erscheint **„Erholung · null“** in der Übersicht. Im Takt-Look nicht sichtbar (Zweig ist dort aus), in
  der App ist Gesundheit immer im Takt-Look, die Regression ist also latent, tritt aber in Tests und bei jeder Wiederverwendung auf.
- **G42 ✅ Stichprobe Spec 01 und 07:** Die Takt-Tests (275, darunter Heute, Detailscreens, Strain, Schlaf-Kopf) laufen grün; H1/H8 (Kopf, Tag
  wechseln) am Strain und Schlaf erfüllt. Die neue Stress-Detailansicht erfüllt H1 nur teils (kleingeschriebener Name ja, „von wann“ als
  ISO-Datum nein).
- **G43 ⚪** Heute-Tests `today_screen_test`: liefen außerhalb 00:00–00:35, alle grün.

## Hinweise (nicht als Fehler gezählt)

1. **Prozess:** Feature 05 und der Stress-Teil sind ohne Spec, Architektur und Plan gebaut. `CLAUDE.md` führt 05 als „idee“. Vorschlag: Spec
   nachträglich schreiben (Gesundheit, Stress) und mit Felix freigeben. Besonders die Frage „was ist Stress hier, und wie ehrlich benennen wir die
   Schätzung“ (G15) braucht eine Entscheidung. Ein Test mit nur 3 Samples und 390 px deckt weder Größe 2,0 noch Datenlücken ab.
2. **Reihenfolge für die Nacharbeit** (mein Vorschlag, Felix entscheidet): G1/G2 (Vitalwerte, Erkunden, Labore wieder
   erreichbar machen, z. B. als Tür auf der Übersicht), G14/G15 (Stress-Basis und Sportgrenze), G19/G20 (Zeitachse nach Uhrzeit),
   G34/G35 („Training starten“ zurückbringen, Route-Zuordnung), dann Überläufe und B5 der Detailansicht.
3. Für die Stress-Kurve: Zeit als x-Achse nehmen (0 bis 24 Uhr, Lücken als Lücken); Sport als eigenes Band statt Wert 2,5; gleitende Basis aus
   `baselines` und Tag-HRV mit Tag-HRV-Mittel (`daytime_hrv.mean_rmssd`) vergleichen; Mindestabdeckung pro Bin; bei fehlender Basis „—“
   statt Standardwerte; einen Satz in die Info-Karte: „Eigene Schätzung aus Puls und HRV, kein klinischer Wert“.
4. `takt_stress_view.dart` und `takt_health_views.dart` liegen in `lib/takt/` und sind damit von `ui2_tokens_test` nicht
   erfasst. Den Test auf `lib/takt` erweitern würde G27 künftig fangen.
5. Tests auflisten, die die Änderungen mitziehen müssen: `ui2_router_test` (Erwartung `activity`), Provider-Harnisch für `ThemeController` in
   `thai_l10n_test`, `language_picker_sheet_test`, `ui2_onboarding_profile_test`; Höhe in `ui2_gallery_test`.
6. Nicht geprüft, weil nicht möglich: ⚪ echtes Handy und Band (Live-Puls, Daten-Sync, echte HR-Kurven mit Lücken), Android-Darstellung von „Doto“,
   Rückfall bei Schreibfehlern der Prefs.
7. Ein Vergleich der roten Tests mit dem Stand HEAD war nicht möglich (kein Kopieren des Repos erlaubt). Die Zuordnung zu den Änderungen beruht auf den
   Fehlermeldungen (Router und ThemeController eindeutig, Gallery wahrscheinlich).
