// Takt Feature: Stress-Tagesansicht & Karte (Whoop-Style Stress Monitor).
//
// Zeigt den Stressverlauf über den gesamten Tag (0,0 bis 3,0 Skala):
// - Interaktive 24h-Kurve mit Zeitachse (00:00 bis 24:00), Scrubbing und Zonen
// - Sport & Aktivitäten als Aktivitätsblöcke ohne künstlichen Stress-Score (G13)
// - Pult-Ästhetik mit StripeDodge und Pult.digits (B5)

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../data/day_label.dart';
import '../../l10n/decimal_text.dart';
import '../../state/app_state.dart';
import '../../ui2/ui2.dart';
import '../header.dart';
import '../look.dart';
import '../pult_tokens.dart';
import '../stripe/stripe.dart';
import 'day_stress.dart';

/// Berechnet die Farbe für einen Stresswert oder eine Aktivität unter Berücksichtigung von P.
Color stressZoneColor(double? score, P p) {
  if (score == null) return p.on(C.blue); // Aktivität / Sport
  if (score < 1.0) return p.on(C.teal); // Niedrig
  if (score < 2.0) return Pult.orangeFor(p.dark); // Mittel
  return p.on(C.red); // Hoch
}

String stressZoneLabel(double? score, bool de) {
  if (score == null) return de ? 'Sport' : 'Activity';
  if (score < 1.0) return de ? 'Niedrig' : 'Low';
  if (score < 2.0) return de ? 'Mittel' : 'Medium';
  return de ? 'Hoch' : 'High';
}

/// G22: Sommerzeit-sichere Kalender-Verschiebung um [delta] Tage (kein add(Duration(days: ...))).
String shiftDayString(String date, int delta) {
  try {
    final parts = date.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    final next = DateTime(y, m, d + delta);
    final yy = next.year.toString().padLeft(4, '0');
    final mm = next.month.toString().padLeft(2, '0');
    final dd = next.day.toString().padLeft(2, '0');
    return '$yy-$mm-$dd';
  } catch (_) {
    return date;
  }
}

/// Ermittelt den Unix-Sekunden-Startzeitpunkt (00:00 Uhr lokal) für ein ISO-Datum 'YYYY-MM-DD'.
int dayStartTimestampSec(String date) {
  try {
    final parts = date.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    return DateTime(y, m, d).millisecondsSinceEpoch ~/ 1000;
  } catch (_) {
    return 0;
  }
}

/// Kompakte Karte für den Gesundheit-Tab oder Home-Screen.
class TaktStressCard extends StatelessWidget {
  const TaktStressCard({super.key, required this.analysis, this.onTap});

  final DayStressAnalysis analysis;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final de = Localizations.localeOf(c).languageCode == 'de';
    final hasData = analysis.hasData && analysis.avgStress != null;
    final avg = analysis.avgStress ?? 0.0;
    final latest = analysis.latestAwakeSample;
    final latestScore = latest?.score;
    // Die große Zahl ist der Stand jetzt. Der Tagesdurchschnitt war es vorher
    // und wirkte höher oder niedriger als das, was gerade ist (Gerätetest 0.5.1).
    // Ohne aktuellen Messwert (gerade Sport) bleibt der Durchschnitt groß.
    final showsNow = latestScore != null;
    final shown = latestScore ?? avg;
    final shownColor = stressZoneColor(shown, p);

    return Surface(
      key: const ValueKey('takt-stress-card'),
      onTap:
          onTap ??
          () => Navigator.of(c).push(
            MaterialPageRoute(
              builder: (_) => TaktLook(
                child: TaktStressDetailScreen(initialDate: analysis.date),
              ),
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.brain, size: 16, color: p.ink2),
              const SizedBox(width: S.x2),
              Expanded(
                child: Text(
                  de ? 'TAGES-STRESS' : 'DAYTIME STRESS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: F.cap.copyWith(
                    color: p.ink2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: S.x2),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: S.x2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: shownColor.withValues(alpha: 0.15),
                    borderRadius: R.rPill,
                    border: Border.all(
                      color: shownColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    stressZoneLabel(shown, de).toUpperCase(),
                    style: F.over.copyWith(
                      color: shownColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: S.x1),
              Icon(LucideIcons.chevronRight, size: 16, color: p.ink3),
            ],
          ),
          const SizedBox(height: S.x2),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: S.x2),
              child: StripeDodge(
                line: true,
                child: Text(
                  de
                      ? 'Noch keine Stressdaten für diesen Tag vorhanden.'
                      : 'No daytime stress data recorded for this day yet.',
                  style: F.cap.copyWith(color: p.ink3),
                ),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StripeDodge(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                displayFixed(shown, 1),
                                key: const ValueKey('takt-stress-card-score'),
                                style: Pult.digits(36, shownColor),
                              ),
                              const SizedBox(width: 4),
                              StripeDodge(
                                line: true,
                                child: Text(
                                  de ? '/ 3,0' : '/ 3.0',
                                  style: F.body.copyWith(
                                    color: p.ink3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        showsNow
                            ? (de ? 'Aktuell' : 'Now')
                            : (de ? 'Tagesdurchschnitt' : 'Daily average'),
                        key: const ValueKey('takt-stress-card-latest'),
                        style: F.over.copyWith(color: p.ink3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: S.x2),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showsNow)
                        StripeDodge(
                          line: true,
                          align: 1,
                          child: Text(
                            'Ø ${displayFixed(avg, 1)}',
                            style: F.cap.copyWith(color: p.ink2),
                          ),
                        ),
                      if (analysis.peakStress != null)
                        StripeDodge(
                          line: true,
                          align: 1,
                          child: Text(
                            '${de ? 'Spitze' : 'Peak'} ${displayFixed(analysis.peakStress!, 1)}',
                            style: F.cap.copyWith(color: p.ink2),
                          ),
                        ),
                      StripeDodge(
                        line: true,
                        align: 1,
                        child: Text(
                          '${analysis.awakeDataMin ~/ 60}h ${analysis.awakeDataMin % 60}m ${de ? 'gemessen' : 'recorded'}',
                          textAlign: TextAlign.end,
                          style: F.over.copyWith(color: p.ink3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: S.x2),
            SizedBox(
              height: 36,
              child: _StressMiniCurve(
                date: analysis.date,
                samples: analysis.samples,
                p: p,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mini-Kurve für die Kachel.
class _StressMiniCurve extends StatelessWidget {
  const _StressMiniCurve({
    required this.date,
    required this.samples,
    required this.p,
  });

  final String date;
  final List<DayStressSample> samples;
  final P p;

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) return const SizedBox();
    return CustomPaint(
      size: Size.infinite,
      painter: _StressChartPainter(
        dayStartSec: dayStartTimestampSec(date),
        samples: samples,
        p: p,
        showZones: false,
      ),
    );
  }
}

/// Vollbild-Detailansicht des Stress-Tagesverlaufs.
class TaktStressDetailScreen extends StatefulWidget {
  const TaktStressDetailScreen({
    super.key,
    this.initialDate,
    this.injectedAnalysis,
  });

  final String? initialDate;
  final DayStressAnalysis? injectedAnalysis;

  @override
  State<TaktStressDetailScreen> createState() => _TaktStressDetailScreenState();
}

class _TaktStressDetailScreenState extends State<TaktStressDetailScreen> {
  late String _date;
  DayStressAnalysis? _analysis;
  bool _loading = true;
  DayStressSample? _scrubbedSample;
  int _loadGen = 0; // G21: Race condition guard

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? todayLabel();
    if (widget.injectedAnalysis != null) {
      _analysis = widget.injectedAnalysis;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final gen = ++_loadGen;
    setState(() => _loading = true);
    final repo = context.read<AppState>().repo;
    if (repo == null) {
      if (mounted && gen == _loadGen) setState(() => _loading = false);
      return;
    }
    final res = await DayStressCalculator.loadForDay(repo, _date);
    if (mounted && gen == _loadGen) {
      setState(() {
        _analysis = res;
        _loading = false;
        _scrubbedSample = null;
      });
    }
  }

  void _shiftDay(int delta) {
    final nextDate = shiftDayString(_date, delta);
    final today = todayLabel();
    if (delta > 0 && _date == today) return;
    if (nextDate.compareTo(today) > 0) return;
    setState(() => _date = nextDate);
    _load();
  }

  String _formatHhmm(int sec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _durStr(int min, bool de) {
    final h = min ~/ 60;
    final m = min % 60;
    if (h > 0) return '${h}h ${m}m';
    return '$m min';
  }

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final de = Localizations.localeOf(c).languageCode == 'de';
    final a = _analysis ?? DayStressAnalysis.empty(_date);
    final isToday = _date == todayLabel();
    final dispSample = _scrubbedSample;
    final dispScore = dispSample != null ? dispSample.score : a.avgStress;
    final zoneColor = stressZoneColor(dispScore, p);
    final dayStart = dayStartTimestampSec(_date);

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(S.x4, 0, S.x4, S.x10),
          children: [
            TaktHeader(de ? 'tages-stress' : 'daytime stress', back: true),
            const SizedBox(height: S.x2),

            // Datums-Leiste mit StripeDodge für Ziffern (G29)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Pressable(
                  onTap: () => _shiftDay(-1),
                  child: Padding(
                    padding: const EdgeInsets.all(S.x2),
                    child: Icon(
                      LucideIcons.chevronLeft,
                      size: 20,
                      color: p.ink,
                    ),
                  ),
                ),
                StripeDodge(
                  line: true,
                  child: Text(
                    isToday ? (de ? 'Heute' : 'Today') : _date,
                    style: F.body.copyWith(
                      color: p.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Pressable(
                  onTap: isToday ? null : () => _shiftDay(1),
                  child: Padding(
                    padding: const EdgeInsets.all(S.x2),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: isToday ? p.ink3 : p.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: S.x3),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: S.x10),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (a.hasError)
              StatusCard(
                de ? 'Fehler beim Laden' : 'Error loading data',
                de
                    ? 'Die Stressdaten für diesen Tag konnten nicht geladen werden.'
                    : 'Could not load daytime stress data for this calendar day.',
                icon: LucideIcons.circleAlert,
                fix: de ? 'Erneut versuchen' : 'Retry',
                onFix: _load,
              )
            else if (!a.hasData)
              StatusCard(
                de ? 'Keine Daten' : 'No data recorded',
                de
                    ? 'Für diesen Tag liegen noch keine Herzfrequenzdaten vor.'
                    : 'No heart rate data found for this calendar day.',
                icon: LucideIcons.brain,
              )
            else ...[
              // Hero Card
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dispSample != null
                                ? '${de ? 'ZEITPUNKT' : 'AT'} ${_formatHhmm(dispSample.timestampSec)}'
                                : (de ? 'TAGESDURCHSCHNITT' : 'DAY AVERAGE'),
                            style: F.cap.copyWith(
                              color: p.ink2,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: S.x2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: S.x2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: zoneColor.withValues(alpha: 0.15),
                            borderRadius: R.rPill,
                            border: Border.all(
                              color: zoneColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            dispSample?.isActivity == true
                                ? (dispSample?.activityName ??
                                          (de ? 'SPORT' : 'ACTIVITY'))
                                      .toUpperCase()
                                : stressZoneLabel(dispScore, de).toUpperCase(),
                            style: F.over.copyWith(
                              color: zoneColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: S.x3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        StripeDodge(
                          child: Text(
                            dispScore != null
                                ? displayFixed(dispScore, 1)
                                : '—',
                            style: Pult.digits(44, p.ink),
                          ),
                        ),
                        const SizedBox(width: 6),
                        StripeDodge(
                          line: true,
                          child: Text(
                            de ? '/ 3,0' : '/ 3.0',
                            style: F.body.copyWith(color: p.ink3),
                          ),
                        ),
                        const Spacer(),
                        if (dispSample != null) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              StripeDodge(
                                line: true,
                                align: 1,
                                child: Text(
                                  '${dispSample.hr.round()} bpm',
                                  style: F.body.copyWith(
                                    color: p.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (dispSample.rmssd != null)
                                StripeDodge(
                                  line: true,
                                  align: 1,
                                  child: Text(
                                    '${dispSample.rmssd!.round()} ms HRV',
                                    style: F.over.copyWith(color: p.ink3),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: S.x3),

              // Interaktiver 24h-Chart
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.chartLine, size: 16, color: p.ink2),
                        const SizedBox(width: S.x2),
                        Expanded(
                          child: StripeDodge(
                            line: true,
                            child: Text(
                              de ? '24-STUNDEN-VERLAUF' : '24-HOUR TIMELINE',
                              style: F.cap.copyWith(
                                color: p.ink2,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: S.x2),
                        Text(
                          de ? 'Wischen zum Prüfen' : 'Swipe to scrub',
                          style: F.over.copyWith(color: p.ink3),
                        ),
                      ],
                    ),
                    const SizedBox(height: S.x3),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        return SizedBox(
                          height: 180,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (details) {
                              _updateScrub(
                                details.localPosition.dx,
                                width,
                                a.samples,
                                dayStart,
                              );
                            },
                            onHorizontalDragEnd: (_) {
                              setState(() => _scrubbedSample = null);
                            },
                            onTapUp: (details) {
                              _updateScrub(
                                details.localPosition.dx,
                                width,
                                a.samples,
                                dayStart,
                              );
                            },
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: _StressChartPainter(
                                dayStartSec: dayStart,
                                samples: a.samples,
                                p: p,
                                showZones: true,
                                scrubbedSample: dispSample,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: S.x2),
                    // Zeit-Achsenbeschriftung mit StripeDodge geschützt (G29, G30)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 320,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StripeDodge(
                              line: true,
                              child: Text(
                                '00:00',
                                style: F.over.copyWith(color: p.ink3),
                              ),
                            ),
                            StripeDodge(
                              line: true,
                              child: Text(
                                '06:00',
                                style: F.over.copyWith(color: p.ink3),
                              ),
                            ),
                            StripeDodge(
                              line: true,
                              child: Text(
                                '12:00',
                                style: F.over.copyWith(color: p.ink3),
                              ),
                            ),
                            StripeDodge(
                              line: true,
                              child: Text(
                                '18:00',
                                style: F.over.copyWith(color: p.ink3),
                              ),
                            ),
                            StripeDodge(
                              line: true,
                              child: Text(
                                '24:00',
                                style: F.over.copyWith(color: p.ink3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: S.x3),

              // Zonen-Verteilung
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      de ? 'ZEIT IN STRESSZONEN' : 'TIME IN STRESS ZONES',
                      style: F.cap.copyWith(
                        color: p.ink2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: S.x3),
                    _buildZoneRow(
                      color: p.on(C.teal),
                      label: de
                          ? 'Niedriger Stress (0,0 – 1,0)'
                          : 'Low stress (0.0 – 1.0)',
                      duration: _durStr(a.lowStressMin, de),
                      pct: (a.lowPct * 100).round(),
                      p: p,
                    ),
                    const SizedBox(height: S.x2),
                    _buildZoneRow(
                      color: Pult.orangeFor(p.dark),
                      label: de
                          ? 'Moderater Stress (1,0 – 2,0)'
                          : 'Medium stress (1.0 – 2.0)',
                      duration: _durStr(a.mediumStressMin, de),
                      pct: (a.mediumPct * 100).round(),
                      p: p,
                    ),
                    const SizedBox(height: S.x2),
                    _buildZoneRow(
                      color: p.on(C.red),
                      label: de
                          ? 'Hoher Stress (2,0 – 3,0)'
                          : 'High stress (2.0 – 3.0)',
                      duration: _durStr(a.highStressMin, de),
                      pct: (a.highPct * 100).round(),
                      p: p,
                    ),
                    if (a.activityMin > 0) ...[
                      const SizedBox(height: S.x2),
                      _buildZoneRow(
                        color: p.on(C.blue),
                        label: de
                            ? 'Aktivität & Training'
                            : 'Activity & workout',
                        duration: _durStr(a.activityMin, de),
                        pct: null,
                        p: p,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: S.x3),

              // Info Card
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.info, size: 16, color: p.ink3),
                        const SizedBox(width: S.x2),
                        Text(
                          de
                              ? 'WIE STRESS GEMESSEN WIRD'
                              : 'HOW STRESS IS MEASURED',
                          style: F.cap.copyWith(
                            color: p.ink2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: S.x2),
                    Text(
                      de
                          ? 'Der Stress Monitor vergleicht deine Herzfrequenz und Herzratenvariabilität (HRV) im Wachzustand mit deinen persönlichen Ruhewerten. Workouts und Trainings werden automatisch als körperliche Aktivität separiert, damit Sport nicht fälschlich als mentaler Stress bewertet wird.\n\nEigene Näherung aus Herzfrequenz und HRV, kein klinischer Befund.'
                          : 'The stress monitor continuously tracks heart rate and HRV relative to your resting baseline. Exercise and workouts are automatically isolated as physical activity so training strain is not confused with autonomic stress.\n\nApproximation based on heart rate and HRV, not a clinical measurement.',
                      style: F.cap.copyWith(color: p.ink2, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateScrub(
    double dx,
    double width,
    List<DayStressSample> samples,
    int dayStartSec,
  ) {
    if (samples.isEmpty || width <= 0) return;
    final frac = (dx / width).clamp(0.0, 1.0);
    final targetSec = dayStartSec + (frac * 86400).round();

    DayStressSample? closest;
    var minDiff = 1 << 30;
    for (final s in samples) {
      final diff = (s.timestampSec - targetSec).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = s;
      }
    }

    if (closest != null && minDiff <= 3600) {
      setState(() => _scrubbedSample = closest);
    } else {
      setState(() => _scrubbedSample = null);
    }
  }

  Widget _buildZoneRow({
    required Color color,
    required String label,
    required String duration,
    required int? pct,
    required P p,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: S.x2),
        Expanded(
          child: StripeDodge(
            line: true,
            child: Text(label, style: F.cap.copyWith(color: p.ink)),
          ),
        ),
        StripeDodge(
          child: Text(
            duration,
            style: F.cap.copyWith(color: p.ink, fontWeight: FontWeight.w700),
          ),
        ),
        if (pct != null) ...[
          const SizedBox(width: S.x2),
          SizedBox(
            width: 36,
            child: StripeDodge(
              line: true,
              align: 1,
              child: Text('$pct%', style: F.over.copyWith(color: p.ink3)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom Painter für die Stress-Kurve.
class _StressChartPainter extends CustomPainter {
  _StressChartPainter({
    required this.dayStartSec,
    required this.samples,
    required this.p,
    this.showZones = true,
    this.scrubbedSample,
  });

  final int dayStartSec;
  final List<DayStressSample> samples;
  final P p;
  final bool showZones;
  final DayStressSample? scrubbedSample;

  double _xForSec(int tSec, double w) {
    return ((tSec - dayStartSec) / 86400.0).clamp(0.0, 1.0) * w;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final h = size.height;
    final w = size.width;

    // Horizontale Zonenlinien (bei Stress = 1,0 und 2,0)
    final yZone1 = h - (1.0 / 3.0) * h;
    final yZone2 = h - (2.0 / 3.0) * h;

    final linePaint = Paint()
      ..color = p.line.withValues(alpha: showZones ? 0.6 : 0.35)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, yZone1), Offset(w, yZone1), linePaint);
    canvas.drawLine(Offset(0, yZone2), Offset(w, yZone2), linePaint);

    // 1. Physische Aktivitäten als farbige Hintergrund-Balken zeichnen (G13)
    final activityPaint = Paint()
      ..color = p.on(C.blue).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    for (final s in samples) {
      if (s.isActivity) {
        final xLeft = _xForSec(s.timestampSec - 150, w);
        final xRight = _xForSec(s.timestampSec + 150, w);
        canvas.drawRect(Rect.fromLTRB(xLeft, 0, xRight, h), activityPaint);
      }
    }

    // 2. Stress-Kurve: Nur Segmente mit gültigem Score und Abstand <= 10 Min (G19)
    final strokePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.45, 0.85],
        colors: [p.on(C.red), Pult.orangeFor(p.dark), p.on(C.teal)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.5, 0.85, 1.0],
        colors: [
          p.on(C.red).withValues(alpha: 0.28),
          Pult.orangeFor(p.dark).withValues(alpha: 0.18),
          p.on(C.teal).withValues(alpha: 0.10),
          p.on(C.teal).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    Path? curStrokePath;
    Path? curFillPath;
    double? curSegStartX;
    double? curSegLastX;
    DayStressSample? prevSample;

    void flushSegment() {
      if (curStrokePath != null &&
          curFillPath != null &&
          curSegStartX != null &&
          curSegLastX != null) {
        canvas.drawPath(curStrokePath!, strokePaint);
        curFillPath!.lineTo(curSegLastX!, h);
        curFillPath!.lineTo(curSegStartX!, h);
        curFillPath!.close();
        canvas.drawPath(curFillPath!, fillPaint);
      }
      curStrokePath = null;
      curFillPath = null;
      curSegStartX = null;
      curSegLastX = null;
    }

    for (final s in samples) {
      if (s.score == null) {
        flushSegment();
        prevSample = null;
        continue;
      }

      final x = _xForSec(s.timestampSec, w);
      final y = h - (s.score! / 3.0).clamp(0.0, 1.0) * h;

      if (prevSample == null ||
          (s.timestampSec - prevSample.timestampSec) > 600) {
        flushSegment();
        curStrokePath = Path()..moveTo(x, y);
        curFillPath = Path()..moveTo(x, y);
        curSegStartX = x;
        curSegLastX = x;
      } else {
        curStrokePath!.lineTo(x, y);
        curFillPath!.lineTo(x, y);
        curSegLastX = x;
      }
      prevSample = s;
    }
    flushSegment();

    // 3. Scrubbing-Fadenkreuz
    if (scrubbedSample != null) {
      final sx = _xForSec(scrubbedSample!.timestampSec, w);
      final sScore = scrubbedSample!.score;
      final sy = sScore != null
          ? (h - (sScore / 3.0).clamp(0.0, 1.0) * h)
          : (h / 2);

      final guidePaint = Paint()
        ..color = p.ink.withValues(alpha: 0.6)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(sx, 0), Offset(sx, h), guidePaint);

      final dotPaint = Paint()
        ..color = stressZoneColor(sScore, p)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(sx, sy), 5, dotPaint);

      final borderPaint = Paint()
        ..color = p.bg
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(sx, sy), 5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StressChartPainter old) {
    return old.samples != samples ||
        old.scrubbedSample != scrubbedSample ||
        old.dayStartSec != dayStartSec ||
        old.p != p;
  }
}
