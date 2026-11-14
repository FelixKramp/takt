import 'journal_config.dart';

class MorningSheetDecision {
  const MorningSheetDecision({
    required this.shouldShow,
    this.yesterdayAnswers = const {},
    this.todayAnswers = const {},
  });

  final bool shouldShow;
  final Map<String, double> yesterdayAnswers;
  final Map<String, double> todayAnswers;
}

/// Ab dieser Stunde kommt das Blatt beim ersten Öffnen am Tag, ohne auf die
/// berechnete Nacht zu warten (Änderung 2026-11-14, wie bei WHOOP).
const int kMorningSheetFromHour = 5;

/// Prüft, ob das Morgenblatt jetzt automatisch aufpoppen soll (J1, J7, J8, J21, J22, J25).
///
/// Änderung 2026-11-14: Vorher kam das Blatt erst, wenn der Kalendertag der
/// aktive Tag war. Ohne berechnete Nacht bleibt der Vortag aber bis 12 Uhr
/// aktiv, das Blatt kam dann morgens gar nicht. Jetzt zählt nur die Uhr:
/// ab [kMorningSheetFromHour] Uhr beim ersten Öffnen, davor nur mit fertiger
/// Nacht. [activeDayId] bleibt für Aufrufer, entscheidet aber nichts mehr.
MorningSheetDecision checkMorningSheetRule({
  required DateTime now,
  String? activeDayId,
  required String calToday,
  bool todayHasSleep = false,
  bool nightInProgress = false,
  required String? lastDismissedOrCompletedDay,
  required List<JournalQuestion> sheetQuestionsYesterday,
  required List<JournalQuestion> sheetQuestionsToday,
  required Map<String, double> existingYesterdayAnswers,
  required Map<String, double> existingTodayAnswers,
}) {
  // J1, J21, J22: Ab 5 Uhr sofort, davor (z. B. 01:00, noch wach) nur, wenn
  // die Nacht schon fertig berechnet ist.
  final sleepSettled = todayHasSleep && !nightInProgress;
  if (now.hour < kMorningSheetFromHour && !sleepSettled) {
    return const MorningSheetDecision(shouldShow: false);
  }

  // J7 & J25: Für diesen Tag bereits beantwortet oder weggewischt.
  if (lastDismissedOrCompletedDay == calToday) {
    return const MorningSheetDecision(shouldShow: false);
  }

  // J8: Prüfen, ob alle Fragen des Blatts für diesen Tag im Journal bereits
  // beantwortet wurden.
  final yAnswered = sheetQuestionsYesterday.every(
    (q) => existingYesterdayAnswers.containsKey(q.key),
  );
  final tAnswered = sheetQuestionsToday.every(
    (q) => existingTodayAnswers.containsKey(q.key),
  );

  if (sheetQuestionsYesterday.isNotEmpty || sheetQuestionsToday.isNotEmpty) {
    if (yAnswered && tAnswered) {
      return const MorningSheetDecision(shouldShow: false);
    }
  }

  return MorningSheetDecision(
    shouldShow: true,
    yesterdayAnswers: Map.unmodifiable(existingYesterdayAnswers),
    todayAnswers: Map.unmodifiable(existingTodayAnswers),
  );
}
