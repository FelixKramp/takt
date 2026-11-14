// Feature 14: Gehen und Spaziergänge aus dem Schrittzähler erkennen.
// Alle Daten synthetisch: ein Tag ab einer festen Epoche, keine echten Zeiten.
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/ui2/activity/catalogue.dart' show activityByName;
import 'package:openstrap_edge/takt/walk/walk_detect.dart';

const t0 = 1700000000 - 1700000000 % 60; // Minutengrenze

/// Baut 1-Hz-Reihen aus einer Liste „Schritte je Minute“.
({List<int> ts, List<int> steps, List<int> hr}) series(
  List<int> spmPerMinute, {
  int startCounter = 0,
  int bpm = 100,
}) {
  final ts = <int>[], steps = <int>[], hr = <int>[];
  var counter = startCounter;
  for (var m = 0; m < spmPerMinute.length; m++) {
    final perMin = spmPerMinute[m];
    for (var s = 0; s < 60; s++) {
      // Gleichmäßig verteilt, Rest am Ende der Minute.
      final before = perMin * s ~/ 60;
      final after = perMin * (s + 1) ~/ 60;
      ts.add(t0 + m * 60 + s);
      steps.add(counter);
      hr.add(bpm);
      counter = (counter + after - before) % 65536;
    }
  }
  // Schlusspunkt, damit die letzte Sekunde ihre Schritte abgibt.
  ts.add(t0 + spmPerMinute.length * 60);
  steps.add(counter);
  hr.add(0);
  return (ts: ts, steps: steps, hr: hr);
}

List<WalkBout> run(List<int> spm,
    {List<(int, int)> blocked = const [], int startCounter = 0}) {
  final s = series(spm, startCounter: startCounter);
  return detectWalks(
      tsSec: s.ts, stepCount: s.steps, hr: s.hr, blocked: blocked);
}

List<int> rest(int n) => List.filled(n, 0);
List<int> walk(int n, [int spm = 100]) => List.filled(n, spm);

void main() {
  test('W1 – 20 Minuten Gehen mit 100 Schritten/Minute wird ein Gang', () {
    final b = run([...rest(5), ...walk(20), ...rest(5)]);
    expect(b, hasLength(1));
    expect(b.single.startSec, t0 + 5 * 60);
    expect(b.single.endSec, t0 + 25 * 60);
    expect(b.single.durationMin, 20);
    expect(b.single.cadenceSpm, closeTo(100, 1));
    expect(b.single.avgBpm, 100);
  });

  test('W2 – Spaziergang bei Puls um 100 und 85 Schritten/Minute zählt', () {
    final b = run([...rest(3), ...walk(30, 85), ...rest(3)]);
    expect(b, hasLength(1));
    expect(b.single.durationMin, 30);
  });

  test('W3 – kürzer als 15 Minuten ist kein Gang', () {
    expect(run([...rest(5), ...walk(14), ...rest(5)]), isEmpty);
    expect(run([...rest(5), ...walk(15), ...rest(5)]), hasLength(1));
  });

  test('W4 – Pause bis 2 Minuten wird überbrückt, 3 Minuten trennen', () {
    final bridged = run([...walk(8), ...rest(2), ...walk(8)]);
    expect(bridged, hasLength(1));
    expect(bridged.single.durationMin, 18);

    final split = run([...walk(10), ...rest(3), ...walk(10)]);
    expect(split, isEmpty, reason: 'zwei Teile zu je 10 Minuten');
  });

  test('W5 – langsames Schlurfen unter 80 Schritten/Minute zählt nicht', () {
    expect(run(walk(40, 60)), isEmpty);
    expect(run(walk(40, 79)), isEmpty);
  });

  test('W6 – gespeichertes Training sperrt seine Minuten', () {
    // Training in Minute 10 bis 20 mitten im Gehen: übrig bleiben 10 + 10
    // Minuten, beide zu kurz. Die Sperre wird nicht überbrückt.
    final blocked = [(t0 + 10 * 60, t0 + 20 * 60)];
    expect(run(walk(30), blocked: blocked), isEmpty);
    // Heimweg nach dem Training: 20 Minuten danach bleiben ein Gang.
    final after = run(walk(40), blocked: [(t0, t0 + 20 * 60)]);
    expect(after, hasLength(1));
    expect(after.single.startSec, t0 + 20 * 60);
  });

  test('W7 – Zählerüberlauf bei 65536 zählt richtig weiter', () {
    final b = run(walk(20), startCounter: 65536 - 500);
    expect(b, hasLength(1));
    expect(b.single.steps, closeTo(2000, 3));
  });

  test('W8 – Datenlücke und Zählersprung erfinden keine Schritte', () {
    final s = series(walk(20));
    // 5 Minuten Lücke in der Mitte: zwei Teile zu ~10 Minuten.
    final keep = [
      for (var i = 0; i < s.ts.length; i++)
        if (s.ts[i] < t0 + 8 * 60 || s.ts[i] >= t0 + 13 * 60) i
    ];
    final gap = detectWalks(
      tsSec: [for (final i in keep) s.ts[i]],
      stepCount: [for (final i in keep) s.steps[i]],
    );
    expect(gap, isEmpty);

    // Reset des Zählers auf 0 mitten im Stillsitzen: kein Riesengang.
    final ts = [for (var i = 0; i < 1800; i++) t0 + i];
    final steps = [for (var i = 0; i < 1800; i++) i < 900 ? 40000 : 0];
    expect(detectWalks(tsSec: ts, stepCount: steps), isEmpty);
  });

  test('W9 – Band ohne Schrittzähler (-1) liefert nichts', () {
    final ts = [for (var i = 0; i < 3600; i++) t0 + i];
    expect(detectWalks(tsSec: ts, stepCount: List.filled(3600, -1)), isEmpty);
    expect(detectWalks(tsSec: ts, stepCount: const []), isEmpty);
  });

  test('W10 – Vorschlagszeile hat Sportart walking aus dem Katalog', () {
    final rows = walkSuggestionRows('2026-01-01', run(walk(20)));
    expect(rows, hasLength(1));
    final r = rows.single;
    expect(r['id'], '2026-01-01:$t0');
    expect(r['sport'], 'walking');
    expect(r['start_ts'], t0);
    expect(r['end_ts'], t0 + 20 * 60);
    expect(r['steps'] as int, closeTo(2000, 3));
    expect(activityByName(r['sport'] as String)?.name, 'Walking');
  });
}
