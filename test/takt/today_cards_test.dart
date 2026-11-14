// Felix' Gerätetest von 0.2.0: Auf Heute stand bei HRV und Ruhepuls nur ein
// Strich, obwohl die Detailansicht einen Wert hatte, und „von 21“ unter dem
// Strain wirkte falsch.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/l10n/decimal_text.dart' show displayFixed;
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/takt/today/pulse_display.dart';
import 'package:openstrap_edge/takt/today/pulse_state.dart';
import 'package:openstrap_edge/takt/today/takt_today_screen.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';

Metric m(num v) => Metric.parse({'value': v, 'unit': ''});

const pulse = PulseView(state: PulseState(PulseKind.live, bpm: 72), trace: [70, 72]);
final now = DateTime(2026, 11, 8, 14, 0);
int noon(int d) => DateTime(2026, 11, d, 12).millisecondsSinceEpoch ~/ 1000;

Future<void> pump(WidgetTester t, Widget w) async {
  t.view.physicalSize = const Size(390, 1400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: w),
  ));
  await t.pump();
}

void main() {
  testWidgets('G1: unter dem Strain steht nur die Zahl, ohne „von 21“ und ohne Stufe',
      (t) async {
    await pump(t, TaktTodayView(data: HomeData(strain: m(12.4)), pulse: pulse, now: now));
    expect(find.text('12.4'), findsOneWidget);
    expect(find.text('mittel'), findsNothing);
    expect(find.text('von 21'), findsNothing);
    expect(find.text('of 21'), findsNothing);
  });

  testWidgets('G2: ohne heutige Nacht zeigen HRV und Ruhepuls den letzten Wert mit Tag',
      (t) async {
    await pump(
      t,
      TaktTodayView(
        data: const HomeData(),
        pulse: pulse,
        now: now,
        hrvLast: (t: noon(7), v: 61.4),
        rhrLast: (t: noon(5), v: 53.6),
      ),
    );
    expect(find.text('61 ms'), findsOneWidget);
    expect(find.text('HRV, gestern'), findsOneWidget);
    expect(find.text('54'), findsOneWidget);
    expect(find.text('Ruhepuls, Do'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('takt-cards')), matching: find.text('–')),
        findsOneWidget,
        reason: 'nur Schritte fehlen');
  });

  testWidgets('G3: mit heutiger Nacht gilt der heutige Wert ohne Tag', (t) async {
    await pump(
      t,
      TaktTodayView(
        data: HomeData(rhr: m(51)),
        hrv: Metric.parse({'value': 66, 'unit': 'ms'}),
        pulse: pulse,
        now: now,
        hrvLast: (t: noon(7), v: 61.4),
        rhrLast: (t: noon(7), v: 53.6),
      ),
    );
    expect(find.text('66 ms'), findsOneWidget);
    expect(find.text('HRV'), findsOneWidget);
    expect(find.text('51'), findsOneWidget);
    expect(find.text('Ruhepuls'), findsOneWidget);
  });

  testWidgets('G2: ein Wert von heute bekommt keinen Tag', (t) async {
    await pump(
      t,
      TaktTodayView(
        data: const HomeData(),
        pulse: pulse,
        now: now,
        hrvLast: (t: noon(8), v: 58),
      ),
    );
    expect(find.text('58 ms'), findsOneWidget);
    expect(find.text('HRV'), findsOneWidget);
  });

  testWidgets('Gerätetest 0.5.1: HRV, Ruhepuls und Schritte sind groß (32 pt)', (t) async {
    await pump(
      t,
      TaktTodayView(
        data: HomeData(rhr: m(51), steps: m(9876)),
        hrv: Metric.parse({'value': 66, 'unit': 'ms'}),
        pulse: pulse,
        now: now,
      ),
    );
    final cards = find.byKey(const ValueKey('takt-cards'));
    for (final v in ['66 ms', '51', displayFixed(9876, 0)]) {
      final text = find.descendant(of: cards, matching: find.text(v));
      expect(text, findsOneWidget, reason: v);
      expect(t.widget<Text>(text).style?.fontSize, greaterThanOrEqualTo(32), reason: v);
    }
  });
}
