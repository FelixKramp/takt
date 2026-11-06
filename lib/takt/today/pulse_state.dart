// Was das Puls-Display zeigt. Reine Logik, damit die Regeln testbar sind:
// nie eine erfundene Zahl, und der letzte Wert trägt immer Uhrzeit und Grund.
enum PulseKind { live, stale, never }

enum PulseReason { notPaired, notConnected, notWorn }

class LastPulse {
  const LastPulse(this.bpm, this.at);
  final int bpm;
  final DateTime at;

  String encode() => '$bpm|${at.millisecondsSinceEpoch}';

  static LastPulse? decode(String? raw) {
    final parts = raw?.split('|');
    if (parts == null || parts.length != 2) return null;
    final bpm = int.tryParse(parts[0]);
    final ms = int.tryParse(parts[1]);
    if (bpm == null || ms == null) return null;
    return LastPulse(bpm, DateTime.fromMillisecondsSinceEpoch(ms));
  }
}

class PulseState {
  const PulseState(this.kind, {this.bpm, this.at, this.reason});
  final PulseKind kind;
  final int? bpm;
  final DateTime? at;
  final PulseReason? reason;
}

PulseState pulseStateOf({
  required int? live,
  required LastPulse? last,
  required bool paired,
  required bool connected,
}) {
  if (live != null) return PulseState(PulseKind.live, bpm: live);
  final reason = !paired
      ? PulseReason.notPaired
      : !connected
          ? PulseReason.notConnected
          : PulseReason.notWorn;
  if (last == null) return PulseState(PulseKind.never, reason: reason);
  return PulseState(PulseKind.stale, bpm: last.bpm, at: last.at, reason: reason);
}

/// Hält den Live-Strom nur offen, solange der Puls wirklich zu sehen ist.
class PulseStreamGate {
  PulseStreamGate({required this.retain, required this.release});
  final void Function() retain;
  final void Function() release;
  bool _open = false;

  bool get isOpen => _open;

  void update(bool visible) {
    if (visible == _open) return;
    _open = visible;
    visible ? retain() : release();
  }
}
