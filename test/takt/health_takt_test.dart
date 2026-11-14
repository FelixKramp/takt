// Tests für den überarbeiteten Gesundheit-Tab im Takt-Design (Feature 05)
// sowie die auffällige Aktivitäten-Kachel und die Shell-Tab-Deaktivierung:
// - Shell: Aktivität-Tab ist aus der Leiste ausgeblendet (Heute, Schlaf, Gesundheit).
// - Heute-Screen: Aktivitäten erscheinen als auffällige Kacheln mit Belastung,
//   Ø Puls, Max Puls, Dauer und StripeDodge-Schutz.
// - Gesundheit-Tab:
//   - TaktSubTabBar steuert die Abschnitte (Übersicht, Trends, Vitalwerte etc.).
//   - Trends: Ruhepuls, HRV, Schlaf und Konsistenz in Takt-Karten mit Pult.digits,
//     Referenzbereich und StripeDodge-Schutz.
//   - Vitalwerte: TaktDayStepper zum Blättern der Tage, Tagespuls-Bereich
//     (Tiefstwert & Spitzenwert), Atemfrequenz, Hauttemperatur, Tragedauer
//     und HRV-Analyse, alle mit StripeDodge-Schutz.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/state/locale_controller.dart';
import 'package:openstrap_edge/takt/health/body_age_view.dart' show TaktBodyAgeCard;
import 'package:openstrap_edge/takt/health/takt_health_views.dart';
import 'package:openstrap_edge/takt/header.dart';
import 'package:openstrap_edge/takt/journal/journal_tab.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/prebuild.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/takt/today/activity_items.dart';
import 'package:openstrap_edge/takt/today/activity_list.dart';
import 'package:openstrap_edge/ui2/app_shell.dart';
import 'package:openstrap_edge/ui2/screens/health_screen.dart';
import 'package:openstrap_edge/ui2/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _hasDigit(RenderParagraph p) =>
    RegExp(r'\d').hasMatch(p.text.toPlainText(includeSemanticsLabels: false));

void _assertAllDigitsDodged(WidgetTester t) {
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
    expect(
      wrapped,
      isTrue,
      reason:
          'Ungeschützte Zahl: "${p.text.toPlainText(includeSemanticsLabels: false)}"',
    );
  }
}

Widget _wrap(Widget child, {Brightness brightness = Brightness.dark}) =>
    MaterialApp(
      theme: buildTheme(brightness),
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: TaktLook(child: child)),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocaleController.seed('de').useForPresentation();
  });

  tearDown(() {
    TaktStripe.fraction.value = null;
    LocaleController.seed('en').useForPresentation();
  });

  group('Shell: Aktivität-Tab deaktiviert (aber nicht gelöscht)', () {
    testWidgets('AppShell zeigt mit domains nur die 3 aktiven Tabs', (t) async {
      await t.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.dark),
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: AppShell(
          domains: const [
            ShellDomain.today,
            ShellDomain.sleep,
            ShellDomain.health,
          ],
          builder: (_, d) => Text('Inhalt ${d.name}'),
        ),
      ));
      await t.pump();

      expect(find.text('Heute'), findsOneWidget);
      expect(find.text('Schlaf'), findsOneWidget);
      expect(find.text('Gesundheit'), findsOneWidget);
      expect(find.text('Aktivität'), findsNothing);
    });

    // Gerätetest 14.11.: Die Prüfung hing an TaktLook, das in der echten App
    // nur um die einzelnen Tabs liegt. Deshalb hier bewusst OHNE TaktLook.
    testWidgets('prebuild baut Gesundheit nach 3 s im Hintergrund, ohne TaktLook', (t) async {
      final built = <ShellDomain>[];
      Widget shell(Set<ShellDomain> pre) => MaterialApp(
            theme: buildTheme(Brightness.dark),
            locale: const Locale('de'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: AppShell(
              key: ValueKey(pre.length),
              domains: const [ShellDomain.today, ShellDomain.sleep, ShellDomain.health],
              prebuild: pre,
              builder: (_, d) {
                built.add(d);
                return Text('Inhalt ${d.name}');
              },
            ),
          );

      await t.pumpWidget(shell(const {ShellDomain.health}));
      expect(built, isNot(contains(ShellDomain.health)));
      await t.pump(kTaktPrebuildDelay + const Duration(milliseconds: 10));
      expect(built, contains(ShellDomain.health));
      expect(built, isNot(contains(ShellDomain.sleep)));

      built.clear();
      await t.pumpWidget(shell(const {}));
      await t.pump(kTaktPrebuildDelay * 2);
      expect(built, isNot(contains(ShellDomain.health)));
    });
  });

  group('Aktivitäten-Kachel auf dem Homescreen', () {
    testWidgets('TaktActivityCard zeigt Belastung, Ø Puls, Max Puls, Kalorien und schützt alle Zahlen', (t) async {
      t.view.physicalSize = const Size(390, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      TaktStripe.fraction.value = 0.65;

      final startTs = DateTime(2026, 11, 11, 16, 30).millisecondsSinceEpoch ~/ 1000;
      final item = ActivityItem(
        id: 'workout_1',
        startTs: startTs,
        type: 'running',
        detected: true,
        durationMin: 45,
        avgHr: 148,
        maxHr: 172,
        strain: 12.4,
        calories: 420,
      );

      var opened = false;
      var discarded = false;

      await t.pumpWidget(_wrap(
        ActivityList(
          items: [item],
          onOpen: (_) => opened = true,
          onDiscard: (_) => discarded = true,
        ),
      ));
      await t.pump();

      // Auffällige Kachel mit Sportart & Status
      expect(find.text('Laufen'), findsOneWidget);
      expect(find.text('erkannt'), findsOneWidget);
      expect(find.textContaining('45 min'), findsOneWidget);

      // Wichtigste Werte auf einen Blick
      expect(find.text('BELASTUNG'), findsOneWidget);
      expect(find.text('12,4'), findsOneWidget);
      expect(find.text('Ø PULS'), findsOneWidget);
      expect(find.text('148'), findsOneWidget);
      expect(find.text('MAX PULS'), findsOneWidget);
      expect(find.text('172'), findsOneWidget);
      expect(find.text('KALORIEN'), findsOneWidget);
      expect(find.text('420'), findsOneWidget);

      // Interaktionen
      await t.tap(find.text('Laufen'));
      expect(opened, isTrue);

      await t.tap(find.byIcon(LucideIcons.x));
      expect(discarded, isTrue);

      // Streifenschutz
      _assertAllDigitsDodged(t);
    });
  });

  group('Gesundheit-Tab im Takt-Design: Vitalwerte & Trends', () {
    testWidgets('Trends: TaktTrendsView zeigt Ruhepuls, HRV, Schlaf & Konsistenz mit Pult-Ziffern und StripeDodge', (t) async {
      t.view.physicalSize = const Size(390, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      TaktStripe.fraction.value = 0.55;

      final pts = [
        for (var i = 0; i < 30; i++) (t: 1700000000 + i * 86400, v: 52.0 + (i % 3)),
      ];
      final hrvPts = [
        for (var i = 0; i < 30; i++) (t: 1700000000 + i * 86400, v: 65.0 + (i % 5)),
      ];
      final sleepPts = [
        for (var i = 0; i < 30; i++) (t: 1700000000 + i * 86400, v: 460.0 + (i % 20)),
      ];

      final d = HealthData(
        daysWithData: 28,
        charts: {
          'resting_hr': pts,
          'hrv': hrvPts,
          'sleep': sleepPts,
        },
        need: Metric.parse({'value': 480, 'unit': 'min'}),
        baselines: const {
          'resting_hr': {'usual': 53.0, 'lower': 50.0, 'upper': 56.0},
          'hrv': {'usual': 66.0, 'lower': 60.0, 'upper': 72.0},
        },
      );

      await t.pumpWidget(_wrap(HealthScreen(data: d, tab: 0)));
      await t.pump();

      // TaktSubTabBar für Vitalwerte, Erkunden & Labore aktiv (G1/G2)
      expect(find.byType(TaktSubTabBar), findsOneWidget);
      expect(find.text('Mehr zu heute'), findsNothing);
      // Trends & Körperalter direkt auf der Übersichtsseite
      expect(find.byType(TaktTrendsView), findsOneWidget);

      // Kacheln
      expect(find.text('RUHEPULS'), findsOneWidget);
      expect(find.text('HRV'), findsOneWidget);
      expect(find.text('SCHLAFDAUER'), findsOneWidget);
      expect(find.text('TAGES-STRESS'), findsOneWidget);
      expect(find.text('DATEN-KONSISTENZ'), findsOneWidget);

      // Alle Ziffern geschützt
      _assertAllDigitsDodged(t);
    });

    testWidgets('Vitalwerte: TaktVitalsView zeigt Stepper, Pulsbereich, Atmung, Temp, Tragedauer & HRV-Deep-Dive', (t) async {
      t.view.physicalSize = const Size(390, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      TaktStripe.fraction.value = 0.40;

      final v = VitalsData(
        day: '2026-11-11',
        days: const ['2026-11-11', '2026-11-10', '2026-11-09'],
        timeline: const {
          'highs': {
            'low_hr': {'v': 48},
            'peak_hr': {'v': 164},
          },
        },
        lungs: const {
          'resp': {'value': 14.6},
        },
        wear: const {
          'worn_min': 1380,
          'coverage_pct': 96.0,
        },
        hrv: const {
          'rmssd': 64,
        },
      );

      final d = HealthData(
        today: const {
          'skin_temp': {'dev_c': 0.3},
        },
        charts: {
          'hrv': [
            for (var i = 0; i < 20; i++) (t: 1700000000 + i * 86400, v: 62.0),
          ],
        },
      );

      await t.pumpWidget(_wrap(ListView(
        children: [
          TaktVitalsView(
            vitals: v,
            health: d,
            vDay: v.day,
            vDays: v.days,
            vFailed: false,
            onDay: (_) {},
            onRetry: () {},
          ),
        ],
      )));
      await t.pump();

      // Stepper & Vitalwerte-Kacheln
      expect(find.byType(TaktDayStepper), findsOneWidget);
      expect(find.byType(TaktVitalsView), findsOneWidget);

      expect(find.text('TAGESPULS-BEREICH'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
      expect(find.text('164'), findsOneWidget);

      expect(find.text('ATEMFREQUENZ'), findsOneWidget);
      expect(find.text('14,6'), findsOneWidget);

      expect(find.text('HAUTTEMPERATUR'), findsOneWidget);
      expect(find.text('+0,3'), findsOneWidget);

      expect(find.text('SENSOR-TRAGEDAUER'), findsOneWidget);
      expect(find.text('23h 0m'), findsOneWidget);
      expect(find.textContaining('96% des Tages getragen'), findsOneWidget);

      expect(find.text('HRV-ANALYSE (RMSSD)'), findsOneWidget);
      expect(find.text('64'), findsOneWidget);

      expect(find.text('Erweiterte Analysen'), findsOneWidget);

      // Alle Ziffern geschützt
      _assertAllDigitsDodged(t);
    });

    testWidgets('Journal: Tab 5 zeigt JournalTab mit "Heute eintragen" Button (J26, J27)', (t) async {
      t.view.physicalSize = const Size(390, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      final d = HealthData(daysWithData: 10);
      await t.pumpWidget(_wrap(HealthScreen(data: d, tab: 5)));
      for (var i = 0; i < 15; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await t.pump(const Duration(milliseconds: 30));
      }

      // TaktSubTabBar enthält 3 Tabs: Übersicht, Vitalwerte, Journal (J26)
      expect(find.byType(TaktSubTabBar), findsOneWidget);
      expect(find.text('Übersicht'), findsOneWidget);
      expect(find.text('Vitalwerte'), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);

      // Erkunden & Labore sind in Takt entfernt (J26)
      expect(find.text('Erkunden'), findsNothing);
      expect(find.text('Labore'), findsNothing);

      // JournalTab ist aktiv und zeigt "Heute eintragen" (J27)
      expect(find.byType(JournalTab), findsOneWidget);
      expect(find.byKey(const ValueKey('journal-log-today-btn')), findsOneWidget);
      expect(find.text('Heute eintragen'), findsOneWidget);

      _assertAllDigitsDodged(t);
    });
  });

  testWidgets('Gerätetest 14.11.: schneller erster Stand zeigt Übersicht, Körperalter und Stress laden nach', (t) async {
    t.view.physicalSize = const Size(390, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(_wrap(HealthScreen(data: const HealthData(daysWithData: 20, partial: true), tab: 0)));
    await t.pump();
    expect(find.byType(TaktTrendsView), findsOneWidget);
    expect(find.byKey(const ValueKey('takt-body-age-loading')), findsOneWidget);
    expect(find.byKey(const ValueKey('takt-stress-loading')), findsOneWidget);
    expect(find.byType(TaktBodyAgeCard), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(t.takeException(), isNull);
  });
}
