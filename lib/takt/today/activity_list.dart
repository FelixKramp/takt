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

String _duration(int? min) {
  if (min == null) return '';
  return min < 60 ? '$min min' : '${min ~/ 60}:${(min % 60).toString().padLeft(2, '0')} h';
}

class ActivityList extends StatefulWidget {
  const ActivityList({
    super.key,
    required this.items,
    this.onOpen,
    this.onDiscard,
    this.onLog,
  });

  final List<ActivityItem> items;
  final void Function(ActivityItem)? onOpen;
  final void Function(ActivityItem)? onDiscard;
  final VoidCallback? onLog;

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
          child: Text(t.noActivities, style: F.body.copyWith(color: p.ink2)),
        ),
      for (final item in v.shown)
        _Row(item,
            onOpen: widget.onOpen == null ? null : () => widget.onOpen!(item),
            onDiscard: item.detected && widget.onDiscard != null
                ? () => widget.onDiscard!(item)
                : null),
      if (v.hidden > 0)
        Pressable(
          onTap: () => setState(() => _expanded = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: S.x3),
            child: Text(t.showAll(v.hidden), style: F.body.copyWith(color: p.ink)),
          ),
        ),
      const SizedBox(height: S.x3),
      Pressable(
        onTap: widget.onLog,
        child: Container(
          constraints: const BoxConstraints(minHeight: S.tap),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(S.x2),
          decoration: BoxDecoration(color: Pult.orange, borderRadius: R.rSm),
          child: Text(t.logWorkout,
              textAlign: TextAlign.center,
              style: F.body.copyWith(color: C.n900, fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row(this.item, {this.onOpen, this.onDiscard});

  final ActivityItem item;
  final VoidCallback? onOpen, onDiscard;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    final name = activityByName(item.type)?.displayName(c) ?? readableType(item.type);
    final start = DateTime.fromMillisecondsSinceEpoch(item.startTs * 1000);
    final details = [
      if (item.detected) t.detected,
      formatClockOf(start),
      if (item.durationMin != null) _duration(item.durationMin),
      if (item.avgHr != null && item.avgHr! > 0) 'Ø ${item.avgHr} bpm',
    ].join(', ');
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
      child: Row(children: [
        Expanded(
          child: Pressable(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: S.x2),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: F.body.copyWith(color: p.ink, fontWeight: FontWeight.w600)),
                    Text(details, style: F.cap.copyWith(color: p.ink3)),
                  ]),
                ),
                if (item.strain != null) ...[
                  const SizedBox(width: S.x2),
                  Text(displayFixed(item.strain!, 1), style: Pult.digits(22, p.ink)),
                ],
              ]),
            ),
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
          ),
      ]),
    );
  }
}
