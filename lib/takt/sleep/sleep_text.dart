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
  // F6: kurze Hinweise in der Korrekturkarte, je eine Zeile.
  String get windowMine => de ? 'Zeitraum von dir gesetzt' : 'You set this window';
  String get windowFallback => de ? 'Zeitraum aus dem Puls geschätzt' : 'Window guessed from pulse';
  String get windowVendor => de ? 'Phasen vom Gerät' : 'Staged by your device';
  String get windowAuto => de ? 'Zeitraum automatisch erkannt' : 'Window detected automatically';
  String get windowFallbackBody => de ? 'Beginn und Ende sind geschätzt.' : 'Start and end are a guess.';
  String get uncorrectable => de ? 'Nicht mehr korrigierbar.' : 'Can no longer be corrected.';
  String get eveningPruned => de ? 'Nur Bettzeit nach Mitternacht oder „Kein Schlaf“.' : 'Only a bedtime after midnight or Not sleep.';
  String get noStages => de ? 'Keine Phasen für diese Nacht' : 'No stages for this night';
  String get versus => de ? 'Gegen deine Nächte' : 'Against your nights';
  String usual(String lo, String hi, int n) =>
      de ? 'üblich $lo bis $hi, aus $n Nächten' : 'usual $lo to $hi, from $n nights';
  String get signals => de ? 'Signale in der Nacht' : 'Signals overnight';
  String get sleepingHr => de ? 'Schlafpuls' : 'Sleeping HR';
  String get lowestHr => de ? 'Tiefster Puls' : 'Lowest HR';
  String get breathsPerMin => de ? 'Atemzüge/Min' : 'Breaths/min';
  String get alarm => de ? 'Wecker' : 'Alarm';
  String get alarmSub => de ? 'Vibriert am Handgelenk' : 'Buzzes on your wrist';
  String get bodyClock => de ? 'Körperuhr' : 'Body clock';
  String get bodyClockSub =>
      de ? 'Natürliche Bettzeit, Wochenendverschiebung' : 'Natural bedtime, weekend shift';
  String get naps => de ? 'Nickerchen' : 'Naps';
  String get napsSub => de ? 'Schlaf am Tag' : 'Sleep during the day';
  String get allReadings => de ? 'Alle Messwerte' : 'All readings';
  String get allReadingsSub => de ? 'Genaue Zahlen zu dieser Nacht' : 'Exact figures for this night';
  String get nothingStoodOut => de ? 'Nichts aufgefallen.' : 'Nothing stood out.';
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
      ? 'Dauer zählt 60 %, Effizienz und Regelmäßigkeit je 20 %. Fehlender Schlaf zählt überproportional.'
      : 'Duration counts 60 %, efficiency and regularity 20 % each. Missing sleep counts extra.';
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
