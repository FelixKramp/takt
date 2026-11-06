import 'package:flutter/foundation.dart';

/// Ob der Heute-Tab gerade vorne ist. Der Shell hält Tabs am Leben, sie sehen
/// also nicht selbst, wann sie verdeckt sind.
final ValueNotifier<bool> taktTodayVisible = ValueNotifier(true);
