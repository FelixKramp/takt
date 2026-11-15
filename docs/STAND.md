# Stand

Übergabe zwischen Agenten (Claude Code, Antigravity). Diese Datei beschreibt nur
den **aktuellen** Stand und wird am Ende jeder Sitzung **neu geschrieben**, nicht
verlängert. Höchstens etwa 30 Zeilen. Was sich im Code geändert hat, steht in
`git log`; hier steht, was Git nicht weiß. Das Repo ist öffentlich: nichts
Privates (keine Schlafzeiten, Gesundheitswerte, Journalfragen).

**Aktualisiert:** 2026-11-15 · **Letzter Commit:** siehe `git log -1` (Heute, Stress, Belastung & Erholung, Übergabe) · **Version:** 0.5.1+35

## Zuletzt dazugekommen (committet und gepusht)
- Heute: Karte „Bettzeit heute Nacht“ unter den Ringen (`_TonightCard` in `lib/takt/today/takt_today_screen.dart`)
- Heute frei anordnen: `lib/takt/today/today_order.dart`, Knopf „Heute anordnen“ unten auf Heute
- Tagesstress: Wachfenster vom Aufwachen bis zum Einschlafen, Verlauf beginnt beim Einschlafen und zeigt Nacht (Mond) und Workouts (Symbol); Durchschnitt und Zonen nur Wachzeit (`lib/takt/stress/`)
- Kopfkarte im Stressverlauf behält ihre Höhe beim Wischen (Verlauf sprang)
- Belastung & Erholung statt Batterie-Woche auf Heute (`lib/takt/battery/load_recovery_week.dart`)
- Gehen-Erkennung aus der Schrittfrequenz (Feature 14, `lib/takt/walk/`)

## Auf dem Gerät geprüft
- Alles oben: ja (Pixel, Build 35), außer Ziehen im Anordnen-Screen (nur Widget-Test)
- Gehen-Erkennung: nur Tests, noch kein echter Spaziergang gesehen

## Entscheidungen
- Schlaf zählt nicht in Stress-Durchschnitt und -Zonen (anders als WHOOP), wird aber im Verlauf gezeigt
- Tagesnotizen ohne `v: 2` (alte Bedarfsrechnung) werden verworfen; gestrichelte Empfehlungslinien füllen sich deshalb ab 15.11. neu
- Strain fehlt für die ersten Tage mit eigenem Band absichtlich (ruhiges Wach-Niveau braucht 3 Vortage)
- Bekannt: Heute-Tests können in einem Lauf über Mitternacht hängen (Zeitabhängigkeit), einzeln grün

## Nächster Schritt
- iOS: Simulator-Build vorbereiten (CocoaPods, Bundle-ID `de.felixkramp.takt` in `ios/Config`)
- Gehen-Erkennung mit echtem Spaziergang prüfen
