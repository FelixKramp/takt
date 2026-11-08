// Felix' Gerätetest von 0.2.0: Der Schlafring auf Heute führte in den alten
// Schlaf-Screen, und der Takt-Kopf lud beim schnellen Hochscrollen neu.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/sleep/sleep_head.dart';
import 'package:openstrap_edge/takt/sleep/sleep_head_loader.dart';
import 'package:openstrap_edge/takt/today/takt_today_screen.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart' show HomeRingKind;
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';

import 'sleep_head_test.dart' show view;

void main() {
  test('E1: der Schlafring öffnet den Schlaf-Screen mit Takt-Kopf', () {
    final w = taktRingTarget(HomeRingKind.sleep);
    expect(w, isA<SleepDetail>());
    final head = (w as SleepDetail).head;
    expect(head, isNotNull, reason: 'ohne Kopf zeigt er den alten Abschnitt');
    expect(head!('2026-11-08'), isA<TaktSleepHeadLoader>());
  });

  testWidgets('E2: der Kopf bleibt beim Weg- und Zurückscrollen geladen', (t) async {
    t.view.physicalSize = const Size(390, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    var loads = 0;
    final scroll = ScrollController();
    await t.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: ListView(controller: scroll, children: [
          TaktSleepHeadLoader(
            day: '2026-11-08',
            load: (_) async {
              loads++;
              return view;
            },
          ),
          for (var i = 0; i < 40; i++) SizedBox(height: 200, child: Text('Zeile $i')),
        ]),
      ),
    ));
    await t.pump();
    await t.pump();
    expect(find.byType(TaktSleepHead), findsOneWidget);
    expect(loads, 1);

    scroll.jumpTo(scroll.position.maxScrollExtent);
    await t.pump();
    scroll.jumpTo(0);
    await t.pump();
    expect(find.byType(TaktSleepHead), findsOneWidget,
        reason: 'im ersten Frame nach dem Zurückscrollen, ohne Leerfläche');
    await t.pump();
    expect(loads, 1, reason: 'kein neues Laden nur durchs Scrollen');
  });
}
