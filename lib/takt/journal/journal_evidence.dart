import 'package:intl/intl.dart';
import 'journal_config.dart';

enum HabitImpact {
  helps, // "Hilft"
  costs, // "Kostet"
  noDifference, // "Kein Unterschied erkennbar"
  tooFewDays, // "Zu wenig Tage"
}

class HabitOutcomeComparison {
  const HabitOutcomeComparison({
    required this.outcomeKey,
    required this.yesAvg,
    required this.noAvg,
    required this.diff,
  });

  final String outcomeKey;
  final double yesAvg;
  final double noAvg;
  final double diff;
}

class HabitAnalysis {
  const HabitAnalysis({
    required this.question,
    required this.yesCount,
    required this.noCount,
    required this.impact,
    this.waitingCount = 0,
    this.readinessComparison,
    this.hrvComparison,
    this.rhrComparison,
    this.efficiencyComparison,
  });

  final JournalQuestion question;
  final int yesCount;
  final int noCount;
  final HabitImpact impact;

  /// Eingetragene Ja/Nein-Antworten, deren Nacht danach noch nicht gemessen
  /// oder berechnet ist (etwa: gestern eingetragen, heute Nacht steht noch
  /// aus). Sie zählen noch nicht, stehen aber sichtbar da, damit ein Eintrag
  /// nicht verschwunden wirkt (Gerätetest 14.11.).
  final int waitingCount;
  final HabitOutcomeComparison? readinessComparison;
  final HabitOutcomeComparison? hrvComparison;
  final HabitOutcomeComparison? rhrComparison;
  final HabitOutcomeComparison? efficiencyComparison;

  bool get hasEnoughDays => yesCount >= 5 && noCount >= 5;
}

String _nextDayString(String dateStr) {
  final d = DateTime.tryParse(dateStr);
  if (d == null) return dateStr;
  final next = DateTime(d.year, d.month, d.day + 1);
  return DateFormat('yyyy-MM-dd').format(next);
}

/// Berechnet die Auswertung „Was tut mir gut“ (J12 bis J17).
List<HabitAnalysis> computeJournalEvidence({
  required List<JournalQuestion> questions,
  required Map<String, Map<String, double>> metricsByDay,
  required Map<String, Map<String, double>> outcomeMaps,
  required List<Map<String, dynamic>> numericInsights,
  required Set<String> excludedDates,
}) {
  final results = <HabitAnalysis>[];
  final readinessMap = outcomeMaps['readiness'] ?? const {};
  final hrvMap = outcomeMaps['rmssd'] ?? const {};
  final rhrMap = outcomeMaps['rhr'] ?? const {};
  final effMap = outcomeMaps['efficiency'] ?? const {};

  for (final q in questions) {
    if (q.isRating || q.max != 1.0) continue; // Nur Ja/Nein-Gewohnheiten auswerten

    final yesReadiness = <double>[];
    final noReadiness = <double>[];

    final yesHrv = <double>[];
    final noHrv = <double>[];

    final yesRhr = <double>[];
    final noRhr = <double>[];

    final yesEff = <double>[];
    final noEff = <double>[];
    var waiting = 0;
    var yesCount = 0;
    var noCount = 0;

    for (final entry in metricsByDay.entries) {
      final logDate = entry.key;
      final val = entry.value[q.key];
      if (val == null) continue;

      // J16: Zeitbezug ist die Nacht nach Tag D -> Tag D+1
      final nextDate = _nextDayString(logDate);

      // J17: Eigene Nächte (kein WHOOP-Import, keine Tage ohne gemessene Nacht)
      if (excludedDates.contains(nextDate)) continue;

      // Für den Zählstand muss die Nacht gemessen sein. Änderung 14.11.: Das
      // hing allein an Readiness, die erst nach 14 Nächten Kalibrierung
      // existiert. Bis dahin zählte kein einziger Eintrag. Jetzt reicht ein
      // gemessener Nachtwert (Readiness, HRV, Ruhepuls oder Effizienz).
      final readVal = readinessMap[nextDate];
      final hrv = hrvMap[nextDate];
      final rhr = rhrMap[nextDate];
      final eff = effMap[nextDate];
      final measured = readVal != null || hrv != null || rhr != null || eff != null;
      if (!measured) {
        if (val == 1.0 || val == 0.0) waiting++;
        continue;
      }

      if (val == 1.0) {
        yesCount++;
        if (readVal != null) yesReadiness.add(readVal);
        if (hrv != null) yesHrv.add(hrv);
        if (rhr != null) yesRhr.add(rhr);
        if (eff != null) yesEff.add(eff);
      } else if (val == 0.0) {
        noCount++;
        if (readVal != null) noReadiness.add(readVal);
        if (hrv != null) noHrv.add(hrv);
        if (rhr != null) noRhr.add(rhr);
        if (eff != null) noEff.add(eff);
      }
    }

    // J13: Wenn < 5 Ja oder < 5 Nein -> Zu wenig Tage
    if (yesCount < 5 || noCount < 5) {
      results.add(HabitAnalysis(
        question: q,
        yesCount: yesCount,
        noCount: noCount,
        impact: HabitImpact.tooFewDays,
        waitingCount: waiting,
      ));
      continue;
    }

    // J12: Durchschnitte und Differenzen
    double avg(List<double> list) =>
        list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;

    HabitOutcomeComparison? comp(String key, List<double> y, List<double> n) {
      if (y.isEmpty || n.isEmpty) return null;
      final ya = avg(y);
      final na = avg(n);
      return HabitOutcomeComparison(
        outcomeKey: key,
        yesAvg: ya,
        noAvg: na,
        diff: ya - na,
      );
    }

    // J14: Einstufung Hilft / Kostet nur bei statistischer Signifikanz
    HabitImpact impact = HabitImpact.noDifference;
    for (final ni in numericInsights) {
      if (ni['field'] == q.key && ni['outcome'] == 'readiness') {
        final helped = ni['helped'] as bool?;
        final meaningful = ni['meaningful'] as bool? ?? false;
        final insufficient = ni['insufficient'] as bool? ?? false;
        final delta = (ni['delta'] as num?)?.toDouble();

        if (meaningful && !insufficient) {
          if (helped == true || (delta != null && delta > 0)) {
            impact = HabitImpact.helps;
          } else {
            impact = HabitImpact.costs;
          }
        }
        break;
      }
    }

    results.add(HabitAnalysis(
      question: q,
      yesCount: yesCount,
      noCount: noCount,
      impact: impact,
      waitingCount: waiting,
      readinessComparison: comp('readiness', yesReadiness, noReadiness),
      hrvComparison: comp('rmssd', yesHrv, noHrv),
      rhrComparison: comp('rhr', yesRhr, noRhr),
      efficiencyComparison: comp('efficiency', yesEff, noEff),
    ));
  }

  // J15: Sortierung: Hilft > Kostet > Kein Unterschied > Zu wenig Tage
  results.sort((a, b) {
    final rankA = _impactRank(a.impact);
    final rankB = _impactRank(b.impact);
    if (rankA != rankB) return rankA.compareTo(rankB);

    final diffA = (a.readinessComparison?.diff ?? 0.0).abs();
    final diffB = (b.readinessComparison?.diff ?? 0.0).abs();
    return diffB.compareTo(diffA);
  });

  return results;
}

int _impactRank(HabitImpact impact) => switch (impact) {
      HabitImpact.helps => 1,
      HabitImpact.costs => 2,
      HabitImpact.noDifference => 3,
      HabitImpact.tooFewDays => 4,
    };
