// Feature 06, F13: Im ganzen Schlaf-Tab steht jede Zahl in einer Hülle, und
// für Streifen quer über die Breite liegt keine Ziffer darauf.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/sleep/sleep_head.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

import 'sleep_head_test.dart' show view;
import 'support/night_fixture.dart';

bool _hasDigit(RenderParagraph p) =>
    RegExp(r'\d').hasMatch(p.text.toPlainText(includeSemanticsLabels: false));

Future<void> pump(WidgetTester t, {SleepData? data}) async {
  t.view.physicalSize = const Size(390, 7000);
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.alwaysUse24HourFormatTestValue = true;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearAlwaysUse24HourTestValue);
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
        body: TaktLook(
            child: SleepDetail(
                embedded: true,
                data: data ?? sleepData(),
                head: (_) => TaktSleepHead(view: view)))),
  ));
  await t.pumpAndSettle();
}

void main() {
  tearDown(() => TaktStripe.fraction.value = null);

  testWidgets('F13: jede Zahl im Schlaf-Tab steht in einer Hülle', (t) async {
    TaktStripe.fraction.value = 0.72;
    await pump(t);
    final bare = <String>[];
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
      if (!wrapped) bare.add(p.text.toPlainText());
    }
    expect(bare, isEmpty, reason: bare.join('\n'));
  });

  testWidgets('F13: für Streifen quer über die Breite liegt keine Ziffer darauf', (t) async {
    await pump(t);
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
  });

  testWidgets('F13: auch die selbst gesetzte Nacht mit Einschlafdauer', (t) async {
    TaktStripe.fraction.value = 0.72;
    final d = sleepData();
    final n = {...d.night, 'sleep_source': 'confirmed'};
    await pump(t,
        data: SleepData(
            day: d.day, latestDay: d.latestDay, days: d.days, night: n, solMin: 22,
            timeline: d.timeline, tstHistory: d.tstHistory));
    final bare = <String>[];
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
      if (!wrapped) bare.add(p.text.toPlainText());
    }
    expect(bare, isEmpty, reason: bare.join('\n'));
  });
}
