// Takt-Haut: Markiert einen Teilbaum als Takt. Gemeinsame Bausteine aus
// lib/ui2 (Surface, InlineMetrics, Hypnogramm …) zeichnen sich darin im
// Takt-Stil. Außerhalb (Aktivität, Gesundheit) bleibt alles wie bei
// OpenStrap. Feature 06, siehe docs/features/06-schlaf-tab-ganz/architektur.md.

import 'package:flutter/material.dart';

import '../ui2/theme.dart';

class TaktLook extends StatelessWidget {
  const TaktLook({super.key, required this.child});

  final Widget child;

  static bool on(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_TaktMark>() != null;

  /// Wie [on], ohne Abhängigkeit, für initState.
  static bool peek(BuildContext c) => c.getInheritedWidgetOfExactType<_TaktMark>() != null;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final theme = Theme.of(c);
    // F6: flache Takt-Knöpfe mit Rand statt grüner Textlinks.
    return _TaktMark(
      child: Theme(
        data: theme.copyWith(
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: p.ink,
              backgroundColor: p.card,
              disabledForegroundColor: p.ink3,
              padding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x2),
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                borderRadius: R.rSm,
                side: BorderSide(color: p.line),
              ),
              textStyle: F.cap.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _TaktMark extends InheritedWidget {
  const _TaktMark({required super.child});

  @override
  bool updateShouldNotify(_TaktMark old) => false;
}
