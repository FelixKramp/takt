// Feature 03, Board A+: der Takt-Kopf des Schlaf-Tabs.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/sleep/night_log.dart';
import 'package:openstrap_edge/takt/sleep/sleep_head.dart';
import 'package:openstrap_edge/takt/sleep/sleep_score.dart';
import 'package:openstrap_edge/takt/sleep/sleep_tab_data.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/takt/today/dial_ring.dart';

int ts(int d, int h, int m) => DateTime(2026, 11, d, h, m).millisecondsSinceEpoch ~/ 1000;

final view = TaktSleepView(
  day: '2026-11-08',
  score: scoreNight(durationMin: 432, needMin: 480, efficiencyPct: 89, regularity: 76),
  sleptMin: 432,
  needMin: 480,
  needParts: const NightNote(needMin: 480, debtMin: 18, strainMin: 12, napMin: 0),
  inBedMin: 485,
  awakeMin: 53,
  onsetTs: ts(7, 23, 48),
  wakeTs: ts(8, 7, 6),
  effPct: 89,
  awakenings: 9,
  regularity: 76,
  nights: const [
    NightBar('2026-11-02', 71),
    NightBar('2026-11-03', 88),
    NightBar('2026-11-04', null),
    NightBar('2026-11-05', 79),
    NightBar('2026-11-06', 91),
    NightBar('2026-11-07', 77),
    NightBar('2026-11-08', 65),
  ],
  week: const [
    WeekNight('2026-11-03', bed: 220, wake: 650, bedRec: 210, wakeRec: 660),
    WeekNight('2026-11-04', bed: 270, wake: 680),
    WeekNight('2026-11-05', bed: 190, wake: 640, bedRec: 200, wakeRec: 655),
    WeekNight('2026-11-06', bed: 320, wake: 690, bedRec: 205, wakeRec: 660),
    WeekNight('2026-11-07', bed: 200, wake: 670, bedRec: 195, wakeRec: 650),
    WeekNight('2026-11-08', bed: 228, wake: 666, bedRec: 195, wakeRec: 660),
  ],
  bedRecTonight: 1395,
  wakeRecTonight: 420,
  asleep: const [Run(0.03, 0.34), Run(0.36, 1)],
  awake: const [Run(0, 0.03), Run(0.34, 0.36)],
);

Widget host(Widget child, {double width = 390}) => MaterialApp(
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  tearDown(() => TaktStripe.fraction.value = null);

  Future<void> pump(WidgetTester t, TaktSleepView v, {double height = 2600}) async {
    t.view.physicalSize = Size(390, height);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.alwaysUse24HourFormatTestValue = true;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearAlwaysUse24HourTestValue);
    await t.pumpWidget(host(TaktSleepHead(view: v)));
    await t.pump();
  }

  testWidgets('C4: Score groß, Stufe, Zeiten, drei Teile, Gewichtung', (t) async {
    await pump(t, view);
    expect(find.text('65'), findsWidgets);
    expect(find.text('knapp'), findsOneWidget);
    expect(find.text('7:12 Std geschlafen'), findsOneWidget);
    expect(find.textContaining('bis'), findsWidgets);
    for (final l in ['Dauer zu Bedarf', 'Effizienz', 'Regelmäßigkeit']) {
      expect(find.text(l), findsWidgets);
    }
    expect(find.textContaining('Dauer zählt 60 %'), findsOneWidget);
  });

  testWidgets('C12: Ring und Balken in der Farbe der Stufe', (t) async {
    await pump(t, view);
    final dial = t.widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((c) => c.painter)
        .whereType<DialPainter>()
        .single;
    expect(dial.litColor, ScoreBand.knapp.fill);
    expect(dial.lit, dialLitTicks(0.65));
    final word = t.widget<Text>(find.text('knapp'));
    expect(word.style?.color, ScoreBand.knapp.ink(false));
  });

  testWidgets('C5: sieben Nächte mit Wochentag, Lücke ohne Zahl', (t) async {
    await pump(t, view);
    expect(find.text('Letzte 7 Nächte'), findsOneWidget);
    for (final d in ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']) {
      expect(find.text(d), findsWidgets);
    }
    expect(find.text('91'), findsOneWidget);
    expect(find.byKey(const ValueKey('night-gap-2026-11-04')), findsOneWidget);
  });

  testWidgets('C6: Geschlafen gegen Bedarf und die Teile des Bedarfs', (t) async {
    await pump(t, view);
    expect(find.text('Dauer und Bedarf'), findsOneWidget);
    expect(find.text('7:12'), findsWidgets);
    expect(find.text('8:00'), findsWidgets);
    expect(find.text('Grundbedarf'), findsOneWidget);
    expect(find.text('7:30'), findsOneWidget);
    expect(find.text('+0:12'), findsOneWidget);
    expect(find.text('+0:18'), findsOneWidget);
    expect(find.text('Nickerchen'), findsNothing, reason: 'null oder 0 fällt weg');
  });

  testWidgets('C6: ohne Notiz ein Satz statt der Teile', (t) async {
    await pump(t, TaktSleepView(
      day: view.day, score: view.score, sleptMin: 432, needMin: 480, nights: view.nights));
    expect(find.text('Grundbedarf'), findsNothing);
    expect(find.textContaining('ab der nächsten Nacht'), findsOneWidget);
  });

  testWidgets('C7: Regelmäßigkeit mit Wert, Diagramm und Empfehlung für heute', (t) async {
    await pump(t, view);
    expect(find.text('76'), findsWidgets);
    expect(find.byKey(const ValueKey('regularity-chart')), findsOneWidget);
    expect(find.text('gestrichelt: empfohlen für jeden Tag'), findsOneWidget);
    expect(find.textContaining('ins Bett 23:15, aufstehen 07:00'), findsOneWidget);
  });

  testWidgets('C8: Effizienz, Streifen, Wachzeit und Aufwachereignisse', (t) async {
    await pump(t, view);
    expect(find.text('89 %'), findsWidgets);
    expect(find.byKey(const ValueKey('efficiency-strips')), findsOneWidget);
    expect(find.text('0:53'), findsOneWidget);
    expect(find.text('Aufwachereignisse'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('C2/Randfall: keine Nacht, ein Hinweis statt Zahlen', (t) async {
    await pump(t, const TaktSleepView(bedRecTonight: 1395, wakeRecTonight: 420));
    expect(find.textContaining('Trag das Band über Nacht'), findsOneWidget);
    expect(find.text('knapp'), findsNothing);
  });

  testWidgets('C2: Nacht ohne Bedarf, Strich und Grund', (t) async {
    await pump(t, TaktSleepView(
      day: '2026-11-08', sleptMin: 432,
      score: scoreNight(durationMin: 432, needMin: null)));
    expect(find.text('–'), findsWidgets);
    expect(find.textContaining('Schlafbedarf erst nach'), findsOneWidget);
  });

  testWidgets('C2: fehlender Teil heißt „noch nicht genug Nächte“', (t) async {
    await pump(t, TaktSleepView(
      day: '2026-11-08', sleptMin: 432, needMin: 480,
      score: scoreNight(durationMin: 432, needMin: 480, efficiencyPct: 89)));
    expect(find.text('noch nicht genug Nächte'), findsOneWidget);
  });

  testWidgets('C13: jede Zahl in einer Hülle, keine Ziffer auf dem Streifen', (t) async {
    await pump(t, view);
    for (var f = 0.05; f < 0.96; f += 0.05) {
      TaktStripe.fraction.value = f;
      await t.pump();
      final x = f * 390;
      for (final p in t.allRenderObjects.whereType<RenderParagraph>()) {
        final s = p.text.toPlainText(includeSemanticsLabels: false);
        if (!RegExp(r'\d').hasMatch(s)) continue;
        RenderObject? o = p.parent;
        while (o != null && o is! RenderStripeDodge) {
          o = o.parent;
        }
        expect(o, isNotNull, reason: '"$s" ohne StripeDodge');
      }
      for (final h in t.allRenderObjects.whereType<RenderStripeDodge>()) {
        for (final r in h.paintedDigitRects()) {
          final hit = r.right > x - kStripeGap + 0.01 && r.left < x + kStripeGap - 0.01;
          expect(hit, isFalse, reason: 'Streifen bei $x: $r');
        }
      }
    }
  });
}
