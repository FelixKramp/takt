// Feature 03: Takts Schlafscore. OpenStrap rechnet bewusst keinen. Dieser
// steht offen da: drei Teile aus Werten, die OpenStrap schon misst, mit festen
// Gewichten, und die Teile stehen unter der Zahl.
//
//   Dauer zu Bedarf  60 %  (Anteil am Bedarf zum Quadrat, bei 100 gedeckelt:
//                           6 von 8 Std. → 56, 7 von 8 → 77)
//   Effizienz        20 %  (85 % → 0, 98 % → 100, linear)
//   Regelmäßigkeit   20 %  (SRI 50 → 0, 100 → 100, linear)
//
// Änderung 2026-11-14: Vorher 50/25/25 mit Effizienz ab 70 % und SRI ab 0.
// Effizienz (meist 90–97 %) und SRI (meist 75–95) lagen fast immer nahe am
// Maximum und trugen die Hälfte, der Score blieb so bei ~80, egal ob sechs
// oder acht Stunden geschlafen. Jetzt bewegt eine kurze Nacht den Score.
//
// Fehlt Effizienz oder Regelmäßigkeit, zählen die übrigen Teile anteilig
// (C2). Ohne Dauer oder Bedarf gibt es keinen Score.

import 'package:flutter/foundation.dart';
import 'dart:ui' show Color;

enum ScorePart { duration, efficiency, regularity }

enum NoScore { noNight, noNeed }

class NightScore {
  const NightScore({
    this.score,
    this.duration,
    this.efficiency,
    this.regularity,
    this.reason,
  });

  /// 0…100, ganze Zahl. `null` heißt kein Score, siehe [reason].
  final int? score;

  /// Die Teile, je 0…100, ungerundet.
  final double? duration, efficiency, regularity;
  final NoScore? reason;

  ScoreBand? get band => score == null ? null : bandOf(score!);

  /// Teile, die zum Score nichts beitragen konnten.
  List<ScorePart> get missing => [
        if (duration == null) ScorePart.duration,
        if (efficiency == null) ScorePart.efficiency,
        if (regularity == null) ScorePart.regularity,
      ];
}

const double kWDuration = 0.6, kWEfficiency = 0.2, kWRegularity = 0.2;
const double kEffZero = 85, kEffFull = 98, kSriZero = 50;

double _clamp100(double v) => v < 0 ? 0 : (v > 100 ? 100 : v);

NightScore scoreNight({
  required num? durationMin,
  required num? needMin,
  num? efficiencyPct,
  num? regularity,
}) {
  final eff = efficiencyPct == null
      ? null
      : _clamp100((efficiencyPct - kEffZero) / (kEffFull - kEffZero) * 100);
  final reg = regularity == null
      ? null
      : _clamp100((regularity - kSriZero) / (100 - kSriZero) * 100);
  if (durationMin == null || durationMin <= 0) {
    return NightScore(efficiency: eff, regularity: reg, reason: NoScore.noNight);
  }
  if (needMin == null || needMin <= 0) {
    return NightScore(efficiency: eff, regularity: reg, reason: NoScore.noNeed);
  }
  final ratio = (durationMin / needMin).clamp(0.0, 1.0);
  final dur = _clamp100(ratio * ratio * 100);
  var sum = kWDuration * dur, weight = kWDuration;
  if (eff != null) {
    sum += kWEfficiency * eff;
    weight += kWEfficiency;
  }
  if (reg != null) {
    sum += kWRegularity * reg;
    weight += kWRegularity;
  }
  return NightScore(
    score: (sum / weight).round(),
    duration: dur,
    efficiency: eff,
    regularity: reg,
  );
}

enum ScoreBand {
  gut(Color(0xFF2F62C9), Color(0xFF2552AD), Color(0xFF8CB0F5)),
  okay(Color(0xFFF0560A), Color(0xFFA63A00), Color(0xFFFF9A5C)),
  knapp(Color(0xFFB3261E), Color(0xFFA3221B), Color(0xFFF4877F));

  const ScoreBand(this.fill, this._inkLight, this._inkDark);

  /// Die Farbe als Fläche: Ring, Balken, markierte Nacht.
  final Color fill;
  final Color _inkLight, _inkDark;

  /// Die Farbe als Text, lesbar auf Karte und Grund.
  Color ink(bool dark) => dark ? _inkDark : _inkLight;

  /// Das Wort zur Stufe. Steht immer neben der Farbe (C12).
  String word(bool de) => switch (this) {
        ScoreBand.gut => de ? 'gut' : 'good',
        ScoreBand.okay => 'okay',
        ScoreBand.knapp => de ? 'knapp' : 'short',
      };
}

/// Stufe des neuesten Schlafscores, für die Farbe des Schlaf-Tabs in der
/// Tab-Leiste (Feature 06, F2). Gesetzt von den Schlafscore-Ladern.
class TaktSleepBand {
  static final current = ValueNotifier<ScoreBand?>(null);
}

ScoreBand bandOf(int score) => score >= 85
    ? ScoreBand.gut
    : score >= 70
        ? ScoreBand.okay
        : ScoreBand.knapp;
