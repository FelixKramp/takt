// Erkannte Workouts ohne Klick. Gespeichert wird erst, wenn das Training sicher
// vorbei ist: Eine gespeicherte Erkennung wächst nicht mehr mit, und eine
// spätere, längere Erkennung desselben Trainings würde verworfen. Bis dahin
// steht es als offene Erkennung in der Liste.
import '../../models/activity_suggestion.dart';

const kSettleSeconds = 30 * 60;

/// Wie weit zurück automatisch gespeichert wird. Ein Training vor Mitternacht
/// soll nicht liegen bleiben, alte Vorschläge aus einem Import aber schon.
const kAutoConfirmWindow = Duration(hours: 36);

/// Sicher vorbei heißt: Die Daten reichen 30 Minuten über das Ende hinaus, und
/// die Berechnung hat diese Daten schon gesehen. Ohne die zweite Bedingung
/// würde ein Sync nach einer Datenlücke das Training bei einer alten, kurzen
/// Erkennung einfrieren.
///
/// [sameDay] sagt, ob [derivedAt] zum laufenden Tag gehört. Der wird immer neu
/// gerechnet und muss bis zum Datenstand reichen. Ein vergangener Tag bleibt
/// stehen, seine Rechnung muss nur klar nach dem Trainingsende liegen.
bool isSettled(
  ActivitySuggestion s, {
  required DateTime? dataThrough,
  required DateTime? derivedAt,
  required bool sameDay,
  required bool busy,
}) {
  if (busy || dataThrough == null || derivedAt == null) return false;
  final settledAt = s.endTs + kSettleSeconds;
  if (dataThrough.millisecondsSinceEpoch ~/ 1000 < settledAt) return false;
  return sameDay
      ? !derivedAt.isBefore(dataThrough)
      : derivedAt.millisecondsSinceEpoch ~/ 1000 >= settledAt;
}

/// Speichert abgeschlossene Workouts und gibt zurück, was offen bleibt.
/// Nickerchen laufen weiter über den bisherigen Ablauf.
Future<List<ActivitySuggestion>> autoConfirmWorkouts({
  required Future<List<ActivitySuggestion>> Function() pending,
  required Future<void> Function(ActivitySuggestion) confirm,
  required DateTime? dataThrough,
  required Future<DateTime?> Function(ActivitySuggestion) derivedAt,
  required bool busy,
  required DateTime now,
}) async {
  final oldest = now.subtract(kAutoConfirmWindow).millisecondsSinceEpoch ~/ 1000;
  final left = <ActivitySuggestion>[];
  for (final s in await pending()) {
    if (s.kind != ActivityKind.workout || s.startTs < oldest) continue;
    final end = DateTime.fromMillisecondsSinceEpoch(s.endTs * 1000);
    final sameDay =
        end.year == now.year && end.month == now.month && end.day == now.day;
    if (!isSettled(s,
        dataThrough: dataThrough,
        derivedAt: await derivedAt(s),
        sameDay: sameDay,
        busy: busy)) {
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
