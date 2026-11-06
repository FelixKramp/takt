// Erkannte Workouts ohne Klick: Bestätigt zählen sie mit Strain und Verlauf.
import '../../models/activity_suggestion.dart';

/// Bestätigt alle offenen Workouts und gibt zurück, was offen geblieben ist.
/// Nickerchen laufen weiter über den bisherigen Ablauf.
Future<List<ActivitySuggestion>> autoConfirmWorkouts({
  required Future<List<ActivitySuggestion>> Function() pending,
  required Future<void> Function(ActivitySuggestion) confirm,
}) async {
  final left = <ActivitySuggestion>[];
  for (final s in await pending()) {
    if (s.kind != ActivityKind.workout) continue;
    try {
      await confirm(s);
    } catch (_) {
      left.add(s);
    }
  }
  return left;
}
