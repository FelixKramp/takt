// Tests für Feature 10 (Körperalter) & Feature 05 (Gesundheit im Takt-Design):
// - K1: Körperalter steht prominent im Gesundheit-Tab mit echtem Alter und
//       Vorwochen-Vergleich.
// - K2: Alle 7 Einflussfaktoren sind nach größtem Hebel sortiert.
// - K3: Kein Aufklappen mehr; keine Studien und keine Formel in der Ansicht.
// - K4: Unter 14 Tagen steht „Noch X Tage bis zum Körperalter"; fehlende
//       Einzelfaktoren fließen mit 0,0 Jahren ein.
// - K5: Der Wochenwert wird am Montag festgelegt und bis Sonntag eingefroren.
// - K6: Jede Zahl auf dem Gesundheit-Tab und im Körperalter-Detail steht in
//       einer StripeDodge-Hülle.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/data/day_label.dart';
import 'package:openstrap_edge/data/local_repository.dart';
import 'package:openstrap_edge/import/whoop_import.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/ui2/activity/catalogue.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart' show ChartPoint;
import 'package:openstrap_edge/takt/health/body_age.dart';
import 'package:openstrap_edge/takt/health/body_age_view.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/ui2/profile/settings.dart' show BodyAgeStudiesScreen;
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/ui2/screens/health_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _hasDigit(RenderParagraph p) =>
    RegExp(r'\d').hasMatch(p.text.toPlainText(includeSemanticsLabels: false));

void _assertAllDigitsDodged(WidgetTester t) {
  final paragraphs =
      t.allRenderObjects.whereType<RenderParagraph>().where(_hasDigit).toList();
  expect(paragraphs, isNotEmpty);
  for (final p in paragraphs) {
    RenderObject? o = p.parent;
    var wrapped = false;
    while (o != null) {
      if (o is RenderStripeDodge) {
        wrapped = true;
        break;
      }
      o = o.parent;
    }
    expect(
      wrapped,
      isTrue,
      reason:
          'Ungeschützte Zahl: "${p.text.toPlainText(includeSemanticsLabels: false)}"',
    );
  }
}

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: TaktLook(child: child)),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => TaktStripe.fraction.value = null);

  group('BodyAgeCalculator (K1, K2, K4)', () {
    test('K1 + K2: berechnet Körperalter aus 7 Faktoren und sortiert nach größtem Hebel', () {
      final snap = BodyAgeCalculator.calculate(
        realAge: 34,
        dataDays: 28,
        avgSleepHours: 7.5, // optimal -> ~ -0.7 J.
        avgSri: 86, // optimal -> < 0 J.
        avgRhr: 52, // niedrig -> deutlich jünger
        avgSteps: 9500, // gut -> jünger
        moderateMinPerWeek: 180, // gut -> jünger
        intensiveMinPerWeek: 45, // gut -> jünger
        strengthMinPerWeek: 60, // optimal -> jünger
        prevWeekDelta: -0.4,
      );

      expect(snap.ready, isTrue);
      expect(snap.hasAge, isTrue);
      expect(snap.missingDays, 0);
      expect(snap.bodyAge, isNotNull);
      expect(snap.bodyAge!, lessThan(34.0));
      expect(snap.diffYears, closeTo(snap.bodyAge! - 34.0, 0.01));
      expect(snap.prevWeekDelta, -0.4);
      expect(snap.factors.length, 7);

      // K2: Sortiert nach dem größten Hebel (verbesserbarer Beitrag).
      for (var i = 0; i < snap.factors.length - 1; i++) {
        expect(
          snap.factors[i].potentialYears,
          greaterThanOrEqualTo(snap.factors[i + 1].potentialYears),
        );
      }

      // K7: Alterungstempo vorhanden und < 1.0 bei gesundem Lebensstil.
      expect(snap.paceOfAging, isNotNull);
      expect(snap.paceOfAging!, lessThan(1.0));
    });

    test('K7: Alterungstempo verdoppelt sich bei +8 Jahren und halbiert sich bei -8 Jahren', () {
      final snapGood = BodyAgeCalculator.calculate(
        realAge: 30,
        dataDays: 30,
        avgSleepHours: 7.5,
        avgSri: 85,
        avgRhr: 48,
        avgSteps: 12000,
        moderateMinPerWeek: 200,
        intensiveMinPerWeek: 60,
        strengthMinPerWeek: 80,
      );
      // diffYears < 0 -> Pace < 1.0 (verlangsamtes Altern)
      expect(snapGood.paceOfAging!, lessThan(1.0));
      expect(snapGood.paceOfAging!, closeTo(math.pow(2.0, snapGood.diffYears / 8.0), 0.001));

      final snapBad = BodyAgeCalculator.calculate(
        realAge: 30,
        dataDays: 30,
        avgSleepHours: 4.0,
        avgSri: 25,
        avgRhr: 90,
        avgSteps: 1000,
        moderateMinPerWeek: 0,
        intensiveMinPerWeek: 0,
        strengthMinPerWeek: 0,
      );
      // diffYears > 0 -> Pace > 1.0 (beschleunigtes Altern, bis zu > 2.0x)
      expect(snapBad.paceOfAging!, greaterThan(1.5));
      expect(snapBad.paceOfAging!, closeTo(math.pow(2.0, snapBad.diffYears / 8.0), 0.001));
    });

    test('Geburtsdatum / exactAge: berechnet Körperalter basierend auf exaktem Alter mit Dezimalstellen', () {
      final snap = BodyAgeCalculator.calculate(
        realAge: 20,
        exactAge: 20.7,
        dataDays: 30,
        avgSleepHours: 7.5,
        avgSri: 85,
        avgRhr: 50,
        avgSteps: 12000,
      );

      expect(snap.realAge, equals(20));
      expect(snap.exactAge, equals(20.7));
      expect(snap.chronologicalAge, equals(20.7));
      expect(snap.bodyAge, isNotNull);
      expect(snap.bodyAge!, closeTo(20.7 + snap.diffYears, 0.001));
    });

    test('K4: unter 14 Tagen im Kalibrierungszustand, fehlende Tage exakt ausgewiesen', () {
      final snap = BodyAgeCalculator.calculate(
        realAge: 30,
        dataDays: 9,
        avgSleepHours: 7.2,
      );

      expect(snap.ready, isFalse);
      expect(snap.hasEnoughDays, isFalse);
      expect(snap.missingDays, 5);
    });

    test('K4: fehlende Einzelfaktoren fließen mit 0,0 Jahren ein und stehen am Ende', () {
      final snap = BodyAgeCalculator.calculate(
        realAge: 30,
        dataDays: 20,
        avgSleepHours: 6.0, // schlechter als Ziel -> > 0 J.
        avgRhr: 54.0, // besser als 65 -> < 0 J.
        // Alle anderen 5 Faktoren sind null.
      );

      expect(snap.ready, isTrue);
      final absentFactors = snap.factors.where((f) => f.absent).toList();
      expect(absentFactors.length, 5);
      for (final f in absentFactors) {
        expect(f.yearsShift, 0.0);
        expect(f.formattedValue(true), 'fehlt');
      }
      // Die aktiven Faktoren stehen vor den fehlenden Faktoren.
      expect(snap.factors.first.absent, isFalse);
      expect(snap.factors[1].absent, isFalse);
      expect(snap.factors.last.absent, isTrue);
    });

    test('Kappung: Einzelfaktor maximal ±3,0 Jahre und Gesamtabweichung maximal ±10,0 Jahre', () {
      final snap = BodyAgeCalculator.calculate(
        realAge: 40,
        dataDays: 30,
        avgSleepHours: 3.5,
        avgSri: 20,
        avgRhr: 98,
        avgSteps: 800,
        moderateMinPerWeek: 0,
        intensiveMinPerWeek: 0,
        strengthMinPerWeek: 0,
      );

      for (final f in snap.factors) {
        expect(f.yearsShift.abs(), lessThanOrEqualTo(3.0));
      }
      expect(snap.diffYears.abs(), lessThanOrEqualTo(10.0));
      expect(snap.bodyAge, lessThanOrEqualTo(50.0));
    });

    test('K5: mondayOfWeek liefert immer den Montag derselben Kalenderwoche', () {
      // Mittwoch, 11.11.2026 -> Montag, 09.11.2026
      expect(mondayOfWeek(DateTime(2026, 11, 11, 18, 30)), '2026-11-09');
      // Sonntag, 15.11.2026 -> Montag, 09.11.2026
      expect(mondayOfWeek(DateTime(2026, 11, 15, 23, 59)), '2026-11-09');
      // Montag, 09.11.2026 -> Montag, 09.11.2026
      expect(mondayOfWeek(DateTime(2026, 11, 9, 0, 1)), '2026-11-09');
    });
  });

  group('UI: TaktBodyAgeCard, TaktBodyAgeDetail & HealthScreen (K1–K4, K6)', () {
    testWidgets('K4: zeigt Kalibrierungs-Hinweis bei weniger als 14 Tagen', (t) async {
      final snap = BodyAgeCalculator.calculate(
        realAge: 32,
        dataDays: 8,
      );
      await t.pumpWidget(_wrap(TaktBodyAgeCard(snapshot: snap)));
      await t.pump();

      expect(find.text('Körperalter'), findsOneWidget);
      expect(find.textContaining('Noch 6 Tage bis zum Körperalter'), findsOneWidget);
      _assertAllDigitsDodged(t);
    });

    testWidgets('Fehlendes Alter im Profil zeigt Hinweis statt Zahl', (t) async {
      final snap = BodyAgeCalculator.calculate(
        realAge: null,
        dataDays: 20,
      );
      await t.pumpWidget(_wrap(TaktBodyAgeCard(snapshot: snap)));
      await t.pump();

      expect(
        find.textContaining('Alter im Profil eintragen'),
        findsOneWidget,
      );
    });

    testWidgets('K1 + K3 + K6: Detail-Screen zeigt alle 7 Faktoren ohne Studien und schützt alle Zahlen', (t) async {
      t.view.physicalSize = const Size(390, 2200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      TaktStripe.fraction.value = 0.5;

      final snap = BodyAgeCalculator.calculate(
        realAge: 35,
        dataDays: 28,
        avgSleepHours: 7.4,
        avgSri: 82,
        avgRhr: 55,
        avgSteps: 8500,
        moderateMinPerWeek: 150,
        intensiveMinPerWeek: 35,
        strengthMinPerWeek: 50,
        prevWeekDelta: -0.3,
      );

      await t.pumpWidget(_wrap(TaktBodyAgeDetail(snapshot: snap)));
      await t.pump();

      expect(find.text('körperalter'), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-body-age-pace-card')), findsOneWidget);
      expect(find.text('Alterungstempo'), findsOneWidget);
      expect(find.text('Faktoren (letzte 30 Tage)'), findsOneWidget);
      expect(find.text('Ruhepuls'), findsOneWidget);
      expect(find.text('Schlafdauer'), findsOneWidget);
      expect(find.text('Krafttraining'), findsOneWidget);

      // K3: Antippen eines Faktors klappt die Studien-Herleitung auf.
      expect(find.byKey(const ValueKey('takt-factor-corridor-resting_hr')), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-factor-dot-resting_hr')), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-factor-corridor-sleep_duration')), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-factor-dot-sleep_duration')), findsOneWidget);

      // Kein Aufklappen, keine Studien in der Ansicht: Zitate und Umrechnung
      // stehen nur im Studienbildschirm (Gerätetest 0.5.1).
      await t.tap(find.text('Ruhepuls'));
      await t.pump();
      expect(find.textContaining('Jensen'), findsNothing);
      expect(find.textContaining('Studie:'), findsNothing);
      expect(find.textContaining('Umrechnung'), findsNothing);

      // K6: Jede Ziffer steht in einer RenderStripeDodge-Hülle.
      _assertAllDigitsDodged(t);
    });

    testWidgets('K1 + K6: Gesundheit-Tab im TaktLook zeigt Körperalter oben und schützt alle Zahlen', (t) async {
      t.view.physicalSize = const Size(390, 2200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      TaktStripe.fraction.value = 0.45;

      Map<String, dynamic> env(num v, [String u = '']) => {
            'value': v,
            'unit': u,
            'confidence': 0.95,
          };
      final d = HealthData(
        profile: const {'age': 33},
        daysWithData: 25,
        today: {
          'daily': {
            'resting_hr': env(54, 'bpm'),
            'spo2': env(98, '%'),
            'skin_temp': env(36.4, '°C'),
          },
          'hrv': {'rmssd': 68, 'confidence': 0.95},
          'sleep': {'duration_min': env(450, 'min')},
          'resp': env(14.8, 'brpm'),
        },
        charts: {
          'resting_hr': [
            for (var i = 0; i < 25; i++) (t: 1700000000 + i * 86400, v: 54.0),
          ],
          'sleep': [
            for (var i = 0; i < 25; i++) (t: 1700000000 + i * 86400, v: 450.0),
          ],
        },
      );

      await t.pumpWidget(_wrap(HealthScreen(data: d)));
      await t.pump();

      expect(find.text('Körperalter'), findsOneWidget);
      expect(find.byType(TaktBodyAgeCard), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-body-age-pace')), findsOneWidget);
      _assertAllDigitsDodged(t);
    });

    testWidgets('7 Tage: Dropdown zeigt die letzten sieben Tage neben den 30 Tagen', (t) async {
      t.view.physicalSize = const Size(390, 2600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final base = BodyAgeCalculator.calculate(
        realAge: 18,
        dataDays: 28,
        avgSleepHours: 6.5,
        avgSri: 70,
        avgRhr: 58,
        avgSteps: 7500,
        moderateMinPerWeek: 135,
        intensiveMinPerWeek: 25,
        strengthMinPerWeek: 45,
      );
      final week = BodyAgeCalculator.calculate(
        realAge: 18,
        dataDays: 7,
        avgSleepHours: 7.6,
        avgSri: 70,
        avgRhr: 58,
        avgSteps: 7500,
        moderateMinPerWeek: 135,
        intensiveMinPerWeek: 25,
        strengthMinPerWeek: 45,
      );
      final snap = base.withRecent(week);
      await t.pumpWidget(_wrap(TaktBodyAgeDetail(snapshot: snap)));
      await t.pump();
      // Gesamt: was die letzten 7 Tage ergäben.
      expect(find.byKey(const ValueKey('takt-body-age-recent-total')), findsOneWidget);
      // Zwei Punkte auf demselben Balken, ohne Aufklappen.
      expect(find.byKey(const ValueKey('takt-factor-dot-sleep_duration')), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-factor-dot-recent-sleep_duration')), findsOneWidget);
      // Zugeklappt steht die Statistik noch nicht da.
      expect(find.byKey(const ValueKey('takt-body-age-week-sleep_duration')), findsNothing);
      expect(find.byKey(const ValueKey('takt-body-age-recent-sleep_duration')), findsNothing);
      // Dropdown: Tipp auf die Zeile klappt die 7-Tage-Statistik auf.
      await t.tap(find.byKey(const ValueKey('takt-body-age-toggle-sleep_duration')));
      await t.pump();
      final legend = find.byKey(const ValueKey('takt-body-age-recent-sleep_duration'));
      expect(find.byKey(const ValueKey('takt-body-age-week-sleep_duration')), findsOneWidget);
      expect(legend, findsOneWidget);
      expect(find.descendant(of: legend, matching: find.textContaining('7 Tage')),
          findsOneWidget);
      expect(find.descendant(of: legend, matching: find.textContaining('7,6')), findsOneWidget);
      expect(find.textContaining('30 Tage · 6,5'), findsOneWidget);
      // Nochmal tippen klappt wieder zu.
      await t.tap(find.byKey(const ValueKey('takt-body-age-toggle-sleep_duration')));
      await t.pump();
      expect(find.byKey(const ValueKey('takt-body-age-week-sleep_duration')), findsNothing);
      expect(find.textContaining('Cappuccio'), findsNothing);
      _assertAllDigitsDodged(t);
    });

    testWidgets('TaktBodyAgeStrip zeigt Korridor, Chrono-Linie, Dot und Verdict', (t) async {
      final snap = BodyAgeCalculator.calculate(
        realAge: 19,
        exactAge: 18.7,
        dataDays: 20,
        avgSleepHours: 7.5,
        avgSri: 80,
        avgRhr: 54,
        avgSteps: 10000,
        moderateMinPerWeek: 150,
        intensiveMinPerWeek: 30,
        strengthMinPerWeek: 60,
      );

      await t.pumpWidget(_wrap(TaktBodyAgeStrip(snapshot: snap)));
      await t.pump();

      // Zielkorridor ist vorläufig abgeschaltet (kBodyAgeTargetCorridor, Befund 4).
      expect(find.byKey(const ValueKey('takt-body-age-corridor')),
          kBodyAgeTargetCorridor ? findsOneWidget : findsNothing);
      expect(find.byKey(const ValueKey('takt-body-age-chrono-line')), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-body-age-dot')), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-body-age-verdict')), findsOneWidget);
      _assertAllDigitsDodged(t);
    });
  });

  group('Befunde der Prüfung (pruefung.md)', () {
    final now = DateTime(2026, 11, 11, 18, 30); // Mittwoch, Woche ab 2026-11-09

    List<String> daysBack(DateTime from, int n) => [
          for (var i = 0; i < n; i++)
            dayLabelOf(DateTime(from.year, from.month, from.day - i)),
        ];

    List<ChartPoint> pts(DateTime from, int n, double v) => [
          for (var i = 0; i < n; i++)
            (
              t: DateTime(from.year, from.month, from.day - i, 12).millisecondsSinceEpoch ~/ 1000,
              v: v,
            ),
        ];

    Map<String, List<ChartPoint>> charts(DateTime at, {double rhr = 60, int n = 20}) => {
          'sleep': pts(at, n, 450), // 7,5 Std.
          'resting_hr': pts(at, n, rhr),
          'steps': pts(at, n, 8000),
        };

    BodyAgeFactor factor(BodyAgeSnapshot s, String key) =>
        s.factors.firstWhere((f) => f.key == key);

    Future<BodyAgeSnapshot> load(
      _Repo repo, {
      DateTime? at,
      double rhr = 60,
      Map<String, dynamic>? profile,
      int n = 20,
    }) {
      final d = at ?? now;
      return loadBodyAge(
        repo,
        profile: profile ?? const {'age': 18},
        insights: const {},
        charts: charts(d, rhr: rhr, n: n),
        availableDays: daysBack(d, n),
        now: d,
      );
    }

    test('P1: kStrengthWorkoutTypes stammt aus der Katalog-Gruppe Strength (ohne HIIT, Zirkel, CrossFit)', () {
      final strength =
          activityLibrary.firstWhere((g) => g.name == 'Strength').items.map((a) => a.typeKey).toSet();
      // Echte Katalog-Schlüssel.
      expect(strength, containsAll(['weight_training', 'functional', 'powerlifting']));
      expect(kStrengthWorkoutTypes,
          {'weight_training', 'powerlifting', 'bodyweight', 'calisthenics', 'kettlebell', 'functional'});
      expect(kStrengthWorkoutTypes, isNot(contains('hiit')));
      expect(kStrengthWorkoutTypes, isNot(contains('circuit_training')));
      expect(kStrengthWorkoutTypes, isNot(contains('crossfit')));
      // Jede Strength-Sportart ist entweder dabei oder ausdrücklich ausgeschlossen.
      expect(strength.difference(kStrengthWorkoutTypes), {'hiit', 'circuit_training', 'crossfit'});
      // Der WHOOP-Import mappt auf diese Schlüssel.
      for (final whoop in ['Weightlifting', 'Strength Trainer', 'Functional Fitness']) {
        expect(kStrengthWorkoutTypes, contains(WhoopImporter.activityTypeKey(whoop)),
            reason: whoop);
      }
      // Ältere Importe haben den rohen WHOOP-Namen gespeichert.
      expect(isStrengthWorkoutType('weightlifting'), isTrue);
      expect(isStrengthWorkoutType('Weight training'), isTrue);
      expect(isStrengthWorkoutType('running'), isFalse);
      expect(isStrengthWorkoutType(null), isFalse);
    });

    test('P1: loadBodyAge zählt weight_training und die anderen Strength-Schlüssel, nicht HIIT', () async {
      final ts = DateTime(2026, 11, 8, 10).millisecondsSinceEpoch ~/ 1000;
      for (final type in ['weight_training', 'bodyweight', 'functional', 'powerlifting']) {
        SharedPreferences.setMockInitialValues({});
        final repo = _Repo(workouts: [
          {'type': type, 'start_ts': ts, 'duration_min': 60},
        ]);
        final snap = await load(repo);
        // 60 Min. in 20 Kalendertagen = 21 Min./Woche.
        expect(factor(snap, 'strength').value, closeTo(21.0, 0.01), reason: type);
      }
      SharedPreferences.setMockInitialValues({});
      final hiit = await load(_Repo(workouts: [
        {'type': 'hiit', 'start_ts': ts, 'duration_min': 60},
      ]));
      expect(factor(hiit, 'strength').value, 0.0);
    });

    test('7 Tage: eigene Werte der letzten sieben Tage neben den 30 Tagen, nicht von der Wochensperre betroffen', () async {
      SharedPreferences.setMockInitialValues({});
      List<ChartPoint> sleepWith(double recentMin, double olderMin) => [
            for (var i = 0; i < 20; i++)
              (
                t: DateTime(now.year, now.month, now.day - i, 12).millisecondsSinceEpoch ~/ 1000,
                v: i < 7 ? recentMin : olderMin,
              ),
          ];
      Future<BodyAgeSnapshot> run(double recentMin) => loadBodyAge(
            _Repo(),
            profile: const {'age': 18},
            insights: const {},
            charts: {
              'sleep': sleepWith(recentMin, 360), // vorher 6 Std.
              'resting_hr': pts(now, 20, 60),
              'steps': pts(now, 20, 8000),
            },
            availableDays: daysBack(now, 20),
            now: now,
          );
      final snap = await run(480); // letzte 7 Tage: 8 Std.
      // 30 Tage (hier 20 Punkte): (7 × 8 + 13 × 6) / 20 = 6,7 Std.
      expect(factor(snap, 'sleep_duration').value, closeTo(402 / 60, 0.01));
      final r7 = snap.recent['sleep_duration'];
      expect(r7, isNotNull);
      expect(r7!.value, closeTo(8.0, 0.01));
      expect(snap.recentDays, 7);
      expect(snap.recentDiffYears, isNotNull);

      // Die Woche ist gesperrt (30 Tage). Die 7 Tage rechnen jedes Mal neu.
      final again = await run(420); // jetzt 7 Std.
      expect(factor(again, 'sleep_duration').value, closeTo(402 / 60, 0.01),
          reason: 'Wochenwert bleibt');
      expect(again.recent['sleep_duration']!.value, closeTo(7.0, 0.01));
    });

    test('7 Tage: weniger als drei Tage mit Daten ergeben keinen Vergleich', () async {
      SharedPreferences.setMockInitialValues({});
      final snap = await loadBodyAge(
        _Repo(),
        profile: const {'age': 18},
        insights: const {},
        charts: charts(now),
        availableDays: [
          for (final i in [0, 1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21])
            dayLabelOf(DateTime(now.year, now.month, now.day - i)),
        ],
        now: now,
      );
      expect(snap.recent, isEmpty);
      expect(snap.recentDiffYears, isNull);
    });

    test('P1: Krafttraining teilt durch die Kalenderspanne, nicht durch die Tage mit Daten', () async {
      final ts = DateTime(2026, 11, 8, 10).millisecondsSinceEpoch ~/ 1000;
      final days = [
        for (final i in [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28])
          dayLabelOf(DateTime(2026, 11, 11 - i)),
      ];
      final snap = await loadBodyAge(
        _Repo(workouts: [
          {'type': 'weight_training', 'start_ts': ts, 'duration_min': 60},
        ]),
        profile: const {'age': 18},
        insights: const {},
        charts: charts(now),
        availableDays: days,
        now: now,
      );
      // Spanne 29 Tage: 60 / (29/7) = 14,5, nicht 60 / (15/7) = 28.
      expect(factor(snap, 'strength').value, closeTo(60 / (29 / 7), 0.01));
    });

    test('P2: Wochen-Momentaufnahme ist gesperrt (Kopf, Faktoren, Summe, Tempo, exaktes Alter)', () async {
      final repo = _Repo();
      final profile = {'age': 18, 'birthdate': '2008-05-01'};
      final a = await load(repo, rhr: 60, profile: profile);
      // Donnerstag: andere Daten, später in der Woche: nichts ändert sich.
      final b = await load(repo,
          at: DateTime(2026, 11, 12, 9), rhr: 50, profile: profile);
      final c = await load(repo,
          at: DateTime(2026, 11, 15, 23), rhr: 70, profile: profile);
      for (final x in [b, c]) {
        expect(x.diffYears, a.diffYears);
        expect(x.bodyAge, a.bodyAge);
        expect(x.exactAge, a.exactAge);
        expect(x.paceOfAging, a.paceOfAging);
        expect(x.weekMonday, '2026-11-09');
        expect([for (final f in x.factors) f.key], [for (final f in a.factors) f.key]);
        expect([for (final f in x.factors) f.yearsShift], [for (final f in a.factors) f.yearsShift]);
        expect([for (final f in x.factors) f.value], [for (final f in a.factors) f.value]);
      }
      expect(factor(a, 'resting_hr').value, 60);
      // Die Faktoren ergeben die Kopfzahl.
      expect(a.factors.fold<double>(0, (s, f) => s + f.yearsShift), closeTo(a.diffYears, 1e-9));
      expect(a.bodyAge, closeTo(a.exactAge! + a.diffYears, 1e-9));
      // Nächste Woche (Montag): neu gerechnet, Vergleich zur Vorwoche.
      final d = await load(repo, at: DateTime(2026, 11, 16, 8), rhr: 50, profile: profile);
      expect(d.weekMonday, '2026-11-16');
      expect(factor(d, 'resting_hr').value, 50);
      expect(d.diffYears, isNot(a.diffYears));
      expect(d.prevWeekDelta, closeTo(d.diffYears - a.diffYears, 1e-9));
    });

    test('P3: typischer 18-Jähriger liegt bei etwa 0 Jahren (Referenzpunkt = typischer Wert)', () {
      final typical = BodyAgeCalculator.calculate(
        realAge: 18,
        dataDays: 30,
        avgSleepHours: 7.5,
        avgSri: 70,
        avgRhr: 55,
        avgSteps: 8000,
        moderateMinPerWeek: 150,
        intensiveMinPerWeek: 30,
        strengthMinPerWeek: 60,
      );
      expect(typical.diffYears.abs(), lessThan(1.5));
      // Vorher −7,0 Jahre und Körperalter 11,0.
      expect(typical.bodyAge!, greaterThan(16.0));
    });

    test('P3: Referenzpunkt jedes Faktors hat relatives Risiko 1,0 und 0 Jahre', () {
      final refs = {
        'sleep_duration': 7.5,
        'sleep_regularity': 70.0,
        'resting_hr': 58.0,
        'steps': 7500.0,
        'moderate_activity': 135.0,
        'intensive_activity': 25.0,
        'strength': 45.0,
      };
      for (final e in refs.entries) {
        final f = BodyAgeCalculator.factorFor(e.key, e.value)!;
        expect(f.relativeRisk, closeTo(1.0, 1e-9), reason: e.key);
        expect(f.yearsShift, closeTo(0.0, 1e-9), reason: e.key);
      }
    });

    test('P3: alle Zielwerte getroffen ergibt klar negativ, aber im begrenzten Bereich', () {
      final best = BodyAgeCalculator.calculate(
        realAge: 18,
        dataDays: 30,
        avgSleepHours: 7.5,
        avgSri: 80,
        avgRhr: 52,
        avgSteps: 10000,
        moderateMinPerWeek: 200,
        intensiveMinPerWeek: 60,
        strengthMinPerWeek: 45,
      );
      expect(best.diffYears, lessThan(-2.0));
      expect(best.diffYears, greaterThanOrEqualTo(-BodyAgeCalculator.totalCap));
      // Auch alles am Optimum bleibt in der Kappung.
      final top = BodyAgeCalculator.calculate(
        realAge: 40,
        dataDays: 30,
        avgSleepHours: 7.5,
        avgSri: 100,
        avgRhr: 40,
        avgSteps: 20000,
        moderateMinPerWeek: 600,
        intensiveMinPerWeek: 300,
        strengthMinPerWeek: 45,
      );
      expect(top.diffYears, greaterThanOrEqualTo(-10.0));
      expect(top.topLever, isNull, reason: 'am Optimum bleibt nichts zu gewinnen');
    });

    test('P3: Größter Hebel ist der größte verbesserbare Beitrag, nicht der beste', () {
      final snap = BodyAgeCalculator.calculate(
        realAge: 18,
        dataDays: 30,
        avgRhr: 45, // am Boden der Näherung: größter Gewinn, nichts mehr zu holen
        avgSteps: 5000, // ungünstig: viel zu holen
        avgSleepHours: 7.5,
      );
      final rhr = factor(snap, 'resting_hr');
      final steps = factor(snap, 'steps');
      expect(rhr.yearsShift.abs(), lessThan(steps.yearsShift.abs() + 1.0));
      expect(rhr.potentialYears, lessThan(0.05));
      expect(steps.potentialYears, greaterThan(2.0));
      expect(snap.topLever!.key, 'steps');
      expect(snap.factors.first.key, 'steps');
    });

    testWidgets('P3: Karte zeigt keinen Zielkorridor und keine Einstufung „im optimalen Zielbereich“', (t) async {
      t.view.physicalSize = const Size(390, 1200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final snap = BodyAgeCalculator.calculate(
        realAge: 18,
        dataDays: 30,
        avgSleepHours: 7.5,
        avgSri: 80,
        avgRhr: 52,
        avgSteps: 10000,
        moderateMinPerWeek: 200,
        intensiveMinPerWeek: 60,
        strengthMinPerWeek: 45,
      );
      await t.pumpWidget(_wrap(TaktBodyAgeCard(snapshot: snap)));
      await t.pump();
      expect(find.textContaining('optimalen'), findsNothing);
      expect(find.textContaining('Optimal'), findsNothing);
      expect(find.textContaining('Zielkorridor'), findsNothing);
      expect(find.byKey(const ValueKey('takt-body-age-corridor')), findsNothing);
      expect(find.textContaining('Größter Hebel'), findsOneWidget);
    });

    test('Zonen: Zone 1–3 und 4–5 werden je Tag mit Zonen auf eine Woche hochgerechnet', () async {
      SharedPreferences.setMockInitialValues({});
      final snap = await load(_Repo(zones: {'z1': 30, 'z2': 20, 'z3': 10, 'z4': 5, 'z5': 2}));
      expect(factor(snap, 'moderate_activity').value, closeTo(60 * 7, 1e-9));
      expect(factor(snap, 'intensive_activity').value, closeTo(7 * 7, 1e-9));
    });

    test('P4: Schritte zählen nur bis 10 000 (Plateau)', () {
      double years(double steps) =>
          BodyAgeCalculator.factorFor('steps', steps)!.yearsShift;
      expect(years(12000), years(10000));
      expect(years(10000), lessThan(years(8000)));
    });

    testWidgets('P4: Studienbildschirm nennt nur Belegtes und kennzeichnet die eigene Näherung', (t) async {
      t.view.physicalSize = const Size(390, 4000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(_wrap(const BodyAgeStudiesScreen()));
      await t.pump();
      expect(find.textContaining('verdoppelt das Risiko kardiovaskulärer'), findsNothing);
      expect(find.textContaining('Kohortenstudien'), findsNothing);
      expect(find.textContaining('21–23'), findsNothing);
      expect(find.textContaining('19–21'), findsNothing);
      expect(find.textContaining('3,06'), findsOneWidget);
      expect(find.textContaining('Gesamtsterblichkeit'), findsWidgets);
      expect(find.textContaining('eigene Näherung, nicht direkt aus den Studien übernommen',
          findRichText: true), findsOneWidget);
      expect(find.textContaining('kein medizinischer Befund'), findsOneWidget);
      // Lee: Zonenzuordnung ist unsere, nicht die der Studie.
      expect(find.textContaining('eigene Zuordnung'), findsNWidgets(2));
    });

    test('P4: Einstellungszeile behauptet keine „7 Kohortenstudien“ mehr', () {
      final src = File('lib/ui2/profile/settings.dart').readAsStringSync();
      expect(src, isNot(contains('7 Kohortenstudien')));
      expect(src, isNot(contains('7 cohort studies')));
    });

    testWidgets('P4: Karte und Detail tragen „grobe Schätzung, kein medizinischer Befund“ und die Näherung', (t) async {
      t.view.physicalSize = const Size(390, 3000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final snap = BodyAgeCalculator.calculate(
        realAge: 18,
        dataDays: 30,
        avgSleepHours: 6.0,
        avgRhr: 60,
        avgSteps: 6000,
        moderateMinPerWeek: 100,
      );
      await t.pumpWidget(_wrap(TaktBodyAgeCard(snapshot: snap)));
      await t.pump();
      expect(find.text('Grobe Schätzung, kein medizinischer Befund.'), findsOneWidget);

      await t.pumpWidget(_wrap(TaktBodyAgeDetail(snapshot: snap)));
      await t.pump();
      expect(find.text('Grobe Schätzung, kein medizinischer Befund.'), findsOneWidget);
      expect(find.textContaining('Eigene Näherung, nicht direkt aus den Studien übernommen'),
          findsOneWidget);
      expect(find.textContaining('Jensen'), findsNothing);
      // Die Zuordnung „Zonen statt Fragebogen“ steht im Studienbildschirm.
    });

    testWidgets('P5: im Kalibrierungszustand zeigt das Detail keine Faktor-Jahre', (t) async {
      t.view.physicalSize = const Size(390, 3000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final snap = BodyAgeCalculator.calculate(
        realAge: 18,
        dataDays: 3,
        avgSleepHours: 7.5,
        avgRhr: 70,
      );
      await t.pumpWidget(_wrap(TaktBodyAgeDetail(snapshot: snap)));
      await t.pump();
      for (final k in kBodyAgeFactorKeys) {
        final row = find.byKey(ValueKey('takt-body-age-factor-$k'));
        expect(row, findsOneWidget);
        expect(find.descendant(of: row, matching: find.textContaining('J.')), findsNothing,
            reason: k);
        expect(find.descendant(of: row, matching: find.textContaining('Jahre')), findsNothing,
            reason: k);
      }
      await t.tap(find.text('Schlafdauer'));
      await t.pump();
      expect(find.textContaining('Umrechnung'), findsNothing);
    });

    test('P5: sieben fehlende Faktoren bei ≥14 Tagen ergeben kein Ergebnis und keinen Wochenwert', () async {
      final snap = BodyAgeCalculator.calculate(realAge: 18, dataDays: 30);
      expect(snap.hasFactors, isFalse);
      expect(snap.ready, isFalse);
      expect(snap.paceOfAging, isNull);

      SharedPreferences.setMockInitialValues({});
      final loaded = await loadBodyAge(
        _Repo(failWorkouts: true),
        profile: const {'age': 18},
        insights: const {},
        charts: const {},
        availableDays: daysBack(now, 30),
        now: now,
      );
      expect(loaded.ready, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kBodyAgeWeeksKey), isNull);
    });

    testWidgets('P5: Karte ohne Messwerte zeigt statt 18,0 den Hinweis', (t) async {
      final snap = BodyAgeCalculator.calculate(realAge: 18, dataDays: 30);
      await t.pumpWidget(_wrap(TaktBodyAgeCard(snapshot: snap)));
      await t.pump();
      expect(find.byKey(const ValueKey('takt-body-age-no-factors')), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-body-age-value')), findsNothing);
      expect(find.byKey(const ValueKey('takt-body-age-pace')), findsNothing);
    });

    testWidgets('P6: Gekappte Faktoren nennen Rechenwert und angezeigten Wert', (t) async {
      t.view.physicalSize = const Size(390, 3000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final snap = BodyAgeCalculator.calculate(
        realAge: 40,
        dataDays: 30,
        avgSleepHours: 4.0,
        avgSri: 0,
        avgRhr: 100,
        avgSteps: 1500,
        moderateMinPerWeek: 0,
        intensiveMinPerWeek: 0,
        strengthMinPerWeek: 0,
      );
      expect(snap.diffYears, 10.0);
      final f = snap.factors.firstWhere((f) => f.capped);
      // Das Rechenergebnis folgt aus dem Risiko, die Anzeige danach aus der Kappung.
      expect(f.rawYears, closeTo(BodyAgeCalculator.riskToYears(f.relativeRisk), 1e-9));
      expect(f.yearsShift, lessThan(f.rawYears));

      await t.pumpWidget(_wrap(TaktBodyAgeDetail(snapshot: snap)));
      await t.pump();
      // Die Begrenzung steht direkt in der Zeile, ohne Aufklappen.
      final text = t
          .widget<Text>(find.byKey(ValueKey('takt-body-age-capped-${f.key}')))
          .data!;
      final raw = formatSignedYears(f.rawYears, true, short: true);
      final shown = formatSignedYears(f.yearsShift, true, short: true);
      expect(text, contains(raw));
      expect(text, contains('angezeigt $shown'));
    });

    test('P6: Körperalter und Abweichung widersprechen sich nicht an der 10-Jahre-Grenze', () {
      for (final age in [14, 18]) {
        final snap = BodyAgeCalculator.calculate(
          realAge: age,
          dataDays: 30,
          avgSleepHours: 7.5,
          avgSri: 100,
          avgRhr: 40,
          avgSteps: 10000,
          moderateMinPerWeek: 300,
          intensiveMinPerWeek: 150,
          strengthMinPerWeek: 45,
        );
        expect(snap.bodyAge!, greaterThanOrEqualTo(10.0 - 1e-9));
        expect(snap.bodyAge! - age, closeTo(snap.diffYears, 1e-9), reason: 'Alter $age');
        expect(snap.factors.fold<double>(0, (s, f) => s + f.yearsShift),
            closeTo(snap.diffYears, 1e-9));
        expect(snap.paceOfAging, closeTo(math.pow(2.0, snap.diffYears / 8.0), 1e-9));
      }
      final young = BodyAgeCalculator.calculate(
        realAge: 14,
        dataDays: 30,
        avgSleepHours: 7.5,
        avgSri: 100,
        avgRhr: 40,
        avgSteps: 10000,
        moderateMinPerWeek: 300,
        intensiveMinPerWeek: 150,
        strengthMinPerWeek: 45,
      );
      expect(young.bodyAge, closeTo(10.0, 1e-9));
      expect(young.diffYears, closeTo(-4.0, 1e-9));
    });

    for (final textScale in [1.0, 2.0]) {
      testWidgets('P7: Karte läuft bei 320 px und Textgröße $textScale nicht über', (t) async {
        t.view.physicalSize = const Size(320, 2400);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        TaktStripe.fraction.value = 0.5;
        final snap = BodyAgeCalculator.calculate(
          realAge: 18,
          exactAge: 18.56,
          dataDays: 30,
          avgSleepHours: 7.5,
          avgSri: 80,
          avgRhr: 52,
          avgSteps: 10000,
          moderateMinPerWeek: 200,
          intensiveMinPerWeek: 60,
          strengthMinPerWeek: 45,
          prevWeekDelta: -0.4,
        );
        await t.pumpWidget(MediaQuery(
          data: MediaQueryData(
              size: const Size(320, 2400), textScaler: TextScaler.linear(textScale)),
          child: _wrap(TaktBodyAgeCard(snapshot: snap)),
        ));
        await t.pump();
        expect(
          MediaQuery.textScalerOf(t.element(find.byType(TaktBodyAgeCard))).scale(10),
          closeTo(10 * textScale, 1e-9),
          reason: 'Textgröße kommt an',
        );
        expect(t.takeException(), isNull);
        _assertAllDigitsDodged(t);
      });
    }

    testWidgets('P7: Detail und Studienbildschirm laufen bei 320 px, Textgröße 2,0 nicht über', (t) async {
      t.view.physicalSize = const Size(320, 6000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      TaktStripe.fraction.value = 0.5;
      final snap = BodyAgeCalculator.calculate(
        realAge: 40,
        dataDays: 30,
        avgSleepHours: 4.0,
        avgSri: 0,
        avgRhr: 100,
        avgSteps: 1500,
        moderateMinPerWeek: 0,
        intensiveMinPerWeek: 0,
        strengthMinPerWeek: 0,
        prevWeekDelta: 2.0,
      );
      Widget scaled(Widget w) => MediaQuery(
            data: MediaQueryData(size: const Size(320, 6000), textScaler: TextScaler.linear(2.0)),
            child: _wrap(w),
          );
      await t.pumpWidget(scaled(TaktBodyAgeDetail(snapshot: snap)));
      await t.pump();
      expect(t.takeException(), isNull);
      await t.pumpWidget(scaled(const BodyAgeStudiesScreen()));
      await t.pump();
      expect(t.takeException(), isNull);
      _assertAllDigitsDodged(t);
    });

    testWidgets('P7: englische Kurzform heißt „y“, nicht „J.“', (t) async {
      final snap = BodyAgeCalculator.calculate(
        realAge: 18,
        dataDays: 30,
        avgSleepHours: 6.0,
        avgRhr: 60,
        avgSteps: 6000,
        prevWeekDelta: -0.4,
      );
      await t.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: TaktLook(child: TaktBodyAgeCard(snapshot: snap))),
      ));
      await t.pump();
      expect(find.textContaining('J.'), findsNothing);
      expect(find.textContaining('Top lever'), findsOneWidget);
      expect(find.textContaining(' y'), findsWidgets);
      expect(formatSignedYears(-1.9, false, short: true), endsWith(' y'));
      expect(formatSignedYears(-1.9, true, short: true), endsWith(' J.'));
    });

    test('P7: keine rohen Farben in body_age_view.dart', () {
      final src = File('lib/takt/health/body_age_view.dart').readAsStringSync();
      expect(RegExp(r'Color\(0x').hasMatch(src), isFalse);
    });

    group('P8: Robustheit', () {
      test('kaputter Speicher-String wird neu gerechnet, repariert und danach gesperrt', () async {
        SharedPreferences.setMockInitialValues({kBodyAgeWeeksKey: 'garbage{'});
        final repo = _Repo();
        final a = await load(repo, rhr: 60);
        expect(a.ready, isTrue);
        final prefs = await SharedPreferences.getInstance();
        final repaired = jsonDecode(prefs.getString(kBodyAgeWeeksKey)!) as Map;
        expect(repaired.keys, contains('2026-11-09'));
        final b = await load(repo, at: DateTime(2026, 11, 12), rhr: 50);
        expect(b.diffYears, a.diffYears, reason: 'Sperre ist an');
      });

      for (final bad in <Object>[55, 1e308, -40, 'x', true, <Object>[], {'diff': 55}, {'diff': 1e308}]) {
        test('Wert außerhalb des plausiblen Bereichs ($bad) wird verworfen und neu gerechnet', () async {
          SharedPreferences.setMockInitialValues({
            kBodyAgeWeeksKey: jsonEncode({'2026-11-09': bad}),
          });
          final a = await load(_Repo());
          expect(a.ready, isTrue);
          expect(a.diffYears.abs(), lessThanOrEqualTo(10.0));
          expect(a.paceOfAging!.isFinite, isTrue);
          expect(a.paceOfAging!, lessThan(3.0));
          final prefs = await SharedPreferences.getInstance();
          final stored = jsonDecode(prefs.getString(kBodyAgeWeeksKey)!) as Map;
          expect((stored['2026-11-09'] as Map)['diff'], a.diffYears);
        });
      }

      final fieldBreaks = <String, void Function(Map<String, dynamic> e)>{
        'Summe 12 (über ±10) bei passenden Faktoren': (e) {
          final present = [for (final f in (e['f'] as List).cast<Map>()) if (f['v'] != null) f];
          for (final f in present) {
            f['y'] = 12.0 / present.length;
          }
          e['diff'] = 12.0;
        },
        'Faktorbeitrag 55': (e) => ((e['f'] as List).first as Map)['y'] = 55,
        'Messwert 1e308': (e) => ((e['f'] as List).first as Map)['v'] = 1e308,
        'negativer Messwert': (e) => ((e['f'] as List).first as Map)['v'] = -5,
        'Alter 500': (e) => e['real'] = 500,
        'exaktes Alter 500': (e) => e['exact'] = 500,
        'Tage 9999': (e) => e['days'] = 9999,
        'Faktor doppelt': (e) => ((e['f'] as List)[1] as Map)['k'] = ((e['f'] as List)[0] as Map)['k'],
        'unbekannter Faktor': (e) => ((e['f'] as List).first as Map)['k'] = 'unbekannt',
        'Faktorliste fehlt': (e) => e['f'] = 'x',
      };
      for (final e in fieldBreaks.entries) {
        test('einzelnes Feld kaputt (${e.key}): ganze Momentaufnahme verworfen, neu gerechnet', () async {
          final repo = _Repo();
          SharedPreferences.setMockInitialValues({});
          await load(repo, rhr: 60);
          final prefs = await SharedPreferences.getInstance();
          final stored =
              jsonDecode(prefs.getString(kBodyAgeWeeksKey)!) as Map<String, dynamic>;
          e.value((stored['2026-11-09'] as Map).cast<String, dynamic>());
          // Map-Cast liefert eine Sicht auf dieselbe Map.
          await prefs.setString(kBodyAgeWeeksKey, jsonEncode(stored));
          final b = await load(repo, at: DateTime(2026, 11, 12), rhr: 50);
          expect(factor(b, 'resting_hr').value, 50, reason: 'neu gerechnet, nicht übernommen');
          expect(b.diffYears.abs(), lessThanOrEqualTo(10.0));
          expect(b.paceOfAging!, lessThan(3.0));
        });
      }

      test('Momentaufnahme, deren Faktoren nicht zur Summe passen, wird verworfen', () async {
        final repo = _Repo();
        SharedPreferences.setMockInitialValues({});
        final a = await load(repo, rhr: 60);
        final prefs = await SharedPreferences.getInstance();
        final stored = jsonDecode(prefs.getString(kBodyAgeWeeksKey)!) as Map<String, dynamic>;
        (stored['2026-11-09'] as Map)['diff'] = (a.diffYears + 2).clamp(-10.0, 10.0);
        await prefs.setString(kBodyAgeWeeksKey, jsonEncode(stored));
        final b = await load(repo, at: DateTime(2026, 11, 12), rhr: 50);
        expect(b.diffYears, isNot(a.diffYears + 2));
        expect(factor(b, 'resting_hr').value, 50, reason: 'neu gerechnet');
      });

      test('altes Format (nur die Zahl) dient als Vorwochenwert, nie als Sperre', () async {
        SharedPreferences.setMockInitialValues({
          kBodyAgeWeeksKey: jsonEncode({'2026-11-02': -1.0, '2026-11-09': -5.0}),
        });
        final a = await load(_Repo(), rhr: 60);
        expect(a.diffYears, isNot(-5.0));
        expect(a.prevWeekDelta, closeTo(a.diffYears + 1.0, 1e-9));
      });

      test('falsche Typen im Profil werfen nicht', () async {
        for (final profile in <Map<String, dynamic>>[
          {'age': '18'},
          {'age': 'abc'},
          {'age': <String, dynamic>{'x': 1}},
          {'age': 18, 'birthdate': 5},
          {'age': 18, 'birthdate': 'kein Datum'},
          {'age': double.nan},
          {'birthdate': <String>[]},
          <String, dynamic>{},
        ]) {
          SharedPreferences.setMockInitialValues({});
          final snap = await load(_Repo(), profile: profile);
          if (profile['age'] == '18') {
            expect(snap.realAge, 18);
            expect(snap.ready, isTrue);
          } else if (profile['age'] == 18) {
            expect(snap.ready, isTrue, reason: '$profile');
          } else {
            expect(snap.hasAge, isFalse, reason: '$profile');
            expect(snap.ready, isFalse);
          }
        }
      });

      test('SharedPreferences-Fehler: Live-Wert statt Absturz', () async {
        // Kein Mock-Setup nötig: Der Pfad liefert bei jedem Fehler den Live-Wert.
        SharedPreferences.setMockInitialValues({});
        final a = await load(_Repo());
        expect(a.ready, isTrue);
      });
    });
  });
}

/// Minimales Repository für `loadBodyAge`: nur, was die Berechnung liest.
class _Repo extends LocalRepository {
  _Repo({this.workouts = const [], this.zones, this.failWorkouts = false});

  final bool failWorkouts;
  final List<Map<String, dynamic>> workouts;
  final Map<String, dynamic>? zones;

  @override
  Future<Map<String, dynamic>> getProfile() async => {'age': 18};

  @override
  Future<Map<String, dynamic>> getInsights() async => {};

  @override
  Future<List<String>> availableDays() async => [];

  @override
  Future<Map<String, dynamic>> getChart(
    String metric, {
    int? from,
    int? to,
    Set<String> signals = const {},
  }) async =>
      {'points': []};

  @override
  Future<Map<String, dynamic>> getDayStrain(String date) async =>
      {if (zones != null) 'zones': zones};

  @override
  Future<Map<String, dynamic>> getWorkouts({String range = 'month'}) async {
    if (failWorkouts) throw StateError('keine Trainings');
    return {'workouts': workouts};
  }
}
