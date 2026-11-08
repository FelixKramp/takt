// Feature 03: die Tagesnotiz. OpenStrap hält Schlafbedarf, seine Teile und die
// Bett-/Aufstehempfehlung nur als aktuellen Wert. Für den Score einer Nacht
// und die Empfehlungslinie (C7) braucht Takt die Werte von damals, also
// schreibt es sie bei jedem Laden unter das heutige Datum. Der letzte Stand
// eines Tages bleibt stehen.

import 'dart:convert';

import '../../state/prefs.dart';

class NightNote {
  const NightNote({
    this.needMin,
    this.debtMin,
    this.strainMin,
    this.napMin,
    this.bedRec,
    this.wakeRec,
  });

  /// Bedarf für die kommende Nacht und seine Teile, in Minuten.
  final int? needMin, debtMin, strainMin, napMin;

  /// Empfohlene Bett- und Aufstehzeit, Minuten nach Mitternacht.
  final int? bedRec, wakeRec;

  /// Grundbedarf als Rest, damit die Teile genau den Bedarf ergeben.
  int? get baseMin => needMin == null
      ? null
      : needMin! - (debtMin ?? 0) - (strainMin ?? 0) + (napMin ?? 0);

  Map<String, dynamic> toJson() => {
        if (needMin != null) 'need': needMin,
        if (debtMin != null) 'debt': debtMin,
        if (strainMin != null) 'strain': strainMin,
        if (napMin != null) 'nap': napMin,
        if (bedRec != null) 'bed': bedRec,
        if (wakeRec != null) 'wake': wakeRec,
      };

  static NightNote fromJson(Map<String, dynamic> j) {
    int? i(String k) => (j[k] as num?)?.round();
    return NightNote(
      needMin: i('need'),
      debtMin: i('debt'),
      strainMin: i('strain'),
      napMin: i('nap'),
      bedRec: i('bed'),
      wakeRec: i('wake'),
    );
  }
}

String dayLabel(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String prevDay(String day) {
  final d = DateTime.parse(day);
  return dayLabel(DateTime(d.year, d.month, d.day - 1));
}

class TaktNightLog {
  TaktNightLog._();

  static const String key = 'takt.night_log';
  static const int keepDays = 30;

  static Map<String, NightNote> read() {
    try {
      final raw = jsonDecode(Prefs.getString(key, '{}'));
      if (raw is! Map) return const {};
      return {
        for (final e in raw.entries)
          if (e.value is Map)
            e.key.toString(): NightNote.fromJson((e.value as Map).cast<String, dynamic>()),
      };
    } catch (_) {
      return const {};
    }
  }

  static void record(String day, NightNote note) {
    final log = {...read(), day: note};
    final days = log.keys.toList()..sort();
    final keep = days.skip(days.length > keepDays ? days.length - keepDays : 0);
    Prefs.setString(key, jsonEncode({for (final d in keep) d: log[d]!.toJson()}));
  }

  static void clear() => Prefs.setString(key, '{}');
}

/// Der Bedarf, gegen den die Nacht bis zum Morgen von [nightDay] zählt.
class NightNeed {
  const NightNeed(this.needMin, {this.fromLog = false, this.note});
  final int? needMin;
  final bool fromLog;

  /// Die Teile, wenn die Notiz vom Vortag da ist.
  final NightNote? note;
  int? get strainMin => note?.strainMin;
}

/// Bedarf für die Nacht, die am Morgen von [nightDay] endet: die Notiz vom
/// Vortag. Ohne sie der heutige Bedarf ohne die Belastung von heute, sonst
/// würde der Score der letzten Nacht über den Tag wandern.
NightNeed needForNight(
  String nightDay,
  Map<String, NightNote> log, {
  required int? needNow,
  int? strainNowMin,
  int? napNowMin,
}) {
  final n = log[prevDay(nightDay)];
  if (n?.needMin != null) return NightNeed(n!.needMin, fromLog: true, note: n);
  if (needNow == null) return const NightNeed(null);
  return NightNeed(needNow - (strainNowMin ?? 0) + (napNowMin ?? 0));
}
