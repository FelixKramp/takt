import 'package:flutter/foundation.dart';

/// Ob der Heute-Tab gerade vorne ist. Der Shell hält Tabs am Leben, sie sehen
/// also nicht selbst, wann sie verdeckt sind.
final ValueNotifier<bool> taktTodayVisible = ValueNotifier(true);

const kBackToTodayAfter = Duration(minutes: 5);

/// Android hält die App oft am Leben, „Öffnen" ist dann eine Rückkehr aus dem
/// Hintergrund. Nach kurzem Wechsel bleibt man, wo man war, ein laufendes
/// Workout wird nie verlassen.
bool shouldReturnToToday({
  required DateTime? leftAt,
  required DateTime now,
  required bool workoutLive,
}) =>
    !workoutLive && leftAt != null && now.difference(leftAt) >= kBackToTodayAfter;
