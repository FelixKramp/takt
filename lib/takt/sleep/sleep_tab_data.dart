// Feature 03: alles, was der Takt-Kopf des Schlaf-Tabs zeigt, als reines
// Modell. [buildSleepView] rechnet ohne Datenbank (testbar), [loadTaktSleep]
// holt die Werte aus dem Repository und schreibt die Tagesnotiz.

import '../../data/local_repository.dart';
import '../../ui2/screens/home_screen.dart' show envValue, pointsOf;
import '../../ui2/screens/sleep_detail.dart' show SleepData;
import '../../ui2/charts.dart' show SleepStage;
import 'night_log.dart';
import 'sleep_score.dart';

/// Eine Nacht in der Siebener-Reihe.
class NightBar {
  const NightBar(this.day, this.score);
  final String day;
  final int? score;
}

/// Eine Nacht im Regelmäßigkeitsdiagramm. Zeiten in Minuten ab 20:00 des
/// Vorabends, damit eine Nacht als ein Balken von oben nach unten läuft.
class WeekNight {
  const WeekNight(this.day, {this.bed, this.wake, this.bedRec, this.wakeRec});
  final String day;
  final int? bed, wake, bedRec, wakeRec;
}

/// Ein Abschnitt der Nacht, als Anteil 0…1 des Fensters im Bett.
class Run {
  const Run(this.from, this.to);
  final double from, to;
}

class TaktSleepView {
  const TaktSleepView({
    this.day,
    this.score = const NightScore(reason: NoScore.noNight),
    this.sleptMin,
    this.needMin,
    this.needParts,
    this.inBedMin,
    this.awakeMin,
    this.onsetTs,
    this.wakeTs,
    this.effPct,
    this.awakenings,
    this.regularity,
    this.nights = const [],
    this.week = const [],
    this.bedRecTonight,
    this.wakeRecTonight,
    this.asleep = const [],
    this.awake = const [],
  });

  /// Der Tag, an dessen Morgen die Nacht endete. `null`: keine Nacht.
  final String? day;
  final NightScore score;
  final int? sleptMin, needMin, inBedMin, awakeMin, onsetTs, wakeTs;

  /// Teile des Bedarfs, wenn die Notiz vom Vortag da ist.
  final NightNote? needParts;
  final double? effPct, awakenings;

  /// Rohwert der Regelmäßigkeit (SRI), zur Anzeige.
  final int? regularity;
  final List<NightBar> nights;
  final List<WeekNight> week;
  final int? bedRecTonight, wakeRecTonight;
  final List<Run> asleep, awake;

  bool get hasNight => day != null && sleptMin != null;
}

int? _noon(String day) {
  final d = DateTime.tryParse('$day 12:00:00');
  return d == null ? null : d.millisecondsSinceEpoch ~/ 1000;
}

double? _at(Object? chart, String day) {
  final noon = _noon(day);
  if (noon == null) return null;
  for (final p in pointsOf(chart)) {
    if (p.t == noon) return p.v.toDouble();
  }
  return null;
}

/// Minuten ab 20:00 des Vorabends von [day] für den Zeitpunkt [ts].
int? _sinceEvening(String day, int? ts) {
  if (ts == null) return null;
  final d = DateTime.parse(day);
  final evening = DateTime(d.year, d.month, d.day - 1, 20);
  return DateTime.fromMillisecondsSinceEpoch(ts * 1000).difference(evening).inMinutes;
}

/// Eine Uhrzeit (Minuten nach Mitternacht) auf derselben Achse.
int? _clockSinceEvening(int? minOfDay) {
  if (minOfDay == null) return null;
  return minOfDay >= 20 * 60 ? minOfDay - 20 * 60 : minOfDay + 4 * 60;
}

Map<String, num> _sriByDate(Object? regularityEnv) {
  final v = envValue(regularityEnv);
  final out = <String, num>{};
  for (final p in (v?['pairs'] as List?) ?? const []) {
    if (p is Map && p['date'] != null && p['sri'] is num) {
      out[p['date'].toString()] = p['sri'] as num;
    }
  }
  return out;
}

List<Run> _runs(List<SleepStage?> cols, bool Function(SleepStage s) keep) {
  final out = <Run>[];
  int? start;
  for (var i = 0; i <= cols.length; i++) {
    final s = i < cols.length ? cols[i] : null;
    final on = s != null && keep(s);
    if (on && start == null) start = i;
    if (!on && start != null) {
      out.add(Run(start / cols.length, i / cols.length));
      start = null;
    }
  }
  return out;
}

int? _round(num? v) => v?.round();

TaktSleepView buildSleepView({
  required SleepData d,
  required Map<String, dynamic> insights,
  required Object? sleepChart,
  required Object? effChart,
  required List<Map<String, dynamic>> windows,
  required Map<String, NightNote> log,
}) {
  final day = d.day;
  final coach = insights['sleep_coach'];
  final coachMap = coach is Map ? coach : const {};
  final needSec = envValue(coachMap['need'])?['need_sec'] as num?;
  final needNow = needSec == null ? null : (needSec / 60).round();
  final strainNow = _round(coachMap['strain_bonus_min'] as num?);
  final napNow = _round(coachMap['nap_credit_min'] as num?);
  final bedTonight = _round(envValue(coachMap['bedtime'])?['bedtime_min_of_day'] as num?);
  final wakeTonight = _round(envValue(coachMap['wake'])?['wake_min_of_day'] as num?);
  final sriAll = envValue(insights['regularity'])?['sri'] as num?;
  final sriBy = _sriByDate(insights['regularity']);

  if (day == null) {
    return TaktSleepView(bedRecTonight: bedTonight, wakeRecTonight: wakeTonight);
  }
  final n = d.night;
  final slept = _round(n['duration_min'] as num?);
  final eff = (n['efficiency'] as num?) == null ? null : (n['efficiency'] as num) * 100;

  NightScore scoreFor(String x, {num? dur, num? effPct}) {
    final need = needForNight(x, log, needNow: needNow, strainNowMin: strainNow, napNowMin: napNow);
    return scoreNight(
      durationMin: dur ?? _at(sleepChart, x),
      needMin: need.needMin,
      efficiencyPct: effPct ?? _at(effChart, x),
      regularity: sriBy[x] ?? sriAll,
    );
  }

  final need = needForNight(day, log, needNow: needNow, strainNowMin: strainNow, napNowMin: napNow);
  final score = scoreFor(day, dur: slept, effPct: eff);

  final days = <String>[day];
  while (days.length < 7) {
    days.insert(0, prevDay(days.first));
  }
  final nights = [
    for (final x in days)
      NightBar(x, x == day ? score.score : scoreFor(x).score),
  ];

  final byDate = {for (final w in windows) w['date']?.toString(): w};
  final week = [
    for (final x in days.skip(1))
      WeekNight(
        x,
        bed: _sinceEvening(x, x == day ? n['onset_ts'] as int? : byDate[x]?['onset_ts'] as int?),
        wake: _sinceEvening(x, x == day ? n['wake_ts'] as int? : byDate[x]?['wake_ts'] as int?),
        bedRec: _clockSinceEvening(log[prevDay(x)]?.bedRec),
        wakeRec: _clockSinceEvening(log[prevDay(x)]?.wakeRec),
      ),
  ];

  final cols = SleepData.stagesOf(n.cast<String, Object?>());
  return TaktSleepView(
    day: day,
    score: score,
    sleptMin: slept,
    needMin: need.needMin,
    needParts: need.note,
    inBedMin: _round(n['in_bed_min'] as num?),
    awakeMin: _round(n['awake_min'] as num?),
    onsetTs: n['onset_ts'] as int?,
    wakeTs: n['wake_ts'] as int?,
    effPct: eff?.toDouble(),
    awakenings: d.awakenings,
    regularity: _round(sriBy[day] ?? sriAll),
    nights: nights,
    week: week,
    bedRecTonight: bedTonight,
    wakeRecTonight: wakeTonight,
    asleep: _runs(cols, (s) => s != SleepStage.awake),
    awake: _runs(cols, (s) => s == SleepStage.awake),
  );
}

/// Liest alles für den Takt-Kopf und schreibt die heutige Tagesnotiz.
Future<TaktSleepView> loadTaktSleep(LocalRepository repo, {String? want}) async {
  final d = await SleepData.load(repo, want: want);
  final insights = await repo.getInsights();
  final coach = insights['sleep_coach'];
  final c = coach is Map ? coach : const {};
  final needSec = envValue(c['need'])?['need_sec'] as num?;
  final debtH = envValue(insights['sleep_debt'])?['debt_hours'] as num?;
  if (needSec != null) {
    TaktNightLog.record(
      dayLabel(DateTime.now()),
      NightNote(
        needMin: (needSec / 60).round(),
        debtMin: debtH == null ? null : (debtH * 60).round(),
        strainMin: (c['strain_bonus_min'] as num?)?.round(),
        napMin: (c['nap_credit_min'] as num?)?.round(),
        bedRec: (envValue(c['bedtime'])?['bedtime_min_of_day'] as num?)?.round(),
        wakeRec: (envValue(c['wake'])?['wake_min_of_day'] as num?)?.round(),
      ),
    );
  }
  return buildSleepView(
    d: d,
    insights: insights,
    sleepChart: await repo.getChart('sleep'),
    effChart: await repo.getChart('efficiency'),
    windows: await repo.sleepWindows(days: 8),
    log: TaktNightLog.read(),
  );
}
