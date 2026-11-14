# Architektur: Journal im Takt-Design mit Morgenblatt und Auswertung (Feature 13)

Gehört zu [spec.md](spec.md) (freigegeben 2026-11-12). Status: Entwurf, wartet auf Freigabe durch Felix.

## Was schon da ist (und nicht neu gebaut wird)
- **Antworten speichern:** Tabelle `journal_metric` (Tag, Feld, Zahl). Die Zugriffe `getJournalMetrics`,
  `postJournalMetrics` und `editJournalMetrics` im Repository gibt es. `editJournalMetrics` ändert nur
  die genannten Felder eines Tages, nicht den ganzen Tag.
- **Eigene Felder:** Tabelle `journal_field_def` (Name, Art, Einheit, Höchstwert, Schritt). Ein Feld mit
  Höchstwert 1 und Schritt 1 ist eine Ja/Nein-Frage. Die Rechnung in `getJournalInsights` erkennt Felder
  mit nur 0 und 1 als „Gewohnheit“ und vergleicht dann Tage mit und ohne.
- **Rechnung:** Vergleich der Mittelwerte mit Zufallstest und Fehlerkontrolle (q-Wert) gegen Ladung,
  HRV, Ruhepuls und Schlafeffizienz. Sie nimmt nur gemessene Nächte, keine WHOOP-Importtage.

## Neue Bestandteile (alles unter `lib/takt/journal/`)
| Datei | Aufgabe |
|---|---|
| `journal_config.dart` | Die Einstellungen je Frage: Anzeigename, im Blatt ja/nein, gestern oder heute, ausgeblendet, Reihenfolge. Liegt als JSON in den SharedPreferences (`takt.journal.config.v1`). Die vier Standardfragen und das Gefühl stehen als feste Liste im Code. |
| `journal_seed.dart` | Legt beim ersten Gebrauch die fünf Felder in `journal_field_def` an (Vitamin D, Gelesen, Fleisch, Private Frage, Gefühl), wenn sie fehlen. Nichts wird überschrieben. |
| `morning_sheet_rule.dart` | Reine Entscheidung, ob das Blatt jetzt kommt (J1, J7, J8, J21, J22). Eingaben: Uhrzeit, ob die Nacht berechnet ist, zuletzt behandelter Tag, schon beantwortete Fragen. |
| `morning_sheet.dart` | Das Blatt im Takt-Design (J2 bis J6, J23). |
| `journal_evidence.dart` | Reine Rechnung für die Auswertung: Tage mit Ja und Nein, Durchschnitt je Seite, Differenz, Zählstand, Einstufung (J12 bis J17). |
| `journal_tab.dart` | Der Tab „Journal“ in Gesundheit: Eintragen, Auswertung, Fragenliste (J27). |
| `new_question_sheet.dart` | „Eigene Frage“ anlegen (J9), dazu Anzeigename, Umbenennen, Ausblenden (J10, J11). |
| `journal_text.dart` | Alle Texte, deutsch und englisch (wie `TaktText`). |

## Stellen in Upstream-Dateien (klein, mit `TAKT (Feature 13)` markiert)
1. **`lib/ui2/screens/health_screen.dart`:** Die Takt-Leiste wird `[Übersicht, Vitalwerte, Journal]`
   (`_taktOrder` und ein neuer Zweig im `switch`). Erkunden und Labore bleiben im Code und in der
   Upstream-Leiste (J26).
2. **`lib/takt/today/takt_today_screen.dart`** (Takt-Datei): nach dem Laden die Regel prüfen und das
   Blatt als `showModalBottomSheet` öffnen.
3. **`lib/data/local_repository_impl.dart`, `_numericJournalInsights`:** Die Karte der Verzögerungen
   (`kJournalFieldLagDays`) bekommt zusätzlich alle eigenen Felder mit Höchstwert 1 mit Verzögerung 1.
   Ohne das paart die Rechnung Ja/Nein-Fragen mit der Ladung **desselben** Tages. Verlangt wird die
   Ladung des Morgens danach (J16). Die eingebauten Felder bleiben unverändert.
4. **`lib/data/csv_export.dart`, Satz `habits`:** Zeilen mit Schlüssel `priv_…` fallen heraus (J20).
5. **`lib/data/recent_slice.dart`, Tabelle `journal_metric`:** Der Fehlerbericht kopiert die Tabelle
   ganz. Dort kommt eine `WHERE`-Bedingung hinein, die `priv_…` auslässt (J20).
6. **`lib/ui2/screens/journal_compose.dart`:** Der Bildschirm wird in `TaktLook` geöffnet. Nur dort, wo
   die Takt-Bausteine nicht reichen (Ja/Nein-Felder als Stepper), gibt es eine Takt-Variante (J18).

## Datenmodell
- **Antworten:** `journal_metric`, ein Eintrag je Tag und Frage. Ja = 1, Nein = 0, Gefühl = 1 bis 4.
  Nicht beantwortet = kein Eintrag. Das schützt J6.
- **Schlüssel der Standardfragen:** `vitamin_d`, `read_evening`, `meat`, `priv_solo`, `feeling`.
  **Privat ist der Schlüssel:** Beginnt er mit `priv_`, ist er privat. Das lässt sich später nicht
  ändern, weil ein Schlüssel nie umbenannt wird (sonst verwaist der Verlauf). Eigene Fragen bekommen
  diese Wahl deshalb beim Anlegen.
- **Gefühl:** ein `rating`-Feld mit Höchstwert 4. Die Rechnung nimmt es mit Verzögerung 0 auf, es
  wird aber in diesem Feature nicht ausgewertet (Nicht-Ziel).
- **Zuletzt behandelter Tag:** `takt.journal.sheet.last` in den SharedPreferences, ein Tagesetikett.
- **Anzeigenamen und Schalter:** nur in der Takt-Einstellung, nie in der Datenbank. So bleibt das
  Schema von Upstream unverändert (kein `ALTER TABLE` in der riesigen `db.dart`).

## Rechte und Datenschutz
- Alles liegt auf dem Gerät. Neu geht nichts ins Netz.
- **Wege nach außen und was passiert:**
  | Weg | Zeigt Journal-Werte? | Maßnahme |
  |---|---|---|
  | CSV-Export `habits` | ja | `priv_…` herausfiltern (Stelle 4) |
  | Fehlerbericht (letzte 14 Tage der Datenbank) | ja | `priv_…` auslassen (Stelle 5) |
  | KI-Coach | nein, liest nur die Ansichten `v_metric`, `v_daily`, `v_series`, `v_hypnogram`, `v_sessions`, `v_baselines`, `v_insights`, `v_ecg_readings` | im Plan prüfen, ob `v_insights` Journal-Werte enthält |
  | KI-Journal-Chat | nein, schreibt nur Tags und Notiz | keine |
  | Benachrichtigungen | nein, der Abend-Check-in prüft nur eingebaute Ratings | keine |
- Ein Test je Weg: ein Eintrag `priv_solo` darf dort nicht auftauchen (J20).

## Auswertung: wie die Zahlen entstehen
- **Quelle der Zahlen:** Ladung (`readiness`), HRV (`rmssd`), Ruhepuls (`rhr`), Schlafeffizienz
  (`efficiency`) aus `metric_series`, nur gemessene Tage (`importedDates()` und `metricNotOursDates()`
  herausgenommen, wie in der Rechnung selbst, J17).
- **Zeitbezug:** Antwort für Tag D wird mit Tag D+1 gepaart (J16).
- **Durchschnitte und Zählstand** rechnet `journal_evidence.dart` selbst, weil die Rechnung der App nur
  Ergebnisse liefert, die belastbar sind, und die Zahlen dahinter (Tage je Seite) nur dann.
- **Einstufung:** „Hilft“ oder „Kostet“, wenn die Rechnung der App für die Frage und die Ladung einen
  belastbaren Eintrag liefert (`binary`, `helped`); sonst bei mindestens 5 und 5 Tagen „Kein
  Unterschied erkennbar“; sonst „Zu wenig Tage“ mit Zählstand (J13, J14).
- **Wann sie läuft:** beim Öffnen des Tabs, nicht beim Start der App. `getJournalInsights` wird in
  Wellness und im Metrik-Detail schon genauso aufgerufen. Läuft sie spürbar langsam, kommt im Plan eine
  Aufgabe dazu, sie in einen Isolate zu legen (wie `getWeekdayEffect`).

## Verhalten bei Fehlern
- **Speichern scheitert (J23):** Das Blatt bleibt offen, die Antworten bleiben im Zustand des Blatts,
  eine Fehlerzeile mit „Nochmal“. Der „zuletzt behandelt“-Eintrag wird erst nach erfolgreichem Speichern
  geschrieben.
- **Seed scheitert:** Das Blatt kommt nicht, und der Tab zeigt „Journal nicht verfügbar“ mit „Nochmal“.
  Es gibt keinen Rückfall auf halb angelegte Felder.
- **Auswertung scheitert:** Der Tab zeigt Eintragen und Fragen weiter, die Auswertung eine Fehlerzeile.
- **Keine Daten:** Zählstand statt Zahlen, nie ein erfundener Wert.

## Entscheidungen mit verworfenen Alternativen
| Entscheidung | Verworfen | Grund |
|---|---|---|
| Ja/Nein als Feld mit Höchstwert 1 in `journal_field_def` | neue Art `yesno` in `JournalFieldKind` | Die Rechnung erkennt 0/1 schon als Gewohnheit. Eine neue Art hieße Änderungen an der Enum und an jedem `switch` in Upstream. |
| Privat über Schlüsselvorsatz `priv_` | eigene Tabelle für private Antworten | Die Rechnung sähe sie dann nicht, und der Fehlerbericht kopiert unbekannte Tabellen bis zu einer Zeilengrenze ganz. |
| Anzeigenamen und Schalter in SharedPreferences | neue Spalten in `journal_field_def` | Schemaänderung in `db.dart` erschwert `git merge upstream/main`. |
| Standardfragen als Zeilen in `journal_field_def` (Seed) | als Konstanten in `kJournalFields` | Die Konstanten liegen in Upstream. Der Seed hält alles unter `lib/takt/`. Nachteil: die Beschriftung im vollen Journal-Bildschirm kommt aus der Zeile (deutsch). |
| Durchschnitte selbst rechnen, Einstufung von der App-Rechnung | alles selbst rechnen | Die Rechnung rechnet Zufall heraus (Permutationstest, q-Wert). Das nachzubauen wäre fehleranfällig. |
| Blatt-Bedingung unabhängig vom aktiven Tag: Nacht berechnet **oder** ab 10 Uhr | „aktiver Tag ist heute“ | Der aktive Tag bleibt vor 12 Uhr beim Vortag, wenn heute noch keine Nacht da ist. Dann käme das Blatt erst um 12 statt um 10. J22 (01:00 Uhr) gilt trotzdem. |

## Manuelle Aufgaben für Felix
Keine. Es gibt keine Schlüssel, Konten oder Dienste.

## Auswirkungen
- **Erkunden und Labore** sind in Takt nicht mehr erreichbar (J26).
- **Der volle Journal-Bildschirm** zeigt die Standardfragen wegen des Seeds mit deutschen Namen.
- **Eigene Fragen** haben das „privat“ nur beim Anlegen.
