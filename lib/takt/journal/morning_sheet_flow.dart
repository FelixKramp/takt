import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../data/day_label.dart' show dayLabelBefore, todayLabel;
import '../../data/db.dart' show LocalDb;
import '../../data/journal_fields.dart' show JournalMetricValue;
import '../../data/local_repository.dart' show LocalRepository;
import '../../ui2/screens/home_screen.dart' show repoOf;
import '../../ui2/screens/log_workout.dart' show bumpInsights;
import '../now.dart';
import 'journal_config.dart';
import 'morning_sheet.dart';

/// Merkt sich, für welchen Tag das Blatt zuletzt beantwortet oder weggewischt
/// wurde (J7, J25). Der Schlüssel steht an genau einer Stelle.
const String kJournalSheetLastKey = 'takt.journal.sheet.last';

/// Zeigt das Morgenblatt und schreibt die Antworten. Eine Stelle für den
/// automatischen Start auf Heute und für „Heute eintragen“ im Journal-Tab,
/// damit beide dasselbe Blatt zeigen und gleich speichern.
Future<void> presentMorningSheet(
  BuildContext context, {
  required JournalConfig config,
  required String calYesterday,
  required String calToday,
  required Map<String, double> initialYesterday,
  required Map<String, double> initialToday,
  VoidCallback? onOpenFullJournal,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return;
  final yKeys = {for (final q in config.sheetQuestionsYesterday) q.key};
  final tKeys = {for (final q in config.sheetQuestionsToday) q.key};

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => MorningSheet(
      config: config,
      calYesterday: calYesterday,
      calToday: calToday,
      initialYesterdayAnswers: initialYesterday,
      initialTodayAnswers: initialToday,
      onSave: (yesterdayAnswers, todayAnswers) async {
        final repo = context.mounted ? repoOf(context) : null;
        await _writeDay(repo, calYesterday, yKeys, yesterdayAnswers);
        await _writeDay(repo, calToday, tKeys, todayAnswers);
        await prefs.setString(kJournalSheetLastKey, calToday);
        if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
        if (context.mounted) bumpInsights(context);
      },
      onDismiss: () async {
        await prefs.setString(kJournalSheetLastKey, calToday);
        if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
      },
      onOpenFullJournal: onOpenFullJournal == null
          ? null
          : () {
              if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
              onOpenFullJournal();
            },
    ),
  );
  // Falls per Swipe weggewischt wurde.
  await prefs.setString(kJournalSheetLastKey, calToday);
}

/// „Heute eintragen“ im Journal-Tab: öffnet das Blatt von Hand, mit dem, was
/// für gestern und heute schon eingetragen ist. Die Tageszeit-Regel gilt hier
/// nicht, das Blatt ist immer erreichbar (J26).
Future<void> openMorningSheetManually(BuildContext context) async {
  final now = taktNow();
  final calToday = todayLabel(now);
  final calYesterday = dayLabelBefore(calToday, 1);
  if (calYesterday == null) return;
  final config = await JournalConfig.load();
  final metrics = await LocalDb.journalMetricsByDay(sinceDaysEpoch: calYesterday);
  Map<String, double> answersOf(String day) => {
        for (final e in (metrics[day] ?? const <String, JournalMetricValue>{}).entries)
          e.key: e.value.value,
      };
  if (!context.mounted) return;
  await presentMorningSheet(
    context,
    config: config,
    calYesterday: calYesterday,
    calToday: calToday,
    initialYesterday: answersOf(calYesterday),
    initialToday: answersOf(calToday),
  );
}

Future<void> _writeDay(
  LocalRepository? repo,
  String date,
  Set<String> sheetKeys,
  Map<String, double> answers,
) async {
  if (repo != null) {
    await repo.editJournalMetrics(date, (day) {
      for (final k in sheetKeys) {
        final v = answers[k];
        if (v == null) {
          day.remove(k);
        } else {
          day[k] = JournalMetricValue(v);
        }
      }
    });
    return;
  }
  final db = await LocalDb.instance;
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  await db.transaction((txn) async {
    for (final k in sheetKeys) {
      final v = answers[k];
      if (v == null) {
        await txn.delete('journal_metric', where: 'date = ? AND field = ?', whereArgs: [date, k]);
      } else {
        await txn.insert(
          'journal_metric',
          {'date': date, 'field': k, 'value': v, 'at_min': null, 'updated_at': nowMs},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  });
}
