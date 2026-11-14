// Überlauf-Suche auf Heute: deutsche Texte (so wie auf dem Handy), schmale
// Displays und große Schrift. Gerätetest 0.5.1: Ein Overflow im Schlaf-Tab
// fiel in den Tests nicht auf, weil sie englische Kurzformen benutzten.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/state/locale_controller.dart';
import 'package:openstrap_edge/takt/today/activity_items.dart';
import 'package:openstrap_edge/takt/today/pulse_display.dart';
import 'package:openstrap_edge/takt/today/pulse_state.dart';
import 'package:openstrap_edge/takt/today/takt_today_screen.dart';
import 'package:openstrap_edge/takt/stress/day_stress.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';
import 'package:openstrap_edge/data/db.dart';
import 'package:openstrap_edge/takt/journal/journal_config.dart';
import 'package:openstrap_edge/takt/journal/journal_tab.dart';
import 'package:openstrap_edge/takt/journal/morning_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Metric m(num v) => Metric.parse({'value': v, 'unit': ''});

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    LocalDb.dbName = inMemoryDatabasePath;
    await LocalDb.instance;
  });

  final data = HomeData(
    readiness: m(62),
    strain: m(13.8),
    sleepMin: m(432),
    sleepNeedMin: m(480),
    rhr: m(54),
    steps: m(18412),
  );
  final items = [
    for (var i = 0; i < 3; i++)
      ActivityItem(
        id: 'w$i',
        startTs: DateTime(2026, 11, 6, 8 + i).millisecondsSinceEpoch ~/ 1000,
        type: 'running',
        detected: i == 0,
        durationMin: 84,
        avgHr: 148,
        strain: 11.2,
      ),
  ];
  final t0 = 1700000000;
  final stress = DayStressCalculator.compute(
    date: '2026-11-06',
    hrCurve: [
      for (var bin = 0; bin < 12; bin++)
        for (var i = 0; i < 4; i++) {'t': t0 + bin * 300 + i * 30, 'v': 60 + bin * 3},
    ],
    restingHr: 50.0,
    maxHr: 195.0,
  );

  for (final lang in ['de', 'en']) {
    for (final (w, s) in [(320.0, 1.3), (360.0, 1.3), (411.0, 1.0), (360.0, 2.0)]) {
      testWidgets('Heute ohne Overflow: $lang, ${w.toInt()} px, Schrift $s', (t) async {
        final lc = LocaleController.seed(lang);
        lc.useForPresentation();
        addTearDown(lc.dispose);
        t.view.physicalSize = Size(w, 2600);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(MaterialApp(
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(s)),
              child: child!),
          home: Scaffold(
            body: TaktTodayView(
              data: data,
              pulse: const PulseView(
                  state: PulseState(PulseKind.live, bpm: 72), trace: [70, 72, 74]),
              items: items,
              dayStress: stress,
              onStart: () {},
              onLog: () {},
              now: DateTime(2026, 11, 6, 14),
            ),
          ),
        ));
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        final e = t.takeException();
        expect(e, isNull, reason: e is FlutterError ? e.toStringDeep() : e?.toString());
      });

      testWidgets('MorningSheet ohne Overflow (J24): $lang, ${w.toInt()} px, Schrift $s', (t) async {
        final lc = LocaleController.seed(lang);
        lc.useForPresentation();
        addTearDown(lc.dispose);
        t.view.physicalSize = Size(w, 2600);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final config = JournalConfig(List.of(JournalConfig.standardQuestions));
        await t.pumpWidget(MaterialApp(
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(s)),
              child: child!),
          home: Scaffold(
            body: MorningSheet(
              config: config,
              calYesterday: '2026-11-11',
              calToday: '2026-11-12',
              initialYesterdayAnswers: const {'vitamin_d': 1.0},
              initialTodayAnswers: const {'feeling': 3.0},
              onSave: (y, t) async {},
              onDismiss: () async {},
            ),
          ),
        ));
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        final e = t.takeException();
        expect(e, isNull, reason: e is FlutterError ? e.toStringDeep() : e?.toString());
      });

      testWidgets('JournalTab ohne Overflow (J24): $lang, ${w.toInt()} px, Schrift $s', (t) async {
        final lc = LocaleController.seed(lang);
        lc.useForPresentation();
        addTearDown(lc.dispose);
        t.view.physicalSize = Size(w, 3000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        SharedPreferences.setMockInitialValues({});
        await t.pumpWidget(MaterialApp(
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(s)),
              child: child!),
          home: const Scaffold(
            body: SingleChildScrollView(child: JournalTab()),
          ),
        ));
        for (var i = 0; i < 10; i++) {
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
          await t.pump(const Duration(milliseconds: 30));
        }
        final e = t.takeException();
        expect(e, isNull, reason: e is FlutterError ? e.toStringDeep() : e?.toString());
      });
    }
  }
}
