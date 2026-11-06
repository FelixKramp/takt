# Plan: Heute-Screen

Fortschritt: 10/11 Aufgaben · nächste: 11

| Anforderung | Aufgaben |
|---|---|
| A1, A4, A5 | 5, 8 |
| A2, A3, A20 | 3, 5 |
| A6, A7, A18, A19 | 4 |
| A8, A9, A10, A11, A21, A22 | 6, 7 |
| A12, A13, A14, A23 | 8 |
| A15, A16 | 2, 9 |
| A17 | 10 |
| A24 | 3, 4, 7 |
| A25 | 9 |

## Aufgaben
- [x] 1. Grundlage: Abhängigkeiten holen, bestehende Testsuite läuft, Debug-APK baut (Toolchain, pub get)
- [x] 2. Eigene Identität: `applicationId`, Name Takt, Icon, `lib/takt/brand.dart` (A15) (A15, Icon aus tool/takt/make_icon.py)
- [x] 3. Pult-Theme, Schriften und Drehregler-Ring mit Kalibrier-Zustand (A2, A20, A24) (A2, A20, A24)
- [x] 4. Puls-Display: live, letzter Wert grau, nie gemessen, Strom nur während sichtbar (A6, A7, A18, A19, A24) (A6, A7, A18, A19)
- [x] 5. Neuer Heute-Screen mit Ringen und Karten, im Shell eingehängt (A1, A2, A3, A4) (A1 bis A4)
- [x] 6. Automatisches Bestätigen erkannter Workouts (A8, A9) (A8)
- [x] 7. Aktivitätenliste mit Nachtragen, leer und viele Einträge (A8–A11, A21, A22, A24) (A9 bis A11, A21, A22)
- [x] 8. Sync beim Öffnen, Frische-Anzeige, laufendes Workout, alter Heute-Screen im Gesundheit-Tab (A5, A12, A13, A14, A23) (A5, A12, A13; A14 und A23 nur auf dem Gerät prüfbar)
- [x] 9. Über-diese-App, Update-Prüfung, Fehlerberichte an OpenStrap aus (A16, A25) (A16, A25)
- [x] 10. Datenübernahme aus Edge prüfen und Release-APK bauen (A17; Import ist Upstream-Funktion, Beweis steht im Gerätetest aus)
- [ ] 11. 🙋 Gerätetest durch Felix: Band umziehen, A6, A12, A14 prüfen
