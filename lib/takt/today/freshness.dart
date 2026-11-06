// Wie alt die Daten sind, und wann das Öffnen einen Sync auslöst.
import '../takt_text.dart';

String freshnessText(DateTime? at, DateTime now, TaktText t) {
  if (at == null) return t.noData;
  final d = now.difference(at);
  if (d.inMinutes < 1) return t.justNow;
  if (d.inHours < 1) return t.minutesAgo(d.inMinutes);
  return t.hoursAgo(d.inHours);
}

/// Sync beim Öffnen, höchstens alle fünf Minuten, damit Tabwechsel nichts kosten.
class SyncOnOpenGate {
  SyncOnOpenGate({this.every = const Duration(minutes: 5)});
  final Duration every;
  DateTime? _last;

  bool shouldSync(DateTime now, {required bool paired}) {
    if (!paired) return false;
    final last = _last;
    if (last != null && now.difference(last) < every) return false;
    _last = now;
    return true;
  }
}
