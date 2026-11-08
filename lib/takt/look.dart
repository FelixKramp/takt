// Takt-Haut: Markiert einen Teilbaum als Takt. Gemeinsame Bausteine aus
// lib/ui2 (Surface, InlineMetrics, Hypnogramm …) zeichnen sich darin im
// Takt-Stil. Außerhalb (Aktivität, Gesundheit) bleibt alles wie bei
// OpenStrap. Feature 06, siehe docs/features/06-schlaf-tab-ganz/architektur.md.

import 'package:flutter/widgets.dart';

class TaktLook extends InheritedWidget {
  const TaktLook({super.key, required super.child});

  static bool on(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<TaktLook>() != null;

  @override
  bool updateShouldNotify(TaktLook old) => false;
}
