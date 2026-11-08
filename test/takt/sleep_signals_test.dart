// Feature 06, F10: Signale in der Nacht mit drei großen Ziffern.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

import 'support/night_fixture.dart';

void main() {
  testWidgets('F10: Schlafpuls, tiefster Puls und Atmung als große Ziffern', (t) async {
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
              child: SleepDetail(
                  embedded: true, data: sleepData(), head: (_) => const SizedBox()))),
    ));
    await t.pumpAndSettle();
    expect(find.text('Signale in der Nacht'), findsOneWidget);
    for (final (label, value) in [
      ('Schlafpuls', '54'),
      ('Tiefster Puls', '47'),
      ('Atemzüge/Min', '14.2'),
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
      final v = t.widget<Text>(find.text(value));
      expect(v.style?.fontFamily, 'Doto', reason: label);
      expect(v.style?.fontSize, greaterThanOrEqualTo(24), reason: label);
    }
  });
}
