// Die Uhr von Takt. Tests setzen sie fest, damit ein Ergebnis nicht davon
// abhängt, wann der Test läuft (zwischen 00:00 und 00:35 liegt der Wachtag
// noch beim Vortag).
//
// Gerätetest: Mit --dart-define=TAKT_FAKE_NOW=2026-11-15T07:00:00 läuft die
// Uhr ab diesem Zeitpunkt weiter. Nur für Test-Builds, im normalen Build leer.
const String _kFakeNow = String.fromEnvironment('TAKT_FAKE_NOW');

DateTime Function() taktNow = _kFakeNow.isEmpty ? DateTime.now : _fakeClock();

DateTime Function() _fakeClock() {
  final offset = DateTime.parse(_kFakeNow).difference(DateTime.now());
  return () => DateTime.now().add(offset);
}
