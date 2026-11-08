// Feature 06, F1 und F15: Kopfzeile „schlaf“ mit Blätterpfeilen, im Tab mit
// Profilbild, gepusht mit Zurück-Pfeil. Kein großer Titel, keine eigene
// Blätterzeile.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/header.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/ui2/profile/profile.dart' show ProfileAvatar;
import 'package:openstrap_edge/ui2/screens/metric_detail.dart' show DayNav;
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';
import 'package:openstrap_edge/ui2/grammar.dart' show ScreenTitle;
import 'package:openstrap_edge/ui2/theme.dart';

import 'support/night_fixture.dart';

Future<void> pump(WidgetTester t, Widget w) async {
  t.view.physicalSize = const Size(390, 1600);
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

void main() {
  test('F1: Name der Nacht', () {
    expect(nightLabel('2026-11-08', true), 'Nacht auf So, 8. Nov.');
    expect(nightLabel('2026-11-07', false), 'Night to Sat, 7 Nov');
  });

  testWidgets('F1: im Tab „schlaf“, Nacht mit Pfeilen, Profilbild, kein großer Titel',
      (t) async {
    await pump(t, SleepDetail(embedded: true, data: sleepData()));
    expect(find.text('schlaf'), findsOneWidget);
    expect(find.text('Nacht auf So, 8. Nov.'), findsOneWidget);
    expect(find.byType(ProfileAvatar), findsOneWidget);
    expect(find.byType(ScreenTitle), findsNothing);
    expect(find.byType(DayNav), findsNothing, reason: 'keine eigene Blätterzeile');

    await t.tap(find.byKey(const ValueKey('takt-day-prev')));
    await t.pumpAndSettle();
    expect(find.text('Nacht auf Sa, 7. Nov.'), findsOneWidget);
  });

  testWidgets('F15: gepusht mit Zurück-Pfeil statt Profilbild', (t) async {
    await pump(t, SleepDetail(data: sleepData()));
    expect(find.text('schlaf'), findsOneWidget);
    expect(find.byKey(const ValueKey('takt-back')), findsOneWidget);
    expect(find.byType(ProfileAvatar), findsNothing);
    expect(find.byType(DayNav), findsNothing);
  });

  testWidgets('F1: an der neuesten Nacht ist der Pfeil nach vorn aus', (t) async {
    await pump(t, SleepDetail(embedded: true, data: sleepData()));
    final next = t.widget<TaktHeaderArrow>(find.byKey(const ValueKey('takt-day-next')));
    expect(next.onTap, isNull);
  });
}
