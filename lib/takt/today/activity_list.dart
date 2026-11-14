// Alle Aktivitäten des Tages an einem Ort.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/decimal_text.dart' show displayFixed;
import '../../state/clock_format.dart' show formatClockOf;
import '../../ui2/activity/catalogue.dart';
import '../../ui2/ui2.dart';
import '../pult_tokens.dart';
import '../takt_text.dart';
import 'activity_items.dart';
import '../stripe/stripe.dart';

String _duration(int? min) {
  if (min == null) return '';
  return min < 60 ? '$min min' : '${min ~/ 60}:${(min % 60).toString().padLeft(2, '0')} h';
}

class ActivityList extends StatefulWidget {
  const ActivityList({
    super.key,
    required this.items,
    this.isPastDay = false,
    this.onOpen,
    this.onDiscard,
    this.onLog,
    this.onStart,
  });

  final List<ActivityItem> items;
  final bool isPastDay;
  final void Function(ActivityItem)? onOpen;
  final void Function(ActivityItem)? onDiscard;
  final VoidCallback? onLog;

  /// Startet ein Live-Training. Null: kein Knopf (vergangener Tag oder es
  /// läuft schon eins).
  final VoidCallback? onStart;

  @override
  State<ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<ActivityList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    final v = visibleActivities(widget.items, expanded: _expanded);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(t.activities, style: F.t2.copyWith(color: p.ink)),
      const SizedBox(height: S.x1),
      if (widget.items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: S.x3),
          child: Text(
            widget.isPastDay ? t.noActivitiesPastDay : t.noActivities,
            style: F.body.copyWith(color: p.ink2),
          ),
        ),
      for (final item in v.shown)
        TaktActivityCard(
          item: item,
          onOpen: widget.onOpen == null ? null : () => widget.onOpen!(item),
          onDiscard: item.detected && widget.onDiscard != null
              ? () => widget.onDiscard!(item)
              : null,
        ),
      if (v.hidden > 0)
        Pressable(
          onTap: () => setState(() => _expanded = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: S.x3),
            child: StripeDodge(
              line: true,
              child: Text(t.showAll(v.hidden), style: F.body.copyWith(color: p.ink)),
            ),
          ),
        ),
      const SizedBox(height: S.x3),
      // Gerätetest 14.11.: Der große Start-Knopf war zu wuchtig. Jetzt zwei
      // gleich große, flache Tasten nebeneinander, ohne Farbe: Starten links
      // (Play), Nachtragen rechts (Plus). Gleiche Form wie die Pult-Karten.
      Row(children: [
        if (!widget.isPastDay && widget.onStart != null) ...[
          Expanded(
            child: _WorkoutKey(
              boxKey: const ValueKey('takt-start-workout'),
              icon: LucideIcons.play,
              label: t.startWorkout,
              onTap: widget.onStart,
              strong: true,
            ),
          ),
          const SizedBox(width: S.x2),
        ],
        Expanded(
          child: _WorkoutKey(
            boxKey: const ValueKey('takt-log-workout'),
            icon: LucideIcons.plus,
            label: t.logWorkout,
            onTap: widget.onLog,
          ),
        ),
      ]),
    ]);
  }
}

class TaktActivityCard extends StatelessWidget {
  const TaktActivityCard({
    super.key,
    required this.item,
    this.onOpen,
    this.onDiscard,
  });

  final ActivityItem item;
  final VoidCallback? onOpen, onDiscard;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    final de = Localizations.localeOf(c).languageCode == 'de';
    final name = item.type == 'other'
        ? t.training
        : activityByName(item.type)?.displayName(c) ?? readableType(item.type);
    final icon = activityByName(item.type)?.icon ?? LucideIcons.activity;
    final start = DateTime.fromMillisecondsSinceEpoch(item.startTs * 1000);
    final timeStr = formatClockOf(start);
    final durStr =
        item.durationMin != null ? _duration(item.durationMin) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: S.x2),
      child: Surface(
        onTap: onOpen,
        pad: const EdgeInsets.all(S.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kopfzeile der Kachel: Icon, Name, Startzeit / Dauer, Verwerfen
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: p.card2,
                    borderRadius: R.rSm,
                  ),
                  child: Icon(icon, size: 18, color: Pult.orange),
                ),
                const SizedBox(width: S.x2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: S.x2,
                        runSpacing: 2,
                        children: [
                          Text(
                            name,
                            style: F.body.copyWith(
                              color: p.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.detected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Pult.orange.withValues(alpha: 0.15),
                                borderRadius: R.rSm,
                              ),
                              child: Text(
                                t.detected,
                                style: F.over.copyWith(
                                  color: Pult.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      StripeDodge(
                        line: true,
                        child: Text(
                          [
                            timeStr,
                            if (durStr != null) '· $durStr',
                          ].join(' '),
                          style: F.cap.copyWith(color: p.ink3),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDiscard != null)
                  Pressable(
                    onTap: onDiscard,
                    semanticLabel: t.discard(name),
                    child: SizedBox(
                      width: S.tap,
                      height: S.tap,
                      child: Icon(LucideIcons.x, size: 18, color: p.ink3),
                    ),
                  )
                else
                  Icon(LucideIcons.chevronRight, size: 16, color: p.ink3),
              ],
            ),
            const SizedBox(height: S.x3),
            // Wichtigste Kennzahlen auf einen Blick: Belastung, Ø Puls, Max Puls, (Kalorien)
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: S.x2,
                horizontal: S.x2,
              ),
              decoration: BoxDecoration(
                color: p.card2,
                borderRadius: R.rSm,
              ),
              child: Row(
                children: [
                  // Belastung / Strain
                  Expanded(
                    child: _StatCell(
                      label: de ? 'BELASTUNG' : 'STRAIN',
                      value: item.strain != null
                          ? displayFixed(item.strain!, 1)
                          : '—',
                      color: Pult.orange,
                    ),
                  ),
                  Container(width: 1, height: 32, color: p.line),
                  // Durchschnittspuls
                  Expanded(
                    child: _StatCell(
                      label: de ? 'Ø PULS' : 'AVG HR',
                      value: item.avgHr != null && item.avgHr! > 0
                          ? '${item.avgHr}'
                          : '—',
                      unit: 'bpm',
                    ),
                  ),
                  Container(width: 1, height: 32, color: p.line),
                  // Maximalpuls
                  Expanded(
                    child: _StatCell(
                      label: de ? 'MAX PULS' : 'MAX HR',
                      value: item.maxHr != null && item.maxHr! > 0
                          ? '${item.maxHr}'
                          : '—',
                      unit: 'bpm',
                    ),
                  ),
                  if (item.calories != null && item.calories! > 0) ...[
                    Container(width: 1, height: 32, color: p.line),
                    Expanded(
                      child: _StatCell(
                        label: de ? 'KALORIEN' : 'CALORIES',
                        value: '${item.calories}',
                        unit: 'kcal',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.unit,
    this.color,
  });

  final String label;
  final String value;
  final String? unit;
  final Color? color;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final valColor = color ?? p.ink;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: F.over.copyWith(color: p.ink3, fontWeight: FontWeight.w600),
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 2),
        StripeDodge(
          align: 0,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: Pult.digits(18, valColor),
                  maxLines: 1,
                ),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit!,
                    style: F.over.copyWith(color: p.ink3),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Eine flache Taste unter den Aktivitäten: Rahmen, keine Fläche, keine Farbe.
class _WorkoutKey extends StatelessWidget {
  const _WorkoutKey({
    required this.boxKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.strong = false,
  });

  final Key boxKey;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Starten: Rahmen und Schrift etwas kräftiger als Nachtragen.
  final bool strong;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final ink = strong ? p.ink : p.ink2;
    return Pressable(
      onTap: onTap,
      child: Container(
        key: boxKey,
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: S.x2, vertical: S.x1),
        decoration: BoxDecoration(
          borderRadius: R.rSm,
          border: Border.all(color: strong ? p.ink3 : p.line, width: strong ? 1.2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ink),
            const SizedBox(width: S.x1 + 2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: F.cap.copyWith(color: ink, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
