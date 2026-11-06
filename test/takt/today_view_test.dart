import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/takt/takt_text.dart';
import 'package:openstrap_edge/takt/today/activity_items.dart';
import 'package:openstrap_edge/takt/today/dial_ring.dart';
import 'package:openstrap_edge/takt/today/pulse_display.dart';
import 'package:openstrap_edge/takt/today/pulse_state.dart';
import 'package:openstrap_edge/takt/today/takt_today_screen.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';

Metric m(num v, [String? note]) => Metric.parse({'value': v, 'unit': ''});

const data0 = HomeData();
final full = HomeData(
  readiness: m(62),
  strain: m(13.8),
  sleepMin: m(432),
  sleepNeedMin: m(480),
  rhr: m(54),
  steps: m(8412),
);

ActivityItem item(String id, int h, {bool detected = false}) => ActivityItem(
      id: id,
      startTs: DateTime(2026, 11, 6, h).millisecondsSinceEpoch ~/ 1000,
      type: 'running',
      detected: detected,
      durationMin: 84,
      avgHr: 148,
      strain: 11.2,
    );

Widget host(Widget child, {double scale = 1}) => MaterialApp(
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(size: const Size(390, 844), textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: child),
      ),
    );

const livePulse = PulseView(state: PulseState(PulseKind.live, bpm: 72), trace: [70, 72, 74, 72]);

void main() {
  Future<void> pump(WidgetTester t, Widget w, {double scale = 1}) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(host(w, scale: scale));
    await t.pump();
  }

  testWidgets('A1: Reihenfolge Ringe, Puls, Karten, Aktivitäten, Puls ohne Scrollen', (t) async {
    await pump(t, TaktTodayView(data: full, pulse: livePulse));
    double y(String k) => t.getTopLeft(find.byKey(ValueKey(k))).dy;
    expect(y('takt-rings'), lessThan(y('takt-pulse')));
    expect(y('takt-pulse'), lessThan(y('takt-cards')));
    expect(y('takt-cards'), lessThan(y('takt-activities')));
    expect(t.getBottomLeft(find.byKey(const ValueKey('takt-pulse'))).dy, lessThan(844));
  });

  testWidgets('A2: Drei Ringe zeigen ihre Werte', (t) async {
    await pump(t, TaktTodayView(data: full, pulse: livePulse));
    expect(find.byType(DialRing), findsNWidgets(3));
    expect(find.text('62'), findsOneWidget);
    expect(find.text(ringViewOf(HomeRingKind.sleep, full, null).value), findsOneWidget);
  });

  testWidgets('A3: Ring antippen meldet die Art', (t) async {
    HomeRingKind? hit;
    await pump(t, TaktTodayView(data: full, pulse: livePulse, onRing: (k) => hit = k));
    await t.tap(find.text(ringViewOf(HomeRingKind.sleep, full, null).value));
    expect(hit, HomeRingKind.sleep);
  });

  testWidgets('A4: Drei Karten führen zu ihren Details', (t) async {
    final hits = <String>[];
    await pump(t, TaktTodayView(data: full, hrv: m(58), pulse: livePulse, onCard: hits.add));
    await t.tap(find.text('54'));
    await t.tap(find.text('58 ms'));
    await t.tap(find.text('Schritte'));
    expect(hits, ['resting_hr', 'hrv', 'steps']);
  });

  testWidgets('A13: Status zeigt Frische oder den laufenden Sync', (t) async {
    final now = DateTime(2026, 11, 6, 12);
    await pump(t, TaktTodayView(data: full, pulse: livePulse, now: now, lastData: now.subtract(const Duration(minutes: 2))));
    expect(find.text('vor 2 Min'), findsOneWidget);
    await pump(t, TaktTodayView(data: full, pulse: livePulse, now: now, syncing: true));
    expect(find.text('Synchronisiert …'), findsOneWidget);
  });

  testWidgets('A18: Letzter Wert steht mit Uhrzeit und Grund, Höhe bleibt gleich', (t) async {
    await pump(t, livePulse);
    final liveHeight = t.getSize(find.byType(PulseView)).height;
    await pump(
      t,
      PulseView(
        state: PulseState(PulseKind.stale,
            bpm: 70, at: DateTime(2026, 11, 6, 14, 32), reason: PulseReason.notConnected),
      ),
    );
    expect(find.text('70'), findsOneWidget);
    expect(find.textContaining(':32'), findsOneWidget);
    expect(find.text('Band nicht verbunden'), findsOneWidget);
    expect(t.getSize(find.byType(PulseView)).height, liveHeight);
  });

  testWidgets('A19: Ohne Messung keine Zahl, aber ein Weg zum Koppeln', (t) async {
    var paired = false;
    await pump(
      t,
      PulseView(
        state: const PulseState(PulseKind.never, reason: PulseReason.notPaired),
        onPair: () => paired = true,
      ),
    );
    expect(find.text('--'), findsOneWidget);
    await t.tap(find.text('Band koppeln'));
    expect(paired, isTrue);
  });

  testWidgets('A20: Kalibrierung zeigt Fortschritt statt Wert', (t) async {
    final d = HomeData(
      readiness: Metric.parse({'value': '—', 'note': 'need_baseline:have=6,need=14'}),
      sleepMin: m(432),
    );
    await pump(t, TaktTodayView(data: d, pulse: livePulse));
    expect(find.text('6/14'), findsOneWidget);
    expect(find.text(ringViewOf(HomeRingKind.sleep, d, null).value), findsOneWidget);
    final sleep = t.widget<DialRing>(find.byType(DialRing).at(2));
    expect(dialLitTicks(sleep.view.frac), 0);
  });

  testWidgets('A9: Erkanntes lässt sich mit einem Tipp verwerfen', (t) async {
    ActivityItem? gone;
    await pump(t, TaktTodayView(data: full, pulse: livePulse, items: [item('suggestion:a', 18, detected: true)], onDiscard: (i) => gone = i));
    await t.drag(find.byType(ListView), const Offset(0, -900));
    await t.pump();
    await t.tap(find.bySemanticsLabel(RegExp('verwerfen')));
    expect(gone?.id, 'suggestion:a');
  });

  testWidgets('A11 und A21: Leere Liste zeigt Hinweis und Nachtragen', (t) async {
    var logged = false;
    await pump(t, TaktTodayView(data: data0, pulse: livePulse, onLog: () => logged = true));
    await t.drag(find.byType(ListView), const Offset(0, -900));
    await t.pump();
    expect(find.text(const TaktText(true).noActivities), findsOneWidget);
    await t.tap(find.text(const TaktText(true).logWorkout));
    expect(logged, isTrue);
  });

  testWidgets('A22: Mehr als fünf lassen sich aufklappen', (t) async {
    await pump(t, TaktTodayView(data: full, pulse: livePulse, items: [for (var i = 0; i < 7; i++) item('w$i', 8 + i)]));
    await t.drag(find.byType(ListView), const Offset(0, -900));
    await t.pump();
    await t.tap(find.text('2 weitere anzeigen'));
    await t.pump();
    expect(find.text('2 weitere anzeigen'), findsNothing);
  });

  testWidgets('A24: Bei 200 % Schrift läuft nichts über', (t) async {
    await pump(t, TaktTodayView(data: full, hrv: m(58), pulse: livePulse, items: [item('suggestion:a', 18, detected: true)]), scale: 2);
    expect(t.takeException(), isNull);
  });
}
