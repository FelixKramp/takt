# Architektur: Schlaf-Tab ganz im Takt-Design (06)

## Entscheidung: Takt-Haut statt Neubau
Der Schlaf-Screen (`lib/ui2/screens/sleep_detail.dart`, 2500 Zeilen) trägt viel Logik:
Korrekturen der Schlafzeiten, Geräteauswahl, Zeitpunkt antippen, Spannen der Phasen, Vergleich
gegen die eigenen Nächte. Ein Neubau unter `lib/takt/` würde diese Logik kopieren und bei jedem
Upstream-Merge auseinanderlaufen. Stattdessen bekommt der Screen eine **Takt-Haut**:

- `lib/takt/look.dart`: `TaktLook` (InheritedWidget) markiert einen Teilbaum als Takt.
  `TaktLook.on(c)` fragt das ab. Außerhalb (Aktivität, Gesundheit) bleibt alles wie bisher.
- Die gemeinsamen Bausteine in `lib/ui2/grammar.dart` und `lib/ui2/charts.dart` fragen
  `TaktLook.on(c)` und zeichnen dann im Takt-Stil: `Surface` als Takt-Karte (Rand, 3 px
  Unterkante, kleiner Radius, kein Schatten), `InlineMetrics` mit Punktziffern im Streifen,
  Hypnogramm-Farben (Tief dunkel, REM und Leicht grau, Wach orange).
- Was nur den Schlaf-Screen betrifft (Kopfzeile, Vergleichszeilen, Auffällig, Signale, Links),
  zweigt in `sleep_detail.dart` an wenigen Stellen mit `TaktLook.on(c)` ab und baut Takt-Widgets
  aus `lib/takt/sleep/night/`.
- Die Tab-Leiste (`lib/ui2/app_shell.dart`, `_Tab`) wird direkt umgestellt: Takt ist die App.
  Die Farbe des Schlaf-Tabs kommt aus `TaktSleepBand.current` (ValueNotifier), den der
  Schlafscore-Lader auf Heute und der Kopf-Lader setzen.

Verworfen: eigener Schlaf-Screen unter `lib/takt/` (doppelte Logik); globale Haut für alle Tabs
(ändert Aktivität und Gesundheit, Nicht-Ziel).

## Datenfluss
Unverändert: `SleepData.load` → `_SleepDetailState` → Abschnitte. Keine neue Abfrage.

## Fehlerfälle
Wie bisher; Lesefehler, keine Nacht und keine Phasen zeigen die bisherigen Gründe, nur im
Takt-Stil.

## Manuelle Aufgaben für Felix
Keine.
