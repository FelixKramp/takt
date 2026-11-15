// TAKT 14.11.: Belastung & Erholung, die letzten sieben Tage als zwei Linien
// (wie bei WHOOP). Blau die Belastung (Strain 0–21), dazu die Ladung der
// Batterie am Morgen (0–100 %), farbig nach Höhe. Ein Tag, an dem abends
// weniger als 20 % übrig blieben, ist über dem Limit: Wochentag rot, Ring
// unten (D7, wie in der Batterie-Woche).
//
// Alle Zahlen stehen als Widgets in einem StripeDodge (B5), gezeichnet werden
// nur Linien, Punkte und der Tagesrahmen.

import 'package:flutter/material.dart';

import '../../l10n/decimal_text.dart' show displayFixed;
import '../../ui2/grammar.dart' show Surface;
import '../../ui2/theme.dart';
import '../sleep/sleep_score.dart' show ScoreBand;
import '../stripe/stripe.dart';
import '../takt_text.dart';
import 'battery.dart';

/// Farbe der Morgenladung: ab 67 grün, ab 34 gelb, darunter rot.
Color chargeColor(double v, P p) =>
    v >= 67 ? p.on(C.green) : (v >= 34 ? p.on(C.yellow) : p.on(C.red));

class TaktLoadRecoveryWeek extends StatelessWidget {
  const TaktLoadRecoveryWeek({super.key, required this.days, required this.today});

  final List<BatteryDay> days;
  final DateTime today;

  static const _chartH = 176.0;
  static const _padTop = 22.0, _padBottom = 22.0;

  bool _isToday(DateTime d) => d.year == today.year && d.month == today.month && d.day == today.day;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    final blue = p.on(C.blue);
    final red = ScoreBand.knapp.fill;
    final over = [
      for (final d in days)
        if (d.over) t.weekdayShort(d.day),
    ];
    final anyCharge = days.any((d) => d.morning != null);

    return Surface(
      key: const ValueKey('takt-load-recovery'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.loadRecovery, style: F.cap.copyWith(color: p.ink, fontWeight: FontWeight.w600)),
        const SizedBox(height: S.x3),
        LayoutBuilder(builder: (_, box) {
          final w = box.maxWidth;
          final n = days.length;
          final slot = w / n;
          const ph = _chartH - _padTop - _padBottom;
          double x(int i) => slot * (i + .5);
          double yStrain(double s) => _padTop + ph * (1 - (s / 21).clamp(0.0, 1.0));
          double yCharge(double m) => _padTop + ph * (1 - (m / 100).clamp(0.0, 1.0));

          Widget label(int i, double y, String text, Color color, {String? key}) => Positioned(
                left: x(i) - slot / 2,
                width: slot,
                top: y - 9,
                height: 18,
                child: StripeDodge(
                  key: key == null ? null : ValueKey(key),
                  align: .5,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(text,
                        maxLines: 1,
                        style: F.cap.copyWith(color: color, fontWeight: FontWeight.w700)),
                  ),
                ),
              );

          return SizedBox(
            height: _chartH,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LinesPainter(
                    days: days,
                    todayIndex: days.indexWhere((d) => _isToday(d.day)),
                    p: p,
                    blue: blue,
                    padTop: _padTop,
                    padBottom: _padBottom,
                  ),
                ),
              ),
              for (var i = 0; i < n; i++) ...[
                // Ladung über dem Punkt, Belastung darunter: so überdecken sie
                // sich nur, wenn beide fast gleich hoch liegen.
                if (days[i].morning != null)
                  label(i, yCharge(days[i].morning!) - 16, '${days[i].morning!.round()} %',
                      chargeColor(days[i].morning!, p),
                      key: 'takt-lr-charge-$i'),
                if (days[i].strain != null)
                  label(i, yStrain(days[i].strain!) + 16, displayFixed(days[i].strain!, 1), blue,
                      key: 'takt-lr-strain-$i'),
              ],
            ]),
          );
        }),
        const SizedBox(height: S.x2),
        Row(children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Column(children: [
                Text(t.weekdayShort(days[i].day),
                    style: F.cap.copyWith(
                        color: days[i].over ? red : (_isToday(days[i].day) ? p.ink : p.ink3),
                        fontWeight: _isToday(days[i].day) || days[i].over
                            ? FontWeight.w700
                            : FontWeight.w400)),
                StripeDodge(
                  align: .5,
                  child: Text('${days[i].day.day}',
                      style: F.cap.copyWith(color: days[i].over ? red : p.ink3)),
                ),
                const SizedBox(height: 2),
                Container(
                  key: days[i].over ? ValueKey('takt-lr-over-$i') : null,
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: days[i].over ? red : Colors.transparent,
                  ),
                ),
              ]),
            ),
        ]),
        const SizedBox(height: S.x3),
        Wrap(spacing: S.x4, runSpacing: S.x1, children: [
          _Legend(color: blue, text: t.loadLegend),
          _Legend(color: p.on(C.green), text: t.chargeLegend),
        ]),
        const SizedBox(height: S.x2),
        Text(
          !anyCharge
              ? t.loadNoCharge
              : (over.isEmpty ? t.loadNoneOver : t.batteryOver(over.join(', '))),
          style: F.cap.copyWith(
              color: over.isEmpty ? p.ink2 : ScoreBand.knapp.ink(p.dark), height: 1.4),
        ),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: S.x1),
      Text(text, style: F.cap.copyWith(color: p.ink2)),
    ]);
  }
}

class _LinesPainter extends CustomPainter {
  _LinesPainter({
    required this.days,
    required this.todayIndex,
    required this.p,
    required this.blue,
    required this.padTop,
    required this.padBottom,
  });

  final List<BatteryDay> days;
  final int todayIndex;
  final P p;
  final Color blue;
  final double padTop, padBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final n = days.length;
    if (n == 0) return;
    final slot = size.width / n;
    final ph = size.height - padTop - padBottom;
    double x(int i) => slot * (i + .5);
    double yS(double s) => padTop + ph * (1 - (s / 21).clamp(0.0, 1.0));
    double yC(double m) => padTop + ph * (1 - (m / 100).clamp(0.0, 1.0));

    if (todayIndex >= 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(slot * todayIndex + 4, 0, slot - 8, size.height),
          const Radius.circular(8),
        ),
        Paint()..color = p.ink.withValues(alpha: .06),
      );
    }
    final grid = Paint()
      ..color = p.line
      ..strokeWidth = 1;
    for (final f in [0.0, 1 / 3, 2 / 3, 1.0]) {
      final y = padTop + ph * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    void line(double? Function(BatteryDay) v, double Function(double) y, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      Offset? prev;
      for (var i = 0; i < n; i++) {
        final value = v(days[i]);
        if (value == null) {
          prev = null;
          continue;
        }
        final o = Offset(x(i), y(value));
        if (prev != null) canvas.drawLine(prev, o, paint);
        prev = o;
      }
    }

    void dots(double? Function(BatteryDay) v, double Function(double) y, Color Function(double) c) {
      for (var i = 0; i < n; i++) {
        final value = v(days[i]);
        if (value == null) continue;
        final o = Offset(x(i), y(value));
        canvas.drawCircle(o, 5.5, Paint()..color = p.card);
        canvas.drawCircle(
          o,
          5.5,
          Paint()
            ..color = c(value)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }

    line((d) => d.morning, yC, p.ink3);
    line((d) => d.strain, yS, blue);
    dots((d) => d.morning, yC, (v) => chargeColor(v, p));
    dots((d) => d.strain, yS, (_) => blue);
  }

  @override
  bool shouldRepaint(covariant _LinesPainter old) =>
      old.days != days || old.todayIndex != todayIndex || old.p != p;
}
