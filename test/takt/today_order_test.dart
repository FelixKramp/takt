import 'package:flutter/gestures.dart' show kLongPressTimeout, kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/state/prefs.dart';
import 'package:openstrap_edge/takt/today/pulse_display.dart';
import 'package:openstrap_edge/takt/today/pulse_state.dart';
import 'package:openstrap_edge/takt/today/takt_today_screen.dart';
import 'package:openstrap_edge/takt/today/today_order.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TAKT 14.11.: Heute frei anordnen.
Metric m(num v) => Metric.parse({'value': v, 'unit': ''});

Widget host(Widget child) => MaterialApp(
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    );

const livePulse = PulseView(state: PulseState(PulseKind.live, bpm: 72), trace: [70, 72]);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.ensureLoaded();
    TodayOrder.reset();
  });

  test('gespeicherte Reihenfolge, Unbekanntes raus, Fehlendes ans Ende', () {
    Prefs.setString(TodayOrder.key, 'stress,quatsch,pulse,stress,week');
    expect(TodayOrder.read(), [
      TodaySection.stress,
      TodaySection.pulse,
      TodaySection.week,
      TodaySection.tonight,
      TodaySection.cards,
      TodaySection.watch,
      TodaySection.activities,
    ]);
  });

  test('speichern und neu lesen', () {
    final o = [...kDefaultTodayOrder.reversed];
    TodayOrder.save(o);
    expect(TodayOrder.read(), o);
    expect(TodayOrder.current.value, o);
    TodayOrder.reset();
    expect(TodayOrder.read(), kDefaultTodayOrder);
  });

  testWidgets('Heute zeigt die Abschnitte in der gewählten Reihenfolge', (t) async {
    t.view.physicalSize = const Size(390, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    Future<double> yOf(String key) async => t.getTopLeft(find.byKey(ValueKey(key))).dy;

    final data = HomeData(readiness: m(62), strain: m(8), rhr: m(54), steps: m(3000));
    await t.pumpWidget(host(TaktTodayView(
      data: data,
      pulse: livePulse,
      tonight: (bed: 1366, wake: 475),
    )));
    await t.pump();
    expect(await yOf('takt-tonight'), lessThan(await yOf('takt-pulse')));
    expect(await yOf('takt-pulse'), lessThan(await yOf('takt-cards')));

    await t.pumpWidget(host(TaktTodayView(
      data: data,
      pulse: livePulse,
      tonight: (bed: 1366, wake: 475),
      order: const [TodaySection.cards, TodaySection.pulse, TodaySection.tonight],
    )));
    await t.pump();
    expect(await yOf('takt-cards'), lessThan(await yOf('takt-pulse')));
    expect(await yOf('takt-pulse'), lessThan(await yOf('takt-tonight')));
    expect(await yOf('takt-tonight'), lessThan(await yOf('takt-activities')),
        reason: 'nicht genannte Abschnitte kommen ans Ende');
  });

  testWidgets('Anordnen-Screen: Ziehen speichert die neue Reihenfolge', (t) async {
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(host(const TodayArrangeScreen()));
    await t.pumpAndSettle();

    final week = find.byKey(const ValueKey('takt-arrange-week'));
    final first = find.byKey(const ValueKey('takt-arrange-tonight'));
    final g = await t.startGesture(t.getCenter(week));
    await t.pump(kLongPressTimeout + kPressTimeout);
    await g.moveTo(t.getTopLeft(first));
    await t.pump();
    await g.moveTo(t.getTopLeft(first) - const Offset(0, 10));
    await t.pump(const Duration(milliseconds: 300));
    await g.up();
    await t.pumpAndSettle();

    // Ganz oben oder direkt darunter, je nachdem, wo der Finger losließ.
    expect(TodayOrder.read().indexOf(TodaySection.week), lessThan(2),
        reason: '${TodayOrder.read()}');
    expect(TodayOrder.current.value, TodayOrder.read());

    await t.tap(find.byKey(const ValueKey('takt-arrange-reset')));
    await t.pumpAndSettle();
    expect(TodayOrder.read(), kDefaultTodayOrder);
  });
}
