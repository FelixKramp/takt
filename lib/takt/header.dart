// Takt-Kopfzeile für Tabs und gepushte Screens (Feature 06, F1 und F15;
// Feature 07, H1): links Zurück-Pfeil oder nichts, der Name klein
// geschrieben, in der Mitte optional die Nacht oder der Tag mit Pfeilen,
// rechts optional das Profilbild.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_localizations.dart';
import '../ui2/grammar.dart' show Pressable;
import '../ui2/screens/metric_detail.dart' show chooseDay;
import '../ui2/theme.dart';

/// „Nacht auf So, 8. Nov.“ für den Tag, an dem die Nacht endet (yyyy-MM-dd).
String nightLabel(String day, bool de) {
  final d = DateTime.parse(day);
  const wdDe = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  const wdEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const moDe = ['Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sep.', 'Okt.', 'Nov.', 'Dez.'];
  const moEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return de
      ? 'Nacht auf ${wdDe[d.weekday - 1]}, ${d.day}. ${moDe[d.month - 1]}'
      : 'Night to ${wdEn[d.weekday - 1]}, ${d.day} ${moEn[d.month - 1]}';
}

class TaktHeader extends StatelessWidget {
  const TaktHeader(this.name, {super.key, this.back = false, this.center, this.trailing});

  final String name;
  final bool back;
  final Widget? center;
  final Widget? trailing;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(children: [
        if (back) ...[
          Pressable(
            key: const ValueKey('takt-back'),
            onTap: () => Navigator.maybePop(c),
            semanticLabel: AppLocalizations.of(c)?.supplementNavBack ?? 'Back',
            child: SizedBox(
              width: 32,
              height: 44,
              child: Icon(LucideIcons.chevronLeft, size: 24, color: p.ink),
            ),
          ),
          const SizedBox(width: S.x1),
        ],
        Text(name.toLowerCase(), style: F.t2.copyWith(color: p.ink)),
        const SizedBox(width: S.x2),
        Expanded(child: center ?? const SizedBox.shrink()),
        if (trailing != null) ...[const SizedBox(width: S.x2), trailing!],
      ]),
    );
  }
}

class TaktHeaderArrow extends StatelessWidget {
  const TaktHeaderArrow({super.key, required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: SizedBox(
        width: 36,
        height: 44,
        child: Icon(icon, size: 20, color: onTap == null ? p.ink3.withValues(alpha: .4) : p.ink),
      ),
    );
  }
}

/// Die gezeigte Nacht mit Pfeilen. [days] ist neueste zuerst wie bei DayNav.
class TaktDayStepper extends StatelessWidget {
  const TaktDayStepper({super.key, required this.day, required this.days, required this.onDay});

  final String? day;
  final List<String> days;
  final ValueChanged<String> onDay;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final de = Localizations.localeOf(c).languageCode == 'de';
    final l = AppLocalizations.of(c);
    final shown = day ?? (days.isEmpty ? null : days.first);
    if (shown == null) return const SizedBox.shrink();
    final i = days.indexOf(shown);
    final older = i < 0 ? (days.isEmpty ? null : days.first) : (i + 1 < days.length ? days[i + 1] : null);
    final newer = i > 0 ? days[i - 1] : null;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      TaktHeaderArrow(
        key: const ValueKey('takt-day-prev'),
        icon: LucideIcons.chevronLeft,
        label: l?.metricDetailPreviousDay ?? 'Previous day',
        onTap: older == null ? null : () => onDay(older),
      ),
      Flexible(
        child: Pressable(
          onTap: days.length < 2
              ? null
              : () async {
                  final picked = await chooseDay(c, days, shown);
                  if (picked != null && picked != shown) onDay(picked);
                },
          semanticLabel: nightLabel(shown, de),
          child: Text(
            nightLabel(shown, de),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: F.cap.copyWith(color: p.ink2),
          ),
        ),
      ),
      TaktHeaderArrow(
        key: const ValueKey('takt-day-next'),
        icon: LucideIcons.chevronRight,
        label: l?.metricDetailNextDay ?? 'Next day',
        onTap: newer == null ? null : () => onDay(newer),
      ),
    ]);
  }
}
