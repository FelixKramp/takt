import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/takt/battery/battery.dart';
import 'package:openstrap_edge/takt/pult_tokens.dart' show Pult;
import 'package:openstrap_edge/takt/sleep/sleep_score.dart';
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
  sleepScoreRingTests();
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
    // Feature 04, D3: Der erste Ring ist die Batterie, 62 % am Morgen.
    expect(find.text('${batteryLeft(62, 13.8)}'), findsOneWidget);
    expect(find.text('von 62 %'), findsOneWidget);
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

  testWidgets('A4: Die drei Karten sind gleich breit', (t) async {
    await pump(t, TaktTodayView(data: full, hrv: m(58), pulse: livePulse));
    double w(String label) => t.getSize(find.ancestor(of: find.text(label), matching: find.byType(Container)).first).width;
    expect(w('HRV'), w('Schritte'));
    expect(w('HRV'), w('Ruhepuls'));
  });

  testWidgets('A13: Status zeigt Frische oder den laufenden Sync', (t) async {
    final now = DateTime(2026, 11, 6, 12);
    await pump(t, TaktTodayView(data: full, pulse: livePulse, now: now, lastData: now.subtract(const Duration(minutes: 2))));
    expect(find.text('vor 2 Min'), findsOneWidget);
    await pump(t, TaktTodayView(data: full, pulse: livePulse, now: now, syncing: true));
    expect(find.text('Synchronisiert …'), findsOneWidget);
  });

  testWidgets('A13: Die Anzeige bleibt nicht stehen', (t) async {
    await pump(t, TaktTodayView(data: full, pulse: livePulse, lastData: DateTime.now()));
    expect(find.text('gerade eben'), findsOneWidget);
    var ticks = 0;
    await pump(t, TaktTodayView(data: full, pulse: livePulse, lastData: DateTime.now(), onTick: () => ticks++));
    await t.pump(const Duration(seconds: 31));
    expect(ticks, 1);
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

  testWidgets('A19: Gekoppelt ohne Messung bietet kein Koppeln an', (t) async {
    await pump(t, PulseView(state: const PulseState(PulseKind.never, reason: PulseReason.notWorn), onPair: () {}));
    expect(find.text('Band koppeln'), findsNothing);
    expect(find.text('Warte auf den Puls …'), findsOneWidget);
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

  testWidgets('A8: Ohne Sportart heißt es Training', (t) async {
    final it = ActivityItem(id: 'suggestion:a', startTs: DateTime(2026, 11, 6, 18).millisecondsSinceEpoch ~/ 1000, type: 'other', detected: true);
    await pump(t, TaktTodayView(data: full, pulse: livePulse, items: [it]));
    await t.drag(find.byType(ListView), const Offset(0, -900));
    await t.pump();
    expect(find.text('Training'), findsOneWidget);
  });

  testWidgets('A9: Erkanntes lässt sich mit einem Tipp verwerfen', (t) async {
    ActivityItem? gone;
    await pump(t, TaktTodayView(data: full, pulse: livePulse, items: [item('suggestion:a', 18, detected: true)], onDiscard: (i) => gone = i));
    await t.drag(find.byType(ListView), const Offset(0, -900));
    await t.pump();
    await t.tap(find.byIcon(LucideIcons.x));
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

  testWidgets('Workout starten und Nachtragen: zwei gleich große flache Tasten nebeneinander (14.11.)', (t) async {
    var started = 0;
    var logged = 0;
    await pump(
        t,
        TaktTodayView(
            data: data0,
            pulse: livePulse,
            onStart: () => started++,
            onLog: () => logged++));
    await t.drag(find.byType(ListView), const Offset(0, -900));
    await t.pump();
    final text = const TaktText(true);
    expect(find.text(text.startWorkout), findsOneWidget);
    final startBox = find.byKey(const ValueKey('takt-start-workout'));
    final logBox = find.byKey(const ValueKey('takt-log-workout'));
    final start = t.getSize(startBox);
    final log = t.getSize(logBox);
    // Gerätetest 14.11.: der alte 64-pt-Knopf war zu groß.
    expect(start.height, lessThanOrEqualTo(48));
    expect(start.height, log.height);
    expect(start.width, closeTo(log.width, 1));
    expect(t.getTopLeft(startBox).dy, t.getTopLeft(logBox).dy, reason: 'in einer Reihe');
    // Komplett transparent, keine Farbe: nur Rahmen und normale Schrift
    // (Gerätetest 0.5.1).
    final box = t.widget<Container>(find.byKey(const ValueKey('takt-start-workout')));
    final deco = box.decoration! as BoxDecoration;
    expect(deco.color == null || deco.color!.a == 0, isTrue, reason: 'keine Fläche');
    final border = (deco.border! as Border).top.color;
    expect(border, isNot(Pult.orange));
    expect(border, isNot(Pult.orangeFor(true)));
    final label = t.widget<Text>(find.text(text.startWorkout));
    expect(label.style!.color, isNot(Pult.orange));
    expect(label.style!.color, isNot(Pult.orangeFor(true)));
    await t.tap(find.text(text.startWorkout));
    await t.tap(find.text(text.logWorkout));
    expect((started, logged), (1, 1));
  });

  testWidgets('Workout starten fehlt auf einem vergangenen Tag und ohne onStart (läuft schon eins)', (t) async {
    await pump(
        t,
        TaktTodayView(
            data: data0, pulse: livePulse, isToday: false, onStart: () {}, onLog: () {}));
    await t.drag(find.byType(ListView), const Offset(0, -900));
    await t.pump();
    expect(find.text(const TaktText(true).startWorkout), findsNothing);
    expect(find.text(const TaktText(true).logWorkout), findsOneWidget);
    await pump(t, TaktTodayView(data: data0, pulse: livePulse, onLog: () {}));
    await t.drag(find.byType(ListView), const Offset(0, -900));
    await t.pump();
    expect(find.text(const TaktText(true).startWorkout), findsNothing);
  });

  testWidgets('Gerätetest 0.5.1: Schlafring ist ohne Score nicht blau (blau hieße „gut“)', (t) async {
    await pump(t, TaktTodayView(data: full, pulse: livePulse));
    final sleep = t
        .widgetList<DialRing>(find.byType(DialRing))
        .firstWhere((r) => r.view.kind == HomeRingKind.sleep);
    expect(sleep.color, isNot(ScoreBand.gut.fill));
    expect(sleep.color, isNot(Pult.blue));
    expect(sleep.color, isNot(Pult.blueOnDark));
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

// Feature 03, C11/C12: Der Schlafring zeigt den Schlafscore in der Farbe der
// Stufe, darunter die Schlafdauer. Ohne Score bleibt er wie in A2.
void sleepScoreRingTests() {
  testWidgets('C11: Schlafring zeigt den Score und die Dauer', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(host(TaktTodayView(
      data: full,
      pulse: livePulse,
      sleepScore: scoreNight(durationMin: 432, needMin: 480, efficiencyPct: 89, regularity: 76),
    )));
    await t.pump();
    final rings = t.widgetList<DialRing>(find.byType(DialRing)).toList();
    final sleep = rings.firstWhere((r) => r.view.kind == HomeRingKind.sleep);
    expect(sleep.view.value, '65');
    expect(sleep.view.frac, closeTo(0.65, 0.001));
    expect(sleep.view.sub, contains('7:12'));
    expect(sleep.color, ScoreBand.knapp.fill);
  });

  testWidgets('C11: ohne Score bleibt der Schlafring wie bisher', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(host(TaktTodayView(
      data: full,
      pulse: livePulse,
      sleepScore: scoreNight(durationMin: 432, needMin: null),
    )));
    await t.pump();
    final sleep = t.widgetList<DialRing>(find.byType(DialRing))
        .firstWhere((r) => r.view.kind == HomeRingKind.sleep);
    expect(sleep.view.value, ringViewOf(HomeRingKind.sleep, full, null).value);
  });
}
