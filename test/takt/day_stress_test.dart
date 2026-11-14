import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/data/local_repository.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/l10n/decimal_text.dart' show displayFixed;
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/stress/day_stress.dart';
import 'package:openstrap_edge/takt/stress/takt_stress_view.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';

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

Widget _wrap(Widget child, {Locale locale = const Locale('de'), double textScale = 1.0}) {
  Widget w = MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: TaktLook(child: child)),
  );
  if (textScale != 1.0) {
    w = MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: w,
    );
  }
  return w;
}

/// Repository mit genau den Feldern, die `DayStressCalculator.loadForDay` liest.
class _StressRepo extends LocalRepository {
  _StressRepo({this.age, this.dayMax, this.maxHrUsed, this.hr = const []});

  final num? age;
  final num? dayMax;
  final num? maxHrUsed;
  final List<Map<String, dynamic>> hr;

  @override
  Future<Map<String, dynamic>> getDayTimeline(String date) async =>
      {'date': date, 'hr': hr, 'sleep': [], 'sessions': []};

  @override
  Future<Map<String, dynamic>> getDayStress(String date) async => {};

  @override
  Future<Map<String, dynamic>> getDayHeart(String date) async => {
        'baselines': {
          'resting_hr': {'usual': 55},
        },
        if (dayMax != null) 'max_hr': dayMax,
      };

  @override
  Future<Map<String, dynamic>> getDayStrain(String date) async =>
      {if (maxHrUsed != null) 'max_hr_used': maxHrUsed};

  @override
  Future<Map<String, dynamic>> getProfile() async =>
      {if (age != null) 'age': age};
}

List<Map<String, dynamic>> _flat(int t0, num bpm) => [
      for (var i = 0; i < 10; i++) {'t': t0 + i * 30, 'v': bpm},
    ];

void main() {
  group('Stress-Basis (G14/G15)', () {
    test('G15: ohne Maximalpuls kein erfundener Ersatz (Ruhepuls + 120)', () {
      // Ohne Maximalpuls gibt es keine Sportgrenze. 150 bpm bei Ruhepuls 55
      // wären mit dem erfundenen Ersatz (175) Sport, ohne ihn nicht.
      final res = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: _flat(1700000000, 150),
        restingHr: 55,
      );
      expect(res.samples, isNotEmpty);
      expect(res.samples.every((s) => !s.isActivity), isTrue);
    });

    test('G14: der Tageshöchstwert verschiebt die Sportgrenze nicht', () {
      // Alter 60 → persönlicher Maximalpuls 166 (Tanaka), Grenze bei 75 % HRR
      // = 55 + 0,75 × 111 = 138,25. Der Tageshöchstwert 180 (ein Sprint) darf
      // sie nicht auf 148,75 heben: 142 bpm ist Sport.
      final repo = _StressRepo(age: 60, dayMax: 180, hr: _flat(1700000000, 142));
      return DayStressCalculator.loadForDay(repo, '2026-11-11').then((res) {
        expect(res.samples, isNotEmpty);
        expect(res.samples.every((s) => s.isActivity), isTrue);
      });
    });

    test('G14: der persönliche Wert der App (max_hr_used) hat Vorrang', () {
      // max_hr_used 190 → Grenze 55 + 0,75 × 135 = 156. 142 bpm ist kein Sport.
      final repo = _StressRepo(
          age: 60, dayMax: 180, maxHrUsed: 190, hr: _flat(1700000000, 142));
      return DayStressCalculator.loadForDay(repo, '2026-11-11').then((res) {
        expect(res.samples, isNotEmpty);
        expect(res.samples.every((s) => !s.isActivity), isTrue);
      });
    });

    test('G15: weder Alter noch max_hr_used: keine Sportgrenze, kein Ersatzwert', () {
      final repo = _StressRepo(dayMax: 180, hr: _flat(1700000000, 150));
      return DayStressCalculator.loadForDay(repo, '2026-11-11').then((res) {
        expect(res.samples, isNotEmpty);
        expect(res.samples.every((s) => !s.isActivity), isTrue);
      });
    });
  });

  group('DayStressCalculator', () {
    test('returns empty analysis when hrCurve is empty', () {
      final res = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: const [],
      );
      expect(res.hasData, isFalse);
      expect(res.samples, isEmpty);
      expect(res.avgStress, isNull);
      expect(res.lowStressMin, equals(0));
    });

    // G15: Nie erfundene Werte (Regel 3). Ohne Ruhebasis leer.
    test('G15: returns empty analysis when restingHr is null or <= 0', () {
      final nowSec = 1700000000;
      final hrCurve = [
        {'t': nowSec, 'v': 60},
        {'t': nowSec + 30, 'v': 62},
      ];

      final resNull = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: hrCurve,
        restingHr: null,
      );
      expect(resNull.hasData, isFalse);
      expect(resNull.avgStress, isNull);

      final resZero = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: hrCurve,
        restingHr: 0.0,
      );
      expect(resZero.hasData, isFalse);
    });

    // G18: Mindestabdeckung je 5-Min-Bin (mindestens 2 Samples nötig)
    test('G18: bin with single isolated sample is skipped', () {
      final nowSec = 1700000000;
      final hrCurve = [
        {'t': nowSec, 'v': 60}, // Nur 1 Sample in diesem Bin
      ];

      final res = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: hrCurve,
        restingHr: 50.0,
      );
      expect(res.hasData, isFalse);
      expect(res.samples, isEmpty);
    });

    // G13: Physisches Training bekommt score = null (nicht 2.5)
    test('G13: workouts have null score and do not skew avg stress or peak', () {
      final nowSec = (1700000000 ~/ 300) * 300;
      final hrCurve = <Map<String, dynamic>>[];

      // 4 Bins (20 min): Wachstress (HR = 65, RHR = 50) -> ca. 0.35
      for (var i = 0; i < 4; i++) {
        hrCurve.add({'t': nowSec + i * 300, 'v': 65});
        hrCurve.add({'t': nowSec + i * 300 + 30, 'v': 65});
      }

      // 4 Bins (20 min): Workout (Running)
      final workoutStart = nowSec + 4 * 300;
      final workoutEnd = nowSec + 8 * 300;
      for (var i = 4; i < 8; i++) {
        hrCurve.add({'t': nowSec + i * 300, 'v': 150});
        hrCurve.add({'t': nowSec + i * 300 + 30, 'v': 150});
      }

      final res = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: hrCurve,
        restingHr: 50.0,
        maxHr: 185.0,
        workouts: [(workoutStart, workoutEnd, 'Running')],
      );

      expect(res.hasData, isTrue);
      expect(res.activityMin, equals(20));
      for (final s in res.samples.where((s) => s.isActivity)) {
        expect(s.score, isNull, reason: 'G13: Workout bins must have score == null, not 2.5');
        expect(s.activityName, equals('Running'));
      }
      // Peak stress must NOT be 2.5 from the workout
      expect(res.peakStress, isNotNull);
      expect(res.peakStress!, lessThan(1.5));
    });

    // G14: Sportgrenze bei 75 % HRR gegen persönliche maxHr
    test('G14: high heart rate above 75% HRR is classified as activity', () {
      final nowSec = 1700000000;
      final hrCurve = <Map<String, dynamic>>[];

      // rhr = 50, mhr = 190. 75% HRR = 50 + 0.75 * 140 = 155 bpm.
      // Bin at 160 bpm -> Activity
      hrCurve.add({'t': nowSec, 'v': 160});
      hrCurve.add({'t': nowSec + 30, 'v': 160});

      final res = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: hrCurve,
        restingHr: 50.0,
        maxHr: 190.0,
      );

      expect(res.hasData, isTrue);
      expect(res.samples.first.isActivity, isTrue);
      expect(res.samples.first.score, isNull);
    });

    test('correctly calculates low, medium, high stress zones and activities', () {
      final nowSec = (1700000000 ~/ 300) * 300;
      final hrCurve = <Map<String, dynamic>>[];

      // 10 5-min intervals (50 mins): Low stress (HR = 55 bpm, RHR = 50 bpm)
      for (var i = 0; i < 10; i++) {
        hrCurve.add({'t': nowSec + i * 300, 'v': 55});
        hrCurve.add({'t': nowSec + i * 300 + 30, 'v': 55});
      }

      // 6 5-min intervals (30 mins): Medium stress (HR = 78 bpm, RHR = 50 bpm)
      for (var i = 10; i < 16; i++) {
        hrCurve.add({'t': nowSec + i * 300, 'v': 78});
        hrCurve.add({'t': nowSec + i * 300 + 30, 'v': 78});
      }

      // 4 5-min intervals (20 mins): High stress (HR = 100 bpm, RHR = 50 bpm)
      for (var i = 16; i < 20; i++) {
        hrCurve.add({'t': nowSec + i * 300, 'v': 100});
        hrCurve.add({'t': nowSec + i * 300 + 30, 'v': 100});
      }

      // 4 5-min intervals (20 mins): Workout activity
      final workoutStart = nowSec + 20 * 300;
      final workoutEnd = nowSec + 24 * 300;
      for (var i = 20; i < 24; i++) {
        hrCurve.add({'t': nowSec + i * 300, 'v': 145});
        hrCurve.add({'t': nowSec + i * 300 + 30, 'v': 145});
      }

      final res = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: hrCurve,
        restingHr: 50.0,
        maxHr: 185.0,
        workouts: [(workoutStart, workoutEnd, 'Running')],
      );

      expect(res.hasData, isTrue);
      expect(res.samples.length, equals(24));
      expect(res.lowStressMin, greaterThan(0));
      expect(res.mediumStressMin, greaterThan(0));
      expect(res.highStressMin, greaterThan(0));
      expect(res.activityMin, equals(20)); // 4 intervals * 5 min = 20 min
      expect(res.avgStress, isNotNull);
      expect(res.avgStress!, inInclusiveRange(0.0, 3.0));
    });

    test('sleep periods are marked as isSleep and low score', () {
      final nowSec = (1700000000 ~/ 300) * 300;
      final hrCurve = <Map<String, dynamic>>[];

      // Sleep window: 10 intervals (50 min)
      for (var i = 0; i < 10; i++) {
        hrCurve.add({'t': nowSec + i * 300 + 10, 'v': 52});
        hrCurve.add({'t': nowSec + i * 300 + 30, 'v': 52});
      }

      final res = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: hrCurve,
        restingHr: 50.0,
        sleepWindows: [(nowSec, nowSec + 3000)],
      );

      expect(res.hasData, isTrue);
      expect(res.sleepMin, equals(50));
      for (final s in res.samples) {
        expect(s.isSleep, isTrue);
        expect(s.score, lessThan(1.0));
      }
    });

    test('latestAwakeSample returns the most recent non-sleep and non-activity sample', () {
      final nowSec = 1700000000;
      final hrCurve = [
        {'t': nowSec, 'v': 55},
        {'t': nowSec + 30, 'v': 55},
        {'t': nowSec + 300, 'v': 75},
        {'t': nowSec + 330, 'v': 75},
        {'t': nowSec + 600, 'v': 95},
        {'t': nowSec + 630, 'v': 95},
      ];

      final res = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: hrCurve,
        restingHr: 50.0,
      );

      expect(res.latestAwakeSample, isNotNull);
      expect(res.latestAwakeSample!.timestampSec, equals(1700000550));
    });

    // G22: shiftDayString handles DST transitions
    test('G22: shiftDayString shifts correctly across autumn DST change (2026-10-25)', () {
      expect(shiftDayString('2026-10-25', 1), equals('2026-10-26'));
      expect(shiftDayString('2026-10-26', -1), equals('2026-10-25'));
    });
  });

  group('TaktStress UI & Displaystreifen B5', () {
    testWidgets('TaktStressCard zeigt Live-Stress, Durchschnitt, Spitze und dodged alle Ziffern', (t) async {
      final nowSec = 1700000000;
      final hrCurve = [
        {'t': nowSec, 'v': 55},
        {'t': nowSec + 30, 'v': 55},
        {'t': nowSec + 300, 'v': 75},
        {'t': nowSec + 330, 'v': 75},
        {'t': nowSec + 600, 'v': 95},
        {'t': nowSec + 630, 'v': 95},
      ];

      final res = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: hrCurve,
        restingHr: 50.0,
      );

      await t.pumpWidget(_wrap(TaktStressCard(analysis: res)));
      await t.pump();

      expect(find.byKey(const ValueKey('takt-stress-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-stress-card-score')), findsOneWidget);
      expect(find.byKey(const ValueKey('takt-stress-card-latest')), findsOneWidget);
      _assertAllDigitsDodged(t);
    });

    testWidgets('Die große Zahl ist der aktuelle Stress, nicht der Tagesdurchschnitt', (t) async {
      final t0 = 1700000000;
      final res = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: [
          for (var bin = 0; bin < 8; bin++)
            for (var i = 0; i < 4; i++)
              {'t': t0 + bin * 300 + i * 30, 'v': bin < 6 ? 95 : 62},
        ],
        restingHr: 50.0,
        maxHr: 200.0,
      );
      final latest = res.latestAwakeSample!.score!;
      final avg = res.avgStress!;
      expect(displayFixed(latest, 1), isNot(displayFixed(avg, 1)),
          reason: 'Annahme des Tests: aktuell und Durchschnitt unterscheiden sich');

      await t.pumpWidget(_wrap(TaktStressCard(analysis: res)));
      await t.pump();

      final big = t.widget<Text>(find.byKey(const ValueKey('takt-stress-card-score')));
      expect(big.data, displayFixed(latest, 1));
      expect(find.text('Aktuell'), findsOneWidget);
      expect(find.textContaining('Ø'), findsOneWidget, reason: 'Durchschnitt steht klein daneben');
      _assertAllDigitsDodged(t);
    });

    // G29: Detailansicht dodged ausnahmslos alle Ziffern
    testWidgets('G29: TaktStressDetailScreen dodged ausnahmslos alle Ziffern', (t) async {
      final nowSec = 1700000000;
      final hrCurve = [
        {'t': nowSec, 'v': 55},
        {'t': nowSec + 30, 'v': 55},
        {'t': nowSec + 300, 'v': 75},
        {'t': nowSec + 330, 'v': 75},
      ];

      final res = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: hrCurve,
        restingHr: 50.0,
      );

      await t.pumpWidget(_wrap(TaktStressDetailScreen(
        initialDate: '2026-11-11',
        injectedAnalysis: res,
      )));
      await t.pumpAndSettle();

      _assertAllDigitsDodged(t);
    });

    // G30: Keine Überläufe bei 320 px und Schriftgröße 1.0 / 2.0
    testWidgets('G30: TaktStressDetailScreen überläuft nicht bei 320 px und Schriftgröße 1.0', (t) async {
      t.view.physicalSize = const Size(320 * 2, 700 * 2);
      t.view.devicePixelRatio = 2.0;
      addTearDown(() => t.view.resetPhysicalSize());

      final nowSec = 1700000000;
      final hrCurve = [
        {'t': nowSec, 'v': 55},
        {'t': nowSec + 30, 'v': 55},
        {'t': nowSec + 300, 'v': 75},
        {'t': nowSec + 330, 'v': 75},
      ];

      final res = DayStressCalculator.compute(
        date: '2026-11-11',
        hrCurve: hrCurve,
        restingHr: 50.0,
      );

      await t.pumpWidget(_wrap(TaktStressDetailScreen(
        initialDate: '2026-11-11',
        injectedAnalysis: res,
      )));
      await t.pumpAndSettle();

      expect(t.takeException(), isNull);
    });
  });
}
