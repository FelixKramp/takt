// Feature 10: Karte und Detailansicht des Körperalters im Takt-Design
// (K1–K6, Spec: docs/features/10-koerperalter/spec.md).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/decimal_text.dart' show displayFixed;
import '../../ui2/grammar.dart' show Section, Surface;
import '../../ui2/profile/profile.dart' show openProfile;
import '../../ui2/screens/home_screen.dart' show go, pad;
import '../../ui2/theme.dart';
import '../detail/value_card.dart';
import '../header.dart';
import '../look.dart';
import '../pult_tokens.dart';
import '../stripe/stripe.dart';
import '../takt_text.dart';
import 'body_age.dart';

String formatSignedYears(double years, bool de, {bool short = false}) {
  final absVal = years.abs();
  if (absVal < 0.05) {
    final z = de ? '0,0' : '0.0';
    return short ? '±$z ${de ? 'J.' : 'y'}' : (de ? '±$z Jahre' : '±$z years');
  }
  final sign = years < 0 ? '−' : '+';
  final numStr = displayFixed(absVal, 1);
  return short
      ? '$sign$numStr ${de ? 'J.' : 'y'}'
      : (de ? '$sign$numStr Jahre' : '$sign$numStr years');
}

/// Formatiert das Alterungstempo (z.B. „0,85×“ oder „2,10×“).
String formatPaceOfAging(double pace, bool de) {
  final numStr = displayFixed(pace, 2);
  return '$numStr×';
}

/// Kurze Erklärung des Alterungstempos (z.B. „15% langsamer als normal“).
String paceDescription(double pace, bool de) {
  final pct = ((pace - 1.0) * 100).round();
  if (pct.abs() <= 2) {
    return de ? 'Normales Tempo (1:1)' : 'Normal pace (1:1)';
  }
  if (pct < 0) {
    final absPct = pct.abs();
    return de
        ? '$absPct% langsamer als normal'
        : '$absPct% slower than normal';
  } else {
    return de
        ? '$pct% schneller als normal'
        : '$pct% faster than normal';
  }
}

/// Ampelfarbe für das Alterungstempo: grün bei < 0.98, orange bei > 1.02.
Color paceStatusColor(double pace, P p) {
  if (pace < 0.98) return p.on(C.green);
  if (pace > 1.02) return Pult.orangeFor(p.dark);
  return p.ink2;
}

/// Kompakte Karte für das Körperalter oben im Gesundheit-Tab.
/// Tippen öffnet [TaktBodyAgeDetail] (oder das Profil, wenn das Alter fehlt).
class TaktBodyAgeCard extends StatelessWidget {
  const TaktBodyAgeCard({
    super.key,
    required this.snapshot,
    this.onOpenProfile,
  });

  final BodyAgeSnapshot snapshot;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final de = Localizations.localeOf(c).languageCode == 'de';
    final title = de ? 'Körperalter' : 'Body age';
    final t = TaktText.of(c);

    // Randfall Spec: Kein Alter im Profil hinterlegt -> Hinweis mit Weg zum Profil.
    if (!snapshot.hasAge) {
      return TaktLook(
        child: Surface(
          key: const ValueKey('takt-body-age-missing-age'),
          onTap: onOpenProfile ?? () => openProfile(c),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: F.body.copyWith(color: p.ink, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: S.x1),
                  StripeDodge(
                    line: true,
                    child: Text(
                      de
                          ? 'Alter im Profil eintragen, um das Körperalter zu berechnen.'
                          : 'Add your age in Profile to calculate your body age.',
                      style: F.cap.copyWith(color: p.ink2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: S.x2),
            Icon(LucideIcons.chevronRight, size: 18, color: p.ink3),
          ]),
        ),
      );
    }

    // K4: Unter 14 Tagen erscheint „noch X Tage“ statt einer Zahl.
    if (!snapshot.hasEnoughDays) {
      final rem = snapshot.missingDays;
      final waitText = de
          ? (rem == 1 ? 'Noch 1 Tag bis zum Körperalter' : 'Noch $rem Tage bis zum Körperalter')
          : (rem == 1 ? '1 more day needed' : '$rem more days needed');
      return TaktLook(
        child: Surface(
          key: const ValueKey('takt-body-age-calibrating'),
          onTap: () => go(c, TaktLook(child: TaktBodyAgeDetail(snapshot: snapshot))),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: F.body.copyWith(color: p.ink, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: S.x1),
                  StripeDodge(
                    line: true,
                    child: Text(
                      '$waitText (${snapshot.dataDays}/$kBodyAgeMinDays)',
                      style: F.cap.copyWith(color: p.ink2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: S.x2),
            Icon(LucideIcons.chevronRight, size: 18, color: p.ink3),
          ]),
        ),
      );
    }

    // K4: Mindestens ein Faktor braucht einen Messwert, sonst gibt es kein Ergebnis.
    if (!snapshot.hasFactors) {
      return TaktLook(
        child: Surface(
          key: const ValueKey('takt-body-age-no-factors'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: F.body.copyWith(color: p.ink, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: S.x1),
              StripeDodge(
                line: true,
                child: Text(t.bodyAgeNoFactors, style: F.cap.copyWith(color: p.ink2)),
              ),
            ],
          ),
        ),
      );
    }

    // K1: Körperalter mit einer Nachkommastelle und Abweichung zum echten Alter.
    final ageStr = displayFixed(snapshot.bodyAge!, 1);
    final diffStr = formatSignedYears(snapshot.diffYears, de);
    final diffColor = snapshot.diffYears < -0.05
        ? p.on(C.green)
        : snapshot.diffYears > 0.05
            ? Pult.orangeFor(p.dark)
            : p.ink2;
    final prevDelta = snapshot.prevWeekDelta;
    final topFactor = snapshot.topLever;

    return TaktLook(
      child: Surface(
        key: const ValueKey('takt-body-age-card'),
        onTap: () => go(c, TaktLook(child: TaktBodyAgeDetail(snapshot: snapshot))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: F.cap.copyWith(color: p.ink2)),
                      const SizedBox(height: S.x1),
                      StripeDodge(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            ageStr,
                            key: const ValueKey('takt-body-age-value'),
                            style: Pult.digits(40, p.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: S.x3),
                Flexible(
                  flex: 6,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StripeDodge(
                      line: true,
                      align: 1,
                      child: Text(
                        diffStr,
                        key: const ValueKey('takt-body-age-diff'),
                        style: F.body.copyWith(
                          color: diffColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (snapshot.paceOfAging != null) ...[
                      const SizedBox(height: 2),
                      StripeDodge(
                        line: true,
                        align: 1,
                        child: Text(
                          '${de ? 'Tempo' : 'Pace'} ${formatPaceOfAging(snapshot.paceOfAging!, de)}',
                          key: const ValueKey('takt-body-age-pace'),
                          style: F.cap.copyWith(
                            color: paceStatusColor(snapshot.paceOfAging!, p),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (prevDelta != null) ...[
                      const SizedBox(height: 2),
                      StripeDodge(
                        line: true,
                        align: 1,
                        child: Text(
                          de
                              ? '${formatSignedYears(prevDelta, true, short: true)} zur Vorwoche'
                              : '${formatSignedYears(prevDelta, false, short: true)} vs last week',
                          style: F.cap.copyWith(color: p.ink3),
                        ),
                      ),
                    ],
                  ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: S.x3),
            TaktBodyAgeStrip(snapshot: snapshot),
            if (topFactor != null) ...[
              const SizedBox(height: S.x2),
              Divider(color: p.line, height: 1),
              const SizedBox(height: S.x2),
              Row(children: [
                Expanded(
                  child: StripeDodge(
                    line: true,
                    child: Text(
                      de
                          ? 'Größter Hebel: ${topFactor.label(true)} (bis zu ${formatSignedYears(-topFactor.potentialYears, true, short: true)})'
                          : 'Top lever: ${topFactor.label(false)} (up to ${formatSignedYears(-topFactor.potentialYears, false, short: true)})',
                      style: F.cap.copyWith(color: p.ink2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: S.x2),
                Icon(LucideIcons.chevronRight, size: 16, color: p.ink3),
              ]),
            ],
            const SizedBox(height: S.x2),
            Text(
              t.bodyAgeDisclaimer,
              key: const ValueKey('takt-body-age-card-disclaimer'),
              style: F.over.copyWith(color: p.ink3),
            ),
          ],
        ),
      ),
    );
  }
}


/// Detailansicht des Körperalters mit allen sieben Faktoren (K2) und
/// aufklappbarer Studien-Herleitung je Faktor (K3).
class TaktBodyAgeDetail extends StatefulWidget {
  const TaktBodyAgeDetail({super.key, required this.snapshot});

  final BodyAgeSnapshot snapshot;

  @override
  State<TaktBodyAgeDetail> createState() => _TaktBodyAgeDetailState();
}

class _TaktBodyAgeDetailState extends State<TaktBodyAgeDetail> {
  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final de = Localizations.localeOf(c).languageCode == 'de';
    final s = widget.snapshot;
    final t = TaktText.of(c);

    final refAgeStr = s.exactAge != null ? displayFixed(s.exactAge!, 1) : '${s.realAge}';
    final subLines = <String>[
      if (s.ready)
        de
            ? '${formatSignedYears(s.diffYears, true)} gegenüber $refAgeStr Jahren'
            : '${formatSignedYears(s.diffYears, false)} vs age $refAgeStr',
      if (s.ready && s.prevWeekDelta != null)
        de
            ? '${formatSignedYears(s.prevWeekDelta!, true, short: true)} zur Vorwoche'
            : '${formatSignedYears(s.prevWeekDelta!, false, short: true)} vs last week',
      if (s.ready && s.prevWeekDelta == null)
        de ? '30-Tage-Schnitt' : '30-day average',
      if (s.ready) t.bodyAgeWeekNote,
    ];

    final whyNotReady = !s.hasAge
        ? (de
            ? 'Trage dein Alter im Profil ein, um das Körperalter zu berechnen.'
            : 'Add your age in Profile to calculate your body age.')
        : (!s.hasEnoughDays
            ? (de
                ? 'Noch ${s.missingDays} Tage bis zum Körperalter (${s.dataDays}/$kBodyAgeMinDays Tage in den letzten 30 Tagen).'
                : '${s.missingDays} more days needed (${s.dataDays}/$kBodyAgeMinDays days in the last 30 days).')
            : (!s.hasFactors ? t.bodyAgeNoFactors : null));

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
          padding: pad,
          children: [
            TaktHeader(de ? 'körperalter' : 'body age', back: true),
            const SizedBox(height: S.x2),
            TaktValueCard(
              value: s.ready ? displayFixed(s.bodyAge!, 1) : null,
              unit: de ? 'Jahre' : 'years',
              when: subLines.isEmpty ? null : subLines.join('\n'),
              why: whyNotReady,
            ),
            if (s.ready) ...[
              const SizedBox(height: S.x3),
              Surface(
                key: const ValueKey('takt-body-age-corridor-card'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kBodyAgeTargetCorridor
                          ? (de ? 'Zielkorridor & Einstufung' : 'Target corridor & rating')
                          : (de ? 'Einordnung' : 'Position'),
                      style: F.cap.copyWith(
                        color: p.ink2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: S.x3),
                    TaktBodyAgeStrip(snapshot: s),
                  ],
                ),
              ),
            ],
            if (s.ready && s.paceOfAging != null) ...[
              const SizedBox(height: S.x3),
              Surface(
                key: const ValueKey('takt-body-age-pace-card'),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.card2,
                        borderRadius: R.rSm,
                      ),
                      child: Icon(
                        LucideIcons.gauge,
                        size: 20,
                        color: paceStatusColor(s.paceOfAging!, p),
                      ),
                    ),
                    const SizedBox(width: S.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  de ? 'Alterungstempo' : 'Pace of aging',
                                  style: F.body.copyWith(
                                    color: p.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: S.x2),
                              Flexible(
                                child: StripeDodge(
                                  line: true,
                                  align: 1,
                                  child: Text(
                                    formatPaceOfAging(s.paceOfAging!, de),
                                    key: const ValueKey('takt-body-age-detail-pace'),
                                    style: Pult.digits(
                                      22,
                                      paceStatusColor(s.paceOfAging!, p),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          StripeDodge(
                            line: true,
                            child: Text(
                              paceDescription(s.paceOfAging!, de),
                              style: F.cap.copyWith(color: p.ink2),
                            ),
                          ),
                          const SizedBox(height: 2),
                          StripeDodge(
                            line: true,
                            child: Text(
                              t.bodyAgePaceNote,
                              style: F.over.copyWith(color: p.ink3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (s.ready && s.recentDiffYears != null && s.chronologicalAge != null) ...[
              const SizedBox(height: S.x4),
              Surface(
                key: const ValueKey('takt-body-age-recent-total'),
                child: StripeDodge(
                  line: true,
                  child: Text(
                    de
                        ? 'Letzte 7 Tage: Hältst du sie, läge dein Körperalter bei '
                            '${displayFixed(s.chronologicalAge! + s.recentDiffYears!, 1)} '
                            '(30 Tage: ${displayFixed(s.bodyAge!, 1)}).'
                        : 'Last 7 days: if you keep them up, your body age would be '
                            '${displayFixed(s.chronologicalAge! + s.recentDiffYears!, 1)} '
                            '(30 days: ${displayFixed(s.bodyAge!, 1)}).',
                    style: F.cap.copyWith(color: p.ink, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            const SizedBox(height: S.x5),
            Section(
              de ? 'Faktoren (letzte 30 Tage)' : 'Factors (last 30 days)',
              Surface(
                pad: const EdgeInsets.symmetric(horizontal: S.x4),
                child: Column(
                  children: [
                    for (var i = 0; i < s.factors.length; i++) ...[
                      if (i > 0) Divider(color: p.line, height: 1),
                      _FactorRow(
                        factor: s.factors[i],
                        de: de,
                        showYears: s.ready,
                        recent: s.recent[s.factors[i].key],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: S.x4),
            Surface(
              key: const ValueKey('takt-body-age-method'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StripeDodge(
                    line: true,
                    child: Text(
                      t.bodyAgeOwnApprox,
                      key: const ValueKey('takt-body-age-own-approx'),
                      style: F.cap.copyWith(color: p.ink2, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: S.x2),
                  Text(
                    t.bodyAgeDisclaimer,
                    key: const ValueKey('takt-body-age-disclaimer'),
                    style: F.cap.copyWith(color: p.ink2, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grafischer Zielkorridor für einen einzelnen Lebensstil-Faktor (wie _TaktStrip im Schlaf-Tab):
/// Zeigt den optimalen Bereich (Zielband), den Wertebereich und die Position
/// des Nutzers als Dot.
class _FactorCorridorStrip extends StatelessWidget {
  const _FactorCorridorStrip({required this.factor, required this.de, this.recent});

  final BodyAgeFactor factor;
  final bool de;

  /// Zweiter Punkt (hohl) für die letzten sieben Tage.
  final BodyAgeFactor? recent;

  (double lo, double hi, double bandLo, double bandHi) _bounds() {
    switch (factor.key) {
      case 'sleep_duration':
        return (4.5, 10.5, 7.0, 8.0);
      case 'sleep_regularity':
        return (40.0, 100.0, 75.0, 100.0);
      case 'resting_hr':
        return (40.0, 90.0, 40.0, 58.0);
      case 'steps':
        return (1500.0, 12000.0, 8000.0, 10000.0);
      case 'moderate_activity':
        return (0.0, 300.0, 150.0, 300.0);
      case 'intensive_activity':
        return (0.0, 120.0, 45.0, 120.0);
      case 'strength':
        return (0.0, 90.0, 30.0, 60.0);
      default:
        return (0.0, 100.0, 40.0, 60.0);
    }
  }

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final (lo, hi, bandLo, bandHi) = _bounds();
    final span = hi - lo;
    double f(double v) => span <= 0 ? .5 : ((v - lo) / span).clamp(0.0, 1.0);

    final mark = factor.value;
    final hasVal = !factor.absent && mark != null && mark.isFinite;

    final insideOptimal = hasVal && mark >= bandLo && mark <= bandHi;
    final dotColor = insideOptimal
        ? p.on(C.green)
        : (factor.yearsShift > 0.05 ? Pult.orangeFor(p.dark) : p.ink2);

    return LayoutBuilder(
      key: ValueKey('takt-factor-corridor-${factor.key}'),
      builder: (c, box) {
        final w = box.maxWidth;
        final bandLeft = (f(bandLo) * w).toDouble();
        final bandWidth = math.max(6.0, (f(bandHi) - f(bandLo)) * w).toDouble();
        const dot = 14.0;
        final dotLeft = hasVal
            ? (f(mark) * w - dot / 2).clamp(0.0, math.max(0.0, w - dot)).toDouble()
            : 0.0;

        final corridorColor = p.on(C.green).withValues(alpha: 0.22);
        final rv = recent?.value;
        final hasRecent = recent != null && rv != null && rv.isFinite;
        final recentLeft = hasRecent
            ? (f(rv) * w - dot / 2).clamp(0.0, math.max(0.0, w - dot)).toDouble()
            : 0.0;
        final recentColor =
            hasRecent ? _recentColor(p, recent!, factor) : p.ink2;

        return SizedBox(
          height: dot,
          width: w,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 3,
                width: w,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.card2,
                    borderRadius: R.rPill,
                  ),
                ),
              ),
              Positioned(
                left: bandLeft.clamp(0.0, w),
                top: 3,
                width: bandWidth.clamp(0.0, math.max(0.0, w - bandLeft)),
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: corridorColor,
                    borderRadius: R.rPill,
                    border: Border.all(
                      color: p.on(C.green).withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                ),
              ),
              if (hasVal && hasRecent) ...[
                // Verbindung vom 30-Tage-Punkt zum 7-Tage-Punkt: die Richtung.
                Positioned(
                  left: math.min(dotLeft, recentLeft) + dot / 2,
                  top: dot / 2 - 1,
                  width: (dotLeft - recentLeft).abs(),
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: recentColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
              if (hasRecent)
                Positioned(
                  left: recentLeft,
                  top: 0,
                  width: dot,
                  height: dot,
                  child: Container(
                    key: ValueKey('takt-factor-dot-recent-${factor.key}'),
                    decoration: BoxDecoration(
                      color: p.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: recentColor, width: 2.5),
                    ),
                  ),
                ),
              if (hasVal)
                Positioned(
                  left: dotLeft,
                  top: 0,
                  width: dot,
                  height: dot,
                  child: Container(
                    key: ValueKey('takt-factor-dot-${factor.key}'),
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.card, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FactorRow extends StatefulWidget {
  const _FactorRow({
    required this.factor,
    required this.de,
    required this.showYears,
    this.recent,
  });

  final BodyAgeFactor factor;
  final bool de;

  /// Im Kalibrierungszustand (<14 Tage) stehen keine Jahre.
  final bool showYears;

  /// Derselbe Faktor, nur aus den letzten sieben Tagen gerechnet. Er steht als
  /// zweiter Punkt auf demselben Balken, ohne Aufklappen.
  final BodyAgeFactor? recent;

  @override
  State<_FactorRow> createState() => _FactorRowState();
}

class _FactorRowState extends State<_FactorRow> {
  bool _open = false;

  @override
  Widget build(BuildContext c) {
    final factor = widget.factor;
    final de = widget.de;
    final showYears = widget.showYears;
    final recent = widget.recent;
    final p = P.of(c);
    final shiftStr = factor.absent
        ? (de ? '0,0 J.' : '0.0 y')
        : formatSignedYears(factor.yearsShift, de, short: true);
    final shiftColor = factor.absent
        ? p.ink3
        : factor.yearsShift < -0.05
            ? p.on(C.green)
            : factor.yearsShift > 0.05
                ? Pult.orangeFor(p.dark)
                : p.ink2;
    final r = showYears ? recent : null;

    return Padding(
      key: ValueKey('takt-body-age-factor-${factor.key}'),
      padding: const EdgeInsets.symmetric(vertical: S.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            key: ValueKey('takt-body-age-toggle-${factor.key}'),
            behavior: HitTestBehavior.opaque,
            onTap: r == null ? null : () => setState(() => _open = !_open),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        factor.label(de),
                        style: F.body.copyWith(
                          color: p.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      StripeDodge(
                        line: true,
                        child: Text(
                          de
                              ? '${factor.formattedValue(true)} · Ziel: ${factor.target(true)}'
                              : '${factor.formattedValue(false)} · Target: ${factor.target(false)}',
                          style: F.cap.copyWith(color: p.ink2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: S.x2),
                if (showYears)
                  StripeDodge(
                    line: true,
                    align: 1,
                    child: Text(
                      shiftStr,
                      style: F.body.copyWith(
                        color: shiftColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (r != null) ...[
                  const SizedBox(width: S.x1),
                  Icon(
                    _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    key: ValueKey('takt-body-age-chevron-${factor.key}'),
                    size: 18,
                    color: p.ink2,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: S.x2),
          _FactorCorridorStrip(factor: factor, recent: r, de: de),
          if (r != null && _open) ...[
            const SizedBox(height: S.x3),
            Container(
              key: ValueKey('takt-body-age-week-${factor.key}'),
              width: double.infinity,
              padding: const EdgeInsets.all(S.x3),
              decoration: BoxDecoration(color: p.card2, borderRadius: R.rSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    de ? 'Letzte 7 Tage' : 'Last 7 days',
                    style: F.cap.copyWith(color: p.ink2, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: S.x2),
                  _WeekLine(
                    key: ValueKey('takt-body-age-recent-${factor.key}'),
                    filled: false,
                    color: _recentColor(p, r, factor),
                    label: de ? '7 Tage' : '7 days',
                    value: r.formattedValue(de),
                    years: formatSignedYears(r.yearsShift, de, short: true),
                    p: p,
                  ),
                  const SizedBox(height: S.x1),
                  _WeekLine(
                    filled: true,
                    color: shiftColor,
                    label: de ? '30 Tage' : '30 days',
                    value: factor.formattedValue(de),
                    years: shiftStr,
                    p: p,
                  ),
                  const SizedBox(height: S.x1),
                  StripeDodge(
                    line: true,
                    child: Text(
                      de ? 'Ziel: ${factor.target(true)}' : 'Target: ${factor.target(false)}',
                      style: F.over.copyWith(color: p.ink3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showYears && factor.capped) ...[
            const SizedBox(height: S.x1),
            StripeDodge(
              line: true,
              child: Text(
                key: ValueKey('takt-body-age-capped-${factor.key}'),
                de
                    ? 'Begrenzt: Rechnerisch ${formatSignedYears(factor.rawYears, true, short: true)}, angezeigt $shiftStr.'
                    : 'Capped: ${formatSignedYears(factor.rawYears, false, short: true)} by the formula, shown as $shiftStr.',
                style: F.over.copyWith(color: p.ink3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Farbe eines Punktes: grün im Zielbereich-Sinne (weniger Jahre), orange bei mehr.
Color _recentColor(P p, BodyAgeFactor recent, BodyAgeFactor base) {
  final d = recent.yearsShift - base.yearsShift;
  return d < -0.05
      ? p.on(C.green)
      : d > 0.05
          ? Pult.orangeFor(p.dark)
          : p.ink2;
}

/// Eine Zeile im Dropdown: Punkt (voll oder hohl), Zeitraum, Wert, Wirkung in Jahren.
class _WeekLine extends StatelessWidget {
  const _WeekLine({
    super.key,
    required this.filled,
    required this.color,
    required this.label,
    required this.value,
    required this.years,
    required this.p,
  });

  final bool filled;
  final Color color;
  final String label;
  final String value;
  final String years;
  final P p;

  @override
  Widget build(BuildContext c) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: S.x2),
        Expanded(
          child: StripeDodge(
            line: true,
            child: Text('$label · $value', style: F.cap.copyWith(color: p.ink)),
          ),
        ),
        const SizedBox(width: S.x2),
        StripeDodge(
          line: true,
          align: 1,
          child: Text(
            years,
            style: F.cap.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Grafische Leiste für das Körperalter (wie _TaktStrip im Schlaf-Tab):
/// Zeigt den Zielkorridor (Optimaler Bereich), das chronologische Alter
/// als Markierung und das aktuelle Körperalter als Dot.
class TaktBodyAgeStrip extends StatelessWidget {
  const TaktBodyAgeStrip({
    super.key,
    required this.snapshot,
    this.showLabels = true,
  });

  final BodyAgeSnapshot snapshot;
  final bool showLabels;

  @override
  Widget build(BuildContext c) {
    if (!snapshot.ready) return const SizedBox();
    final p = P.of(c);
    final de = Localizations.localeOf(c).languageCode == 'de';

    final chrono = snapshot.chronologicalAge!;
    final body = snapshot.bodyAge!;
    // Zielkorridor nur mit dem Schalter [kBodyAgeTargetCorridor] (Befund 4).
    const corridor = kBodyAgeTargetCorridor;
    final optLo = snapshot.optimalAgeMin;
    final optHi = snapshot.optimalAgeMax;

    final double lo, hi;
    if (corridor) {
      lo = math.min(math.min(body - 1.5, optLo - 1.0), chrono - 6.5);
      hi = math.max(math.max(body + 1.5, chrono + 3.5), optHi + 4.5);
    } else {
      lo = math.min(body, chrono) - 2.5;
      hi = math.max(body, chrono) + 2.5;
    }
    final span = hi - lo;
    double f(double v) => span <= 0 ? .5 : ((v - lo) / span).clamp(0.0, 1.0);

    final diff = body - chrono;
    Color dotColor;
    if (corridor && body <= optHi) {
      dotColor = p.on(C.green);
    } else if (diff < -0.05) {
      dotColor = p.on(C.green);
    } else if (diff > 0.05) {
      dotColor = Pult.orangeFor(p.dark);
    } else {
      dotColor = p.ink2;
    }

    String verdict;
    if (corridor && body <= optHi) {
      final d = diff.abs();
      verdict = de
          ? 'Im optimalen Zielbereich (${displayFixed(d, 1)} Jahre jünger)'
          : 'In optimal target range (${displayFixed(d, 1)} years younger)';
    } else if (corridor && body < chrono) {
      final toOpt = body - optHi;
      verdict = de
          ? '${displayFixed(-diff, 1)} Jahre jünger · Noch ${displayFixed(toOpt, 1)} J. bis zum Optimum'
          : '${displayFixed(-diff, 1)} years younger · ${displayFixed(toOpt, 1)} y to optimal target';
    } else if (corridor && diff >= 0.05) {
      verdict = de
          ? '${displayFixed(diff, 1)} Jahre über deinem Alter · Ziel: ${displayFixed(optLo, 1)}–${displayFixed(optHi, 1)} J.'
          : '${displayFixed(diff, 1)} years above actual age · Target: ${displayFixed(optLo, 1)}–${displayFixed(optHi, 1)} y';
    } else if (diff < -0.05) {
      verdict = de
          ? '${displayFixed(-diff, 1)} Jahre jünger als dein Alter'
          : '${displayFixed(-diff, 1)} years younger than your age';
    } else if (diff > 0.05) {
      verdict = de
          ? '${displayFixed(diff, 1)} Jahre über deinem Alter'
          : '${displayFixed(diff, 1)} years above your age';
    } else {
      verdict = de ? 'So alt wie dein Alter' : 'As old as your age';
    }

    const dotSize = 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabels) ...[
          Row(
            children: [
              if (corridor)
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: p.on(C.green),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: StripeDodge(
                          line: true,
                          child: Text(
                            de
                                ? 'Optimal ${displayFixed(optLo, 1)}–${displayFixed(optHi, 1)} J.'
                                : 'Optimal ${displayFixed(optLo, 1)}–${displayFixed(optHi, 1)} y',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: F.over.copyWith(
                              color: p.on(C.green),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (corridor) const SizedBox(width: S.x2),
              Flexible(
                child: StripeDodge(
                  line: true,
                  align: corridor ? 1 : 0,
                  child: Text(
                    de
                        ? 'Echtes Alter ${displayFixed(chrono, 1)} J.'
                        : 'Actual age ${displayFixed(chrono, 1)} y',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: F.over.copyWith(color: p.ink3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: S.x2),
        ],
        ExcludeSemantics(
          child: LayoutBuilder(
            builder: (c, box) {
              final w = box.maxWidth;
              final leftCorridor = f(optLo) * w;
              final rightCorridor = f(optHi) * w;
              final widthCorridor = math.max(12.0, rightCorridor - leftCorridor);
              final xChrono = (f(chrono) * w).clamp(0.0, w);
              final xBody = (f(body) * w - dotSize / 2).clamp(0.0, w - dotSize);

              return SizedBox(
                height: 22,
                width: w,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Hintergrund-Schiene
                    Positioned(
                      left: 0,
                      top: 5,
                      width: w,
                      height: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: p.card2,
                          borderRadius: R.rPill,
                        ),
                      ),
                    ),
                    // 2. Zielkorridor (Optimaler Bereich), nur mit Schalter
                    if (corridor)
                    Positioned(
                      left: leftCorridor,
                      top: 5,
                      width: widthCorridor,
                      height: 12,
                      child: Container(
                        key: const ValueKey('takt-body-age-corridor'),
                        decoration: BoxDecoration(
                          color: p.on(C.green).withValues(alpha: 0.22),
                          borderRadius: R.rPill,
                          border: Border.all(
                            color: p.on(C.green).withValues(alpha: 0.55),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    // 3. Echtes Alter (Referenz-Linie)
                    Positioned(
                      left: (xChrono - 1.0).clamp(0.0, w - 2.0),
                      top: 1,
                      width: 2,
                      height: 20,
                      child: Container(
                        key: const ValueKey('takt-body-age-chrono-line'),
                        decoration: BoxDecoration(
                          color: p.ink3,
                          borderRadius: R.rPill,
                        ),
                      ),
                    ),
                    // 4. Körperalter-Marker (Dot)
                    Positioned(
                      left: xBody,
                      top: 2,
                      width: dotSize,
                      height: dotSize,
                      child: Container(
                        key: const ValueKey('takt-body-age-dot'),
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.card, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.35),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: S.x2),
        StripeDodge(
          line: true,
          child: Text(
            verdict,
            key: const ValueKey('takt-body-age-verdict'),
            style: F.cap.copyWith(
              color: dotColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}


