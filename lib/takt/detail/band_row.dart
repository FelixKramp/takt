// Feature 07, H10 (und wie F8): eine Vergleichszeile. Name, Wert in
// Punktziffern, graue Spur, Band „üblich bei dir“, der Wert als Punkt
// (orange, wenn er außerhalb liegt), darunter ein kurzer Satz.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui2/theme.dart';
import '../pult_tokens.dart';
import '../stripe/stripe.dart';

class TaktBandRow extends StatelessWidget {
  const TaktBandRow({
    super.key,
    required this.index,
    required this.label,
    required this.value,
    required this.sentence,
    this.mark,
    this.bandLo,
    this.bandHi,
    this.outside = false,
  });

  final int index;
  final String label;

  /// Wert als Text; leer, wenn die Zahl nicht gezeigt wird (z. B. Hauttemperatur).
  final String value;
  final String sentence;
  final double? mark, bandLo, bandHi;
  final bool outside;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final warn = p.dark ? const Color(0xFFFF9A5C) : const Color(0xFFA63A00);
    final hasBand = mark != null && bandLo != null && bandHi != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: S.x3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: F.body.copyWith(color: p.ink))),
          if (value.isNotEmpty) ...[
            const SizedBox(width: S.x2),
            StripeDodge(align: 1, child: Text(value, style: Pult.digits(17, p.ink))),
          ],
        ]),
        if (hasBand) ...[
          const SizedBox(height: S.x3),
          _Strip(index: index, mark: mark!, lo: bandLo!, hi: bandHi!, outside: outside),
        ],
        const SizedBox(height: S.x2),
        StripeDodge(
          line: true,
          child: Text(sentence,
              style: F.cap.copyWith(
                  color: outside ? warn : p.ink2, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip(
      {required this.index, required this.mark, required this.lo, required this.hi, required this.outside});
  final int index;
  final double mark, lo, hi;
  final bool outside;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    // Die Spur reicht über Band und Wert, mit einem halben Band Luft.
    final half = math.max((hi - lo) / 2, 1e-6);
    final a = math.min(lo - half, mark), b = math.max(hi + half, mark);
    double f(double v) => b - a <= 0 ? .5 : ((v - a) / (b - a)).clamp(0.0, 1.0);
    return ExcludeSemantics(
      child: LayoutBuilder(builder: (c, box) {
        final w = box.maxWidth;
        const dot = 16.0;
        return SizedBox(
          height: dot,
          width: w,
          child: Stack(children: [
            Positioned(
                left: 0,
                top: 3,
                width: w,
                height: 10,
                child: DecoratedBox(
                    decoration: BoxDecoration(color: p.card2, borderRadius: R.rPill))),
            Positioned(
                left: f(lo) * w,
                top: 3,
                width: math.max(6, (f(hi) - f(lo)) * w),
                height: 10,
                child: Container(
                    key: ValueKey('takt-band-$index'),
                    decoration: BoxDecoration(color: p.line, borderRadius: R.rPill))),
            Positioned(
              left: (f(mark) * w - dot / 2).clamp(0.0, w - dot),
              top: 0,
              width: dot,
              height: dot,
              child: Container(
                key: ValueKey('takt-band-dot-$index'),
                decoration: BoxDecoration(
                  color: outside
                      ? (p.dark ? const Color(0xFFFF9A5C) : Pult.orange)
                      : p.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.card, width: 2),
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }
}
