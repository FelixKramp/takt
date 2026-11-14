// Takt Feature: Tages-Stress-Kurve (Whoop-Style Stress Monitor).
//
// Berechnet einen kontinuierlichen Stress-Score von 0,0 bis 3,0 über den gesamten
// Tag aus 5-Minuten-Intervallen von Herzfrequenz und HRV gegenüber der Ruhebasis:
// - 0,0 – 0,99: Niedriger Stress (Erholung, Entspannung) — Blau / Teal
// - 1,0 – 1,99: Moderater Stress (Alltag, normale mentale/körperliche Last) — Gelb / Orange
// - 2,0 – 3,00: Hoher Stress (starke sympathetic-arousal Belastung) — Rot
//
// Sporteinheiten und Trainings werden als Aktivität erkannt und separiert,
// sodass physische Belastung nicht fälschlich als mentaler Stress gewertet wird.

import 'dart:math' as math;

import '../../data/local_repository.dart';
import '../../compute/hr_max.dart' show estimatedMaxHr;

/// Ein 5-Minuten-Stressdatenpunkt im Tagesverlauf.
class DayStressSample {
  const DayStressSample({
    required this.timestampSec,
    required this.score,
    required this.hr,
    this.rmssd,
    this.isSleep = false,
    this.isActivity = false,
    this.activityName,
  });

  /// Unix-Zeitstempel in Sekunden.
  final int timestampSec;

  /// Stresswert von 0,0 bis 3,0 (Whoop-Skala) oder null bei Aktivitäten (G13).
  final double? score;

  /// Durchschnittliche Herzfrequenz in diesem Intervall (bpm).
  final double hr;

  /// RMSSD in diesem Intervall (ms), falls verfügbar.
  final double? rmssd;

  /// Ob das Intervall während des Schlafs lag.
  final bool isSleep;

  /// Ob das Intervall während eines Trainings / Aktivität lag.
  final bool isActivity;

  /// Name der Sportart / Aktivität, falls vorhanden.
  final String? activityName;

  /// Stress-Zone (0 = Niedrig, 1 = Mittel, 2 = Hoch).
  int get zone {
    final s = score;
    if (s == null) return 0;
    if (s < 1.0) return 0;
    if (s < 2.0) return 1;
    return 2;
  }
}

/// Aggregierte Analyse des Tages-Stressverlaufs.
class DayStressAnalysis {
  const DayStressAnalysis({
    required this.date,
    required this.samples,
    required this.avgStress,
    required this.lowStressMin,
    required this.mediumStressMin,
    required this.highStressMin,
    required this.activityMin,
    required this.sleepMin,
    required this.peakStress,
    required this.peakTimeSec,
    required this.hasData,
    this.hasError = false,
  });

  factory DayStressAnalysis.empty(String date) => DayStressAnalysis(
        date: date,
        samples: const [],
        avgStress: null,
        lowStressMin: 0,
        mediumStressMin: 0,
        highStressMin: 0,
        activityMin: 0,
        sleepMin: 0,
        peakStress: null,
        peakTimeSec: null,
        hasData: false,
        hasError: false,
      );

  factory DayStressAnalysis.error(String date) => DayStressAnalysis(
        date: date,
        samples: const [],
        avgStress: null,
        lowStressMin: 0,
        mediumStressMin: 0,
        highStressMin: 0,
        activityMin: 0,
        sleepMin: 0,
        peakStress: null,
        peakTimeSec: null,
        hasData: false,
        hasError: true,
      );

  final String date;
  final List<DayStressSample> samples;

  /// Durchschnittlicher Stress während der Wachzeit (ohne Workouts).
  final double? avgStress;

  /// Minuten in niedriger Stresszone (0,0 – 1,0).
  final int lowStressMin;

  /// Minuten in mittlerer Stresszone (1,0 – 2,0).
  final int mediumStressMin;

  /// Minuten in hoher Stresszone (2,0 – 3,0).
  final int highStressMin;

  /// Minuten in erfassten Aktivitäten / Sport.
  final int activityMin;

  /// Minuten im Schlaf.
  final int sleepMin;

  /// Maximaler Stresswert des Tages (ohne Workouts).
  final double? peakStress;

  /// Zeitpunkt des Höchstwerts (Unix-Sekunden).
  final int? peakTimeSec;

  final bool hasData;

  /// Ob beim Laden ein Fehler aufgetreten ist (G23).
  final bool hasError;

  /// Gesamtminuten der Wachphase mit auswertbaren Daten.
  int get awakeDataMin => lowStressMin + mediumStressMin + highStressMin;

  /// Prozentualer Anteil der Zonen an der Wachzeit.
  double get lowPct => awakeDataMin > 0 ? (lowStressMin / awakeDataMin) : 0.0;
  double get mediumPct =>
      awakeDataMin > 0 ? (mediumStressMin / awakeDataMin) : 0.0;
  double get highPct =>
      awakeDataMin > 0 ? (highStressMin / awakeDataMin) : 0.0;

  /// Der aktuellste nicht-schlafende Messwert des Tages (für die Live-Anzeige).
  DayStressSample? get latestAwakeSample {
    final awake = samples.where((s) => !s.isSleep && !s.isActivity).toList();
    return awake.isEmpty ? null : awake.last;
  }
}

class DayStressCalculator {
  /// Berechnet die Stress-Kurve aus HR-Kurve, HRV-Timeline, Schlaf- und Trainingszeiträumen.
  static DayStressAnalysis compute({
    required String date,
    required List<Map<String, dynamic>> hrCurve,
    List<Map<String, dynamic>> hrvTimeline = const [],
    double? restingHr,
    double? maxHr,
    double? baselineRmssd,
    List<(int, int)> sleepWindows = const [],
    List<(int, int, String)> workouts = const [],
  }) {
    if (hrCurve.isEmpty) return DayStressAnalysis.empty(date);

    // G15: Nie erfundene Werte (AGENTS.md, Regel 3). Ohne Ruhebasis kann kein Stress
    // berechnet werden.
    if (restingHr == null || restingHr <= 0) return DayStressAnalysis.empty(date);

    final rhr = restingHr;
    // G14/G15: Ohne persönlichen Maximalpuls gibt es keine Sportgrenze über den
    // Puls. Ein Ersatzwert (Ruhepuls + 120) wäre erfunden. Trainings aus der
    // Tages-Timeline zählen weiter als Sport.
    final mhr = (maxHr != null && maxHr > rhr) ? maxHr : null;
    final rmssdBsl = baselineRmssd;

    // 1. HRV-Map für schnellen Lookup nach 5-Minuten-Bin
    final hrvByBin = <int, double>{};
    for (final h in hrvTimeline) {
      final t = (h['t'] as num?)?.toInt();
      final v = (h['rmssd'] ?? h['v'] as num?)?.toDouble();
      if (t != null && v != null && v > 0) {
        final bin = t ~/ 300;
        hrvByBin[bin] = v;
      }
    }

    // 2. HR nach 5-Minuten-Bins gruppieren (300 Sekunden)
    final hrBuckets = <int, List<double>>{};
    for (final e in hrCurve) {
      final t = (e['t'] as num?)?.toInt();
      final v = (e['v'] as num?)?.toDouble();
      if (t != null && v != null && v > 0) {
        final bin = t ~/ 300;
        (hrBuckets[bin] ??= []).add(v);
      }
    }

    if (hrBuckets.isEmpty) return DayStressAnalysis.empty(date);

    final sortedBins = hrBuckets.keys.toList()..sort();
    final rawSamples = <DayStressSample>[];

    for (final bin in sortedBins) {
      final hrs = hrBuckets[bin]!;
      // G18: Mindestabdeckung. Ein einzelner isolierter Messwert in 5 Minuten (z. B. 1 Sekunde)
      // rechtfertigt keine 5 Minuten Auswertung. Mindestens 2 Samples nötig.
      if (hrs.length < 2) continue;

      final tSec = bin * 300 + 150; // Intervallmitte
      final avgHr = hrs.reduce((a, b) => a + b) / hrs.length;
      final binRmssd = hrvByBin[bin];

      // Schlaf prüfen
      var isSleep = false;
      for (final (start, end) in sleepWindows) {
        if (tSec >= start && tSec <= end) {
          isSleep = true;
          break;
        }
      }

      // Workout / Aktivität prüfen
      var isActivity = false;
      String? actName;
      for (final (start, end, name) in workouts) {
        if (tSec >= start && tSec <= end) {
          isActivity = true;
          actName = name;
          break;
        }
      }

      // G14: Sportgrenze bei 75 % HRR gegen persönliche maxHr
      if (!isSleep && !isActivity && mhr != null && avgHr >= rhr + 0.75 * (mhr - rhr)) {
        isActivity = true;
        actName = 'Aktivität';
      }

      double? score;
      if (isSleep) {
        // Im Schlaf: Ruhestress typischerweise niedrig (0,0 – 0,7)
        final diff = math.max(0.0, avgHr - rhr);
        score = (diff / 25.0 * 0.7).clamp(0.0, 0.9);
      } else if (isActivity) {
        // G13: Physisches Training ist kein mentaler Stress. Kein erfundener Wert 2,5!
        score = null;
      } else {
        // Wachzeit ohne Workout: Autonomer Stress
        final hrDelta = avgHr - rhr;
        final hrStressFactor =
            ((hrDelta - 10.0) / 42.0).clamp(0.0, 1.0);

        double stressFactor;
        if (binRmssd != null && rmssdBsl != null && rmssdBsl > 0) {
          // Geringere HRV bedeutet höhere sympathische Aktivierung
          final hrvFactor =
              (1.0 - (binRmssd / rmssdBsl)).clamp(0.0, 1.0);
          stressFactor = 0.55 * hrStressFactor + 0.45 * hrvFactor;
        } else {
          stressFactor = hrStressFactor;
        }

        score = (stressFactor * 3.0).clamp(0.0, 3.0);
      }

      rawSamples.add(DayStressSample(
        timestampSec: tSec,
        score: score,
        hr: avgHr,
        rmssd: binRmssd,
        isSleep: isSleep,
        isActivity: isActivity,
        activityName: actName,
      ));
    }

    // 3. Glätten mit 3-Punkt-Median (nur für Wachzeit-Nicht-Workouts mit Score)
    final smoothed = <DayStressSample>[];
    for (var i = 0; i < rawSamples.length; i++) {
      final cur = rawSamples[i];
      if (cur.isSleep || cur.isActivity || cur.score == null || i == 0 || i == rawSamples.length - 1) {
        smoothed.add(cur);
        continue;
      }
      final prev = rawSamples[i - 1];
      final next = rawSamples[i + 1];
      if (prev.isSleep || prev.isActivity || prev.score == null ||
          next.isSleep || next.isActivity || next.score == null) {
        smoothed.add(cur);
        continue;
      }
      final trio = [prev.score!, cur.score!, next.score!]..sort();
      final medianScore = trio[1];
      smoothed.add(DayStressSample(
        timestampSec: cur.timestampSec,
        score: medianScore,
        hr: cur.hr,
        rmssd: cur.rmssd,
        isSleep: false,
        isActivity: false,
        activityName: null,
      ));
    }

    // 4. Statistiken aggregieren
    var lowMin = 0;
    var medMin = 0;
    var highMin = 0;
    var actMin = 0;
    var sleepMin = 0;
    var wakingScoreSum = 0.0;
    var wakingScoreCount = 0;
    double? peak;
    int? peakTime;

    for (final s in smoothed) {
      if (s.isSleep) {
        sleepMin += 5;
      } else if (s.isActivity) {
        actMin += 5;
      } else if (s.score != null) {
        wakingScoreSum += s.score!;
        wakingScoreCount++;
        if (s.score! < 1.0) {
          lowMin += 5;
        } else if (s.score! < 2.0) {
          medMin += 5;
        } else {
          highMin += 5;
        }
        if (peak == null || s.score! > peak) {
          peak = s.score!;
          peakTime = s.timestampSec;
        }
      }
    }

    final avgStress = wakingScoreCount > 0
        ? (wakingScoreSum / wakingScoreCount)
        : null;

    return DayStressAnalysis(
      date: date,
      samples: smoothed,
      avgStress: avgStress,
      lowStressMin: lowMin,
      mediumStressMin: medMin,
      highStressMin: highMin,
      activityMin: actMin,
      sleepMin: sleepMin,
      peakStress: peak,
      peakTimeSec: peakTime,
      hasData: smoothed.isNotEmpty,
    );
  }

  /// Lädt alle relevanten Daten für [date] aus dem Repository und errechnet die Analyse.
  static Future<DayStressAnalysis> loadForDay(
    LocalRepository repo,
    String date,
  ) async {
    try {
      final tl = await repo.getDayTimeline(date);
      // G16: Timeline muss zum angeforderten Tag gehören!
      final tlDate = tl['date'] as String?;
      if (tlDate != null && tlDate != date) {
        return DayStressAnalysis.empty(date);
      }

      final stressPayload = await repo.getDayStress(date);
      final heart = await repo.getDayHeart(date);
      final profile = await repo.getProfile();

      final hrCurve = (tl['hr'] as List?)?.cast<Map<String, dynamic>>() ??
          (stressPayload['hr'] as List?)?.cast<Map<String, dynamic>>() ??
          const [];

      final dtHrv = stressPayload['daytime_hrv'];
      final hrvTimeline = dtHrv is Map && dtHrv['timeline'] is List
          ? (dtHrv['timeline'] as List).cast<Map<String, dynamic>>()
          : const <Map<String, dynamic>>[];

      // G15: Bevorzuge gleitende Baseline
      final baselines = heart['baselines'] is Map ? heart['baselines'] as Map : null;
      final baselineRhr = (baselines?['resting_hr'] is Map
              ? baselines!['resting_hr']['usual'] as num?
              : null)
          ?.toDouble();
      final rhr = baselineRhr ??
          (heart['resting_hr'] as num?)?.toDouble() ??
          (heart['rhr'] as num?)?.toDouble();

      // G14: Persönliche Maximal-Herzfrequenz, die EINE Definition der App:
      // `max_hr_used` aus dem Tages-Strain, sonst die Schätzung nach Alter
      // (hr_max.dart). Nie der Höchstwert dieses Tages: Der wäre an jedem Tag
      // mit einem Sprint die Grenze und sortierte die stärkste Belastung ohne
      // Sport als Sport aus.
      final strain = await repo.getDayStrain(date);
      final used = (strain['max_hr_used'] as num?)?.toDouble();
      final mhr = (used != null && used > 0)
          ? used
          : estimatedMaxHr(profile['age'] as num?, null);

      // G15: Daytime-HRV oder Baseline-HRV
      final baselineHrv = (baselines?['hrv'] is Map
              ? baselines!['hrv']['usual'] as num?
              : null)
          ?.toDouble();
      final dtHrvMean = (dtHrv is Map ? dtHrv['mean_rmssd'] as num? : null)?.toDouble();
      final rmssdBsl = dtHrvMean ??
          baselineHrv ??
          (stressPayload['stress'] is Map
              ? (stressPayload['stress']['rmssd'] as num?)?.toDouble()
              : null) ??
          (heart['rmssd'] as num?)?.toDouble();

      final sleepList = tl['sleep'] as List?;
      final sleepWindows = <(int, int)>[];
      if (sleepList != null) {
        for (final s in sleepList) {
          if (s is Map) {
            final on = (s['onset_ts'] as num?)?.toInt();
            final off = (s['wake_ts'] as num?)?.toInt();
            if (on != null && off != null) sleepWindows.add((on, off));
          }
        }
      }

      final sessions = tl['sessions'] as List?;
      final workouts = <(int, int, String)>[];
      if (sessions != null) {
        for (final s in sessions) {
          if (s is Map) {
            final start = (s['start_ts'] as num?)?.toInt();
            final end = (s['end_ts'] as num?)?.toInt();
            final sport = (s['sport'] ?? s['type'] ?? 'Training').toString();
            if (start != null && end != null) {
              workouts.add((start, end, sport));
            }
          }
        }
      }

      return compute(
        date: date,
        hrCurve: hrCurve,
        hrvTimeline: hrvTimeline,
        restingHr: rhr,
        maxHr: mhr,
        baselineRmssd: rmssdBsl,
        sleepWindows: sleepWindows,
        workouts: workouts,
      );
    } catch (_) {
      return DayStressAnalysis.error(date);
    }
  }
}
