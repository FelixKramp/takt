// TAKT 14.11.: Heute frei anordnen. Kopf und Ringe stehen fest oben, alles
// darunter steht in der Reihenfolge, die man in „Heute anordnen“ zieht. Die
// Reihenfolge liegt in den Prefs.

import 'package:flutter/material.dart';

import '../../state/prefs.dart';
import '../../ui2/ui2.dart';
import '../takt_text.dart';

enum TodaySection { tonight, pulse, cards, stress, watch, activities, week }

const List<TodaySection> kDefaultTodayOrder = TodaySection.values;

/// Gespeicherte Reihenfolge ohne Unbekanntes und Doppeltes. Was fehlt (etwa
/// ein neuer Abschnitt nach einem Update), kommt in Standardreihenfolge ans Ende.
List<TodaySection> normalizeTodayOrder(List<TodaySection> order) {
  final out = <TodaySection>[];
  for (final s in [...order, ...kDefaultTodayOrder]) {
    if (!out.contains(s)) out.add(s);
  }
  return out;
}

class TodayOrder {
  TodayOrder._();

  static const String key = 'takt.today.order';
  static final ValueNotifier<List<TodaySection>> current = ValueNotifier<List<TodaySection>>(
    kDefaultTodayOrder,
  );

  static List<TodaySection> read() {
    final raw = Prefs.getString(key, '');
    if (raw.isEmpty) return kDefaultTodayOrder;
    final byName = {for (final s in TodaySection.values) s.name: s};
    return normalizeTodayOrder([
      for (final n in raw.split(','))
        if (byName[n.trim()] != null) byName[n.trim()]!,
    ]);
  }

  static void load() => current.value = read();

  static void save(List<TodaySection> order) {
    final o = normalizeTodayOrder(order);
    Prefs.setString(key, o.map((s) => s.name).join(','));
    current.value = o;
  }

  static void reset() {
    Prefs.setString(key, '');
    current.value = kDefaultTodayOrder;
  }
}

String todaySectionLabel(TodaySection s, TaktText t) => switch (s) {
  TodaySection.tonight => t.sectionTonight,
  TodaySection.pulse => t.sectionPulse,
  TodaySection.cards => t.sectionCards,
  TodaySection.stress => t.sectionStress,
  TodaySection.watch => t.sectionWatch,
  TodaySection.activities => t.sectionActivities,
  TodaySection.week => t.sectionWeek,
};

/// „Heute anordnen“: Abschnitte an der Griffleiste ziehen. Jede Änderung wird
/// sofort gespeichert.
class TodayArrangeScreen extends StatefulWidget {
  const TodayArrangeScreen({super.key});

  @override
  State<TodayArrangeScreen> createState() => _TodayArrangeScreenState();
}

class _TodayArrangeScreenState extends State<TodayArrangeScreen> {
  late List<TodaySection> _order = List.of(TodayOrder.read());

  void _move(int from, int to) {
    setState(() {
      // ReorderableListView zählt `to` vor dem Entfernen.
      if (to > from) to--;
      final s = _order.removeAt(from);
      _order.insert(to, s);
    });
    TodayOrder.save(_order);
  }

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        title: Text(t.arrange, style: F.t2.copyWith(color: p.ink)),
        actions: [
          TextButton(
            key: const ValueKey('takt-arrange-reset'),
            onPressed: () {
              TodayOrder.reset();
              setState(() => _order = List.of(kDefaultTodayOrder));
            },
            child: Text(t.arrangeReset, style: F.cap.copyWith(color: p.ink2)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(S.x4, S.x2, S.x4, S.x3),
            child: Text(t.arrangeHint, style: F.cap.copyWith(color: p.ink2)),
          ),
          Expanded(
            child: ReorderableListView(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.symmetric(horizontal: S.x4),
              onReorder: _move,
              children: [
                for (var i = 0; i < _order.length; i++)
                  Padding(
                    key: ValueKey('takt-arrange-${_order[i].name}'),
                    padding: const EdgeInsets.only(bottom: S.x2),
                    child: ReorderableDragStartListener(
                      index: i,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: S.x4, vertical: S.x4),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: R.rSm,
                          border: Border.all(color: p.line),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                todaySectionLabel(_order[i], t),
                                style: F.body.copyWith(color: p.ink),
                              ),
                            ),
                            Icon(Icons.drag_handle, color: p.ink3),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
