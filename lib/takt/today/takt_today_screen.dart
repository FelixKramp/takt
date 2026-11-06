// Der neue Heute-Tab: Ringe, Live-Puls, Karten, Aktivitäten. In dieser Reihenfolge.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/day_label.dart' show todayLabel;
import '../../data/db.dart' show LocalDb;
import '../../l10n/app_localizations.dart';
import '../../l10n/decimal_text.dart' show displayFixed;
import '../../models/activity_suggestion.dart';
import '../../models/metric.dart';
import '../../state/app_state.dart';
import '../../ui2/activity/catalogue.dart';
import '../../ui2/activity/day_strain.dart' show DayStrainDetail;
import '../../ui2/activity/picker.dart' show ActivityPicker;
import '../../ui2/profile/profile.dart' show ProfileAvatar;
import '../../ui2/screens/home_screen.dart';
import '../../ui2/screens/log_workout.dart' show LogWorkout, bumpInsights;
import '../../ui2/screens/metric_detail.dart';
import '../../ui2/screens/readiness_detail.dart';
import '../../ui2/screens/sleep_detail.dart';
import '../../ui2/ui2.dart';
import '../brand.dart';
import '../pult_tokens.dart';
import '../takt_text.dart';
import '../update_check.dart';
import 'activity_items.dart';
import 'activity_list.dart';
import 'auto_confirm.dart';
import 'dial_ring.dart';
import 'freshness.dart';
import 'minute_tick.dart';
import 'pulse_display.dart';
import 'visibility.dart';

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
  List<ActivityItem> _items = const [];
  String? _day;
  bool _wasBusy = false;
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
    if (_syncGate.shouldSync(DateTime.now(), paired: app.isPaired)) {
      unawaited(app.syncNow().catchError((Object _) {}));
    }
  }

  /// Nach Mitternacht darf nicht der gestrige Tag stehen bleiben.
  void _onTick() {
    if (_day != todayLabel()) reload();
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
      final now = DateTime.now();
      final left = await autoConfirmWorkouts(
        pending: repo.pendingActivities,
        confirm: (s) => repo.confirmActivity(s, workoutType: sportOf(s)),
        dataThrough: dataThrough,
        derivedAt: _derivedAt,
        busy: busy,
        now: now,
      );
      final data = await HomeData.load(repo, l);
      final today = await repo.getToday();
      final week = await repo.getWorkouts(range: 'week');
      final raw = week['workouts'];
      final workouts = [
        for (final w in (raw is List ? raw : const []))
          if (w is Map) w.cast<String, dynamic>(),
      ];
      final hrv = today['hrv'];
      final rmssd = hrv is Map ? hrv['rmssd'] as num? : null;
      if (!stillNewest(#taktToday, token)) return;
      setState(() {
        _day = todayLabel();
        _data = data;
        _hrv = rmssd == null || hrv is! Map
            ? Metric.empty
            : overnightMetric(
                today, {...hrv.cast<String, dynamic>(), 'value': rmssd, 'unit': 'ms'}, l);
        _items = todayActivities(workouts, now, pending: left, sportOf: sportOf);
      });
    } catch (_) {
      // Eine fehlgeschlagene Lesung lässt den letzten Stand stehen, die nächste
      // Revision versucht es wieder.
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

  Future<void> _pickSport(ActivityItem item) async {
    final s = item.suggestion;
    var picking = false;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ActivityPicker(onPick: (pc, activity) async {
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
      }),
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

  Future<void> _push(Widget w) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
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
    return RefreshIndicator(
      onRefresh: _refresh,
      child: TaktTodayView(
        scroll: _scroll,
        data: _data,
        hrv: _hrv,
        items: _items,
        lastData: lastDataAtOf(c),
        syncing: syncing || derivingOf(c),
        pulse: const PulseDisplay(),
        header: const ProfileAvatar(accent: C.domHome),
        watch: bodyWatchOf(c, _data, todayLabel()),
        onRing: (k) => _push(switch (k) {
          HomeRingKind.recovery => const ReadinessDetail(),
          HomeRingKind.strain => const DayStrainDetail(),
          HomeRingKind.sleep => const SleepDetail(),
        }),
        onCard: (key) => _push(MetricDetail(key)),
        onOpen: _pickSport,
        onTick: _onTick,
        onDiscard: _discard,
        onLog: () => _push(const LogWorkout()),
      ),
    );
  }
}

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
    this.onRing,
    this.onCard,
    this.onOpen,
    this.onDiscard,
    this.onLog,
    this.onTick,
    this.now,
    this.scroll,
  });

  final HomeData data;
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
  final VoidCallback? onTick;
  final DateTime? now;
  final ScrollController? scroll;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    final l = AppLocalizations.of(c);
    final rings = [
      for (final k in HomeRingKind.values) ringViewOf(k, data, l),
    ];
    final colors = {
      HomeRingKind.recovery: Pult.orange,
      HomeRingKind.strain: p.ink,
      HomeRingKind.sleep: p.dark ? Pult.blueOnDark : Pult.blue,
    };
    final gaps = [
      for (final r in rings)
        if (r.why != null && r.why!.isNotEmpty) r.why!,
    ];
    return ListView(controller: scroll, padding: pad, children: [
      const SizedBox(height: S.x3),
      Row(children: [
        Text(kAppName.toLowerCase(), style: F.t2.copyWith(color: p.ink)),
        const SizedBox(width: S.x3),
        Expanded(
          child: MinuteTick(
            onTick: onTick,
            builder: (_) => Text(
                syncing ? t.syncing : freshnessText(lastData, now ?? DateTime.now(), t),
                key: const ValueKey('takt-status'),
                textAlign: TextAlign.end,
                style: F.cap.copyWith(color: p.ink2)),
          ),
        ),
        if (header != null) ...[const SizedBox(width: S.x3), header!],
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
        Text(g, style: F.cap.copyWith(color: p.ink2)),
      ],
      const SizedBox(height: S.x3),
      KeyedSubtree(key: const ValueKey('takt-pulse'), child: pulse),
      const SizedBox(height: S.x3),
      Row(key: const ValueKey('takt-cards'), children: [
        Expanded(child: _Card(t.hrv, _num(hrv, 'ms'), () => onCard?.call('hrv'))),
        const SizedBox(width: S.x2),
        Expanded(child: _Card(t.restingHr, _num(data.rhr, ''), () => onCard?.call('resting_hr'))),
        const SizedBox(width: S.x2),
        Expanded(child: _Card(t.steps, _num(data.steps, ''), () => onCard?.call('steps'))),
      ]),
      if (watch != null) ...[const SizedBox(height: S.x3), ...watch!],
      const SizedBox(height: S.x5),
      KeyedSubtree(
        key: const ValueKey('takt-activities'),
        child: ActivityList(items: items, onOpen: onOpen, onDiscard: onDiscard, onLog: onLog),
      ),
    ]);
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
        padding: const EdgeInsets.all(S.x3),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: Pult.digits(24, p.ink)),
          ),
          const SizedBox(height: S.x1),
          Text(label, style: F.cap.copyWith(color: p.ink2)),
        ]),
      ),
    );
  }
}
