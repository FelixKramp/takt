import 'dart:async';

import 'package:flutter/foundation.dart' show VoidCallback;

/// Wie lange nach dem Start der Gesundheit-Tab im Hintergrund aufgebaut wird
/// (Gerätetest 14.11.). Ein Timer, keine Animation: Reduced Motion hat hier
/// nichts zu sagen, deshalb steht die Dauer außerhalb von lib/ui2.
const Duration kTaktPrebuildDelay = Duration(seconds: 3);

Timer taktPrebuildTimer(VoidCallback run) => Timer(kTaktPrebuildDelay, run);
