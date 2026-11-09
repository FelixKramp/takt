// Feature 04: Batterie statt Erholung. Morgens steht sie auf der Erholung,
// über den Tag zieht die Belastung ab. Wenig Belastung zieht wenig ab, viel
// überproportional: Stand = Ladung × (1 − (Strain / 21)^1,5) (D2, sanftere
// Kurve nach Felix' Wahl am 9.11.2026). Nichts davon wird gespeichert.

import 'dart:math' as math;

import '../../l10n/app_localizations.dart';
import '../../ui2/screens/home_screen.dart'
    show ChartPoint, HomeData, HomeRingKind, RingView, ringViewOf;
import '../takt_text.dart';

/// Unter diesem Rest am Abend gilt ein Tag als „mehr belastet als erholt“ (D7).
const kBatteryLow = 20;

/// Rest in Prozent, gerundet. Ohne Strain bleibt die Ladung stehen.
int batteryLeft(double morning, double? strain) {
  final s = ((strain ?? 0) / 21).clamp(0.0, 1.0);
  return (morning.clamp(0.0, 100.0) * (1 - math.pow(s, 1.5))).round();
}

/// D4: der Stand pro Minute aus der Strain-Kurve des Tages. Die Kurve ist
/// nicht monoton, ein ruhiger Abend zieht Strain wieder ab. Aufladen während
/// des Tages ist ein Nicht-Ziel, deshalb zählt der höchste Strain bis dahin
/// (Prüfung 04, B2).
List<double?> batteryCurve(double morning, List<double?> strainCurve) {
  double? peak;
  return [
    for (final s in strainCurve)
      if (s == null)
        null
      else
        batteryLeft(morning, peak = peak == null || s > peak ? s : peak).toDouble(),
  ];
}

class BatteryDay {
  const BatteryDay({required this.day, this.morning, this.strain});
  final DateTime day;
  final double? morning, strain;

  /// Rest am Abend, null ohne Erholung.
  int? get left => morning == null ? null : batteryLeft(morning!, strain);
  bool get over => left != null && left! < kBatteryLow;
}

DateTime _dayOf(int sec) {
  final d = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
  return DateTime(d.year, d.month, d.day);
}

/// D6: die letzten sieben Tage bis [today]. Heute nimmt nur die frischen Werte
/// von Heute, nie den Verlauf: Teilnacht-Rechnungen schreiben dort schon eine
/// Erholung, die der Ring noch nicht zeigt (Prüfung 04, B1).
List<BatteryDay> batteryWeek({
  required List<ChartPoint> recovery,
  required List<ChartPoint> strain,
  required DateTime today,
  double? todayMorning,
  double? todayStrain,
}) {
  final t0 = DateTime(today.year, today.month, today.day);
  double? on(List<ChartPoint> pts, DateTime d) {
    double? v;
    for (final p in pts) {
      if (_dayOf(p.t) == d) v = p.v;
    }
    return v;
  }

  return [
    for (var i = 6; i >= 0; i--)
      () {
        final d = DateTime(t0.year, t0.month, t0.day - i);
        return i == 0
            ? BatteryDay(
                day: d,
                morning: todayMorning,
                strain: todayStrain)
            : BatteryDay(day: d, morning: on(recovery, d), strain: on(strain, d));
      }(),
  ];
}

/// D3, D5: der erste Ring. Ohne Erholung oder während der Nacht ist es
/// OpenStraps Erholungsring mit neuem Namen, sonst der Stand der Batterie.
RingView batteryRing(HomeData d, AppLocalizations? l, TaktText t) {
  final base = ringViewOf(HomeRingKind.recovery, d, l);
  final v = d.readiness.value?.toDouble();
  if (v == null || d.recoveryState == 'night_in_progress') {
    return RingView(
      kind: HomeRingKind.recovery,
      label: t.battery,
      value: base.value,
      sub: base.sub,
      frac: base.frac,
      calibrating: base.calibrating,
      provisional: base.provisional,
      measured: base.measured,
      have: base.have,
      need: base.need,
      why: base.why,
    );
  }
  final strain = d.strain.value?.toDouble();
  final left = batteryLeft(v, strain);
  return RingView(
    kind: HomeRingKind.recovery,
    label: t.battery,
    value: '$left',
    sub: t.batteryOf(v.round()),
    frac: left / 100,
    provisional: base.provisional,
    why: strain == null ? t.strainPending : null,
  );
}
