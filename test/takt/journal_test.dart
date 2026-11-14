import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/data/db.dart';
import 'package:openstrap_edge/data/journal_fields.dart' show JournalMetricValue;
import 'package:openstrap_edge/takt/journal/briefing_link.dart';
import 'package:openstrap_edge/takt/journal/journal_config.dart';
import 'package:openstrap_edge/takt/journal/journal_evidence.dart';
import 'package:openstrap_edge/takt/journal/journal_seed.dart';
import 'package:openstrap_edge/takt/journal/journal_tab.dart';
import 'package:openstrap_edge/takt/journal/morning_sheet.dart';
import 'package:openstrap_edge/ui2/screens/journal_compose.dart' show JournalCompose;
import 'package:openstrap_edge/takt/journal/morning_sheet_rule.dart';
import 'package:openstrap_edge/takt/journal/new_question_sheet.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:openstrap_edge/data/local_repository_impl.dart';
import 'package:openstrap_edge/state/app_state.dart';
import 'package:openstrap_edge/sync/paired_device.dart' show PairedDevice;
import 'package:openstrap_edge/takt/now.dart';
import 'package:openstrap_edge/takt/today/takt_today_screen.dart';
import 'package:openstrap_edge/takt/today/visibility.dart';
import 'package:openstrap_edge/theme/theme_controller.dart';
import 'package:openstrap_edge/ui2/ui2.dart';

class _TestApp extends AppState {
  _TestApp(this.through) : super.forTesting();
  final DateTime? through;
  @override
  bool get deriving => false;
  @override
  DateTime? get lastRecordAt => through;
  @override
  Future<void> syncNow() async {}
  @override
  void retainLiveHrView() {}
  @override
  void releaseLiveHrView() {}
}

Widget _wrap(Widget child, {Locale locale = const Locale('de')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: TaktLook(child: child)),
  );
}

Future<void> _settle(WidgetTester t, [int n = 15]) async {
  for (var i = 0; i < n; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await t.pump(const Duration(milliseconds: 40));
  }
}

void main() {
  Future<void> resetTestDb() async {
    final db = await LocalDb.instance;
    await db.delete('journal_metric');
    await db.delete('journal');
  }

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await LocalDb.close();
    LocalDb.dbName = 'takt_journal_test.db';
    await databaseFactory.deleteDatabase(
      p.join(await databaseFactory.getDatabasesPath(), LocalDb.dbName),
    );
    await LocalDb.instance;
  });

  group('13-1: JournalConfig', () {
    test('Standardfragen sind definiert mit korrekten Eigenschaften', () async {
      SharedPreferences.setMockInitialValues({});
      final config = await JournalConfig.load();

      expect(config.questions.length, 5);

      final vitD = config.question('vitamin_d')!;
      expect(vitD.label, 'Vitamin D genommen');
      expect(vitD.section, JournalSection.yesterday);
      expect(vitD.isPrivate, false);
      expect(vitD.showInSheet, true);
      expect(vitD.hidden, false);

      final read = config.question('read_evening')!;
      expect(read.label, 'Gelesen');
      expect(read.section, JournalSection.yesterday);

      final meat = config.question('meat')!;
      expect(meat.label, 'Fleisch gegessen');
      expect(meat.section, JournalSection.yesterday);

      final solo = config.question('priv_solo')!;
      expect(solo.label, 'Private Frage');
      expect(solo.section, JournalSection.yesterday);
      expect(solo.isPrivate, true);

      final feeling = config.question('feeling')!;
      expect(feeling.label, 'Wie fühlst du dich?');
      expect(feeling.section, JournalSection.today);
      expect(feeling.isRating, true);
    });

    test('Anzeigename ändern (J10) und persistieren', () async {
      SharedPreferences.setMockInitialValues({});
      var config = await JournalConfig.load();

      await config.setDisplayName('vitamin_d', 'Sonne & Vit D');
      config = await JournalConfig.load();

      expect(config.question('vitamin_d')?.label, 'Sonne & Vit D');
    });

    test('Ein-/Ausschalten im Morgenblatt (J11)', () async {
      SharedPreferences.setMockInitialValues({});
      var config = await JournalConfig.load();

      await config.setShowInSheet('meat', false);
      config = await JournalConfig.load();

      expect(config.question('meat')?.showInSheet, false);
      expect(config.sheetQuestionsYesterday.map((q) => q.key), isNot(contains('meat')));
    });

    test('Ausblenden / Löschen und Wiedereinblenden (J11)', () async {
      SharedPreferences.setMockInitialValues({});
      var config = await JournalConfig.load();

      await config.setHidden('read_evening', true);
      config = await JournalConfig.load();

      expect(config.question('read_evening')?.hidden, true);
      expect(config.activeQuestions.map((q) => q.key), isNot(contains('read_evening')));

      await config.setHidden('read_evening', false);
      config = await JournalConfig.load();
      expect(config.question('read_evening')?.hidden, false);
    });

    test('Eigene Frage anlegen mit privat (J9, J20)', () async {
      SharedPreferences.setMockInitialValues({});
      var config = await JournalConfig.load();

      final created = await config.addCustomQuestion(
        name: 'Kalt geduscht',
        section: JournalSection.yesterday,
        isPrivate: false,
      );
      expect(created.key.startsWith('custom_'), true);
      expect(created.isPrivate, false);

      final privateCreated = await config.addCustomQuestion(
        name: 'Tagebuch geschrieben',
        section: JournalSection.yesterday,
        isPrivate: true,
      );
      expect(privateCreated.key.startsWith('priv_'), true);
      expect(privateCreated.isPrivate, true);
    });
  });

  group('13-2: journalSeed', () {
    test('journalSeed legt die 5 Standardfelder in journal_field_def an', () async {
      final db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE journal_field_def (
            key TEXT PRIMARY KEY,
            label TEXT NOT NULL,
            kind TEXT NOT NULL,
            unit TEXT NOT NULL DEFAULT '',
            max_value REAL NOT NULL,
            step REAL NOT NULL,
            has_time INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
      });

      await journalSeed(db);

      final rows = await db.query('journal_field_def');
      expect(rows.length, 5);

      final keys = rows.map((r) => r['key'] as String).toSet();
      expect(keys, {'vitamin_d', 'read_evening', 'meat', 'priv_solo', 'feeling'});

      // Idempotent: zweiter Aufruf verändert nichts
      await journalSeed(db);
      final rows2 = await db.query('journal_field_def');
      expect(rows2.length, 5);
      await db.close();
    });
  });

  group('13-4: MorningSheetRule', () {
    final yQuestions = [
      const JournalQuestion(key: 'vitamin_d', defaultLabel: 'Vitamin D', section: JournalSection.yesterday),
      const JournalQuestion(key: 'read_evening', defaultLabel: 'Gelesen', section: JournalSection.yesterday),
    ];
    final tQuestions = [
      const JournalQuestion(key: 'feeling', defaultLabel: 'Gefühl', section: JournalSection.today, isRating: true),
    ];

    test('J1: Kalendertag aktiv und Nacht fertig -> Blatt kommt', () {
      final decision = checkMorningSheetRule(
        now: DateTime(2026, 11, 12, 7, 30),
        activeDayId: '2026-11-12',
        calToday: '2026-11-12',
        todayHasSleep: true,
        nightInProgress: false,
        lastDismissedOrCompletedDay: null,
        sheetQuestionsYesterday: yQuestions,
        sheetQuestionsToday: tQuestions,
        existingYesterdayAnswers: {},
        existingTodayAnswers: {},
      );
      expect(decision.shouldShow, true);
      expect(decision.yesterdayAnswers, isEmpty);
    });

    test('J22: 01:00 nach Mitternacht, Vortag noch aktiv -> Blatt kommt NICHT', () {
      final decision = checkMorningSheetRule(
        now: DateTime(2026, 11, 12, 1, 0),
        activeDayId: '2026-11-11',
        calToday: '2026-11-12',
        todayHasSleep: false,
        nightInProgress: false,
        lastDismissedOrCompletedDay: null,
        sheetQuestionsYesterday: yQuestions,
        sheetQuestionsToday: tQuestions,
        existingYesterdayAnswers: {},
        existingTodayAnswers: {},
      );
      expect(decision.shouldShow, false);
    });

    test('J21 (Änderung 14.11.): ohne berechnete Nacht ab 5 Uhr ja, davor nein', () {
      MorningSheetDecision at(int h, int m, {String active = '2026-11-11'}) => checkMorningSheetRule(
            now: DateTime(2026, 11, 12, h, m),
            // Nacht noch nicht berechnet: der Vortag ist noch aktiv (bis 12 Uhr).
            activeDayId: active,
            calToday: '2026-11-12',
            todayHasSleep: false,
            nightInProgress: false,
            lastDismissedOrCompletedDay: null,
            sheetQuestionsYesterday: yQuestions,
            sheetQuestionsToday: tQuestions,
            existingYesterdayAnswers: {},
            existingTodayAnswers: {},
          );
      expect(at(4, 59).shouldShow, false);
      // Gerätetest 14.11.: morgens um 7 kam das Blatt nicht, weil der Vortag
      // noch aktiv war. Jetzt kommt es beim ersten Öffnen.
      expect(at(7, 0).shouldShow, true);
      expect(at(10, 15).shouldShow, true);
    });

    test('J1: fertige Nacht vor 5 Uhr -> Blatt kommt schon', () {
      final d = checkMorningSheetRule(
        now: DateTime(2026, 11, 12, 4, 40),
        calToday: '2026-11-12',
        todayHasSleep: true,
        nightInProgress: false,
        lastDismissedOrCompletedDay: null,
        sheetQuestionsYesterday: yQuestions,
        sheetQuestionsToday: tQuestions,
        existingYesterdayAnswers: {},
        existingTodayAnswers: {},
      );
      expect(d.shouldShow, true);
    });

    test('J7/J25: Heute bereits weggewischt oder beantwortet -> kommt nicht', () {
      final decision = checkMorningSheetRule(
        now: DateTime(2026, 11, 12, 11, 0),
        activeDayId: '2026-11-12',
        calToday: '2026-11-12',
        todayHasSleep: true,
        nightInProgress: false,
        lastDismissedOrCompletedDay: '2026-11-12',
        sheetQuestionsYesterday: yQuestions,
        sheetQuestionsToday: tQuestions,
        existingYesterdayAnswers: {},
        existingTodayAnswers: {},
      );
      expect(decision.shouldShow, false);
    });

    test('J8: Alle Fragen schon beantwortet -> kommt nicht; teilweise -> vorbefüllt', () {
      final allAnswered = checkMorningSheetRule(
        now: DateTime(2026, 11, 12, 8, 0),
        activeDayId: '2026-11-12',
        calToday: '2026-11-12',
        todayHasSleep: true,
        nightInProgress: false,
        lastDismissedOrCompletedDay: null,
        sheetQuestionsYesterday: yQuestions,
        sheetQuestionsToday: tQuestions,
        existingYesterdayAnswers: {'vitamin_d': 1.0, 'read_evening': 0.0},
        existingTodayAnswers: {'feeling': 3.0},
      );
      expect(allAnswered.shouldShow, false);

      final partialAnswered = checkMorningSheetRule(
        now: DateTime(2026, 11, 12, 8, 0),
        activeDayId: '2026-11-12',
        calToday: '2026-11-12',
        todayHasSleep: true,
        nightInProgress: false,
        lastDismissedOrCompletedDay: null,
        sheetQuestionsYesterday: yQuestions,
        sheetQuestionsToday: tQuestions,
        existingYesterdayAnswers: {'vitamin_d': 1.0},
        existingTodayAnswers: {},
      );
      expect(partialAnswered.shouldShow, true);
      expect(partialAnswered.yesterdayAnswers['vitamin_d'], 1.0);
    });
  });

  group('13-5: MorningSheet Widget', () {
    testWidgets('J2, J3, J4: Fragen rendern, Antippen selektiert und deselektiert', (tester) async {
      final config = JournalConfig(List.of(JournalConfig.standardQuestions));

      Map<String, double>? savedYesterday;
      Map<String, double>? savedToday;

      await tester.pumpWidget(
        _wrap(
          MorningSheet(
            config: config,
            calYesterday: '2026-11-11',
            calToday: '2026-11-12',
            onSave: (y, t) async {
              savedYesterday = y;
              savedToday = t;
            },
            onDismiss: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // J2: Gestern Header und Fragen
      expect(find.textContaining('Gestern'), findsOneWidget);
      expect(find.text('Vitamin D genommen'), findsOneWidget);
      expect(find.text('Gelesen'), findsOneWidget);
      expect(find.text('Fleisch gegessen'), findsOneWidget);
      expect(find.text('Private Frage'), findsOneWidget);

      // J3: Heute Header und 4 Stufen
      expect(find.textContaining('Heute'), findsOneWidget);
      expect(find.text('Wie fühlst du dich?'), findsOneWidget);
      expect(find.text('schlecht'), findsOneWidget);
      expect(find.text('geht so'), findsOneWidget);
      expect(find.text('gut'), findsOneWidget);
      expect(find.text('sehr gut'), findsOneWidget);

      // J4: Ein Tipp selektiert, zweiter Tipp deselektiert
      final vitDYes = find.byKey(const ValueKey('sheet-btn-vitamin_d-yes'));
      expect(vitDYes, findsOneWidget);

      await tester.tap(vitDYes);
      await tester.pumpAndSettle();

      // Tipp auf "Fertig" (J5)
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      expect(savedYesterday, isNotNull);
      expect(savedYesterday!['vitamin_d'], 1.0);
      // J6: Unbeantwortet bleibt unbeantwortet (wird nicht als Nein gespeichert)
      expect(savedYesterday!.containsKey('read_evening'), false);
      expect(savedToday, isEmpty);
    });

    testWidgets('J4: Zweiter Tipp deselektiert Antwort', (tester) async {
      final config = JournalConfig(List.of(JournalConfig.standardQuestions));

      Map<String, double>? savedYesterday;

      await tester.pumpWidget(
        _wrap(
          MorningSheet(
            config: config,
            calYesterday: '2026-11-11',
            calToday: '2026-11-12',
            onSave: (y, t) async {
              savedYesterday = y;
            },
            onDismiss: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final vitDYes = find.byKey(const ValueKey('sheet-btn-vitamin_d-yes'));
      await tester.tap(vitDYes);
      await tester.pumpAndSettle();
      // Zweiter Tipp nimmt Antwort zurück:
      await tester.tap(vitDYes);
      await tester.pumpAndSettle();

      // Antwort auf Gefühl:
      await tester.tap(find.text('gut'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      expect(savedYesterday, isEmpty);
    });

    testWidgets('J7: Später speichert nichts und ruft onDismiss', (tester) async {
      final config = JournalConfig(List.of(JournalConfig.standardQuestions));
      var dismissed = false;

      await tester.pumpWidget(
        _wrap(
          MorningSheet(
            config: config,
            calYesterday: '2026-11-11',
            calToday: '2026-11-12',
            onSave: (y, t) async {},
            onDismiss: () async => dismissed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Später'));
      await tester.pumpAndSettle();

      expect(dismissed, true);
    });

    testWidgets('J23: Schreibfehler zeigt Fehlermeldung mit Nochmal, Antworten bleiben erhalten', (tester) async {
      final config = JournalConfig(List.of(JournalConfig.standardQuestions));
      var shouldThrow = true;
      var saved = false;

      await tester.pumpWidget(
        _wrap(
          MorningSheet(
            config: config,
            calYesterday: '2026-11-11',
            calToday: '2026-11-12',
            onSave: (y, t) async {
              if (shouldThrow) throw Exception('DB error');
              saved = true;
            },
            onDismiss: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('sheet-btn-meat-yes')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      expect(find.text('Speichern fehlgeschlagen'), findsOneWidget);
      expect(find.text('Nochmal'), findsOneWidget);

      // Beim erneuten Versuch klappt es:
      shouldThrow = false;
      await tester.tap(find.text('Nochmal'));
      await tester.pumpAndSettle();

      expect(saved, true);
    });
  });

  group('13-7: JournalEvidence Rechnung (J12-J17)', () {
    final vitD = const JournalQuestion(
      key: 'vitamin_d',
      defaultLabel: 'Vitamin D',
      section: JournalSection.yesterday,
    );
    final reading = const JournalQuestion(
      key: 'read_evening',
      defaultLabel: 'Gelesen',
      section: JournalSection.yesterday,
    );
    final meat = const JournalQuestion(
      key: 'meat',
      defaultLabel: 'Fleisch',
      section: JournalSection.yesterday,
    );

    test('J13: < 5 Tage Ja oder Nein -> tooFewDays, keine Durchschnitte', () {
      final metrics = {
        '2026-11-01': {'vitamin_d': 1.0},
        '2026-11-02': {'vitamin_d': 1.0},
        '2026-11-03': {'vitamin_d': 1.0},
        '2026-11-04': {'vitamin_d': 0.0},
      };
      final outcomes = {
        'readiness': {
          '2026-11-02': 75.0,
          '2026-11-03': 80.0,
          '2026-11-04': 70.0,
          '2026-11-05': 65.0,
        },
      };

      final results = computeJournalEvidence(
        questions: [vitD],
        metricsByDay: metrics,
        outcomeMaps: outcomes,
        numericInsights: [],
        excludedDates: {},
      );

      expect(results.length, 1);
      final res = results.first;
      expect(res.impact, HabitImpact.tooFewDays);
      expect(res.yesCount, 3);
      expect(res.noCount, 1);
      expect(res.hasEnoughDays, false);
      expect(res.readinessComparison, isNull);
    });

    test('J12, J14, J16: >= 5 Ja und >= 5 Nein -> Rechnet Durchschnitte & Differenz auf D+1, prüft Signifikanz', () {
      final metrics = <String, Map<String, double>>{};
      final readiness = <String, double>{};

      // 5 Ja Tage: 01 bis 05 -> Outcomes auf 02 bis 06 mit 80.0
      for (var i = 1; i <= 5; i++) {
        final d = '2026-11-0$i';
        metrics[d] = {'vitamin_d': 1.0};
        readiness['2026-11-0${i + 1}'] = 80.0;
      }
      // 5 Nein Tage: 06 bis 10 -> Outcomes auf 07 bis 11 mit 60.0
      for (var i = 6; i <= 10; i++) {
        final d = i < 10 ? '2026-11-0$i' : '2026-11-$i';
        final nextD = i + 1 < 10 ? '2026-11-0${i + 1}' : '2026-11-${i + 1}';
        metrics[d] = {'vitamin_d': 0.0};
        readiness[nextD] = 60.0;
      }

      // 1. Ohne Eintrag in numericInsights -> noDifference (J14)
      var results = computeJournalEvidence(
        questions: [vitD],
        metricsByDay: metrics,
        outcomeMaps: {'readiness': readiness},
        numericInsights: [],
        excludedDates: {},
      );

      expect(results.length, 1);
      expect(results.first.impact, HabitImpact.noDifference);
      expect(results.first.yesCount, 5);
      expect(results.first.noCount, 5);
      expect(results.first.readinessComparison?.yesAvg, 80.0);
      expect(results.first.readinessComparison?.noAvg, 60.0);
      expect(results.first.readinessComparison?.diff, 20.0);

      // 2. Mit signifikantem Eintrag in numericInsights mit helped: true -> helps (J14)
      results = computeJournalEvidence(
        questions: [vitD],
        metricsByDay: metrics,
        outcomeMaps: {'readiness': readiness},
        numericInsights: [
          {'field': 'vitamin_d', 'outcome': 'readiness', 'helped': true, 'meaningful': true},
        ],
        excludedDates: {},
      );
      expect(results.first.impact, HabitImpact.helps);

      // 3. Mit signifikantem Eintrag mit helped: false -> costs (J14)
      results = computeJournalEvidence(
        questions: [vitD],
        metricsByDay: metrics,
        outcomeMaps: {'readiness': readiness},
        numericInsights: [
          {'field': 'vitamin_d', 'outcome': 'readiness', 'helped': false, 'meaningful': true},
        ],
        excludedDates: {},
      );
      expect(results.first.impact, HabitImpact.costs);
    });

    test('J17: Importierte Tage und Tage ohne gemessene Nacht zählen nicht mit', () {
      final metrics = <String, Map<String, double>>{};
      final readiness = <String, double>{};
      for (var i = 1; i <= 5; i++) {
        metrics['2026-11-0$i'] = {'vitamin_d': 1.0};
        readiness['2026-11-0${i + 1}'] = 80.0;
      }
      for (var i = 6; i <= 10; i++) {
        final d = i < 10 ? '2026-11-0$i' : '2026-11-$i';
        final nextD = i + 1 < 10 ? '2026-11-0${i + 1}' : '2026-11-${i + 1}';
        metrics[d] = {'vitamin_d': 0.0};
        readiness[nextD] = 60.0;
      }

      // '2026-11-02' (Nacht auf 2. Nov) ist importiert
      final results = computeJournalEvidence(
        questions: [vitD],
        metricsByDay: metrics,
        outcomeMaps: {'readiness': readiness},
        numericInsights: [],
        excludedDates: {'2026-11-02'},
      );

      // Ein Ja-Tag fiel weg -> nur noch 4 Ja-Tage -> tooFewDays
      expect(results.first.impact, HabitImpact.tooFewDays);
      expect(results.first.yesCount, 4);
      expect(results.first.noCount, 5);
    });

    test('Gerätetest 14.11.: Eintrag ohne gemessene Nacht danach wartet sichtbar', () {
      final results = computeJournalEvidence(
        questions: [vitD],
        metricsByDay: {
          '2026-11-12': {'vitamin_d': 1.0},
          '2026-11-13': {'vitamin_d': 0.0},
        },
        // Nacht auf den 13. gemessen, Nacht auf den 14. noch nicht berechnet.
        outcomeMaps: {'readiness': {'2026-11-13': 70.0}},
        numericInsights: [],
        excludedDates: {},
      );
      expect(results.first.yesCount, 1);
      expect(results.first.noCount, 0);
      expect(results.first.waitingCount, 1);
    });

    // Echte Daten vom Pixel, 14.11.: Readiness ist während der 14 Nächte
    // Kalibrierung leer, HRV, Ruhepuls und Effizienz sind da. Vorher zählte
    // deshalb kein Eintrag („Ja 0 von 5“, „2 Einträge warten“).
    test('Gerätetest 14.11.: Nacht ohne Readiness, aber mit HRV zählt', () {
      final results = computeJournalEvidence(
        questions: [vitD],
        metricsByDay: {
          '2026-11-12': {'vitamin_d': 0.0},
          '2026-11-13': {'vitamin_d': 1.0},
          '2026-11-14': {'vitamin_d': 1.0},
        },
        outcomeMaps: {
          'readiness': {},
          'rmssd': {'2026-11-13': 78.9, '2026-11-14': 83.3},
          'rhr': {'2026-11-13': 56.4, '2026-11-14': 57.9},
          'efficiency': {'2026-11-13': 97.7, '2026-11-14': 94.4},
        },
        numericInsights: [],
        excludedDates: {},
      );
      expect(results.first.yesCount, 1);
      expect(results.first.noCount, 1);
      expect(results.first.waitingCount, 1); // Nacht auf den 15. steht aus
      expect(results.first.readinessComparison, isNull);
    });

    test('Gerätetest 14.11.: Ab 5/5 ohne Readiness gibt es HRV-Vergleich, keinen Readiness-Vergleich', () {
      final metrics = <String, Map<String, double>>{};
      final hrv = <String, double>{};
      for (var i = 1; i <= 10; i++) {
        String day(int n) => '2026-11-${n.toString().padLeft(2, '0')}';
        metrics[day(i)] = {'vitamin_d': i <= 5 ? 1.0 : 0.0};
        hrv[day(i + 1)] = i <= 5 ? 80.0 : 70.0;
      }
      final r = computeJournalEvidence(
        questions: [vitD],
        metricsByDay: metrics,
        outcomeMaps: {'rmssd': hrv},
        numericInsights: [],
        excludedDates: {},
      ).first;
      expect(r.yesCount, 5);
      expect(r.noCount, 5);
      expect(r.impact, HabitImpact.noDifference);
      expect(r.readinessComparison, isNull);
      expect(r.hrvComparison?.diff, 10.0);
    });

    test('J15: Sortierung: Hilft > Kostet > Kein Unterschied > Zu wenig Tage', () {
      final metrics = <String, Map<String, double>>{};
      final readiness = <String, double>{};

      for (var i = 1; i <= 5; i++) {
        metrics['2026-11-0$i'] = {'vitamin_d': 1.0, 'read_evening': 1.0, 'meat': 1.0};
        readiness['2026-11-0${i + 1}'] = 80.0;
      }
      for (var i = 6; i <= 10; i++) {
        final d = i < 10 ? '2026-11-0$i' : '2026-11-$i';
        final nextD = i + 1 < 10 ? '2026-11-0${i + 1}' : '2026-11-${i + 1}';
        metrics[d] = {'vitamin_d': 0.0, 'read_evening': 0.0}; // meat fehlt -> tooFewDays
        readiness[nextD] = 60.0;
      }

      final results = computeJournalEvidence(
        questions: [meat, reading, vitD],
        metricsByDay: metrics,
        outcomeMaps: {'readiness': readiness},
        numericInsights: [
          {'field': 'vitamin_d', 'outcome': 'readiness', 'helped': true, 'meaningful': true, 'delta': 20.0},
          {'field': 'read_evening', 'outcome': 'readiness', 'helped': false, 'meaningful': true, 'delta': -10.0},
        ],
        excludedDates: {},
      );

      expect(results.map((r) => r.question.key).toList(), [
        'vitamin_d',   // helps
        'read_evening', // costs
        'meat',        // tooFewDays
      ]);
    });
  });

  group('13-8 & 13-9: Eigene Fragen UI & JournalTab (J9, J10, J11, J20, J27)', () {
    testWidgets('NewQuestionSheet legt Frage an und schließt Sheet (J9, J20)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final config = await JournalConfig.load();
      JournalQuestion? created;

      await tester.pumpWidget(
        _wrap(
          NewQuestionSheet(
            config: config,
            onCreated: (q) => created = q,
          ),
        ),
      );
      await _settle(tester);

      expect(find.text('Neue Frage anlegen'), findsOneWidget);
      expect(find.text('Name der Frage'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Kreatin genommen');
      await tester.pump();

      // Private-Schalter antippen
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Speichern
      await tester.tap(find.byKey(const ValueKey('new-question-save-btn')));
      await _settle(tester);

      expect(created, isNotNull);
      expect(created!.label, 'Kreatin genommen');
      expect(created!.isPrivate, true);
      expect(created!.key, startsWith('priv_'));
    });

    testWidgets('EditQuestionSheet ändert Anzeigenamen und Toggles (J10, J11)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final config = await JournalConfig.load();
      final q = config.question('vitamin_d')!;
      var changed = false;

      await tester.pumpWidget(
        _wrap(
          EditQuestionSheet(
            config: config,
            question: q,
            onChanged: () => changed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vitamin D genommen'), findsWidgets);
      expect(find.text('Anzeigename'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Vitamin D3 & K2');
      await tester.pumpAndSettle();

      // Toggle im Morgenblatt anzeigen
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Speichern
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(changed, true);
      expect(config.question('vitamin_d')?.label, 'Vitamin D3 & K2');
      expect(config.question('vitamin_d')?.showInSheet, false);
    });

    testWidgets('JournalTab rendert "Heute eintragen" Button und Fragen (J27)', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_wrap(const JournalTab()));
      await _settle(tester);

      expect(find.byKey(const ValueKey('journal-log-today-btn')), findsOneWidget);
      expect(find.text('Heute eintragen'), findsOneWidget);
      expect(find.text('Was tut mir gut'), findsOneWidget);
      expect(find.text('Gewohnheiten'), findsOneWidget);
      expect(find.byKey(const ValueKey('journal-add-custom-question-btn')), findsOneWidget);
    });
  });

  group('13-12: Heute eintragen öffnet das Morgenblatt, nicht den alten Editor', () {
    testWidgets('Tipp auf „Heute eintragen“ zeigt das Morgenblatt und speichert', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final now = DateTime(2026, 11, 12, 14, 0);
      taktNow = () => now;
      addTearDown(() => taktNow = DateTime.now);
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(resetTestDb);

      await tester.pumpWidget(_wrap(const JournalTab()));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('journal-log-today-btn')));
      await _settle(tester, 25);

      expect(find.byType(MorningSheet), findsOneWidget);
      expect(find.byType(JournalCompose), findsNothing);

      await tester.ensureVisible(find.byKey(const ValueKey('sheet-btn-vitamin_d-yes')));
      await tester.tap(find.byKey(const ValueKey('sheet-btn-vitamin_d-yes')));
      await tester.pump();
      await tester.ensureVisible(find.text('Fertig'));
      await tester.tap(find.text('Fertig'));
      await _settle(tester, 15);

      expect(find.byType(MorningSheet), findsNothing);
      final y = await tester.runAsync(() => LocalDb.journalMetricsForDay('2026-11-11'));
      expect(y!['vitamin_d']?.value, 1.0);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('13-13: Morgenbriefing-Link (J28–J32)', () {
    test('J28: nur https-Links auf drive.google.com werden angenommen', () {
      expect(normalizeBriefingLink('https://drive.google.com/file/d/abc123/view?usp=sharing'),
          'https://drive.google.com/file/d/abc123/view?usp=sharing');
      expect(normalizeBriefingLink('  https://drive.google.com/open?id=abc  '),
          'https://drive.google.com/open?id=abc');
      expect(normalizeBriefingLink('http://drive.google.com/file/d/abc/view'), isNull);
      expect(normalizeBriefingLink('https://example.com/file/d/abc/view'), isNull);
      expect(normalizeBriefingLink('https://drive.google.com.evil.example/x'), isNull);
      expect(normalizeBriefingLink('https://drive.google.com/'), isNull);
      expect(normalizeBriefingLink('kein link'), isNull);
      expect(normalizeBriefingLink(''), isNull);
    });

    testWidgets('J28: Einrichten im Tab speichert den Link, ungültiger wird abgelehnt', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(_wrap(const JournalTab()));
      await _settle(tester);
      expect(find.byKey(const ValueKey('briefing-listen')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('briefing-setup')));
      await _settle(tester, 20);

      await tester.enterText(find.byKey(const ValueKey('briefing-link-field')), 'https://example.com/x/y');
      await tester.tap(find.byKey(const ValueKey('briefing-link-save')));
      await tester.pump();
      expect(find.byKey(const ValueKey('briefing-link-invalid')), findsOneWidget);
      expect(find.text('Das ist kein Google-Drive-Link'), findsOneWidget);
      final prefs = await tester.runAsync(() => SharedPreferences.getInstance());
      expect(prefs!.getString(kBriefingLinkKey), isNull);

      await tester.enterText(find.byKey(const ValueKey('briefing-link-field')),
          'https://drive.google.com/file/d/abc123/view');
      await tester.tap(find.byKey(const ValueKey('briefing-link-save')));
      await _settle(tester, 20);
      expect(prefs.getString(kBriefingLinkKey), 'https://drive.google.com/file/d/abc123/view');
      expect(find.byKey(const ValueKey('briefing-listen')), findsOneWidget);
      expect(find.text('Morgenbriefing anhören'), findsOneWidget);
      expect(find.byKey(const ValueKey('briefing-setup')), findsNothing);
    });

    testWidgets('J29, J31: Tipp öffnet den Link, Fehlschlag zeigt eine Meldung', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({kBriefingLinkKey: 'https://drive.google.com/file/d/abc123/view'});
      final opened = <Uri>[];
      var ok = true;
      briefingLauncher = (u) async {
        opened.add(u);
        return ok;
      };
      addTearDown(() => briefingLauncher = (u) async => false);

      await tester.pumpWidget(_wrap(const JournalTab()));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('briefing-listen')));
      await tester.pump();
      expect(opened.single.toString(), 'https://drive.google.com/file/d/abc123/view');
      expect(find.text('Link konnte nicht geöffnet werden'), findsNothing);

      ok = false;
      await tester.tap(find.byKey(const ValueKey('briefing-listen')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Link konnte nicht geöffnet werden'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('J29: Link entfernen im Blatt bringt die Einrichten-Zeile zurück', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({kBriefingLinkKey: 'https://drive.google.com/file/d/abc123/view'});

      await tester.pumpWidget(_wrap(const JournalTab()));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('briefing-edit')));
      await _settle(tester, 20);
      await tester.tap(find.byKey(const ValueKey('briefing-link-remove')));
      await _settle(tester, 20);
      final prefs = await tester.runAsync(() => SharedPreferences.getInstance());
      expect(prefs!.getString(kBriefingLinkKey), isNull);
      expect(find.byKey(const ValueKey('briefing-setup')), findsOneWidget);
    });

    testWidgets('J30: Morgenblatt zeigt die Zeile nur mit Link, die Antworten bleiben', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Future<void> pumpSheet() async {
        await tester.pumpWidget(const SizedBox()); // frischer State, Link wird neu geladen
        await tester.pumpWidget(_wrap(MorningSheet(
          config: JournalConfig(List.of(JournalConfig.standardQuestions)),
          calYesterday: '2026-11-11',
          calToday: '2026-11-12',
          onSave: (y, t) async {},
          onDismiss: () async {},
        )));
        await _settle(tester);
      }

      SharedPreferences.setMockInitialValues({});
      await pumpSheet();
      expect(find.byKey(const ValueKey('briefing-listen')), findsNothing);
      expect(find.text('Morgenbriefing-Link einrichten'), findsNothing);

      SharedPreferences.setMockInitialValues({kBriefingLinkKey: 'https://drive.google.com/file/d/abc123/view'});
      final opened = <Uri>[];
      briefingLauncher = (u) async {
        opened.add(u);
        return true;
      };
      addTearDown(() => briefingLauncher = (u) async => false);
      await pumpSheet();
      expect(find.byKey(const ValueKey('briefing-listen')), findsOneWidget);
      expect(find.byKey(const ValueKey('briefing-edit')), findsNothing);

      await tester.ensureVisible(find.byKey(const ValueKey('sheet-btn-vitamin_d-yes')));
      await tester.tap(find.byKey(const ValueKey('sheet-btn-vitamin_d-yes')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('briefing-listen')));
      await tester.pump();
      expect(opened, hasLength(1));
      expect(find.byType(MorningSheet), findsOneWidget);
      expect(find.text('1/5'), findsOneWidget);
    });

    for (final lang in ['de', 'en']) {
      testWidgets('J24: Tab und Blatt mit Link ohne Overflow, 320 px, große Schrift ($lang)', (tester) async {
        tester.view.physicalSize = const Size(320, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({kBriefingLinkKey: 'https://drive.google.com/file/d/abc123/view'});
        Widget big(Widget c) => MaterialApp(
              locale: Locale(lang),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (ctx, w) => MediaQuery(
                  data: MediaQuery.of(ctx).copyWith(textScaler: const TextScaler.linear(1.3)), child: w!),
              home: Scaffold(body: TaktLook(child: SingleChildScrollView(child: c))),
            );
        await tester.pumpWidget(big(const JournalTab()));
        await _settle(tester);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(big(MorningSheet(
          config: JournalConfig(List.of(JournalConfig.standardQuestions)),
          calYesterday: '2026-11-11',
          calToday: '2026-11-12',
          onSave: (y, t) async {},
          onDismiss: () async {},
        )));
        await _settle(tester);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }

    test('J32: Der Link taucht in Export, Bericht und KI-Chat nirgends auf', () {
      for (final dir in ['lib/data', 'lib/ai', 'lib/coach', 'lib/import']) {
        for (final f in Directory(dir).listSync(recursive: true).whereType<File>()) {
          if (!f.path.endsWith('.dart')) continue;
          final text = f.readAsStringSync();
          expect(text.contains('briefing_url') || text.contains('kBriefingLinkKey'), isFalse,
              reason: f.path);
        }
      }
    });
  });

  group('Gerätetest 14.11.: Journal-Tab zählt neue Einträge ohne Neustart', () {
    testWidgets('Morgenblatt woanders gespeichert und Nacht berechnet: Tab lädt neu und zählt', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(resetTestDb);
      await tester.runAsync(() async {
        final db = await LocalDb.instance;
        await db.delete('metric_series');
      });
      final app = _TestApp(null);
      addTearDown(app.dispose);

      await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: app,
        child: _wrap(const JournalTab()),
      ));
      await _settle(tester);
      final vitCard = find.ancestor(
          of: find.text('Vitamin D genommen').first, matching: find.byType(Surface));
      expect(find.descendant(of: vitCard.first, matching: find.textContaining('Ja 0 von 5')),
          findsOneWidget);

      // Wie auf dem Handy: Das Morgenblatt auf Heute schreibt gestern Ja, die
      // Nacht danach wird berechnet. Der Tab bleibt dabei offen.
      await tester.runAsync(() async {
        final db = await LocalDb.instance;
        await db.insert('journal_metric', {
          'date': '2026-11-12',
          'field': 'vitamin_d',
          'value': 1.0,
          'at_min': null,
          'updated_at': 0,
        });
        await LocalDb.putMetricSeriesValue('2026-11-13', 'readiness', 74);
      });
      app.insightsRevision.value++;
      await _settle(tester, 25);

      expect(find.descendant(of: vitCard.first, matching: find.textContaining('Ja 1 von 5')),
          findsOneWidget);
    });
  });

  group('13-11: Einbindung in Heute-Screen (J1, J7, J21, J22, J25)', () {
    testWidgets('Heute-Screen öffnet Morgenblatt automatisch bei unvollständigen Antworten (J1, J21)', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final now = DateTime(2026, 11, 12, 14, 0);
      taktNow = () => now;
      addTearDown(() => taktNow = DateTime.now);

      taktTodayVisible.value = true;
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(resetTestDb);

      final app = _TestApp(now)..repo = LocalRepositoryImpl(getProfileMap: () => {});
      app.paired = PairedDevice('AA:BB:CC:DD:EE:FF', 'SER1');
      addTearDown(app.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: app),
            ChangeNotifierProvider<ThemeController>(
              create: (_) => ThemeController.seed(AppThemeChoice.light, Brightness.light),
            ),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            locale: const Locale('de'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: TaktTodayScreen()),
          ),
        ),
      );
      await _settle(tester, 25);

      // J1: Morgenblatt schiebt sich von unten ein
      expect(find.byType(MorningSheet), findsOneWidget);
      await _settle(tester, 15);
      expect(find.textContaining('Gestern'), findsOneWidget);
      expect(find.text('Wie fühlst du dich?'), findsOneWidget);

      // J7: Später tippen schließt das Blatt und setzt lastDismissed
      await tester.ensureVisible(find.text('Später'));
      await tester.tap(find.text('Später'));
      await _settle(tester, 10);

      expect(find.byType(MorningSheet), findsNothing);

      final prefs = await tester.runAsync(() => SharedPreferences.getInstance());
      expect(prefs!.getString('takt.journal.sheet.last'), '2026-11-12');

      taktTodayVisible.value = false;
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('Gerätetest 14.11.: um 7 Uhr ohne berechnete Nacht kommt das Blatt beim Öffnen, genau einmal', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final now = DateTime(2026, 11, 14, 7, 0);
      taktNow = () => now;
      addTearDown(() => taktNow = DateTime.now);
      taktTodayVisible.value = true;
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(resetTestDb);
      final app = _TestApp(now)..repo = LocalRepositoryImpl(getProfileMap: () => {});
      app.paired = PairedDevice('AA:BB:CC:DD:EE:FF', 'SER1');
      addTearDown(app.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: app),
            ChangeNotifierProvider<ThemeController>(
              create: (_) => ThemeController.seed(AppThemeChoice.light, Brightness.light),
            ),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            locale: const Locale('de'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: TaktTodayScreen()),
          ),
        ),
      );
      await _settle(tester, 25);
      expect(find.byType(MorningSheet), findsOneWidget);
      taktTodayVisible.value = false;
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('Heute-Screen speichert MorningSheet-Antworten in SQLite (Fertig schließt Blatt)', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final now = DateTime(2026, 11, 12, 14, 0);
      taktNow = () => now;
      addTearDown(() => taktNow = DateTime.now);

      taktTodayVisible.value = true;
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(resetTestDb);

      final app = _TestApp(now)..repo = LocalRepositoryImpl(getProfileMap: () => {});
      app.paired = PairedDevice('AA:BB:CC:DD:EE:FF', 'SER1');
      addTearDown(app.dispose);

      // Bestehendes Feld water_ml am Vortag darf beim Speichern nicht verloren gehen.
      await tester.runAsync(() async {
        await app.repo!.editJournalMetrics('2026-11-11', (day) {
          day['water_ml'] = const JournalMetricValue(750);
        });
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: app),
            ChangeNotifierProvider<ThemeController>(
              create: (_) => ThemeController.seed(AppThemeChoice.light, Brightness.light),
            ),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            locale: const Locale('de'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: TaktTodayScreen()),
          ),
        ),
      );
      await _settle(tester, 25);

      expect(find.byType(MorningSheet), findsOneWidget);
      // Slide-up-Animation des ModalBottomSheet vollständig auslaufen lassen.
      await _settle(tester, 15);
      expect(find.text('0/5'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('sheet-btn-vitamin_d-yes')));
      await tester.tap(find.byKey(const ValueKey('sheet-btn-vitamin_d-yes')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('sheet-btn-meat-no')));
      await tester.tap(find.byKey(const ValueKey('sheet-btn-meat-no')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('sheet-btn-feeling-3')));
      await tester.tap(find.byKey(const ValueKey('sheet-btn-feeling-3')));
      await tester.pump();
      expect(find.text('3/5'), findsOneWidget);

      await tester.ensureVisible(find.text('Fertig'));
      await tester.tap(find.text('Fertig'));
      await _settle(tester, 15);

      expect(find.text('Speichern fehlgeschlagen'), findsNothing);
      expect(find.byType(MorningSheet), findsNothing);

      final yMetrics = await tester.runAsync(() => LocalDb.journalMetricsForDay('2026-11-11'));
      final tMetrics = await tester.runAsync(() => LocalDb.journalMetricsForDay('2026-11-12'));
      expect(yMetrics!['vitamin_d']?.value, 1.0);
      expect(yMetrics['meat']?.value, 0.0);
      expect(yMetrics['water_ml']?.value, 750.0);
      expect(tMetrics!['feeling']?.value, 3.0);

      final prefs = await tester.runAsync(() => SharedPreferences.getInstance());
      expect(prefs!.getString('takt.journal.sheet.last'), '2026-11-12');

      taktTodayVisible.value = false;
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    });
  });
}
