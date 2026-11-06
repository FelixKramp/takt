// Texte von Takt. Deutsch und Englisch, alles andere fällt auf Englisch zurück.
import 'package:flutter/widgets.dart';

class TaktText {
  const TaktText(this.de);
  final bool de;

  static TaktText of(BuildContext c) =>
      TaktText(Localizations.localeOf(c).languageCode == 'de');

  String get live => de ? 'bpm live' : 'bpm live';
  String lastAt(String time) => de ? 'zuletzt um $time' : 'last at $time';
  String get notConnected => de ? 'Band nicht verbunden' : 'Band not connected';
  String get notWorn => de ? 'Band nicht angelegt' : 'Band not on your wrist';
  String get notPaired => de ? 'Noch kein Band gekoppelt' : 'No band paired yet';
  String get pairBand => de ? 'Band koppeln' : 'Pair a band';
  String get pulseTrace =>
      de ? 'Pulsverlauf der letzten Messwerte' : 'Recent heart rate readings';

  String get activities => de ? 'Aktivitäten' : 'Activities';
  String get detected => de ? 'erkannt' : 'detected';
  String get training => 'Training';
  String get waitingForPulse => de ? 'Warte auf den Puls …' : 'Waiting for your pulse…';
  String get noActivities => de
      ? 'Heute noch nichts erkannt. War da ein Training?'
      : 'Nothing detected yet today. Did you train?';
  String get logWorkout => de ? 'Workout nachtragen' : 'Log a workout';
  String discard(String name) => de ? '$name verwerfen' : 'Discard $name';
  String showAll(int n) => de ? '$n weitere anzeigen' : 'Show $n more';
  String get allToday => de ? 'Aktivitäten heute' : "Today's activities";

  String get hrv => 'HRV';
  String get restingHr => de ? 'Ruhepuls' : 'Resting HR';
  String get steps => de ? 'Schritte' : 'Steps';

  String get syncing => de ? 'Synchronisiert …' : 'Syncing…';
  String get justNow => de ? 'gerade eben' : 'just now';
  String minutesAgo(int m) => de ? 'vor $m Min' : '$m min ago';
  String hoursAgo(int h) => de ? 'vor $h Std' : '$h h ago';
  String get noData => de ? 'noch keine Daten' : 'no data yet';

  String get moreForToday => de ? 'Mehr zu heute' : 'More for today';
  String get moreForTodaySub =>
      de ? 'Plan, Hinweise und Wecker' : 'Plan, tips and alarm';

  String get about => de ? 'Über diese App' : 'About this app';
  String get basedOn => de ? 'Basiert auf OpenStrap' : 'Based on OpenStrap';
  String get sourceCode => de ? 'Quellcode von Takt' : 'Takt source code';
  String get licenseLine =>
      de ? 'Lizenz: AGPL-3.0, Code offen' : 'License: AGPL-3.0, open source';
  String get legal => de
      ? '© OpenStrap-Beitragende und Felix Kramp. Ohne jede Gewähr, kein Medizinprodukt.'
      : '© OpenStrap contributors and Felix Kramp. No warranty, not a medical device.';
  String get newVersion => de ? 'Neue Version verfügbar' : 'New version available';
}
