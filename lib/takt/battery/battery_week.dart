// Feature 04, D6 bis D8: die letzten sieben Tage als Batterie-Säulen. Hell die
// Ladung am Morgen, voll der Rest am Abend, dazwischen hat die Belastung
// verbraucht. Tage unter 20 % sind rot und werden unter der Karte genannt.

import 'package:flutter/material.dart';

import '../../ui2/grammar.dart' show Surface;
import '../../ui2/theme.dart';
import '../pult_tokens.dart';
import '../sleep/sleep_score.dart' show ScoreBand;
import '../stripe/stripe.dart';
import '../takt_text.dart';
import 'battery.dart';

class TaktBatteryWeek extends StatelessWidget {
  const TaktBatteryWeek({super.key, required this.days, required this.today});

  final List<BatteryDay> days;
  final DateTime today;

  static const _barH = 88.0;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    final ink = Pult.orangeFor(p.dark);
    final red = ScoreBand.knapp.fill;
    final over = [
      for (final d in days)
        if (d.over) t.weekdayShort(d.day),
    ];
    bool isToday(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;

    return Surface(
      key: const ValueKey('takt-battery-week'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        StripeDodge(
          line: true,
          child: Text(t.batteryWeek,
              style: F.cap.copyWith(color: p.ink, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: S.x3),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: KeyedSubtree(
                key: ValueKey('takt-battery-day-$i'),
                child: Column(children: [
                  StripeDodge(
                    align: .5,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(days[i].left?.toString() ?? '–',
                          maxLines: 1,
                          style: Pult.digits(15, days[i].over ? red : p.ink)),
                    ),
                  ),
                  const SizedBox(height: S.x1),
                  SizedBox(
                    height: _barH,
                    width: 18,
                    child: Stack(alignment: Alignment.bottomCenter, children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: R.rSm,
                          border: Border.all(color: p.line),
                        ),
                      ),
                      if (days[i].morning != null)
                        Container(
                          height: _barH * (days[i].morning!.clamp(0, 100) / 100),
                          decoration: BoxDecoration(
                            color: ink.withValues(alpha: .22),
                            borderRadius: R.rSm,
                          ),
                        ),
                      if (days[i].left != null)
                        Container(
                          key: days[i].over ? ValueKey('takt-battery-over-$i') : null,
                          height: _barH * (days[i].left! / 100),
                          decoration: BoxDecoration(
                            color: days[i].over ? red : ink,
                            borderRadius: R.rSm,
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: S.x1),
                  StripeDodge(
                    align: .5,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(t.weekdayShort(days[i].day),
                          maxLines: 1,
                          style: F.cap.copyWith(
                              color: isToday(days[i].day) ? p.ink : p.ink3,
                              fontWeight:
                                  isToday(days[i].day) ? FontWeight.w700 : FontWeight.w400)),
                    ),
                  ),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: S.x3),
        StripeDodge(
          line: true,
          child: Text(over.isEmpty ? t.batteryWeekHelp : t.batteryOver(over.join(', ')),
              style: F.cap.copyWith(color: over.isEmpty ? p.ink2 : ScoreBand.knapp.ink(p.dark), height: 1.4)),
        ),
      ]),
    );
  }
}
