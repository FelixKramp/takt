# Plan: Journal im Takt-Design mit Morgenblatt und Auswertung (Feature 13)

Anforderungs-IDs aus `spec.md` (J1 bis J27). Architektur aus `architektur.md`.
Tests in `test/takt/journal_test.dart` und `test/takt/journal_privacy_test.dart`.

## Schrittfolge (Test-Driven: Rot vor Grün)

### Phase 1: Daten & Seed & Privatsphäre (J9, J10, J11, J20)
- [x] 13-1 `JournalConfig` (`lib/takt/journal/journal_config.dart`):
  - Speichert Einstellungen in SharedPreferences (`takt.journal.config.v1`):
    - Anzeigenamen (J10)
    - Ein/Aus im Morgenblatt (`showInSheet`, J11)
    - Ausgeblendet / gelöscht (`hidden`, J11)
    - Reihenfolge / Abschnitt (`section`: `yesterday` oder `today`, J9)
    - Privat (`isPrivate`, J20)
  - Standardfragen (`vitamin_d`, `read_evening`, `meat`, `priv_solo`, `feeling`).
  - Schlüssel mit `priv_` sind immer privat.
  - Test zuerst: `test/takt/journal_test.dart` (Gruppe 1: Config & Standardfragen).
- [x] 13-2 `journalSeed` (`lib/takt/journal/journal_seed.dart`):
  - Legt die 5 Standardfelder in `journal_field_def` an, falls nicht vorhanden.
  - Überschreibt bestehende Felder nicht.
  - Test zuerst: `test/takt/journal_test.dart` (Gruppe 2: Seed idempotenz).
- [x] 13-3 Privatsphäre nach außen (J20):
  - `lib/data/csv_export.dart`: `WHERE j.field NOT LIKE 'priv_%'` in `habits`-Export.
  - `lib/data/recent_slice.dart`: `journal_metric` filtert `field NOT LIKE 'priv_%'`.
  - Test zuerst: `test/takt/journal_privacy_test.dart` (J20: CSV-Export und Recent-Slice enthalten kein `priv_solo`).

### Phase 2: Morgenblatt-Entscheidungsregel (J1, J7, J8, J21, J22, J25)
- [x] 13-4 `MorningSheetRule` (`lib/takt/journal/morning_sheet_rule.dart`):
  - Reine Logik-Funktion:
    - Eingaben: `now`, `activeDayId`, `calToday`, `todayHasSleep`, `nightInProgress`, `lastDismissedOrCompletedDay`, `answeredKeys`
    - Prüfung J22: Wenn `now.hour < 12` und aktiver Tag ist gestern -> `shouldShow = false`.
    - Prüfung J1, J21: Berechnete Nacht heute (`todayHasSleep && !nightInProgress`) ODER `now.hour >= 10`.
    - Prüfung J7, J25: Wenn `lastDismissedOrCompletedDay == calToday` -> `shouldShow = false`.
    - Prüfung J8: Wenn alle für das Blatt aktiven Fragen für gestern/heute bereits beantwortet sind -> `shouldShow = false`.
    - Liefert `shouldShow: bool` und `prefilled: Map<String, int>`.
  - Test zuerst: `test/takt/journal_test.dart` (Gruppe 3: Morgenblatt-Regel).

### Phase 3: Morgenblatt-Widget (J2 bis J6, J18, J19, J23, J24)
- [x] 13-5 `MorningSheet` (`lib/takt/journal/morning_sheet.dart`) & Texte (`journal_text.dart`):
  - Header „Gestern (Tag)“ mit Ja/Nein für Vitamin D, Gelesen, Fleisch, Private Frage (J2).
  - Header „Heute“ mit „Wie fühlst du dich?“ (4 Stufen: schlecht, geht so, gut, sehr gut) (J3).
  - Ein Tipp setzt/entfernt Antwort (Toggle, J4).
  - Unbeantwortet bleibt `null` (kein Nein, J6).
  - „Fertig“-Taste speichert Antworten: Gestern nach gestern, Heute nach heute (J5).
  - „Später“ / Wegwischen speichert nichts, merkt `lastDismissedOrCompletedDay = calToday` (J7).
  - Link „Journal öffnen“ (J7).
  - Fehlerbehandlung bei Schreibfehler: Fehlermeldung mit „Nochmal“, Antworten bleiben erhalten (J23).
  - Takt-Design (J18), StripeDodge für alle Ziffern (J19), kein Textfeld (J4).
  - Test zuerst: `test/takt/journal_test.dart` (Gruppe 4: Morgenblatt Interaktion, Speichern, Fehlerbehandlung).

### Phase 4: Auswertung „Was tut mir gut“ (J12 bis J17)
- [x] 13-6 Verzögerung für Ja/Nein-Gewohnheiten:
  - `lib/data/local_repository_impl.dart` (`_numericJournalInsights`): alle Ja/Nein-Felder (max == 1) erhalten `fieldLagDays = 1` (J16).
  - Test zuerst: `test/takt/journal_test.dart` (Gruppe 5: Lag-Zuweisung).
- [x] 13-7 `JournalEvidence` (`lib/takt/journal/journal_evidence.dart`):
  - Rechnet Tage mit Ja (1) und Nein (0) gepaart mit nächster Nacht (D+1) für Readiness, RMSSD, RHR, Efficiency (J12, J16, J17).
  - Nur gemessene Tage / eigene Nächte (kein WHOOP-Import, keine Nächte ohne Messung, J17).
  - Zählstand: wenn < 5 Ja oder < 5 Nein -> Status „Ja X von 5, Nein Y von 5“, keine Mittelwerte (J13).
  - Wenn >= 5 Ja und >= 5 Nein: Mittelwert Ja vs Nein, Differenz in Prozentpunkten (J12).
  - Einstufung: „Hilft“ / „Kostet“ nur bei statistischer Signifikanz aus `getJournalInsights`, sonst „Kein Unterschied erkennbar“ (J14).
  - Formulierung „geht zusammen mit“ (J14).
  - Sortierung (J15): Hilft (nach Differenz), Kostet, Kein Unterschied, Zu wenig Tage.
  - Test zuerst: `test/takt/journal_test.dart` (Gruppe 6: Evidence Berechnung & Sortierung).

### Phase 5: Tab „Journal“ in Gesundheit & Eigene Fragen (J9, J10, J11, J26, J27)
- [x] 13-8 `NewQuestionSheet` & Frage-Verwaltung (`lib/takt/journal/new_question_sheet.dart`):
  - Eigene Ja/Nein-Frage anlegen mit Name, Bezug (gestern/heute), privat (J9, J20).
  - Anzeigename ändern (J10).
  - Im Morgenblatt ein-/ausschalten, umbenennen, löschen/ausblenden (J11).
  - Test zuerst: `test/takt/journal_test.dart` (Gruppe 7: Frage-Verwaltung).
- [x] 13-9 `JournalTab` (`lib/takt/journal/journal_tab.dart`):
  - Kopf: „Heute eintragen“ -> öffnet vollen Journal-Screen (J27).
  - Mitte: Auswertung „Was tut mir gut“ mit Zeilen (J12-J15).
  - Unten: Fragenliste mit Schaltern, Anzeigenamen, „Eigene Frage“ Knopf (J9-J11, J27).
  - StripeDodge für Ziffern (J19), Takt-Design.
- [x] 13-10 `health_screen.dart` Integration (J26):
  - Takt-Tabs: `[Übersicht, Vitalwerte, Journal]` (Erkunden & Labore nicht in Takt-Leiste).
  - Tab 2 zeigt `JournalTab`.
  - Test zuerst: `test/takt/journal_test.dart` (Gruppe 8: Health Screen Takt-Tabs).

### Phase 6: Einbindung in Heute-Screen (J1, J7, J21, J22)
- [x] 13-11 `TaktTodayScreen` Integration:
  - Nach `_load()`: Prüfen von `MorningSheetRule`.
  - Wenn `shouldShow`: `showModalBottomSheet` mit `MorningSheet`.
  - Test zuerst: `test/takt/journal_test.dart` (Gruppe 9: Heute-Screen automatisches Morgenblatt).

### Phase 7: Responsive & Barrierefreiheit (J24) & Verifikation
- [x] 13-12 Layoutprüfung bei 320 px Breite, Schriftfaktor 2.0, Deutsch und Englisch (J24).
- [x] 13-13 Gesamttests & `flutter analyze`.
- [x] 13-14 Unabhängige Prüfung / Audit aller Akzeptanzkriterien J1 bis J27.
