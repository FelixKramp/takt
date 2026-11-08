// Feature 07, H12: In jedem Detailscreen steht jede Zahl in einer Hülle.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/ui2/activity/day_strain.dart';
import 'package:openstrap_edge/ui2/screens/driver_breakdown.dart';
import 'package:openstrap_edge/ui2/screens/metric_detail.dart';
import 'package:openstrap_edge/ui2/screens/readiness_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

bool _hasDigit(RenderParagraph p) =>
    RegExp(r'\d').hasMatch(p.text.toPlainText(includeSemanticsLabels: false));

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

Future<List<String>> bare(WidgetTester t, Widget screen) async {
  t.view.physicalSize = const Size(390, 4000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  TaktStripe.fraction.value = .72;
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: TaktLook(child: screen),
  ));
  await t.pumpAndSettle();
  final out = <String>[];
  for (final p in t.allRenderObjects.whereType<RenderParagraph>().where(_hasDigit)) {
    RenderObject? o = p.parent;
    var wrapped = false;
    while (o != null) {
      if (o is RenderStripeDodge) {
        wrapped = true;
        break;
      }
      o = o.parent;
    }
    if (!wrapped) out.add(p.text.toPlainText());
  }
  return out;
}

void main() {
  tearDown(() => TaktStripe.fraction.value = null);

  for (final key in ['hrv', 'resting_hr', 'steps']) {
    testWidgets('H12: $key', (t) async {
      final b = await bare(
          t, MetricDetail(key, data: MetricData(series: pts(30, 60), daysAvailable: 30)));
      expect(b, isEmpty, reason: b.join('\n'));
    });
  }

  testWidgets('H12: strain', (t) async {
    final now = DateTime.now();
    final b = await bare(
        t,
        DayStrainDetail(
            data: DayStrainData(
                day: DateTime(now.year, now.month, now.day),
                curve: [for (var i = 0; i < 96; i++) i * .13],
                strain: 12.4,
                zoneMin: const [120, 60, 25, 10, 2],
                peakHr: 171,
                wornMin: 900)));
    expect(b, isEmpty, reason: b.join('\n'));
  });

  testWidgets('H12: erholung', (t) async {
    final breakdown = [
      {'label': 'hrv', 'used': true, 'weight': .4, 'weighted_contribution': -6.2, 'past_mdc': true},
    ];
    final b = await bare(
        t,
        ReadinessDetail(
          data: ReadinessData(
            readiness: Metric.parse({'value': 62, 'unit': '%'}),
            breakdown: breakdown,
            inputsUsed: 1,
            series: [for (var i = 0; i < 20; i++) 50.0 + i],
          ),
          facts: driverFacts(breakdown: breakdown, baselines: const {
            'hrv': {'value': 41.2, 'baseline': 58.4, 'spread': 6.1, 'delta': -17.2},
          }),
        ));
    expect(b, isEmpty, reason: b.join('\n'));
  });

  testWidgets('H12: für Streifen quer über die Breite liegt keine Ziffer darauf', (t) async {
    final now = DateTime.now();
    for (final screen in <Widget>[
      MetricDetail('hrv', data: MetricData(series: pts(30, 60), daysAvailable: 30)),
      DayStrainDetail(
          data: DayStrainData(
              day: DateTime(now.year, now.month, now.day),
              curve: [for (var i = 0; i < 96; i++) i * .13],
              strain: 12.4,
              zoneMin: const [120, 60, 25, 10, 2],
              peakHr: 171,
              wornMin: 900)),
    ]) {
      await bare(t, screen);
      for (var f = 0.05; f < 0.96; f += 0.05) {
        TaktStripe.fraction.value = f;
        await t.pump();
        final x = f * 390;
        for (final h in t.allRenderObjects.whereType<RenderStripeDodge>()) {
          for (final r in h.paintedDigitRects()) {
            final hit = r.right > x - kStripeGap + 0.01 && r.left < x + kStripeGap - 0.01;
            expect(hit, isFalse, reason: 'Streifen bei ${x.toStringAsFixed(1)}: Ziffer $r');
          }
        }
      }
    }
  });
}
