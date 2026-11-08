// Bildschirmfotos zum Ansehen beim Gestalten: TAKT_SHOTS=1 flutter test test/takt/shots_test.dart
// Ohne die Variable laufen die Screens nur durch (kein Überlauf, kein Fehler).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/sleep/sleep_head.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/ui2/activity/day_strain.dart';
import 'package:openstrap_edge/ui2/activity/summary.dart';
import 'package:openstrap_edge/ui2/screens/log_workout.dart';
import 'package:openstrap_edge/ui2/screens/driver_breakdown.dart';
import 'package:openstrap_edge/ui2/screens/metric_detail.dart';
import 'package:openstrap_edge/ui2/screens/readiness_detail.dart';
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

import 'sleep_head_test.dart' show view;
import 'support/night_fixture.dart';
import 'support/shot.dart';
import 'support/workout_fixture.dart';

Widget app(Widget home) => MaterialApp(
      theme: buildTheme(Brightness.light),
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: RepaintBoundary(child: home),
    );

void main() {
  setUpAll(loadRealFonts);

  testWidgets('Schlaf-Tab ganz', (t) async {
    t.view.physicalSize = const Size(390, 4600);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.alwaysUse24HourFormatTestValue = true;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearAlwaysUse24HourTestValue);
    await t.pumpWidget(app(Scaffold(
      body: TaktLook(child: SleepDetail(
        embedded: true,
        data: sleepData(),
        head: (_) => TaktSleepHead(view: view),
      )),
    )));
    await t.pumpAndSettle();
    await shot(t, find.byType(SleepDetail), 'schlaf_tab');
  });

  Future<void> detail(WidgetTester t, Widget w, String name) async {
    t.view.physicalSize = const Size(390, 2200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(TaktLook(child: w)));
    await t.pumpAndSettle();
    await shot(t, find.byType(Scaffold).first, name);
  }

  testWidgets('Detailscreens', (t) async {
    final now = DateTime.now();
    List<({int t, double v})> pts(int n, double base) => [
          for (var i = 0; i < n; i++)
            (
              t: DateTime(now.year, now.month, now.day - (n - 1 - i), 12).millisecondsSinceEpoch ~/ 1000,
              v: base + (i % 5) * 2.0,
            ),
        ];
    await detail(t, MetricDetail('hrv', data: MetricData(series: pts(30, 60), daysAvailable: 30)), 'hrv');
    final day = DateTime(now.year, now.month, now.day);
    final start = day.add(const Duration(hours: 17)).millisecondsSinceEpoch ~/ 1000;
    await detail(
        t,
        DayStrainDetail(
          data: DayStrainData(
              day: day,
              curve: [for (var i = 0; i < 96; i++) i < 68 ? i * .1 : 6.8 + (i - 68) * .2],
              strain: 12.4,
              zoneMin: const [120, 60, 25, 10, 2],
              peakHr: 171,
              wornMin: 900),
          acts: [(start, start + 84 * 60)],
        ),
        'strain');
    final breakdown = [
      {'label': 'hrv', 'used': true, 'weight': .4, 'weighted_contribution': -6.2, 'past_mdc': true},
      {'label': 'rhr', 'used': true, 'weight': .3, 'weighted_contribution': 3.1, 'past_mdc': false},
      {'label': 'resp', 'used': false, 'weight': .15, 'note': 'need_baseline:have=2,need=7'},
    ];
    await detail(
        t,
        ReadinessDetail(
          data: ReadinessData(
            readiness: Metric.parse({'value': 62, 'unit': '%'}),
            breakdown: breakdown,
            inputsUsed: 2,
            series: [for (var i = 0; i < 20; i++) 40.0 + (i * 7) % 50],
          ),
          facts: driverFacts(breakdown: breakdown, baselines: const {
            'hrv': {'value': 41.2, 'baseline': 58.4, 'spread': 6.1, 'delta': -17.2},
            'resting_hr': {'value': 54.0, 'baseline': 53.0, 'spread': 2.0, 'delta': 1.0},
          }),
        ),
        'erholung');
  });

  testWidgets('Training und Nachtragen (Feature 08)', (t) async {
    t.platformDispatcher.alwaysUse24HourFormatTestValue = true;
    addTearDown(t.platformDispatcher.clearAlwaysUse24HourTestValue);
    await detail(t, ActivitySummary(handball(), weightKg: 75), 'training');
    await detail(t, LogWorkout(spans: const [], now: DateTime(2026, 11, 8, 18, 30)), 'nachtragen');
  });
}
