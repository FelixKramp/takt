// Feature 04, D4 und D5: der Screen hinter dem Batterie-Ring. Stand, Kurve
// über den Tag, die Rechnung und der Weg zur Erholung, aus der die Ladung
// kommt.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/decimal_text.dart' show displayFixed;
import '../../ui2/activity/day_strain.dart' show DayStrainData;
import '../../ui2/charts.dart' show AxisSpec, LineChart, axisInt;
import '../../ui2/grammar.dart' show ChartFrame, Pressable, Surface;
import '../../ui2/screens/home_screen.dart'
    show HomeData, HomeRingKind, repoOf, ringViewOf;
import '../../ui2/screens/readiness_detail.dart' show ReadinessDetail;
import '../../ui2/theme.dart';
import '../detail/value_card.dart';
import '../header.dart';
import '../look.dart';
import '../pult_tokens.dart';
import '../stripe/stripe.dart';
import '../takt_text.dart';
import 'battery.dart';

class BatteryDetailData {
  const BatteryDetailData({
    this.morning,
    this.strain,
    this.strainCurve = const [],
    this.why,
    this.now,
  });

  /// Die Erholung des Tages, 0 bis 100. Null: noch keine.
  final double? morning;
  final double? strain;

  /// Kumulierter Strain pro Minute des Tages (00:00 bis 24:00).
  final List<double?> strainCurve;

  /// Warum es keine Ladung gibt (der Grund des Erholungsrings).
  final String? why;
  final DateTime? now;

  BatteryDetailData copyWith({String? why}) => BatteryDetailData(
      morning: morning, strain: strain, strainCurve: strainCurve, why: why ?? this.why, now: now);

  static Future<BatteryDetailData> load(BuildContext c) async {
    final repo = repoOf(c);
    final l = AppLocalizations.of(c);
    if (repo == null) return const BatteryDetailData();
    final d = await HomeData.load(repo, l);
    List<double?> curve = const [];
    try {
      curve = (await DayStrainData.load(repo)).curve;
    } catch (_) {
      // Ohne Kurve bleiben Wertkarte und Rechnung.
    }
    return BatteryDetailData(
      morning: d.readiness.value?.toDouble(),
      strain: d.strain.value?.toDouble(),
      strainCurve: curve,
      why: ringViewOf(HomeRingKind.recovery, d, l).why,
    );
  }
}

class BatteryDetail extends StatefulWidget {
  const BatteryDetail({super.key, this.data});

  /// Vorgeladen für Tests. Null: aus dem Repo.
  final BatteryDetailData? data;

  @override
  State<BatteryDetail> createState() => _BatteryDetailState();
}

class _BatteryDetailState extends State<BatteryDetail> {
  BatteryDetailData? _data;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    if (_data == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          final d = await BatteryDetailData.load(context);
          if (mounted) setState(() => _data = d);
        } catch (_) {
          if (mounted) setState(() => _data = const BatteryDetailData());
        }
      });
    }
  }

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    final d = _data;
    final morning = d?.morning;
    final left = morning == null ? null : batteryLeft(morning, d!.strain);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: S.x4),
            child: TaktHeader(t.batteryHead, back: true),
          ),
          Expanded(
            child: d == null
                ? const SizedBox.shrink()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(S.x4, S.x2, S.x4, S.x10),
                    children: [
                      TaktValueCard(
                        value: left?.toString(),
                        unit: '%',
                        when: morning == null ? null : t.batteryMorning(morning.round()),
                        why: d.why ?? t.noValueYet,
                      ),
                      if (morning != null && d.strain == null) ...[
                        const SizedBox(height: S.x3),
                        StripeDodge(
                          line: true,
                          child: Text(t.strainPending, style: F.cap.copyWith(color: p.ink2)),
                        ),
                      ],
                      if (morning != null && d.strainCurve.any((v) => v != null)) ...[
                        const SizedBox(height: S.x4),
                        Surface(child: _curve(c, p, t, morning, d.strainCurve)),
                      ],
                      if (morning != null) ...[
                        const SizedBox(height: S.x4),
                        Surface(
                          key: const ValueKey('takt-battery-rule'),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _Row(t.batteryMorningRow, '${morning.round()}', '%', first: true),
                            _Row(t.batteryStrainRow,
                                d.strain == null ? '–' : displayFixed(d.strain!, 1), ''),
                            _Row(t.batteryNowRow, '$left', '%'),
                            const SizedBox(height: S.x3),
                            StripeDodge(
                              line: true,
                              child: Text(t.batteryRule,
                                  style: F.cap.copyWith(color: p.ink2, height: 1.4)),
                            ),
                          ]),
                        ),
                      ],
                      const SizedBox(height: S.x4),
                      Pressable(
                        key: const ValueKey('takt-battery-why'),
                        onTap: () => Navigator.of(c).push(MaterialPageRoute<void>(
                            builder: (_) => const TaktLook(child: ReadinessDetail()))),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: S.tap),
                          padding: const EdgeInsets.symmetric(horizontal: S.x4, vertical: S.x2),
                          decoration: BoxDecoration(
                            color: p.card,
                            borderRadius: R.rSm,
                            border: Border.all(color: p.line),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: StripeDodge(
                                line: true,
                                child: Text(t.batteryWhy,
                                    style: F.body.copyWith(
                                        color: p.ink, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            Icon(LucideIcons.chevronRight, size: 16, color: p.ink3),
                          ]),
                        ),
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _curve(BuildContext c, P p, TaktText t, double morning, List<double?> strain) {
    final curve = batteryCurve(morning, strain);
    final axis = AxisSpec(min: 0, max: 100, ticks: 3, format: axisInt);
    return ChartFrame(
      title: t.batteryToday,
      unit: '%',
      height: 140,
      yAxis: axis,
      xLabels: const ['00:00', '12:00', '24:00'],
      series: curve,
      child: CustomPaint(
        size: Size.infinite,
        painter: LineChart(curve, Pult.orangeFor(p.dark), axis: axis),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, this.unit, {this.first = false});
  final String label, value, unit;
  final bool first;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(vertical: S.x2),
      decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: p.line))),
      child: Row(children: [
        Expanded(
          child: StripeDodge(
              line: true, child: Text(label, style: F.body.copyWith(color: p.ink2))),
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
              if (unit.isNotEmpty) ...[
                const SizedBox(width: S.x1),
                Text(unit, style: F.cap.copyWith(color: p.ink2)),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}
