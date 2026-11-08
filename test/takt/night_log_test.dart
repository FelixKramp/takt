import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/state/prefs.dart';
import 'package:openstrap_edge/takt/sleep/night_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.ensureLoaded();
    TaktNightLog.clear();
  });

  const note = NightNote(needMin: 480, debtMin: 18, strainMin: 12, napMin: 0, bedRec: 1395, wakeRec: 420);

  test('C6/C7: Notiz schreiben und lesen', () {
    TaktNightLog.record('2026-11-07', note);
    final n = TaktNightLog.read()['2026-11-07']!;
    expect(n.needMin, 480);
    expect(n.baseMin, 450, reason: 'Grundbedarf = Bedarf − Schuld − Belastung + Nickerchen');
    expect(n.bedRec, 1395);
    expect(n.wakeRec, 420);
  });

  test('C6: derselbe Tag wird überschrieben, der letzte Stand bleibt', () {
    TaktNightLog.record('2026-11-07', note);
    TaktNightLog.record('2026-11-07', const NightNote(needMin: 500, strainMin: 32));
    expect(TaktNightLog.read()['2026-11-07']!.needMin, 500);
    expect(TaktNightLog.read(), hasLength(1));
  });

  test('Die Notiz hält höchstens 30 Tage', () {
    for (var d = 1; d <= 40; d++) {
      final day = DateTime(2026, 10, d);
      TaktNightLog.record(dayLabel(day), note);
    }
    final log = TaktNightLog.read();
    expect(log, hasLength(30));
    expect(log.containsKey(dayLabel(DateTime(2026, 10, 40))), isTrue);
    expect(log.containsKey(dayLabel(DateTime(2026, 10, 1))), isFalse);
  });

  test('C1: Bedarf einer Nacht ist die Notiz vom Vortag', () {
    TaktNightLog.record('2026-11-07', note);
    final need = needForNight('2026-11-08', TaktNightLog.read(),
        needNow: 510, strainNowMin: 40, napNowMin: 0);
    expect(need.needMin, 480);
    expect(need.fromLog, isTrue);
  });

  test('C1: ohne Notiz zählt der heutige Bedarf ohne die Belastung von heute', () {
    final need = needForNight('2026-11-08', const {},
        needNow: 510, strainNowMin: 40, napNowMin: 20);
    expect(need.needMin, 490, reason: '510 − 40 + 20');
    expect(need.fromLog, isFalse);
    expect(need.strainMin, isNull);
  });

  test('vorheriger Tag über Monatsgrenzen', () {
    expect(prevDay('2026-11-01'), '2026-10-31');
    expect(prevDay('2026-01-01'), '2025-12-31');
  });
}
