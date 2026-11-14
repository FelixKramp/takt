// Feature 05: Vitalwerte und Trends im Takt-Design (Pult-Ästhetik).
//
// Strukturierte, auffällige Kacheln statt nüchterner Tabellenzeilen:
// - Vitalwerte: Tagespuls-Bereich (Min/Max mit Verlauf), Atemfrequenz,
//   Hauttemperatur, Tragedauer und HRV-Analyse, gesteuert über TaktDayStepper.
// - Trends: Ruhepuls, HRV, Schlafdauer und Konsistenz mit 30-Tage-Kurve,
//   Referenzbereich und Pult-Ziffern.
// - Alle Zahlen in StripeDodge gehüllt.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/day_label.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/decimal_text.dart';
import '../../ui2/ui2.dart';
import '../../ui2/screens/advanced.dart';
import '../../ui2/screens/health_screen.dart';
import '../../ui2/screens/home_screen.dart';
import '../../ui2/screens/investigate.dart';
import '../../ui2/screens/metric_detail.dart';
import '../header.dart';
import '../pult_tokens.dart';
import '../stress/day_stress.dart';
import '../stress/takt_stress_view.dart';
import '../stripe/stripe.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 1. TaktSubTabBar — Flache, elegante Segment-Navigation im Takt-Design
// ══════════════════════════════════════════════════════════════════════════════

class TaktSubTabBar extends StatelessWidget {
  const TaktSubTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<String> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: S.x2),
              _TaktTabItem(
                label: items[i],
                on: i == index,
                onTap: () => onTap(i),
                ink: p.ink,
                ink3: p.ink3,
                accent: Pult.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaktTabItem extends StatelessWidget {
  const _TaktTabItem({
    required this.label,
    required this.on,
    required this.onTap,
    required this.ink,
    required this.ink3,
    required this.accent,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;
  final Color ink, ink3, accent;

  @override
  Widget build(BuildContext c) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x1),
        decoration: BoxDecoration(
          color: on ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: R.rSm,
          border: Border.all(
            color: on ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: F.cap.copyWith(
              color: on ? ink : ink3,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. TaktVitalsView — Vitalwerte als prominente Kacheln
// ══════════════════════════════════════════════════════════════════════════════

class TaktVitalsView extends StatelessWidget {
  const TaktVitalsView({
    super.key,
    required this.vitals,
    required this.health,
    required this.vDay,
    required this.vDays,
    required this.vFailed,
    required this.onDay,
    required this.onRetry,
    this.now,
  });

  /// The wall clock, injected only by tests: "Heute" is a calendar fact.
  final DateTime? now;

  final VitalsData? vitals;
  final HealthData health;
  final String? vDay;
  final List<String>? vDays;
  final bool vFailed;
  final ValueChanged<String> onDay;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final l = AppLocalizations.of(c);
    final de = Localizations.localeOf(c).languageCode == 'de';
    final v = vitals;

    final days = vDays ?? v?.days ?? [];
    final today = todayLabel(now);
    final shownDay = vDay ?? v?.day ?? (days.isNotEmpty ? days.first : today);

    if (v == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (days.isNotEmpty)
          _DayStepperHeader(
            shownDay: shownDay,
            days: days,
            onDay: onDay,
            de: de,
            today: today,
          ),
        const SizedBox(height: S.x3),
        vFailed
            ? StatusCard(
                l == null ? 'Vitalwerte' : l.healthCouldNotRead(l.healthWhatVitals),
                l?.healthReadFailedBody ??
                    'Die gespeicherten Daten konnten nicht geladen werden.',
                fix: l?.healthTryAgain ?? 'Erneut versuchen',
                icon: LucideIcons.databaseZap,
                onFix: onRetry,
              )
            : const Padding(
                padding: EdgeInsets.only(top: S.x8),
                child: Center(child: CircularProgressIndicator()),
              ),
      ]);
    }

    final highs = v.timeline['highs'];
    num? high(String k) {
      final e = highs is Map ? highs[k] : null;
      return e is Map ? e['v'] as num? : null;
    }

    final lo = high('low_hr'), hi = high('peak_hr');
    final respBlock = v.lungs['resp'];
    final resp = respBlock is Map ? respBlock['value'] as num? : null;
    final worn = v.wear['worn_min'] as num?;
    final coverage = v.wear['coverage_pct'] as num?;
    // Skin temperature is read off the latest overnight bundle, so it belongs
    // to ONE day. Under any other day it is not that day's reading and is left
    // out, never shown as if it were (G4).
    final tempNight = heldOverNightOf(health.today);
    final tempBelongsHere = _skinTempDay(health.today, tempNight, days) == shownDay;
    final skinTemp = tempBelongsHere
        ? metricOf(health.today['skin_temp'])
        : metricOf(null);
    final tempDevC = tempBelongsHere
        ? ((health.today['skin_temp'] as Map?)?['dev_c'] as num?)?.toDouble()
        : null;
    final rmssd = v.hrv['rmssd'] as num?;

    final hasAnyData = (lo != null && hi != null) ||
        resp != null ||
        (skinTemp.value != null || tempDevC != null) ||
        worn != null;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (days.isNotEmpty)
        _DayStepperHeader(
          shownDay: shownDay,
          days: days,
          onDay: onDay,
          de: de,
          today: today,
        ),
      const SizedBox(height: S.x3),
      if (!hasAnyData)
        StatusCard(
          l?.healthNothingMeasuredDay ?? 'Nichts gemessen für diesen Tag',
          l?.healthNoBandRecordings ??
              'Der Sensor war ausgeschaltet oder es bestand keine Verbindung.',
          icon: LucideIcons.moon,
        )
      else ...[
        // 1. Tagespuls-Bereich (Min & Peak)
        if (lo != null && hi != null) ...[
          _HeartRateSpanCard(
            lowHr: lo.round(),
            peakHr: hi.round(),
            de: de,
          ),
          const SizedBox(height: S.x3),
        ],

        // 2. Kachel-Reihe: Atemfrequenz & Hauttemperatur
        Row(
          children: [
            if (resp != null)
              Expanded(
                child: _VitalStatCard(
                  icon: LucideIcons.wind,
                  iconColor: C.teal,
                  title: de ? 'ATEMFREQUENZ' : 'RESPIRATORY',
                  value: displayFixed(resp, 1),
                  unit: 'br/min',
                  sub: de ? 'Im Schlaf' : 'Asleep',
                  onTap: () => go(c, const MetricDetail('resp_rate')),
                ),
              ),
            if (resp != null && (skinTemp.value != null || tempDevC != null))
              const SizedBox(width: S.x3),
            if (skinTemp.value != null || tempDevC != null)
              Expanded(
                child: _VitalStatCard(
                  icon: LucideIcons.thermometer,
                  iconColor: C.orange,
                  title: de ? 'HAUTTEMPERATUR' : 'SKIN TEMP',
                  value: tempDevC != null
                      ? '${tempDevC >= 0 ? '+' : '−'}${displayFixed(tempDevC.abs(), 1)}'
                      : '${skinTemp.value! >= 0 ? '+' : '−'}${displayFixed(skinTemp.value!.abs(), 2)}',
                  unit: tempDevC != null ? '°C' : 'SD',
                  sub: tempNight != null
                      ? '${de ? 'Nacht auf' : 'Night to'} ${dayShortLabel(tempNight, de)}'
                      : (de ? 'vs. eigene Nächte' : 'vs usual nights'),
                  onTap: () => go(c, const MetricDetail('skin_temp')),
                ),
              ),
          ],
        ),
        if (resp != null || (skinTemp.value != null || tempDevC != null))
          const SizedBox(height: S.x3),

        // 3. Tragedauer
        if (worn != null) ...[
          _WearTimeCard(
            wornMin: worn.toInt(),
            coveragePct: coverage?.toDouble(),
            de: de,
            onTap: () => go(c, const MetricDetail('wear')),
          ),
          const SizedBox(height: S.x3),
        ],

        // 4. HRV-Analyse (Deep Dive)
        if (rmssd != null) ...[
          _HrvDeepDiveCard(
            rmssd: rmssd.round(),
            health: health,
            de: de,
            onTap: () => go(c, const Investigate('hrv')),
          ),
          const SizedBox(height: S.x3),
        ],

        // 5. Erweiterte Forschungscharts
        Surface(
          onTap: () => go(c, const AdvancedScreen()),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.card2,
                  borderRadius: R.rSm,
                ),
                child: Icon(LucideIcons.flaskConical, size: 20, color: p.ink),
              ),
              const SizedBox(width: S.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      de ? 'Erweiterte Analysen' : 'Advanced charts',
                      style: F.body.copyWith(
                        color: p.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      de
                          ? 'Schlag-zu-Schlag-Zeiten, Schlafphasen und Rohdaten'
                          : 'Beat-to-beat detail and sleep timing',
                      style: F.cap.copyWith(color: p.ink3),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: p.ink3),
            ],
          ),
        ),
      ],
    ]);
  }
}

/// The day the skin-temperature block in [today] describes: the night it is held
/// over from, else today's own day, else (a bare bundle) the newest derived day.
String? _skinTempDay(
  Map<String, dynamic> today,
  String? heldOverNight,
  List<String> days,
) {
  if (heldOverNight != null) return heldOverNight;
  final st = today['status'];
  final own = st is Map ? st['today_day']?.toString() : null;
  return own ?? (days.isEmpty ? null : days.first);
}

class _DayStepperHeader extends StatelessWidget {
  const _DayStepperHeader({
    required this.shownDay,
    required this.days,
    required this.onDay,
    required this.de,
    required this.today,
  });

  final String shownDay;
  final List<String> days;
  final ValueChanged<String> onDay;
  final bool de;
  final String today;

  @override
  Widget build(BuildContext c) {
    // "Heute" only for the calendar day itself. The newest derived day is
    // often an older one after a sync gap and must carry its own date (G4).
    return Container(
      padding: const EdgeInsets.symmetric(vertical: S.x1),
      alignment: Alignment.center,
      child: TaktDayStepper(
        day: shownDay,
        days: days,
        onDay: onDay,
        labelOf: (d, isDe) =>
            (d == today) ? (isDe ? 'Heute' : 'Today') : dayShortLabel(d, isDe),
      ),
    );
  }
}

class _HeartRateSpanCard extends StatelessWidget {
  const _HeartRateSpanCard({
    required this.lowHr,
    required this.peakHr,
    required this.de,
  });

  final int lowHr, peakHr;
  final bool de;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Surface(
      onTap: () => go(c, const MetricDetail('resting_hr')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.heart, size: 16, color: C.red),
              const SizedBox(width: S.x2),
              Text(
                de ? 'TAGESPULS-BEREICH' : 'HEART RATE SPAN',
                style: F.cap.copyWith(color: p.ink2, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(LucideIcons.chevronRight, size: 16, color: p.ink3),
            ],
          ),
          const SizedBox(height: S.x3),
          Row(
            children: [
              // Min HR
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      de ? 'TIEFSTWERT' : 'LOWEST',
                      style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    StripeDodge(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$lowHr',
                            style: Pult.digits(32, p.ink),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('bpm', style: F.cap.copyWith(color: p.ink3)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Max HR
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      de ? 'SPITZENWERT' : 'PEAK',
                      style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    StripeDodge(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$peakHr',
                            style: Pult.digits(32, Pult.orange),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('bpm', style: F.cap.copyWith(color: p.ink3)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: S.x3),
          // Visuelle Spannbreite
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: R.rPill,
              gradient: LinearGradient(
                colors: [
                  C.red.withValues(alpha: 0.5),
                  Pult.orange,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalStatCard extends StatelessWidget {
  const _VitalStatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.unit,
    required this.sub,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title, value, unit, sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Surface(
      onTap: onTap,
      pad: const EdgeInsets.all(S.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: S.x1),
              Expanded(
                child: Text(
                  title,
                  style: F.over.copyWith(color: p.ink2, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 14, color: p.ink3),
            ],
          ),
          const SizedBox(height: S.x2),
          StripeDodge(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: Pult.digits(28, p.ink)),
                  const SizedBox(width: 4),
                  Text(unit, style: F.cap.copyWith(color: p.ink3)),
                ],
              ),
            ),
          ),
          const SizedBox(height: S.x1),
          StripeDodge(
            line: true,
            child: Text(
              sub,
              style: F.over.copyWith(color: p.ink3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _WearTimeCard extends StatelessWidget {
  const _WearTimeCard({
    required this.wornMin,
    required this.coveragePct,
    required this.de,
    this.onTap,
  });

  final int wornMin;
  final double? coveragePct;
  final bool de;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final hours = wornMin ~/ 60;
    final mins = wornMin % 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}m' : '$mins min';
    // No coverage figure is no figure: not 0 % (G8).
    final cov = coveragePct?.clamp(0.0, 100.0);

    return Surface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.watch, size: 16, color: C.green),
              const SizedBox(width: S.x2),
              Text(
                de ? 'SENSOR-TRAGEDAUER' : 'WEAR TIME',
                style: F.cap.copyWith(color: p.ink2, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(LucideIcons.chevronRight, size: 16, color: p.ink3),
            ],
          ),
          const SizedBox(height: S.x2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StripeDodge(
                child: Text(timeStr, style: Pult.digits(30, p.ink)),
              ),
              const SizedBox(width: S.x3),
              if (cov != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: StripeDodge(
                      line: true,
                      child: Text(
                        '${cov.round()}% ${de ? 'des Tages getragen' : 'of the day'}',
                        style: F.cap.copyWith(color: p.ink3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (cov != null) ...[
            const SizedBox(height: S.x2),
            ClipRRect(
              borderRadius: R.rPill,
              child: LinearProgressIndicator(
                value: cov / 100.0,
                minHeight: 6,
                backgroundColor: p.card2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  cov >= 80 ? C.green : Pult.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HrvDeepDiveCard extends StatelessWidget {
  const _HrvDeepDiveCard({
    required this.rmssd,
    required this.health,
    required this.de,
    required this.onTap,
  });

  final int rmssd;
  final HealthData health;
  final bool de;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    const days = 30;
    final pts = health.points('hrv');
    final win = denseDays(pts, days);
    final have = [for (final v in win) ?v];
    final axis = AxisSpec.of(have, ticks: 2);

    return Surface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.activity, size: 16, color: C.green),
              const SizedBox(width: S.x2),
              Text(
                de ? 'HRV-ANALYSE (RMSSD)' : 'HRV DEEP DIVE',
                style: F.cap.copyWith(color: p.ink2, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(LucideIcons.chevronRight, size: 16, color: p.ink3),
            ],
          ),
          const SizedBox(height: S.x2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StripeDodge(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$rmssd', style: Pult.digits(32, p.ink)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('ms', style: F.cap.copyWith(color: p.ink3)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: S.x3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: StripeDodge(
                    line: true,
                    child: Text(
                      de ? '30-Tage-Verlauf' : '30-day history',
                      style: F.cap.copyWith(color: p.ink3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: S.x2),
          SizedBox(
            height: 48,
            child: have.length < 2
                ? Center(
                    child: Text(
                      de ? 'Noch nicht genug Daten' : 'Not enough data yet',
                      style: F.cap.copyWith(color: p.ink3),
                    ),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: LineChart(
                      win,
                      p.on(C.green),
                      t: 1.0,
                      axis: axis,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. TaktTrendsView — Trends als klare, strukturierte Takt-Karten
// ══════════════════════════════════════════════════════════════════════════════

class TaktTrendsView extends StatelessWidget {
  const TaktTrendsView({super.key, required this.data});

  final HealthData data;

  @override
  Widget build(BuildContext c) {
    final l = AppLocalizations.of(c);
    final de = Localizations.localeOf(c).languageCode == 'de';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Ruhepuls-Trend
        _buildTrendCard(
          c,
          key: 'resting_hr',
          label: de ? 'Ruhepuls' : (l?.healthRowRestingHr ?? 'Resting heart rate'),
          unit: 'bpm',
          color: C.red,
          higherBetter: false,
          de: de,
        ),
        const SizedBox(height: S.x3),

        // 2. HRV-Trend
        _buildTrendCard(
          c,
          key: 'hrv',
          label: de ? 'HRV' : (l?.healthRowHrv ?? 'HRV'),
          unit: 'ms',
          color: C.green,
          higherBetter: true,
          de: de,
        ),
        const SizedBox(height: S.x3),

        // 3. Schlafdauer-Trend
        _buildTrendCard(
          c,
          key: 'sleep',
          label: de ? 'Schlafdauer' : (l?.healthTimeAsleep ?? 'Time asleep'),
          unit: '',
          color: C.blue,
          higherBetter: true,
          against: data.need.value?.toDouble(),
          againstLabel: data.need.value != null
              ? (de ? 'Bedarf: ${hm(data.need.value)}' : 'Need: ${hm(data.need.value)}')
              : null,
          de: de,
        ),
        const SizedBox(height: S.x3),

        // 4. Tages-Stress (Whoop-Style Stressverlauf)
        if (data.partial)
          const TaktLoadingCard(key: ValueKey('takt-stress-loading'))
        else
          TaktStressCard(
            analysis: data.stressAnalysis ?? DayStressAnalysis.empty(todayLabel()),
          ),
        const SizedBox(height: S.x3),

        // 5. Daten-Konsistenz
        _buildConsistencyCard(c, de),
      ],
    );
  }

  Widget _buildTrendCard(
    BuildContext c, {
    required String key,
    required String label,
    required String unit,
    required Color color,
    required bool higherBetter,
    required bool de,
    double? against,
    String? againstLabel,
  }) {
    final pts = data.points(key);
    final l = AppLocalizations.of(c);

    if (pts.isEmpty) {
      return StatusCard(
        l?.healthNoTrendYet(label) ?? 'No $label trend yet',
        l?.healthZeroDaysStored ?? '0 days stored.',
        icon: LucideIcons.chartLine,
      );
    }

    final s = [for (final p in pts) p.v];
    final band = usualRangeFor(key, s, data.baselines);
    final prior = s.length - 1;
    final abstain = prior < kUsualMinDays
        ? usualNeedsDaysText(l, s.length)
        : (de ? 'Noch kein üblicher Bereich' : 'no usual range yet');
    final win = denseDays(pts, 30);
    final toNeed = against == null ? null : s.last - against;
    String fmt(double v) => key == 'sleep' ? hm(v) : metricValue(unit, v);
    // The big number is the newest STORED point, which after a sync gap is
    // not today's. Say when it is from, as the OpenStrap card does (G3).
    final behind = daysBehind(pts.last.t) ?? 0;
    final asOf = behind <= 0
        ? ''
        : (l?.healthAsOf(axisDay(pts.last.t)) ?? ' · as of ${axisDay(pts.last.t)}');
    final base = againstLabel ??
        (band == null ? abstain : (de ? 'Üblicher Bereich' : 'Usual range'));
    final window = base.isEmpty ? asOf.replaceFirst(' · ', '') : '$base$asOf';

    return TaktTrendCard(
      label: label,
      value: fmt(s.last),
      unit: key == 'sleep' ? '' : unit,
      series: win,
      color: color,
      band: band,
      latest: s.last,
      higherBetter: higherBetter,
      delta: toNeed != null
          ? signed(toNeed, fmt(toNeed.abs()))
          : (band != null
              ? signed(s.last - band.usual, fmt((s.last - band.usual).abs()))
              : ''),
      window: window,
      onTap: () => go(c, MetricDetail(key)),
      format: fmt,
      de: de,
    );
  }

  Widget _buildConsistencyCard(BuildContext c, bool de) {
    final p = P.of(c);
    final days = data.daysWithData.clamp(0, 30);
    final pct = (days / 30.0).clamp(0.0, 1.0);

    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.calendarCheck, size: 16, color: Pult.orange),
              const SizedBox(width: S.x2),
              Text(
                de ? 'DATEN-KONSISTENZ' : 'CONSISTENCY',
                style: F.cap.copyWith(color: p.ink2, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: S.x2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              StripeDodge(
                child: Text('$days', style: Pult.digits(32, p.ink)),
              ),
              const SizedBox(width: 4),
              StripeDodge(
                line: true,
                child: Text(
                  '/ 30 ${de ? 'Tage' : 'days'}',
                  style: F.cap.copyWith(color: p.ink3),
                ),
              ),
            ],
          ),
          const SizedBox(height: S.x1),
          StripeDodge(
            line: true,
            child: Text(
              de
                  ? 'Tage mit Sensoraufzeichnung in den letzten 30 Tagen'
                  : 'Days with a score in the last 30 days',
              style: F.cap.copyWith(color: p.ink3),
            ),
          ),
          const SizedBox(height: S.x3),
          ClipRRect(
            borderRadius: R.rPill,
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: p.card2,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 0.7 ? C.green : Pult.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaktTrendCard extends StatefulWidget {
  const TaktTrendCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.series,
    required this.color,
    required this.de,
    this.band,
    this.latest,
    this.higherBetter = true,
    this.delta = '',
    this.window = '',
    this.onTap,
    this.format,
  });

  final String label, value, unit, delta, window;
  final List<double?> series;
  final Color color;
  final bool de;
  final UsualRange? band;
  final double? latest;
  final bool? higherBetter;
  final VoidCallback? onTap;
  final String Function(double)? format;

  @override
  State<TaktTrendCard> createState() => _TaktTrendCardState();
}

/// How long ago the scrubbed point is: "Heute", "Vor 1 Tag", "Vor 3 Tagen".
String _ago(int days, bool de) {
  if (days <= 0) return de ? 'Heute' : 'Today';
  if (de) return days == 1 ? 'Vor 1 Tag' : 'Vor $days Tagen';
  return days == 1 ? '1 day ago' : '$days days ago';
}

class _TaktTrendCardState extends State<TaktTrendCard> {
  int? _held;

  String _fmt(double v) => widget.format?.call(v) ?? axisFixedOrInt(v);

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final w = widget;
    final band = w.latest == null ? null : w.band;
    final side = band?.side(w.latest!);

    final good = side == null
        ? null
        : (side == Side.inside
            ? true
            : (side == Side.above
                ? (w.higherBetter == true)
                : (w.higherBetter == false)));

    final statusText = side == null
        ? ''
        : (side == Side.inside
            ? (w.de ? 'Im üblichen Bereich' : 'Within usual')
            : (side == Side.above
                ? (w.de ? 'Über üblichem Bereich' : 'Above usual')
                : (w.de ? 'Unter üblichem Bereich' : 'Below usual')));

    final statusColor = good == null
        ? p.ink3
        : (good ? p.on(C.green) : Pult.orange);

    final vals = [for (final v in w.series) if (v != null && v.isFinite) v];
    final axis = band?.axis(vals, format: _fmt);

    final held = _held;
    final heldValue = held == null || held >= w.series.length ? null : w.series[held];

    Widget chart = Stack(
      fit: StackFit.expand,
      children: [
        if (band != null && axis != null)
          BandLayer(band, axis, p.wash(w.color)),
        CustomPaint(
          size: Size.infinite,
          painter: LineChart(
            w.series,
            p.on(w.color),
            fill: false,
            dots: band != null,
            dotInk: p.card,
            axis: axis,
            selectedX: held == null || w.series.length < 2
                ? null
                : held / (w.series.length - 1),
          ),
        ),
      ],
    );

    if (w.series.length > 1) {
      chart = ExcludeSemantics(
        child: Scrubber(
          hold: true,
          value: held == null ? null : held / (w.series.length - 1),
          step: 1 / (w.series.length - 1),
          label: w.label,
          describe: (_) => '',
          onChanged: (v) => setState(
            () => _held = (v * (w.series.length - 1)).round(),
          ),
          onEnd: () => setState(() => _held = null),
          child: chart,
        ),
      );
    }

    return Surface(
      onTap: w.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                w.label.toUpperCase(),
                style: F.cap.copyWith(color: p.ink2, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: S.x2),
              const Spacer(),
              if (statusText.isNotEmpty)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: R.rSm,
                    ),
                    child: Text(
                      statusText,
                      style: F.over.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              const SizedBox(width: S.x1),
              Icon(LucideIcons.chevronRight, size: 16, color: p.ink3),
            ],
          ),
          const SizedBox(height: S.x2),

          // Hero Value & Delta
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: StripeDodge(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          heldValue != null ? _fmt(heldValue) : w.value,
                          style: Pult.digits(34, p.ink),
                        ),
                        if (w.unit.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(w.unit, style: F.cap.copyWith(color: p.ink3)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (w.delta.isNotEmpty) ...[
                const SizedBox(width: S.x2),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: StripeDodge(
                      line: true,
                      align: 1,
                      child: Text(
                        w.delta,
                        textAlign: TextAlign.end,
                        style: F.body.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          StripeDodge(
            line: true,
            child: Text(
              held != null ? _ago(w.series.length - 1 - held, w.de) : w.window,
              style: F.cap.copyWith(color: p.ink3),
            ),
          ),
          const SizedBox(height: S.x3),

          // 30-Tage-Kurve
          SizedBox(height: 80, child: chart),
        ],
      ),
    );
  }
}

/// Platzhalter, solange ein schwerer Teil (Körperalter, Tagesstress) noch
/// rechnet: gleiche Kartenform, ein ruhiger Balken, keine Zahl.
class TaktLoadingCard extends StatelessWidget {
  const TaktLoadingCard({super.key});

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: R.rMd,
        border: Border.all(color: p.line),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: S.x5),
      child: ClipRRect(
        borderRadius: R.rPill,
        child: LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: p.card2,
          color: p.ink3,
        ),
      ),
    );
  }
}
