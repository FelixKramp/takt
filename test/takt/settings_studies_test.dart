import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/state/locale_controller.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/ui2/profile/settings.dart';
import 'package:openstrap_edge/ui2/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _hasDigit(RenderParagraph p) =>
    RegExp(r'\d').hasMatch(p.text.toPlainText(includeSemanticsLabels: false));

void _assertAllDigitsDodged(WidgetTester t) {
  final paragraphs =
      t.allRenderObjects.whereType<RenderParagraph>().where(_hasDigit).toList();
  expect(paragraphs, isNotEmpty);
  for (final p in paragraphs) {
    RenderObject? o = p.parent;
    var wrapped = false;
    while (o != null) {
      if (o is RenderStripeDodge) {
        wrapped = true;
        break;
      }
      o = o.parent;
    }
    expect(
      wrapped,
      isTrue,
      reason:
          'Ungeschützte Zahl: "${p.text.toPlainText(includeSemanticsLabels: false)}"',
    );
  }
}

Widget _wrap(Widget child) => MaterialApp(
      theme: buildTheme(Brightness.dark),
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: TaktLook(child: child)),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocaleController.seed('de').useForPresentation();
  });

  tearDown(() {
    TaktStripe.fraction.value = null;
    LocaleController.seed('en').useForPresentation();
  });

  testWidgets('BodyAgeStudiesScreen zeigt Gompertz-Formel, alle 7 Studien und schützt alle Zahlen', (t) async {
    t.view.physicalSize = const Size(390, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    TaktStripe.fraction.value = 0.5;

    await t.pumpWidget(_wrap(const BodyAgeStudiesScreen()));
    await t.pump();

    expect(find.text('körperalter-studien'), findsOneWidget);
    expect(find.text('Gompertz-Verdopplungsregel'), findsOneWidget);
    expect(find.textContaining('Formel: Jahre = ln(Relatives Risiko) / ln(2) × 8'), findsOneWidget);

    // Alle 7 Studien vorhanden
    expect(find.textContaining('Cappuccio et al. (2010)'), findsOneWidget);
    expect(find.textContaining('Windred et al. (2024)'), findsOneWidget);
    expect(find.textContaining('Jensen et al. (2013)'), findsOneWidget);
    expect(find.textContaining('Paluch et al. (2022)'), findsOneWidget);
    expect(find.textContaining('Lee et al. (2022)'), findsNWidgets(2)); // Moderate & Intensive
    expect(find.textContaining('Momma et al. (2022)'), findsOneWidget);

    // Streifenschutz
    _assertAllDigitsDodged(t);
  });
}
