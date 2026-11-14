# Architektur: Körperalter (Feature 10)

Stand: Nacharbeit nach der Prüfung (`pruefung.md`). Die Spec ist Entwurf und nicht freigegeben;
Abweichungen von ihr stehen im letzten Abschnitt, Felix muss sie freigeben.

Das Körperalter ist eine **grobe Schätzung, kein medizinischer Befund**. Die Studien liefern
Richtung und Größenordnung. Die linearen Risikowerte und ihre Referenzpunkte sind unsere
**eigene Näherung, nicht direkt aus den Studien übernommen**. Das steht so auch in der App
(Karte, Detail, Studien-Bildschirm).

## Bestandteile
- **`lib/takt/health/body_age.dart`:** Rechnung und Laden.
  - `BodyAgeCalculator.calculate` nimmt die sieben 30-Tage-Werte und liefert einen
    `BodyAgeSnapshot` (Kopfzahl, Abweichung, Tempo, Faktorenliste).
  - `BodyAgeCalculator.factorFor(key, value)` baut einen einzelnen Faktor. Die Tabelle `_specs`
    hält je Faktor Name, Risikoformel, besten Wert, Zielwert, Studie, Beleg-Hinweis und
    Hebel-Satz. Die Hebel-Sätze werden aus der Formel gerechnet, nicht von Hand geschrieben.
  - `loadBodyAge` liest die Daten aus dem Repository, rechnet und verwaltet die
    Wochen-Momentaufnahme (K5).
  - `kStrengthWorkoutTypes` und `isStrengthWorkoutType` entscheiden, welche Sportarten als
    Krafttraining zählen.
  - `kBodyAgeTargetCorridor` ist der Schalter für den vorläufig entfernten Zielkorridor.
- **`lib/takt/health/body_age_view.dart`:** `TaktBodyAgeCard` (Karte), `TaktBodyAgeDetail`
  (Detail mit aufklappbaren Faktoren), `TaktBodyAgeStrip` (Leiste mit echtem Alter und Körperalter).
- **`lib/ui2/profile/settings.dart`:** Einstellungszeile und `BodyAgeStudiesScreen`
  (Studien-Bildschirm). Nur diese Stellen sind Körperalter.
- **`lib/takt/takt_text.dart`:** die neuen Sätze (Hinweis „kein medizinischer Befund“, Methode,
  Wochen-Hinweis, „keine Messwerte“).
- **`lib/ui2/screens/health_screen.dart`** (andere Gruppe) ruft `loadBodyAge` und
  `BodyAgeCalculator.calculate` auf. Die Signaturen bleiben unverändert.

## Datenquellen (30 Kalendertage, `heute − 29` bis heute)
| Messgröße | Quelle |
|---|---|
| Schlafdauer | Chart `sleep` (Minuten je Tag), Mittel, durch 60 |
| Ruhepuls | Chart `resting_hr`, Mittel |
| Schritte | Chart `steps`, Mittel |
| Schlafregelmäßigkeit | `insights['regularity']`, Mittel der Paar-Werte ab dem Fenster, sonst der Gesamtwert |
| Zone 1–3, Zone 4–5 | `getDayStrain(tag)['zones']`, Mittel je Tag mit Zonen, mal 7 |
| Krafttraining | `getWorkouts('month')`, Sportarten laut `isStrengthWorkoutType`, Minuten geteilt durch die Kalenderspanne (erster Tag mit Daten bis heute, 14 bis 30 Tage) in Wochen |
| Alter | `profile['age']` (Zahl oder Zahltext), `profile['birthdate']` (Datums-Text) für das exakte Alter |
| Tage mit Daten | Tage in `availableDays()` innerhalb der 30 Tage |

Importierte WHOOP-Tage zählen bei Schlaf und Ruhepuls mit. Ein WHOOP-Export enthält keine
Zonenminuten, diese Tage tragen zu Zone 1–3 und 4–5 nichts bei. Importierte Trainings zählen,
weil der Import `Weightlifting` auf `weight_training` abbildet (`whoop_import.dart`).

## Krafttraining: welche Sportarten
Die Menge wird aus dem Katalog (`lib/ui2/activity/catalogue.dart`) abgeleitet: Gruppe
„Strength“ ohne `hiit`, `circuit_training`, `crossfit` (Ausdauer- und Intervallformate, die keine
reine Kraftarbeit sind und schon in Zone 4–5 zählen). Ergebnis: `weight_training`,
`powerlifting`, `bodyweight`, `calisthenics`, `kettlebell`, `functional`. Neue Strength-Sportarten im
Katalog zählen automatisch. Ältere Importe haben den rohen WHOOP-Namen gespeichert
(`weightlifting`, `strength_trainer`, `functional_fitness`), die zählen über eine kleine
Alias-Liste mit. Ob Kettlebell dazugehört und CrossFit nicht, ist eine Festlegung, siehe
„Offene Entscheidungen“ unten im Bericht.

## Formeln je Faktor
Jahre = ln(RR) / ln(2) × 8 (Faustregel: Sterberisiko verdoppelt sich etwa alle 8 Jahre,
Quellen nennen 7 bis 10). Jeder Faktor ist auf ±3,0 Jahre begrenzt.

**Referenzpunkt = RR 1,0 = 0 Jahre.** Er liegt auf einem typischen Erwachsenenwert, nicht auf
dem Optimum. Vorher lag er auf dem Optimum und ein typischer 18-Jähriger kam auf −7 Jahre.
Wer den Referenzwert trifft, bekommt 0 Jahre. Besser als der Referenzwert gibt Minus, schlechter
gibt Plus. „Beleg“ unterscheidet: **Studie** (die Zahl steht im Abstract), **eigene Annahme, nicht
aus der Studie**.

| Faktor | Formel (RR) | Referenzpunkt | Beleg-Status |
|---|---|---|---|
| Schlafdauer h | 7 ≤ h ≤ 8: 1,00; h < 7: 1 + 0,08 × (7 − h); h > 8: 1 + 0,15 × (h − 8); Klemme 1,00 bis 1,35 | Plateau 7 bis 8 Std. | Studie: Cappuccio 2010, 16 Studien, kurzer Schlaf RR 1,12, langer RR 1,30, U-Form. **Eigene Annahme, nicht aus der Studie:** Ort der Werte (5,5 Std. für kurz, 10 Std. für lang), Gerade dazwischen, Plateau 7 bis 8 Std. (je Einzelstudie anders abgegrenzt) |
| Schlafregelmäßigkeit SRI | 1 − 0,006 × (SRI − 70); Klemme 0,85 bis 1,20 | 70 | Studie: Windred 2024, vier regelmäßigere Fünftel 20 bis 48 % weniger Gesamtsterblichkeit als das unregelmäßigste. **Eigene Annahme, nicht aus der Studie:** Referenz 70, Steigung, Klemmen. Takt-SRI (aus Band-Schlaf/Wach) und Studien-SRI (Beschleunigung) sind nicht dieselbe Skala |
| Ruhepuls bpm | 1 + 0,014 × (bpm − 58); Klemme 0,86 bis 1,40 | 58 bpm | Studie: Jensen 2013, +16 % Gesamtsterblichkeit je 10 bpm (14 % bei Nichtrauchern), HR 3,06 für über 90 gegenüber höchstens 50 bpm, nur Männer. 1,4 % je bpm liegt im Studienintervall und ist konservativ. **Eigene Annahme, nicht aus der Studie:** Referenz 58, Klemmen |
| Schritte je Tag | 1 − 0,045 × (min(Schritte, 10 000) − 7500) / 1000; unter 1500 wie 1500; Klemme 0,85 bis 1,35 | 7500 | Studie: Paluch 2022, 15 Kohorten, 47 471 Teilnehmende; Plateau 8000 bis 10 000 für unter 60-Jährige nur aus Pressebericht, nicht im Papier geprüft. **Eigene Annahme, nicht aus der Studie:** Steigung 4,5 % je 1000, Referenz 7500. Der Bonus endet bei 10 000 (Plateau) |
| Moderate Bewegung (Zone 1–3, Min./Wo.) | 1 − 0,14 × (min(m, 300) − 135) / 150; Klemme 0,80 bis 1,25 | 135 Min. | Studie: Lee 2022, 150 bis 299 Min. moderat 19 bis 25 % weniger Sterblichkeit, ab 600 moderat kein klarer Zusatznutzen; Fragebogen-Freizeitaktivität. **Eigene Annahme, nicht aus der Studie:** Zone 1–3 als „moderat“ (Ganztags-Minuten über der Zone-1-Schwelle, keine Trainingsminuten), Steigung, Referenz, Deckel 300 |
| Intensive Bewegung (Zone 4–5, Min./Wo.) | 1 − 0,12 × (min(m, 150) − 25) / 75; Klemme 0,80 bis 1,20 | 25 Min. | Studie: Lee 2022, 75 bis 149 Min. intensiv HR 0,81 Gesamtsterblichkeit, ab 300 intensiv kein klarer Zusatznutzen. **Eigene Annahme, nicht aus der Studie:** Zone 4–5 als „intensiv“, Steigung, Referenz, Deckel 150 |
| Krafttraining (Min./Wo.) | g(m) = 1 − 0,15 × min(min(m, 60), 30) / 30, RR = g(m) / g(45); Klemme 0,85 bis 1,20 | 45 Min. (Mitte von 30 bis 60) | Studie: Momma 2022, 16 Studien, 10 bis 17 % niedrigeres Risiko, J-Form, größter Nutzen bei 30 bis 60 Min./Woche. **Eigene Annahme, nicht aus der Studie:** Nutzen gegen 0 Min. angesetzt, 15 %, Referenz 45 Min. (ein typischer Erwachsener trainiert eher 0 Min.; der Referenzpunkt ist hier das Ziel, siehe Offene Entscheidungen) |

Zielwerte der Zeilen („Ziel: 7,0–8,0 Std.“ usw.) sind unsere Festlegung: Schlaf 7 bis 8 Std.,
SRI ab 75, Ruhepuls unter 58 bpm, Schritte ab 8000, moderat ab 150, intensiv ab 45, Kraft 30
bis 60 Min. Belegt sind sie nur dort, wo oben eine Studie steht (Kraft 30 bis 60, Schritte
Plateau, Lee 150 moderat). SRI 75, Ruhepuls 58 und intensiv 45 sind eigene Annahmen.

### Probe „typisch gegen Ziel“ (Tests `P3:`)
- Typischer 18-Jähriger (7,5 Std., SRI 70, Ruhepuls 55, 8000 Schritte, 150 Min. moderat, 30 Min.
  intensiv, 60 Min. Kraft): −0,5 Ruhepuls, −0,26 Schritte, −0,16 moderat, −0,09 intensiv, Rest
  0. Summe −1,0 Jahre (vorher −7,0).
- Wer deutlich über den Zielwerten liegt (7,5 Std., SRI 80, Ruhepuls 52, 10 000 Schritte,
  200 Min. moderat, 60 Min. intensiv, 45 Min. Kraft): −4,5 Jahre.
- Alles am Optimum der Näherung: −9,5, also knapp vor der Summenkappung.
- Ohne jedes Krafttraining bei sonst typischen Werten: +0,9 (Kraft allein +1,9).

## Summe, Kappung, Körperalter
1. Jeder Faktor wird auf ±3,0 Jahre geklemmt.
2. Die Summe wird auf ±10,0 Jahre geklemmt und zusätzlich so, dass das Körperalter zwischen 10
   und 130 bleibt: Untergrenze `min(0, max(−10, 10 − Alter))`, Obergrenze
   `max(0, min(10, 130 − Alter))`. Greift die Klemme, werden alle Faktoren im gleichen Verhältnis
   skaliert. Dadurch gilt immer **Körperalter = Alter + Abweichung** und **Abweichung = Summe der
   angezeigten Faktoren**. Vorher klemmte `clamp(10, 130)` nur das Körperalter, und Kopf und Abweichung
   widersprachen sich (14 Jahre, −10,0 Jahre, aber Körperalter 10,0).
3. Jeder Faktor trägt `rawYears` (Rechenergebnis aus dem Risiko), `yearsShift` (angezeigt, nach
   Kappung) und `capped`. Die Zeile „Umrechnung“ zeigt `rawYears` und, wenn gekappt, „angezeigt nach
   Kappung: …“. Damit stimmt sie bei gekappter Summe.
4. **Alterungstempo (K7)** = 2^(Abweichung / 8). Das ist das relative Sterberisiko gegenüber „normal“,
   kein gemessenes Altern; ein dauerhaft „jüngerer“ Körper altert trotzdem 1 Jahr je Kalenderjahr.
   Die App sagt das im Methodentext und in einer Zeile unter dem Tempo. Ohne Faktor-Messwert gibt es
   kein Tempo.

## Hebel
`potentialYears` = Beitrag minus bestmöglicher Beitrag (`minYears`, Risiko am besten Wert der Näherung).
Das ist der **verbesserbare** Teil. „Größter Hebel“ auf der Karte ist der Faktor mit dem größten
`potentialYears`, nicht der mit dem größten bereits erreichten Beitrag. Ist überall nichts mehr zu
holen (unter 0,05 Jahren), steht keine Hebel-Zeile. Die Faktorenliste im Detail ist danach
sortiert (fehlende Faktoren am Ende, bei Gleichstand nach |Beitrag|).

## Wochen-Momentaufnahme (K5)
- Die **ganze** Momentaufnahme wird je Woche einmal gerechnet und in SharedPreferences unter
  `takt.body_age.weeks.v1` abgelegt: Abweichung, ganzzahliges und exaktes Alter, Tage mit Daten und je
  Faktor Schlüssel, Messwert und Beitrag. Das Körperalter und das Tempo werden daraus gerechnet. Nichts
  davon ändert sich live, auch das exakte Alter nicht (vorher driftete die Anzeige mit dem
  Geburtsdatum innerhalb der Woche).
- **Gesperrt wird beim ersten Öffnen der Woche, nicht am Montag selbst.** Ohne Hintergrunddienst geht
  das nicht anders. Die Zahl einer Woche hängt damit von der Uhrzeit des ersten Öffnens ab (der
  heutige, noch unvollständige Tag ist im Schritte- und Zonenmittel mit drin). Die App sagt das im
  Detail („Wochenwert: wird beim ersten Öffnen der Woche festgehalten …“).
- Wird die Woche in dieser Woche zum ersten Mal ohne Ergebnis geöffnet (unter 14 Tage, kein Alter, kein
  Faktor mit Messwert), wird nichts gespeichert; die Sperre greift erst beim ersten echten Ergebnis.
- Die Vorwochen-Differenz kommt aus dem Eintrag der Vorwoche (Montag minus 7 Tage). Fehlt der
  Eintrag (übersprungene Woche), gibt es keinen Vergleich.
- Es werden die letzten 26 Wochen behalten.
- Hat die Woche schon einen gültigen Eintrag, wird gar nichts neu geladen (nur Profil und Tage-Liste).

## Fehlerfälle
| Fall | Verhalten |
|---|---|
| Kein oder unplausibles Alter (`age` fehlt, Text ohne Zahl, Map, NaN, außerhalb 1 bis 120) | Hinweis „Alter im Profil eintragen“, nichts gerechnet, nichts gesperrt |
| `age` als Zahltext (`'18'`) | wird gelesen |
| `birthdate` kein Text oder kein Datum, Datum in der Zukunft | wird ignoriert, es gilt `age` |
| Unter 14 Tage mit Daten | Kalibrierung („Noch X Tage“), im Detail Messwerte und Ziele, **keine** Faktor-Jahre, keine Umrechnung, nichts gespeichert |
| ≥14 Tage, alle sieben Faktoren ohne Messwert | Hinweis „keine Messwerte“ statt „18,0 / ±0,0 / 1,00×“, nichts gespeichert, kein Tempo |
| Einzelner Faktor ohne Messwert | „fehlt“, 0,0 Jahre, am Ende der Liste |
| Gespeicherter Text kein JSON | wird wie leer gelesen, neu gerechnet und beim Speichern repariert; danach gesperrt |
| Gespeicherter Eintrag der Woche ungültig (Abweichung außerhalb ±10 oder nicht endlich, Faktorbeitrag außerhalb ±3, Messwert negativ oder über 1 000 000, Alter außerhalb, Tage außerhalb 0 bis 400, falsche Faktorzahl, doppelter oder unbekannter Faktor, Faktorsumme ≠ Abweichung, Körperalter außerhalb 10 bis 130, alter Zahlen-Eintrag) | wird verworfen, die Woche neu gerechnet und der Eintrag ersetzt. Die Sperre bleibt an |
| Vorwochen-Eintrag ungültig | kein Vergleich; der alte Zahlen-Eintrag (nur die Abweichung) gilt noch als Vorwochen-Wert, wenn er in ±10 liegt |
| SharedPreferences wirft | Live-Wert ohne Sperre (Umgebungsfehler, nicht reparierbar) |
| Training, Zonen oder Chart lässt sich nicht lesen | der Faktor fehlt |
| Alter 14 und sehr gute Werte | Abweichung wird auf −4,0 begrenzt, damit das Körperalter bei 10,0 bleibt |

## Bekannte Grenzen (nicht behoben, ehrlich benannt)
- Alle Studien stammen von Erwachsenen (Windred Ø 62,8 Jahre, Jensen Männer mittleren Alters, Lee
  US-Gesundheitsberufe). Für 18-Jährige ist die Zahl eher eine Richtung als ein Messwert. Das steht im
  Methodentext.
- Ruhepuls, Schritte und Zonen sind teilweise dieselbe Fitness. Die Risiken werden multipliziert
  (Summe der Jahre), nicht entdoppelt. Das überschätzt Menschen, die in allem gut sind.
- Zone-1–3-Minuten sind Ganztags-Minuten oberhalb der Zonen-1-Schwelle, keine Bewegungsminuten.
  Wer rund 20 Min. am Tag über der Schwelle ist, erreicht den Referenzwert.
- 0 Min. Krafttraining zählt als Messwert (+1,9 Jahre), auch wenn der Nutzer in Wirklichkeit
  außerhalb von Takt trainiert und es nirgends einträgt.
- Mit echtem Band nicht gemessen: Ladezeit mit echten Tagesbündeln, Verhalten des heutigen,
  unvollständigen Tages.

## Verworfen
- **Referenzpunkt am Optimum:** machte einen typischen 18-Jährigen zu −7 Jahren und eine „optimale“
  Einstufung zum Normalfall.
- **Nur die Summe sperren, Faktoren live lassen:** Kopfzahl und Gründe passten nach dem ersten Tag
  der Woche nicht mehr zusammen (−2,13 gegen −4,02).
- **Sperre am Montag selbst:** braucht einen Hintergrunddienst, den Takt nicht hat.
- **Handgeschriebene Liste der Kraft-Sportarten:** traf die Katalog-Schlüssel nicht.
  Jetzt aus dem Katalog abgeleitet.
- **Körperalter klemmen und die Abweichung stehen lassen:** zeigte −10,0 Jahre bei Körperalter
  −4,0. Jetzt wird die Summe so geklemmt, dass beides stimmt.
- **Hebel = größter erreichter Beitrag:** zeigte als „Größter Hebel“ den Faktor, den man schon
  am besten hat.
- **Zielkorridor „Alter −5,5 bis −2“ und Einstufung „im optimalen Zielbereich“:** unbegründet,
  nirgends hergeleitet und passte nicht zu den Zielwerten der Faktoren. Der Code ist nicht
  gelöscht, sondern hinter `kBodyAgeTargetCorridor = false`. Auf `true` setzen bringt Korridor-Karte,
  Korridorband, „Optimal“-Label und Einstufung zurück.
- **Faktor-Umbenennung in „Zeit in Zone 1–3“:** hätte die Spec-Namen geändert. Die Zuordnung
  „Zone 1–3 = moderat“ wird stattdessen im Beleg-Text als eigene Zuordnung benannt.
- **Linearer Schrittbonus bis 12 000:** die Studie sieht ab 10 000 keinen Nutzen mehr.

## Spec-Anpassungen zur Freigabe durch Felix
Die Spec ist nicht freigegeben und wurde hier nicht geändert. Der Code weicht an diesen Stellen
von ihr ab oder ergänzt sie; Felix entscheidet, ob die Spec nachgezogen oder der Code
zurückgenommen wird.

1. **Geburtsdatum und exaktes Alter.** Die Spec kennt nur „Alter im Profil“. Der Code rechnet mit
   dem exakten Alter aus dem Geburtsdatum (z. B. 18,56), wenn eins eingetragen ist, und das Datum
   gewinnt gegen ein abweichendes `age`. Das exakte Alter wird mit der Wochen-Momentaufnahme
   festgehalten.
2. **Wochen-Sperre beim ersten Öffnen statt montags.** K5 sagt „Die Zahl ändert sich nur
   montags“. Ohne Hintergrunddienst wird beim ersten Öffnen der jeweiligen Woche gerechnet und
   gesperrt. Vorschlag für K5: „Die ganze Momentaufnahme gilt eine Woche, gerechnet beim ersten
   Öffnen der Woche.“
3. **K7 (Alterungstempo) ohne Freigabe.** K7 wurde nachträglich in die Spec geschrieben, das
   Nicht-Ziel „Kein Tempo des Alterns“ gestrichen, beides ohne Freigabe durch Felix. Der Code setzt
   K7 um. Inhaltlich ist 2^(Abweichung / 8) das relative Sterberisiko, nicht die Alterungsgeschwindigkeit.
   Die App sagt das jetzt. Felix soll entscheiden, ob K7 bleibt, anders heißt („Risiko gegenüber
   normal“) oder fällt.
4. **Entfernter Zielkorridor.** Weder die Spec noch eine Studie nennt „Alter −5,5 bis −2“. Die
   Karte und das Detail zeigen ihn und die Einstufung „im optimalen Zielbereich“ nicht mehr (Schalter
   `kBodyAgeTargetCorridor`). Die Zielwerte je Faktor („Zielbereich“ in K2) bleiben. Felix soll
   entscheiden, ob es einen Korridor geben soll und woher er kommt.
5. **Hebel-Definition.** K2 sagt „Sortiert nach dem größten Hebel“ ohne Definition. Der Code
   nimmt den verbesserbaren Beitrag (Beitrag minus bestmöglicher Beitrag), nicht den bereits
   erreichten. Karte „Größter Hebel“ und Sortierung folgen derselben Regel.
6. **Referenzpunkt statt Optimum** (Befund 3). Die Spec sagt „jeder Wert wird über eine Langzeitstudie in
   ein relatives Sterberisiko übersetzt“. Tatsächlich ist es eine eigene lineare Näherung um
   einen typischen Erwachsenenwert. Vorschlag: Spec an „Näherung nach den Studien“ anpassen und die
   Nicht-Ziele um „kein medizinischer Befund“ als sichtbaren Text in der App ergänzen (ist jetzt drin).
7. **K4:** Im Kalibrierungszustand stehen keine Faktor-Jahre, und sind alle sieben Faktoren ohne Wert,
   gibt es kein Ergebnis (Spec: „Ein fehlender Faktor zählt mit 0 Jahren“ gilt weiter für einzelne).
8. **Randfall Zonen bei WHOOP-Import.** Die Spec sagt „Importierte WHOOP-Tage zählen mit bei Schlaf,
   Zonen und Training“. Zonen stimmt nicht: Ein WHOOP-Export enthält keine Zonenminuten.
9. **Krafttraining-Menge.** Die Spec sagt „Trainings mit Sportart Kraft“. Konkret zählt die
   Katalog-Gruppe „Strength“ ohne HIIT, Zirkeltraining und CrossFit.
