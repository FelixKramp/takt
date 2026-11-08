// Bildschirmfotos zum Ansehen beim Gestalten: TAKT_SHOTS=1 flutter test test/takt/shots_test.dart
// Ohne die Variable laufen die Screens nur durch (kein Überlauf, kein Fehler).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/sleep/sleep_head.dart';
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

import 'sleep_head_test.dart' show view;
import 'support/night_fixture.dart';
import 'support/shot.dart';

Widget app(Widget home) => MaterialApp(
      theme: buildTheme(Brightness.light),
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: RepaintBoundary(child: home),
    );

void main() {
  setUpAll(loadRealFonts);

  testWidgets('Schlaf-Tab ganz', (t) async {
    t.view.physicalSize = const Size(390, 4600);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.alwaysUse24HourFormatTestValue = true;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearAlwaysUse24HourTestValue);
    await t.pumpWidget(app(Scaffold(
      body: TaktLook(child: SleepDetail(
        embedded: true,
        data: sleepData(),
        head: (_) => TaktSleepHead(view: view),
      )),
    )));
    await t.pumpAndSettle();
    await shot(t, find.byType(SleepDetail), 'schlaf_tab');
  });
}
