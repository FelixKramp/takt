// Feature 07, H1, H9, H13: der Kopf jedes Detailscreens. Wert in großen
// Punktziffern, Einheit daneben, darunter von wann er ist oder das Wort der
// Stufe. Ohne Wert ein Strich und der Grund.

import 'package:flutter/material.dart';

import '../../ui2/grammar.dart' show Surface;
import '../../ui2/theme.dart';
import '../pult_tokens.dart';
import '../stripe/stripe.dart';

class TaktValueCard extends StatelessWidget {
  const TaktValueCard({
    super.key,
    required this.value,
    this.unit = '',
    this.when,
    this.word,
    this.wordColor,
    this.why,
  });

  /// Der Wert als Text. Null: kein Wert, dann steht „–“ und [why].
  final String? value;
  final String unit;
  final String? when;
  final String? word;
  final Color? wordColor;
  final String? why;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Surface(
      key: const ValueKey('takt-value-card'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Wert und Einheit teilen sich den Platz neben dem Wort. Ein loses
          // Flexible neben einem Spacer bekäme nur die Hälfte und schrumpfte
          // die Zahl (Prüfung 08).
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Flexible(
                child: StripeDodge(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value ?? '–', style: Pult.digits(56, p.ink), maxLines: 1),
                  ),
                ),
              ),
              if (value != null && unit.isNotEmpty) ...[
                const SizedBox(width: S.x2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(unit, style: F.body.copyWith(color: p.ink2)),
                ),
              ],
            ]),
          ),
          if (word != null) ...[
            const SizedBox(width: S.x2),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(word!,
                  style: F.head.copyWith(color: wordColor ?? p.ink, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        if (value == null && why != null) ...[
          const SizedBox(height: S.x2),
          StripeDodge(
            line: true,
            child: Text(why!, style: F.cap.copyWith(color: p.ink2, height: 1.4)),
          ),
        ] else if (when != null) ...[
          const SizedBox(height: S.x2),
          StripeDodge(line: true, child: Text(when!, style: F.cap.copyWith(color: p.ink2))),
        ],
      ]),
    );
  }
}
