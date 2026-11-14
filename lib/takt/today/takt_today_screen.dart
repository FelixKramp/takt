// Der neue Heute-Tab: Ringe, Live-Puls, Karten, Aktivitäten. In dieser Reihenfolge.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../now.dart';
import '../../data/day_label.dart' show dayLabelBefore, todayLabel;
import '../../data/db.dart' show LocalDb;
import '../../data/journal_fields.dart' show JournalMetricValue;
import '../../l10n/app_localizations.dart';
import '../../l10n/decimal_text.dart' show displayFixed;
import '../../models/activity_suggestion.dart';
import '../../models/metric.dart';
import '../../state/app_state.dart';
import '../../ui2/activity/catalogue.dart';
import '../../ui2/activity/day_strain.dart' show DayStrainDetail;
import '../../ui2/activity/picker.dart' show ActivityPicker;
import '../../ui2/activity/summary.dart' show ActivityResult, ActivitySummary;
import '../../ui2/profile/profile.dart' show ProfileAvatar;
import '../../ui2/screens/home_screen.dart';
import '../../ui2/screens/journal_compose.dart';
import '../../ui2/screens/log_workout.dart' show LogWorkout, bumpInsights;
import '../../ui2/screens/workout_screen.dart' show taktRecentSports, taktWorkoutPicker, taktWorkoutResult;
import '../../ui2/screens/metric_detail.dart';
import '../../ui2/screens/sleep_detail.dart';
import '../../ui2/ui2.dart';
import '../brand.dart';
import '../journal/journal_config.dart';
import '../journal/morning_sheet_flow.dart';
import '../journal/morning_sheet_rule.dart';
import '../look.dart';
import '../pult_tokens.dart';
import '../takt_text.dart';
import '../update_check.dart';
import 'activity_items.dart';
import 'activity_list.dart';
import 'auto_confirm.dart';
import 'day_pulse.dart';
import 'dial_ring.dart';
import '../battery/battery.dart';
import '../battery/battery_detail.dart';
import '../battery/battery_week.dart';
import '../header.dart';
import 'freshness.dart';
import 'minute_tick.dart';
import 'pulse_display.dart';
import 'visibility.dart';
import 'wake_day.dart';
import '../sleep/sleep_head.dart' show durHm;
import '../sleep/sleep_head_loader.dart';
import '../sleep/sleep_score.dart';
import '../sleep/sleep_tab_data.dart' show loadTaktSleep;
import '../stress/day_stress.dart';
import '../stress/takt_stress_view.dart';
import '../stripe/stripe.dart';

const _kSportPick = 'takt.sport.';

class TaktTodayScreen extends StatefulWidget {
  const TaktTodayScreen({super.key});

  @override
  State<TaktTodayScreen> createState() => _TaktTodayScreenState();
}

class _TaktTodayScreenState extends State<TaktTodayScreen>
    with RevisionReload, WidgetsBindingObserver {
  final _syncGate = SyncOnOpenGate();
  HomeData _data = const HomeData();
  Metric _hrv = Metric.empty;
  NightScore? _sleepScore;
  ChartPoint? _hrvLast, _rhrLast;
  List<ActivityItem> _items = const [];
  String? _day;
  String? _activeDay;
  String? _selectedDay;
  List<String> _availableDays = const [];
  DayPulseData _dayPulse = const DayPulseData();
  DayStressAnalysis? _dayStress;
  double? _dayStrainPeak;
  bool _wasBusy = false;
  bool _morningSheetOpen = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    taktTodayVisible.addListener(_onVisible);
    taktTodayReturned.addListener(_toTop);
    unawaited(refreshTaktUpdate());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reload();
      _syncIfDue();
      // Morgenblatt sofort beim Öffnen, nicht erst nach dem Laden (14.11.).
      unawaited(_checkAndShowMorningSheet(null, taktNow()));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    taktTodayVisible.removeListener(_onVisible);
    taktTodayReturned.removeListener(_toTop);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    reload();
    _syncIfDue();
    unawaited(_checkAndShowMorningSheet(null, taktNow()));
    unawaited(refreshTaktUpdate());
  }

  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _onVisible() {
    if (taktTodayVisible.value) _syncIfDue();
  }

  void _syncIfDue() {
    if (!mounted) return;
    final app = context.read<AppState>();
    if (_syncGate.shouldSync(taktNow(), paired: app.isPaired)) {
      unawaited(app.syncNow().catchError((Object _) {}));
    }
  }

  /// Prüft bei jedem Minutentick, ob ein neuer Kalendertag oder Wachtag
  /// begonnen hat.
  void _onTick() {
    if (_day != todayLabel()) reload();
  }

  bool _dayLoading = false;

  void _selectDay(String day) {
    final active = _activeDay ?? todayLabel();
    setState(() {
      _selectedDay = day == active ? null : day;
      _dayLoading = true;
    });
    reload();
  }

  @override
  void reload() => unawaited(_load());

  Future<void> _load() async {
    final repo = repoOf(context);
    if (repo == null) return;
    final token = beginRead(#taktToday);
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    final dataThrough = app.lastRecordAt;
    final busy = app.syncingNow || app.deriving || app.derivePending;
    try {
      final prefs = await SharedPreferences.getInstance();
      String sportOf(ActivitySuggestion s) =>
          prefs.getString('$_kSportPick${s.id}') ??
          activityByName(s.sport)?.typeKey ??
          'other';
      final now = taktNow();
      final left = await autoConfirmWorkouts(
        pending: repo.pendingActivities,
        confirm: (s) => repo.confirmActivity(s, workoutType: sportOf(s)),
        dataThrough: dataThrough,
        derivedAt: _derivedAt,
        busy: busy,
        now: now,
      );
      final loaded = await loadTaktDay(
        repo,
        selectedDay: _selectedDay,
        now: now,
        l: l,
      );
      final isActive = loaded.dayId == loaded.activeDayId;
      unawaited(_loadStress(loaded.dayId));
      // W26: Lade den Schlafscore nur EINMAL für den tatsächlich bestimmten Tag:
      _loadSleepScore(wantDay: loaded.dayId, updateTabBand: isActive);
      _loadLastValues(loaded.activeDayId);

      final dayDt = DateTime.parse(loaded.dayId);
      final workoutRange = now.difference(dayDt).inDays >= 7 ? 'month' : 'week';
      final week = await repo.getWorkouts(range: workoutRange);
      final raw = week['workouts'];
      var workouts = [
        for (final w in (raw is List ? raw : const []))
          if (w is Map) w.cast<String, dynamic>(),
      ];
      // W21: Für Tage > 30 Tage liefert getWorkouts('month') keine Einträge mehr;
      // lade Sessions aus der Tages-Timeline als Fallback:
      if (workouts.isEmpty && now.difference(dayDt).inDays > 30) {
        try {
          final tl = await repo.getDayTimeline(loaded.dayId);
          final sessions = tl['sessions'] as List?;
          if (sessions != null && sessions.isNotEmpty) {
            workouts = [
              for (final s in sessions)
                if (s is Map) s.cast<String, dynamic>(),
            ];
          }
        } catch (_) {}
      }
      final dayPulse = isActive
          ? const DayPulseData()
          : await DayPulseData.load(repo, loaded.dayId, window: loaded.window);
      if (!stillNewest(#taktToday, token)) return;
      setState(() {
        _dayLoading = false;
        _day = todayLabel(now);
        _activeDay = loaded.activeDayId;
        if (_selectedDay == loaded.activeDayId) _selectedDay = null;
        _availableDays = loaded.availableDays;
        _data = loaded.data;
        _hrv = loaded.hrv;
        _dayStrainPeak = loaded.strainPeak;
        _dayPulse = dayPulse;
        _items = todayActivities(
          workouts,
          dayDt,
          pending: isActive ? left : const [],
          sportOf: sportOf,
          fromSec: loaded.window.fromSec,
          toSec: loaded.window.toSec,
        );
      });
      unawaited(_checkAndShowMorningSheet(loaded, now));
    } catch (_) {
      if (mounted) setState(() => _dayLoading = false);
    }
  }

  /// Prüft, ob das Morgenblatt automatisch eingeblendet werden soll (J1, J7, J21, J22, J25).
  Future<void> _checkAndShowMorningSheet(
    TaktDayLoaded? loaded,
    DateTime now,
  ) async {
    if (_morningSheetOpen || !mounted || _selectedDay != null) return;
    // Sofort belegen: Start, Wiederöffnen und fertiges Laden prüfen
    // gleichzeitig, das Blatt darf trotzdem nur einmal kommen.
    _morningSheetOpen = true;
    try {
      final calToday = todayLabel(now);
      final calYesterday = dayLabelBefore(calToday, 1);
      if (calYesterday == null) return;

      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getString(kJournalSheetLastKey);

      final config = await JournalConfig.load();
      final sheetQuestionsYesterday = config.sheetQuestionsYesterday;
      final sheetQuestionsToday = config.sheetQuestionsToday;

      final metricsByDay = await LocalDb.journalMetricsByDay(
        sinceDaysEpoch: calYesterday,
      );
      final existingYesterday = {
        for (final e in (metricsByDay[calYesterday] ?? const <String, JournalMetricValue>{}).entries)
          e.key: e.value.value,
      };
      final existingToday = {
        for (final e in (metricsByDay[calToday] ?? const <String, JournalMetricValue>{}).entries)
          e.key: e.value.value,
      };

      final decision = checkMorningSheetRule(
        now: now,
        activeDayId: loaded?.activeDayId,
        calToday: calToday,
        todayHasSleep: loaded?.todayHasSleep ?? false,
        nightInProgress: loaded?.nightInProgress ?? false,
        lastDismissedOrCompletedDay: lastShown,
        sheetQuestionsYesterday: sheetQuestionsYesterday,
        sheetQuestionsToday: sheetQuestionsToday,
        existingYesterdayAnswers: existingYesterday,
        existingTodayAnswers: existingToday,
      );

      if (!decision.shouldShow || !mounted) return;

      await presentMorningSheet(
        context,
        config: config,
        calYesterday: calYesterday,
        calToday: calToday,
        initialYesterday: decision.yesterdayAnswers,
        initialToday: decision.todayAnswers,
        onOpenFullJournal: () {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => JournalCompose(date: calToday),
              ),
            );
          }
        },
      );
    } catch (_) {
      // Leise ignorieren, damit Today-Screen nicht gestört wird
    } finally {
      _morningSheetOpen = false;
    }
  }

  /// Wann der Tag, an dem das Training endete, zuletzt vollständig gerechnet
  /// wurde. Teilergebnisse zählen nicht.
  Future<DateTime?> _derivedAt(ActivitySuggestion s) async {
    final end = DateTime.fromMillisecondsSinceEpoch(s.endTs * 1000);
    final row = await LocalDb.dayResult(DateFormat('yyyy-MM-dd').format(end));
    final at = row?['computed_at'];
    if (at is! num || row?['partial'] == 1 || row?['skipped'] == 1) return null;
    return DateTime.fromMillisecondsSinceEpoch(at.toInt());
  }

  /// Feature 08, T1: Übersicht des Trainings, sonst die Sportart-Wahl (T2).
  Future<void> _openWorkout(ActivityItem item) async {
    // Ein zweiter Tipp während des Ladens öffnet nichts doppelt (Prüfung 08).
    if (_opening) return;
    _opening = true;
    try {
      await _openWorkoutOnce(item);
    } finally {
      _opening = false;
    }
  }

  bool _opening = false;

  Future<void> _openWorkoutOnce(ActivityItem item) async {
    final app = context.read<AppState>();
    double? weight;
    try {
      weight = ((await app.repo?.getProfile())?['weight_kg'] as num?)?.toDouble();
    } catch (_) {
      // Ohne Gewicht fehlt nur der Kaloriensatz.
    }
    final target = await taktWorkoutTarget(item, (id) => taktWorkoutResult(app, id), weightKg: weight);
    if (!mounted) return;
    if (target == null) return _pickSport(item, weightKg: weight);
    await _push(target);
  }

  Future<void> _pickSport(ActivityItem item, {double? weightKg}) async {
    final s = item.suggestion;
    var picking = false;
    final recent = await taktRecentSports(context.read<AppState>());
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      // Feature 09, W3: Die Sportart-Wahl im Takt-Design.
      builder: (_) => TaktLook(child: ActivityPicker(recent: recent, weightKg: weightKg, onPick: (pc, activity) async {
        if (picking) return;
        picking = true;
        try {
          if (s != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('$_kSportPick${s.id}', activity.typeKey);
          }
          // Auch bei offener Erkennung: Sie kann während der Wahl gespeichert
          // worden sein. Gibt es die Zeile nicht, ändert das nichts.
          await LocalDb.setSessionType(item.id, activity.typeKey);
        } catch (_) {
          picking = false;
          return;
        }
        if (!pc.mounted) return;
        bumpInsights(pc);
        Navigator.of(pc).pop();
      })),
    ));
    if (mounted) await _load();
  }

  Future<void> _discard(ActivityItem item) async {
    final repo = repoOf(context);
    if (repo == null) return;
    final s = item.suggestion;
    try {
      if (s != null) {
        await repo.discardActivity(s);
      } else {
        // Über AppState, damit ein noch laufendes Workout mit beendet wird.
        await context.read<AppState>().deleteWorkout(item.id);
      }
    } catch (_) {
      // Zum Beispiel eine veraltete Erkennung: Die Liste zeigt danach den
      // aktuellen Stand, und man kann es erneut versuchen.
    }
    if (!mounted) return;
    bumpInsights(context);
    await _load();
  }

  /// Feature 03: Score der gezeigten Nacht für den Schlafring, getrennt vom
  /// Laden des Heute-Screens, damit Ringe, Puls und Aktivitäten nicht auf
  /// die Schlafabfragen warten. Schreibt nebenbei die Tagesnotiz, auch wenn
  /// der Schlaf-Tab nie geöffnet wird.
  Future<void> _loadSleepScore({String? wantDay, bool updateTabBand = true}) async {
    final repo = repoOf(context);
    if (repo == null) return;
    final token = beginRead(#taktSleepScore);
    try {
      final score = (await loadTaktSleep(repo, want: wantDay)).score;
      if (updateTabBand) TaktSleepBand.current.value = score.band;
      if (stillNewest(#taktSleepScore, token)) setState(() => _sleepScore = score);
    } catch (_) {
      // Ohne Score bleibt der Schlafring wie in A2.
    }
  }

  Future<void> _loadStress(String dayLabel) async {
    final repo = repoOf(context);
    if (repo == null) return;
    final token = beginRead(#taktTodayStress);
    try {
      final analysis = await DayStressCalculator.loadForDay(repo, dayLabel);
      if (stillNewest(#taktTodayStress, token)) {
        setState(() => _dayStress = analysis);
      }
    } catch (_) {
      // Wenn keine Stressdaten geladen werden können
    }
  }

  /// Letzte gespeicherte HRV und letzter Ruhepuls aus dem Verlauf, dieselbe
  /// Quelle wie die Detailansicht. Eigenständig und nicht abgewartet wie der
  /// Schlafscore, damit `_load` nicht länger braucht (G2).
  List<ChartPoint> _weekRecovery = const [], _weekStrain = const [];

  /// Höchster Strain je Tag der Woche, aus den Tageskurven (B2′).
  Map<DateTime, double> _peaks = const {};

  static DateTime _today0() {
    final n = taktNow();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _loadLastValues(String activeDay) async {
    final repo = repoOf(context);
    if (repo == null) return;
    final token = beginRead(#taktLastValues);
    try {
      ChartPoint? last(Map<String, dynamic> chart) {
        final pts = pointsOf(chart);
        return pts.isEmpty ? null : pts.reduce((a, b) => b.t > a.t ? b : a);
      }

      final hrv = last(await repo.getChart('hrv'));
      final rhr = last(await repo.getChart('resting_hr'));
      if (stillNewest(#taktLastValues, token)) {
        setState(() {
          _hrvLast = hrv;
          _rhrLast = rhr;
        });
      }
    } catch (_) {
      // Ohne Verlauf bleiben die Karten beim heutigen Wert oder beim Strich.
    }
    // Feature 04, D6: die Woche der Batterie. Eigener Versuch, damit ein
    // Fehler hier HRV und Ruhepuls nicht mitnimmt (Prüfung 04, H5).
    try {
      final recovery = pointsOf(await repo.getChart('recovery'));
      final strain = pointsOf(await repo.getChart('strain'));
      // W14: Die Säulen rechnen nach Wachtagen, wie der Tages-Schalter. Nach
      // Kalendertagen standen dort für denselben Tag andere Werte (12,0 gegen
      // 12,34), und die Belastung nach Mitternacht zählte zweimal.
      final t0 = _today0();
      final dayIds = [
        for (var i = 0; i < 7; i++)
          DateFormat('yyyy-MM-dd').format(DateTime(t0.year, t0.month, t0.day - i)),
      ];
      final byDay = await wakeDayStrainPeaks(repo, dayIds, activeDay: activeDay);
      final peaks = <DateTime, double>{
        for (final e in byDay.entries) DateTime.parse(e.key): e.value,
      };
      if (stillNewest(#taktLastValues, token)) {
        setState(() {
          _weekRecovery = recovery;
          _weekStrain = strain;
          _peaks = peaks;
        });
      }
    } catch (_) {
      // Ohne Verlauf keine Wochenkarte.
    }
  }

  /// Live-Training starten: Sportartenwahl, danach Einrichtung und Live-Bild
  /// (bei Laufen mit GPS) wie im Aktivität-Tab.
  Future<void> _startWorkout() async {
    final app = context.read<AppState>();
    final picker = await taktWorkoutPicker(app);
    if (mounted) await _push(picker);
  }

  /// Alles, was Heute öffnet, steht in der Takt-Haut (Feature 06/07).
  Future<void> _push(Widget w) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => TaktLook(child: w)));
    if (mounted) await _load();
  }

  Future<void> _refresh() async {
    final app = context.read<AppState>();
    if (app.isPaired) {
      try {
        await app.syncNow().timeout(const Duration(seconds: 90));
      } catch (_) {
        // Auch ein gescheiterter Sync liest neu, was angekommen ist.
      }
    }
    await _load();
  }

  @override
  Widget build(BuildContext c) {
    final syncing = c.select<AppState, bool>((a) => a.syncingNow);
    final busy = c.select<AppState, bool>(
        (a) => a.syncingNow || a.deriving || a.derivePending);
    // Am Ende einer Berechnung neu lesen: Erst jetzt darf ein abgeschlossenes
    // Training gespeichert werden, und niemand sonst stößt das an.
    if (_wasBusy && !busy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) reload();
      });
    }
    _wasBusy = busy;
    final activeDay = _activeDay ?? todayLabel();
    final shownDay = _selectedDay ?? activeDay;
    final isToday = shownDay == activeDay;
    final activeDt = DateTime.parse(activeDay);
    final peaks = {
      ..._peaks,
      if (isToday && _dayStrainPeak != null)
        DateTime(activeDt.year, activeDt.month, activeDt.day): _dayStrainPeak!,
    };
    return RefreshIndicator(
      onRefresh: _refresh,
      child: TaktTodayView(
        scroll: _scroll,
        data: _data,
        hrv: _hrv,
        sleepScore: _sleepScore,
        hrvLast: isToday ? _hrvLast : null,
        rhrLast: isToday ? _rhrLast : null,
        strainPeak: _dayStrainPeak ?? _peaks[DateTime.parse(shownDay)],
        dayStepper: _availableDays.length > 1
            ? TaktDayStepper(
                key: const ValueKey('takt-today-stepper'),
                day: shownDay,
                days: _availableDays,
                labelOf: (d, de) =>
                    d == activeDay ? (de ? 'Heute' : 'Today') : dayShortLabel(d, de),
                onDay: _selectDay,
              )
            : null,
        week: _weekRecovery.isEmpty && _weekStrain.isEmpty
            ? null
            : batteryWeek(
                recovery: _weekRecovery,
                strain: _weekStrain,
                today: activeDt,
                // Wie der Ring: in der Nacht noch keine Ladung (B1).
                todayMorning: !isToday || _data.recoveryState == 'night_in_progress'
                    ? null
                    : _data.readiness.value?.toDouble(),
                todayStrain: isToday ? _data.strain.value?.toDouble() : null,
                peaks: peaks,
              ),
        items: _items,
        lastData: lastDataAtOf(c),
        syncing: syncing || derivingOf(c),
        pulse: isToday
            ? PulseDisplay(
                onTap: () => _push(TaktPulseDetail(
                  initialDay: shownDay,
                  activeDay: activeDay,
                  days: _availableDays,
                )),
              )
            : TaktDayPulseCard(data: _dayPulse),
        dayStress: _dayStress,
        header: const ProfileAvatar(accent: C.domHome),
        watch: isToday ? bodyWatchOf(c, _data, activeDay) : null,
        loading: _dayLoading,
        isToday: isToday,
        onRing: (k) => _push(taktRingTarget(k, day: shownDay)),
        onCard: (key) => _push(MetricDetail(key)),
        onOpen: _openWorkout,
        onTick: _onTick,
        onDiscard: _discard,
        onLog: () => _push(const LogWorkout()),
        // Läuft schon ein Training, bringt die Leiste unten dorthin zurück.
        onStart: c.select<AppState, bool>((a) => a.activeWorkout != null)
            ? null
            : _startWorkout,
      ),
    );
  }
}

/// Wohin ein Ring führt. Der Schlafring öffnet den Schlaf-Screen mit dem
/// Takt-Kopf, wie im Schlaf-Tab (Gerätetest 0.2.0, E1).
Widget taktRingTarget(HomeRingKind k, {String? day}) => switch (k) {
      // Feature 04, D4: Der erste Ring ist die Batterie.
      HomeRingKind.recovery => BatteryDetail(day: day),
      HomeRingKind.strain => DayStrainDetail(day: day),
      HomeRingKind.sleep =>
        SleepDetail(day: day, head: (d) => TaktSleepHeadLoader(day: d)),
    };

/// Reine Darstellung, dadurch ohne Band und ohne Datenbank testbar.
class TaktTodayView extends StatelessWidget {
  const TaktTodayView({
    super.key,
    required this.data,
    required this.pulse,
    this.hrv = Metric.empty,
    this.items = const [],
    this.lastData,
    this.syncing = false,
    this.header,
    this.watch,
    this.loading = false,
    this.isToday = true,
    this.onRing,
    this.onCard,
    this.onOpen,
    this.onDiscard,
    this.onLog,
    this.onStart,
    this.onTick,
    this.now,
    this.scroll,
    this.sleepScore,
    this.hrvLast,
    this.rhrLast,
    this.week,
    this.strainPeak,
    this.dayStepper,
    this.dayStress,
  });

  /// Feature 04, B2′: der höchste Strain heute, für den Batterie-Ring.
  final double? strainPeak;

  /// Optionaler Tages-Schalter in der Kopfzeile zwischen `takt` und Profil-Icon.
  final Widget? dayStepper;

  /// Optionaler Stressverlauf des gezeigten Tages.
  final DayStressAnalysis? dayStress;

  final HomeData data;
  final bool loading;
  final bool isToday;

  /// Feature 04, D6: die letzten sieben Tage der Batterie. Null oder ohne
  /// einen Tag mit Ladung: keine Wochenkarte.
  final List<BatteryDay>? week;

  /// Letzter gespeicherter Wert aus dem Verlauf (wie in der Detailansicht).
  /// Gilt nur, wenn die heutige Nacht noch keinen Wert hat, und trägt dann
  /// seinen Tag im Label (Gerätetest 0.2.0, G2).
  final ChartPoint? hrvLast, rhrLast;

  /// Feature 03, C11: Schlafscore der letzten Nacht. Mit Score zeigt der
  /// Schlafring ihn in der Farbe der Stufe, ohne bleibt er wie in A2.
  final NightScore? sleepScore;
  final Metric hrv;
  final Widget pulse;
  final List<ActivityItem> items;
  final DateTime? lastData;
  final bool syncing;
  final Widget? header;
  final List<Widget>? watch;
  final void Function(HomeRingKind)? onRing;
  final void Function(String)? onCard;
  final void Function(ActivityItem)? onOpen;
  final void Function(ActivityItem)? onDiscard;
  final VoidCallback? onLog;
  final VoidCallback? onStart;
  final VoidCallback? onTick;
  final DateTime? now;
  final ScrollController? scroll;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    final l = AppLocalizations.of(c);
    final effectiveData = loading ? const HomeData() : data;
    final score = loading ? null : sleepScore?.score;
    final slept = effectiveData.sleepMin.value;
    final rings = [
      for (final k in HomeRingKind.values)
        if (k == HomeRingKind.recovery)
          batteryRing(effectiveData, l, t, strainPeak: loading ? null : strainPeak)
        else if (k == HomeRingKind.strain && effectiveData.strain.value != null)
          RingView(
            kind: k,
            label: ringViewOf(k, effectiveData, l).label,
            value: displayFixed(effectiveData.strain.value!, 1),
            frac: (effectiveData.strain.value! / 21).clamp(0, 1).toDouble(),
          )
        else if (k == HomeRingKind.sleep && score != null)
          RingView(
            kind: k,
            label: ringViewOf(k, effectiveData, l).label,
            value: '$score',
            sub: slept == null ? '' : t.hoursShort(durHm(slept)),
            frac: score / 100,
          )
        else
          ringViewOf(k, effectiveData, l),
    ];
    final colors = {
      HomeRingKind.recovery: Pult.orange,
      HomeRingKind.strain: p.ink,
      // Ohne Score neutral. Blau ist die Farbe für „gut“ und sprang beim
      // Laden auf Orange oder Rot um (Gerätetest 0.5.1).
      HomeRingKind.sleep: score != null ? sleepScore!.band!.fill : p.ink2,
    };
    final gaps = [
      for (final r in rings)
        if (r.why != null && r.why!.isNotEmpty) r.why!,
    ];
    return ListView(controller: scroll, padding: pad, children: [
      const SizedBox(height: S.x3),
      if (dayStepper == null)
        Row(children: [
          Text(kAppName.toLowerCase(), style: F.t2.copyWith(color: p.ink)),
          const SizedBox(width: S.x3),
          Expanded(
            child: MinuteTick(
              onTick: onTick,
              builder: (_) => StripeDodge(
                line: true,
                child: Text(
                    syncing ? t.syncing : freshnessText(lastData, now ?? taktNow(), t),
                    key: const ValueKey('takt-status'),
                    textAlign: TextAlign.end,
                    style: F.cap.copyWith(color: p.ink2)),
              ),
            ),
          ),
          if (header != null) ...[const SizedBox(width: S.x3), header!],
        ])
      else
        Row(children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 86),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kAppName.toLowerCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: F.t2.copyWith(color: p.ink),
                ),
                MinuteTick(
                  onTick: onTick,
                  builder: (_) {
                    final status =
                        syncing ? t.syncing : freshnessText(lastData, now ?? taktNow(), t);
                    final child = StripeDodge(
                      line: true,
                      child: Text(
                        status,
                        key: const ValueKey('takt-status'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: F.cap.copyWith(color: p.ink2),
                      ),
                    );
                    return status.isEmpty
                        ? Visibility(visible: false, maintainState: true, child: child)
                        : child;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: S.x2),
          Expanded(child: dayStepper!),
          if (header != null) ...[const SizedBox(width: S.x2), header!],
        ]),
      const SizedBox(height: S.x3),
      Row(
        key: const ValueKey('takt-rings'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in rings)
            Expanded(
              child: DialRing(r,
                  color: colors[r.kind]!,
                  onTap: onRing == null ? null : () => onRing!(r.kind)),
            ),
        ],
      ),
      for (final g in gaps.take(1)) ...[
        const SizedBox(height: S.x2),
        StripeDodge(line: true, child: Text(g, style: F.cap.copyWith(color: p.ink2))),
      ],
      const SizedBox(height: S.x3),
      KeyedSubtree(key: const ValueKey('takt-pulse'), child: pulse),
      const SizedBox(height: S.x3),
      Row(key: const ValueKey('takt-cards'), children: [
        Expanded(
            child: _lastCard(t, t.hrv, loading ? Metric.empty : hrv,
                loading ? null : hrvLast, 'ms', () => onCard?.call('hrv'))),
        const SizedBox(width: S.x2),
        Expanded(
            child: _lastCard(
                t,
                t.restingHr,
                effectiveData.rhr,
                loading ? null : rhrLast,
                '',
                () => onCard?.call('resting_hr'))),
        const SizedBox(width: S.x2),
        Expanded(
            child: _Card(t.steps, _num(effectiveData.steps, ''),
                () => onCard?.call('steps'))),
      ]),
      if (dayStress != null && dayStress!.hasData) ...[
        const SizedBox(height: S.x3),
        TaktStressCard(analysis: dayStress!),
      ],
      if (watch != null) ...[const SizedBox(height: S.x3), ...watch!],
      const SizedBox(height: S.x5),
      KeyedSubtree(
        key: const ValueKey('takt-activities'),
        child: ActivityList(
          items: items,
          isPastDay: !isToday,
          onOpen: onOpen,
          onDiscard: onDiscard,
          onLog: onLog,
          onStart: onStart,
        ),
      ),
      // Feature 04, D6: unter den Karten, nach den Aktivitäten, damit die
      // ohne Scrollen sichtbar bleiben.
      if (week != null && week!.any((d) => d.morning != null)) ...[
        const SizedBox(height: S.x5),
        TaktBatteryWeek(days: week!, today: now ?? taktNow()),
      ],
    ]);
  }

  /// Karte mit dem heutigen Wert, sonst dem letzten aus dem Verlauf samt Tag.
  Widget _lastCard(TaktText t, String label, Metric today, ChartPoint? last, String unit,
      VoidCallback onTap) {
    if (today.value != null || last == null) return _Card(label, _num(today, unit), onTap);
    final at = DateTime.fromMillisecondsSinceEpoch(last.t * 1000);
    final n = now ?? taktNow();
    final isToday = at.year == n.year && at.month == n.month && at.day == n.day;
    final v = displayFixed(last.v, 0);
    return _Card(isToday ? label : '$label, ${t.dayOf(at, n)}',
        unit.isEmpty ? v : '$v $unit', onTap);
  }

  static String _num(Metric m, String unit) {
    final v = m.value;
    if (v == null) return '–';
    final n = displayFixed(v, 0);
    return unit.isEmpty ? n : '$n $unit';
  }
}

class _Card extends StatelessWidget {
  const _Card(this.label, this.value, this.onTap);
  final String label, value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x4),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: R.rSm,
          border: Border(
            top: BorderSide(color: p.line),
            left: BorderSide(color: p.line),
            right: BorderSide(color: p.line),
            bottom: BorderSide(color: p.line, width: 3),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StripeDodge(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: Pult.digits(32, p.ink)),
            ),
          ),
          const SizedBox(height: S.x1),
          Text(label, style: F.cap.copyWith(color: p.ink2)),
        ]),
      ),
    );
  }
}

/// Feature 08, T1 und T2: Was das Antippen eines Trainings öffnet. Ein
/// gespeichertes Training öffnet seine Übersicht. Eine nicht gespeicherte
/// Erkennung oder ein Training, das sich nicht laden lässt, ergibt null, dann
/// bleibt es bei der Sportart-Wahl.
Future<Widget?> taktWorkoutTarget(
  ActivityItem item,
  Future<ActivityResult?> Function(String id) load, {
  double? weightKg,
}) async {
  if (item.suggestion != null) return null;
  try {
    final r = await load(item.id);
    return r == null ? null : ActivitySummary(r, weightKg: weightKg);
  } catch (_) {
    return null;
  }
}
