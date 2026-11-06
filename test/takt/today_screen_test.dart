// Der echte Heute-Tab mit echter Datenbank, ohne Band.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:openstrap_edge/data/activity_store.dart';
import 'package:openstrap_edge/data/day_label.dart' show todayLabel;
import 'package:openstrap_edge/data/db.dart';
import 'package:openstrap_edge/data/local_repository_impl.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/activity_suggestion.dart';
import 'package:openstrap_edge/state/app_state.dart';
import 'package:openstrap_edge/sync/paired_device.dart' show PairedDevice;
import 'package:openstrap_edge/takt/today/takt_today_screen.dart';
import 'package:openstrap_edge/takt/today/visibility.dart';
import 'package:openstrap_edge/theme/theme_controller.dart';
import 'package:openstrap_edge/ui2/activity/picker.dart' show ActivityPicker;
import 'package:openstrap_edge/ui2/ui2.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class App extends AppState {
  App(this.through) : super.forTesting();
  final DateTime? through;
  int syncs = 0;
  int retained = 0;
  bool computing = false;
  @override
  bool get deriving => computing;
  void finish() {
    computing = false;
    notifyListeners();
  }
  @override
  DateTime? get lastRecordAt => through;
  @override
  Future<void> syncNow() async => syncs++;
  @override
  void retainLiveHrView() => retained++;
  @override
  void releaseLiveHrView() => retained--;
}

Widget wrap(AppState app, Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: app),
        ChangeNotifierProvider<ThemeController>(
            create: (_) => ThemeController.seed(AppThemeChoice.light, Brightness.light)),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: child,
      ),
    );

Future<void> settle(WidgetTester t, [int n = 80]) async {
  for (var i = 0; i < n; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 100));
  }
}

int derivedAt(int sec) => sec * 1000;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late int start;
  late LocalRepositoryImpl repo;

  Future<void> seed(WidgetTester t) async {
    SharedPreferences.setMockInitialValues({});
    taktTodayVisible.value = true;
    t.view.physicalSize = const Size(390, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final now = DateTime.now();
    start = DateTime(now.year, now.month, now.day, 0, 5).millisecondsSinceEpoch ~/ 1000;
    await t.runAsync(() async {
      await LocalDb.close();
      LocalDb.dbName = 'takt_screen.db';
      await databaseFactory.deleteDatabase(
          p.join(await databaseFactory.getDatabasesPath(), LocalDb.dbName));
      final db = await LocalDb.instance;
      await db.update('activity_review_meta', {'activated_at': start - 1});
      repo = LocalRepositoryImpl(getProfileMap: () => {});
      await db.insert('day_result', {
        'day_id': todayLabel(),
        'algo_version': 1,
        'payload_json': '{}',
        'computed_at': derivedAt(start + 86400),
      });
      await ActivityStore(db).reconcile(ActivityKind.workout, [
        {'id': 'd:$start', 'start_ts': start, 'end_ts': start + 1800, 'avg_bpm': 150, 'duration_min': 30, 'sport': null},
      ]);
    });
  }

  Future<App> open(WidgetTester t, DateTime? through) async {
    final app = App(through)..repo = repo;
    app.paired = PairedDevice('AA:BB:CC:DD:EE:FF', 'SER1');
    addTearDown(app.dispose);
    await t.pumpWidget(wrap(app, const Scaffold(body: TaktTodayScreen())));
    await settle(t);
    return app;
  }

  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(() => LocalDb.close());
  }

  DateTime at(int sec) => DateTime.fromMillisecondsSinceEpoch(sec * 1000);

  testWidgets('A2 und A12: Screen lädt ohne Fehler, Sync startet, Puls-Strom läuft', (t) async {
    await seed(t);
    final app = await open(t, at(start + 600));
    expect(t.takeException(), isNull);
    expect(app.syncs, 1);
    expect(app.retained, 1);
    taktTodayVisible.value = false;
    await t.pump();
    expect(app.retained, 0, reason: 'A7: Tabwechsel schließt den Strom');
    taktTodayVisible.value = true;
    await close(t);
  });

  testWidgets('A8: Laufendes Training steht offen in der Liste und bleibt ungespeichert', (t) async {
    await seed(t);
    await open(t, at(start + 1800 + 60));
    expect(find.textContaining('erkannt,'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    await t.runAsync(() async => expect((await repo.pendingActivities()).length, 1));
    await close(t);
  });

  testWidgets('A8: Abgeschlossenes Training wird gespeichert', (t) async {
    await seed(t);
    await open(t, at(start + 1800 + 1900));
    await t.runAsync(() async {
      expect(await repo.pendingActivities(), isEmpty);
      final w = await repo.getWorkouts(range: 'week');
      expect((w['workouts'] as List).single['id'], startsWith('suggestion:'));
    });
    expect(find.textContaining('erkannt,'), findsOneWidget);
    await close(t);
  });

  testWidgets('A8: Am Ende der Berechnung wird ohne Zutun gespeichert', (t) async {
    await seed(t);
    final app = App(at(start + 1800 + 1900))..computing = true;
    app.repo = repo;
    app.paired = PairedDevice('AA:BB:CC:DD:EE:FF', 'SER1');
    addTearDown(app.dispose);
    await t.pumpWidget(wrap(app, const Scaffold(body: TaktTodayScreen())));
    await settle(t);
    await t.runAsync(() async => expect((await repo.pendingActivities()).length, 1));
    app.finish();
    await settle(t);
    await t.runAsync(() async => expect(await repo.pendingActivities(), isEmpty));
    await close(t);
  });

  testWidgets('A9: Antippen wählt die Sportart, auch Handball', (t) async {
    await seed(t);
    await open(t, at(start + 1800 + 1900));
    await t.tap(find.textContaining('erkannt,'));
    await settle(t, 10);
    expect(find.byType(ActivityPicker), findsOneWidget);
    await t.enterText(find.byType(TextField), 'Handball');
    await settle(t, 5);
    await t.tap(find.text('Handball').last);
    await settle(t);
    expect(find.text('Handball'), findsOneWidget);
    await close(t);
  });

  testWidgets('A9: Auch eine offene Erkennung bekommt ihre Sportart', (t) async {
    await seed(t);
    await open(t, at(start + 1800 + 60));
    await t.tap(find.textContaining('erkannt,'));
    await settle(t, 10);
    await t.enterText(find.byType(TextField), 'Handball');
    await settle(t, 5);
    await t.tap(find.text('Handball').last);
    await settle(t);
    expect(find.text('Handball'), findsOneWidget);
    await t.runAsync(() async => expect((await repo.pendingActivities()).length, 1));
    await close(t);
  });

  testWidgets('A9: Verwerfen entfernt es und es kommt nicht wieder', (t) async {
    await seed(t);
    await open(t, at(start + 1800 + 1900));
    await t.tap(find.byIcon(LucideIcons.x));
    await settle(t);
    expect(find.textContaining('erkannt,'), findsNothing);
    await t.runAsync(() async {
      expect(await repo.pendingActivities(), isEmpty);
      final w = await repo.getWorkouts(range: 'week');
      expect(w['workouts'] as List, isEmpty);
    });
    await close(t);
  });
}
