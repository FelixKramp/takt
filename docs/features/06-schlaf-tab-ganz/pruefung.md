---
feature: 06-schlaf-tab-ganz
geprueft: 2026-11-08
stand: 3b0c563a
pruefer: unabhängiger Prüfer-Agent (Phase 5, Runde 3)
---
# Prüfung: Schlaf-Tab ganz im Takt-Design, Tab-Leiste (06)

Runde 3, 2026-11-08

## Grundlage Runde 3
- Spec, Bericht Runde 2 und `git show 3b0c563a` gelesen, `plan.md` bewusst nicht.
- `flutter test test/takt`: 169 Tests, alle grün. `flutter analyze lib/takt lib/ui2`: keine Befunde.
- `schlaf_tab.png` neu erzeugt, oberen Teil bis „Phasen“ angesehen.
- Eigene Wegwerf-Tests unter `build/` (ignoriert, danach gelöscht), echte Schriften, 390 pt: Korrekturkarte für `auto`, `auto_fallback`, `vendor_staged`, `manual` (mit `solMin`) und `confirmed`, Zeilen jedes Absatzes gezählt; die beiden Hinweise `uncorrectable`/`eveningPruned` auf Kartenbreite gemessen (sie brauchen ein Repo, um in der Karte zu erscheinen); Nacht ohne Phasen; Ziffern ohne `RenderStripeDodge`-Vorfahr im Fall `manual`/`confirmed`.

## Ergebnis Runde 3
✅ 15 · ❌ 1 · ⚪ 1

| ID | Ergebnis | Begründung |
|---|---|---|
| F6 | ✅ | Behoben. Im Takt-Zweig kurze eigene Sätze statt Kappen (`sleep_text.dart:17–23`, `sleep_detail.dart:1082–1106`, `:1180–1192`): „Zeitraum automatisch erkannt“, „Zeitraum aus dem Puls geschätzt“, „Phasen vom Gerät“, „Zeitraum von dir gesetzt“, „Beginn und Ende sind geschätzt.“ stehen gemessen je in einer Zeile, auch in der Fallback-Nacht mit „Ja, diese Zeiten stimmen“. „Nicht mehr korrigierbar.“ (146 pt) und „Nur Bettzeit nach Mitternacht oder „Kein Schlaf“.“ (303 pt) passen auf Kartenbreite (326 pt), in der Karte selbst nur am Code geprüft. Foto: „Zeitraum automatisch erkannt“ ganz, einzeilig. `maxLines` ist entfallen, die Einzeiligkeit hängt also an der Satzlänge, bei sehr großer Schrift kann sie umbrechen (vertretbar). Test `review_fixes_test.dart` F6 Runde 2 zählt echte Zeilen und kann scheitern. Grenzfall: Die Einschlaf-Zeile auf einem selbst gesetzten Zeitraum ist zweizeilig, sie ist aber ein Messwert, kein Korrektur-Hinweis; ihr eigentliches Problem steht unter F13. |
| F13 | ❌ | **Neu gefunden** (in Runde 2 nicht durchlaufen: kein Fall `manual`/`confirmed`). Auf einem selbst gesetzten oder bestätigten Zeitraum mit `solMin` steht in der Korrekturkarte „Vom Beginn des Zeitraums bis zum Einschlafen: 15–30 Minuten.“ (`sleep_detail.dart:1119–1126`, kein Takt-Zweig, kein `taktDodge`). Der Absatz hat keinen `RenderStripeDodge`-Vorfahr; „15–“ liegt bei x ≈ 330–351, „30“ nach dem Umbruch bei x ≈ 33–49, ein Streifen bei 0,85–0,90 oder 0,09–0,12 träfe die Ziffern. Reproduktion: `SleepDetail(embedded: true, data: SleepData(…, night: night()..['sleep_source'] = 'confirmed', solMin: 22))` in `TaktLook`, `TaktStripe.fraction.value = .3`, Ziffer-Absätze ohne Hülle sammeln. Realistisch: Nach „Ja, diese Zeiten stimmen“ wird die Nacht `confirmed`. Die Tests F13 nutzen nur die Auto-Fixture. |
| F1–F5, F7–F12, F15 | ✅ | Durch 3b0c563a nicht berührt (Diff nur Korrekturkarte, `_night`, Phasen-Karte im leeren Fall). 169 Takt-Tests grün, Foto bis „Phasen“ unverändert (Kopf, Ring, Nächte, Bedarf, Regelmäßigkeit, Effizienz, Hypnogramm, Phasen mit Anteilen). Kleinigkeit weiter offen: Kommentar `sleep_detail.dart:1907–1909` sagt noch „Anteile in Prozent stehen bewusst nicht da“. |
| F14 | ⚪ | Weiter nur am Gerät prüfbar. |

### Randfälle Runde 3
| Randfall | Ergebnis | Begründung |
|---|---|---|
| Nacht ohne Phasen | ✅ | Behoben. Im Takt-Zweig je eine Zeile „Keine Phasen für diese Nacht“ für Hypnogramm (`sleep_detail.dart:1390–1396`) und Phasen (`:1931–1936`), keine `StatusCard` (eigener Lauf: 2 Zeilen, 0 `StatusCard`; Test im Repo prüft dasselbe). Anmerkung: Die Zeilen stehen ohne Karte, die Überschrift „Die Nacht“ entfällt dabei mit, darum stehen zwei gleichlautende Zeilen, die erste ohne Überschrift. Wörtlich verlangt die Spec, dass die Karten je eine Zeile zeigen. Felix sollte entscheiden, ob das so bleiben darf. |
| Keine Nacht, Lesefehler, Dunkles Design | ✅ | Nicht berührt, Stand Runde 2. |

### Regressionen Runde 3
- Alle neuen Zweige hängen an `TaktLook.on(c)`; außerhalb bleiben die l10n-Texte und `StatusCard` wie upstream.
- Kein ✅ aus Runde 2 ist gekippt. Der F13-Befund ist alt (Code seit upstream), nur bisher nicht geprüft.

---

# Runde 2 (Stand b7fde943), zur Nachverfolgung

## Grundlage Runde 2
- Spec, beide Berichte der Runde 1 und `git show b7fde943` gelesen, `plan.md` bewusst nicht.
- `flutter test test/takt`: 167 Tests, alle grün. `flutter analyze lib/takt lib/ui2`: keine Befunde.
- Upstream-Tests zu den berührten Bausteinen (`app_shell_back`, `ui2_shell_tabs_l10n`, `ui2_sleep_detail`, `ui2_sleep_detail_load_failure`, `sleep_detail_units_locale`, `ui2_metric_detail_provenance`, `readiness_detail_investigate_day`, `day_strain_dst_grid`, `ui2_component_sweep`, `ui2_tokens`, `ui2_step_goal_unreadable`): 100 grün.
- Bildschirmfotos neu erzeugt (`schlaf_tab.png`), in Stücke geschnitten und angesehen.
- Eigene Wegwerf-Tests unter `build/` (ignoriert, danach gelöscht): Schlaf-Tab mit 3 Nächten, ohne Phasen, ohne Nacht, Fallback-Nacht und voll, je mit Streifen bei 0,72 (Hüllen-Prüfung) und Streifen-Durchlauf 0,05–0,95 (Ziffer-Treffer); Kontrast der Bahnnamen hell und dunkel; Zeilenzahl der Korrektur-Hinweise.

## Ergebnis Runde 2
✅ 15 · ❌ 1 · ⚪ 1

| ID | Ergebnis | Begründung |
|---|---|---|
| E1 | ✅ | Unverändert seit Runde 1, Test grün. |
| E2 | ✅ | Unverändert seit Runde 1, Test grün. Echtes Scrollen nur am Gerät. |
| F1 | ✅ | Kopfzeile wie Runde 1 (Foto: „schlaf ‹ Nacht auf So, 8. Nov. ›“, Profilbild). Der Tag in der Kopfzeile kommt jetzt aus `_day ?? nav?.latestDay ?? nav?.day` (`sleep_detail.dart:525`), siehe Randfall Lesefehler. |
| F2 | ✅ | Nicht berührt, Tests grün. |
| F3 | ✅ | Bahnfarben unverändert (`taktCols`). Nur die Bahnnamen sind jetzt in Tinte statt in Phasenfarbe (`sleep_detail.dart:1757–1762`), die Spec verlangt die Farben für die Bahnen, nicht für die Namen. Upstream (ohne `TaktLook`) zeichnet die Namen weiter farbig. |
| F4 | ✅ | Nicht berührt, Test grün. |
| F5 | ✅ | Nicht berührt. Weiter nur am Code geprüft. |
| F6 | ❌ | Teilweise behoben. Die Kopfzeile der Korrekturkarte hat jetzt `maxLines: 1` (`sleep_detail.dart:1092–1094`), wird dabei aber **mitten im Wort abgeschnitten**: Foto `schlaf_tab.png` zeigt „Dieser Zeitraum wurde automatisch anhan…“. Einzeilig durch Kappen, nicht durch einen kurzen Satz. Die übrigen Hinweise zur Korrektur sind **weiter mehrzeilig**: in der Fallback-Nacht, also genau dort, wo „Zeiten stimmen“ erscheint, steht „Beginn und Ende konnten nicht zuverlässig erkannt werden. Die angezeigten Zeiten sind deshalb Schätzungen.“ über mehrere Zeilen (`sleep_detail.dart:1098–1106`, kein Takt-Zweig), die Kopfzeile davor („…anhand der Herzfrequenz geschätzt“) wird ebenfalls gekappt. Gleiches gilt für `_uncorrectableNote` (`:1175`) und `_eveningPrunedNote` (`:1183`). Reproduktion: `SleepDetail(embedded: true, data: SleepData(day:…, night: night()..['sleep_source'] = 'auto_fallback'))` in `TaktLook`, Zeilen des Absatzes mit „Schätzungen“ zählen. Der Test `review_fixes_test.dart` F6 prüft nur `maxLines` der Kopfzeile im Auto-Fall und kann das nicht finden. Die Knöpfe selbst sind flach und unverändert. |
| F7 | ✅ | Behoben. Jede Phase hat jetzt den Anteil in Prozent (`night_parts.dart`, `shares: true` in `sleep_detail.dart:1915`), aus denselben Minuten wie der Balken, rechtsbündig im `StripeDodge`. Foto: „Tief 23m–2h 38m 20 %“, „REM 21 %“, „Leicht 48 %“, „Wach 53m 12 %“. Test F7 prüft alle vier Werte in der Phasen-Karte und kann scheitern. Kleinigkeit: Der Kommentar `sleep_detail.dart:1895–1897` sagt noch „Anteile in Prozent stehen bewusst nicht da“, das stimmt nicht mehr. Spannenformat „23m–2h 38m“ statt „1:18 bis 1:42“ bleibt kosmetisch. |
| F8 | ✅ | Behoben. Mit zu wenigen Nächten steht im Takt-Zweig eine Textzeile „…: 3 von 7 Nächten bisher“ im `StripeDodge` statt der `StatusCard` (`sleep_detail.dart:2073–2085`). Test F8 prüft: keine `StatusCard`, Zeile vorhanden, Zeile in Hülle. Eigener Durchlauf mit 3 Nächten bestätigt. Mit genug Nächten unverändert (Foto „Gegen deine Nächte“). |
| F9 | ✅ | Nicht berührt, Foto unverändert. |
| F10 | ✅ | Nicht berührt, Foto unverändert. |
| F11 | ✅ | Nicht berührt, Test grün. |
| F12 | ✅ | Nicht berührt, Test grün. |
| F13 | ✅ | Behoben. `StatusCard` hüllt Titel und Begründung jetzt mit `taktDodge(line: true)`, die Aktionszeile über `_Cta` ebenso (`grammar.dart:926–929`, `:1186–1208`); außerhalb von `TaktLook` gibt `taktDodge` das Widget unverändert zurück. Eigener Durchlauf über fünf Fälle (3 Nächte, ohne Phasen, ohne Nacht, Fallback-Nacht, volle Nacht): keine Ziffer ohne `RenderStripeDodge`-Vorfahr, und beim Streifen-Durchlauf 0,05–0,95 trifft der Streifen keine gemalte Ziffer. Der Lesefehler-Fall lässt sich ohne Repo nicht rendern, nutzt aber dieselbe `StatusCard`. Test F13 prüft `StatusCard` einzeln mit allen drei Zeilen. |
| F14 | ⚪ | Weiter nur am Gerät prüfbar (echtes schnelles Scrollen). Risiko wie in Runde 1: `ListView` mit festen Kindern, Einblend-Animation des Hypnogramms kann beim Zurückscrollen neu starten. |
| F15 | ✅ | Nicht berührt, Test grün. |

### Randfälle Runde 2 (zusätzlich, nicht in der Zählung)
| Randfall | Ergebnis | Begründung |
|---|---|---|
| Nacht ohne Phasen | ❌ | Nicht angefasst. Die Phasen-Karte ist im Takt-Zweig weiter die alte `StatusCard` „Keine Phasenaufteilung …“ mit Begründung darunter statt einer Zeile „Keine Phasen für diese Nacht“ (`sleep_detail.dart:1919–1925`). Eigener Test: 1 × `StatusCard`. Ziffern darin sind jetzt geschützt. |
| Keine Nacht | ✅ | Wie Runde 1, Ziffern in der Karte jetzt in Hülle (eigener Durchlauf). |
| Lesefehler | ✅ | Behoben. Die Kopfzeile nimmt jetzt `_day ?? nav?.latestDay ?? nav?.day` (`sleep_detail.dart:525`), also dieselbe Regel wie der Fehlerzweig (`:749`). Nach dem Schritt zur neuesten Nacht (`_day` = null) nennt die Kopfzeile die neueste Nacht, nicht die verlassene. Nur am Code geprüft: Ein Lesefehler braucht ein Repo, und `review_fixes_test.dart` hat dafür keinen Test. |
| Dunkles Design | ✅ | Behoben. Bahnnamen in `p.ink2`: Kontrast gegen `card` 9,01:1 hell und 7,21:1 dunkel, für alle vier Namen (eigene Messung mit `P.contrast`). Der Test im Repo prüft nur „Wach“ im hellen Design. |

### Regressionen Runde 2
- Alle Änderungen im Upstream-Code hängen an `TaktLook.on(c)` bzw. `taktDodge`; ohne Haut bleiben `StatusCard`, `_Cta`, Hypnogramm-Namen, Korrekturkarte, Phasen und Vergleich wie upstream. 100 Upstream-Tests grün.
- Kein Befund aus Runde 1 mit ✅ ist durch die Korrekturen gekippt.

---

# Runde 1 (Stand 81e12048), zur Nachverfolgung

## Grundlage
- Spec und Architektur gelesen, `plan.md` bewusst nicht.
- `flutter test test/takt`: 156 Tests, alle grün.
- `flutter analyze lib/takt lib/ui2`: keine Befunde.
- Bildschirmfotos: `TAKT_SHOTS=1 flutter test test/takt/shots_test.dart` (schlaf_tab.png), in Stücke geschnitten und angesehen.
- Zusätzlich eigene Wegwerf-Tests unter `build/` (ignoriert, danach gelöscht): Schlaf-Tab mit nur 3 Nächten Verlauf und Displaystreifen bei 0,72; Schlaf-Tab im dunklen Design.
- Kontraste der Hypnogramm-Farben aus `Hypnogram.taktCols` gegen `P.card` nachgerechnet (WCAG-Formel).

## Ergebnis
✅ 12 · ❌ 4 · ⚪ 1

| ID | Ergebnis | Begründung |
|---|---|---|
| E1 | ✅ | `takt_today_screen.dart:334` pusht `SleepDetail` mit `TaktSleepHeadLoader`. Test `sleep_fixes_test.dart` E1 grün. |
| E2 | ✅ | `TaktSleepHeadLoader` mit `AutomaticKeepAliveClientMixin` und statischem `_last`. Test E2 grün. Echtes Scrollen am Gerät nicht geprüft. |
| F1 | ✅ | `_taktFrame` (`sleep_detail.dart:518`): „schlaf“, Nacht mit Pfeilen, Profilbild; `_navRow` leert die alte Blätterzeile. Foto bestätigt „schlaf ‹ Nacht auf So, 8. Nov. ›“ und Profilbild. Test prüft Text, Pfeil, Blättern auf Vornacht und fehlenden `ScreenTitle`/`DayNav`, kann also scheitern. Randfall Lesefehler siehe unten. |
| F2 | ✅ | `app_shell.dart` `_TabBar`: Kartenfarbe, Linie oben; `_Tab` ohne Pille, aktiv w700, Schlaf über `TaktSleepBand`, sonst `ScoreBand.okay.ink` (Takt-Orange als Text). Tests prüfen deutsche Beschriftungen, Fettung, Farbe je Stufe, fehlende Pille. Fläche und Linie oben sind nur am Code geprüft. |
| F3 | ✅ | Karte „Die Nacht“, vier Bahnen, Tief `p.ink`, REM/Leicht als Abstufung, Wach orange (`charts.dart` `taktCols`). Test prüft Farben und dass der Painter im Takt-Teilbaum `takt: true` bekommt. Hinweis: Im dunklen Design ist Tief hell (`p.ink` = #F1F1EC), also nicht „dunkel“ im Wortsinn. Das ist als Kontrastumkehr gewollt, Felix sollte es einmal ansehen. Kontrast der Bahnnamen siehe Randfall „Dunkles Design“. |
| F4 | ✅ | Zeitpunkt-Karte: Uhrzeit in Punktziffern im `StripeDodge`, Phase als Text, Werte über `InlineMetrics` (Takt-Zweig). Test tippt ins Hypnogramm und prüft Uhrzeit in Doto und im Streifen-Schutz. |
| F5 | ✅ | `DeviceFilter` mit `allLabel: 'Takt'` (`sleep_detail.dart:875`), Logik unverändert. Kein Takt-Test mit zweitem Gerät, der Fixture fehlen `deviceNights`. Geprüft nur am Code. |
| F6 | ❌ | Die Knöpfe sind flach (Theme in `TaktLook`, Test `look_test.dart` F6). Aber der Korrektur-Hinweis ist **nicht einzeilig**: „Dieser Zeitraum wurde automatisch anhand der Messdaten erkannt“ bricht bei 390 pt auf zwei Zeilen um. Reproduktion: `TAKT_SHOTS=1 flutter test test/takt/shots_test.dart`, `build/shots/schlaf_tab.png`, Karte unter „Die Nacht“. Quelle: `sleep_detail.dart:1079–1090` (Text ohne `maxLines`, kein Takt-Zweig). Dass die vier Aktionen im Takt-Teilbaum weiter funktionieren, prüft kein Takt-Test, die Logik ist aber unverändert. |
| F7 | ❌ | Balken und vier Zeilen mit Phase und Dauer bzw. Spanne sind da, der **Anteil fehlt**. Der Code sagt das selbst: `sleep_detail.dart:1887–1889` „Anteile in Prozent stehen bewusst nicht da“. Die Spec verlangt „Phase, Dauer und Anteil“. Das ist eine Abweichung von der freigegebenen Spec ohne Spec-Änderung. Reproduktion: `schlaf_tab.png`, Karte „Phasen“: Zeilen „Tief 23m–2h 38m“ usw., kein Anteil. Spannen stehen als „23m–2h 38m“, nicht im Spec-Beispielformat „1:18 bis 1:42“ (kosmetisch). |
| F8 | ❌ | Mit genug Nächten erfüllt: Zeile mit Wert, grauem Band, Punkt, Satz (Foto, Test `sleep_compare_test.dart` F8). **Ohne genug Nächte** steht keine Zeile, sondern die alte `StatusCard` mit Titel und blauer OpenStrap-Fix-Zeile „3 von 7 Nächten bisher“. Reproduktion: `SleepDetail` in `TaktLook` mit `tstHistory`/`deepHistory`/`effHistory`/`onsetHistory` von je 3 Einträgen. Quelle: `sleep_detail.dart:2063–2071`. Kein Test deckt diesen Fall. |
| F9 | ✅ | `InsightCard` im Takt-Zweig mit 4-px-Rand in Orange (`grammar.dart`), „Nichts aufgefallen.“ als Zeile (`sleep_detail.dart`). Tests für beide Fälle, Foto bestätigt. |
| F10 | ✅ | Drei Ziffern Schlafpuls, tiefster Puls, Atmung in Punktziffern; darunter vier Verläufe über `onset_ts`–`wake_ts`. Test und Foto bestätigen. |
| F11 | ✅ | `_taktFrame` hängt `footer`/`todayFooter` nicht an. Test prüft mit Platzhaltertexten, dass sie fehlen. |
| F12 | ✅ | `_taktLinks`: Wecker, Körperuhr, Nickerchen, Alle Messwerte in einer Karte. Test und Foto bestätigen. |
| F13 | ❌ | Im Normalfall erfüllt (Tests decken jede Ziffer und einen Streifen-Durchlauf ab). **Aber `StatusCard` kennt keinen Streifen-Schutz** (`grammar.dart:1103 ff.`, kein `taktDodge`). Jede Ziffer in einer `StatusCard` im Schlaf-Tab liegt ungeschützt. Reproduktion: wie F8 (3 Nächte) mit `TaktStripe.fraction.value = .72`, dann alle `RenderParagraph` mit Ziffer ohne `RenderStripeDodge`-Vorfahr sammeln → „3 von 7 Nächten bisher“. Dasselbe betrifft die Lesefehler-Karte („8. Nov. konnte nicht gelesen werden“) und „Keine Nacht“. Der bestehende Test nutzt nur die volle Fixture und kann diesen Fall nicht finden. |
| F14 | ⚪ | Nur am Gerät prüfbar (echtes schnelles Scrollen). Risiko: `_taktFrame` ist eine `ListView` mit festen Kindern; der Hypnogramm-Painter läuft mit `animate(c, 1)`. Wird ein Abschnitt beim Wegscrollen verworfen, kann die Einblend-Animation beim Zurückscrollen neu starten. Am Gerät gezielt darauf achten. |
| F15 | ✅ | Gepusht (`embedded: false`) mit Zurück-Pfeil statt Profilbild, gleicher Aufbau. Test F15 grün. |

### Randfälle (zusätzlich geprüft, nicht in der Zählung)
| Randfall | Ergebnis | Begründung |
|---|---|---|
| Nacht ohne Phasen | ❌ | Die Phasen-Karte zeigt die alte `StatusCard` „Keine Phasenaufteilung …“ mit Text darunter statt einer Zeile (`sleep_detail.dart:1910–1915`). Die Hypnogramm-Karte habe ich nicht gerendert. |
| Keine Nacht | ✅ | `StatusCard` mit Grund, „Ich habe geschlafen“ als flacher Knopf, Nickerchen-Knopf. Der Nickerchen-Zugang ist der alte `_napsButton`, keine Link-Karte. Ziffern in der Karte sind ungeschützt (siehe F13). |
| Lesefehler | ❌ | Die Kopfzeile kann die falsche Nacht nennen. `_taktFrame` setzt `day: _day ?? nav?.day` (`sleep_detail.dart:525`). Der Upstream-Fehlerzweig benutzt dagegen `_day ?? nav.latestDay ?? nav.day` (`:746`). Reproduktion: auf eine ältere Nacht blättern, dann mit › zur neuesten (`_day` wird null). Schlägt das Laden fehl, bleibt `_d` die ältere Nacht: Die Kopfzeile zeigt „Nacht auf Di“, die Karte darunter nennt die neueste Nacht als unlesbar, und die Pfeile rechnen von der falschen Nacht aus. Kurz sichtbar auch während des Ladens nach dem Schritt zur neuesten Nacht. |
| Dunkles Design | ❌ | Die Bahnnamen links im Hypnogramm sind in den Bahnfarben gesetzt (`_labelledHypnogram`, `coloured: true`). Takt-Farben gegen `card`: „Leicht“ 3,94:1 dunkel und 2,8:1 hell, „Wach“ (#F0560A) 2,96:1 hell. Gefordert sind ≥ 4,5:1 für Text. Upstream löste diese Farben gegen die Karte auf (`_shade`), `taktCols` tut das nicht. |

## Sicherheit
- `git diff c1627e3f..HEAD --stat`: nur `lib/takt`, `lib/ui2`, `test/takt`, `docs`, `CLAUDE.md`. Keine Änderungen an `android/`, `ios/`, `pubspec.yaml`, `.env*`, `protocol` oder `analytics`.
- Im Diff kein `http`, `Uri`, Socket, `MethodChannel`, keine Schlüssel oder Tokens, keine neuen Rechte. Neue Datenzugriffe (`availableDays`, `getWorkouts`, `getDayHeart`) lesen nur die lokale Datenbank.
- Ergebnis: unauffällig.

## Regressionen
- Upstream-Tests zu den geänderten Bausteinen gezielt ausgeführt (`app_shell_back`, `ui2_shell_tabs_l10n`, `ui2_sleep_detail`, `ui2_sleep_detail_load_failure`, `sleep_detail_units_locale`, `ui2_metric_detail_provenance`, `readiness_detail_investigate_day`, `day_strain_dst_grid`, `ui2_component_sweep`, `ui2_tokens`): 96 Tests grün. Die ganze Suite lief wie verlangt nicht.
- Takt-Haut ist eng begrenzt: `TaktLook(` steht nur in `sleep_tab.dart:29` und `takt_today_screen.dart:274`. Aktivität und Gesundheit werden nicht umhüllt. Unterscreens, die per `go()`/`push` geöffnet werden, liegen außerhalb, weil Routen ihre InheritedWidgets nicht erben. Alle Abzweigungen in `grammar.dart`, `charts.dart`, `trend.dart` fragen `TaktLook.on` bzw. `taktDodge` und geben außerhalb das alte Widget zurück; `Hypnogram(takt: false)` ist Standard. `look_test.dart` prüft `Surface` mit und ohne Haut.
- Gewollte Änderung außerhalb der Haut: Die Tab-Leiste gilt für alle Tabs (F2). `ui2_shell_tabs_l10n_test` und `app_shell_back_test` bleiben grün.
- Feature 03, C9 („Schlafplan … stehen wie bisher darunter“) ist durch F11 bewusst abgelöst. Kein Fehler, aber C9 ist damit überholt und sollte in Spec 03 vermerkt werden.
- Feature 02 (B4, B5): `StripeDodge` ohne Streifen ändert nichts; B5 ist im Normalfall erfüllt, die Lücke ist `StatusCard` (siehe F13).
- Feature 01: `today_*`-Tests grün. A3 bleibt erfüllt (dieselben Screens, jetzt in der Haut).
