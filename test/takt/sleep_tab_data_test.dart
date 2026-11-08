import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/takt/sleep/night_log.dart';
import 'package:openstrap_edge/takt/sleep/sleep_score.dart';
import 'package:openstrap_edge/takt/sleep/sleep_tab_data.dart';
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';

int ts(int y, int m, int d, int h, int min) =>
    DateTime(y, m, d, h, min).millisecondsSinceEpoch ~/ 1000;
int noon(String day) => DateTime.parse('$day 12:00:00').millisecondsSinceEpoch ~/ 1000;

Map<String, dynamic> chart(Map<String, num> byDay) => {
      'points': [
        for (final e in byDay.entries) {'t': noon(e.key), 'v': e.value},
      ],
    };

final night = <String, dynamic>{
  'has_sleep': true,
  'duration_min': 432,
  'in_bed_min': 485,
  'awake_min': 53,
  'efficiency': 0.89,
  'onset_ts': ts(2026, 11, 7, 23, 48),
  'wake_ts': ts(2026, 11, 8, 7, 6),
  'hypnogram': [
    {'t': ts(2026, 11, 7, 23, 48), 'stage': 'wake'},
    {'t': ts(2026, 11, 7, 23, 58), 'stage': 'light'},
    {'t': ts(2026, 11, 8, 3, 0), 'stage': 'wake'},
    {'t': ts(2026, 11, 8, 3, 10), 'stage': 'deep'},
    {'t': ts(2026, 11, 8, 7, 6), 'stage': 'light'},
  ],
};

final insights = <String, dynamic>{
  'sleep_coach': {
    'need': {'value': {'need_sec': 510 * 60}},
    'strain_bonus_min': 30,
    'nap_credit_min': 0,
    'bedtime': {'value': {'bedtime_min_of_day': 1395}},
    'wake': {'value': {'wake_min_of_day': 420}},
  },
  'regularity': {
    'value': {
      'sri': 74,
      'pairs': [
        {'date': '2026-11-08', 'sri': 76},
        {'date': '2026-11-07', 'sri': 70},
      ],
    },
  },
};

TaktSleepView build({Map<String, NightNote> log = const {}, Map<String, dynamic>? n}) =>
    buildSleepView(
      d: SleepData(day: '2026-11-08', night: n ?? night, awakenings: 9),
      insights: insights,
      sleepChart: chart({'2026-11-07': 400, '2026-11-06': 470, '2026-11-02': 300}),
      effChart: chart({'2026-11-07': 90, '2026-11-06': 85, '2026-11-02': 80}),
      windows: [
        {'date': '2026-11-07', 'onset_ts': ts(2026, 11, 6, 23, 30), 'wake_ts': ts(2026, 11, 7, 6, 50)},
      ],
      log: log,
    );

void main() {
  test('C1/C4: letzte Nacht mit Bedarf aus der Notiz vom Vortag', () {
    final v = build(log: {'2026-11-07': const NightNote(needMin: 480, debtMin: 18, strainMin: 12)});
    expect(v.sleptMin, 432);
    expect(v.needMin, 480);
    expect(v.score.score, 83, reason: '90 · 76 · 76');
    expect(v.score.band, ScoreBand.okay);
    expect(v.needParts?.baseMin, 450);
  });

  test('C1: ohne Notiz zählt der heutige Bedarf ohne die heutige Belastung', () {
    final v = build();
    expect(v.needMin, 480, reason: '510 − 30');
    expect(v.needParts, isNull);
  });

  test('C5: sieben Nächte, älteste zuerst, Lücken bleiben', () {
    final v = build();
    expect(v.nights.map((n) => n.day), [
      '2026-11-02', '2026-11-03', '2026-11-04', '2026-11-05', '2026-11-06', '2026-11-07', '2026-11-08',
    ]);
    expect(v.nights.last.score, v.score.score);
    expect(v.nights[3].score, isNull, reason: 'keine Daten am 5.11.');
    expect(v.nights[5].score, isNotNull);
  });

  test('C7: Regelmäßigkeit pro Nacht, Zeiten ab 20 Uhr, Empfehlung aus der Notiz', () {
    final v = build(log: {'2026-11-06': const NightNote(needMin: 480, bedRec: 1380, wakeRec: 420)});
    expect(v.regularity, 76);
    expect(v.week, hasLength(6));
    final fri = v.week.firstWhere((w) => w.day == '2026-11-07');
    expect(fri.bed, 210, reason: '23:30 ist 3,5 Std nach 20 Uhr');
    expect(fri.wake, 650);
    expect(fri.bedRec, 180);
    expect(fri.wakeRec, 660);
    final sat = v.week.last;
    expect(sat.bed, 228);
    expect(sat.bedRec, isNull, reason: 'keine Notiz vom 7.11. mit Empfehlung');
    expect(v.bedRecTonight, 1395);
    expect(v.wakeRecTonight, 420);
  });

  test('C8: Effizienz, Wachphasen aus dem Hypnogramm, Aufwachereignisse', () {
    final v = build();
    expect(v.effPct, closeTo(89, 0.001));
    expect(v.awakenings, 9);
    expect(v.awake, hasLength(2));
    expect(v.awake.first.from, 0);
    expect(v.asleep, isNotEmpty);
    for (final r in [...v.asleep, ...v.awake]) {
      expect(r.from, inInclusiveRange(0, 1));
      expect(r.to, inInclusiveRange(0, 1));
    }
  });

  test('C10: korrigierte Nacht, der Score rechnet mit den neuen Werten', () {
    final before = build().score.score!;
    final after = build(n: {...night, 'duration_min': 300}).score.score!;
    expect(after, lessThan(before));
  });

  test('C2: ohne Nacht kein Score, aber die Empfehlung für heute', () {
    final v = buildSleepView(
      d: const SleepData(),
      insights: insights,
      sleepChart: null,
      effChart: null,
      windows: const [],
      log: const {},
    );
    expect(v.hasNight, isFalse);
    expect(v.score.score, isNull);
    expect(v.bedRecTonight, 1395);
  });
}
