import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/detail/hr_scrub.dart';
import 'package:openstrap_edge/takt/health/takt_health_views.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/ui2/trend.dart' show UsualRange;

// TAKT 14.11.: Beim Durchwischen einer Kurve darf sich nichts verschieben.
// Ändert die Karte über der Kurve ihre Höhe, springt die Kurve unter dem
// Finger.
void main() {
  for (final width in [412.0, 360.0]) {
    testWidgets('Trendkarte: Wischen verschiebt die Kurve nicht ($width px)', (t) async {
      t.view.physicalSize = Size(width * 2.625, 915 * 2.625);
      t.view.devicePixelRatio = 2.625;
      addTearDown(() => t.view.resetPhysicalSize());

      final series = <double?>[
        for (var i = 0; i < 30; i++) i.isEven ? 6.2 + i / 10 : (i % 3 == 0 ? null : 112.4 - i),
      ];
      await t.pumpWidget(MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: TaktLook(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              TaktTrendCard(
                key: const ValueKey('card'),
                label: 'HRV',
                value: '62',
                unit: 'ms',
                series: series,
                color: Colors.teal,
                de: true,
                band: const UsualRange(50, 70),
                latest: 62,
                delta: '+4',
                window: '30 Tage',
                format: (v) => v.toStringAsFixed(1),
              ),
              const SizedBox(key: ValueKey('below'), height: 40),
            ]),
          ),
        ),
      ));
      await t.pumpAndSettle();

      final below = find.byKey(const ValueKey('below'));
      final card = find.byKey(const ValueKey('card'));
      final y0 = t.getTopLeft(below).dy;
      final box = t.getRect(card);
      final chartY = box.bottom - 16 - 40;
      final g = await t.startGesture(Offset(box.left + 20, chartY));
      for (var x = box.left + 20; x < box.right - 20; x += 5) {
        await g.moveTo(Offset(x, chartY));
        await t.pump();
        expect(t.getTopLeft(below).dy, y0, reason: 'sprang bei x=$x');
      }
      await g.up();
      await t.pump();
      expect(t.getTopLeft(below).dy, y0, reason: 'nach dem Loslassen');
    });
  }

  testWidgets('Pulsverlauf: Wischen verschiebt die Kurve nicht', (t) async {
    t.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
    t.view.devicePixelRatio = 2.625;
    addTearDown(() => t.view.resetPhysicalSize());

    final hr = <double?>[for (var i = 0; i < 240; i++) i % 7 == 0 ? null : 48.0 + (i % 130)];
    await t.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: TaktLook(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TaktHrScrub(hr: hr, t0: DateTime(2026, 11, 14, 8), title: 'Puls'),
            const SizedBox(key: ValueKey('below'), height: 40),
          ]),
        ),
      ),
    ));
    await t.pumpAndSettle();

    final scrub = find.byKey(const ValueKey('takt-hr-scrub'));
    final below = find.byKey(const ValueKey('below'));
    final y0 = t.getTopLeft(below).dy;
    final s0 = t.getTopLeft(scrub).dy;
    final r = t.getRect(scrub);
    final g = await t.startGesture(Offset(r.left + 10, r.center.dy));
    for (var x = r.left + 10; x < r.right - 10; x += 5) {
      await g.moveTo(Offset(x, r.center.dy));
      await t.pump();
      expect(t.getTopLeft(scrub).dy, s0, reason: 'Kurve sprang bei x=$x');
      expect(t.getTopLeft(below).dy, y0, reason: 'darunter sprang bei x=$x');
    }
    await g.up();
    await t.pump();
  });
}
