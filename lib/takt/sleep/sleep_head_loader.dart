// Feature 03: lädt den Takt-Kopf für die Nacht, die der Schlaf-Screen gerade
// zeigt, und liest neu, sobald ein Sync, eine Berechnung oder eine Korrektur
// der Schlafzeiten (C10) die Datenbank ändert.

import 'package:flutter/material.dart';

import '../../ui2/revision.dart';
import '../../ui2/screens/home_screen.dart' show repoOf;
import 'sleep_head.dart';
import 'sleep_tab_data.dart';

class TaktSleepHeadLoader extends StatefulWidget {
  const TaktSleepHeadLoader({super.key, this.day});

  /// Die gezeigte Nacht. Null: die neueste.
  final String? day;

  @override
  State<TaktSleepHeadLoader> createState() => _TaktSleepHeadLoaderState();
}

class _TaktSleepHeadLoaderState extends State<TaktSleepHeadLoader> with RevisionReload {
  TaktSleepView? _view;

  @override
  void reload() => _load();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(TaktSleepHeadLoader old) {
    super.didUpdateWidget(old);
    if (old.day != widget.day) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final repo = repoOf(context);
    if (repo == null) return;
    final token = beginRead(#taktSleep);
    try {
      final v = await loadTaktSleep(repo, want: widget.day);
      if (stillNewest(#taktSleep, token)) setState(() => _view = v);
    } catch (_) {
      // Bleibt beim letzten Stand. Der Upstream-Teil darunter zeigt seinen
      // eigenen Fehlerzustand.
    }
  }

  @override
  Widget build(BuildContext c) {
    final v = _view;
    if (v == null) return const SizedBox(height: 320);
    return TaktSleepHead(view: v);
  }
}
