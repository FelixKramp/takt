# Plan: Körperalter (Feature 10)

Anforderungs-IDs aus `spec.md` (K1 bis K7). Befund-Nummern aus `pruefung.md` (Nacharbeit, Gruppe A). Tests
in `test/takt/body_age_test.dart` und `test/takt/settings_studies_test.dart`, Befund-Tests heißen `P<Nr>: …`.

## Erstbau
- [x] 10-1 Rechnung `BodyAgeCalculator`: sieben Faktoren, Kappung ±3 und ±10, Tempo (K1, K2, K4, K7). Tests `K1 + K2`, `K7`, `K4`, `Kappung`
- [x] 10-2 `loadBodyAge`: 30-Tage-Werte aus dem Repository, Wochen-Speicher (K5). Test `K5: mondayOfWeek`
- [x] 10-3 Karte, Detail, Leiste im Takt-Design, jede Ziffer in `StripeDodge` (K1, K2, K3, K6). Tests `K1 + K3 + K6`, `K1 + K6`, `K4: zeigt Kalibrierungs-Hinweis`
- [x] 10-4 Studien-Bildschirm und Einstellungszeile. Test in `settings_studies_test.dart`

## Nacharbeit nach der Prüfung (Gruppe A)
- [x] 10-5 Krafttraining aus dem Katalog ableiten, WHOOP-Mapping, Alt-Aliasse, Kalenderspanne statt Tage mit Daten (Befund 1). Tests `P1:` (drei)
- [x] 10-6 Ganze Wochen-Momentaufnahme je Woche einmal, bis zur nächsten Woche gesperrt, exaktes Alter gesperrt, beim ersten Öffnen der Woche (K5, Befund 2). Test `P2:`
- [x] 10-7 Referenzpunkte auf typische Erwachsenenwerte, Zielkorridor und „optimaler Zielbereich“ hinter Schalter, Hebel = verbesserbarer Beitrag, Beleg-Status in `architektur.md` (Befund 3). Tests `P3:` (sechs)
- [x] 10-8 Ehrlichkeit: Studientexte nur mit Belegtem, Schrittbonus bis 10 000, Zonenzuordnung als eigene, „eigene Näherung“ und „grobe Schätzung, kein medizinischer Befund“ auf Karte, Detail, Studien-Bildschirm, Einstellungszeile ohne „7 Kohortenstudien“ (Befund 4). Tests `P4:` (fünf)
- [x] 10-9 K4: Kalibrierung ohne Faktor-Jahre, kein Ergebnis und kein Wochenwert ohne Faktor-Messwert (Befund 5). Tests `P5:` (drei)
- [x] 10-10 Kappung: Umrechnungs-Zeile bei gekappter Summe, Körperalter und Abweichung konsistent (Befund 6). Tests `P6:` (zwei)
- [x] 10-11 Layout: Überlauf 320 px / Textgröße 2,0 auf der Karte, englisches „y“, keine rohen Farben, Studien-Bildschirm-Zeile (Befund 7). Tests `P7:` (fünf)
- [x] 10-12 Robustheit: gespeicherte Werte prüfen, neu rechnen und reparieren, falsche Typen im Profil (Befund 8). Tests `P8:` (mehrere)
- [x] 10-13 `architektur.md`, `plan.md`, Abschnitt „Spec-Anpassungen zur Freigabe durch Felix“ (Befund 9, 12)
- [ ] 10-14 🙋 Felix: Spec-Anpassungen und offene Entscheidungen aus `architektur.md` freigeben (Zielkorridor, K7, Krafttraining-Referenz, Kettlebell und CrossFit)
- [ ] 10-15 🙋 Gerätetest: Karte im Gesundheit-Tab, Detail, Wochenwert über einen Montag, mit echten Bandtagen

## Nicht in dieser Gruppe
- `health_screen.dart` (Regression „Recovery · null“ aus Befund 2 der Prüfung, Tab-Verhalten), `loadBodyAge`-Aufruf im Gesundheit-Tab
  mit ungeschütztem `HealthData.load`: gehören anderen Gruppen. `loadBodyAge` fängt falsche Profil-Typen jetzt selbst ab.
