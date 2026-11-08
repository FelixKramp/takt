// Feature 06, F3, F4, F7: Hypnogramm in Takt-Farben, Zeitpunkt mit
// Punktziffern, Phasen als durchgehender Balken mit vier Zeilen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/ui2/charts.dart';
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

import 'support/night_fixture.dart';

Future<void> pump(WidgetTester t, {bool takt = true}) async {
  t.view.physicalSize = const Size(390, 3000);
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.alwaysUse24HourFormatTestValue = true;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearAlwaysUse24HourTestValue);
  final w = SleepDetail(embedded: true, data: sleepData(), head: (_) => const SizedBox());
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: takt ? TaktLook(child: w) : w),
  ));
  await t.pumpAndSettle();
}

void main() {
  test('F3: Takt-Farben der Phasen, Tief dunkel, Wach orange', () {
    const p = P(false);
    final k = Hypnogram.cols(p, takt: true);
    expect(k[SleepStage.deep], p.ink);
    expect(k[SleepStage.awake], const Color(0xFFF0560A));
    double lum(Color c) => c.computeLuminance();
    expect(lum(k[SleepStage.deep]!), lessThan(lum(k[SleepStage.rem]!)));
    expect(lum(k[SleepStage.rem]!), lessThan(lum(k[SleepStage.light]!)));
    expect(Hypnogram.cols(p), isNot(equals(k)), reason: 'ohne Takt bleibt OpenStrap');
  });

  testWidgets('F3: Hypnogramm im Takt-Teilbaum zeichnet mit Takt-Farben', (t) async {
    await pump(t);
    final painters = t
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((c) => c.painter)
        .whereType<Hypnogram>();
    expect(painters, isNotEmpty);
    expect(painters.every((h) => h.takt), isTrue);
    expect(find.text('Die Nacht'), findsOneWidget);
  });

  testWidgets('F7: Phasen als Balken mit vier Segmenten und vier Zeilen', (t) async {
    await pump(t);
    final bar = find.byKey(const ValueKey('takt-phase-bar'));
    expect(bar, findsOneWidget);
    expect(
        find.descendant(
            of: bar,
            matching: find.byWidgetPredicate((w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('takt-phase-seg'))),
        findsNWidgets(4));
    for (final s in ['Tief', 'REM', 'Leicht', 'Wach']) {
      expect(find.descendant(of: find.byKey(const ValueKey('takt-phases')), matching: find.text(s)),
          findsOneWidget, reason: s);
    }
    expect(find.text('53m'), findsOneWidget, reason: 'Wach nur in den Phasen, nicht neben den Bahnen');
    final v = t.widget<Text>(find.text('53m'));
    expect(v.style?.fontFamily, 'Doto');
  });

  testWidgets('F4: Zeitpunkt antippen zeigt Uhrzeit und Werte in Punktziffern', (t) async {
    await pump(t);
    final plot = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is Hypnogram);
    await t.tapAt(t.getCenter(plot.first));
    await t.pumpAndSettle();
    // Die Karte steht unter dem Hypnogramm und, verknüpft, unter den Signalen.
    final clock = find.byKey(const ValueKey('takt-scrub-clock')).first;
    expect(find.byKey(const ValueKey('takt-scrub-clock')), findsWidgets);
    expect(t.widget<Text>(clock).style?.fontFamily, 'Doto');
    expect(find.ancestor(of: clock, matching: find.byType(StripeDodge)), findsOneWidget);
  });
}
