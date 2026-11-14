// Pulsverlauf über den gesamten Tag (für vergangene Tage direkt auf Heute
// und als eigener Detailscreen beim Antippen des Live-Puls-Displays).

import 'package:flutter/material.dart';

import '../../data/db.dart' show LocalDb;
import '../../data/local_repository.dart';
import '../../ui2/grammar.dart' show Surface;
import '../../ui2/screens/home_screen.dart' show repoOf;
import '../../ui2/theme.dart';
import '../detail/hr_scrub.dart';
import '../header.dart';
import '../look.dart';
import '../pult_tokens.dart';
import '../stripe/stripe.dart';
import '../takt_text.dart';
import 'pulse_display.dart';
import 'wake_day.dart';

class DayPulseData {
  const DayPulseData({
    this.t0,
    this.hr = const [],
    this.minBpm,
    this.avgBpm,
    this.maxBpm,
  });

  /// Erste gemessene Minute des Tagesfensters.
  final DateTime? t0;

  /// Ein Wert pro Minute ab [t0], null ohne Messung.
  final List<double?> hr;

  final int? minBpm, avgBpm, maxBpm;

  bool get hasSeries => t0 != null && hr.length >= 2 && hr.any((v) => v != null);

  /// Baut die Minutenkurve und Kennwerte aus `(tsSec, bpm)`-Messpunkten.
  static DayPulseData fromSamples(List<(int, num)> rows) {
    final valid = <(int, double)>[
      for (final (ts, bpm) in rows)
        if (ts > 0 && bpm > 0) (ts, bpm.toDouble()),
    ];
    if (valid.isEmpty) return const DayPulseData();
    valid.sort((a, b) => a.$1.compareTo(b.$1));
    final firstMin = valid.first.$1 ~/ 60;
    final lastMin = valid.last.$1 ~/ 60;
    final n = (lastMin - firstMin + 1).clamp(1, 36 * 60);
    final sum = List<double>.filled(n, 0);
    final cnt = List<int>.filled(n, 0);
    var minV = double.infinity;
    var maxV = 0.0;
    var totalSum = 0.0;
    var totalCnt = 0;
    for (final (ts, bpm) in valid) {
      final i = (ts ~/ 60) - firstMin;
      if (i < 0 || i >= n) continue;
      sum[i] += bpm;
      cnt[i]++;
      if (bpm < minV) minV = bpm;
      if (bpm > maxV) maxV = bpm;
      totalSum += bpm;
      totalCnt++;
    }
    final hr = <double?>[
      for (var i = 0; i < n; i++) cnt[i] == 0 ? null : sum[i] / cnt[i],
    ];
    // Bei genau einer gemessenen Minute verdoppeln wir den Punkt, damit
    // LineChart und TaktHrScrub (ab 2 Punkten) sie darstellen können.
    final series = hr.length == 1 ? <double?>[hr.first, hr.first] : hr;
    return DayPulseData(
      t0: DateTime.fromMillisecondsSinceEpoch(firstMin * 60 * 1000),
      hr: series,
      minBpm: totalCnt == 0 ? null : minV.round(),
      avgBpm: totalCnt == 0 ? null : (totalSum / totalCnt).round(),
      maxBpm: totalCnt == 0 ? null : maxV.round(),
    );
  }

  static Future<DayPulseData> load(
    LocalRepository repo,
    String dayId, {
    WakeWindow? window,
    Future<List<(int, int)>> Function(int fromSec, int toSec)? hrSamples,
  }) async {
    WakeWindow win = window ??
        await () async {
          Map<String, dynamic> sleep = const {}, nextSleep = const {};
          try {
            sleep = await repo.getDaySleepV2(dayId);
          } catch (_) {}
          final next = nextDayLabel(dayId);
          if (next != null) {
            try {
              nextSleep = await repo.getDaySleepV2(next);
            } catch (_) {}
          }
          return buildWakeWindow(
            dayId: dayId,
            sleep: sleep,
            nextSleep: nextSleep,
            isActiveAfterMidnight: false,
          );
        }();

    List<(int, num)> pts = const [];
    try {
      final raw = await (hrSamples ??
          (a, b) async => [
                for (final r in await LocalDb.hrSamplesInRange(a, b))
                  ((r['rec_ts'] as num).toInt(), (r['hr'] as num).toInt()),
              ])(win.fromSec, win.toSec);
      pts = [for (final (t, v) in raw) (t, v)];
    } catch (_) {}

    final rawIncomplete = pts.isNotEmpty && (pts.first.$1 > win.fromSec + 3600);
    if (pts.isEmpty || rawIncomplete) {
      // Ältere Tage, deren 1-Hz-Rohdaten bereits bereinigt sind (oder Grenztage,
      // an denen Rohdaten erst spät am Tag beginnen): aus der gespeicherten
      // Tageskurve des Bundles lesen.
      try {
        final tl = await repo.getDayTimeline(dayId);
        final rawCurve = (tl['hr'] as List?) ?? const [];
        final all = <(int, num)>[
          for (final e in rawCurve)
            if (e is Map && e['t'] is num && e['v'] is num)
              ((e['t'] as num).toInt(), e['v'] as num),
        ];
        final inWin = [
          for (final p in all)
            if (p.$1 >= win.fromSec && p.$1 < win.toSec) p,
        ];
        final bundlePts = inWin.isNotEmpty ? inWin : all;
        if (bundlePts.isNotEmpty && (pts.isEmpty || bundlePts.first.$1 < pts.first.$1)) {
          pts = bundlePts;
        }
      } catch (_) {}
    }

    return fromSamples(pts);
  }
}

/// Karte mit dem ablesbaren Pulsverlauf eines Tages (`TaktHrScrub`).
/// Steht auf vergangenen Tagen direkt auf dem Heute-Screen und unter dem
/// Live-Puls im `TaktPulseDetail`.
class TaktDayPulseCard extends StatelessWidget {
  const TaktDayPulseCard({super.key, required this.data});

  final DayPulseData data;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    if (!data.hasSeries) {
      return TaktLook(
        child: Surface(
          key: const ValueKey('takt-day-pulse-empty'),
          child: StripeDodge(
            line: true,
            child: Text(t.noPulseRecorded, style: F.cap.copyWith(color: p.ink2)),
          ),
        ),
      );
    }
    return TaktLook(
      child: Surface(
        key: const ValueKey('takt-day-pulse-card'),
        child: TaktHrScrub(
          hr: data.hr,
          t0: data.t0!,
          title: t.pulseToday,
          height: 130,
        ),
      ),
    );
  }
}

/// Detailscreen hinter dem Puls-Display: auf dem aktuellen Tag mit Live-Puls
/// oben, darunter der ablesbare Tagesverlauf und Tiefst-, Durchschnitts- und
/// Höchstwert, mit Tages-Umschalter im Kopf.
class TaktPulseDetail extends StatefulWidget {
  const TaktPulseDetail({
    super.key,
    this.initialDay,
    this.activeDay,
    this.days = const [],
    this.data,
    this.pulse,
    this.hrSamples,
  });

  final String? initialDay;
  final String? activeDay;
  final List<String> days;

  /// Vorgeladen für Tests.
  final DayPulseData? data;

  /// Ersetzt das echte `PulseDisplay` in Widget-Tests ohne `AppState`.
  final Widget? pulse;

  final Future<List<(int, int)>> Function(int fromSec, int toSec)? hrSamples;

  @override
  State<TaktPulseDetail> createState() => _TaktPulseDetailState();
}

class _TaktPulseDetailState extends State<TaktPulseDetail> {
  String? _day;
  String? _activeDay;
  List<String> _days = const [];
  DayPulseData? _data;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _day = widget.initialDay;
    _activeDay = widget.activeDay ?? widget.initialDay;
    _days = widget.days;
    _data = widget.data;
    if (_data == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final repo = repoOf(context);
    if (repo == null) {
      setState(() => _data = const DayPulseData());
      return;
    }
    final gen = ++_gen;
    try {
      final loaded = await loadTaktDay(repo, selectedDay: _day);
      final pulse = await DayPulseData.load(
        repo,
        loaded.dayId,
        window: loaded.window,
        hrSamples: widget.hrSamples,
      );
      if (!mounted || gen != _gen) return;
      setState(() {
        _day = loaded.dayId;
        _activeDay = loaded.activeDayId;
        _days = loaded.availableDays;
        _data = pulse;
      });
    } catch (_) {
      if (mounted && gen == _gen) {
        setState(() => _data = const DayPulseData());
      }
    }
  }

  void _onDay(String day) {
    setState(() {
      _day = day;
      if (widget.data == null) _data = null;
    });
    if (widget.data == null) _load();
  }

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    final shown = _day ?? _activeDay;
    final isToday = shown == null || shown == _activeDay;
    final d = _data;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: S.x4),
            child: TaktHeader(
              t.pulseHead,
              back: true,
              center: _days.isEmpty
                  ? null
                  : TaktDayStepper(
                      day: shown,
                      days: _days,
                      onDay: _onDay,
                      labelOf: (day, de) =>
                          day == _activeDay ? TaktText(de).todayCap : dayShortLabel(day, de),
                    ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(S.x4, S.x2, S.x4, S.x10),
              children: [
                if (isToday) ...[
                  widget.pulse ?? const PulseDisplay(),
                  const SizedBox(height: S.x4),
                ],
                if (d != null) ...[
                  TaktDayPulseCard(data: d),
                  if (d.hasSeries &&
                      (d.minBpm != null || d.avgBpm != null || d.maxBpm != null)) ...[
                    const SizedBox(height: S.x4),
                    Surface(
                      key: const ValueKey('takt-pulse-stats'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (d.minBpm != null)
                            _PulseRow(t.pulseMinRow, '${d.minBpm}', 'bpm', first: true),
                          if (d.avgBpm != null)
                            _PulseRow(t.pulseAvgRow, '${d.avgBpm}', 'bpm',
                                first: d.minBpm == null),
                          if (d.maxBpm != null)
                            _PulseRow(t.pulseMaxRow, '${d.maxBpm}', 'bpm',
                                first: d.minBpm == null && d.avgBpm == null),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _PulseRow extends StatelessWidget {
  const _PulseRow(this.label, this.value, this.unit, {this.first = false});
  final String label, value, unit;
  final bool first;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(vertical: S.x2),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: p.line)),
      ),
      child: Row(children: [
        Expanded(
          child: StripeDodge(
            line: true,
            child: Text(label, style: F.body.copyWith(color: p.ink2)),
          ),
        ),
        const SizedBox(width: S.x2),
        StripeDodge(
          align: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: Pult.digits(22, p.ink)),
              const SizedBox(width: S.x1),
              Text(unit, style: F.cap.copyWith(color: p.ink2)),
            ],
          ),
        ),
      ]),
    );
  }
}
