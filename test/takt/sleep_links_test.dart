// Feature 06, F11 und F12: kein doppelter Schlafplan, eine Takt-Karte mit
// Wecker, Körperuhr, Nickerchen und „Alle Messwerte“.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

import 'support/night_fixture.dart';

void main() {
  testWidgets('F11, F12: Plan entfällt, eine Karte mit vier Links', (t) async {
    t.view.physicalSize = const Size(390, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
          body: TaktLook(
              child: SleepDetail(
        embedded: true,
        data: sleepData(),
        head: (_) => const SizedBox(),
        todayFooter: const [Text('ALTER SCHLAFPLAN')],
        footer: const [Text('ALTE LINKS')],
      ))),
    ));
    await t.pumpAndSettle();
    expect(find.text('ALTER SCHLAFPLAN'), findsNothing);
    expect(find.text('ALTE LINKS'), findsNothing);
    final card = find.byKey(const ValueKey('takt-sleep-links'));
    expect(card, findsOneWidget);
    for (final s in ['Wecker', 'Körperuhr', 'Nickerchen', 'Alle Messwerte']) {
      expect(find.descendant(of: card, matching: find.text(s)), findsOneWidget, reason: s);
    }
    expect(find.text('Detailwerte'), findsNothing, reason: 'die alte Zeile ist in der Karte aufgegangen');
    expect(find.widgetWithText(TextButton, 'Nickerchen'), findsNothing);
  });
}
