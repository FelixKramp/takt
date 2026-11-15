// Takt: Radfahren automatisch erkennen (Feature 15).
//
// Am Handgelenk sieht Radfahren so aus: Der Puls ist deutlich über Ruhe, aber
// der Schrittzähler steht fast still, weil die Hand am Lenker liegt. Zwei Wege:
//
//   1. Bouts der Puls-Erkennung (openstrap_analytics, ≥ 45 % HRR) heißen dort
//      nur "detected". Hat so ein Bout kaum Schritte, ist es Radfahren
//      ([cyclingSportFor]).
//   2. Gemütliches Fahren liegt unter dieser Schwelle. [detectCycling] sucht
//      Minuten mit Puls ab Ruhe + [CycleRules.minHrAboveRest] und höchstens
//      [CycleRules.maxSpm] Schritten.
//
// Sitzen mit hohem Puls (Prüfung, Aufregung) sieht genauso aus. Deshalb muss
// eine Fahrt einen sichtbaren Anfang haben: Direkt davor wurde gegangen (zum
// Rad), oder der Puls steigt zu Beginn schnell an. Erkannte Workouts werden
// nach 30 Minuten ohne Rückfrage gespeichert, ein Fehlalarm kostet also mehr
// als eine verpasste Fahrt.
//
// Rein und isolate-fest: keine Uhr, keine Datenbank.

import 'walk_detect.dart';

class CycleRules {
  /// Puls über Ruhepuls (bpm), ab dem eine Minute als Fahren zählen kann.
  final int minHrAboveRest;

  /// Höchstens so viele Schritte pro Minute.
  final int maxSpm;

  /// Längste Pause (Ampel, Absteigen), die eine Fahrt nicht beendet.
  final int maxGapMin;

  /// Kürzeste Fahrt in Minuten.
  final int minDurationMin;

  /// Längste Fahrt. Was länger dauert, ist eher ein Tag mit hohem Puls.
  final int maxDurationMin;

  /// Anstieg (bpm) vom Mittel der 3 Minuten davor zum Mittel der ersten 3
  /// Minuten, der als Anfang einer Fahrt gilt.
  final int onsetRiseBpm;

  /// Schritte pro Minute, ab denen eine Minute direkt vor der Fahrt als Gehen
  /// zum Rad zählt.
  final int walkSpm;

  const CycleRules({
    this.minHrAboveRest = 30,
    this.maxSpm = 25,
    this.maxGapMin = 2,
    this.minDurationMin = 10,
    this.maxDurationMin = 180,
    this.onsetRiseBpm = 12,
    this.walkSpm = 60,
  });
}

class CycleBout {
  final int startSec;
  final int endSec;
  final int? avgBpm;
  final int? peakBpm;

  const CycleBout({required this.startSec, required this.endSec, this.avgBpm, this.peakBpm});

  int get durationMin => ((endSec - startSec) / 60).round();
}

/// Mittlere Schritte pro Minute in `[fromSec, toSec)`, nur über Minuten mit
/// Zählerstand. Null, wenn keine Minute einen hat (Gen4, Lücke).
double? meanSpm(Map<int, int> stepsPerMin, int fromSec, int toSec) {
  var sum = 0, count = 0;
  for (var m = fromSec ~/ 60; m * 60 < toSec; m++) {
    final v = stepsPerMin[m];
    if (v == null) continue;
    sum += v;
    count++;
  }
  // Weniger als die Hälfte der Minuten mit Zähler reicht nicht für ein Urteil.
  final minutes = ((toSec - fromSec) / 60).ceil();
  if (count == 0 || count * 2 < minutes) return null;
  return sum / count;
}

/// Sportart für einen Bout der Puls-Erkennung: `cycling`, wenn er kaum
/// Schritte hat, sonst bleibt [sport] stehen.
String cyclingSportFor(
  String sport,
  Map<int, int> stepsPerMin,
  int startSec,
  int endSec, {
  CycleRules rules = const CycleRules(),
}) {
  final spm = meanSpm(stepsPerMin, startSec, endSec);
  return spm != null && spm <= rules.maxSpm ? 'cycling' : sport;
}

/// Findet Fahrten unterhalb der Puls-Erkennung. [blocked] sind Spannen, die
/// keine Fahrt berühren darf (gespeicherte Trainings, Bouts, Gänge).
List<CycleBout> detectCycling({
  required List<int> tsSec,
  required List<int> stepCount,
  required List<int> hr,
  required int? restingBpm,
  List<(int, int)> blocked = const [],
  CycleRules rules = const CycleRules(),
}) {
  if (restingBpm == null) return const [];
  final steps = stepsByMinute(tsSec, stepCount);
  if (steps.isEmpty) return const [];

  final n = tsSec.length < hr.length ? tsSec.length : hr.length;
  final hrSum = <int, int>{}, hrCount = <int, int>{}, hrPeak = <int, int>{};
  for (var i = 0; i < n; i++) {
    if (hr[i] <= 0) continue;
    final m = tsSec[i] ~/ 60;
    hrSum[m] = (hrSum[m] ?? 0) + hr[i];
    hrCount[m] = (hrCount[m] ?? 0) + 1;
    if (hr[i] > (hrPeak[m] ?? 0)) hrPeak[m] = hr[i];
  }
  // Eine Minute braucht mindestens 30 Pulswerte, sonst ist ihr Mittel Zufall.
  double? hrOf(int m) => (hrCount[m] ?? 0) >= 30 ? hrSum[m]! / hrCount[m]! : null;

  bool isBlocked(int m) {
    final lo = m * 60, hi = lo + 60;
    for (final (a, b) in blocked) {
      if (a < hi && b > lo) return true;
    }
    return false;
  }

  final threshold = restingBpm + rules.minHrAboveRest;
  bool isRiding(int m) {
    final s = steps[m], h = hrOf(m);
    return s != null && h != null && s <= rules.maxSpm && h >= threshold && !isBlocked(m);
  }

  double? meanHr(int fromM, int toM) {
    var sum = 0.0, count = 0;
    for (var m = fromM; m < toM; m++) {
      final h = hrOf(m);
      if (h == null) continue;
      sum += h;
      count++;
    }
    return count == 0 ? null : sum / count;
  }

  bool hasStart(int a) {
    // Zum Rad gegangen: eine Gehminute in den 3 Minuten davor.
    for (var m = a - 3; m < a; m++) {
      if ((steps[m] ?? 0) >= rules.walkSpm) return true;
    }
    // Oder schneller Anstieg. Ohne Puls davor lässt sich das nicht sagen.
    final pre = meanHr(a - 3, a), early = meanHr(a, a + 3);
    return pre != null && early != null && early - pre >= rules.onsetRiseBpm;
  }

  final bouts = <CycleBout>[];
  int? first, last;
  void close() {
    if (first == null) return;
    final a = first!, b = last!;
    first = last = null;
    final len = b - a + 1;
    if (len < rules.minDurationMin || len > rules.maxDurationMin) return;
    if (!hasStart(a)) return;
    var sum = 0.0, count = 0, peak = 0;
    for (var m = a; m <= b; m++) {
      sum += hrSum[m] ?? 0;
      count += hrCount[m] ?? 0;
      if ((hrPeak[m] ?? 0) > peak) peak = hrPeak[m]!;
    }
    bouts.add(
      CycleBout(
        startSec: a * 60,
        endSec: (b + 1) * 60,
        avgBpm: count == 0 ? null : (sum / count).round(),
        peakBpm: peak == 0 ? null : peak,
      ),
    );
  }

  final keys = steps.keys.toList()..sort();
  for (final m in keys) {
    if (!isRiding(m)) continue;
    if (first != null) {
      final gap = m - last! - 1;
      var ok = gap <= rules.maxGapMin;
      for (var g = last! + 1; ok && g < m; g++) {
        if (isBlocked(g)) ok = false;
      }
      if (!ok) close();
    }
    first ??= m;
    last = m;
  }
  close();
  return bouts;
}

/// Fahrten als Vorschlagszeilen, im selben Format wie die Gänge.
List<Map<String, dynamic>> cycleSuggestionRows(String date, List<CycleBout> rides) => [
  for (final r in rides)
    {
      'id': '$date:${r.startSec}',
      'date': date,
      'start_ts': r.startSec,
      'end_ts': r.endSec,
      'avg_bpm': r.avgBpm,
      'peak_bpm': r.peakBpm,
      'duration_min': r.durationMin,
      'sport': 'cycling',
      'detector': 'takt_cycle',
      'dismissed': 0,
    },
];
