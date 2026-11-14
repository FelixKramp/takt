// Tests für Paket 1:
// - Morgen-Sync-Fix (sofortige Übernahme der abgeleiteten Nacht trotz
//   `showing_prior_overnight`-Sperrfrist auf Heute-Screen und Schlaf-Tab)
// - Wach-zu-Wach-Tageszyklus über 00:00 Uhr hinaus bis zum nächsten
//   Einschlafen/Aufwachen
// - Tages-Schalter (`TaktDayStepper`) auf dem Heute-Bildschirm
// - Ganztägiger Pulsverlauf (`TaktDayPulseCard` & `TaktPulseDetail`)
// - StripeDodge-Konformität aller neuen Zahlen

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/data/local_repository.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/state/app_state.dart';
import 'package:openstrap_edge/takt/header.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/takt/today/activity_items.dart';
import 'package:openstrap_edge/takt/today/day_pulse.dart';
import 'package:openstrap_edge/takt/today/pulse_display.dart';
import 'package:openstrap_edge/takt/today/pulse_state.dart';
import 'package:openstrap_edge/takt/today/takt_today_screen.dart';
import 'package:openstrap_edge/takt/today/wake_day.dart';
import 'package:openstrap_edge/theme/theme_controller.dart';
import 'package:openstrap_edge/ui2/screens/home_screen.dart';
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';
import 'package:provider/provider.dart';

class _MorningSyncFakeRepo extends LocalRepository {
  final bool todaySleepReady;

  _MorningSyncFakeRepo({
    this.todaySleepReady = true,
  });

  @override
  Future<List<String>> availableDays() async =>
      ['2026-11-11', '2026-11-10', '2026-11-09'];

  @override
  Future<Map<String, dynamic>> getInsights() async => {};

  @override
  Future<Map<String, dynamic>> getProfile() async => {'name': 'Felix'};

  @override
  Future<Map<String, dynamic>> getToday() async => {
        'status': {
          'today_day': '2026-11-11',
          // Simuliert die 60-Minuten-Sperrfrist nach dem Aufwachen:
          'showing_prior_overnight': true,
          'overnight_day': '2026-11-10',
          'recovery_state': 'final',
        },
        'readiness': {'value': 55, 'confidence': 0.8, 'tier': 'calibrated'},
        'sleep': {
          'duration_min': {'value': 390, 'confidence': 0.8, 'tier': 'calibrated'},
          'need_min': {'value': 480, 'confidence': 0.8, 'tier': 'calibrated'},
        },
        'daily': {
          'resting_hr': {'value': 58, 'confidence': 0.8, 'tier': 'calibrated'},
          'strain': {'value': 4.2, 'confidence': 0.8, 'tier': 'calibrated'},
          'steps': {'value': 1200, 'confidence': 0.8, 'tier': 'calibrated'},
          'calories': {'value': 180, 'confidence': 0.8, 'tier': 'calibrated'},
        },
        'hrv': {'rmssd': 74, 'confidence': 0.8, 'tier': 'calibrated'},
      };

  @override
  Future<Map<String, dynamic>> getDaySleepV2(String date) async {
    if (date == '2026-11-11') {
      if (!todaySleepReady) return {};
      final onset = DateTime(2026, 11, 10, 23, 30).millisecondsSinceEpoch ~/ 1000;
      final wake = DateTime(2026, 11, 11, 7, 30).millisecondsSinceEpoch ~/ 1000;
      return {
        'duration_min': 465,
        'need_min': 480,
        'onset_ts': onset,
        'wake_ts': wake,
        'efficiency': 0.94,
      };
    }
    if (date == '2026-11-10') {
      final onset = DateTime(2026, 11, 9, 23, 0).millisecondsSinceEpoch ~/ 1000;
      final wake = DateTime(2026, 11, 10, 7, 0).millisecondsSinceEpoch ~/ 1000;
      return {
        'duration_min': 390,
        'need_min': 480,
        'onset_ts': onset,
        'wake_ts': wake,
        'efficiency': 0.88,
      };
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> getDayOverview(String date) async {
    if (date == '2026-11-11') {
      return {
        'readiness': {'value': 84, 'confidence': 0.9, 'tier': 'calibrated'},
        'resting_hr': {'value': 51, 'confidence': 0.9, 'tier': 'calibrated'},
        'strain': {'value': 4.2, 'confidence': 0.9, 'tier': 'calibrated'},
        'steps': {'value': 1200, 'confidence': 0.9, 'tier': 'calibrated'},
        'calories': {'value': 180, 'confidence': 0.9, 'tier': 'calibrated'},
        'sleep_min': {'value': 465, 'confidence': 0.9, 'tier': 'calibrated'},
        'sleep_need_min': {'value': 480, 'confidence': 0.9, 'tier': 'calibrated'},
      };
    }
    if (date == '2026-11-10') {
      return {
        'readiness': {'value': 62, 'confidence': 0.9, 'tier': 'calibrated'},
        'resting_hr': {'value': 56, 'confidence': 0.9, 'tier': 'calibrated'},
        'strain': {'value': 12.0, 'confidence': 0.9, 'tier': 'calibrated'},
        'steps': {'value': 8500, 'confidence': 0.9, 'tier': 'calibrated'},
        'calories': {'value': 640, 'confidence': 0.9, 'tier': 'calibrated'},
        'sleep_min': {'value': 390, 'confidence': 0.9, 'tier': 'calibrated'},
        'sleep_need_min': {'value': 480, 'confidence': 0.9, 'tier': 'calibrated'},
      };
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> getDayStrain(String date) async {
    if (date == '2026-11-10') {
      final t1 = DateTime(2026, 11, 10, 12, 0).millisecondsSinceEpoch ~/ 1000;
      final t2 = DateTime(2026, 11, 10, 22, 0).millisecondsSinceEpoch ~/ 1000;
      return {
        'strain': 12.0,
        'steps': 8500,
        'calories': 640,
        'curve': [
          {'t': t1, 'v': 6.0},
          {'t': t2, 'v': 12.0},
        ],
      };
    }
    if (date == '2026-11-11') {
      final t0 = DateTime(2026, 11, 11, 0, 30).millisecondsSinceEpoch ~/ 1000;
      final t1 = DateTime(2026, 11, 11, 10, 0).millisecondsSinceEpoch ~/ 1000;
      return {
        'strain': todaySleepReady ? 6.5 : 4.2,
        'steps': 1200,
        'calories': 180,
        'curve': [
          // Vor dem Einschlafen / Aufwachen (00:30 Uhr): gehört noch zum 10.11.
          {'t': t0, 'v': 4.2},
          // Nach dem Aufwachen (10:00 Uhr):
          if (todaySleepReady) {'t': t1, 'v': 6.5},
        ],
      };
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> getDayTimeline(String date) async => {};

  @override
  Future<Map<String, dynamic>> getChart(String metric,
          {int? from, int? to, Set<String> signals = const {}}) async =>
      {};

  @override
  Future<List<Map<String, dynamic>>> sleepWindows(
          {int days = 60, String? before}) async =>
      [];
}

/// Wie [_MorningSyncFakeRepo], aber mit Schritt-Zeitspannen und einer Nacht,
/// die erst um 01:45 beginnt: Der 10.11. läuft bis dahin weiter.
class _StepsFakeRepo extends _MorningSyncFakeRepo {
  _StepsFakeRepo() : super(todaySleepReady: true);

  static int _ts(int d, int h, [int m = 0]) =>
      DateTime(2026, 11, d, h, m).millisecondsSinceEpoch ~/ 1000;

  @override
  Future<Map<String, dynamic>> getDaySleepV2(String date) async {
    if (date == '2026-11-11') {
      return {
        'duration_min': 435,
        'need_min': 480,
        'onset_ts': _ts(11, 1, 45),
        'wake_ts': _ts(11, 9),
        'efficiency': 0.9,
      };
    }
    return super.getDaySleepV2(date);
  }

  @override
  Future<Map<String, dynamic>> getDaySteps(String date) async {
    Map<String, dynamic> span(int d, int h0, int m0, int h1, int m1, int n) => {
          'start_ts': _ts(d, h0, m0),
          'end_ts': _ts(d, h1, m1),
          'steps': n,
        };
    if (date == '2026-11-10') {
      return {
        'spans': [
          span(10, 6, 0, 7, 0, 250), // vor dem Aufwachen (07:00)
          span(10, 7, 0, 22, 0, 8250),
        ],
      };
    }
    if (date == '2026-11-11') {
      return {
        'spans': [
          span(11, 0, 0, 1, 0, 500), // wach nach Mitternacht
          span(11, 1, 30, 2, 30, 400), // 15 von 60 Minuten vor dem Einschlafen
          span(11, 9, 0, 10, 0, 300), // nach dem Aufwachen
        ],
      };
    }
    return {'spans': []};
  }
}

bool _hasDigit(RenderParagraph p) =>
    RegExp(r'\d').hasMatch(p.text.toPlainText(includeSemanticsLabels: false));

void main() {
  group('Strain-Umrechnung & Wachfenster', () {
    test('strainToNetTrimp und netTrimpToStrain sind zueinander invers', () {
      for (final s in [0.0, 2.5, 7.0, 12.4, 16.8, 20.5, 21.0]) {
        expect(netTrimpToStrain(strainToNetTrimp(s)), closeTo(s, 1e-6));
      }
    });

    test('subtractPreWakeStrain zieht Vor-Aufwach-Belastung ab und combineStrain addiert sie zum Vortag', () {
      const preWake = 4.2;
      const prevDay = 12.0;
      final combined = combineStrain(prevDay, preWake)!;
      expect(combined, greaterThan(prevDay));

      // Wenn um 00:30 Uhr 4.2 Strain angefallen sind und bis 10:00 Uhr insgesamt 6.5:
      final morningOnly = subtractPreWakeStrain(6.5, preWake);
      expect(morningOnly, lessThan(6.5));
      expect(combineStrain(morningOnly, preWake), closeTo(6.5, 1e-6));
    });

    test('Nach 00:00 Uhr ohne abgeschlossene neue Nacht bleibt der Vortag aktiv', () {
      final active = resolveActiveTaktDay(
        now: DateTime(2026, 11, 11, 1, 30),
        availableDays: ['2026-11-10', '2026-11-09'],
        todayHasSleep: false,
        nightInProgress: false,
      );
      expect(active, '2026-11-10');
    });

    test('Sobald die neue Nacht berechnet ist, schaltet der aktive Tag auf heute um', () {
      final active = resolveActiveTaktDay(
        now: DateTime(2026, 11, 11, 7, 45),
        availableDays: ['2026-11-11', '2026-11-10'],
        todayHasSleep: true,
        nightInProgress: false,
      );
      expect(active, '2026-11-11');
    });

    test('Aktivitäten nach 00:00 Uhr vor dem nächsten Einschlafen zählen noch zum Wachtag', () {
      final wake10 = DateTime(2026, 11, 10, 7, 30).millisecondsSinceEpoch ~/ 1000;
      final onset11 = DateTime(2026, 11, 11, 1, 45).millisecondsSinceEpoch ~/ 1000;
      final win = buildWakeWindow(
        dayId: '2026-11-10',
        sleep: {'wake_ts': wake10},
        nextSleep: {'onset_ts': onset11},
        isActiveAfterMidnight: false,
      );
      final lateRunTs = DateTime(2026, 11, 11, 0, 30).millisecondsSinceEpoch ~/ 1000;
      final nextDayRunTs = DateTime(2026, 11, 11, 14, 0).millisecondsSinceEpoch ~/ 1000;
      final items = todayActivities(
        [
          {'id': 'w-late', 'start_ts': lateRunTs, 'type': 'running', 'duration_min': 30},
          {'id': 'w-next', 'start_ts': nextDayRunTs, 'type': 'running', 'duration_min': 40},
        ],
        DateTime(2026, 11, 10),
        fromSec: win.fromSec,
        toSec: win.toSec,
      );
      expect(items.map((e) => e.id).toList(), ['w-late']);
    });
  });

  group('Morgen-Sync-Fix', () {
    test('SleepData.load öffnet sofort die neue Nacht statt an `showing_prior_overnight` zu hängen', () async {
      final repo = _MorningSyncFakeRepo(todaySleepReady: true);
      final d = await SleepData.load(repo);
      expect(d.day, '2026-11-11');
      expect(d.latestDay, '2026-11-11');
      expect(d.night['duration_min'], 465);
    });

    test('loadTaktDay übernimmt am Morgen sofort Schlaf, Batterie, Ruhepuls und HRV von heute', () async {
      final repo = _MorningSyncFakeRepo(todaySleepReady: true);
      final loaded = await loadTaktDay(
        repo,
        now: DateTime(2026, 11, 11, 7, 40),
      );
      expect(loaded.dayId, '2026-11-11');
      expect(loaded.activeDayId, '2026-11-11');
      expect(loaded.data.readiness.value, 84);
      expect(loaded.data.rhr.value, 51);
      expect(loaded.data.sleepMin.value, 465);
      expect(loaded.hrv.value, 74);
      // Vor dem Aufwachen angefallener Strain (4.2 um 00:30 Uhr) wurde abgezogen:
      expect(loaded.data.strain.value, closeTo(subtractPreWakeStrain(6.5, 4.2), 1e-4));
    });

    test('loadTaktDay bleibt um 01:00 Uhr nachts vor dem Einschlafen beim Vortag und rechnet Nach-Mitternacht-Werte hinzu', () async {
      final repo = _MorningSyncFakeRepo(todaySleepReady: false);
      final loaded = await loadTaktDay(
        repo,
        now: DateTime(2026, 11, 11, 1, 0),
      );
      expect(loaded.activeDayId, '2026-11-10');
      expect(loaded.dayId, '2026-11-10');
      expect(loaded.data.readiness.value, 62);
      // Schritte (8500 + 1200) und Strain (12.0 + 4.2) laufen nach 00:00 Uhr weiter:
      expect(loaded.data.steps.value, 9700);
      expect(loaded.data.strain.value, closeTo(combineStrain(12.0, 4.2)!, 1e-4));
    });
  });

  group('Tages-Schalter & Ganztages-Pulsverlauf', () {
    testWidgets('Heute-Screen mit Tages-Schalter und vergangenem Tag zeigt den Ganztages-Pulsverlauf und hält StripeDodge ein', (t) async {
      TaktStripe.fraction.value = 0.68;
      addTearDown(() => TaktStripe.fraction.value = null);
      t.view.physicalSize = const Size(390, 1800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      final startSec = DateTime(2026, 11, 10, 8, 0).millisecondsSinceEpoch ~/ 1000;
      final pulseData = DayPulseData.fromSamples([
        for (var i = 0; i < 60; i++)
          (startSec + i * 600, 62.0 + (i % 15)),
      ]);

      String? pickedDay;
      await t.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: TaktTodayView(
            data: HomeData(
              readiness: Metric.parse({'value': 74, 'unit': '%'}),
              strain: Metric.parse({'value': 11.4, 'unit': ''}),
              sleepMin: Metric.parse({'value': 450, 'unit': 'min'}),
              rhr: Metric.parse({'value': 52, 'unit': 'bpm'}),
              steps: Metric.parse({'value': 9120, 'unit': 'steps'}),
            ),
            hrv: Metric.parse({'value': 68, 'unit': 'ms'}),
            dayStepper: TaktDayStepper(
              day: '2026-11-10',
              days: const ['2026-11-11', '2026-11-10', '2026-11-09'],
              labelOf: (d, de) => d == '2026-11-11' ? 'Heute' : dayShortLabel(d, de),
              onDay: (d) => pickedDay = d,
            ),
            pulse: TaktDayPulseCard(data: pulseData),
          ),
        ),
      ));
      await t.pump();

      expect(t.takeException(), isNull);
      expect(find.byType(TaktDayPulseCard), findsOneWidget);
      expect(find.textContaining('10. Nov.'), findsOneWidget);

      // Jede Ziffer steht in einem StripeDodge:
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
        expect(wrapped, isTrue,
            reason: '"${p.text.toPlainText()}" steht ohne StripeDodge');
      }

      // Pfeil nach rechts schaltet auf den neueren Tag (11.11.):
      await t.tap(find.byKey(const ValueKey('takt-day-next')));
      await t.pump();
      expect(pickedDay, '2026-11-11');
    });

    testWidgets('TaktPulseDetail zeigt Live-Puls, Ganztages-Kurve und Min/Ø/Max mit StripeDodge', (t) async {
      TaktStripe.fraction.value = 0.55;
      addTearDown(() => TaktStripe.fraction.value = null);
      t.view.physicalSize = const Size(390, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      final app = AppState.forTesting();
      addTearDown(app.dispose);
      final startSec = DateTime(2026, 11, 11, 8, 0).millisecondsSinceEpoch ~/ 1000;
      final samplePulse = DayPulseData.fromSamples([
        (startSec, 58.0),
        (startSec + 1800, 74.0),
        (startSec + 3600, 132.0),
      ]);

      await t.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: app),
          ChangeNotifierProvider<ThemeController>(
            create: (_) => ThemeController.seed(AppThemeChoice.light, Brightness.light),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          locale: const Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: TaktLook(
            child: TaktPulseDetail(
              initialDay: '2026-11-11',
              activeDay: '2026-11-11',
              days: const ['2026-11-11', '2026-11-10'],
              data: samplePulse,
              pulse: const PulseView(
                state: PulseState(PulseKind.live, bpm: 72),
                trace: [70, 72, 74, 72],
              ),
            ),
          ),
        ),
      ));
      await t.pump();

      expect(t.takeException(), isNull);
      expect(find.text('puls'), findsOneWidget);
      expect(find.text('Heute'), findsOneWidget);
      expect(find.text('58'), findsOneWidget);
      expect(find.text('88'), findsOneWidget);
      expect(find.text('132'), findsOneWidget);

      final paragraphs =
          t.allRenderObjects.whereType<RenderParagraph>().where(_hasDigit).toList();
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
        expect(wrapped, isTrue,
            reason: '"${p.text.toPlainText()}" steht ohne StripeDodge');
      }
    });
  });

  group('Gruppe D: Wachtag- & Heute-Fixes', () {
    test('W7: Fallback-Schlaf von gestern wird nicht fälschlich als heutige Nacht gewertet', () async {
      final repo = _W7FakeRepo();
      final loaded = await loadTaktDay(
        repo,
        now: DateTime(2026, 11, 12, 0, 30),
      );
      expect(loaded.activeDayId, equals('2026-11-11'));
      expect(loaded.dayId, equals('2026-11-11'));
    });

    test('W22: DayPulseData.load fällt bei unvollständigen Rohdaten am Grenztag auf Bundle zurück', () async {
      final repo = _W22GrenztagFakeRepo();
      final fromSec = DateTime(2026, 11, 10, 8, 0).millisecondsSinceEpoch ~/ 1000;
      final toSec = DateTime(2026, 11, 10, 22, 0).millisecondsSinceEpoch ~/ 1000;
      final win = WakeWindow(dayId: '2026-11-10', fromSec: fromSec, toSec: toSec);
      final data = await DayPulseData.load(
        repo,
        '2026-11-10',
        window: win,
        hrSamples: (a, b) => repo.hrSamplesInRange(a, b),
      );
      expect(data.t0, isNotNull);
      expect(data.t0!.hour, equals(8));
    });
  });

  group('W15: Schritte gehören zum Wachtag', () {
    test('der neue Tag zählt nur Schritte ab dem Aufwachen', () async {
      final loaded = await loadTaktDay(
        _StepsFakeRepo(),
        now: DateTime(2026, 11, 11, 10, 30),
      );
      expect(loaded.dayId, '2026-11-11');
      // Kalendertag-Summe wären 1200; im Wachfenster ab 09:00 sind es 300.
      expect(loaded.data.steps.value, 300);
    });

    test('der Vortag zählt die Schritte nach Mitternacht bis zum Einschlafen mit', () async {
      final loaded = await loadTaktDay(
        _StepsFakeRepo(),
        selectedDay: '2026-11-10',
        now: DateTime(2026, 11, 11, 10, 30),
      );
      expect(loaded.dayId, '2026-11-10');
      // 8250 ab 07:00, dazu 500 (00:00 bis 01:00) und 100 (15 von 60 Minuten
      // der Spanne 01:30 bis 02:30). Die 250 vor dem Aufwachen sind raus.
      expect(loaded.data.steps.value, 8850);
    });

    test('ohne Schritt-Spannen bleibt der bisherige Wert', () async {
      final loaded = await loadTaktDay(
        _MorningSyncFakeRepo(todaySleepReady: true),
        selectedDay: '2026-11-10',
        now: DateTime(2026, 11, 11, 10, 30),
      );
      expect(loaded.data.steps.value, isNotNull);
    });
  });


  group('W14: Wochensäulen rechnen wie der Tages-Schalter', () {
    test('derselbe Tag hat in der Woche denselben Spitzenwert wie im Tages-Schalter', () async {
      final repo = _StepsFakeRepo();
      final now = DateTime(2026, 11, 11, 10, 30);
      final days = ['2026-11-11', '2026-11-10'];
      final week = await wakeDayStrainPeaks(repo, days,
          activeDay: '2026-11-11', now: now);
      for (final d in days) {
        final loaded = await loadTaktDay(repo, selectedDay: d, now: now);
        expect(week[d], isNotNull, reason: d);
        expect(week[d], closeTo(loaded.strainPeak!, 1e-9), reason: d);
      }
      // Der Vortag trägt die 4,2 von 00:30 Uhr mit (nicht 12,0 wie am Kalendertag).
      expect(week['2026-11-10'], closeTo(combineStrain(12.0, 4.2)!, 1e-4));
      expect(week['2026-11-10'], greaterThan(12.0));
    });
  });

}

class _W7FakeRepo extends LocalRepository {
  @override
  Future<List<String>> availableDays() async => ['2026-11-11'];

  @override
  Future<Map<String, dynamic>> getToday() async => {
        'status': {'recovery_state': null},
        'daily': {},
      };

  @override
  Future<Map<String, dynamic>> getDaySleepV2(String date) async {
    return {
      'date': '2026-11-11',
      'duration_min': 420,
      'wake_ts': DateTime(2026, 11, 11, 7, 0).millisecondsSinceEpoch ~/ 1000,
    };
  }

  @override
  Future<Map<String, dynamic>> getDayOverview(String date) async => {};

  @override
  Future<Map<String, dynamic>> getDayStrain(String date) async => {
        'strain': 10.0,
        'curve': [],
      };

  @override
  Future<Map<String, dynamic>> getInsights() async => {};

  @override
  Future<Map<String, dynamic>> getProfile() async => {'name': 'Felix'};
}

class _W22GrenztagFakeRepo extends LocalRepository {
  @override
  Future<Map<String, dynamic>> getDayTimeline(String date) async {
    final startSec = DateTime(2026, 11, 10, 8, 0).millisecondsSinceEpoch ~/ 1000;
    return {
      'hr': [
        for (var i = 0; i < 60; i++)
          {'t': startSec + i * 600, 'v': 65.0},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> getDaySleepV2(String date) async => {};

  Future<List<(int, int)>> hrSamplesInRange(int fromSec, int toSec) async {
    final rawStart = DateTime(2026, 11, 10, 14, 0).millisecondsSinceEpoch ~/ 1000;
    return [
      for (var i = 0; i < 30; i++) (rawStart + i * 600, 70),
    ];
  }

}
