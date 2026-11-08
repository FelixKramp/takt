// Feature 02 auf dem Heute-Screen: Für Streifen quer über die ganze Breite
// liegt keine Ziffer darauf, und jede Zahl steht in einer Hülle (B2, B5).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/takt/today/activity_items.dart';
import 'package:openstrap_edge/takt/today/pulse_display.dart';
import 'package:openstrap_edge/takt/today/pulse_state.dart';
import 'package:openstrap_edge/takt/today/takt_today_screen.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';

Metric m(num v) => Metric.parse({'value': v, 'unit': ''});

final data = HomeData(
  readiness: m(62),
  strain: m(13.8),
  sleepMin: m(432),
  sleepNeedMin: m(480),
  rhr: m(54),
  steps: m(1468),
);

ActivityItem item(String id, int h) => ActivityItem(
      id: id,
      startTs: DateTime(2026, 11, 8, h).millisecondsSinceEpoch ~/ 1000,
      type: 'running',
      detected: true,
      durationMin: 84,
      avgHr: 148,
      strain: 11.2,
    );

final now = DateTime(2026, 11, 8, 18, 30);

Widget view() => MaterialApp(
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: TaktTodayView(
          data: data,
          pulse: const PulseView(
              state: PulseState(PulseKind.live, bpm: 72), trace: [70, 72, 74, 72]),
          items: [for (var h = 8; h < 17; h++) item('a$h', h)],
          lastData: now.subtract(const Duration(minutes: 7)),
          now: now,
          onDiscard: (_) {},
        ),
      ),
    );

bool _hasDigit(RenderParagraph p) =>
    RegExp(r'\d').hasMatch(p.text.toPlainText(includeSemanticsLabels: false));

void main() {
  tearDown(() => TaktStripe.fraction.value = null);

  Future<void> pump(WidgetTester t, {double height = 2400}) async {
    // Hoch genug, dass die ganze Liste gebaut und gezeichnet wird.
    t.view.physicalSize = Size(390, height);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(view());
    await t.pump();
  }

  testWidgets('B5: jede Zahl auf dem Heute-Screen steht in einer Hülle', (t) async {
    TaktStripe.fraction.value = 0.72;
    await pump(t);
    final paragraphs = t.allRenderObjects.whereType<RenderParagraph>().where(_hasDigit).toList();
    expect(paragraphs, isNotEmpty);
    for (final p in paragraphs) {
      RenderObject? o = p.parent;
      var wrapped = false;
      while (o != null) {
        if (o is RenderStripeDodge) {
          wrapped = true;
          break;
        }
        o = o.parent;
      }
      expect(wrapped, isTrue,
          reason: '"${p.text.toPlainText()}" steht ohne StripeDodge');
    }
  });

  testWidgets('B2: für Streifen quer über die Breite liegt keine Ziffer darauf', (t) async {
    await pump(t);
    for (var f = 0.05; f < 0.96; f += 0.025) {
      TaktStripe.fraction.value = f;
      await t.pump();
      final x = f * 390;
      final hulls = t.allRenderObjects.whereType<RenderStripeDodge>().toList();
      expect(hulls, isNotEmpty);
      var digits = 0;
      for (final h in hulls) {
        for (final r in h.paintedDigitRects()) {
          digits++;
          final hit = r.right > x - kStripeGap + 0.01 && r.left < x + kStripeGap - 0.01;
          expect(hit, isFalse, reason: 'Streifen bei ${x.toStringAsFixed(1)}: Ziffer $r');
        }
      }
      expect(digits, greaterThan(20));
    }
  });

  testWidgets('B2: bei 72 % ist die Schrittzahl ganz zu sehen', (t) async {
    TaktStripe.fraction.value = 0.72;
    await pump(t, height: 844);
    final steps = t.renderObject<RenderStripeDodge>(find.ancestor(
      of: find.text('1468'),
      matching: find.byType(StripeDodge),
    ).first);
    expect(steps.paintedDigitRects(), hasLength(4));
  });

  testWidgets('B3/B2: auch bei großer Schrift keine Ziffer auf dem Streifen', (t) async {
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(t, height: 4000);
    for (final f in [0.3, 0.5, 0.72, 0.9]) {
      TaktStripe.fraction.value = f;
      await t.pump();
      final x = f * 390;
      for (final h in t.allRenderObjects.whereType<RenderStripeDodge>()) {
        for (final r in h.paintedDigitRects()) {
          final hit = r.right > x - kStripeGap + 0.01 && r.left < x + kStripeGap - 0.01;
          expect(hit, isFalse, reason: 'Streifen bei $x: Ziffer $r');
        }
      }
    }
  });
}
