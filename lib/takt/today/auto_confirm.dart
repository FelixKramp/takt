// Erkannte Workouts ohne Klick. Gespeichert wird erst, wenn die Daten klar über
// ihr Ende hinausreichen: Ein gespeichertes Workout wächst nicht mehr mit, ein
// laufendes Training würde sonst abgeschnitten. Bis dahin steht es als offene
// Erkennung in der Liste.
import '../../models/activity_suggestion.dart';

const kSettleSeconds = 30 * 60;

bool isSettled(ActivitySuggestion s, DateTime? dataThrough) {
  if (dataThrough == null) return false;
  return dataThrough.millisecondsSinceEpoch ~/ 1000 - s.endTs >= kSettleSeconds;
}

/// Bestätigt abgeschlossene Workouts von heute und gibt zurück, was offen bleibt.
/// Ältere Vorschläge, etwa aus einem Import, und Nickerchen bleiben unberührt.
Future<List<ActivitySuggestion>> autoConfirmWorkouts({
  required Future<List<ActivitySuggestion>> Function() pending,
  required Future<void> Function(ActivitySuggestion) confirm,
  required DateTime? dataThrough,
  required DateTime now,
}) async {
  final midnight =
      DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 1000;
  final left = <ActivitySuggestion>[];
  for (final s in await pending()) {
    if (s.kind != ActivityKind.workout || s.startTs < midnight) continue;
    if (!isSettled(s, dataThrough)) {
      left.add(s);
      continue;
    }
    try {
      await confirm(s);
    } catch (_) {
      left.add(s);
    }
  }
  return left;
}
