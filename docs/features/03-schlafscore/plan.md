---
feature: 03-schlafscore
---
# Plan: Schlafscore und Schlaf-Tab

- [x] **T1** `sleep_score.dart`: Rechnung, fehlende Teile, Stufen, Farben · C1, C2, C3, C12 — `sleep_score_test.dart`. Abweichung: Text-Blau dunkler (`#2552AD`), weil `#2F62C9` auf dem Grund nur 4,0:1 erreicht
- [x] **T2** `night_log.dart`: Tagesnotiz schreiben, lesen, kürzen; Bedarf für eine Nacht · C1, C6, C7 — `night_log_test.dart`
- [x] **T3** `sleep_tab_data.dart`: Lader aus dem Repository zu einem reinen Modell · C4–C8, C10 — `sleep_tab_data_test.dart`
- [x] **T4** `sleep_head.dart`: Kopf, Teile, sieben Nächte · C4, C5, C12, C13 — `sleep_head_test.dart`
- [x] **T5** `sleep_head.dart`: Dauer und Bedarf, Regelmäßigkeit, Effizienz · C6, C7, C8, C13 — `sleep_head_test.dart`, Streifen 5–95 %
- [x] **T6** Einhängen in `SleepDetail`/`SleepTab`, Rest bleibt · C9, C10 — `sleep_tab_hook_test.dart`, Loader liest bei jeder Revision neu (Korrektur)
- [x] **T7** Schlafring auf Heute · C11, C12 — `today_view_test.dart` (C11). Score lädt getrennt vom Heute-Screen, sonst warten Ringe und Puls auf die Schlafabfragen
- [x] **T8** Suite, Analyse, Version 0.2.0, Release-APK — volle Suite: nur die 5 bekannten Fehlschläge von vor Feature 02
- [ ] 🙋 **T9** Gerätetest durch Felix
