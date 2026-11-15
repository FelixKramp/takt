// Feature 15: Radfahren aus Puls und stillem Schrittzähler erkennen.
// Alle Daten synthetisch, keine echten Zeiten.
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/takt/walk/cycle_detect.dart';
import 'package:openstrap_edge/takt/walk/walk_detect.dart';
import 'package:openstrap_edge/ui2/activity/catalogue.dart' show activityByName;

const t0 = 1700000000 - 1700000000 % 60;
const rest = 55;

/// Eine Minute: Schritte und Puls.
typedef Min = (int spm, int bpm);

({List<int> ts, List<int> steps, List<int> hr}) series(List<Min> mins) {
  final ts = <int>[], steps = <int>[], hr = <int>[];
  var counter = 0;
  for (var m = 0; m < mins.length; m++) {
    final (spm, bpm) = mins[m];
    for (var s = 0; s < 60; s++) {
      final before = spm * s ~/ 60, after = spm * (s + 1) ~/ 60;
      ts.add(t0 + m * 60 + s);
      steps.add(counter);
      hr.add(bpm);
      counter = (counter + after - before) % 65536;
    }
  }
  ts.add(t0 + mins.length * 60);
  steps.add(counter);
  hr.add(0);
  return (ts: ts, steps: steps, hr: hr);
}

List<Min> sit(int n, [int bpm = 65]) => List.filled(n, (0, bpm));
List<Min> walk(int n) => List.filled(n, (100, 100));
List<Min> ride(int n, [int bpm = 110]) => List.filled(n, (5, bpm));

List<CycleBout> run(List<Min> mins, {List<(int, int)> blocked = const [], int? restBpm = rest}) {
  final s = series(mins);
  return detectCycling(
    tsSec: s.ts,
    stepCount: s.steps,
    hr: s.hr,
    restingBpm: restBpm,
    blocked: blocked,
  );
}

void main() {
  test('R1 – Gehen zum Rad, dann 20 Minuten fahren: eine Fahrt', () {
    final b = run([...sit(5), ...walk(3), ...ride(20), ...walk(2), ...sit(5)]);
    expect(b, hasLength(1));
    expect(b.single.startSec, t0 + 8 * 60);
    expect(b.single.durationMin, 20);
    expect(b.single.avgBpm, 110);
  });

  test('R2 – schneller Pulsanstieg ohne Gehen davor zählt als Anfang', () {
    final b = run([...sit(5, 70), ...ride(15, 110)]);
    expect(b, hasLength(1));
  });

  test('R3 – Sitzen mit hohem Puls ohne erkennbaren Anfang ist keine Fahrt', () {
    // Puls steigt langsam über viele Minuten (Aufregung), kein Gehen davor.
    final b = run([for (var i = 0; i < 20; i++) (0, 65 + i * 2), ...sit(20, 105)]);
    expect(b, isEmpty);
  });

  test('R4 – 9 Minuten sind keine Fahrt, 10 Minuten sind eine', () {
    expect(run([...walk(3), ...ride(9), ...sit(5)]), isEmpty);
    expect(run([...walk(3), ...ride(10), ...sit(5)]), hasLength(1));
  });

  test('R5 – Ampel bis 2 Minuten überbrückt, 3 Minuten trennen', () {
    expect(run([...walk(3), ...ride(8), ...sit(2, 80), ...ride(8)]), hasLength(1));
    // Nach 3 Minuten Pause hat die zweite Hälfte keinen Anfang mehr und ist
    // allein zu kurz: keine Fahrt.
    expect(run([...walk(3), ...ride(8), ...sit(3, 80), ...ride(8)]), isEmpty);
  });

  test('R6 – Puls unter Ruhe + 30 ist keine Fahrt', () {
    expect(run([...walk(3), ...ride(20, rest + 29)]), isEmpty);
    expect(run([...walk(3), ...ride(20, rest + 30)]), hasLength(1));
  });

  test('R7 – viele Schritte bei hohem Puls sind kein Radfahren', () {
    expect(run([...walk(3), ...List.filled(20, (40, 120))]), isEmpty);
  });

  test('R8 – gesperrte Spannen (Training, Gang) unterbrechen', () {
    final b = run([...walk(3), ...ride(20), ...sit(3)], blocked: [(t0 + 3 * 60, t0 + 23 * 60)]);
    expect(b, isEmpty);
  });

  test('R9 – ohne Ruhepuls oder ohne Schrittzähler keine Erkennung', () {
    expect(run([...walk(3), ...ride(20)], restBpm: null), isEmpty);
    final s = series([...walk(3), ...ride(20)]);
    expect(
      detectCycling(
        tsSec: s.ts,
        stepCount: List.filled(s.steps.length, -1),
        hr: s.hr,
        restingBpm: rest,
      ),
      isEmpty,
    );
  });

  test('R10 – Bout der Puls-Erkennung mit kaum Schritten wird cycling', () {
    final s = series([...walk(3), ...ride(30, 150), ...walk(3)]);
    final spm = stepsByMinute(s.ts, s.steps);
    expect(cyclingSportFor('detected', spm, t0 + 3 * 60, t0 + 33 * 60), 'cycling');
    // Handball: viele Schritte, bleibt wie es ist.
    final h = series(List.filled(30, (90, 150)));
    expect(cyclingSportFor('detected', stepsByMinute(h.ts, h.steps), t0, t0 + 30 * 60), 'detected');
    // Ohne Zähler kein Urteil.
    expect(cyclingSportFor('detected', const {}, t0, t0 + 30 * 60), 'detected');
  });

  test('R11 – Vorschlagszeile mit sport cycling, passt auf den Katalog', () {
    final rows = cycleSuggestionRows('2023-11-14', [
      const CycleBout(startSec: t0, endSec: t0 + 1200, avgBpm: 110, peakBpm: 130),
    ]);
    expect(rows.single['sport'], 'cycling');
    expect(rows.single['duration_min'], 20);
    expect(rows.single['id'], '2023-11-14:$t0');
    expect(activityByName('cycling'), isNotNull);
  });
}
