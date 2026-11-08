// Feature 06: Takt-Bausteine für den Teil des Schlaf-Tabs unter dem Kopf.
// Rein darstellend, die Werte kommen aus dem Schlaf-Screen.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ui2/grammar.dart' show Pressable, Surface;
import '../../ui2/theme.dart';
import '../pult_tokens.dart';
import '../stripe/stripe.dart';

/// Eine Phase: Name, Dauer als Text (Spanne oder Wert), Farbe, und Minuten
/// für den Balken (null: zählt im Balken nicht mit).
typedef PhaseRow = (String name, String value, Color color, num? minutes);

/// F7: durchgehender Balken der vier Phasen, darunter je eine Zeile.
class TaktPhases extends StatelessWidget {
  const TaktPhases({super.key, required this.rows, this.note});

  final List<PhaseRow> rows;
  final String? note;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final bar = [for (final r in rows) if ((r.$4 ?? 0) > 0) r];
    return Surface(
      key: const ValueKey('takt-phases'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (bar.isNotEmpty) ...[
          ClipRRect(
            key: const ValueKey('takt-phase-bar'),
            borderRadius: R.rSm,
            child: SizedBox(
              height: 16,
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final (i, r) in bar.indexed)
                  Expanded(
                    key: ValueKey('takt-phase-seg-$i'),
                    flex: (r.$4! * 10).round().clamp(1, 100000),
                    child: ColoredBox(color: r.$3),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: S.x3),
        ],
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: S.x1 + 2),
            child: Row(children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: r.$3, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: S.x3),
              Expanded(child: Text(r.$1, style: F.body.copyWith(color: p.ink))),
              const SizedBox(width: S.x2),
              Flexible(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: StripeDodge(
                    align: 1,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(r.$2, style: Pult.digits(17, p.ink), maxLines: 1),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        if (note != null) ...[
          const SizedBox(height: S.x2),
          Text(note!, style: F.over.copyWith(color: p.ink3, height: 1.4)),
        ],
      ]),
    );
  }
}

/// Ein Link: Symbol, Titel, Unterzeile, Ziel.
typedef TaktLink = (IconData icon, String title, String sub, VoidCallback onTap);

/// F12: eine Takt-Karte mit Zeilen, die weiterführen.
class TaktLinksCard extends StatelessWidget {
  const TaktLinksCard({super.key, required this.links});
  final List<TaktLink> links;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Surface(
      pad: const EdgeInsets.symmetric(horizontal: S.x4),
      child: Column(children: [
        for (final (i, k) in links.indexed) ...[
          if (i > 0) Divider(height: 1, color: p.card2),
          Pressable(
            onTap: k.$4,
            semanticLabel: '${k.$2}: ${k.$3}',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(children: [
                Icon(k.$1, size: 18, color: p.ink2),
                const SizedBox(width: S.x3),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k.$2, style: F.body.copyWith(color: p.ink)),
                      Text(k.$3, style: F.over.copyWith(color: p.ink3)),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 18, color: p.ink3),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}
