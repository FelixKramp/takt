// Der Weg zum alten Heute-Screen: Plan, Hinweise und Wecker liegen jetzt hier.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ui2/screens/home_screen.dart';
import '../../ui2/ui2.dart';
import '../takt_text.dart';

class MoreForTodayRow extends StatelessWidget {
  const MoreForTodayRow({super.key});

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    return Pressable(
      onTap: () => go(c, const MoreForTodayScreen()),
      child: Surface(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.moreForToday, style: F.body.copyWith(color: p.ink, fontWeight: FontWeight.w600)),
              Text(t.moreForTodaySub, style: F.cap.copyWith(color: p.ink3)),
            ]),
          ),
          Icon(LucideIcons.chevronRight, size: 18, color: p.ink3),
        ]),
      ),
    );
  }
}

class MoreForTodayScreen extends StatelessWidget {
  const MoreForTodayScreen({super.key});

  @override
  Widget build(BuildContext c) => Scaffold(
        backgroundColor: P.of(c).bg,
        appBar: AppBar(title: Text(TaktText.of(c).moreForToday)),
        body: const SafeArea(child: HomeScreen()),
      );
}
