// Eine vollständige Nacht für Darstellungstests und Bildschirmfotos: Phasen,
// Verlauf, Signale über die Nacht und genug Vergleichsnächte.
import 'dart:math' as math;

import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';

final onset = DateTime(2026, 11, 7, 23, 48).millisecondsSinceEpoch ~/ 1000;
const nightMin = 438;

/// Phasenläufe in Minuten ab Einschlafen, wie im Board „Die Nacht“.
const runs = [
  ('light', 0), ('deep', 25), ('light', 75), ('rem', 95), ('awake', 115),
  ('light', 118), ('deep', 150), ('light', 185), ('rem', 215), ('light', 245),
  ('awake', 280), ('light', 285), ('deep', 310), ('rem', 325), ('light', 365),
  ('rem', 395), ('awake', 425),
];

List<Map<String, Object>> lane(double base, double amp, double f) => [
      for (var m = 0; m <= nightMin; m += 5)
        {
          't': onset + m * 60,
          'v': base + math.sin(m / f) * amp + math.sin(m / 23) * amp * .3,
        },
    ];

Map<String, dynamic> night({bool elevated = true}) => {
      'has_sleep': true,
      'duration_min': 432,
      'in_bed_min': 485,
      'awake_min': 53,
      'efficiency': .89,
      'onset_ts': onset,
      'wake_ts': onset + nightMin * 60,
      'light_min': 220,
      'deep_min': 90,
      'rem_min': 95,
      'hypnogram': [
        for (final r in runs) {'t': onset + r.$2 * 60, 'stage': r.$1},
        {'t': onset + nightMin * 60, 'stage': 'awake'},
      ],
      'nocturnal': {
        'sleeping_hr_avg': 54,
        'sleeping_hr_min': 47,
        'vs_baseline_bpm': elevated ? 4.2 : 0.3,
        'elevated': elevated,
      },
      'resp': {'value': 14.2},
    };

SleepData sleepData({bool elevated = true}) => SleepData(
      day: '2026-11-08',
      latestDay: '2026-11-08',
      days: const ['2026-11-06', '2026-11-07', '2026-11-08'],
      night: night(elevated: elevated),
      timeline: {
        'hr': lane(54, 5, 40),
        'hrv': lane(68, 12, 31),
        'resp': lane(14.2, 1.2, 55),
        'skin_temp': lane(0, .4, 90),
      },
      tstHistory: [for (var i = 0; i < 20; i++) 440 + (i % 5) * 9],
      deepHistory: [for (var i = 0; i < 20; i++) 80 + (i % 4) * 5],
      effHistory: [for (var i = 0; i < 20; i++) 90 + (i % 3).toDouble()],
      onsetHistory: [for (var i = 0; i < 20; i++) 23 * 60 + (i % 4) * 8],
      awakenings: 9,
    );
