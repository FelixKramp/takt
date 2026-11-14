---
feature: 10-koerperalter
geprüft: 2026-11-12
prüfer: unabhängiger Prüfer-Agent (nichts gebaut, nichts repariert)
stand: ungeprüfter Arbeitsstand, nicht committet (`git diff HEAD`)
---
# Prüfung: Körperalter

## Ampel: nicht reif

Der Mechanismus (Rechnung, Kappung, Montags-Sperre, Streifen) arbeitet größtenteils wie gebaut, aber drei Dinge
sind für ein Feature, das „keine Zahl ohne Quelle“ verspricht, nicht tragbar: Der Faktor Krafttraining erkennt
die wichtigsten Sportarten nicht (`weight_training`), die Zahl ist für einen typischen 18-Jährigen systematisch
viel zu optimistisch (7,0 Jahre „jünger“, Körperalter 11,0, und die App nennt das „im optimalen Zielbereich“), und
der Studienbildschirm behauptet Dinge, die in den Studien nicht stehen. Dazu kommt eine echte Regression im
Gesundheit-Tab ohne Takt-Haut („Recovery · null“). Mit Nacharbeit an diesen Punkten (und einer Architektur, die die
Risikokonstanten herleitet) wäre es reif, in diesem Zustand nicht.

Gelaufen: `flutter test test/takt` → 275 Tests bestanden. `flutter analyze lib test/takt` → keine Befunde in `lib`
und in den dauerhaften Tests; die 13 Meldungen stammen alle aus fremden Wegwerf-Dateien `zz_pruef_gesundheit_*` und
`zz_pruef_heute_*` anderer Prüfer. Zusätzlich 141 Tests aus `ui2_home_health`, `ui2_tokens`, `ui2_revision_reload`,
`ui2_wiring_r2`, `ui2_labs_delete`, `wearable_screens_wiring`, `ui2_advanced_charts`, `low_readiness_agreement`
bestanden (sie fangen die Regression unten trotzdem nicht).

Alle Wegwerf-Tests (`zz_pruef_koerperalter_*`), die Test-Datenbank und die Bildschirmfotos sind gelöscht.

## Kriterien

| | Ergebnis |
|---|---|
| K1 Zahl | ✅ Zahl mit einer Nachkommastelle und Abweichung („−7,0 Jahre“, grün bei jünger), Alter ohne Profil und unter 14 Tagen sauber getrennt. Die Zahl selbst ist aber unplausibel, siehe G. |
| K2 Faktoren | ❌ Messwert, Zielbereich, Beitrag und Sortierung nach \|Beitrag\| stehen. Aber: (1) Krafttraining-Messwert falsch, siehe ❌1; (2) die Zeilen addieren sich nicht zur Kopfzahl, siehe ❌3; (3) „Größter Hebel“ auf der Karte zeigt den größten *bereits erreichten* Beitrag („Größter Hebel: Ruhepuls (−1,7 J.)“ bei einem, der den Ruhepuls längst gut hat), nicht das, was man noch gewinnen kann. |
| K3 Herleitung | ✅ mit Hinweis. Antippen zeigt Studie, „Relatives Risiko → ln/ln2×8 = …“ und Hebel. Die Hebel-Sätze stimmen im linearen Bereich auf ±10 % (siehe A). Die Zeile „Umrechnung“ rechnet falsch, wenn die Summe gekappt ist (❌9). Dass das RR aus der Studie stammt, legt der Text nahe, ist es aber nicht (❌5). |
| K4 Zu wenig Daten | ❌ teilweise. „Noch 11 Tage bis zum Körperalter (3/14 …)“ ✅, Kopf „–“ ✅, fehlender Faktor „fehlt“ mit 0,0 J. ✅. Aber (1) im Kalibrierungs-Detail stehen trotzdem Faktor-Jahre („Schlafdauer −1,2 J.“ aus 3 Tagen); (2) sind alle sieben Faktoren leer bei ≥14 Tagen, erscheint „18,0 / ±0,0 Jahre / Tempo 1,00×“ als wäre es ein Ergebnis (❌8). |
| K5 Woche | ❌ Der Kern funktioniert (Summe wird je Montag in `takt.body_age.weeks.v1` festgehalten, Vorwochen-Delta, Montag über Zeitumstellung 25.10.2026 und 28.03.2027 korrekt). Aber: die Faktorenliste ist live, nur die Summe gesperrt (❌3); gesperrt wird beim *ersten Öffnen der Woche*, nicht am Montag; das Körperalter driftet innerhalb der Woche mit dem Geburtsdatum (siehe C); kaputte Speicherwerte werden nicht abgefangen (❌11). |
| K6 Streifen | ✅ Sweep Streifenposition 5 %–95 % in 2,5-%-Schritten über Karte, Karte (schlecht), Detail, Studienbildschirm bei 320 und 390 px, Textgröße 1,0 und 2,0: 0 Ziffern ohne `StripeDodge`, 0 Treffer auf dem Streifen bei 3 293 bis 13 357 geprüften Ziffernrechtecken je Lauf. Hinweis: die Zeile „7 Kohortenstudien & 8-Jahres-Verdopplungsregel“ in den Einstellungen (`SetRow.sub`) liegt nicht in einem `StripeDodge`; sie ist Upstream-Einstellungsliste und nicht Teil von K6, aber eine Ziffer. |
| K7 Alterungstempo | ✅ Formel `2^(diff/8)` stimmt (−7,0 J. → 0,54× → „46 % langsamer“; +10 → 2,38× → „138 % schneller“). Aussage-Problem siehe E. |
| Rand: kein Alter | ✅ Karte zeigt Hinweis, Tippen ruft `openProfile` auf. ⚪ Ob man von dort bis ins Altersfeld kommt, nicht durchgeklickt. Unplausibles Alter (130, 200) zeigt denselben Hinweis „Alter im Profil eintragen“, obwohl eins eingetragen ist (kleiner Mangel). |
| Rand: ±3 / ±10 | ✅ im Code und per Test bestätigt (Faktoren 2,44 … 0,30, Summe exakt −10,0 / +10,0). Anzeige danach inkonsistent (❌9). |
| Rand: WHOOP-Import | ❌ Schlaf und Ruhepuls zählen mit (Import schreibt `tst_min`, `rhr`). Zonen: ein WHOOP-Export enthält keine Zonenminuten, diese Tage tragen zu Zone 1–3/4–5 nichts bei (Rechnung teilt korrekt durch die Tage mit Zonen, also kein Fehler, aber die Spec-Aussage „Zonen zählen mit“ trifft nicht zu). Training: zählt nicht, siehe ❌1 (`Weightlifting` wird beim Import zu `weight_training`, das nicht im Set steht). |
| Nicht-Ziel: keine Benachrichtigungen | ✅ kein Benachrichtigungscode im Feature gefunden. |
| Nicht-Ziel: kein medizinischer Befund | ❌ Nirgends steht ein Hinweis „kein medizinischer Befund, keine Lebenserwartung“; die Karte sagt „Im optimalen Zielbereich“, der Bildschirm „Alterungstempo 46 % langsamer“. |
| Spec „Belege / keine Zahl ohne Quelle“ | ❌ siehe E und F. |

## ❌ Befunde mit Reproduktionsweg

**❌1 Krafttraining erkennt die Sportart nicht (hoch).**
`kStrengthWorkoutTypes` (`body_age.dart:24`) enthält `weightlifting, strength, strength_training, powerlifting,
bodybuilding, calisthenics, functional_fitness, crossfit, kettlebell, gym`. Die echten `typeKey`s aus
`lib/ui2/activity/catalogue.dart` (Gruppe „Strength“) sind `weight_training, powerlifting, bodyweight, calisthenics,
kettlebell, crossfit, hiit, circuit_training, functional`. Der WHOOP-Import mappt `weightlifting` und
`strength_trainer` auf `weight_training`, `functional_fitness` auf `functional` (`whoop_import.dart:630`).
Reproduziert mit echter Datenbank (20 Tage Daten, je eine 60-Min-Sitzung 3 Tage zuvor), `loadBodyAge`:
`weight_training → 0 Min./Wo. (+0,45 J.)`, `bodyweight → 0`, `hiit → 0`, `circuit_training → 0`, `functional → 0`,
`strength_trainer → 0`; nur `powerlifting`, `calisthenics`, `kettlebell`, `crossfit` und die toten Schlüssel
`weightlifting`, `strength`, `functional_fitness` → 21 Min./Wo. (−0,19 J.). Wer Gewichte hebt, bekommt also +0,45 Jahre
(älter) statt bis zu −1,5. Die vorhandenen Tests verwenden nur `calculate(strengthMinPerWeek: …)` und prüfen die
Schlüssel nie.
Nebenbefund: geteilt wird durch `recentDays.length / 7` (Tage *mit Daten*), nicht durch 30/7. Bei 20 Datentagen wird
dieselbe Sitzung also 1,5-fach gewertet.

**❌2 Regression: Gesundheit-Tab ohne Takt-Haut zeigt „Recovery · null“ (hoch).**
`health_screen.dart` (Diff): vorher `if (recoveryStateLine(...) case final note?)`, jetzt `if (!TaktLook.on(c)) if
(recoveryStateLine(...) case final note)` ohne `?`. Das Muster passt jetzt auch auf `null`. Reproduziert:
`HealthScreen(data: HealthData(…))` ohne `TaktLook` darüber, Ausgabe der Texte: `…, More for today, Plan, tips and
alarm, Recovery · null, Resting heart rate, …`. Betrifft jeden OpenStrap-Nutzer, dessen Tag weder „Schläft“ noch
„Wird fertig“ ist, also fast alle. Weitere Abweichung in derselben Datei: `MoreForTodayRow` erscheint ohne Takt-Haut
nur noch auf Tab 0, vorher auf jedem Tab.

**❌3 Faktorenliste und Kopfzahl passen nicht zusammen (hoch).**
`loadBodyAge` sperrt nur `diffYears`, `bodyAge`, `pace`; `factors` bleiben `live.factors`. Reproduziert (20 Tage,
Ruhepuls 60): Mittwoch erster Start → Kopf −2,13, Faktorensumme −2,13. Donnerstag, Ruhepuls-Daten auf 50 geändert →
Kopf weiter −2,13, Faktoren summieren sich zu −4,02, Ruhepuls-Zeile zeigt 50 bpm. Die App zeigt also eine Zahl und
darunter Gründe, die sie nicht ergeben. Montag danach springt der Kopf auf −4,02.

**❌4 Die Zahl ist für einen typischen 18-Jährigen systematisch zu optimistisch (hoch), und die Einstufung ist falsch.**
Rechnung für 7,5 Std. Schlaf, SRI 70, Ruhepuls 55, 8000 Schritte, 150 Min. moderat, 30 Min. intensiv, 60 Min. Kraft:
Ruhepuls −1,74, Kraft −1,48, Schlaf −1,22, Schritte −1,09, moderat −0,84, SRI −0,47, intensiv −0,19, Summe −7,02,
Körperalter bei 18,0 Jahren = 10,98; Tempo 0,54×. Ohne Kraft (0 Min.) immer noch −5,09. Wer *genau* alle genannten
Zielwerte trifft (7,5 Std., SRI 75, 58 bpm, 8000, 150, 45, 30–60), landet bei etwa −6,3 bis −7,3. Der
Zielbereich „Alter −5,5 bis −2,0“ (`optimalAgeMin/Max`) ist nirgends begründet (kein Beleg in Spec oder Code) und passt
nicht zu den Zielwerten der Faktoren: Wer alles richtig macht, liegt *unter* dem „Optimal“-Band. Die Einstufung lautet
trotzdem „Im optimalen Zielbereich (7,0 Jahre jünger)“ (`body <= optHi`, es gibt keine Untergrenze; so auf dem Bildschirmfoto
der Karte bei 390 px gesehen). Ursachen: Die Neutralpunkte (RR = 1) liegen bei durchschnittlichen *Erwachsenen* (SRI 65,
Ruhepuls 65, 6000 Schritte, 75 Min. moderat, 20 Min. intensiv, 15 Min. Kraft), der Schlaf hat bei 7,5 Std. ein
Dauer-Bonus (rr 0,90 → −1,2 J., in Cappuccio gibt es keinen solchen Schutz, dort ist die Referenz „normaler Schlaf“),
sieben teilweise korrelierte Faktoren (Ruhepuls, Schritte, Zonen sind alle Fitness) werden multipliziert statt
entdoppelt, und bei 18 ist die 8-Jahres-Verdopplung (Gompertz) nicht der Treiber der Sterblichkeit. Die Spec räumt
das selbst ein (These 3), die App sagt es nirgends. Zusätzlich: Die Zone-1–3-Minuten sind keine Bewegungsminuten
(Ganztags-Herzfrequenz oberhalb 50 % HFmax bzw. HFR, je nach `zone_source`; Zone 3 gilt nach ACSM schon als intensiv).
Wer 21 Min. pro Tag über der Zone-1-Schwelle ist (Schulweg, Handball), erreicht 150 Min./Wo. (−0,84 J.); ab 43 Min.
pro Tag ist der Faktor bei −2,72 J. gesättigt. ⚪ Mit echtem Band-Tag nicht nachgemessen.

**❌5 Studienbildschirm und Karte behaupten mehr, als die Studien tragen (hoch, Ehrlichkeit).**
Der Bildschirm „Körperalter-Studien“, die Methodenzeile im Detail („Jeder 30-Tage-Wert wird über publizierte
Langzeitstudien in ein relatives Sterberisiko übersetzt“) und „Studie: … / Umrechnung: Relatives Risiko 0,90 …“
legen nahe, dass das RR aus der Studie kommt. Tatsächlich sind es lineare Näherungen mit freien Konstanten
(`0,90 + |h−7,5|×0,10`, `1 − (SRI−65)×0,008`, `1 + (RHR−65)×0,014`, `−4,5 % je 1000 Schritte über 6000`,
`−14 % je 150 Min. um 75`, `−12 % je 75 Min. um 20`, `−12 % je 45 Min. um 15`, dazu Klemmen). Es gibt keine
Architektur, die sie herleitet. Einzelne Texte sind falsch (Details im Abschnitt Studien unten):
- Jensen: „Ruhepuls über 80 bpm verdoppelt das Risiko kardiovaskulärer Ereignisse gegenüber Werten unter 50 bpm“ steht
  nicht in der Studie. Ergebnis war Gesamtsterblichkeit, HR 3,06 für >90 vs. ≤50 bpm, +16 % je 10 bpm.
- Einstellungszeile „7 Kohortenstudien“: es sind 6 verschiedene Arbeiten (Lee zweimal), davon 3 Metaanalysen
  (Cappuccio, Paluch, Momma).
- Lee: „150–300 Min. moderate Bewegung senken … um 21–23 %“: im Abstract stehen 19–25 % für 150–299 Min. moderat
  (alle Ursachen/Herz/Nicht-Herz); die 21–23 % gelten für 150–300 Min. *intensiv* laut AHA-Pressemeldung. Und
  „intensive Betätigung (Zone 4–5)“: die Studie fragt freiwillige Freizeitaktivität per Fragebogen ab, keine Pulszonen.
- Es fehlt jeder Hinweis „einfache Näherung, kein medizinischer Befund“.

**❌6 Neutralpunkte und Steigungen mit Studien in Konflikt oder nicht belegbar (mittel).** Siehe Tabelle unten
(„widerspricht“ / „nicht verifizierbar“).

**❌7 K4-Kalibrierungsdetail zeigt Faktor-Jahre** (mittel). `TaktBodyAgeDetail(snapshot: calculate(realAge: 18,
dataDays: 3, avgSleepHours: 7.5))` → Kopf „–“, darunter „Schlafdauer −1,2 J.“ (Foto). Spec: „statt einer Zahl“.

**❌8 Alle Faktoren fehlen, trotzdem eine Zahl** (mittel). `calculate(realAge: 18, dataDays: 30)` mit allen sieben
`null`/NaN/±∞ → `ready == true`, Karte zeigt „Körperalter 18,0 / ±0,0 Jahre / Tempo 1,00×“ und `loadBodyAge` speichert
das als Wochenwert (der dann die nächste Vorwochen-Differenz verzerrt). Auch: ein einzelner Schlaf-Tag reicht als
„Mittelwert“, es gibt keine Mindestanzahl Messungen je Faktor.

**❌9 Anzeige bei gekappter Summe und bei der 10-Jahre-Untergrenze falsch (niedrig).**
(a) `calculate` skaliert alle Faktoren, wenn die Summe über ±10 liegt, die Zeile „Umrechnung: Relatives Risiko 1,25 →
ln(1,25)/ln(2) × 8 = +2,4 J.“ rechnet aber 2,58. Reproduziert: Schlaf 4,0 Std. + SRI 0 + Ruhepuls 100 + … → angezeigt
+2,4, tatsächlich +2,58. (b) `bodyAge.clamp(10, 130)`: bei 14 Jahren und diff −10 steht „−10,0 Jahre gegenüber 14 Jahren“,
Körperalter aber 10,0 (also −4,0); der Verdict-Text rechnet −4,0. Bei einem 18-Jährigen mit sehr guten Werten (diff
< −8,7) tritt dasselbe auf.

**❌10 Layout: Überlauf bei 320 px und Textgröße 2,0 (niedrig).** Karte (gute Werte, mit Vorwochen-Zeile) →
`A RenderFlex overflowed by 5.1 px on the right`, `body_age_view.dart:173` (obere Row, rechte Spalte ohne Flexible).
Alle anderen Kombinationen (320/390 px × 1,0/1,3/2,0 × hell/dunkel × de/en, Karte, Kalibrierung, kein Alter, Detail mit
jedem der sieben Faktoren aufgeklappt, Studienbildschirm) ohne Überlauf. Englisch zeigt im Kurzformat „J.“
(„Top lever: … (−1,9 J.)“, `formatSignedYears(short: true)` ignoriert `de`). Rohe Farben `0xFF2BB594`, `0xFF1B8A6B`
in `body_age_view.dart` (Zeilen 538, 539, 780) widersprechen der Konvention „keine rohen Farben außerhalb theme.dart“.

**❌11 Robustheit gespeicherter Werte und Profil (mittel).** Reproduziert über `SharedPreferences.setMockInitialValues`:
- `takt.body_age.weeks.v1 = "garbage{"` → fällt still auf Live-Wert zurück und wird nie repariert; die Sperre ist für
  immer aus, die Zahl ändert sich täglich.
- `{"2026-11-09": 55}` → Kopf „+55,0 Jahre“, Körperalter 73,6, Tempo 117×; `{"2026-11-09": 1e308}` → Tempo
  `Infinity`. Gespeicherte Werte werden nicht auf ±10 geprüft.
- `profile['age'] = '18'` (String) oder `birthdate = 5` → `loadBodyAge` wirft `type 'String' is not a subtype of
  'num?'`; `HealthData.load` ruft es ungeschützt auf, der ganze Gesundheit-Tab lädt dann nicht. Upstream schreibt
  `age` als Zahl, der Pfad ist deshalb nur ⚪ theoretisch.

**❌12 Prozess (Hinweis, kein Code).** Spec ist verändert (K7 hinzu, Nicht-Ziel „Kein Tempo des Alterns“ gestrichen),
Kopf noch „freigegeben: offen“, CLAUDE.md-Tabelle sagt `spec`. Es gibt weder `architektur.md` noch `plan.md`; die
Risikokonstanten (siehe ❌5) haben damit keinen Ort, an dem sie hergeleitet sind. Der Arbeitsstand enthält außerdem
Fremdes (Tagesstress, neue Palette in `theme.dart`, Shell ohne Aktivität-Tab, `goto()` hüllt jede Profil-Route in
`TaktLook`, Takt-Gesundheit ohne Explore/Labs-Tabs). Das konnte hier nicht abgegrenzt geprüft werden; die
Körperalter-Anteile sind unten geprüft, der Rest nicht.

## Hinweise ohne ❌

- **A Hebel-Texte gegen die Formeln (nachgerechnet, alle sieben Faktoren).** Schlaf: 6,5 → 7,5 Std. −1,22 J.,
  5,5 → 6,5 −1,10 (Text „ca. 1,1“ ✅). SRI: 65 → 76 ≈ −1,0 ✅ (aber ab SRI 90 nur noch −0,4). Ruhepuls: 65 → 59 ≈ −1,0 ✅
  (ab ≈ 50 bpm gekappt, Rest nur noch −0,3). Schritte: 6000 → 8000 −1,09, 8000 → 10000 −1,20 ✅, ab 12 000 nichts mehr.
  Moderat: 75 → 165 ≈ −1,0 ✅ (ab 300 Min. gekappt). Intensiv: 20 → 70 ≈ −1,0 ✅ (ab 150 gekappt). Kraft: 15 → 45
  ≈ −0,97 ✅ (ab 90 gekappt, laut Momma J-Form oberhalb 60 unklar). Vorzeichen (mehr Schlaf-Abweichung/höherer
  Ruhepuls = älter, mehr Schritte/Bewegung/SRI = jünger) ✅. Rundung eine Stelle ✅, `±0,0` ✅. Die Hebel-Sätze sind
  statisch und gelten nicht in den gekappten Bereichen.
- **B Datenquellen.** 30 Kalendertage ✅ (Fenster `heute−29`, Punkte um 12:00 lokal, kein Randproblem).
  `dataDays` zählt Tage mit `day_result`-Zeile, nicht Tage mit Daten im Faktor; mit WHOOP-Import zählen
  importierte Tage ✅. Zonen: Hochrechnung pro Woche korrekt (700 = 100 Min./Tag × 7 im Test, 49 intensiv = 7×7).
  Der heutige, noch unvollständige Tag ist im Schritte- und Zonen-Mittel mit drin (⚪ nicht mit echtem Band
  nachgestellt, vermutete Wirkung −0,1 bis −0,2 Jahre, und weil nur beim ersten Öffnen der Woche gesperrt wird, hängt
  die Wochenzahl von der Uhrzeit des ersten Öffnens ab). SRI: Mittel der Paar-Werte ab `fromDay`, ohne Paare
  Gesamt-SRI des ganzen Zeitraums.
- **C Alter.** Mit Geburtsdatum rechnet die App mit `exactAge` (18,56 statt 18); widersprechen sich Alter 40 und
  Geburtsdatum 2008, gewinnt still das Geburtsdatum. Das Körperalter wird beim Sperren zwar festgehalten (Diff), aber
  `bodyAge = exactAge + Diff` mit heutigem `exactAge`: 14,5969 → 14,6133 in einer Woche, die Anzeige „14,6“ kippt
  gelegentlich mitten in der Woche (alle ~37 Tage um 0,1).
- **D Spec-Frage „Alter 18 und Studien ab 40“.** Alle sechs Studien stammen von Erwachsenen (Windred Ø 62,8 Jahre,
  Jensen Männer mittleren Alters, Lee US-Gesundheitsberufe). Die Aufteilung nach Faktoren ist nützlich, die Jahreszahl
  ist für 18 eher eine Richtung, wie die Spec in These 3 schreibt. Die App sagt das nirgends.
- **E Alterungstempo.** `2^(diff/8)` ist das *relative Sterberisiko*, nicht die Alterungsgeschwindigkeit. Wer dauerhaft
  7 Jahre „jünger“ ist, altert trotzdem 1 Jahr pro Jahr; der Methodentext sagt „1,00× entspricht … 1 Jahr pro Kalenderjahr“,
  „46 % langsamer als normal“ suggeriert etwas anderes. Spec-konform, aber irreführend.
- **F Mehr.** Aktuelle Karte zeigt „Echtes Alter“ doppelt (oben rechts und im Streifen). Dunkelmodus ist
  lesbar (Fotos geprüft, Kontrast sichtbar ausreichend). ⚪ Wischgefühl, Band und echte Daten nicht geprüft; ⚪ Ladezeit
  mit echten Tagesbündeln nicht gemessen (30 Tage leere Bündel: 30 ms, 5 parallele Ladungen 143 ms, gleiche Ergebnisse,
  Speicher konsistent). ⚪ `getDayStrain` wird je Tag einzeln aufgerufen; bei großen Bündeln könnte das merklich sein.
- **G Plausibilität am Beispiel** siehe ❌4.

## Studien: verifiziert / nicht verifizierbar / widerspricht

Geprüft per Websuche (Europe PMC und Pressemeldungen; PubMed und PMC blockierten den Abruf, die Vollpapiere habe ich
nicht gelesen, nur Abstracts).

**Verifiziert (Autor, Jahr, Zeitschrift, Kerngröße):**
- Cappuccio FP, D'Elia L, Strazzullo P, Miller MA, *Sleep* 2010;33(5):585–592: 16 Studien, 1 382 999 Teilnehmende,
  kurzer Schlaf RR 1,12 (1,06–1,18), langer Schlaf RR 1,30 (1,22–1,38). Beide Richtungen erhöht, also U-förmig ✔.
- Windred DP et al., *Sleep* 2024;47: UK Biobank, 60 977 Teilnehmende (Ø 62,8 Jahre), Median-SRI 81,0 (IQR 73,8–86,3),
  oberste vier Quintile 20–48 % weniger Gesamtsterblichkeit als das unregelmäßigste ✔ („Hohe Regelmäßigkeit … verringerte
  Gesamtmortalität“ im App-Text ✔).
- Jensen MT, Suadicani P, Hein HO, Gyntelberg F, *Heart* 2013;99(12):882–887: Copenhagen Male Study, 2 798 Männer,
  16 Jahre, 1 082 Tote, +16 % je 10 bpm (14 % bei Nichtrauchern), HR 3,06 für >90 vs. ≤50 bpm. Die im Code benutzten
  +14 % je 10 bpm liegen im Intervall ✔.
- Paluch AE et al., *Lancet Public Health* 2022;7(3):e219–e228: 15 internationale Kohorten, 47 471 Teilnehmende ✔.
  Plateau 8000–10 000 Schritte für Jüngere (<60), 6000–8000 für Ältere: nur aus Pressebericht, ⚪ nicht im Papier gesehen.
- Lee DH et al., *Circulation* 2022;146:523–534: 116 221 Erwachsene (NHS und HPFS), 47 596 Tote. 75–149 Min. intensiv:
  HR 0,81 Gesamtsterblichkeit; 150–299 Min. moderat: 19–25 % weniger; kein klarer Zusatznutzen ab ≥300 intensiv /
  ≥600 moderat ✔.
- Momma H, Kawakami R, Honda T, Sawada SS, *Br J Sports Med* 2022;56: 16 Studien, 10–17 % niedrigeres Risiko, J-Form mit
  größtem Nutzen (≈10–20 %) bei 30–60 Min./Woche ✔. Die Steigung im Code (0,88 bei 60 Min. gegenüber 1,04 bei 0 Min.,
  also −15 %) trifft das gut.
- Verdopplung des Sterberisikos „etwa alle 8 Jahre“: gängige Faustregel, Quellen nennen 7–10 Jahre (Wikipedia
  Gompertz–Makeham, arXiv 1509.07271 ≈ 10 Jahre über 35). ✔ als Faustregel.

**Nicht verifizierbar (Studie nennt die Zahl so nicht, oder Papier nicht gelesen):**
- Alle linearen RR-Formeln und Neutralpunkte (siehe ❌5), einschließlich Cappuccio-Schutz 0,90 bei 7,5 Std.
- Cappuccio „<6 h“ und „>9 h“ als Grenzen: laut Papier uneinheitlich je Einzelstudie, die Zahlen stammen aus Presse.
- Lee „21–23 %“ für moderat (Abstract: 19–25 %); „19–21 %“ für intensiv (Abstract: 19 % für Gesamtsterblichkeit).
- Paluch-Plateau (nur Presse).
- Moderat/intensiv als HF-Zone 1–3 / 4–5: Die Studie misst Fragebogen-Freizeitaktivität, keine Herzfrequenzzonen.
- Windred-SRI-Skala: Takt-SRI (Epochen aus Band-Schlaf/Wach) ist Phillips-SRI, Windred rechnet aus Beschleunigungs-
  daten; Median 81 in UKB heißt, dass die Mehrheit der Studie bei Takt-Werten ab ≈ 74 liegt und dort laut Code
  −1,0 bis −1,6 J. bekäme, gegenüber einem Referenz-Quintil, das hier nicht definiert ist.

**Widerspricht der Studie:**
- Jensen-Text im Studienbildschirm („verdoppelt das Risiko kardiovaskulärer Ereignisse“ über 80 bpm): Studie sagt
  Gesamtsterblichkeit, HR 3,06 für >90 bpm.
- Zeile „7 Kohortenstudien“: 6 Studien, 3 davon Metaanalysen.
- Linearer Schrittbonus bis 12 000 gegen das Plateau 8000–10 000 für Jüngere (Paluch): Code zählt zwischen 10 000 und
  12 000 weiter −0,7 J., die Studie sieht dort keinen Nutzen mehr.

## Anforderungs- und Randfälle, nachgestellt
K1–K7 und alle Randfälle wurden einzeln mit Wegwerf-Tests nachgestellt (Rechnung `BodyAgeCalculator.calculate` mit
Werten von 0 bis weit über den Klemmen, Alter 0/4/5/13/14/15/120/130/150, NaN, ±∞, negative Werte;
`loadBodyAge` mit echter SQLite-Datenbank über FFI, Schlüsselmatrix der Sportarten, Wochenfolge Mi → Do → So → Mo →
übersprungene Woche, kaputte Speicherwerte, kaputte Profile, parallele Ladungen; Layoutmatrix 2 Breiten × 3 Textgrößen ×
2 Helligkeiten × de/en; Streifensweep). Die eingebauten Tests lesen das Verhalten nicht ab: K5 wird nur als
`mondayOfWeek` getestet, `loadBodyAge` hat keinen Test, und `kStrengthWorkoutTypes` wird nie gegen
`catalogue.dart` geprüft.

## Empfohlene Reihenfolge der Nacharbeit
1. ❌2 und ❌1 (Regression, Sportart-Schlüssel; besser die Katalog-Gruppe „Strength“ per `archOf` verwenden als eine
   handgeschriebene Liste).
2. ❌3 Faktoren sperren oder Faktorenzeilen als „aktuell“ von der Kopfzahl getrennt beschriften.
3. Architektur schreiben: Neutralpunkte aus den Studien herleiten (Referenz = Normalschläfer, Teenager-Bezug),
   Faktor-Redundanz, Korridor begründen oder streichen, Alterungstempo umbenennen oder erklären; Studienbildschirm
   und Methodentext ehrlich formulieren („lineare Näherung aus …“) und „kein medizinischer Befund“ ergänzen.
4. ❌7–❌11.
