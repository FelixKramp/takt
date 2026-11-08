// Feature 06, F8 und F9: Vergleich mit den eigenen Nächten als Zeilen mit
// grauem Band und Punkt, Auffälliges als Karte mit orangem Rand links.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/ui2/grammar.dart' show Surface, InsightCard;
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

import 'support/night_fixture.dart';

Future<void> pump(WidgetTester t, SleepData d) async {
  t.view.physicalSize = const Size(390, 5200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
        body: TaktLook(
            child: SleepDetail(embedded: true, data: d, head: (_) => const SizedBox()))),
  ));
  await t.pumpAndSettle();
}

Color dotColor(WidgetTester t, int i) => (t
        .widget<Container>(find.byKey(ValueKey('takt-compare-dot-$i')))
        .decoration! as BoxDecoration)
    .color!;

void main() {
  testWidgets('F8: Gegen deine Nächte, je Frage Wert, graues Band, Punkt, Satz', (t) async {
    await pump(t, sleepData());
    expect(find.text('Gegen deine Nächte'), findsOneWidget);
    expect(find.text('Im Vergleich zu sonst'), findsNothing);
    expect(find.byKey(const ValueKey('takt-compare-band-0')), findsOneWidget);
    // Die Nacht war kürzer als üblich: Punkt orange.
    expect(dotColor(t, 0), const Color(0xFFF0560A));
    expect(find.textContaining('kürzer als üblich'), findsWidgets);
    final v = t.widget<Text>(find.text('7h 12m').first);
    expect(v.style?.fontFamily, 'Doto');
  });

  testWidgets('F9: Auffälliges als Karte mit orangem Rand links, ohne Farbfläche', (t) async {
    await pump(t, sleepData(elevated: true));
    final card = find.ancestor(
        of: find.text('Erhöhte Herzfrequenz im Schlaf'), matching: find.byType(InsightCard));
    final edge = t.widget<Container>(
        find.descendant(of: card, matching: find.byKey(const ValueKey('takt-insight-edge'))));
    expect(edge.constraints?.maxWidth ?? 4, 4);
    expect(edge.color, const Color(0xFFF0560A));
    final box = t
        .widgetList<Container>(find.descendant(of: card, matching: find.byType(Container)))
        .first
        .decoration! as BoxDecoration;
    expect(box.color, P.of(t.element(card)).card);
  });

  testWidgets('F9: nichts aufgefallen ist eine Zeile, keine Karte', (t) async {
    await pump(t, sleepData(elevated: false, calm: true));
    final line = find.textContaining('Nichts');
    expect(line, findsOneWidget);
    expect(find.ancestor(of: line, matching: find.byType(Surface)), findsNothing);
  });
}
