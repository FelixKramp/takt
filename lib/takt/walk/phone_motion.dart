// Takt (Feature 15): Radfahren über die Aktivitätserkennung des Handys.
//
// Das Band zählt beim Treten Schritte wie beim Gehen, die Gehen-Erkennung
// (walk_detect.dart) kann beides nicht trennen. Das Handy kann es: Android
// meldet Wechsel zwischen zu Fuß, Fahrrad, Fahrzeug und still. Die nativ
// mitgeschriebenen Wechsel (TaktMotion.kt) liest [PhoneMotion.load], und
// [phoneSportFor] sagt für einen erkannten Gang, ob er eine Fahrt war.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ein Wechsel der Handy-Aktivitätserkennung.
class MotionEvent {
  /// Zeitpunkt in Unix-Millisekunden.
  final int ms;

  /// `walking`, `running`, `bicycle`, `vehicle` oder `still`.
  final String type;

  /// Beginn (true) oder Ende (false) dieser Aktivität.
  final bool enter;

  const MotionEvent(this.ms, this.type, this.enter);
}

/// Anteil der Zeit, ab dem ein Gang als Fahrt gilt.
const kBicycleShare = .5;

/// Längste Spanne, die eine Aktivität ohne neuen Wechsel weiter gilt. Fehlt
/// das Ende (Handy aus, Meldung verloren), wird nicht der ganze Tag Fahrrad.
const kMaxMotionSpanMs = 3 * 3600 * 1000;

/// Aktivitätsspannen `(from, to, type)` in Millisekunden aus den Wechseln.
/// Eine Aktivität gilt ab ihrem Beginn bis zu ihrem Ende, dem Beginn der
/// nächsten oder höchstens [kMaxMotionSpanMs].
List<(int, int, String)> motionSpans(List<MotionEvent> events) {
  final sorted = [...events]..sort((a, b) => a.ms.compareTo(b.ms));
  final spans = <(int, int, String)>[];
  String? cur;
  int? from;
  void close(int at) {
    if (cur != null && from != null) {
      final to = at < from! + kMaxMotionSpanMs ? at : from! + kMaxMotionSpanMs;
      if (to > from!) spans.add((from!, to, cur!));
    }
    cur = null;
    from = null;
  }

  for (final e in sorted) {
    if (e.enter) {
      close(e.ms);
      cur = e.type;
      from = e.ms;
    } else if (e.type == cur) {
      close(e.ms);
    }
  }
  if (cur != null) close(from! + kMaxMotionSpanMs);
  return spans;
}

/// `cycling`, wenn das Handy im Gang `[startSec, endSec)` mindestens
/// [kBicycleShare] der Zeit Fahrrad gemeldet hat, sonst null.
String? phoneSportFor(List<MotionEvent> events, int startSec, int endSec, {int? nowMs}) {
  final a = startSec * 1000, b = endSec * 1000;
  if (b <= a) return null;
  var bike = 0;
  for (final (from, to, type) in motionSpans(events)) {
    if (type != 'bicycle') continue;
    // Eine offene Fahrt reicht nicht über jetzt hinaus.
    final end = nowMs != null && to > nowMs ? nowMs : to;
    final lo = from > a ? from : a, hi = end < b ? end : b;
    if (hi > lo) bike += hi - lo;
  }
  return bike >= (b - a) * kBicycleShare ? 'cycling' : null;
}

/// Liest die mitgeschriebenen Wechsel. Leer auf iOS, ohne Berechtigung oder
/// ohne Play-Dienste.
class PhoneMotion {
  static const _channel = MethodChannel('takt/motion');

  static Future<List<MotionEvent>> load() async {
    if (defaultTargetPlatform != TargetPlatform.android) return const [];
    try {
      final raw = await _channel.invokeMethod<String>('events');
      return parse(raw);
    } catch (_) {
      return const [];
    }
  }

  /// Meldet die Wechsel an (etwa nachdem die Berechtigung erteilt wurde).
  static Future<bool> arm() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('arm') ?? false;
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  static List<MotionEvent> parse(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw);
    if (list is! List) return const [];
    return [
      for (final e in list)
        if (e is Map && e['ms'] is num && e['type'] is String)
          MotionEvent((e['ms'] as num).toInt(), e['type'] as String, e['enter'] == true),
    ];
  }
}
