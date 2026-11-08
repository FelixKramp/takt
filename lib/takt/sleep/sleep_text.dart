// Texte des Takt-Schlaf-Tabs. Deutsch und Englisch.
import 'package:flutter/widgets.dart';

class SleepText {
  const SleepText(this.de);
  final bool de;

  static SleepText of(BuildContext c) =>
      SleepText(Localizations.localeOf(c).languageCode == 'de');

  String get of100 => de ? 'von 100' : 'of 100';

  // Feature 06: der Teil unter dem Kopf.
  String get theNight => de ? 'Die Nacht' : 'The night';
  String get phases => de ? 'Phasen' : 'Stages';
  String get phasesNote => de
      ? 'Phasen schätzt das Band aus Puls und Bewegung, deshalb stehen dort Spannen.'
      : 'The band estimates stages from pulse and movement, so they are ranges.';
  String slept(String hm) => de ? '$hm Std geschlafen' : '$hm h asleep';
  String window(String from, String to) => de ? '$from bis $to' : '$from to $to';
  String get durationPart => de ? 'Dauer zu Bedarf' : 'Duration vs need';
  String get efficiencyPart => de ? 'Effizienz' : 'Efficiency';
  String get regularityPart => de ? 'Regelmäßigkeit' : 'Regularity';
  String durationOf(String a, String b) => de ? '$a von $b' : '$a of $b';
  String get notEnoughNights => de ? 'noch nicht genug Nächte' : 'not enough nights yet';
  String get weights => de
      ? 'Dauer zählt zur Hälfte, Effizienz und Regelmäßigkeit je zu einem Viertel.'
      : 'Duration counts for half, efficiency and regularity a quarter each.';
  String get lastSeven => de ? 'Letzte 7 Nächte' : 'Last 7 nights';
  String get noNight => de
      ? 'Keine Nacht ausgewertet. Trag das Band über Nacht, dann steht hier morgen dein Score.'
      : 'No night analysed. Wear the band overnight and your score shows here tomorrow.';
  String get noNeed => de
      ? 'Noch kein Score: Takt kennt deinen Schlafbedarf erst nach ein paar Nächten.'
      : 'No score yet: Takt learns your sleep need over a few nights.';
  String get durationNeed => de ? 'Dauer und Bedarf' : 'Duration and need';
  String get sleptLabel => de ? 'Geschlafen' : 'Asleep';
  String get needLabel => de ? 'Bedarf' : 'Need';
  String get base => de ? 'Grundbedarf' : 'Baseline';
  String get strain => de ? 'Belastung' : 'Strain';
  String get debt => de ? 'Schlafschuld' : 'Sleep debt';
  String get naps => de ? 'Nickerchen' : 'Naps';
  String get partsTomorrow => de
      ? 'Woraus sich der Bedarf zusammensetzt, zeigt Takt ab der nächsten Nacht.'
      : 'Takt shows what makes up your need from the next night on.';
  String get recLegend => de ? 'gestrichelt: empfohlen für jeden Tag' : 'dashed: recommended each day';
  String lastNight(String w) => de ? 'Letzte Nacht $w' : 'Last night $w';
  String tonight(String bed, String up) => de
      ? 'Empfohlen heute Nacht: ins Bett $bed, aufstehen $up'
      : 'Recommended tonight: bed $bed, up $up';
  String get effLegend => de ? 'der Zeit im Bett geschlafen' : 'of time in bed asleep';
  String get asleep => de ? 'Schlafend' : 'Asleep';
  String get awake => de ? 'Wach' : 'Awake';
  String get wakeEvents => de ? 'Aufwachereignisse' : 'Wake-ups';
  List<String> get weekdays =>
      de ? const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'] : const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
}
