// Ein Ring als Drehregler: Teilstriche statt Bogen.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui2/screens/home_screen.dart' show RingView;
import '../../ui2/ui2.dart';
import '../pult_tokens.dart';

const kDialTicks = 48;

/// Wie viele Teilstriche leuchten. Ohne Füllstand bleibt der Ring leer.
int dialLitTicks(double? frac, {int total = kDialTicks}) {
  if (frac == null) return 0;
  return (frac.clamp(0.0, 1.0) * total).round();
}

/// Was in der Mitte steht. Eine Kalibrierung ist Fortschritt, kein Messwert.
String dialCenter(RingView v) {
  if (v.calibrating && v.have != null && v.need != null) {
    return '${v.have}/${v.need}';
  }
  return v.measured ? v.value : '–';
}

class DialRing extends StatelessWidget {
  const DialRing(this.view, {super.key, required this.color, this.onTap, this.size = 108});

  final RingView view;
  final Color color;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final muted = view.calibrating || view.provisional;
    return Pressable(
      onTap: onTap,
      semanticLabel: [view.label, view.value, if (view.sub.isNotEmpty) view.sub].join('. '),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DialPainter(
              lit: dialLitTicks(view.frac),
              litColor: muted ? p.ink3 : color,
              track: p.track,
              knob: p.card,
              line: p.line,
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.24),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(dialCenter(view),
                      style: Pult.digits(size * 0.26, muted ? p.ink3 : p.ink)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: S.x2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(view.label, style: F.cap.copyWith(color: p.ink, fontWeight: FontWeight.w600)),
        ),
        if (view.sub.isNotEmpty)
          Text(view.sub,
              textAlign: TextAlign.center,
              style: F.cap.copyWith(color: p.ink3)),
      ]),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.lit,
    required this.litColor,
    required this.track,
    required this.knob,
    required this.line,
  });

  final int lit;
  final Color litColor, track, knob, line;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.width / 2;
    final inner = outer * 0.8;
    final paint = Paint()
      ..strokeWidth = size.width * 0.024
      ..strokeCap = StrokeCap.butt;
    for (var i = 0; i < kDialTicks; i++) {
      final a = -math.pi / 2 + i / kDialTicks * 2 * math.pi;
      final d = Offset(math.cos(a), math.sin(a));
      paint.color = i < lit ? litColor : track;
      canvas.drawLine(center + d * inner, center + d * outer, paint);
    }
    canvas.drawCircle(center, outer * 0.68, Paint()..color = knob);
    canvas.drawCircle(
        center,
        outer * 0.68,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_DialPainter o) =>
      o.lit != lit || o.litColor != litColor || o.track != track || o.knob != knob;
}
