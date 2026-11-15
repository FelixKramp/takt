// TAKT 15.11.: Zoom im Stressverlauf mit zwei Fingern. Synthetische Daten.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/stress/day_stress.dart';
import 'package:openstrap_edge/takt/stress/takt_stress_view.dart';

const full = (0, 86400);

void main() {
  group('stressZoomView', () {
    test('Auseinanderziehen in der Mitte halbiert den Ausschnitt um die Mitte', () {
      final v = stressZoomView(
        full: full,
        from: full,
        width: 400,
        fromMidX: 200,
        toMidX: 200,
        scale: 2,
      );
      expect(v, (21600, 43200));
    });

    test('Die Uhrzeit unter den Fingern bleibt unter den Fingern', () {
      final v = stressZoomView(
        full: full,
        from: full,
        width: 400,
        fromMidX: 100,
        toMidX: 100,
        scale: 4,
      )!;
      // 100 px von 400 = 06:00. Nach dem Zoom liegt 06:00 wieder bei 100 px.
      expect(v.$1 + 100 / 400 * v.$2, closeTo(21600, 1));
      expect(v.$2, 21600);
    });

    test('Verschieben schiebt den Ausschnitt, bleibt aber im Verlauf', () {
      const from = (21600, 21600);
      final v = stressZoomView(
        full: full,
        from: from,
        width: 400,
        fromMidX: 200,
        toMidX: 300,
        scale: 1,
      )!;
      expect(v.$2, 21600);
      expect(v.$1, lessThan(21600), reason: 'nach rechts ziehen zeigt früher');
      final edge = stressZoomView(
        full: full,
        from: from,
        width: 400,
        fromMidX: 0,
        toMidX: 400,
        scale: 1,
      )!;
      expect(edge.$1, 0, reason: 'nicht vor den Anfang');
    });

    test('Höchstens auf eine halbe Stunde, ganz heraus ist null', () {
      final v = stressZoomView(
        full: full,
        from: full,
        width: 400,
        fromMidX: 200,
        toMidX: 200,
        scale: 1000,
      )!;
      expect(v.$2, kStressMinZoomSec);
      expect(
        stressZoomView(
          full: full,
          from: (0, 43200),
          width: 400,
          fromMidX: 200,
          toMidX: 200,
          scale: .3,
        ),
        isNull,
      );
    });
  });

  testWidgets('Zwei Finger zoomen, „Ganzer Verlauf“ setzt zurück', (t) async {
    t.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
    t.view.devicePixelRatio = 2.625;
    addTearDown(() => t.view.resetPhysicalSize());

    final day0 = DateTime(2026, 11, 11).millisecondsSinceEpoch ~/ 1000;
    final res = DayStressAnalysis(
      date: '2026-11-11',
      samples: [
        for (var m = 0; m < 24 * 60; m += 10)
          DayStressSample(timestampSec: day0 + m * 60, score: (m % 180) / 60, hr: 70),
      ],
      avgStress: 1.2,
      lowStressMin: 400,
      mediumStressMin: 300,
      highStressMin: 200,
      activityMin: 0,
      sleepMin: 0,
      peakStress: 2.9,
      peakTimeSec: day0 + 600 * 60,
      hasData: true,
    );
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: TaktLook(
            child: TaktStressDetailScreen(initialDate: '2026-11-11', injectedAnalysis: res),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('00:00'), findsOneWidget);
    expect(find.byKey(const ValueKey('takt-stress-zoom-reset')), findsNothing);

    final c = t.getCenter(find.byKey(const ValueKey('takt-stress-chart')));
    final a = await t.startGesture(c - const Offset(20, 0));
    final b = await t.startGesture(c + const Offset(20, 0));
    for (var d = 20.0; d <= 120; d += 10) {
      await a.moveTo(c - Offset(d, 0));
      await b.moveTo(c + Offset(d, 0));
      await t.pump();
    }
    await a.up();
    await b.up();
    await t.pumpAndSettle();

    expect(t.takeException(), isNull);
    expect(find.text('00:00'), findsNothing, reason: 'Achse zeigt den Ausschnitt');
    expect(find.text('12:00'), findsWidgets, reason: 'in der Mitte hineingezoomt');
    await t.tap(find.byKey(const ValueKey('takt-stress-zoom-reset')));
    await t.pumpAndSettle();
    expect(find.text('00:00'), findsOneWidget);
  });
}
