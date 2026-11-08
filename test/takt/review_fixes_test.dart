// Befunde der unabhängigen Prüfung von 06 und 07 (pruefung.md).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/takt/detail/value_card.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/ui2/grammar.dart';
import 'package:openstrap_edge/ui2/screens/driver_breakdown.dart';
import 'package:openstrap_edge/ui2/screens/metric_detail.dart';
import 'package:openstrap_edge/ui2/screens/readiness_detail.dart';
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

import 'support/night_fixture.dart';

Future<void> pump(WidgetTester t, Widget w, {double h = 5200}) async {
  t.view.physicalSize = Size(390, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: TaktLook(child: w)),
  ));
  await t.pumpAndSettle();
}

bool dodged(WidgetTester t, Finder f) =>
    find.ancestor(of: f, matching: find.byType(StripeDodge)).evaluate().isNotEmpty;

List<({int t, double v})> pts(int n, double base) {
  final now = DateTime.now();
  return [
    for (var i = 0; i < n; i++)
      (
        t: DateTime(now.year, now.month, now.day - (n - 1 - i), 12).millisecondsSinceEpoch ~/ 1000,
        v: base + (i % 5) * 2.0,
      ),
  ];
}

void main() {
  testWidgets('F6: Hinweis zum Zeitraum ist einzeilig', (t) async {
    await pump(t, SleepDetail(embedded: true, data: sleepData(), head: (_) => const SizedBox()));
    final txt = t.widget<Text>(find.textContaining('automatisch'));
    expect(txt.maxLines, 1);
  });

  testWidgets('F7: jede Phase mit Anteil in Prozent', (t) async {
    await pump(t, SleepDetail(embedded: true, data: sleepData(), head: (_) => const SizedBox()));
    final card = find.byKey(const ValueKey('takt-phases'));
    // 90 + 95 + 220 + 53 = 458 Minuten: Tief 20 %, REM 21 %, Leicht 48 %, Wach 12 %.
    for (final s in ['20 %', '21 %', '48 %', '12 %']) {
      expect(find.descendant(of: card, matching: find.text(s)), findsOneWidget, reason: s);
    }
  });

  testWidgets('F8: zu wenige Nächte ist eine Zeile, keine Karte', (t) async {
    final d = SleepData(day: '2026-11-08', night: night(), tstHistory: const [400, 410, 420]);
    await pump(t, SleepDetail(embedded: true, data: d, head: (_) => const SizedBox()));
    expect(find.byType(StatusCard), findsNothing);
    final line = find.textContaining('3 von 7');
    expect(line, findsOneWidget);
    expect(dodged(t, line), isTrue);
  });

  testWidgets('F13: StatusCard im Takt-Teilbaum weicht mit allen Zeilen aus', (t) async {
    await pump(t, const StatusCard('Seit 3 Tagen', '2 Nächte fehlen', fix: '5 von 7'), h: 800);
    for (final s in ['Seit 3 Tagen', '2 Nächte fehlen', '5 von 7']) {
      expect(dodged(t, find.text(s)), isTrue, reason: s);
    }
  });

  testWidgets('Kontrast: Bahnnamen im Hypnogramm in Tinte, nicht in der Phasenfarbe', (t) async {
    await pump(t, SleepDetail(embedded: true, data: sleepData(), head: (_) => const SizedBox()));
    final p = P.of(t.element(find.byType(SleepDetail)));
    final wach = t.widgetList<Text>(find.text('Wach')).first;
    expect(wach.style?.color, isNot(const Color(0xFFF0560A)));
    expect(P.contrast(wach.style!.color!, p.card), greaterThanOrEqualTo(4.5));
  });

  testWidgets('H2: Band im Verlauf grau, nicht orange getönt', (t) async {
    await pump(t, MetricDetail('hrv', data: MetricData(series: pts(30, 60), daysAvailable: 30)),
        h: 2400);
    await t.tap(find.text('30 Tage'));
    await t.pumpAndSettle();
    // Ohne Basiswerte gibt es kein Band, die Farbe ist trotzdem gesetzt.
    final frames = t.widgetList<ChartFrame>(find.byType(ChartFrame)).where((f) => f.bandColor != null);
    expect(frames, isNotEmpty);
    final p = P.of(t.element(find.byType(MetricDetail)));
    for (final f in frames) {
      expect(f.bandColor, p.card2);
    }
  });

  testWidgets('H12: Tagesdurchschnitt bei 7 Tagen weicht aus', (t) async {
    await pump(t, MetricDetail('hrv', data: MetricData(series: pts(30, 60), daysAvailable: 30)),
        h: 2400);
    await t.tap(find.text('7 Tage'));
    await t.pumpAndSettle();
    final bare = <String>[];
    for (final p in t.allRenderObjects.whereType<RenderParagraph>()) {
      final s = p.text.toPlainText(includeSemanticsLabels: false);
      if (!RegExp(r'\d').hasMatch(s)) continue;
      RenderObject? o = p.parent;
      var ok = false;
      while (o != null) {
        if (o is RenderStripeDodge) {
          ok = true;
          break;
        }
        o = o.parent;
      }
      if (!ok) bare.add(s);
    }
    expect(bare, isEmpty, reason: bare.join('\n'));
  });

  testWidgets('H5: Schrittziel als Balken', (t) async {
    await pump(t, MetricDetail('steps', data: MetricData(series: pts(30, 8000), daysAvailable: 30)),
        h: 2400);
    expect(find.byKey(const ValueKey('takt-step-goal-bar')), findsOneWidget);
  });

  Future<void> readiness(WidgetTester t, {num? value}) async {
    final breakdown = [
      {'label': 'resp', 'used': false, 'weight': .15, 'note': 'need_baseline:have=2,need=7'},
    ];
    await pump(
        t,
        ReadinessDetail(
          data: ReadinessData(
            readiness: value == null ? Metric.empty : Metric.parse({'value': value, 'unit': '%'}),
            breakdown: breakdown,
            series: [for (var i = 0; i < 80; i++) 50.0 + i % 20],
          ),
          facts: driverFacts(breakdown: breakdown),
        ),
        h: 3000);
  }

  testWidgets('H10: fehlender Baustein auf Deutsch', (t) async {
    await readiness(t, value: 62);
    expect(find.text('Atmung'), findsOneWidget);
    expect(find.text('Breathing rate'), findsNothing);
    expect(find.textContaining('Need'), findsNothing);
  });

  testWidgets('H11: Verlauf zeigt höchstens 30 Tage', (t) async {
    await readiness(t, value: 62);
    expect(find.text('Letzte 30 Tage'), findsOneWidget);
  });

  testWidgets('H13: Erholung ohne Wert zeigt Strich und Grund in der Wert-Karte', (t) async {
    await readiness(t);
    expect(find.byType(TaktValueCard), findsOneWidget);
    expect(find.descendant(of: find.byType(TaktValueCard), matching: find.text('–')), findsOneWidget);
  });
}
