// Eine Liste für alle Aktivitäten des Tages. Reine Logik.
import '../../models/activity_suggestion.dart';

const kDetectedPrefix = 'suggestion:';
const kMaxShownActivities = 5;

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.startTs,
    required this.type,
    required this.detected,
    this.endTs,
    this.durationMin,
    this.avgHr,
    this.strain,
    this.suggestion,
  });

  final String id;
  final int startTs;
  final int? endTs;
  final String type;
  final bool detected;
  final int? durationMin;
  final int? avgHr;
  final double? strain;

  /// Gesetzt, wenn das automatische Bestätigen gescheitert ist.
  final ActivitySuggestion? suggestion;
}

/// Heutige, abgeschlossene Workouts und noch offene Erkennungen, neueste zuerst.
List<ActivityItem> todayActivities(
  List<Map<String, dynamic>> workouts,
  DateTime day, {
  List<ActivitySuggestion> pending = const [],
}) {
  final from = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch ~/ 1000;
  final to = DateTime(day.year, day.month, day.day + 1).millisecondsSinceEpoch ~/ 1000;
  bool isToday(int ts) => ts >= from && ts < to;

  final items = <ActivityItem>[
    for (final w in workouts)
      if (w['status'] != 'live' &&
          w['start_ts'] is int &&
          isToday(w['start_ts'] as int))
        ActivityItem(
          id: '${w['id']}',
          startTs: w['start_ts'] as int,
          endTs: w['end_ts'] as int?,
          type: (w['type'] as String?) ?? 'other',
          detected: '${w['id']}'.startsWith(kDetectedPrefix),
          durationMin: w['duration_min'] as int?,
          avgHr: (w['avg_hr'] as num?)?.toInt(),
          strain: (w['strain'] as num?)?.toDouble(),
        ),
    for (final s in pending)
      if (s.kind == ActivityKind.workout && isToday(s.startTs))
        ActivityItem(
          id: '$kDetectedPrefix${s.id}',
          startTs: s.startTs,
          endTs: s.endTs,
          type: s.sport ?? 'other',
          detected: true,
          durationMin: s.durationMin,
          avgHr: (s.details['avg_bpm'] as num?)?.round(),
          suggestion: s,
        ),
  ];
  items.sort((a, b) => b.startTs.compareTo(a.startTs));
  return items;
}

({List<ActivityItem> shown, int hidden}) visibleActivities(
  List<ActivityItem> items, {
  bool expanded = false,
}) {
  if (expanded || items.length <= kMaxShownActivities) {
    return (shown: items, hidden: 0);
  }
  return (
    shown: items.sublist(0, kMaxShownActivities),
    hidden: items.length - kMaxShownActivities,
  );
}

/// Für Sportarten, die der Katalog nicht kennt: aus `table_tennis` wird
/// „Table tennis".
String readableType(String type) {
  final t = type.replaceAll('_', ' ').trim();
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}
