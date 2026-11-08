// Feature 07, H1 und H13: Takt-Rahmen der Detailscreens und Wert-Karte.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/detail/value_card.dart';
import 'package:openstrap_edge/takt/header.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/ui2/grammar.dart' show NavBar;
import 'package:openstrap_edge/ui2/screens/metric_detail.dart' show detailScaffold;
import 'package:openstrap_edge/ui2/theme.dart';

Future<void> pump(WidgetTester t, Widget w) async {
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: TaktLook(child: w),
  ));
  await t.pump();
}

void main() {
  testWidgets('H1: Detailgerüst mit Zurück-Pfeil und kleinem Namen statt NavBar', (t) async {
    await pump(t, Builder(builder: (c) => detailScaffold(c, 'HRV', const [Text('Inhalt')])));
    expect(find.byType(TaktHeader), findsOneWidget);
    expect(find.text('hrv'), findsOneWidget);
    expect(find.byKey(const ValueKey('takt-back')), findsOneWidget);
    expect(find.byType(NavBar), findsNothing);
    expect(find.text('Inhalt'), findsOneWidget);
  });

  testWidgets('H1: Wert-Karte mit Punktziffern im Streifen und Zeile von wann', (t) async {
    await pump(t, const Scaffold(body: TaktValueCard(value: '61', unit: 'ms', when: 'gestern')));
    final v = t.widget<Text>(find.text('61'));
    expect(v.style?.fontFamily, 'Doto');
    expect(v.style?.fontSize, greaterThanOrEqualTo(48));
    expect(find.ancestor(of: find.text('61'), matching: find.byType(StripeDodge)), findsOneWidget);
    expect(find.text('ms'), findsOneWidget);
    expect(find.text('gestern'), findsOneWidget);
  });

  testWidgets('H13: ohne Wert ein Strich und der Grund', (t) async {
    await pump(t,
        const Scaffold(body: TaktValueCard(value: null, why: 'Noch nicht genug Nächte.')));
    expect(find.text('–'), findsOneWidget);
    expect(find.text('Noch nicht genug Nächte.'), findsOneWidget);
  });

  testWidgets('H9: Wert-Karte mit Stufenwort in Farbe', (t) async {
    await pump(t,
        const Scaffold(
            body: TaktValueCard(value: '62', unit: '%', word: 'Startklar', wordColor: Color(0xFF2552AD))));
    expect(t.widget<Text>(find.text('Startklar')).style?.color, const Color(0xFF2552AD));
  });
}
