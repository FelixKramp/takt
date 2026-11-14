import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/takt/sleep/sleep_score.dart';
import 'package:openstrap_edge/ui2/theme.dart';

void main() {
  test('C1: Dauer 60 % (Anteil zum Quadrat), Effizienz 20 %, Regelmäßigkeit 20 %', () {
    final s = scoreNight(durationMin: 432, needMin: 480, efficiencyPct: 89, regularity: 76);
    expect(s.duration, closeTo(81, 0.01)); // 0,9² = 0,81
    expect(s.efficiency, closeTo(30.77, 0.01)); // (89 − 85) / 13
    expect(s.regularity, closeTo(52, 0.01)); // (76 − 50) / 50
    expect(s.score, 65);
  });

  test('C1 (Gerätetest 14.11.): sechs von acht Stunden ist knapp, nicht 80', () {
    // Felix: 6 Std. geschlafen, Regelmäßigkeit 90, Effizienz typisch 94 %.
    final short = scoreNight(durationMin: 360, needMin: 480, efficiencyPct: 94, regularity: 90);
    expect(short.duration, closeTo(56.25, 0.01));
    expect(short.score, 64);
    expect(short.band, ScoreBand.knapp);
    final full = scoreNight(durationMin: 480, needMin: 480, efficiencyPct: 94, regularity: 90);
    expect(full.score, 90);
    expect(full.band, ScoreBand.gut);
    final seven = scoreNight(durationMin: 420, needMin: 480, efficiencyPct: 94, regularity: 90);
    expect(seven.band, ScoreBand.okay);
    // Eine Stunde mehr Schlaf bewegt den Score deutlich, nicht um 3 Punkte.
    expect(full.score! - short.score!, greaterThanOrEqualTo(20));
  });

  test('C1: Dauer über dem Bedarf zählt höchstens 100', () {
    final s = scoreNight(durationMin: 540, needMin: 480, efficiencyPct: 98, regularity: 100);
    expect(s.duration, 100);
    expect(s.score, 100);
  });

  test('C1: Effizienz linear von 85 % bis 98 %, außerhalb begrenzt', () {
    expect(scoreNight(durationMin: 480, needMin: 480, efficiencyPct: 85).efficiency, 0);
    expect(scoreNight(durationMin: 480, needMin: 480, efficiencyPct: 70).efficiency, 0);
    expect(scoreNight(durationMin: 480, needMin: 480, efficiencyPct: 91.5).efficiency,
        closeTo(50, 0.01));
    expect(scoreNight(durationMin: 480, needMin: 480, efficiencyPct: 99).efficiency, 100);
  });

  test('C1: Regelmäßigkeit linear von SRI 50 bis 100, außerhalb begrenzt', () {
    expect(scoreNight(durationMin: 480, needMin: 480, regularity: -20).regularity, 0);
    expect(scoreNight(durationMin: 480, needMin: 480, regularity: 50).regularity, 0);
    expect(scoreNight(durationMin: 480, needMin: 480, regularity: 75).regularity, 50);
    expect(scoreNight(durationMin: 480, needMin: 480, regularity: 130).regularity, 100);
  });

  test('C2: fehlende Regelmäßigkeit, die anderen Gewichte werden hochgerechnet', () {
    final s = scoreNight(durationMin: 432, needMin: 480, efficiencyPct: 89);
    expect(s.regularity, isNull);
    // (0,6·81 + 0,2·30,77) / 0,8 = 68,44
    expect(s.score, 68);
    expect(s.missing, [ScorePart.regularity]);
  });

  test('C2: ohne Dauer oder Bedarf gibt es keinen Score, aber einen Grund', () {
    final a = scoreNight(durationMin: null, needMin: 480, efficiencyPct: 89, regularity: 70);
    expect(a.score, isNull);
    expect(a.reason, NoScore.noNight);
    final b = scoreNight(durationMin: 432, needMin: null, efficiencyPct: 89, regularity: 70);
    expect(b.score, isNull);
    expect(b.reason, NoScore.noNeed);
  });

  test('C3: Stufen gut ab 85, okay 70 bis 84, knapp darunter', () {
    expect(bandOf(85), ScoreBand.gut);
    expect(bandOf(100), ScoreBand.gut);
    expect(bandOf(84), ScoreBand.okay);
    expect(bandOf(70), ScoreBand.okay);
    expect(bandOf(69), ScoreBand.knapp);
    expect(bandOf(0), ScoreBand.knapp);
  });

  test('C12: Farbe je Stufe, als Text lesbar auf Karte und Grund, hell und dunkel', () {
    expect(ScoreBand.gut.fill, const Color(0xFF2F62C9));
    expect(ScoreBand.okay.fill, const Color(0xFFF0560A));
    expect(ScoreBand.knapp.fill, const Color(0xFFB3261E));
    for (final dark in [false, true]) {
      final p = P(dark);
      for (final b in ScoreBand.values) {
        for (final surface in [p.card, p.bg]) {
          expect(P.contrast(b.ink(dark), surface), greaterThanOrEqualTo(4.5),
              reason: '$b als Text, dunkel=$dark');
        }
      }
    }
  });
}
