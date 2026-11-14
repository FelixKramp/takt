// Gegen deine Nächte: kein Overflow, auch auf schmalem Display und bei
// vergrößerter Schrift (Gerätetest 0.5.1: Overflow in diesem Abschnitt).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/state/locale_controller.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

import 'support/night_fixture.dart';

Future<void> pump(WidgetTester t, SleepData d, double width, double scale, String lang) async {
  t.view.physicalSize = Size(width, 5200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    locale: Locale(lang),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)), child: w!),
    home: Scaffold(
        body: TaktLook(
            child: SleepDetail(embedded: true, data: d, head: (_) => const SizedBox()))),
  ));
  await t.pumpAndSettle();
}

void main() {
  for (final lang in ['de', 'en']) {
    for (final (w, s) in [(360.0, 1.0), (411.0, 1.0), (360.0, 1.3), (320.0, 1.15)]) {
      testWidgets('Vergleich ohne Overflow: $lang, ${w.toInt()} px, Schrift $s', (t) async {
        // Wie auf dem Handy: Dauern in der App-Sprache („1 Std. 03 Min.“ ist
        // deutlich breiter als „1h 3m“). Gerätetest 0.5.1: Die Spanne beim
        // Tiefschlaf drückte das Label auf ein Zeichen Breite zusammen.
        final lc = LocaleController.seed(lang);
        lc.useForPresentation();
        addTearDown(lc.dispose);
        await pump(t, sleepData(), w, s, lang);
        final e = t.takeException();
        expect(e, isNull, reason: e is FlutterError ? e.toStringDeep() : e?.toString());
      });
    }
  }

  testWidgets('Spannen stehen kompakt („1:03–2:45 Std.“), nicht als lange Wörterkette', (t) async {
    final lc = LocaleController.seed('de');
    lc.useForPresentation();
    addTearDown(lc.dispose);
    await pump(t, sleepData(), 360, 1.0, 'de');
    final range = RegExp(r'^\d+:\d\d–\d+:\d\d Std\.$');
    final hits = t
        .widgetList<Text>(find.byType(Text))
        .where((w) => range.hasMatch(w.data ?? ''))
        .toList();
    // Tiefschlaf im Vergleich, dazu REM, Leicht, Tief in „Die Nacht“.
    expect(hits.length, greaterThanOrEqualTo(2));
    expect(find.textContaining('Std. 0'), findsNothing,
        reason: 'keine ausgeschriebene Spanne wie „1 Std. 03 Min.–2 Std. 45 Min.“');
  });
}
