// Feature 04: Batterie statt Erholung.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/takt/battery/battery.dart';
import 'package:openstrap_edge/takt/battery/battery_detail.dart';
import 'package:openstrap_edge/takt/battery/battery_week.dart';
import 'package:openstrap_edge/takt/detail/value_card.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/takt/today/dial_ring.dart';
import 'package:openstrap_edge/takt/today/pulse_display.dart';
import 'package:openstrap_edge/takt/today/pulse_state.dart';
import 'package:openstrap_edge/takt/today/takt_today_screen.dart';
import 'package:openstrap_edge/ui2/charts.dart' show LineChart;
import 'package:openstrap_edge/ui2/screens/home_screen.dart';
import 'package:openstrap_edge/ui2/screens/readiness_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

import 'support/shot.dart' show loadRealFonts;

Metric m(num v) => Metric.parse({'value': v, 'unit': ''});
Finder _key(String k) => find.byKey(ValueKey(k));
int sec(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

const livePulse = PulseView(state: PulseState(PulseKind.live, bpm: 72), trace: [70, 72]);

Future<void> pump(WidgetTester t, Widget w, {double width = 390, double scale = 1}) async {
  t.view.physicalSize = Size(width, 2000);
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: TaktLook(child: Scaffold(body: w)),
  ));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadRealFonts);

  group('Rechnung', () {
    test('D1: ohne Belastung bleibt die Ladung vom Morgen', () {
      expect(batteryLeft(78, 0), 78);
    });

    test('D2: sanftere Kurve, Beispiele aus der Spec', () {
      expect(batteryLeft(78, 6), 66);
      expect(batteryLeft(78, 14), 36);
      expect(batteryLeft(78, 16), 26);
      expect(batteryLeft(78, 21), 0);
      expect(batteryLeft(78, 25), 0, reason: 'über 21 bleibt leer');
    });

    test('Randfall: ohne Strain bleibt die Ladung stehen', () {
      expect(batteryLeft(78, null), 78);
    });

    test('D4: Kurve pro Minute aus der Strain-Kurve, Lücken bleiben Lücken', () {
      expect(batteryCurve(78, [0, null, 6, 14]), [78, null, 66, 36]);
    });

    test('D6, D7: sieben Tage aus den Verläufen, heute aus den frischen Werten', () {
      final today = DateTime(2026, 11, 9);
      ({int t, double v}) pt(int daysAgo, double v) =>
          (t: sec(DateTime(2026, 11, 9 - daysAgo, 7)), v: v);
      final week = batteryWeek(
        recovery: [pt(6, 80), pt(5, 70), pt(3, 50), pt(1, 78)],
        strain: [pt(6, 6), pt(5, 16), pt(3, 18), pt(1, 14), pt(0, 3)],
        today: today,
        todayMorning: 62,
        todayStrain: 13.8,
      );
      expect(week.length, 7);
      expect(week.first.day, DateTime(2026, 11, 3));
      expect(week.last.day, today);
      expect(week[0].left, batteryLeft(80, 6));
      expect(week[2].morning, isNull, reason: 'ohne Erholung leer');
      expect(week[2].left, isNull);
      expect(week[3].over, isTrue, reason: '50 % und Strain 18: unter 20 %');
      expect(week[1].over, isFalse);
      expect(week[6].left, batteryLeft(62, 13.8));
    });
  });

  group('Ring', () {
    final full = HomeData(readiness: m(62), strain: m(13.8), sleepMin: m(432), sleepNeedMin: m(480));

    testWidgets('D3: erster Ring heißt Batterie, zeigt den Stand und die Ladung vom Morgen',
        (t) async {
      await pump(t, TaktTodayView(data: full, pulse: livePulse));
      final first = find.byType(DialRing).first;
      expect(find.descendant(of: first, matching: find.text('Batterie')), findsOneWidget);
      expect(find.descendant(of: first, matching: find.text('${batteryLeft(62, 13.8)}')),
          findsOneWidget);
      expect(find.descendant(of: first, matching: find.text('von 62 %')), findsOneWidget);
      expect(find.text('Erholung'), findsNothing);
    });

    testWidgets('D5: ohne Erholung Strich und der Grund des Erholungsrings', (t) async {
      const d = HomeData(strain: Metric.empty);
      await pump(t, TaktTodayView(data: d, pulse: livePulse));
      final first = find.byType(DialRing).first;
      final base =
          ringViewOf(HomeRingKind.recovery, d, AppLocalizations.of(t.element(first)));
      expect(find.descendant(of: first, matching: find.text('Batterie')), findsOneWidget);
      expect(find.descendant(of: first, matching: find.text(dialCenter(base))), findsOneWidget);
    });

    testWidgets('Randfall: ohne Strain voll und der Hinweis', (t) async {
      await pump(t, TaktTodayView(data: HomeData(readiness: m(70)), pulse: livePulse));
      final first = find.byType(DialRing).first;
      expect(find.descendant(of: first, matching: find.text('70')), findsOneWidget);
      expect(find.text('Belastung noch nicht berechnet'), findsOneWidget);
    });

    testWidgets('D4: der Ring öffnet die Batterie', (t) async {
      expect(taktRingTarget(HomeRingKind.recovery), isA<BatteryDetail>());
    });
  });

  group('Detail', () {
    final now = DateTime(2026, 11, 9, 18, 30);
    BatteryDetailData data({double? strain = 11.0, double? morning = 78}) => BatteryDetailData(
          morning: morning,
          strain: strain,
          strainCurve: [for (var i = 0; i < 1440; i++) i < 7 * 60 ? null : (i > 18 * 60 + 30 ? null : (i - 420) / 60)],
          now: now,
        );

    testWidgets('D4: Wertkarte, Kurve über den Tag, Rechnung, Weg zur Erholung', (t) async {
      await pump(t, BatteryDetail(data: data()));
      expect(find.text('batterie'), findsOneWidget);
      final card = find.byType(TaktValueCard);
      expect(find.descendant(of: card, matching: find.text('${batteryLeft(78, 11)}')),
          findsOneWidget);
      expect(find.descendant(of: card, matching: find.text('von 78 % am Morgen')), findsOneWidget);
      final line = t
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((c) => c.painter)
          .whereType<LineChart>()
          .single;
      expect(line.d.length, 1440);
      expect(line.d[7 * 60], 78);
      expect(line.d[6 * 60], isNull);
      expect(_key('takt-battery-rule'), findsOneWidget);
      await t.tap(_key('takt-battery-why'));
      await t.pumpAndSettle();
      expect(find.byType(ReadinessDetail), findsOneWidget);
    });

    testWidgets('D5: ohne Erholung Strich und Grund', (t) async {
      await pump(t, BatteryDetail(data: data(morning: null).copyWith(why: 'Noch keine Nacht.')));
      final card = find.byType(TaktValueCard);
      expect(find.descendant(of: card, matching: find.text('–')), findsOneWidget);
      expect(find.text('Noch keine Nacht.'), findsOneWidget);
    });

    testWidgets('Randfall: ohne Strain der Hinweis im Detail', (t) async {
      await pump(t, BatteryDetail(data: data(strain: null)));
      expect(find.text('Belastung noch nicht berechnet'), findsOneWidget);
    });
  });

  group('Woche', () {
    final today = DateTime(2026, 11, 9);
    List<BatteryDay> week() => [
          for (var i = 0; i < 7; i++)
            BatteryDay(
              day: DateTime(2026, 11, 3 + i),
              morning: i == 2 ? null : 60.0 + i * 3,
              strain: i == 3 ? 19 : 8.0 + i,
            ),
        ];

    testWidgets('D6: sieben Säulen mit Rest, Wochentag, heute hervorgehoben', (t) async {
      await pump(t, TaktBatteryWeek(days: week(), today: today));
      for (var i = 0; i < 7; i++) {
        expect(_key('takt-battery-day-$i'), findsOneWidget);
      }
      final w = week();
      expect(find.descendant(of: _key('takt-battery-day-0'), matching: find.text('${w[0].left}')),
          findsOneWidget);
      expect(find.descendant(of: _key('takt-battery-day-2'), matching: find.text('–')),
          findsOneWidget);
      expect(find.descendant(of: _key('takt-battery-day-6'), matching: find.text('Mo')),
          findsOneWidget);
      final todayLabel = t.widget<Text>(
          find.descendant(of: _key('takt-battery-day-6'), matching: find.text('Mo')));
      final otherLabel = t.widget<Text>(
          find.descendant(of: _key('takt-battery-day-5'), matching: find.text('So')));
      expect(todayLabel.style?.fontWeight, isNot(otherLabel.style?.fontWeight));
    });

    testWidgets('D7: zu viel gemacht ist markiert und benannt', (t) async {
      await pump(t, TaktBatteryWeek(days: week(), today: today));
      expect(week()[3].over, isTrue);
      expect(_key('takt-battery-over-3'), findsOneWidget);
      expect(_key('takt-battery-over-1'), findsNothing);
      expect(find.textContaining('Mehr belastet als erholt'), findsOneWidget);
      expect(find.textContaining('Fr'), findsWidgets);
    });

    testWidgets('D8: alle Ziffern weichen dem Displaystreifen aus', (t) async {
      await pump(t, TaktBatteryWeek(days: week(), today: today));
      for (var i = 0; i < 7; i++) {
        final n = find.descendant(of: _key('takt-battery-day-$i'), matching: find.byType(Text)).first;
        expect(find.ancestor(of: n, matching: find.byType(StripeDodge)), findsWidgets,
            reason: 'Tag $i');
      }
    });

    testWidgets('D6: auf Heute unter den Karten, bei 320 px und Schrift 2,0 ohne Überlauf',
        (t) async {
      final full = HomeData(readiness: m(62), strain: m(13.8));
      await pump(t, TaktTodayView(data: full, pulse: livePulse, week: week()),
          width: 320, scale: 2.0);
      expect(_key('takt-battery-week'), findsOneWidget);
      expect(t.getTopLeft(_key('takt-battery-week')).dy,
          greaterThan(t.getTopLeft(_key('takt-cards')).dy));
      expect(t.takeException(), isNull);
    });

    testWidgets('ohne Verlauf keine Wochenkarte', (t) async {
      await pump(t, TaktTodayView(data: HomeData(readiness: m(62)), pulse: livePulse));
      expect(_key('takt-battery-week'), findsNothing);
    });
  });
}
