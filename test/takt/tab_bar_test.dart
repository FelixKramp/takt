// Feature 06, F2: flache Tab-Leiste, aktiver Tab fett und farbig ohne Pille,
// Schlaf in der Farbe des Schlafscores, die anderen in Takt-Orange.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/sleep/sleep_score.dart';
import 'package:openstrap_edge/ui2/app_shell.dart';
import 'package:openstrap_edge/ui2/theme.dart';

Future<void> pump(WidgetTester t, ShellDomain initial) async {
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: AppShell(initial: initial, builder: (_, d) => Text('Inhalt ${d.name}')),
  ));
  await t.pump();
}

Text label(WidgetTester t, String s) => t.widget<Text>(find.text(s));

void main() {
  tearDown(() => TaktSleepBand.current.value = null);

  testWidgets('F2: Beschriftungen deutsch, aktiver Tab fett in Orange, ohne Pille', (t) async {
    await pump(t, ShellDomain.today);
    for (final s in ['Heute', 'Schlaf', 'Aktivität', 'Gesundheit']) {
      expect(find.text(s), findsOneWidget);
    }
    final on = label(t, 'Heute');
    expect(on.style?.fontWeight, FontWeight.w700);
    expect(on.style?.color, ScoreBand.okay.ink(false));
    final off = label(t, 'Schlaf');
    expect(off.style?.fontWeight, isNot(FontWeight.w700));
    // Keine Pille: kein Container mit gefüllter Fläche hinter dem Symbol.
    final pills = t
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .where((c) => (c.decoration as BoxDecoration?)?.color?.a != 0);
    expect(pills, isEmpty);
  });

  testWidgets('Gerätetest 0.5.1: Schlaf-Tab bleibt Takt-Orange, die Stufe wechselt ihn nicht mehr', (t) async {
    // Vorher sprang er beim Laden von Orange auf Blau oder Rot. Die Stufe steht
    // am Ring, den Balken und am Wort, nicht mehr am Tab.
    await pump(t, ShellDomain.sleep);
    expect(label(t, 'Schlaf').style?.color, ScoreBand.okay.ink(false));
    for (final band in ScoreBand.values) {
      TaktSleepBand.current.value = band;
      await t.pump();
      expect(label(t, 'Schlaf').style?.color, ScoreBand.okay.ink(false), reason: band.name);
    }
  });
}
