// Feature 08: Training von Heute aus und „Workout nachtragen“ im Takt-Design.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/activity_suggestion.dart';
import 'package:openstrap_edge/takt/detail/value_card.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/pult_tokens.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/takt/today/activity_items.dart';
import 'package:openstrap_edge/takt/today/takt_today_screen.dart' show taktWorkoutTarget;
import 'package:openstrap_edge/ui2/activity/poster.dart' show PosterStatRow;
import 'package:openstrap_edge/ui2/activity/summary.dart';
import 'package:openstrap_edge/ui2/charts.dart' show LineChart;
import 'package:openstrap_edge/ui2/grammar.dart';
import 'package:openstrap_edge/ui2/profile/profile.dart' show SetRow;
import 'package:openstrap_edge/ui2/screens/log_workout.dart';
import 'package:openstrap_edge/ui2/theme.dart';

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:openstrap_edge/ui2/activity/catalogue.dart' show activityByName;

import 'support/shot.dart' show loadRealFonts;
import 'support/workout_fixture.dart';

Future<void> pump(WidgetTester t, Widget w, {bool takt = true, bool dark = false}) async {
  t.view.physicalSize = const Size(390, 2400);
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.alwaysUse24HourFormatTestValue = true;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearAlwaysUse24HourTestValue);
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(dark ? Brightness.dark : Brightness.light),
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: takt ? TaktLook(child: w) : w,
  ));
  await t.pumpAndSettle();
}

ActivityItem item({ActivitySuggestion? s}) => ActivityItem(
      id: s == null ? 'w1' : 'suggestion:${s.id}',
      startTs: 1,
      type: 'handball',
      detected: s != null,
      suggestion: s,
    );

void main() {
  setUpAll(loadRealFonts);

  group('Training öffnen', () {
    test('T1: gespeichertes Training öffnet die Übersicht', () async {
      String? asked;
      final w = await taktWorkoutTarget(item(), (id) async {
        asked = id;
        return handball();
      });
      expect(asked, 'w1');
      expect(w, isA<ActivitySummary>());
    });

    test('T2: Erkennung ohne Speicherung bleibt bei der Sportart-Wahl', () async {
      var called = false;
      const s = ActivitySuggestion(
          id: 's1', kind: ActivityKind.workout, startTs: 1, endTs: 2, revision: 0, details: {});
      final w = await taktWorkoutTarget(item(s: s), (_) async {
        called = true;
        return handball();
      });
      expect(w, isNull);
      expect(called, isFalse);
    });

    test('T2: Training, das sich nicht laden lässt, fällt auf die Sportart-Wahl zurück', () async {
      expect(await taktWorkoutTarget(item(), (_) async => null), isNull);
      expect(await taktWorkoutTarget(item(), (_) async => throw StateError('weg')), isNull);
    });
  });

  group('Übersicht', () {
    testWidgets('T4: Takt-Kopf mit Name, Tag, Stift und Teilen, Wert-Karte statt 48-pt-Zahl',
        (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      expect(find.byKey(const ValueKey('takt-back')), findsOneWidget);
      expect(find.text('handball'), findsOneWidget);
      expect(find.byType(NavBar), findsNothing);
      expect(find.byKey(const ValueKey('takt-workout-when')), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-workout-edit')), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-workout-share')), findsOneWidget);
      final card = find.byType(TaktValueCard);
      expect(card, findsOneWidget);
      final v = t.widget<Text>(find.descendant(of: card, matching: find.text('55:00')));
      expect(v.style?.fontFamily, 'Doto');
    });

    testWidgets('T5: Pulskurve in Takt-Orange', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      final lines = t
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((c) => c.painter)
          .whereType<LineChart>()
          .toList();
      expect(lines, isNotEmpty);
      expect(lines.every((l) => l.color == Pult.orange), isTrue);
    });

    testWidgets('T6: Messwerte als Zeilen mit Punktziffern, ohne runde Symbole', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      expect(find.byType(PosterStatRow), findsNothing);
      final rows = find.byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('takt-stat-'));
      expect(rows, findsNWidgets(5), reason: 'Ø Puls, Max. Puls, Erholung, Kalorien, Strain');
      // Das Dezimalzeichen kommt aus der App-Einstellung, nicht vom Gerät.
      // Feature 09, W9: Die Erholung heißt „Pulsabfall nach 1 Min.“ mit „16 bpm“.
      expect(find.descendant(of: rows, matching: find.text('bpm')), findsNWidgets(3),
          reason: 'nur die Zahl punktiert');
      for (final s in ['146', '197', '16', '718', RegExp(r'^11[.,]0$')]) {
        final f = find.descendant(
            of: rows,
            matching: s is String ? find.text(s) : find.textContaining(s as RegExp));
        expect(f, findsOneWidget, reason: "$s");
        expect(t.widget<Text>(f).style?.fontFamily, 'Doto', reason: "$s");
        expect(find.ancestor(of: f, matching: find.byType(StripeDodge)), findsWidgets, reason: "$s");
      }
    });

    testWidgets('T7: Reiter und Zonen bleiben', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      expect(find.byType(SubTabs), findsOneWidget);
      expect(find.text('Zone 5'), findsOneWidget);
    });

    // Prüfung 08, T4: Tag und Uhrzeit dürfen auch bei langen Namen und
    // schmalen Handys nicht abgeschnitten werden.
    for (final width in [320.0, 360.0, 390.0]) {
      testWidgets('T4: Tag und Uhrzeit ganz sichtbar bei ${width.round()} px, langer Name',
          (t) async {
        await pump(t, const SizedBox());
        t.view.physicalSize = Size(width, 1600);
        final base = handball();
        final r = ActivityResult(activityByName('General workout')!,
            start: base.start, duration: base.duration, sessionId: 'w1', hr: base.hr);
        await pump(t, ActivitySummary(r));
        t.view.physicalSize = Size(width, 1600);
        await t.pumpAndSettle();
        final when = t.renderObject<RenderParagraph>(
            find.byKey(const ValueKey('takt-workout-when')));
        expect(when.didExceedMaxLines, isFalse);
        expect(t.getSize(find.byKey(const ValueKey('takt-workout-when'))).width,
            greaterThanOrEqualTo(when.getMaxIntrinsicWidth(double.infinity) - .5));
      });
    }

    // Prüfung 08, Runde 2: 320 px, Textgröße 1,3, langes Datum.
    for (final scale in [1.3, 2.0]) {
      testWidgets('T4: Tag und Uhrzeit ganz sichtbar bei 320 px und Textgröße $scale', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final b = handball();
        final r = ActivityResult(b.activity,
            start: DateTime(2026, 9, 28, 23, 59), duration: b.duration, sessionId: 'w1', hr: b.hr);
        await pump(t, ActivitySummary(r));
        t.view.physicalSize = const Size(320, 1600);
        await t.pumpAndSettle();
        final when =
            t.renderObject<RenderParagraph>(find.byKey(const ValueKey('takt-workout-when')));
        expect(when.didExceedMaxLines, isFalse);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('Hinweis: privates Training schrumpft die Zahl nicht', (t) async {
      final b = handball();
      final r = ActivityResult(b.activity,
          start: b.start, duration: b.duration, sessionId: 'w1', hr: b.hr, private: true);
      await pump(t, ActivitySummary(r));
      final f = find.descendant(of: find.byType(TaktValueCard), matching: find.text('55:00'));
      final drawn = t.getSize(f).width;
      final natural =
          t.renderObject<RenderParagraph>(f).getMaxIntrinsicWidth(double.infinity);
      // FittedBox skaliert: gezeichnete Breite in globalen Koordinaten.
      final box = t.getRect(f);
      expect(box.width, closeTo(natural, 1), reason: 'gezeichnet $drawn');
    });

    testWidgets('Hinweis: Zahlen der Fußnote weichen dem Streifen aus', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      final note = find.textContaining('MET');
      expect(note, findsOneWidget);
      expect(find.ancestor(of: note, matching: find.byType(StripeDodge)), findsWidgets);
    });

    testWidgets('Hinweis: aktiver Reiter in Takt-Orange wie bei HRV und Strain', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75));
      expect(t.widget<SubTabs>(find.byType(SubTabs)).color, Pult.orange);
    });

    testWidgets('ohne Takt-Haut bleibt OpenStrap', (t) async {
      await pump(t, ActivitySummary(handball(), weightKg: 75), takt: false);
      expect(find.byType(NavBar), findsOneWidget);
      expect(find.byType(TaktValueCard), findsNothing);
      expect(find.byType(PosterStatRow), findsWidgets);
    });
  });

  group('Workout nachtragen', () {
    final now = DateTime(2026, 11, 8, 18, 30);

    testWidgets('T8: Takt-Kopf, schlichte Zeilen, Zeiten in Punktziffern', (t) async {
      await pump(t, LogWorkout(spans: const [], now: now));
      expect(find.byKey(const ValueKey('takt-back')), findsOneWidget);
      expect(find.text('training nachtragen'), findsOneWidget);
      expect(find.byType(NavBar), findsNothing);
      expect(find.byType(SetRow), findsNothing);
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(ValueKey('takt-log-row-$i')), findsOneWidget, reason: 'Zeile $i');
      }
      expect(find.text('min'), findsOneWidget, reason: 'Einheit klein neben der Dauer');
      for (final s in ['17:00', '18:00', '60']) {
        final f = find.text(s);
        expect(f, findsOneWidget, reason: s);
        expect(t.widget<Text>(f).style?.fontFamily, 'Doto', reason: s);
      }
    });

    testWidgets('T8: Beginn antippen öffnet die Uhrzeit-Wahl', (t) async {
      await pump(t, LogWorkout(spans: const [], now: now));
      await t.tap(find.byKey(const ValueKey('takt-log-row-2')));
      await t.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
    });

    testWidgets('T9: Hinweis als Zeile, Knopf flach und orange', (t) async {
      await pump(t, LogWorkout(spans: const [], now: now));
      expect(find.byType(StatusCard), findsNothing);
      expect(find.byKey(const ValueKey('takt-log-note')), findsOneWidget);
      expect(find.byType(BigButton), findsNothing);
      final btn = find.byKey(const ValueKey('takt-log-save'));
      expect(btn, findsOneWidget);
      final box = t.widget<Container>(
          find.descendant(of: btn, matching: find.byType(Container)).first);
      expect((box.decoration as BoxDecoration).color, Pult.orange);
      expect(t.widget<Pressable>(btn).onTap, isNotNull);
    });

    testWidgets('T9: ungültiger Zeitraum graut den Knopf aus und nennt den Grund', (t) async {
      // Endet in der Zukunft: Das Fenster beginnt 18:00 an einem Tag, an dem
      // es erst 18:10 ist, und endet 19:00.
      await pump(
          t,
          LogWorkout(
              spans: const [],
              now: DateTime(2026, 11, 8, 18, 10),
              start: DateTime(2026, 11, 8, 18),
              end: DateTime(2026, 11, 8, 19)));
      expect(t.widget<Pressable>(find.byKey(const ValueKey('takt-log-save'))).onTap, isNull);
      expect(find.byType(StatusCard), findsOneWidget);
    });

    testWidgets('T10: Sportart-Liste im Takt-Design', (t) async {
      await pump(t, LogWorkout(spans: const [], now: now));
      await t.tap(find.byKey(const ValueKey('takt-log-row-0')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('takt-type-row-0')), findsOneWidget);
      expect(find.byType(SetRow), findsNothing);
      await t.tap(find.text('Handball'));
      await t.pumpAndSettle();
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('takt-log-row-0')), matching: find.text('Handball')),
          findsOneWidget);
    });

    testWidgets('ohne Takt-Haut bleibt OpenStrap', (t) async {
      await pump(t, LogWorkout(spans: const [], now: now), takt: false);
      expect(find.byType(NavBar), findsOneWidget);
      expect(find.byType(SetRow), findsWidgets);
      expect(find.byType(BigButton), findsOneWidget);
    });
  });
}
