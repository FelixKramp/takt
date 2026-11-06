# Takt

Eine App für WHOOP-Bänder ohne Abo: öffnen und sofort Ringe, Live-Puls und das heutige Training sehen. Alle Daten bleiben auf dem Handy.

## Herkunft

Takt basiert auf [OpenStrap](https://github.com/OpenStrap) und nutzt dessen Bluetooth-Anbindung und Algorithmen unverändert. Takt ist kein offizielles OpenStrap-Projekt und steht in keiner Verbindung zu OpenStrap, WHOOP oder anderen Geräteherstellern. Gerätenamen sind Marken ihrer Inhaber und stehen hier nur, um die Kompatibilität zu beschreiben.

## Was anders ist

- Neuer Heute-Screen im Pult-Design: drei Ringe als Drehregler, Live-Puls auf einem Display, Karten und Aktivitäten
- Erkannte Workouts erscheinen ohne Bestätigung, Handball steht im Sportkatalog
- Kein Firebase, keine Absturzberichte und keine Tickets an fremde Server

Details stehen in `docs/features/`. Takt ist kein Medizinprodukt.

## Bauen

Flutter 3.41.6 und JDK 17:

```bash
cp .env.example .env
flutter pub get
flutter run --dart-define-from-file=.env
```

## Lizenz

AGPL-3.0, siehe `LICENSE`. Der Quellcode dieser Version steht in diesem Repository.
