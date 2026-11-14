# Takt

Dünner Fork von OpenStrap Edge für WHOOP-Bänder: gleiche Algorithmen und Bluetooth-Anbindung, eigener Heute-Screen im Pult-Design, eigener Name.

## Produkt
- **Problem:** OpenStrap zeigt Puls und Training nicht direkt beim Öffnen und ist unübersichtlich.
- **MVP:** Heute-Screen mit Ringen, Live-Puls, Karten und Aktivitäten (Feature 01).
- **Nicht im MVP:** Redesign anderer Tabs, iOS. (Batterie kam als Feature 04 dazu.)

## Stack und Befehle
Toolchain liegt in `~/Developer/tools` (Flutter 3.41.6, JDK 17, Android SDK).
- Env: `export PATH=$HOME/Developer/tools/flutter/bin:$HOME/Developer/tools/android-sdk/platform-tools:$PATH JAVA_HOME=$HOME/Developer/tools/jdk/Contents/Home ANDROID_HOME=$HOME/Developer/tools/android-sdk`
- Tests: `flutter test` (muss eine Testanzahl > 0 melden), Takt-Tests: `flutter test test/takt`
- Build: `flutter build apk --debug --dart-define-from-file=.env`
- Lint: `flutter analyze`

## Arbeitsweise
Blueprint-Ablauf (Skill `/blueprint`): Spec → Architektur → Plan → Build (TDD) → unabhängige Prüfung.

| Dokument | Ändern darf | Wann |
|---|---|---|
| `docs/features/*/spec.md` | nur nach Freigabe durch Felix | Phase 1, Änderungsweg |
| `docs/features/*/architektur.md` | Claude, Freigabe durch Felix | Phase 2 |
| `docs/features/*/plan.md` | Hauptsession | Phase 3–4 |
| `docs/features/*/pruefung.md` | nur der Prüfer-Agent | Phase 5 |

Während des Builds ist die Spec eingefroren: Abweichung → stoppen und Felix fragen.

## Features
| Nr | Feature | Status | Ordner |
|---|---|---|---|
| 01 | Heute-Screen | build | `docs/features/01-heute-screen/` |
| 02 | Displaystreifen: Zahlen weichen einem Displayfehler aus | fertig | `docs/features/02-displaystreifen/` |
| 03 | Schlafscore und Schlaf-Tab im Takt-Design | build | `docs/features/03-schlafscore/` |
| 04 | Batterie statt Erholung, Wochenverlauf Belastung gegen Batterie | build | `docs/features/04-batterie/` |
| 05 | Aktivität und Gesundheit im Takt-Design | idee | — |
| 06 | Schlaf-Tab ganz im Takt-Design, Tab-Leiste | build | `docs/features/06-schlaf-tab-ganz/` |
| 07 | Detailscreens von Heute (HRV, Ruhepuls, Schritte, Strain, Erholung) | build | `docs/features/07-detailscreens/` |
| 08 | Training von Heute und Workout nachtragen im Takt-Design | build | `docs/features/08-training/` |
| 09 | Feinschliff Training: Sportart-Wahl, Pulskurve ablesen, Puls beim Nachtragen, Pulsabfall erklärt | build | `docs/features/09-training-feinschliff/` |
| 10 | Körperalter: geschätztes Alter aus Schlaf, Ruhepuls, Schritten, Bewegung, Kraft | spec | `docs/features/10-koerperalter/` |
| 13 | Journal im Takt-Design mit Morgenblatt, eigene Ja/Nein-Fragen, Auswertung gegen die Batterie | architektur | `docs/features/13-journal/` |

## Konventionen
- Neuer Code liegt unter `lib/takt/`, Upstream-Dateien nur punktuell ändern, damit `git merge upstream/main` sauber bleibt.
- Upstream-Regeln aus `AGENTS.md` und `lib/ui2/README.md` gelten: keine rohen Farben oder Größen außerhalb von `theme.dart`, nie erfundene Werte.
- Takt-Haut: Was in einer `TaktLook` (`lib/takt/look.dart`) steht, zeichnen die Upstream-Bausteine im Takt-Stil (Karten, Ziffern, Knöpfe, Hypnogramm). Schlaf-Tab und alles, was Heute öffnet, stehen darin. Abzweigungen in Upstream-Dateien sind mit `TAKT (Feature NN)` markiert.
- Bildschirmfotos aus Tests: `TAKT_SHOTS=1 flutter test test/takt/shots_test.dart` → `build/shots/`.
- Jede Zahl im Takt-Design steht in einem `StripeDodge` (`lib/takt/stripe/stripe.dart`): Einzelwerte als Block, Zeilen mit Zahlen mit `line: true`. Neue Screens prüfen das wie `test/takt/stripe_today_test.dart` (Feature 02, B5).
- Tests tragen die Anforderungs-ID im Namen: `A3: …`
- Commits: `01-<Aufgabe>: <was>`

## Leitplanken
- Lizenz AGPL-3.0, Name und Logo von OpenStrap nicht verwenden, „basiert auf OpenStrap" ist erlaubt.
- Secrets nur in `.env*`, Signaturschlüssel nie im Repo.
- Kein force-push, kein reset --hard, Änderungen an `protocol` und `analytics` gehören nicht hierher.
