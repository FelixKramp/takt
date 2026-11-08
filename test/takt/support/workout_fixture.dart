// Ein Handballtraining wie im Gerätetest vom 8.11.: 55 Minuten, Ø 146, max 197.
import 'package:openstrap_edge/ui2/activity/catalogue.dart';
import 'package:openstrap_edge/ui2/activity/summary.dart';

ActivityResult handball({String? id = 'w1'}) {
  final hr = <double?>[
    for (var i = 0; i < 55; i++)
      i < 3
          ? 118.0 + i * 15
          : i < 26
              ? 175.0 + (i % 6) * 3
              : 110.0 + (i % 7) * 2,
  ];
  return ActivityResult(
    activityByName('handball')!,
    start: DateTime(2026, 11, 8, 16, 57),
    duration: const Duration(minutes: 55),
    sessionId: id,
    avgHr: 146,
    maxHr: 197,
    hrr60: 16,
    calories: 718,
    strain: 11.0,
    hr: hr,
    zoneMinutes: const [11, 9, 8, 14, 13],
  );
}
