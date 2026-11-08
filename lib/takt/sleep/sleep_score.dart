// Feature 03: Takts Schlafscore. OpenStrap rechnet bewusst keinen. Dieser
// steht offen da: drei Teile aus Werten, die OpenStrap schon misst, mit festen
// Gewichten, und die Teile stehen unter der Zahl.
//
//   Dauer zu Bedarf  50 %  (bei 100 gedeckelt)
//   Effizienz        25 %  (70 % → 0, 95 % → 100, linear)
//   Regelmäßigkeit   25 %  (OpenStraps SRI, auf 0…100 begrenzt)
//
// Fehlt Effizienz oder Regelmäßigkeit, zählen die übrigen Teile anteilig
// (C2). Ohne Dauer oder Bedarf gibt es keinen Score.

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

double _clamp100(double v) => v < 0 ? 0 : (v > 100 ? 100 : v);

NightScore scoreNight({
  required num? durationMin,
  required num? needMin,
  num? efficiencyPct,
  num? regularity,
}) {
  final eff = efficiencyPct == null
      ? null
      : _clamp100((efficiencyPct - 70) / 25 * 100);
  final reg = regularity == null ? null : _clamp100(regularity.toDouble());
  if (durationMin == null || durationMin <= 0) {
    return NightScore(efficiency: eff, regularity: reg, reason: NoScore.noNight);
  }
  if (needMin == null || needMin <= 0) {
    return NightScore(efficiency: eff, regularity: reg, reason: NoScore.noNeed);
  }
  final dur = _clamp100(durationMin / needMin * 100);
  var sum = 0.5 * dur, weight = 0.5;
  if (eff != null) {
    sum += 0.25 * eff;
    weight += 0.25;
  }
  if (reg != null) {
    sum += 0.25 * reg;
    weight += 0.25;
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

ScoreBand bandOf(int score) => score >= 85
    ? ScoreBand.gut
    : score >= 70
        ? ScoreBand.okay
        : ScoreBand.knapp;
