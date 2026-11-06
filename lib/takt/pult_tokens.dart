// Pult: die Farben und Schriften, die nur Takt braucht. Flächen und Tinte
// kommen weiter aus `P` in lib/ui2/theme.dart.

import 'package:flutter/material.dart';

class Pult {
  static const orange = Color(0xFFF0560A);
  static const blue = Color(0xFF2F62C9);
  static const blueOnDark = Color(0xFF8CB0F5);
  static const lcdBg = Color(0xFF1D211D);
  static const lcdInk = Color(0xFFF9AE45);
  static const lcdDim = Color(0xFFA8AD9F);
  static const lcdFrame = Color(0xFFB5B5AF);

  /// Punktmatrix-Ziffern wie auf einem Gerätedisplay. Doto ist eine variable
  /// Schrift, das Gewicht läuft deshalb über die Achse.
  static TextStyle digits(double size, Color color) => TextStyle(
        fontFamily: 'Doto',
        fontSize: size,
        height: 1,
        color: color,
        fontVariations: const [FontVariation('wght', 900)],
      );
}
