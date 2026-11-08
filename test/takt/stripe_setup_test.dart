import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/state/prefs.dart';
import 'package:openstrap_edge/takt/about.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/takt/stripe/stripe_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host(Widget child) => MaterialApp(
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.ensureLoaded();
    TaktStripe.clear();
  });

  Future<void> phone(WidgetTester t) async {
    t.view.physicalSize = const Size(400, 860);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  testWidgets('B1: Linie einstellen, speichern, nach Neustart wieder da', (t) async {
    await phone(t);
    await t.pumpWidget(host(const TaktDisplayGroup()));
    await t.tap(find.text('Displaystreifen'));
    await t.pumpAndSettle();
    expect(find.byType(StripeSetupScreen), findsOneWidget);

    final slider = t.widget<Slider>(find.byType(Slider));
    slider.onChanged!(0.72);
    await t.pump();
    final line = t.getRect(find.byKey(const ValueKey('stripe-line')));
    expect(line.center.dx, closeTo(0.72 * 400, 1));

    await t.tap(find.text('Speichern'));
    await t.pumpAndSettle();
    expect(TaktStripe.fraction.value, closeTo(0.72, 0.001));

    // Neustart: Wert vergessen, aus den Prefs neu lesen.
    TaktStripe.fraction.value = null;
    TaktStripe.load();
    expect(TaktStripe.fraction.value, closeTo(0.72, 0.001));
    expect(find.textContaining('72'), findsOneWidget, reason: 'Zeile zeigt die Lage');
  });

  testWidgets('B1: Feinschritt bewegt die Linie um einen halben Punkt', (t) async {
    await phone(t);
    await t.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const StripeSetupScreen(),
    ));
    final before = t.getRect(find.byKey(const ValueKey('stripe-line'))).center.dx;
    await t.tap(find.byKey(const ValueKey('stripe-right')));
    await t.pump();
    final after = t.getRect(find.byKey(const ValueKey('stripe-line'))).center.dx;
    expect(after - before, closeTo(0.5, 0.01));
  });

  testWidgets('B1: Entfernen schaltet die Funktion aus', (t) async {
    await phone(t);
    TaktStripe.save(0.6);
    await t.pumpWidget(host(const TaktDisplayGroup()));
    await t.tap(find.text('Displaystreifen'));
    await t.pumpAndSettle();
    await t.tap(find.text('Entfernen'));
    await t.pumpAndSettle();
    expect(TaktStripe.fraction.value, isNull);
    TaktStripe.load();
    expect(TaktStripe.fraction.value, isNull);
  });
}
