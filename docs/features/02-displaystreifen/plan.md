---
feature: 02-displaystreifen
---
# Plan: Displaystreifen

- [x] **T1** `placeBlock` und `StripeDodge` (Block und Zeile) mit Tests · B2, B3, B4 — `test/takt/stripe_test.dart`. Abweichung: Platzierung rechnet mit der Glyphenausdehnung, Reserve fest 36 Punkte.
- [x] **T2** `TaktStripe` speichern/laden, Einstellscreen, Zeile in den Einstellungen · B1 — `test/takt/stripe_setup_test.dart`
- [x] **T3** Heute-Screen umstellen, Test: keine Ziffer auf dem Streifen, alle Ziffern abgedeckt · B2, B4, B5 — `test/takt/stripe_today_test.dart`, Streifen von 5 bis 95 % in 2,5-%-Schritten, auch bei doppelter Schrift
- [x] **T4** Designregel B5 in CLAUDE.md (Konventionen) festgehalten, Version 0.1.3, Release-APK
- [ ] 🙋 **T5** Gerätetest: Streifen einstellen, Heute-Screen ansehen, Schrittzahl ganz lesbar
