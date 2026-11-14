// Feature 10: Körperalter (Spec: docs/features/10-koerperalter/spec.md,
// Herleitung: docs/features/10-koerperalter/architektur.md).
//
// Berechnet aus den letzten 30 Tagen über sieben Alltagsfaktoren eine grobe
// Schätzung des Körperalters. Jeder Faktor wird über ein lineares relatives
// Risiko (eigene Näherung, nicht direkt aus den Studien übernommen) mit der
// 8-Jahres-Verdopplungsregel in Jahre umgerechnet: Jahre = ln(Risiko) / ln(2) * 8.
// Das Risiko ist 1,0 beim Referenzpunkt (typischer Erwachsenenwert, eigene
// Annahme), nicht beim Optimum. Jeder Faktor ist auf ±3,0 Jahre begrenzt, die
// Summe auf ±10,0 Jahre und so, dass das Körperalter zwischen 10 und 130 bleibt.
// Kein medizinischer Befund.

import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../compute/profile.dart' show plausibleAgeYears;
import '../../data/day_label.dart' show dayLabelOf;
import '../../data/local_repository.dart';
import '../../ui2/activity/catalogue.dart' show activityLibrary;
import '../../ui2/screens/home_screen.dart' show ChartPoint, envValue, pointsOf;

/// Speicherort der Wochen-Momentaufnahmen (K5). Je Montag ein Eintrag.
const kBodyAgeWeeksKey = 'takt.body_age.weeks.v1';

/// Erforderliche Tage mit Daten innerhalb der letzten 30 Kalendertage (K1, K4).
const kBodyAgeMinDays = 14;

/// Ab so vielen Tagen mit Daten in den letzten sieben Kalendertagen steht der
/// 7-Tage-Vergleich da. Darunter wäre es Zufall.
const kBodyAgeRecentMinDays = 3;

/// Schalter für den vorläufig entfernten Zielkorridor „Alter −5,5 bis −2“ und die
/// Einstufung „im optimalen Zielbereich“ (Befund 4: unbegründet, Felix hat noch
/// nicht entschieden). `false` = nicht gezeigt. Umkehrbar: auf `true` setzen,
/// dann erscheinen Korridor-Karte, Korridorband, „Optimal“-Label und Einstufung
/// wieder wie vorher.
const kBodyAgeTargetCorridor = false;

const double _kMinBodyAge = 10.0;
const double _kMaxBodyAge = 130.0;

/// Sportarten, die für den Faktor „Krafttraining“ zählen: die Katalog-Gruppe
/// „Strength“ (`lib/ui2/activity/catalogue.dart`) ohne die Ausdauer-/Intervall-
/// Formate, die keine reine Kraftarbeit sind. Schlüssel wie `Activity.typeKey`
/// (Name klein, Leerzeichen als `_`).
const _kNotStrength = <String>{'hiit', 'circuit_training', 'crossfit'};

final Set<String> kStrengthWorkoutTypes = {
  for (final g in activityLibrary)
    if (g.name == 'Strength')
      for (final a in g.items)
        if (!_kNotStrength.contains(a.typeKey)) a.typeKey,
};

/// WHOOP-Namen, die ältere Importe roh gespeichert haben (der Import mappt sie
/// heute auf die Katalog-Schlüssel, `whoop_import.dart`, `_whoopActivityAliases`).
const _kLegacyStrengthAliases = <String>{
  'weightlifting',
  'strength_trainer',
  'functional_fitness',
};

/// Ob ein gespeicherter `sessions.type` als Krafttraining zählt.
bool isStrengthWorkoutType(String? type) {
  if (type == null) return false;
  final k = type.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  return kStrengthWorkoutTypes.contains(k) || _kLegacyStrengthAliases.contains(k);
}

/// Ein einzelner Faktor des Körperalters (K2, K3, K4).
class BodyAgeFactor {
  const BodyAgeFactor({
    required this.key,
    required this.labelDe,
    required this.labelEn,
    required this.value,
    required this.formattedValueDe,
    required this.formattedValueEn,
    required this.targetDe,
    required this.targetEn,
    required this.study,
    required this.leverDe,
    required this.leverEn,
    required this.relativeRisk,
    required this.yearsShift,
    required this.absent,
    double? rawYears,
    this.minYears = 0.0,
    this.evidenceDe = '',
    this.evidenceEn = '',
  }) : _rawYears = rawYears;

  final String key;
  final String labelDe, labelEn;
  final double? value;
  final String formattedValueDe, formattedValueEn;
  final String targetDe, targetEn;
  final String study;
  final String leverDe, leverEn;

  /// Relatives Risiko laut Näherungsformel (1,0 beim Referenzpunkt).
  final double relativeRisk;

  /// Beitrag in Jahren nach allen Kappungen (Faktor ±3, Summe), so wie er in die
  /// Summe eingeht und angezeigt wird.
  final double yearsShift;
  final bool absent;

  final double? _rawYears;

  /// Ergebnis der Umrechnung `ln(RR)/ln 2 × 8` vor jeder Kappung.
  double get rawYears => _rawYears ?? yearsShift;

  /// Beitrag, den der Faktor im besten Fall erreichen kann (Risiko am besten
  /// Wert der Näherung). Null oder negativ.
  final double minYears;

  /// Beleg-Status in einem Satz: was die Studie sagt, was unsere Annahme ist.
  final String evidenceDe, evidenceEn;

  /// Ob die Anzeige wegen Faktor- oder Summenkappung vom Rechenergebnis abweicht.
  bool get capped => !absent && (rawYears - yearsShift).abs() > 0.05;

  /// Hebel: wie viele Jahre dieser Faktor noch gutmachen könnte. Nicht der
  /// bereits erreichte Beitrag, sondern der verbesserbare Teil (Befund 3).
  double get potentialYears =>
      absent ? 0.0 : math.max(0.0, yearsShift - math.min(0.0, minYears));

  String label(bool de) => de ? labelDe : labelEn;
  String formattedValue(bool de) =>
      absent ? (de ? 'fehlt' : 'missing') : (de ? formattedValueDe : formattedValueEn);
  String target(bool de) => de ? targetDe : targetEn;
  String lever(bool de) => de ? leverDe : leverEn;
  String evidence(bool de) => de ? evidenceDe : evidenceEn;

  BodyAgeFactor withShift(double years) => BodyAgeFactor(
        key: key,
        labelDe: labelDe,
        labelEn: labelEn,
        value: value,
        formattedValueDe: formattedValueDe,
        formattedValueEn: formattedValueEn,
        targetDe: targetDe,
        targetEn: targetEn,
        study: study,
        leverDe: leverDe,
        leverEn: leverEn,
        relativeRisk: relativeRisk,
        yearsShift: years,
        absent: absent,
        rawYears: rawYears,
        minYears: minYears,
        evidenceDe: evidenceDe,
        evidenceEn: evidenceEn,
      );
}

/// Ergebnis der Körperalter-Berechnung (K1–K5).
class BodyAgeSnapshot {
  const BodyAgeSnapshot({
    required this.realAge,
    this.exactAge,
    required this.bodyAge,
    required this.diffYears,
    required this.dataDays,
    required this.factors,
    this.weekMonday,
    this.prevWeekDelta,
    this.paceOfAging,
    this.recent = const {},
    this.recentDiffYears,
    this.recentDays = 0,
  });

  /// Dieselben Faktoren, gerechnet aus nur den letzten sieben Tagen (Schlüssel
  /// wie in [factors]). Nicht Teil der Wochen-Momentaufnahme: sie rechnen bei
  /// jedem Laden neu. Leer bei weniger als [kBodyAgeRecentMinDays] Tagen mit Daten.
  final Map<String, BodyAgeFactor> recent;

  /// Gesamtabweichung in Jahren, wenn die letzten sieben Tage so weiterliefen.
  final double? recentDiffYears;

  /// Tage mit Daten in den letzten sieben Kalendertagen.
  final int recentDays;

  /// Kopie mit den 7-Tage-Werten aus [week] (Ergebnis von
  /// [BodyAgeCalculator.calculate] für die letzten sieben Tage).
  BodyAgeSnapshot withRecent(BodyAgeSnapshot week) => BodyAgeSnapshot(
        realAge: realAge,
        exactAge: exactAge,
        bodyAge: bodyAge,
        diffYears: diffYears,
        dataDays: dataDays,
        factors: factors,
        weekMonday: weekMonday,
        prevWeekDelta: prevWeekDelta,
        paceOfAging: paceOfAging,
        recent: {
          for (final f in week.factors)
            if (!f.absent) f.key: f,
        },
        recentDiffYears: week.hasFactors ? week.diffYears : null,
        recentDays: week.dataDays,
      );

  /// [withRecent], oder unverändert ohne 7-Tage-Ergebnis.
  BodyAgeSnapshot withRecentOrSelf(BodyAgeSnapshot? week) =>
      week == null ? this : withRecent(week);

  /// Chronologisches Alter aus dem Profil (Ganzzahl). Null, wenn im Profil kein Alter
  /// hinterlegt ist (Randfall Spec).
  final int? realAge;

  /// Exaktes chronologisches Alter (Dezimalwert) berechnet aus dem Geburtsdatum,
  /// z.B. 18,7 Jahre. Null, wenn nur das ganzzahlige Alter vorliegt.
  final double? exactAge;

  /// Exaktes oder ganzzahliges chronologisches Alter als Referenz.
  double? get chronologicalAge => exactAge ?? realAge?.toDouble();

  /// Geschätztes Körperalter (`chronologicalAge + diffYears`). Null ohne Profil-Alter.
  final double? bodyAge;

  /// Gesamtabweichung in Jahren (auf ±10,0 Jahre begrenzt).
  final double diffYears;

  /// Anzahl Tage mit Daten in den letzten 30 Kalendertagen.
  final int dataDays;

  /// Die sieben Faktoren, sortiert nach dem größten Hebel (verbesserbarer
  /// Beitrag), fehlende Faktoren am Ende (K2, K4).
  final List<BodyAgeFactor> factors;

  /// Der Montag (`YYYY-MM-DD`) der aktuellen Berechnungs-Woche (K5).
  final String? weekMonday;

  /// Veränderung gegenüber der Vorwoche in Jahren (K5), sofern vorhanden.
  final double? prevWeekDelta;

  /// Alterungstempo als Multiplikator: `2^(diffYears / 8.0)` (K7). Das ist das
  /// relative Sterberisiko gegenüber „normal“, kein gemessenes Altern.
  final double? paceOfAging;

  /// Untere Grenze des Zielkorridors, nur sichtbar mit [kBodyAgeTargetCorridor].
  double get optimalAgeMin {
    final c = chronologicalAge ?? 30.0;
    return math.max(10.0, c - 5.5);
  }

  /// Obere Grenze des Zielkorridors, nur sichtbar mit [kBodyAgeTargetCorridor].
  double get optimalAgeMax {
    final c = chronologicalAge ?? 30.0;
    return math.max(10.0, c - 2.0);
  }

  /// Ob das Körperalter im Zielkorridor liegt (nur mit [kBodyAgeTargetCorridor]).
  bool get isInOptimalRange {
    if (!kBodyAgeTargetCorridor || bodyAge == null) return false;
    return bodyAge! <= optimalAgeMax;
  }

  bool get hasAge => realAge != null && plausibleAgeYears(realAge!);
  bool get hasEnoughDays => dataDays >= kBodyAgeMinDays;

  /// Mindestens ein Faktor hat einen Messwert. Ohne ist „18,0 / ±0,0“ kein Ergebnis.
  bool get hasFactors => factors.any((f) => !f.absent);
  bool get ready => hasAge && hasEnoughDays && hasFactors && bodyAge != null;
  int get missingDays =>
      dataDays >= kBodyAgeMinDays ? 0 : (kBodyAgeMinDays - dataDays);

  /// Der Faktor mit dem größten verbesserbaren Beitrag, sonst null (Befund 3).
  BodyAgeFactor? get topLever {
    BodyAgeFactor? best;
    for (final f in factors) {
      if (f.absent || f.potentialYears < 0.05) continue;
      if (best == null || f.potentialYears > best.potentialYears) best = f;
    }
    return best;
  }
}

// ── Faktor-Formeln (Herleitung und Beleg-Status: architektur.md) ───────────

typedef _Rr = double Function(double v);

double _clampD(double v, double lo, double hi) => v.clamp(lo, hi).toDouble();

// Schlaf: flach zwischen 7 und 8 Std. (Referenzbereich), darunter und darüber
// lineares Ansteigen bis zu den Cappuccio-Werten 1,12 (kurz) und 1,30 (lang).
// Der Ort, an dem der Studienwert gilt (5,5 bzw. 10 Std.), ist unsere Annahme.
double _rrSleep(double h) {
  final rr = h < 7.0 ? 1.0 + 0.08 * (7.0 - h) : (h > 8.0 ? 1.0 + 0.15 * (h - 8.0) : 1.0);
  return _clampD(rr, 1.0, 1.35);
}

double _rrSri(double s) => _clampD(1.0 - (s - 70.0) * 0.006, 0.85, 1.20);

double _rrRhr(double r) => _clampD(1.0 + (r - 58.0) * 0.014, 0.86, 1.40);

// Schritte: Bonus nur bis 10 000 (Plateau, Paluch), darunter linear.
double _rrSteps(double s) =>
    _clampD(1.0 - ((_clampD(s, 1500.0, 10000.0) - 7500.0) / 1000.0) * 0.045, 0.85, 1.35);

double _rrModerate(double m) =>
    _clampD(1.0 - ((_clampD(m, 0.0, 300.0) - 135.0) / 150.0) * 0.14, 0.80, 1.25);

double _rrIntensive(double m) =>
    _clampD(1.0 - ((_clampD(m, 0.0, 150.0) - 25.0) / 75.0) * 0.12, 0.80, 1.20);

// Kraft: Momma vergleicht gegen 0 Min. (J-Form, größter Nutzen bei 30–60 Min.).
// g(0)=1,00, g(30..60)=0,85; relativ zum Referenzpunkt 45 Min. (eigene Annahme).
double _gStrength(double m) => 1.0 - 0.15 * math.min(_clampD(m, 0.0, 60.0), 30.0) / 30.0;
double _rrStrength(double m) => _clampD(_gStrength(m) / _gStrength(45.0), 0.85, 1.20);

class _Spec {
  const _Spec({
    required this.key,
    required this.labelDe,
    required this.labelEn,
    required this.rr,
    required this.bestValue,
    required this.valid,
    required this.fmtDe,
    required this.fmtEn,
    required this.targetDe,
    required this.targetEn,
    required this.study,
    required this.evidenceDe,
    required this.evidenceEn,
    required this.lever,
  });

  final String key, labelDe, labelEn, targetDe, targetEn, study;
  final String evidenceDe, evidenceEn;
  final _Rr rr;

  /// Wert, bei dem das Risiko am niedrigsten ist.
  final double bestValue;
  final bool Function(double v) valid;
  final String Function(double v) fmtDe, fmtEn;

  /// Hebel-Satz, aus der Formel gerechnet: (de) -> Text.
  final String Function(bool de) lever;
}

String _fmtDec(double v, int digits, bool de) {
  final s = v.toStringAsFixed(digits);
  return de ? s.replaceAll('.', ',') : s;
}

double _years(double rr) => BodyAgeCalculator.riskToYears(rr);

/// Jahre-Differenz beim Schritt von [from] nach [to] (negativ = jünger).
double _leverYears(_Rr rr, double from, double to) => _years(rr(to)) - _years(rr(from));

String _leverFmt(double y, bool de) => _fmtDec(y.abs(), 1, de);

final Map<String, _Spec> _specs = {
  'sleep_duration': _Spec(
    key: 'sleep_duration',
    labelDe: 'Schlafdauer',
    labelEn: 'Sleep duration',
    rr: _rrSleep,
    bestValue: 7.5,
    valid: (v) => v > 0,
    fmtDe: (v) => '${_fmtDec(v, 1, true)} Std.',
    fmtEn: (v) => '${_fmtDec(v, 1, false)} h',
    targetDe: '7,0–8,0 Std.',
    targetEn: '7.0–8.0 h',
    study: 'Cappuccio et al. (2010), Sleep',
    evidenceDe: 'Studie: U-förmig, kurzer Schlaf RR 1,12, langer Schlaf RR 1,30 (16 Studien). Die Orte, an denen wir diese Werte ansetzen (5,5 und 10 Std.), und die Gerade dazwischen sind unsere Annahme.',
    evidenceEn: 'Study: U-shaped, short sleep RR 1.12, long sleep RR 1.30 (16 studies). Where we place these values (5.5 and 10 h) and the line between them are our assumption.',
    lever: (de) {
      final a = _leverFmt(_leverYears(_rrSleep, 6.0, 7.0), de);
      final b = _leverFmt(_leverYears(_rrSleep, 9.0, 8.0), de);
      return de
          ? 'Zwischen 7 und 8 Std. bleibt es beim Referenzwert. Von 6 auf 7 Std. verschiebt um ca. $a Jahre, von 9 auf 8 Std. um ca. $b Jahre.'
          : 'Between 7 and 8 h stays at the reference. From 6 to 7 h shifts by approx. $a years, from 9 to 8 h by approx. $b years.';
    },
  ),
  'sleep_regularity': _Spec(
    key: 'sleep_regularity',
    labelDe: 'Schlafregelmäßigkeit',
    labelEn: 'Sleep regularity',
    rr: _rrSri,
    bestValue: 100.0,
    valid: (v) => true,
    fmtDe: (v) => '${v.round()} SRI',
    fmtEn: (v) => '${v.round()} SRI',
    targetDe: 'ab 75 SRI',
    targetEn: '75+ SRI',
    study: 'Windred et al. (2024), Sleep',
    evidenceDe: 'Studie: Die vier regelmäßigeren Fünftel hatten 20–48 % weniger Gesamtsterblichkeit als das unregelmäßigste. Steigung je Punkt und Referenzwert 70 sind unsere Annahme; die Takt-Skala und die der Studie sind nicht dieselbe.',
    evidenceEn: 'Study: The four more regular fifths had 20–48% lower all-cause mortality than the most irregular. Slope per point and reference value 70 are our assumption; Takt\'s scale and the study\'s are not the same.',
    lever: (de) {
      final a = _leverFmt(_leverYears(_rrSri, 70.0, 80.0), de);
      return de
          ? '+10 Punkte Regelmäßigkeit (zwischen 70 und 95) senken um ca. $a Jahre.'
          : '+10 regularity points (between 70 and 95) lower by approx. $a years.';
    },
  ),
  'resting_hr': _Spec(
    key: 'resting_hr',
    labelDe: 'Ruhepuls',
    labelEn: 'Resting heart rate',
    rr: _rrRhr,
    bestValue: 40.0,
    valid: (v) => v > 0,
    fmtDe: (v) => '${v.round()} bpm',
    fmtEn: (v) => '${v.round()} bpm',
    targetDe: 'unter 58 bpm',
    targetEn: 'under 58 bpm',
    study: 'Jensen et al. (2013), Heart',
    evidenceDe: 'Studie: +16 % Gesamtsterblichkeit je 10 bpm, nur Männer. Wir rechnen mit 1,4 % je bpm. Der Referenzwert 58 bpm ist unsere Annahme.',
    evidenceEn: 'Study: +16% all-cause mortality per 10 bpm, men only. We use 1.4% per bpm. The reference value 58 bpm is our assumption.',
    lever: (de) {
      final a = _leverFmt(_leverYears(_rrRhr, 58.0, 52.0), de);
      return de
          ? '6 bpm niedrigerer Ruhepuls (zwischen 58 und 48 bpm) senkt um ca. $a Jahre.'
          : '6 bpm lower resting HR (between 58 and 48 bpm) lowers by approx. $a years.';
    },
  ),
  'steps': _Spec(
    key: 'steps',
    labelDe: 'Schritte',
    labelEn: 'Steps',
    rr: _rrSteps,
    bestValue: 10000.0,
    valid: (v) => v > 0,
    fmtDe: (v) => '${v.round()} / Tag',
    fmtEn: (v) => '${v.round()} / day',
    targetDe: 'ab 8000 / Tag',
    targetEn: '8000+ / day',
    study: 'Paluch et al. (2022), Lancet Public Health',
    evidenceDe: 'Studie: weniger Sterblichkeit mit mehr Schritten. Ein Plateau bei 8000–10 000 für unter 60-Jährige wird berichtet (laut Pressebericht, nicht im Papier geprüft). Wir zählen nur bis 10 000; Steigung und Referenzwert 7500 sind unsere Annahme.',
    evidenceEn: 'Study: lower mortality with more steps. A plateau at 8,000–10,000 for under-60s is reported (per press coverage, not checked in the paper). We count only up to 10,000; slope and reference value 7,500 are our assumption.',
    lever: (de) {
      final a = _leverFmt(_leverYears(_rrSteps, 7500.0, 9500.0), de);
      return de
          ? '+2000 Schritte pro Tag (zwischen 7500 und 10 000) senken um ca. $a Jahre. Darüber zählt nichts mehr.'
          : '+2000 steps per day (between 7,500 and 10,000) lower by approx. $a years. Nothing more counts above that.';
    },
  ),
  'moderate_activity': _Spec(
    key: 'moderate_activity',
    labelDe: 'Moderate Bewegung',
    labelEn: 'Moderate activity',
    rr: _rrModerate,
    bestValue: 300.0,
    valid: (v) => true,
    fmtDe: (v) => '${v.round()} Min./Wo.',
    fmtEn: (v) => '${v.round()} min/wk',
    targetDe: 'ab 150 Min./Wo.',
    targetEn: '150+ min/wk',
    study: 'Lee et al. (2022), Circulation',
    evidenceDe: 'Studie: 150–299 Min. moderate Freizeitaktivität pro Woche, 19–25 % weniger Sterblichkeit (Fragebogen, keine Herzfrequenzzonen). Dass Zone 1–3 „moderat“ ist, ist unsere Zuordnung, nicht aus der Studie.',
    evidenceEn: 'Study: 150–299 min moderate leisure activity per week, 19–25% lower mortality (questionnaire, no heart rate zones). Treating zones 1–3 as “moderate” is our mapping, not from the study.',
    lever: (de) {
      final a = _leverFmt(_leverYears(_rrModerate, 135.0, 225.0), de);
      return de
          ? '+90 Min./Woche in Zone 1–3 (zwischen 135 und 300) senken um ca. $a Jahre.'
          : '+90 min/week in zones 1–3 (between 135 and 300) lower by approx. $a years.';
    },
  ),
  'intensive_activity': _Spec(
    key: 'intensive_activity',
    labelDe: 'Intensive Bewegung',
    labelEn: 'Vigorous activity',
    rr: _rrIntensive,
    bestValue: 150.0,
    valid: (v) => true,
    fmtDe: (v) => '${v.round()} Min./Wo.',
    fmtEn: (v) => '${v.round()} min/wk',
    targetDe: 'ab 45 Min./Wo.',
    targetEn: '45+ min/wk',
    study: 'Lee et al. (2022), Circulation',
    evidenceDe: 'Studie: 75–149 Min. intensive Freizeitaktivität pro Woche, HR 0,81 für Gesamtsterblichkeit (Fragebogen, keine Herzfrequenzzonen). Dass Zone 4–5 „intensiv“ ist, ist unsere Zuordnung, nicht aus der Studie.',
    evidenceEn: 'Study: 75–149 min vigorous leisure activity per week, HR 0.81 for all-cause mortality (questionnaire, no heart rate zones). Treating zones 4–5 as “vigorous” is our mapping, not from the study.',
    lever: (de) {
      final a = _leverFmt(_leverYears(_rrIntensive, 25.0, 75.0), de);
      return de
          ? '+50 Min./Woche in Zone 4–5 (zwischen 25 und 150) senken um ca. $a Jahre.'
          : '+50 min/week in zones 4–5 (between 25 and 150) lower by approx. $a years.';
    },
  ),
  'strength': _Spec(
    key: 'strength',
    labelDe: 'Krafttraining',
    labelEn: 'Strength training',
    rr: _rrStrength,
    bestValue: 45.0,
    valid: (v) => true,
    fmtDe: (v) => '${v.round()} Min./Wo.',
    fmtEn: (v) => '${v.round()} min/wk',
    targetDe: '30–60 Min./Wo.',
    targetEn: '30–60 min/wk',
    study: 'Momma et al. (2022), BJSM',
    evidenceDe: 'Studie: 10–17 % niedrigeres Risiko, J-Form, größter Nutzen bei 30–60 Min./Woche. Dass wir den Nutzen gegen 0 Min. ansetzen und der Referenzpunkt 45 Min. sind eigene Annahmen, nicht aus der Studie.',
    evidenceEn: 'Study: 10–17% lower risk, J-shaped, greatest benefit at 30–60 min/week. Anchoring the benefit against 0 min and the reference point of 45 min are our own assumptions, not from the study.',
    lever: (de) {
      final a = _leverFmt(_leverYears(_rrStrength, 0.0, 30.0), de);
      return de
          ? 'Von 0 auf 30 Min./Woche senkt um ca. $a Jahre. Zwischen 30 und 60 Min. bleibt es beim Referenzwert.'
          : 'From 0 to 30 min/week lowers by approx. $a years. Between 30 and 60 min it stays at the reference.';
    },
  ),
};

/// Reihenfolge der sieben Faktoren (stabil, auch für die Speicherung).
const kBodyAgeFactorKeys = <String>[
  'sleep_duration',
  'sleep_regularity',
  'resting_hr',
  'steps',
  'moderate_activity',
  'intensive_activity',
  'strength',
];

class BodyAgeCalculator {
  static const double factorCap = 3.0;
  static const double totalCap = 10.0;

  /// Rechnet ein relatives Sterberisiko über die 8-Jahres-Verdopplungsregel in
  /// Lebensjahre um: `Jahre = ln(Risiko) / ln(2) * 8`.
  static double riskToYears(double relativeRisk) {
    if (!relativeRisk.isFinite || relativeRisk <= 0) return 0.0;
    return 8.0 * math.log(relativeRisk) / math.ln2;
  }

  static double _cap(double v, double limit) => v.clamp(-limit, limit).toDouble();

  /// Ein Faktor aus Schlüssel und Messwert; Beitrag noch ohne Summenkappung
  /// (`yearsShift` = Faktorkappung ±3). Null bei unbekanntem Schlüssel.
  static BodyAgeFactor? factorFor(String key, double? value) {
    final s = _specs[key];
    if (s == null) return null;
    final absent = value == null || !value.isFinite || !s.valid(value);
    final rr = absent ? 1.0 : s.rr(value);
    final raw = absent ? 0.0 : riskToYears(rr);
    return BodyAgeFactor(
      key: key,
      labelDe: s.labelDe,
      labelEn: s.labelEn,
      value: absent ? null : value,
      formattedValueDe: absent ? 'fehlt' : s.fmtDe(value),
      formattedValueEn: absent ? 'missing' : s.fmtEn(value),
      targetDe: s.targetDe,
      targetEn: s.targetEn,
      study: s.study,
      leverDe: s.lever(true),
      leverEn: s.lever(false),
      relativeRisk: rr,
      yearsShift: absent ? 0.0 : _cap(raw, factorCap),
      absent: absent,
      rawYears: raw,
      minYears: riskToYears(s.rr(s.bestValue)),
      evidenceDe: s.evidenceDe,
      evidenceEn: s.evidenceEn,
    );
  }

  /// Sortierung nach dem größten Hebel (verbesserbarer Beitrag), dann nach
  /// Beitrag; fehlende Faktoren am Ende (K2, K4).
  static int _byLever(BodyAgeFactor a, BodyAgeFactor b) {
    if (a.absent != b.absent) return a.absent ? 1 : -1;
    final c = b.potentialYears.compareTo(a.potentialYears);
    if (c != 0) return c;
    final d = b.yearsShift.abs().compareTo(a.yearsShift.abs());
    if (d != 0) return d;
    return kBodyAgeFactorKeys.indexOf(a.key).compareTo(kBodyAgeFactorKeys.indexOf(b.key));
  }

  static List<BodyAgeFactor> sortFactors(List<BodyAgeFactor> f) =>
      [...f]..sort(_byLever);

  /// Berechnet das Körperalter und alle sieben Faktoren aus den 30-Tage-Werten.
  static BodyAgeSnapshot calculate({
    required int? realAge,
    double? exactAge,
    required int dataDays,
    double? avgSleepHours,
    double? avgSri,
    double? avgRhr,
    double? avgSteps,
    double? moderateMinPerWeek,
    double? intensiveMinPerWeek,
    double? strengthMinPerWeek,
    String? weekMonday,
    double? prevWeekDelta,
  }) {
    final values = <String, double?>{
      'sleep_duration': avgSleepHours,
      'sleep_regularity': avgSri,
      'resting_hr': avgRhr,
      'steps': avgSteps,
      'moderate_activity': moderateMinPerWeek,
      'intensive_activity': intensiveMinPerWeek,
      'strength': strengthMinPerWeek,
    };
    final raw = [
      for (final k in kBodyAgeFactorKeys) factorFor(k, values[k])!,
    ];

    final validAge = (realAge != null && plausibleAgeYears(realAge)) ? realAge : null;
    final validExactAge = (exactAge != null &&
            exactAge.isFinite &&
            plausibleAgeYears(exactAge.round()))
        ? exactAge
        : null;
    final baseAge = validExactAge ?? validAge?.toDouble();

    // Summenkappung: ±10 Jahre und so, dass das Körperalter zwischen 10 und 130
    // bleibt. Dann ist Körperalter = Alter + Abweichung ohne weiteres Klemmen.
    var lo = -totalCap, hi = totalCap;
    if (baseAge != null) {
      lo = math.min(0.0, math.max(lo, _kMinBodyAge - baseAge));
      hi = math.max(0.0, math.min(hi, _kMaxBodyAge - baseAge));
    }
    final uncappedSum = raw.fold<double>(0.0, (s, f) => s + f.yearsShift);
    final cappedSum = uncappedSum.clamp(lo, hi).toDouble();
    final scale = (uncappedSum.abs() > 1e-9 && cappedSum != uncappedSum)
        ? (cappedSum / uncappedSum)
        : 1.0;

    final factors = sortFactors([
      for (final f in raw) f.absent ? f : f.withShift(f.yearsShift * scale),
    ]);

    final hasFactors = raw.any((f) => !f.absent);
    final bodyAge = baseAge == null ? null : baseAge + cappedSum;

    // K7: Alterungstempo nach der inversen Verdopplungsregel: 2^(diff / 8).
    final pace = math.pow(2.0, cappedSum / 8.0).toDouble();

    return BodyAgeSnapshot(
      realAge: validAge,
      exactAge: validExactAge,
      bodyAge: bodyAge,
      diffYears: cappedSum,
      dataDays: dataDays,
      factors: factors,
      weekMonday: weekMonday,
      prevWeekDelta: prevWeekDelta,
      // Ohne einen einzigen Messwert gibt es kein Tempo.
      paceOfAging: hasFactors ? pace : null,
    );
  }
}

/// Montag (`YYYY-MM-DD`) der Woche, in der [d] liegt (K5).
String mondayOfWeek(DateTime d) {
  final m = DateTime(d.year, d.month, d.day - (d.weekday - 1));
  return dayLabelOf(m);
}

double? _meanInWindow(List<ChartPoint> pts, int cutoffSec) {
  var sum = 0.0;
  var n = 0;
  for (final p in pts) {
    if (p.t >= cutoffSec && p.v.isFinite) {
      sum += p.v;
      n++;
    }
  }
  return n == 0 ? null : sum / n;
}

double? _sriFromInsights(Map<String, dynamic> insights, String fromDay) {
  final reg = envValue(insights['regularity']);
  if (reg == null) return null;
  final pairs = reg['pairs'];
  if (pairs is List && pairs.isNotEmpty) {
    var sum = 0.0;
    var n = 0;
    for (final p in pairs) {
      if (p is Map && p['date'] != null && p['sri'] is num) {
        final d = p['date'].toString();
        final v = (p['sri'] as num).toDouble();
        if (d.compareTo(fromDay) >= 0 && v.isFinite) {
          sum += v;
          n++;
        }
      }
    }
    if (n > 0) return sum / n;
  }
  final sri = reg['sri'];
  return sri is num && sri.isFinite ? sri.toDouble() : null;
}

// ── Wochen-Momentaufnahme (K5) ──────────────────────────────────────────────
//
// Die ganze Momentaufnahme (Kopf, Faktorenliste, Summe, Tempo, exaktes Alter)
// wird je Woche einmal gerechnet und in `takt.body_age.weeks.v1` abgelegt. Ohne
// Hintergrunddienst geht das nicht am Montag selbst, sondern beim ersten Öffnen
// der Woche. Bis zur nächsten Woche ändert sich nichts daran.

final _dayLabelRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
const _kKeepWeeks = 26;

bool _okNum(Object? v, double lo, double hi) =>
    v is num && v.isFinite && v >= lo && v <= hi;

Map<String, dynamic> _snapshotToJson(BodyAgeSnapshot s) => {
      'diff': s.diffYears,
      'real': s.realAge,
      'exact': s.exactAge,
      'days': s.dataDays,
      'f': [
        for (final f in s.factors) {'k': f.key, 'v': f.value, 'y': f.yearsShift},
      ],
    };

/// Liest eine gespeicherte Momentaufnahme. Null bei jeder Unstimmigkeit.
BodyAgeSnapshot? _snapshotFromJson(
  Object? raw, {
  required String monday,
  double? prevWeekDelta,
}) {
  if (raw is! Map) return null;
  if (!_okNum(raw['diff'], -BodyAgeCalculator.totalCap, BodyAgeCalculator.totalCap)) {
    return null;
  }
  final diff = (raw['diff'] as num).toDouble();
  final real = raw['real'];
  if (real is! int || !plausibleAgeYears(real)) return null;
  final exactRaw = raw['exact'];
  double? exact;
  if (exactRaw != null) {
    if (!_okNum(exactRaw, 1, 130)) return null;
    exact = (exactRaw as num).toDouble();
  }
  final days = raw['days'];
  if (days is! int || days < 0 || days > 400) return null;
  final fs = raw['f'];
  if (fs is! List || fs.length != kBodyAgeFactorKeys.length) return null;

  final byKey = <String, BodyAgeFactor>{};
  var sum = 0.0;
  for (final e in fs) {
    if (e is! Map) return null;
    final k = e['k'];
    if (k is! String || byKey.containsKey(k)) return null;
    final v = e['v'];
    if (v != null && !_okNum(v, 0, 1e6)) return null;
    if (!_okNum(e['y'], -BodyAgeCalculator.factorCap, BodyAgeCalculator.factorCap)) {
      return null;
    }
    final f = BodyAgeCalculator.factorFor(k, (v as num?)?.toDouble());
    if (f == null) return null;
    final y = (e['y'] as num).toDouble();
    if (f.absent && y != 0.0) return null;
    byKey[k] = f.absent ? f : f.withShift(y);
    sum += y;
  }
  if (byKey.length != kBodyAgeFactorKeys.length) return null;
  if ((sum - diff).abs() > 0.05) return null;
  if (!byKey.values.any((f) => !f.absent)) return null;

  final base = exact ?? real.toDouble();
  final body = base + diff;
  if (body < _kMinBodyAge - 1e-9 || body > _kMaxBodyAge + 1e-9) return null;

  return BodyAgeSnapshot(
    realAge: real,
    exactAge: exact,
    bodyAge: body,
    diffYears: diff,
    dataDays: days,
    factors: BodyAgeCalculator.sortFactors(byKey.values.toList()),
    weekMonday: monday,
    prevWeekDelta: prevWeekDelta,
    paceOfAging: math.pow(2.0, diff / 8.0).toDouble(),
  );
}

/// Diff einer gespeicherten Woche, auch aus dem alten Format (nur die Zahl).
double? _storedDiff(Object? raw) {
  final d = raw is Map ? raw['diff'] : raw;
  return _okNum(d, -BodyAgeCalculator.totalCap, BodyAgeCalculator.totalCap)
      ? (d as num).toDouble()
      : null;
}

/// Alle gültigen Wochen; ein kaputter String oder kaputte Einträge ergeben eine
/// leere bzw. kürzere Map (und werden beim nächsten Speichern überschrieben).
Map<String, Object?> _readWeeks(SharedPreferences prefs) {
  final out = <String, Object?>{};
  try {
    final raw = prefs.getString(kBodyAgeWeeksKey);
    if (raw == null || raw.isEmpty) return out;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return out;
    for (final e in decoded.entries) {
      final k = e.key.toString();
      if (_dayLabelRe.hasMatch(k)) out[k] = e.value;
    }
  } catch (_) {}
  return out;
}

Future<void> _writeWeeks(SharedPreferences prefs, Map<String, Object?> weeks) async {
  final keys = weeks.keys.toList()..sort();
  final keep = keys.length > _kKeepWeeks ? keys.sublist(keys.length - _kKeepWeeks) : keys;
  await prefs.setString(kBodyAgeWeeksKey, jsonEncode({for (final k in keep) k: weeks[k]}));
}

double? _numOf(Object? v) {
  if (v is num) return v.isFinite ? v.toDouble() : null;
  if (v is String) {
    final d = double.tryParse(v.trim());
    return d != null && d.isFinite ? d : null;
  }
  return null;
}

/// Die Faktoren aus nur den letzten sieben Kalendertagen, als eigenes Ergebnis
/// der Berechnung. Null bei weniger als [kBodyAgeRecentMinDays] Tagen mit Daten.
/// Wird bei jedem Laden neu gerechnet und nie gespeichert: Die Wochensperre
/// gilt für die 30 Tage, nicht für diesen Blick auf die jüngste Woche.
Future<BodyAgeSnapshot?> _recentWeek(
  LocalRepository repo, {
  required int realAge,
  required double? exactAge,
  required List<String> allDays,
  required DateTime clock,
  required Map<String, dynamic> insights,
  required Future<List<ChartPoint>> Function(String) series,
}) async {
  final fromDt = DateTime(clock.year, clock.month, clock.day - 6);
  final fromDay = dayLabelOf(fromDt);
  final cutoffSec = fromDt.millisecondsSinceEpoch ~/ 1000;
  final days = [
    for (final d in allDays)
      if (d.compareTo(fromDay) >= 0) d,
  ];
  if (days.length < kBodyAgeRecentMinDays) return null;

  final sleepMin = _meanInWindow(await series('sleep'), cutoffSec);
  final rhr = _meanInWindow(await series('resting_hr'), cutoffSec);
  final steps = _meanInWindow(await series('steps'), cutoffSec);
  final sri = _sriPairsSince(insights, fromDay);

  var zoneDays = 0, modSum = 0, intSum = 0;
  for (final d in days) {
    try {
      final z = (await repo.getDayStrain(d))['zones'];
      if (z is! Map) continue;
      final v = [for (var i = 1; i <= 5; i++) (z['z$i'] as num?)?.toInt()];
      if (v.every((e) => e == null)) continue;
      zoneDays++;
      modSum += (v[0] ?? 0) + (v[1] ?? 0) + (v[2] ?? 0);
      intSum += (v[3] ?? 0) + (v[4] ?? 0);
    } catch (_) {}
  }

  double? strength;
  try {
    final list = (await repo.getWorkouts(range: 'month'))['workouts'];
    if (list is List) {
      var min = 0.0;
      for (final w in list) {
        if (w is! Map) continue;
        final ts = (w['start_ts'] as num?)?.toInt();
        if (ts != null && ts < cutoffSec) continue;
        if (!isStrengthWorkoutType((w['type'] ?? w['sport'] ?? '').toString())) continue;
        final dur = (w['duration_min'] as num?)?.toDouble() ??
            (((w['end_ts'] as num?) != null && ts != null)
                ? ((w['end_ts'] as num).toInt() - ts) / 60.0
                : 0.0);
        if (dur > 0 && dur.isFinite) min += dur;
      }
      // Sieben Tage sind eine Woche: Minuten pro Woche = Summe.
      strength = min;
    }
  } catch (_) {}

  return BodyAgeCalculator.calculate(
    realAge: realAge,
    exactAge: exactAge,
    dataDays: days.length,
    avgSleepHours: sleepMin == null ? null : sleepMin / 60.0,
    avgSri: sri,
    avgRhr: rhr,
    avgSteps: steps,
    moderateMinPerWeek: zoneDays > 0 ? modSum / zoneDays * 7.0 : null,
    intensiveMinPerWeek: zoneDays > 0 ? intSum / zoneDays * 7.0 : null,
    strengthMinPerWeek: strength,
  );
}

/// SRI nur aus Paaren ab [fromDay]. Anders als [_sriFromInsights] ohne den
/// Gesamtwert als Rückfall: Der wäre der 30-Tage-Wert und kein 7-Tage-Wert.
double? _sriPairsSince(Map<String, dynamic> insights, String fromDay) {
  final reg = envValue(insights['regularity']);
  final pairs = reg?['pairs'];
  if (pairs is! List) return null;
  var sum = 0.0;
  var n = 0;
  for (final p in pairs) {
    if (p is Map && p['date'] != null && p['sri'] is num) {
      final v = (p['sri'] as num).toDouble();
      if (p['date'].toString().compareTo(fromDay) >= 0 && v.isFinite) {
        sum += v;
        n++;
      }
    }
  }
  return n == 0 ? null : sum / n;
}

/// Liest die 30-Tage-Werte aus [repo] und berechnet das Körperalter samt
/// Wochen-Momentaufnahme (K5). Falsche Typen im Profil werden abgefangen.
Future<BodyAgeSnapshot> loadBodyAge(
  LocalRepository repo, {
  Map<String, dynamic>? profile,
  Map<String, dynamic>? insights,
  Map<String, List<ChartPoint>>? charts,
  List<String>? availableDays,
  DateTime? now,
}) async {
  final clock = now ?? DateTime.now();
  final fromDt = DateTime(clock.year, clock.month, clock.day - 29);
  final fromDay = dayLabelOf(fromDt);
  final cutoffSec = fromDt.millisecondsSinceEpoch ~/ 1000;

  final prof = profile ?? await repo.getProfile();
  final allDays = availableDays ?? await repo.availableDays();
  final recentDays = [
    for (final d in allDays)
      if (d.compareTo(fromDay) >= 0) d,
  ];

  // Alter: `age` darf Zahl oder Zahl-Text sein, `birthdate` nur ein Datums-Text.
  final birthRaw = prof['birthdate'];
  final birthdate = birthRaw is String && birthRaw.isNotEmpty
      ? DateTime.tryParse(birthRaw)
      : null;
  double? exactAge;
  if (birthdate != null) {
    final days = clock.difference(birthdate).inDays;
    if (days > 0) exactAge = days / 365.2425;
  }
  final ageNum = _numOf(prof['age']);
  final realAge = ageNum?.round() ?? exactAge?.floor();

  final monday = mondayOfWeek(clock);
  final prevMonday = mondayOfWeek(DateTime(clock.year, clock.month, clock.day - 7));

  // Ohne gültiges Alter gibt es nichts zu rechnen oder zu sperren.
  if (realAge == null || !plausibleAgeYears(realAge)) {
    return BodyAgeCalculator.calculate(
      realAge: null,
      dataDays: recentDays.length,
      weekMonday: monday,
    );
  }

  final ins = insights ?? await repo.getInsights();

  Future<List<ChartPoint>> series(String k) async {
    if (charts != null && charts.containsKey(k)) return charts[k]!;
    try {
      return pointsOf(await repo.getChart(k));
    } catch (_) {
      return const [];
    }
  }

  // 7 Tage: immer frisch, auch wenn die Woche gesperrt ist.
  final week7 = await _recentWeek(
    repo,
    realAge: realAge,
    exactAge: exactAge,
    allDays: allDays,
    clock: clock,
    insights: ins,
    series: series,
  );

  // K5: Liegt für diese Woche eine gültige Momentaufnahme vor, gilt sie unverändert.
  SharedPreferences? prefs;
  var weeks = <String, Object?>{};
  try {
    prefs = await SharedPreferences.getInstance();
    weeks = _readWeeks(prefs);
  } catch (_) {
    prefs = null;
  }
  final prevDiff = _storedDiff(weeks[prevMonday]);
  final stored = _snapshotFromJson(weeks[monday], monday: monday);
  if (stored != null) {
    final lockedDiff = stored.diffYears;
    return BodyAgeSnapshot(
      realAge: stored.realAge,
      exactAge: stored.exactAge,
      bodyAge: stored.bodyAge,
      diffYears: lockedDiff,
      dataDays: stored.dataDays,
      factors: stored.factors,
      weekMonday: monday,
      prevWeekDelta: prevDiff == null ? null : lockedDiff - prevDiff,
      paceOfAging: stored.paceOfAging,
    ).withRecentOrSelf(week7);
  }

  final sleepPts = await series('sleep');
  final rhrPts = await series('resting_hr');
  final stepsPts = await series('steps');

  final avgSleepMin = _meanInWindow(sleepPts, cutoffSec);
  final avgSleepHours = avgSleepMin == null ? null : avgSleepMin / 60.0;
  final avgRhr = _meanInWindow(rhrPts, cutoffSec);
  final avgSteps = _meanInWindow(stepsPts, cutoffSec);
  final avgSri = _sriFromInsights(ins, fromDay);

  // Zonen-Minuten (Zone 1–3, Zone 4–5) aus den abgeleiteten Tagen der letzten 30
  // Tage. Das sind Minuten im Herzfrequenzbereich, keine Fragebogen-Aktivität
  // wie in der Lee-Studie (eigene Zuordnung, siehe architektur.md).
  double? modMinPerWeek;
  double? intMinPerWeek;
  var zoneDays = 0;
  var modSum = 0;
  var intSum = 0;
  for (final d in recentDays) {
    try {
      final s = await repo.getDayStrain(d);
      final z = s['zones'];
      if (z is Map) {
        final z1 = (z['z1'] as num?)?.toInt();
        final z2 = (z['z2'] as num?)?.toInt();
        final z3 = (z['z3'] as num?)?.toInt();
        final z4 = (z['z4'] as num?)?.toInt();
        final z5 = (z['z5'] as num?)?.toInt();
        if (z1 != null || z2 != null || z3 != null || z4 != null || z5 != null) {
          zoneDays++;
          modSum += (z1 ?? 0) + (z2 ?? 0) + (z3 ?? 0);
          intSum += (z4 ?? 0) + (z5 ?? 0);
        }
      }
    } catch (_) {}
  }
  if (zoneDays > 0) {
    modMinPerWeek = modSum / zoneDays * 7.0;
    intMinPerWeek = intSum / zoneDays * 7.0;
  }

  // Krafttraining-Minuten pro Woche aus den Trainings der letzten 30 Tage,
  // geteilt durch die Kalenderspanne vom ersten Tag mit Daten bis heute (14 bis
  // 30 Tage), nicht durch die Zahl der Tage mit Daten.
  double? strengthMinPerWeek;
  try {
    final wMap = await repo.getWorkouts(range: 'month');
    final list = wMap['workouts'];
    if (list is List) {
      var strMin = 0.0;
      for (final w in list) {
        if (w is! Map) continue;
        final ts = (w['start_ts'] as num?)?.toInt();
        if (ts != null && ts < cutoffSec) continue;
        final type = (w['type'] ?? w['sport'] ?? '').toString();
        if (isStrengthWorkoutType(type)) {
          final durMin = (w['duration_min'] as num?)?.toDouble() ??
              (((w['end_ts'] as num?) != null && ts != null)
                  ? ((w['end_ts'] as num).toInt() - ts) / 60.0
                  : 0.0);
          if (durMin > 0 && durMin.isFinite) strMin += durMin;
        }
      }
      if (recentDays.isNotEmpty) {
        final first = recentDays.reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
        final firstDt = DateTime.tryParse(first);
        final today = DateTime(clock.year, clock.month, clock.day);
        final span = firstDt == null ? 30 : today.difference(firstDt).inDays + 1;
        final spanDays = span.clamp(kBodyAgeMinDays, 30);
        strengthMinPerWeek = strMin / (spanDays / 7.0);
      }
    }
  } catch (_) {}

  final live = BodyAgeCalculator.calculate(
    realAge: realAge,
    exactAge: exactAge,
    dataDays: recentDays.length,
    avgSleepHours: avgSleepHours,
    avgSri: avgSri,
    avgRhr: avgRhr,
    avgSteps: avgSteps,
    moderateMinPerWeek: modMinPerWeek,
    intensiveMinPerWeek: intMinPerWeek,
    strengthMinPerWeek: strengthMinPerWeek,
    weekMonday: monday,
  );

  // Kalibrierung (<14 Tage) und „kein einziger Faktor“ sind kein Ergebnis:
  // nichts speichern.
  if (!live.ready) return live;

  final result = BodyAgeSnapshot(
    realAge: live.realAge,
    exactAge: live.exactAge,
    bodyAge: live.bodyAge,
    diffYears: live.diffYears,
    dataDays: live.dataDays,
    factors: live.factors,
    weekMonday: monday,
    prevWeekDelta: prevDiff == null ? null : live.diffYears - prevDiff,
    paceOfAging: live.paceOfAging,
  ).withRecentOrSelf(week7);
  if (prefs != null) {
    try {
      weeks[monday] = _snapshotToJson(live);
      await _writeWeeks(prefs, weeks);
    } catch (_) {}
  }
  return result;
}
