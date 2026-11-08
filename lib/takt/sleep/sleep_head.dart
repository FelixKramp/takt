// Feature 03, Board A+: der Takt-Kopf des Schlaf-Tabs. Zifferblatt mit Score,
// die drei Teile, sieben Nächte, dann Dauer und Bedarf, Regelmäßigkeit und
// Effizienz. Ring, Balken und markierte Nacht tragen die Farbe der Stufe
// (C12). Jede Zahl steht in einem StripeDodge (C13, Regel B5).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../state/clock_format.dart';
import '../../ui2/ui2.dart';
import '../pult_tokens.dart';
import '../stripe/stripe.dart';
import '../today/dial_ring.dart';
import 'sleep_score.dart';
import 'sleep_tab_data.dart';
import 'sleep_text.dart';

String hm(num min) {
  final m = min.round();
  return '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
}

class TaktSleepHead extends StatelessWidget {
  const TaktSleepHead({super.key, required this.view});
  final TaktSleepView view;

  @override
  Widget build(BuildContext c) {
    final t = SleepText.of(c);
    final p = P.of(c);
    if (!view.hasNight) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Card(child: Text(t.noNight, style: F.body.copyWith(color: p.ink))),
        if (view.bedRecTonight != null && view.wakeRecTonight != null) ...[
          const SizedBox(height: S.x3),
          StripeDodge(
            line: true,
            child: Text(
                t.tonight(formatClockMinute(view.bedRecTonight!), formatClockMinute(view.wakeRecTonight!)),
                style: F.cap.copyWith(color: p.ink2)),
          ),
        ],
      ]);
    }
    final band = view.score.band;
    final accent = band?.fill ?? p.ink3;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _ScoreCard(view: view, accent: accent),
      const SizedBox(height: S.x3),
      _NightsCard(view: view, accent: accent),
      _Title(t.durationNeed),
      _NeedCard(view: view, accent: accent),
      _Title(t.regularityPart),
      _RegularityCard(view: view, accent: accent),
      _Title(t.efficiencyPart),
      _EfficiencyCard(view: view, accent: accent),
    ]);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Container(
      padding: const EdgeInsets.all(S.x4),
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
      child: child,
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext c) => Padding(
        padding: const EdgeInsets.fromLTRB(S.x1, S.x5, S.x1, S.x2),
        child: Text(text, style: F.head.copyWith(color: P.of(c).ink, fontWeight: FontWeight.w600)),
      );
}

class _Bar extends StatelessWidget {
  const _Bar(this.frac, this.color, {this.height = 8});
  final double frac;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Container(
      height: height,
      decoration: BoxDecoration(color: p.bg, borderRadius: R.rSm),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: frac.clamp(0.0, 1.0),
        child: Container(decoration: BoxDecoration(color: color, borderRadius: R.rSm)),
      ),
    );
  }
}

Widget _digits(String s, double size, Color color, {double align = 0}) =>
    StripeDodge(align: align, child: Text(s, style: Pult.digits(size, color)));

// ── Kopf: Zifferblatt, Stufe, Zeiten, drei Teile ───────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.view, required this.accent});
  final TaktSleepView view;
  final Color accent;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = SleepText.of(c);
    final s = view.score;
    final band = s.band;
    final from = view.onsetTs == null
        ? null
        : formatClockOf(DateTime.fromMillisecondsSinceEpoch(view.onsetTs! * 1000));
    final to = view.wakeTs == null
        ? null
        : formatClockOf(DateTime.fromMillisecondsSinceEpoch(view.wakeTs! * 1000));
    const dial = 148.0;
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          SizedBox(
            width: dial,
            height: dial,
            child: CustomPaint(
              painter: DialPainter(
                lit: dialLitTicks(s.score == null ? null : s.score! / 100),
                litColor: accent,
                track: p.track,
                knob: p.card,
                line: p.line,
              ),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _digits(s.score?.toString() ?? '–', 48, p.ink, align: 0.5),
                  const SizedBox(height: S.x1),
                  StripeDodge(
                    align: 0.5,
                    child: Text(t.of100, style: F.over.copyWith(color: p.ink3)),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(width: S.x4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (band != null)
                Text(band.word(t.de),
                    style: F.t2.copyWith(color: band.ink(p.dark), fontWeight: FontWeight.w600)),
              const SizedBox(height: S.x1),
              StripeDodge(
                line: true,
                child: Text(t.slept(hm(view.sleptMin!)), style: F.body.copyWith(color: p.ink)),
              ),
              if (from != null && to != null)
                StripeDodge(
                  line: true,
                  child: Text(t.window(from, to), style: F.cap.copyWith(color: p.ink2)),
                ),
            ]),
          ),
        ]),
        if (s.reason == NoScore.noNeed) ...[
          const SizedBox(height: S.x3),
          Text(t.noNeed, style: F.cap.copyWith(color: p.ink2)),
        ],
        if (s.score != null) ...[
          const SizedBox(height: S.x4),
          _Part(t.durationPart,
              view.needMin == null ? '' : t.durationOf(hm(view.sleptMin!), hm(view.needMin!)),
              s.duration, accent),
          _Part(t.efficiencyPart, view.effPct == null ? '' : '${view.effPct!.round()} %',
              s.efficiency, accent),
          _Part(t.regularityPart, '', s.regularity, accent),
          const SizedBox(height: S.x1),
          Text(t.weights, style: F.cap.copyWith(color: p.ink3)),
        ],
      ]),
    );
  }
}

class _Part extends StatelessWidget {
  const _Part(this.label, this.detail, this.value, this.accent);
  final String label, detail;
  final double? value;
  final Color accent;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = SleepText.of(c);
    return Padding(
      padding: const EdgeInsets.only(bottom: S.x3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(label, style: F.cap.copyWith(color: p.ink, fontWeight: FontWeight.w600)),
          const SizedBox(width: S.x2),
          Expanded(
            child: StripeDodge(
              line: true,
              child: Text(value == null ? t.notEnoughNights : detail,
                  textAlign: TextAlign.end, style: F.cap.copyWith(color: p.ink2)),
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: S.x2),
            _digits('${value!.round()}', 16, p.ink, align: 1),
          ],
        ]),
        const SizedBox(height: S.x1),
        _Bar((value ?? 0) / 100, accent),
      ]),
    );
  }
}

// ── Sieben Nächte ──────────────────────────────────────────────────────────

class _NightsCard extends StatelessWidget {
  const _NightsCard({required this.view, required this.accent});
  final TaktSleepView view;
  final Color accent;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = SleepText.of(c);
    const maxH = 80.0;
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        StripeDodge(
          line: true,
          child: Text(t.lastSeven, style: F.cap.copyWith(color: p.ink, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: S.x3),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < view.nights.length; i++) ...[
            if (i > 0) const SizedBox(width: S.x2),
            Expanded(
              child: _NightColumn(
                night: view.nights[i],
                last: i == view.nights.length - 1,
                accent: accent,
                maxH: maxH,
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class _NightColumn extends StatelessWidget {
  const _NightColumn({required this.night, required this.last, required this.accent, required this.maxH});
  final NightBar night;
  final bool last;
  final Color accent;
  final double maxH;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = SleepText.of(c);
    final wd = t.weekdays[DateTime.parse(night.day).weekday - 1];
    final s = night.score;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (s == null) ...[
        Text('–', key: ValueKey('night-gap-${night.day}'), style: Pult.digits(13, p.ink3)),
        const SizedBox(height: S.x1),
        Container(height: 2, color: p.line),
      ] else ...[
        _digits('$s', 13, last ? p.ink : p.ink2, align: 0.5),
        const SizedBox(height: S.x1),
        Container(
          height: math.max(2.0, maxH * s / 100),
          decoration: BoxDecoration(color: last ? accent : p.track, borderRadius: R.rSm),
        ),
      ],
      const SizedBox(height: S.x1),
      Text(wd,
          style: F.over.copyWith(
              color: last ? p.ink : p.ink3, fontWeight: last ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }
}

// ── Dauer und Bedarf ───────────────────────────────────────────────────────

class _NeedCard extends StatelessWidget {
  const _NeedCard({required this.view, required this.accent});
  final TaktSleepView view;
  final Color accent;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = SleepText.of(c);
    final need = view.needMin;
    final parts = view.needParts;
    Widget row(String label, String value, {double size = 20}) => Row(children: [
          Expanded(child: Text(label, style: F.cap.copyWith(color: p.ink2))),
          _digits(value, size, p.ink, align: 1),
        ]);
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        row(t.sleptLabel, hm(view.sleptMin!)),
        const SizedBox(height: S.x2),
        _Bar(need == null ? 0 : view.sleptMin! / need, accent, height: 14),
        const SizedBox(height: S.x2),
        _Bar(need == null ? 0 : 1, p.track, height: 14),
        const SizedBox(height: S.x2),
        row(t.needLabel, need == null ? '–' : hm(need)),
        const SizedBox(height: S.x3),
        if (parts == null)
          Text(t.partsTomorrow, style: F.cap.copyWith(color: p.ink3))
        else
          Container(
            padding: const EdgeInsets.all(S.x3),
            decoration: BoxDecoration(color: p.bg, borderRadius: R.rSm),
            child: Column(children: [
              if (parts.baseMin != null) row(t.base, hm(parts.baseMin!), size: 15),
              if ((parts.strainMin ?? 0) > 0) ...[
                const SizedBox(height: S.x2),
                row(t.strain, '+${hm(parts.strainMin!)}', size: 15),
              ],
              if ((parts.debtMin ?? 0) > 0) ...[
                const SizedBox(height: S.x2),
                row(t.debt, '+${hm(parts.debtMin!)}', size: 15),
              ],
              if ((parts.napMin ?? 0) > 0) ...[
                const SizedBox(height: S.x2),
                row(t.naps, '−${hm(parts.napMin!)}', size: 15),
              ],
            ]),
          ),
      ]),
    );
  }
}

// ── Regelmäßigkeit ─────────────────────────────────────────────────────────

/// Achse von 20:00 bis 10:00 des Folgetags, in Minuten ab 20:00.
const _axisMin = 14 * 60;

class _RegularityCard extends StatelessWidget {
  const _RegularityCard({required this.view, required this.accent});
  final TaktSleepView view;
  final Color accent;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = SleepText.of(c);
    const h = 200.0;
    final from = view.onsetTs == null
        ? null
        : formatClockOf(DateTime.fromMillisecondsSinceEpoch(view.onsetTs! * 1000));
    final to = view.wakeTs == null
        ? null
        : formatClockOf(DateTime.fromMillisecondsSinceEpoch(view.wakeTs! * 1000));
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _digits(view.regularity?.toString() ?? '–', 30, p.ink),
          const SizedBox(width: S.x3),
          Expanded(
            child: Text(t.recLegend, textAlign: TextAlign.end, style: F.cap.copyWith(color: p.ink2)),
          ),
        ]),
        const SizedBox(height: S.x3),
        SizedBox(
          height: h,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 44,
              child: Stack(children: [
                for (final (i, label) in const ['20:00', '00:00', '04:00', '08:00'].indexed)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: (i * 240 / _axisMin * h - 7).clamp(0.0, h - 14),
                    child: StripeDodge(
                      line: true,
                      child: Text(formatClockMinute([1200, 0, 240, 480][i]),
                          semanticsLabel: label, style: F.over.copyWith(color: p.ink3)),
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: S.x2),
            Expanded(
              child: CustomPaint(
                key: const ValueKey('regularity-chart'),
                painter: _WeekPainter(
                  week: view.week,
                  accent: accent,
                  bar: p.track,
                  rec: p.ink3,
                  grid: p.line,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: S.x1),
        Row(children: [
          const SizedBox(width: 44 + S.x2),
          for (final (i, w) in view.week.indexed)
            Expanded(
              child: Text(t.weekdays[DateTime.parse(w.day).weekday - 1],
                  textAlign: TextAlign.center,
                  style: F.over.copyWith(
                      color: i == view.week.length - 1 ? p.ink : p.ink3,
                      fontWeight: i == view.week.length - 1 ? FontWeight.w600 : FontWeight.w400)),
            ),
        ]),
        const SizedBox(height: S.x3),
        if (from != null && to != null)
          StripeDodge(
            line: true,
            child: Text(t.lastNight(t.window(from, to)), style: F.cap.copyWith(color: p.ink2)),
          ),
        if (view.bedRecTonight != null && view.wakeRecTonight != null)
          StripeDodge(
            line: true,
            child: Text(
                t.tonight(formatClockMinute(view.bedRecTonight!), formatClockMinute(view.wakeRecTonight!)),
                style: F.cap.copyWith(color: p.ink2)),
          ),
      ]),
    );
  }
}

class _WeekPainter extends CustomPainter {
  _WeekPainter({required this.week, required this.accent, required this.bar, required this.rec, required this.grid});
  final List<WeekNight> week;
  final Color accent, bar, rec, grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (week.isEmpty) return;
    double y(int m) => (m.clamp(0, _axisMin) / _axisMin) * size.height;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final m in const [0, 240, 480, 720]) {
      canvas.drawLine(Offset(0, y(m)), Offset(size.width, y(m)), gridPaint);
    }
    final col = size.width / week.length;
    final bw = math.min(col * 0.55, 28.0);
    for (final (i, w) in week.indexed) {
      if (w.bed == null || w.wake == null) continue;
      final cx = col * (i + 0.5);
      final r = RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - bw / 2, y(w.bed!), cx + bw / 2, y(w.wake!)),
        const Radius.circular(3),
      );
      canvas.drawRRect(r, Paint()..color = i == week.length - 1 ? accent : bar);
    }
    final dash = Paint()
      ..color = rec
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    void dashed(int? Function(WeekNight) pick) {
      Offset? prev;
      for (final (i, w) in week.indexed) {
        final v = pick(w);
        if (v == null) {
          prev = null;
          continue;
        }
        final a = Offset(col * i, y(v)), b = Offset(col * (i + 1), y(v));
        if (prev != null) _dashLine(canvas, prev, a, dash);
        _dashLine(canvas, a, b, dash);
        prev = b;
      }
    }

    dashed((w) => w.bedRec);
    dashed((w) => w.wakeRec);
  }

  static void _dashLine(Canvas c, Offset a, Offset b, Paint p) {
    final d = (b - a).distance;
    if (d == 0) return;
    final dir = (b - a) / d;
    for (var s = 0.0; s < d; s += 9) {
      c.drawLine(a + dir * s, a + dir * math.min(s + 5, d), p);
    }
  }

  @override
  bool shouldRepaint(_WeekPainter o) =>
      o.week != week || o.accent != accent || o.bar != bar || o.rec != rec;
}

// ── Effizienz ──────────────────────────────────────────────────────────────

class _EfficiencyCard extends StatelessWidget {
  const _EfficiencyCard({required this.view, required this.accent});
  final TaktSleepView view;
  final Color accent;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = SleepText.of(c);
    Widget row(String label, String value) => Row(children: [
          Expanded(child: Text(label, style: F.cap.copyWith(color: p.ink))),
          _digits(value, 16, p.ink, align: 1),
        ]);
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _digits(view.effPct == null ? '–' : '${view.effPct!.round()} %', 30, p.ink),
          const SizedBox(width: S.x3),
          Expanded(
            child: Text(t.effLegend, textAlign: TextAlign.end, style: F.cap.copyWith(color: p.ink2)),
          ),
        ]),
        const SizedBox(height: S.x3),
        row(t.asleep, hm(view.sleptMin!)),
        const SizedBox(height: S.x2),
        SizedBox(
          key: const ValueKey('efficiency-strips'),
          height: 40,
          child: CustomPaint(
            painter: _StripsPainter(
              asleep: view.asleep,
              awake: view.awake,
              accent: accent,
              track: p.bg,
              ink: p.ink,
            ),
          ),
        ),
        const SizedBox(height: S.x2),
        row(t.awake, view.awakeMin == null ? '–' : hm(view.awakeMin!)),
        const SizedBox(height: S.x3),
        Container(height: 1, color: p.line),
        const SizedBox(height: S.x3),
        row(t.wakeEvents, view.awakenings == null ? '–' : '${view.awakenings!.round()}'),
      ]),
    );
  }
}

class _StripsPainter extends CustomPainter {
  _StripsPainter({required this.asleep, required this.awake, required this.accent, required this.track, required this.ink});
  final List<Run> asleep, awake;
  final Color accent, track, ink;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 6.0;
    final h = (size.height - gap) / 2;
    final top = Rect.fromLTWH(0, 0, size.width, h);
    final bottom = Rect.fromLTWH(0, h + gap, size.width, h);
    final bg = Paint()..color = track;
    canvas.drawRRect(RRect.fromRectAndRadius(top, const Radius.circular(3)), bg);
    canvas.drawRRect(RRect.fromRectAndRadius(bottom, const Radius.circular(3)), bg);
    final a = Paint()..color = accent;
    for (final r in asleep) {
      canvas.drawRect(Rect.fromLTRB(r.from * size.width, 0, r.to * size.width, h), a);
    }
    final w = Paint()..color = ink;
    for (final r in awake) {
      final l = r.from * size.width;
      final rr = math.max(r.to * size.width, l + 2);
      canvas.drawRect(Rect.fromLTRB(l, h + gap, rr, size.height), w);
    }
  }

  @override
  bool shouldRepaint(_StripsPainter o) =>
      o.asleep != asleep || o.awake != awake || o.accent != accent || o.track != track;
}
