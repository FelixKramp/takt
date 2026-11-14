// Tageslogik von Takt: Ein Tag reicht vom Aufwachen bis zum nächsten
// Einschlafen (und bleibt nach 00:00 Uhr aktiv, bis die nächste Nacht vorbei
// ist). Sobald morgens nach dem Aufwachen eine Nacht berechnet ist, stehen
// Schlaf, Batterie, HRV und Ruhepuls sofort bereit, ohne eine Stunde auf
// OpenStraps `overnightSettled` zu warten.

import 'dart:math' as math;

import '../../data/day_label.dart'
    show dayLabelBefore, dayLabelOf, localDayEndSec, localDayStartSec, todayLabel;
import '../../data/local_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/metric.dart';
import '../../ui2/activity/day_strain.dart' show DayStrainData;
import '../../ui2/screens/home_screen.dart'
    show HomeData, metricOf, overnightMetric, pointsOf;
import '../battery/battery.dart' show peakStrain;
import '../now.dart';

const _kDefaultStepGoal = 8000;

const _maxNetTrimp = 400.0;
const _strainCurvature = 15.0;

/// Umkehrung von `strainFromNetTrimp`: rechnet einen 0–21-Strain zurück in den
/// Netto-TRIMP über der Ruheschwelle, damit Belastung vor und nach Mitternacht
/// exakt auf derselben Skala addiert und abgezogen werden kann.
double strainToNetTrimp(double strain) {
  if (!strain.isFinite || strain <= 0) return 0.0;
  final s = strain.clamp(0.0, 21.0);
  final u = (math.pow(_strainCurvature, s / 21.0) - 1.0) / (_strainCurvature - 1.0);
  return (_maxNetTrimp * u).clamp(0.0, _maxNetTrimp);
}

/// Abbildung von Netto-TRIMP auf die 0–21-Skala (identisch zu
/// `openstrap_analytics` `strainFromNetTrimp`).
double netTrimpToStrain(double net) {
  if (!net.isFinite || net <= 0) return 0.0;
  final u = math.min(1.0, net / _maxNetTrimp);
  final s = 21.0 *
      math.log(1.0 + u * (_strainCurvature - 1.0)) /
      math.log(_strainCurvature);
  return s.clamp(0.0, 21.0);
}

/// Addiert zwei Strain-Werte auf der 0–21-Skala über ihren Netto-TRIMP.
double? combineStrain(double? a, double? b) {
  if (a == null && b == null) return null;
  if (a == null) return b;
  if (b == null) return a;
  return netTrimpToStrain(strainToNetTrimp(a) + strainToNetTrimp(b));
}

/// Zieht die vor dem Aufwachen (zwischen 00:00 Uhr und dem Einschlafen)
/// angefallene Belastung vom Tageswert ab, damit sie beim Vortag bleibt und
/// den neuen Morgen nicht vorbelastet.
double subtractPreWakeStrain(double total, double? preWake) {
  if (preWake == null || preWake <= 0) return total;
  final net = math.max(0.0, strainToNetTrimp(total) - strainToNetTrimp(preWake));
  return netTrimpToStrain(net);
}

/// Das Wachfenster eines Tages: vom eigenen Aufwachen ([fromSec]) bis zum
/// Einschlafen der nächsten Nacht ([toSec]).
class WakeWindow {
  const WakeWindow({
    required this.dayId,
    required this.fromSec,
    required this.toSec,
    this.wakeSec,
    this.nextOnsetSec,
  });

  final String dayId;
  final int fromSec;
  final int toSec;
  final int? wakeSec;
  final int? nextOnsetSec;
}

String? nextDayLabel(String dayId) {
  final d = DateTime.tryParse(dayId);
  if (d == null) return null;
  return dayLabelOf(DateTime(d.year, d.month, d.day + 1));
}

/// Entscheidet, welcher Tag gerade „Heute“ ist:
/// - Hat der heutige Kalendertag ([calToday]) bereits eine abgeschlossene Nacht
///   ([todayHasSleep] und nicht [nightInProgress]), ist sofort [calToday] aktiv.
/// - Zwischen 00:00 und 12:00 Uhr, solange die neue Nacht noch nicht vorbei ist
///   und für gestern ([calYesterday]) Daten vorliegen, bleibt [calYesterday]
///   der aktive Tag (kein Reset um Mitternacht).
String resolveActiveTaktDay({
  required DateTime now,
  required List<String> availableDays,
  required bool todayHasSleep,
  required bool nightInProgress,
  bool yesterdayHasData = false,
}) {
  final calToday = todayLabel(now);
  if (todayHasSleep && !nightInProgress) return calToday;
  final calYesterday = dayLabelBefore(calToday, 1);
  if (calYesterday != null &&
      now.hour < 12 &&
      (availableDays.contains(calYesterday) || yesterdayHasData)) {
    return calYesterday;
  }
  return calToday;
}

/// Berechnet das Wachfenster [fromSec, toSec) für [dayId].
WakeWindow buildWakeWindow({
  required String dayId,
  required Map<String, dynamic> sleep,
  required Map<String, dynamic> nextSleep,
  required bool isActiveAfterMidnight,
}) {
  final dayStart = localDayStartSec(dayId) ?? 0;
  final dayEnd = localDayEndSec(dayId) ?? (dayStart + 86400);
  final wakeTs = (sleep['wake_ts'] as num?)?.toInt();
  final fromSec =
      (wakeTs != null && wakeTs >= dayStart && wakeTs < dayEnd) ? wakeTs : dayStart;

  final nextDay = nextDayLabel(dayId);
  final nextEnd = (nextDay == null ? null : localDayEndSec(nextDay)) ?? (dayEnd + 86400);
  final nextOnset = (nextSleep['onset_ts'] as num?)?.toInt();

  int toSec;
  if (nextOnset != null && nextOnset > fromSec && nextOnset <= nextEnd) {
    // Die nächste Nacht hat begonnen: Der Wachtag endet genau beim Einschlafen,
    // auch wenn das erst nach 00:00 Uhr in der Folgenacht war.
    toSec = nextOnset;
  } else if (isActiveAfterMidnight) {
    // Nach 00:00 Uhr noch wach (noch keine neue Nacht): Der Tag läuft weiter.
    toSec = nextEnd;
  } else {
    toSec = dayEnd;
  }

  return WakeWindow(
    dayId: dayId,
    fromSec: fromSec,
    toSec: toSec,
    wakeSec: wakeTs,
    nextOnsetSec: nextOnset,
  );
}

class TaktDayLoaded {
  const TaktDayLoaded({
    required this.dayId,
    required this.activeDayId,
    required this.availableDays,
    required this.window,
    required this.data,
    required this.hrv,
    required this.strainPeak,
    required this.strainCurve,
    this.todayHasSleep = false,
    this.nightInProgress = false,
  });

  final String dayId;
  final String activeDayId;
  final List<String> availableDays;
  final WakeWindow window;
  final HomeData data;
  final Metric hrv;
  final double? strainPeak;
  final List<double?> strainCurve;
  final bool todayHasSleep;
  final bool nightInProgress;
}

int? _noonSec(String day) {
  final d = DateTime.tryParse('$day 12:00:00');
  return d == null ? null : d.millisecondsSinceEpoch ~/ 1000;
}

Future<Metric> _hrvForDay(
  LocalRepository repo,
  String dayId, {
  Map<String, dynamic>? todayBundle,
  bool allowTodayBundle = false,
}) async {
  if (allowTodayBundle && todayBundle != null) {
    final hrvData = todayBundle['hrv'];
    final rmssd = hrvData is Map ? hrvData['rmssd'] as num? : null;
    if (rmssd != null) {
      return Metric.parse({'value': rmssd, 'unit': 'ms'});
    }
  }
  try {
    final noon = _noonSec(dayId);
    if (noon != null) {
      for (final p in pointsOf(await repo.getChart('hrv'))) {
        if (p.t == noon) return Metric.parse({'value': p.v, 'unit': 'ms'});
      }
    }
  } catch (_) {}
  return Metric.empty;
}

/// Filtert und korrigiert die Strain-Kurve eines Tages um etwaige Minuten vor
/// dem Aufwachen ([wakeSec]) und hängt bei Bedarf Wachminuten nach Mitternacht
/// (aus [nextPts] vor [toSec]) an.
({double? strain, double? peak, List<double?> curve}) adjustWakeStrain({
  required String dayId,
  required double? rawStrain,
  required List<(int, double)> dayPts,
  required WakeWindow window,
  List<(int, double)> nextPts = const [],
  double? nextInterimStrain,
}) {
  final dayStart = localDayStartSec(dayId) ?? 0;
  final dayEnd = localDayEndSec(dayId) ?? (dayStart + 86400);
  final wakeSec = window.wakeSec;

  // 1. Belastung vor dem Aufwachen (00:00 bis wakeSec) gehört zum Vortag.
  double? preWakePeak;
  if (wakeSec != null && wakeSec > dayStart) {
    for (final (t, v) in dayPts) {
      if (t >= dayStart && t < wakeSec && (preWakePeak == null || v > preWakePeak)) {
        preWakePeak = v;
      }
    }
  }

  final adjustedDayPts = <(int, double)>[
    for (final (t, v) in dayPts)
      if (t >= dayStart &&
          t < dayEnd &&
          (wakeSec == null || t >= wakeSec) &&
          t < window.toSec)
        (t, subtractPreWakeStrain(v, preWakePeak)),
  ];

  final rawPeakInDay =
      dayPts.isEmpty ? null : dayPts.map((e) => e.$2).reduce(math.max);
  final effectiveRaw = rawStrain == null && rawPeakInDay == null
      ? null
      : math.max(rawStrain ?? 0.0, rawPeakInDay ?? 0.0);

  var baseStrain = effectiveRaw == null
      ? null
      : subtractPreWakeStrain(effectiveRaw, preWakePeak);
  var basePeak = peakStrain(
    baseStrain,
    [for (final p in adjustedDayPts) p.$2],
  );

  final (_, grid) = DayStrainData.gridCurve(adjustedDayPts);
  final curve = grid.isEmpty ? List<double?>.filled(1440, null) : List<double?>.of(grid);

  // 2. Wachminuten nach 00:00 Uhr (vor dem nächsten Einschlafen) anhängen.
  if (window.toSec > dayEnd) {
    double? postPeak;
    for (final (t, v) in nextPts) {
      if (t >= dayEnd && t < window.toSec && (postPeak == null || v > postPeak)) {
        postPeak = v;
      }
    }
    postPeak ??= nextInterimStrain;
    if (postPeak != null && postPeak > 0) {
      baseStrain = combineStrain(baseStrain, postPeak);
      basePeak = combineStrain(basePeak, postPeak);
      if (curve.any((v) => v != null) && basePeak != null) {
        curve[1439] = basePeak;
      }
    }
  }

  final hasCurve = curve.any((v) => v != null);
  return (
    strain: baseStrain,
    peak: basePeak,
    curve: hasCurve ? curve : const <double?>[],
  );
}

List<(int, double)> _extractCurvePoints(Map<String, dynamic> s, String expectedDay) {
  final start = localDayStartSec(expectedDay);
  final end = localDayEndSec(expectedDay);
  if (start == null || end == null) return const [];
  final out = <(int, double)>[];
  for (final e in (s['curve'] as List? ?? const [])) {
    if (e is Map && e['t'] is num && e['v'] is num) {
      final t = (e['t'] as num).toInt();
      if (t >= start && t < end) {
        out.add((t, (e['v'] as num).toDouble()));
      }
    }
  }
  return out;
}

Future<Map<String, dynamic>> _softMap(
    Future<Map<String, dynamic>> Function() fn) async {
  try {
    return await fn();
  } catch (_) {
    return const {};
  }
}

/// W14: Der Spitzen-Strain je Wachtag für mehrere Tage auf einmal (die Säulen
/// der Wochenkarte). Rechnet mit denselben Bausteinen wie [loadTaktDay]
/// (Wachfenster, Abzug vor dem Aufwachen, Zuschlag nach Mitternacht), damit ein
/// Tag in der Woche denselben Wert hat wie im Tages-Schalter. Tage ohne Kurve
/// fehlen in der Antwort.
Future<Map<String, double>> wakeDayStrainPeaks(
  LocalRepository repo,
  List<String> dayIds, {
  required String activeDay,
  DateTime? now,
}) async {
  final clock = now ?? taktNow();
  final calToday = todayLabel(clock);
  final rawDays = await _softList(repo.availableDays);
  final rawTodaySleep = await _softMap(() => repo.getDaySleepV2(calToday));
  final todayStartSec = localDayStartSec(calToday) ?? 0;
  final wakeTs = (rawTodaySleep['wake_ts'] as num?)?.toInt();
  final sleepDate = rawTodaySleep['date'] as String?;
  final todaySleep = ((sleepDate == null || sleepDate == calToday) &&
          (wakeTs == null || wakeTs >= todayStartSec))
      ? rawTodaySleep
      : const <String, dynamic>{};

  final out = <String, double>{};
  for (final dayId in dayIds) {
    final daySleep = dayId == calToday
        ? todaySleep
        : await _softMap(() => repo.getDaySleepV2(dayId));
    final nextDay = nextDayLabel(dayId);
    Map<String, dynamic> nextSleep = const {};
    if (nextDay != null) {
      if (nextDay == calToday) {
        nextSleep = todaySleep;
      } else if (rawDays.contains(nextDay)) {
        nextSleep = await _softMap(() => repo.getDaySleepV2(nextDay));
      }
    }
    final isActiveAfterMidnight = dayId == activeDay && dayId != calToday;
    final window = buildWakeWindow(
      dayId: dayId,
      sleep: daySleep,
      nextSleep: nextSleep,
      isActiveAfterMidnight: isActiveAfterMidnight,
    );
    final dayStart = localDayStartSec(dayId) ?? 0;
    final dayEnd = localDayEndSec(dayId) ?? (dayStart + 86400);
    final dayMap = await _softMap(() => repo.getDayStrain(dayId));
    final dayPts = _extractCurvePoints(dayMap, dayId);

    final needsWakeAdjust =
        (window.wakeSec != null && window.wakeSec! > dayStart) ||
            window.toSec != dayEnd ||
            dayId != calToday;
    double? peak;
    if (!needsWakeAdjust) {
      peak = peakStrain(null, [for (final p in dayPts) p.$2]);
    } else {
      List<(int, double)> nextPts = const [];
      double? nextInterim;
      if (nextDay != null && window.toSec > dayEnd) {
        final nextMap = await _softMap(() => repo.getDayStrain(nextDay));
        nextPts = _extractCurvePoints(nextMap, nextDay);
        if (isActiveAfterMidnight) {
          nextInterim = (nextMap['strain'] as num?)?.toDouble();
        }
      }
      peak = adjustWakeStrain(
        dayId: dayId,
        rawStrain: (dayMap['strain'] as num?)?.toDouble(),
        dayPts: dayPts,
        window: window,
        nextPts: nextPts,
        nextInterimStrain: nextInterim,
      ).peak;
    }
    if (peak != null) out[dayId] = peak;
  }
  return out;
}

Future<List<String>> _softList(Future<List<String>> Function() fn) async {
  try {
    return await fn();
  } catch (_) {
    return const [];
  }
}

/// W15: Die Schritte, die im Wachfenster [window] liegen. Spannen, die über
/// eine Fenstergrenze reichen, zählen anteilig nach Dauer. Null, wenn der
/// Tag keine Spannen hat (dann bleibt der bisherige Wert).
Future<int?> stepsInWakeWindow(
  LocalRepository repo,
  String dayId,
  String? nextDay,
  WakeWindow window,
) async {
  final dayEnd = localDayEndSec(dayId) ?? ((localDayStartSec(dayId) ?? 0) + 86400);
  var total = 0.0;
  var any = false;
  Future<void> add(String d) async {
    final r = await _softMap(() => repo.getDaySteps(d));
    final spans = r['spans'];
    if (spans is! List) return;
    for (final e in spans) {
      if (e is! Map) continue;
      final a = (e['start_ts'] as num?)?.toInt();
      final b = (e['end_ts'] as num?)?.toInt();
      final n = (e['steps'] as num?)?.toDouble();
      if (a == null || b == null || n == null) continue;
      any = true;
      if (b <= a) {
        if (a >= window.fromSec && a < window.toSec) total += n;
        continue;
      }
      final overlap = math.min(b, window.toSec) - math.max(a, window.fromSec);
      if (overlap > 0) total += n * overlap / (b - a);
    }
  }

  await add(dayId);
  if (nextDay != null && window.toSec > dayEnd) await add(nextDay);
  return any ? total.round() : null;
}

/// Lädt den angeforderten Tag ([selectedDay], oder null für den aktiven Tag)
/// samt Wachfenster, Morgen-Sync-Sofortwerten und über Mitternacht laufender
/// Belastung.
Future<TaktDayLoaded> loadTaktDay(
  LocalRepository repo, {
  String? selectedDay,
  DateTime? now,
  AppLocalizations? l,
}) async {
  final clock = now ?? taktNow();
  final calToday = todayLabel(clock);
  final rawDaysF = repo.availableDays();
  final todayBundleF = repo.getToday();
  final todaySleepF = _softMap(() => repo.getDaySleepV2(calToday));

  final rawDays = await rawDaysF;
  final todayBundle = await todayBundleF;
  final rawTodaySleep = await todaySleepF;

  // W7: Sicherstellen, dass rawTodaySleep wirklich zu calToday gehört und
  // nicht ein Fallback auf den Vortag ist.
  final todayStartSec = localDayStartSec(calToday) ?? 0;
  final wakeTs = (rawTodaySleep['wake_ts'] as num?)?.toInt();
  final sleepDate = rawTodaySleep['date'] as String?;
  final isActuallyTodaySleep = (sleepDate == null || sleepDate == calToday) &&
      (wakeTs == null || wakeTs >= todayStartSec);
  final todaySleep = isActuallyTodaySleep ? rawTodaySleep : const <String, dynamic>{};

  final status = todayBundle['status'];
  final recoveryState =
      status is Map ? status['recovery_state']?.toString() : null;
  final nightInProgress = recoveryState == 'night_in_progress';
  final todayHasSleep = isActuallyTodaySleep &&
      (todaySleep['duration_min'] != null || todaySleep['wake_ts'] != null);

  final calYesterday = dayLabelBefore(calToday, 1);
  final yesterdayHasData =
      calYesterday != null && rawDays.contains(calYesterday);

  final activeDay = resolveActiveTaktDay(
    now: clock,
    availableDays: rawDays,
    todayHasSleep: todayHasSleep,
    nightInProgress: nightInProgress,
    yesterdayHasData: yesterdayHasData,
  );

  final days = <String>[
    if (!rawDays.contains(activeDay)) activeDay,
    ...rawDays,
  ];
  final dayId = (selectedDay != null && days.contains(selectedDay))
      ? selectedDay
      : (selectedDay ?? activeDay);

  final Map<String, dynamic> daySleep = dayId == calToday
      ? todaySleep
      : await _softMap(() => repo.getDaySleepV2(dayId));

  final nextDay = nextDayLabel(dayId);
  final isActiveAfterMidnight = dayId == activeDay && dayId != calToday;
  Map<String, dynamic> nextSleep = const {};
  if (nextDay != null) {
    if (nextDay == calToday) {
      nextSleep = todaySleep;
    } else if (rawDays.contains(nextDay)) {
      nextSleep = await _softMap(() => repo.getDaySleepV2(nextDay));
    }
  }

  final window = buildWakeWindow(
    dayId: dayId,
    sleep: daySleep,
    nextSleep: nextSleep,
    isActiveAfterMidnight: isActiveAfterMidnight,
  );

  HomeData data;
  Metric hrv;
  if (dayId == calToday) {
    data = await HomeData.load(repo, l);
    // Morgen-Sync-Fix: Wenn `getToday()` wegen der 60-Minuten-Frist noch
    // `showing_prior_overnight` meldet, die heutige Nacht aber schon berechnet
    // ist, übernehmen wir Schlaf, Erholung und Ruhepuls sofort aus `calToday`.
    if (todayHasSleep &&
        !nightInProgress &&
        (data.sleepMin.value == null || data.readiness.value == null)) {
      final overview = await _softMap(() => repo.getDayOverview(calToday));
      final freshReadiness = metricOf(overview['readiness']);
      final freshRhr = metricOf(overview['resting_hr']);
      final freshSleep = metricOf(todaySleep['duration_min']);
      data = HomeData(
        name: data.name,
        dayId: calToday,
        readiness: freshReadiness.value != null ? freshReadiness : data.readiness,
        absentDiag: freshReadiness.value != null ? null : data.absentDiag,
        recoveryState: 'final',
        rhr: freshRhr.value != null ? freshRhr : data.rhr,
        strain: data.strain,
        steps: data.steps,
        calories: data.calories,
        caloriesTotal: data.caloriesTotal,
        sleepMin: freshSleep.value != null ? freshSleep : data.sleepMin,
        sleepNeedMin: data.sleepNeedMin.value != null
            ? data.sleepNeedMin
            : metricOf(todaySleep['need_min']),
        stepGoal: data.stepGoal,
        illnessState: data.illnessState,
        illnessDay: data.illnessDay,
        illnessZ: data.illnessZ,
      );
    }
    final hrvRaw = todayBundle['hrv'];
    final rmssd = hrvRaw is Map ? hrvRaw['rmssd'] as num? : null;
    final showingPrior =
        status is Map && status['showing_prior_overnight'] == true;
    if (rmssd != null && hrvRaw is Map && !showingPrior) {
      hrv = overnightMetric(
        todayBundle,
        {...hrvRaw.cast<String, dynamic>(), 'value': rmssd, 'unit': 'ms'},
        l,
      );
    } else if (todayHasSleep && !nightInProgress) {
      hrv = await _hrvForDay(
        repo,
        calToday,
        todayBundle: todayBundle,
        allowTodayBundle: true,
      );
    } else {
      hrv = Metric.empty;
    }
  } else {
    data = await HomeData.loadForDay(repo, dayId, l);
    hrv = await _hrvForDay(repo, dayId);
  }

  final dayStart = localDayStartSec(dayId) ?? 0;
  final dayEnd = localDayEndSec(dayId) ?? (dayStart + 86400);
  final needsWakeAdjust = (window.wakeSec != null && window.wakeSec! > dayStart) ||
      window.toSec != dayEnd ||
      dayId != calToday;

  if (!needsWakeAdjust) {
    return TaktDayLoaded(
      dayId: dayId,
      activeDayId: activeDay,
      availableDays: days,
      window: window,
      data: data,
      hrv: hrv,
      strainPeak: null,
      strainCurve: const [],
      todayHasSleep: todayHasSleep,
      nightInProgress: nightInProgress,
    );
  }

  // Strain-Kurve des Tages und etwaige Wachminuten nach Mitternacht.
  final dayStrainMap = await _softMap(() => repo.getDayStrain(dayId));
  final dayPts = _extractCurvePoints(dayStrainMap, dayId);

  List<(int, double)> nextPts = const [];
  double? nextInterimStrain;
  int extraSteps = 0;
  int extraCal = 0;
  if (nextDay != null && window.toSec > dayEnd) {
    final nextStrainMap = await _softMap(() => repo.getDayStrain(nextDay));
    nextPts = _extractCurvePoints(nextStrainMap, nextDay);
    if (isActiveAfterMidnight) {
      final daily = todayBundle['daily'];
      final dStrain = daily is Map ? metricOf(daily['strain']).value : null;
      nextInterimStrain =
          dStrain?.toDouble() ?? (nextStrainMap['strain'] as num?)?.toDouble();
      final dSteps = daily is Map ? metricOf(daily['steps']).value : null;
      extraSteps = (dSteps ?? (nextStrainMap['steps'] as num?) ?? 0).round();
      final dCal = daily is Map ? metricOf(daily['calories']).value : null;
      extraCal = (dCal ?? (nextStrainMap['calories'] as num?) ?? 0).round();
    }
  }

  final adjusted = adjustWakeStrain(
    dayId: dayId,
    rawStrain: data.strain.value?.toDouble(),
    dayPts: dayPts,
    window: window,
    nextPts: nextPts,
    nextInterimStrain: nextInterimStrain,
  );

  // W15: Außer am Tag nach Mitternacht (dort läuft er ohnehin bis zum
  // Einschlafen) zählen nur die Schritte im Wachfenster.
  final windowSteps = isActiveAfterMidnight
      ? null
      : await stepsInWakeWindow(repo, dayId, nextDay, window);
  final newSteps = windowSteps != null
      ? Metric.parse({'value': windowSteps, 'unit': 'steps'})
      : extraSteps > 0
      ? Metric.parse(
          {'value': (data.steps.value?.round() ?? 0) + extraSteps, 'unit': 'steps'})
      : data.steps;
  final newCal = extraCal > 0
      ? Metric.parse(
          {'value': (data.calories.value?.round() ?? 0) + extraCal, 'unit': 'kcal'})
      : data.calories;
  final newStrain = adjusted.strain != null
      ? Metric.parse({'value': adjusted.strain, 'unit': ''})
      : data.strain;

  data = HomeData(
    name: data.name,
    dayId: data.dayId ?? dayId,
    heldOverNight: data.heldOverNight,
    illnessState: data.illnessState,
    illnessDay: data.illnessDay,
    illnessZ: data.illnessZ,
    readiness: data.readiness,
    absentDiag: data.absentDiag,
    recoveryState: data.recoveryState,
    readinessUpdate: data.readinessUpdate,
    drivers: data.drivers,
    strain: newStrain,
    sleepMin: data.sleepMin,
    rhr: data.rhr,
    steps: newSteps,
    calories: newCal,
    caloriesTotal: data.caloriesTotal,
    stepGoal: data.stepGoal == 0 ? _kDefaultStepGoal : data.stepGoal,
    sleepNeedMin: data.sleepNeedMin,
    bedtime: data.bedtime,
    strainTarget: data.strainTarget,
    insightsStale: data.insightsStale,
  );

  return TaktDayLoaded(
    dayId: dayId,
    activeDayId: activeDay,
    availableDays: days,
    window: window,
    data: data,
    hrv: hrv,
    strainPeak: adjusted.peak,
    strainCurve: adjusted.curve,
    todayHasSleep: todayHasSleep,
    nightInProgress: nightInProgress,
  );
}
