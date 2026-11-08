// Feature 03: lädt den Takt-Kopf für die Nacht, die der Schlaf-Screen gerade
// zeigt, und liest neu, sobald ein Sync, eine Berechnung oder eine Korrektur
// der Schlafzeiten (C10) die Datenbank ändert.
//
// Der Schlaf-Screen ist eine ListView: Was aus dem Bild scrollt, wird
// abgebaut. Ohne Keep-alive stand nach schnellem Hochscrollen kurz eine
// leere Fläche da, bis der Kopf neu gelesen war (Gerätetest 0.2.0, E2).

import 'package:flutter/material.dart';

import '../../data/day_label.dart' show todayLabel;
import '../../ui2/revision.dart';
import '../../ui2/screens/home_screen.dart' show repoOf;
import 'sleep_head.dart';
import 'sleep_score.dart';
import 'sleep_tab_data.dart';

class TaktSleepHeadLoader extends StatefulWidget {
  const TaktSleepHeadLoader({super.key, this.day, this.load});

  /// Die gezeigte Nacht. Null: die neueste.
  final String? day;

  /// Nur für Tests: liest die Ansicht ohne Datenbank.
  final Future<TaktSleepView> Function(String? day)? load;

  @override
  State<TaktSleepHeadLoader> createState() => _TaktSleepHeadLoaderState();
}

class _TaktSleepHeadLoaderState extends State<TaktSleepHeadLoader>
    with RevisionReload, AutomaticKeepAliveClientMixin {
  /// Die zuletzt gelesene Ansicht, über Screen-Wechsel hinweg. Ein frisch
  /// geöffneter Schlaf-Screen zeigt sie sofort und ersetzt sie, sobald neu
  /// gelesen ist, statt mit einer leeren Fläche anzufangen.
  static TaktSleepView? _last;

  TaktSleepView? _view;

  @override
  bool get wantKeepAlive => true;

  @override
  void reload() => _load();

  @override
  void initState() {
    super.initState();
    final last = _last;
    if (last != null && (widget.day == null || widget.day == last.day)) _view = last;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(TaktSleepHeadLoader old) {
    super.didUpdateWidget(old);
    if (old.day != widget.day) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final inject = widget.load;
    final repo = inject == null ? repoOf(context) : null;
    if (inject == null && repo == null) return;
    final token = beginRead(#taktSleep);
    try {
      final v = inject != null
          ? await inject(widget.day)
          : await loadTaktSleep(repo!, want: widget.day);
      if (stillNewest(#taktSleep, token) && mounted) {
        _last = v;
        // Die Tab-Leiste färbt Schlaf nach der neuesten Nacht (F2).
        if (v.day == todayLabel()) TaktSleepBand.current.value = v.score.band;
        setState(() => _view = v);
      }
    } catch (_) {
      // Bleibt beim letzten Stand. Der Upstream-Teil darunter zeigt seinen
      // eigenen Fehlerzustand.
    }
  }

  @override
  Widget build(BuildContext c) {
    super.build(c);
    final v = _view;
    if (v == null) return const SizedBox(height: 320);
    return TaktSleepHead(view: v);
  }
}
