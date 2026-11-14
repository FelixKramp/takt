// Takt: Gehen und Spaziergänge automatisch erkennen.
//
// Die Workout-Erkennung aus openstrap_analytics schlägt nur Bouts vor, die
// mindestens 12 Minuten bei hohem Puls liegen. Ein Spaziergang mit Puls um 100
// fällt da nie hinein. Dieser Detektor schaut deshalb nicht auf den Puls,
// sondern auf den Schrittzähler des Bands (Gen5, ein Zählerstand pro Sekunde).
//
// Regel (Spec docs/features/14-gehen-erkennen):
//   * Eine Minute zählt als Gehen ab [WalkRules.minSpm] Schritten.
//   * Pausen bis [WalkRules.maxGapMin] Minuten werden überbrückt (Ampel,
//     kurz stehen bleiben).
//   * Ein Gang zählt ab [WalkRules.minDurationMin] Minuten.
//   * Minuten in gespeicherten Trainings, erkannten Workouts oder Schlaf sind
//     gesperrt: Sie unterbrechen einen Gang und werden nicht überbrückt.
//
// Rein und isolate-fest: keine Uhr, keine Datenbank.

/// Schwellen des Detektors. Werte an Felix' echten Banddaten geprüft, siehe
/// Spec.
class WalkRules {
  /// Schritte pro Minute, ab denen eine Minute als Gehen zählt.
  final int minSpm;

  /// Längste Pause in Minuten, die einen Gang nicht beendet.
  final int maxGapMin;

  /// Kürzester Gang in Minuten.
  final int minDurationMin;

  const WalkRules({
    this.minSpm = 80,
    this.maxGapMin = 2,
    this.minDurationMin = 15,
  });
}

/// Ein erkannter Gang.
class WalkBout {
  final int startSec;
  final int endSec;
  final int steps;
  final int? avgBpm;
  final int? peakBpm;

  const WalkBout({
    required this.startSec,
    required this.endSec,
    required this.steps,
    this.avgBpm,
    this.peakBpm,
  });

  int get durationMin => ((endSec - startSec) / 60).round();

  /// Mittlere Schrittfrequenz über den ganzen Gang, Pausen eingerechnet.
  int get cadenceSpm =>
      endSec > startSec ? (steps * 60 / (endSec - startSec)).round() : 0;
}

/// Zwei Zählerstände, die mehr als so viele Sekunden auseinanderliegen, werden
/// nicht verrechnet: Über eine Datenlücke ist unbekannt, wann gegangen wurde.
const _kMaxSampleGapSec = 10;

/// Mehr Schritte in einer Sekunde sind kein Gehen, sondern ein Zählersprung
/// (Reset, Neustart des Bands).
const _kMaxStepsPerSample = 50;

/// Findet Gänge im 1-Hz-Schrittzähler.
///
/// [tsSec] ist aufsteigend, [stepCount] parallel dazu der kumulative
/// Zählerstand des Bands (u16, läuft bei 65536 über, -1 = kein Wert).
/// [hr] ist optional parallel (0 = kein Puls). [blocked] sind Spannen
/// `(startSec, endSec)`, die kein Gang berühren darf.
List<WalkBout> detectWalks({
  required List<int> tsSec,
  required List<int> stepCount,
  List<int> hr = const [],
  List<(int, int)> blocked = const [],
  WalkRules rules = const WalkRules(),
}) {
  final n = tsSec.length < stepCount.length ? tsSec.length : stepCount.length;
  if (n < 2) return const [];

  // Schritte und Puls je Minute.
  final steps = <int, int>{};
  final hrSum = <int, int>{};
  final hrCount = <int, int>{};
  final hrPeak = <int, int>{};
  var prevI = -1;
  for (var i = 0; i < n; i++) {
    final m = tsSec[i] ~/ 60;
    if (i < hr.length && hr[i] > 0) {
      hrSum[m] = (hrSum[m] ?? 0) + hr[i];
      hrCount[m] = (hrCount[m] ?? 0) + 1;
      if (hr[i] > (hrPeak[m] ?? 0)) hrPeak[m] = hr[i];
    }
    if (stepCount[i] < 0) continue;
    if (prevI >= 0) {
      final dt = tsSec[i] - tsSec[prevI];
      final d = (stepCount[i] - stepCount[prevI]) % 65536;
      if (dt > 0 && dt <= _kMaxSampleGapSec && d <= _kMaxStepsPerSample) {
        steps[m] = (steps[m] ?? 0) + d;
      }
    }
    prevI = i;
  }
  if (steps.isEmpty) return const [];

  bool isBlocked(int m) {
    final lo = m * 60, hi = lo + 60;
    for (final (a, b) in blocked) {
      if (a < hi && b > lo) return true;
    }
    return false;
  }

  bool isWalking(int m) => (steps[m] ?? 0) >= rules.minSpm && !isBlocked(m);

  final keys = steps.keys.toList()..sort();
  final bouts = <WalkBout>[];
  int? first, last;

  void close() {
    if (first == null) return;
    final a = first!, b = last!;
    first = last = null;
    if (b - a + 1 < rules.minDurationMin) return;
    var total = 0, sum = 0, count = 0, peak = 0;
    for (var m = a; m <= b; m++) {
      total += steps[m] ?? 0;
      sum += hrSum[m] ?? 0;
      count += hrCount[m] ?? 0;
      final p = hrPeak[m] ?? 0;
      if (p > peak) peak = p;
    }
    bouts.add(WalkBout(
      startSec: a * 60,
      endSec: (b + 1) * 60,
      steps: total,
      avgBpm: count == 0 ? null : (sum / count).round(),
      peakBpm: peak == 0 ? null : peak,
    ));
  }

  for (final m in keys) {
    if (!isWalking(m)) continue;
    if (first != null) {
      // Lücke zwischen letzter Gehminute und dieser: höchstens maxGapMin
      // Minuten, und keine davon gesperrt.
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

/// Erkannte Gänge als Zeilen für `ActivityStore.reconcile(ActivityKind.workout, …)`,
/// im selben Format wie die Workout-Vorschläge der Upstream-Erkennung.
List<Map<String, dynamic>> walkSuggestionRows(String date, List<WalkBout> walks) => [
      for (final w in walks)
        {
          'id': '$date:${w.startSec}',
          'date': date,
          'start_ts': w.startSec,
          'end_ts': w.endSec,
          'avg_bpm': w.avgBpm,
          'peak_bpm': w.peakBpm,
          'duration_min': w.durationMin,
          'sport': 'walking',
          'steps': w.steps,
          'cadence_spm': w.cadenceSpm,
          'detector': 'takt_walk',
          'dismissed': 0,
        },
    ];
