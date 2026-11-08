// Feature 09: Feinschliff nach dem Gerätetest von 0.3.1.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/ui2/activity/catalogue.dart';
import 'package:openstrap_edge/ui2/activity/picker.dart';
import 'package:openstrap_edge/ui2/activity/summary.dart';
import 'package:openstrap_edge/ui2/charts.dart' show LineChart;
import 'package:openstrap_edge/ui2/grammar.dart';
import 'package:openstrap_edge/ui2/screens/log_workout.dart';

import 'support/shot.dart' show loadRealFonts;
import 'support/workout_fixture.dart';
import 'workout_takt_test.dart' show pump;

Finder _key(String k) => find.byKey(ValueKey(k));

String _digits(WidgetTester t, String key) {
  final f = find.descendant(of: _key(key), matching: find.byType(Text)).first;
  final w = t.widget<Text>(f);
  expect(w.style?.fontFamily, 'Doto', reason: key);
  return w.data!;
}

LineChart _chart(WidgetTester t, Finder within) => t
    .widgetList<CustomPaint>(find.descendant(of: within, matching: find.byType(CustomPaint)))
    .map((c) => c.painter)
    .whereType<LineChart>()
    .single;

void main() {
  setUpAll(loadRealFonts);

  group('Sportart-Wahl', () {
    testWidgets('W1: Takt-Kopf, schlichte Zeilen, Kalorien-Erklärung als Zeile', (t) async {
      await pump(t, ActivityPicker(weightKg: 75, onPick: (_, _) {}));
      expect(find.text('sportart wählen'), findsOneWidget);
      expect(_key('takt-back'), findsOneWidget);
      expect(find.byType(NavBar), findsNothing);
      expect(find.byType(ActivityRow), findsNothing);
      expect(find.byType(StatusCard), findsNothing);
      expect(_key('takt-pick-recent-0'), findsOneWidget);
      expect(_key('takt-pick-group-0'), findsOneWidget);
      expect(_key('takt-pick-note'), findsOneWidget);
      // Keine bunten Symbole in den Zeilen.
      expect(
          find.descendant(of: _key('takt-pick-recent-0'), matching: find.byType(Icon)),
          findsNothing);
    });

    testWidgets('W2: Gruppe aufklappen und Sportart antippen wählt sie', (t) async {
      Activity? got;
      await pump(t, ActivityPicker(onPick: (_, a) => got = a));
      await t.tap(_key('takt-pick-group-0'));
      await t.pumpAndSettle();
      final first = activityLibrary[0].items.first;
      await t.tap(_key('takt-pick-row-${first.name}'));
      expect(got, first);
    });

    testWidgets('W2: Suche findet Handball', (t) async {
      Activity? got;
      await pump(t, ActivityPicker(onPick: (_, a) => got = a));
      await t.enterText(_key('takt-pick-search'), 'handb');
      await t.pumpAndSettle();
      await t.tap(_key('takt-pick-row-Handball'));
      expect(got?.name, 'Handball');
    });

    testWidgets('W1: zuletzt gemachte Sportarten stehen oben', (t) async {
      Activity? got;
      final hb = activityByName('handball')!;
      await pump(t, ActivityPicker(recent: [hb], onPick: (_, a) => got = a));
      expect(find.text('Zuletzt'), findsOneWidget);
      await t.tap(_key('takt-pick-recent-0'));
      expect(got, hb);
    });

    testWidgets('W1: der Stift öffnet die Sportart-Wahl im Takt-Design', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      await t.tap(_key('takt-workout-edit'));
      await t.pumpAndSettle();
      expect(find.byType(ActivityPicker), findsOneWidget);
      expect(find.text('sportart wählen'), findsOneWidget);
      expect(find.byType(ActivityRow), findsNothing);
    });

    testWidgets('ohne Takt-Haut bleibt die Liste OpenStrap', (t) async {
      await pump(t, ActivityPicker(onPick: (_, _) {}), takt: false);
      expect(find.byType(NavBar), findsOneWidget);
      expect(find.text('sportart wählen'), findsNothing);
    });
  });

  group('Pulskurve ablesen', () {
    testWidgets('W5: vor dem Antippen steht der Hinweis', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      expect(find.text('Kurve antippen oder wischen'), findsOneWidget);
      expect(_chart(t, _key('takt-hr-scrub')).selectedX, isNull);
    });

    testWidgets('W4: Antippen zeigt Uhrzeit und Puls, Wischen folgt, Loslassen behält', (t) async {
      final r = handball();
      await pump(t, ActivitySummary(r, weightKg: 75));
      final box = t.getRect(_key('takt-hr-scrub'));
      await t.tapAt(Offset(box.left + 1, box.center.dy));
      await t.pump();
      expect(_digits(t, 'takt-hr-time'), '16:57');
      expect(_digits(t, 'takt-hr-bpm'), '${r.hr[0]!.round()}');
      expect(_chart(t, _key('takt-hr-scrub')).selectedX, 0);

      final g = await t.startGesture(Offset(box.left + 1, box.center.dy));
      await g.moveTo(Offset(box.right - 1, box.center.dy));
      await t.pump();
      expect(_digits(t, 'takt-hr-time'), '17:51');
      await g.up();
      await t.pump();
      expect(_digits(t, 'takt-hr-time'), '17:51', reason: 'bleibt nach dem Loslassen');
      expect(_digits(t, 'takt-hr-bpm'), '${r.hr[54]!.round()}');
      expect(find.ancestor(of: _key('takt-hr-time'), matching: find.byType(StripeDodge)),
          findsWidgets);
    });

    testWidgets('W5: Minute ohne Messung zeigt einen Strich', (t) async {
      final r = handball();
      final gap = r.copyWith(hr: [null, ...r.hr.skip(1)]);
      await pump(t, ActivitySummary(gap, weightKg: 75));
      final box = t.getRect(_key('takt-hr-scrub'));
      await t.tapAt(Offset(box.left + 1, box.center.dy));
      await t.pump();
      expect(_digits(t, 'takt-hr-bpm'), '–');
      expect(find.text('keine Messung'), findsOneWidget);
    });
  });

  group('Prüfung 09', () {
    testWidgets('W4: Kurve beginnt nach dem Trainingsbeginn, die Uhrzeit stimmt trotzdem',
        (t) async {
      // Wie `_denseMinutes` es liefert: ab der ersten Messung (17:02), hinten
      // mit leeren Minuten auf Trainingslänge aufgefüllt.
      final base = handball();
      final r = base.copyWith(
          hrFrom: DateTime(2026, 11, 8, 17, 2),
          hr: [...base.hr.take(51), null, null, null, null, null]);
      await pump(t, ActivitySummary(r, weightKg: 75));
      final box = t.getRect(_key('takt-hr-scrub'));
      await t.tapAt(Offset(box.left + 1, box.center.dy));
      await t.pump();
      expect(_digits(t, 'takt-hr-time'), '16:57', reason: 'links ist der Trainingsbeginn');
      expect(_digits(t, 'takt-hr-bpm'), '–');
      await t.tapAt(Offset(box.right - 1, box.center.dy));
      await t.pump();
      expect(_digits(t, 'takt-hr-time'), '17:52', reason: 'rechts das Ende, nicht später');
      final line = _chart(t, _key('takt-hr-scrub'));
      expect(line.d[5], base.hr[0], reason: '17:02 ist die erste Messung');
    });

    testWidgets('W4: Beginn mit Sekunden und späte erste Messung, Uhrzeit stimmt', (t) async {
      // Runde 3: Erkennung 00:05:30 bis 00:35:30, Puls ab 00:10.
      final hr = <double?>[for (var i = 0; i < 26; i++) 170.0 - i, ...List.filled(5, null)];
      final r = ActivityResult(activityByName('handball')!,
          start: DateTime(2026, 11, 9, 0, 5, 30),
          duration: const Duration(minutes: 30),
          hr: hr,
          hrFrom: DateTime(2026, 11, 9, 0, 10));
      await pump(t, ActivitySummary(r, weightKg: 75));
      final box = t.getRect(_key('takt-hr-scrub'));
      final line = _chart(t, _key('takt-hr-scrub'));
      expect(line.d.length, 31, reason: '00:05 bis 00:35');
      expect(line.d[5], 170, reason: '00:10 ist die erste Messung');
      await t.tapAt(Offset(box.left + box.width * 5 / 30, box.center.dy));
      await t.pump();
      expect(_digits(t, 'takt-hr-time'), '00:10');
      expect(_digits(t, 'takt-hr-bpm'), '170');
      await t.tapAt(Offset(box.right - 1, box.center.dy));
      await t.pump();
      expect(_digits(t, 'takt-hr-time'), '00:35');
      expect(_digits(t, 'takt-hr-bpm'), '145');
    });

    testWidgets('W4: senkrecht über die Kurve scrollen setzt keine Minute', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      await t.drag(_key('takt-hr-scrub'), const Offset(0, -150));
      await t.pumpAndSettle();
      expect(find.text('Kurve antippen oder wischen'), findsOneWidget);
    });

    testWidgets('W4: waagrecht wischen liest ab', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      final box = t.getRect(_key('takt-hr-scrub'));
      await t.dragFrom(Offset(box.left + 5, box.center.dy), Offset(box.width - 6, 0));
      await t.pump();
      expect(_digits(t, 'takt-hr-time'), '17:51');
    });

    for (final width in [320.0, 360.0]) {
      testWidgets('W5: Ablesezeile ohne Überlauf bei ${width.round()} px und Textgröße 2,0',
          (t) async {
        t.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final r = handball();
        await pump(t, ActivitySummary(r.copyWith(hr: [null, ...r.hr.skip(1)]), weightKg: 75));
        t.view.physicalSize = Size(width, 2400);
        await t.pumpAndSettle();
        final box = t.getRect(_key('takt-hr-scrub'));
        await t.tapAt(Offset(box.left + 1, box.center.dy));
        await t.pump();
        expect(find.text('keine Messung'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('W1: über den Stift steht die Kalorien-Erklärung', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      await t.tap(_key('takt-workout-edit'));
      await t.pumpAndSettle();
      expect(_key('takt-pick-note'), findsOneWidget);
    });

    testWidgets('W1: Doppeltipp auf den Stift öffnet nur eine Liste', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      await t.tap(_key('takt-workout-edit'));
      await t.tap(_key('takt-workout-edit'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(find.byType(ActivityPicker), findsOneWidget);
    });

    testWidgets('B5: Gruppenzahlen weichen dem Displaystreifen aus', (t) async {
      await pump(t, ActivityPicker(onPick: (_, _) {}));
      final n = find.descendant(of: _key('takt-pick-group-0'), matching: find.text('12'));
      expect(n, findsOneWidget);
      expect(find.ancestor(of: n, matching: find.byType(StripeDodge)), findsWidgets);
    });
  });

  group('Puls beim Nachtragen', () {
    final now = DateTime(2026, 11, 8, 20);
    final start = DateTime(2026, 11, 8, 18);
    final end = DateTime(2026, 11, 8, 19);
    int sec(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

    // Puls 100, zwischen 18:10 und 18:50 dagegen 160.
    Future<List<(int, int)>> samples(int from, int to) async => [
          for (var s = from; s <= to; s += 30)
            (s, s >= sec(DateTime(2026, 11, 8, 18, 10)) && s < sec(DateTime(2026, 11, 8, 18, 50)) ? 160 : 100),
        ];

    testWidgets('W6: Kurve von 30 Minuten vor bis 30 nach, Zeitraum hinterlegt', (t) async {
      final asked = <(int, int)>[];
      await pump(
          t,
          LogWorkout(
              spans: const [],
              now: now,
              start: start,
              end: end,
              hrSamples: (a, b) {
                asked.add((a, b));
                return samples(a, b);
              }));
      expect(asked.last, (sec(DateTime(2026, 11, 8, 17, 30)), sec(DateTime(2026, 11, 8, 19, 30))));
      final card = _key('takt-log-hr');
      expect(card, findsOneWidget);
      final line = _chart(t, card);
      expect(line.d.length, 120);
      expect(line.d[50], 160);
      expect(line.d[10], 100);
      expect(_key('takt-hr-window'), findsOneWidget);
    });

    testWidgets('W7: „Beginn hier“ und „Ende hier“ übernehmen die Minute, die Kurve zieht mit',
        (t) async {
      final asked = <(int, int)>[];
      await pump(
          t,
          LogWorkout(
              spans: const [],
              now: now,
              start: start,
              end: end,
              hrSamples: (a, b) {
                asked.add((a, b));
                return samples(a, b);
              }));
      expect(_key('takt-hr-set-start'), findsNothing, reason: 'erst nach dem Antippen');
      final box = t.getRect(_key('takt-hr-scrub'));
      // Minute 40 von 120: 18:10.
      await t.tapAt(Offset(box.left + box.width * 40 / 119, box.center.dy));
      await t.pump();
      expect(_digits(t, 'takt-hr-time'), '18:10');
      expect(_digits(t, 'takt-hr-bpm'), '160');
      await t.tap(_key('takt-hr-set-start'));
      await t.pumpAndSettle();
      expect(find.descendant(of: _key('takt-log-row-2'), matching: find.text('18:10')),
          findsOneWidget);
      expect(find.descendant(of: _key('takt-log-row-3'), matching: find.text('19:00')),
          findsOneWidget, reason: 'das Ende bleibt');
      expect(asked.last.$1, sec(DateTime(2026, 11, 8, 17, 40)), reason: 'die Kurve zieht mit');

      final box2 = t.getRect(_key('takt-hr-scrub'));
      // Neue Kurve 17:40 bis 19:30 (110 Minuten), Minute 70: 18:50.
      await t.tapAt(Offset(box2.left + box2.width * 70 / 109, box2.center.dy));
      await t.pump();
      expect(_digits(t, 'takt-hr-time'), '18:50');
      await t.tap(_key('takt-hr-set-end'));
      await t.pumpAndSettle();
      expect(find.descendant(of: _key('takt-log-row-3'), matching: find.text('18:50')),
          findsOneWidget);
      expect(find.descendant(of: _key('takt-log-row-4'), matching: find.text('40')),
          findsOneWidget);
    });

    testWidgets('Randfall: „Ende hier“ vor dem Beginn nennt den Grund auf Deutsch', (t) async {
      await pump(
          t,
          LogWorkout(spans: const [], now: now, start: start, end: end, hrSamples: samples));
      final box = t.getRect(_key('takt-hr-scrub'));
      await t.tapAt(Offset(box.left + 1, box.center.dy));
      await t.pump();
      await t.tap(_key('takt-hr-set-end'));
      await t.pumpAndSettle();
      expect(find.text('Das Ende muss nach dem Beginn liegen.'), findsOneWidget);
      expect(t.widget<Pressable>(_key('takt-log-save')).onTap, isNull);
    });

    testWidgets('Mittelung pro Minute', (t) async {
      await pump(
          t,
          LogWorkout(
              spans: const [],
              now: now,
              start: start,
              end: end,
              hrSamples: (a, b) async => [(a + 10, 100), (a + 40, 120), (a + 70, 90)]));
      final line = _chart(t, _key('takt-log-hr'));
      expect(line.d[0], 110);
      expect(line.d[1], 90);
      expect(line.d[2], isNull);
    });

    testWidgets('W8: ohne Aufzeichnung eine graue Zeile statt der Kurve, Speichern geht', (t) async {
      await pump(
          t,
          LogWorkout(
              spans: const [], now: now, start: start, end: end, hrSamples: (_, _) async => []));
      expect(find.text('Für diese Zeit hat das Band keinen Puls aufgezeichnet.'), findsOneWidget);
      expect(_key('takt-hr-scrub'), findsNothing);
      expect(t.widget<Pressable>(_key('takt-log-save')).onTap, isNotNull);
    });

    testWidgets('W8: Lesefehler wie keine Aufzeichnung', (t) async {
      await pump(
          t,
          LogWorkout(
              spans: const [],
              now: now,
              start: start,
              end: end,
              hrSamples: (_, _) async => throw StateError('db')));
      expect(find.text('Für diese Zeit hat das Band keinen Puls aufgezeichnet.'), findsOneWidget);
    });

    testWidgets('Randfall: über zwölf Stunden keine Kurve und keine Abfrage', (t) async {
      var asked = false;
      await pump(
          t,
          LogWorkout(
              spans: const [],
              now: DateTime(2026, 11, 9, 12),
              start: DateTime(2026, 11, 8, 6),
              end: DateTime(2026, 11, 8, 19),
              hrSamples: (_, _) async {
                asked = true;
                return [];
              }));
      expect(asked, isFalse);
      expect(_key('takt-hr-scrub'), findsNothing);
      expect(find.text('Für diese Zeit hat das Band keinen Puls aufgezeichnet.'), findsOneWidget);
    });
  });

  group('Erholung verständlich', () {
    testWidgets('W9: Pulsabfall nach 1 Min., Wert in bpm, Erklärung darunter', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      expect(find.text('Pulsabfall nach 1 Min.'), findsOneWidget);
      expect(find.text('bpm in 60 s'), findsNothing);
      final row = find.ancestor(
          of: find.text('Pulsabfall nach 1 Min.'),
          matching: find.byWidgetPredicate((w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('takt-stat-')));
      expect(find.descendant(of: row, matching: find.text('16')), findsOneWidget);
      expect(find.descendant(of: row, matching: find.text('bpm')), findsOneWidget);
      expect(
          find.text('So weit ist dein Puls in der ersten Minute nach dem Training gefallen. '
              'Mehr ist besser, über 12 gilt als normal.'),
          findsOneWidget);
    });
  });
}
