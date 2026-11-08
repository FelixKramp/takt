// Felix' Gerätetest von 0.2.0: Auf Heute stand bei HRV und Ruhepuls nur ein
// Strich, obwohl die Detailansicht einen Wert hatte, und „von 21“ unter dem
// Strain wirkte falsch.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/takt/takt_text.dart';
import 'package:openstrap_edge/takt/today/pulse_display.dart';
import 'package:openstrap_edge/takt/today/pulse_state.dart';
import 'package:openstrap_edge/takt/today/takt_today_screen.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';

Metric m(num v) => Metric.parse({'value': v, 'unit': ''});

const pulse = PulseView(state: PulseState(PulseKind.live, bpm: 72), trace: [70, 72]);
final now = DateTime(2026, 11, 8, 14, 0);
int noon(int d) => DateTime(2026, 11, d, 12).millisecondsSinceEpoch ~/ 1000;

Future<void> pump(WidgetTester t, Widget w) async {
  t.view.physicalSize = const Size(390, 1400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: w),
  ));
  await t.pump();
}

void main() {
  test('G1: Strain-Stufe als Wort', () {
    const t = TaktText(true);
    expect(t.strainWord(4.2), 'leicht');
    expect(t.strainWord(10), 'mittel');
    expect(t.strainWord(13.9), 'mittel');
    expect(t.strainWord(14), 'hoch');
    expect(t.strainWord(18), 'sehr hoch');
    expect(const TaktText(false).strainWord(12), 'moderate');
  });

  testWidgets('G1: unter dem Strain steht die Stufe statt „von 21“', (t) async {
    await pump(t, TaktTodayView(data: HomeData(strain: m(12.4)), pulse: pulse, now: now));
    expect(find.text('12.4'), findsOneWidget);
    expect(find.text('mittel'), findsOneWidget);
    expect(find.text('von 21'), findsNothing);
    expect(find.text('of 21'), findsNothing);
  });

  testWidgets('G2: ohne heutige Nacht zeigen HRV und Ruhepuls den letzten Wert mit Tag',
      (t) async {
    await pump(
      t,
      TaktTodayView(
        data: const HomeData(),
        pulse: pulse,
        now: now,
        hrvLast: (t: noon(7), v: 61.4),
        rhrLast: (t: noon(5), v: 53.6),
      ),
    );
    expect(find.text('61 ms'), findsOneWidget);
    expect(find.text('HRV, gestern'), findsOneWidget);
    expect(find.text('54'), findsOneWidget);
    expect(find.text('Ruhepuls, Do'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('takt-cards')), matching: find.text('–')),
        findsOneWidget,
        reason: 'nur Schritte fehlen');
  });

  testWidgets('G3: mit heutiger Nacht gilt der heutige Wert ohne Tag', (t) async {
    await pump(
      t,
      TaktTodayView(
        data: HomeData(rhr: m(51)),
        hrv: Metric.parse({'value': 66, 'unit': 'ms'}),
        pulse: pulse,
        now: now,
        hrvLast: (t: noon(7), v: 61.4),
        rhrLast: (t: noon(7), v: 53.6),
      ),
    );
    expect(find.text('66 ms'), findsOneWidget);
    expect(find.text('HRV'), findsOneWidget);
    expect(find.text('51'), findsOneWidget);
    expect(find.text('Ruhepuls'), findsOneWidget);
  });

  testWidgets('G2: ein Wert von heute bekommt keinen Tag', (t) async {
    await pump(
      t,
      TaktTodayView(
        data: const HomeData(),
        pulse: pulse,
        now: now,
        hrvLast: (t: noon(8), v: 58),
      ),
    );
    expect(find.text('58 ms'), findsOneWidget);
    expect(find.text('HRV'), findsOneWidget);
  });
}
