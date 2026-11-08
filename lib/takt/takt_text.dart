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
  // Feature 08, T8: Kopf des Nachtragens, klein geschrieben wie alle Köpfe.
  String get logWorkoutHead => de ? 'training nachtragen' : 'log a workout';
  String get retimeHead => de ? 'zeiten ändern' : 'change the times';
  String discard(String name) => de ? '$name verwerfen' : 'Discard $name';
  String showAll(int n) => de ? '$n weitere anzeigen' : 'Show $n more';
  String get allToday => de ? 'Aktivitäten heute' : "Today's activities";

  String get hrv => 'HRV';
  String get restingHr => de ? 'Ruhepuls' : 'Resting HR';
  String hoursShort(String hm) => de ? '$hm Std' : '$hm h';
  String get steps => de ? 'Schritte' : 'Steps';
  String get today => de ? 'heute' : 'today';
  String get noValueYet => de ? 'Noch kein Wert.' : 'No value yet.';
  String driverName(String key, String fallback) => switch (key) {
        'hrv' => 'HRV',
        'rhr' => restingHr,
        'resp' => de ? 'Atmung' : 'Breathing',
        'temp' => de ? 'Hauttemperatur' : 'Skin temperature',
        _ => fallback,
      };
  String get driverUsual => de ? 'im üblichen Bereich' : 'within your usual range';
  String driverLower(String by) => de
      ? (by.isEmpty ? 'niedriger als üblich' : '$by niedriger als üblich')
      : (by.isEmpty ? 'lower than usual' : '$by lower than usual');
  String driverHigher(String by) => de
      ? (by.isEmpty ? 'höher als üblich' : '$by höher als üblich')
      : (by.isEmpty ? 'higher than usual' : '$by higher than usual');
  String driverMissing(String why) =>
      (de ? 'nicht verfügbar' : 'not available') + (why.isEmpty ? '' : ': $why');
  String get allReadings => de ? 'Alle Messwerte' : 'All readings';

  /// Von wann ein Kartenwert stammt, der nicht von heute ist: „gestern“, der
  /// Wochentag innerhalb einer Woche, sonst das Datum.
  String dayOf(DateTime d, DateTime now) {
    final a = DateTime(d.year, d.month, d.day);
    final b = DateTime(now.year, now.month, now.day);
    final days = b.difference(a).inHours ~/ 24;
    if (days == 1) return de ? 'gestern' : 'yesterday';
    if (days > 1 && days < 7) {
      const wd = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
      const we = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return (de ? wd : we)[d.weekday - 1];
    }
    return de ? '${d.day}.${d.month}.' : '${d.month}/${d.day}';
  }

  String get syncing => de ? 'Synchronisiert …' : 'Syncing…';
  String get justNow => de ? 'gerade eben' : 'just now';
  String minutesAgo(int m) => de ? 'vor $m Min' : '$m min ago';
  String hoursAgo(int h) => de ? 'vor $h Std' : '$h h ago';
  String get noData => de ? 'noch keine Daten' : 'no data yet';

  String get moreForToday => de ? 'Mehr zu heute' : 'More for today';
  String get moreForTodaySub =>
      de ? 'Plan, Hinweise und Wecker' : 'Plan, tips and alarm';

  String get reportSub => de
      ? 'Erstellt einen Bericht, den du selbst teilen kannst'
      : 'Creates a report you can share yourself';
  String get about => de ? 'Über diese App' : 'About this app';
  String get basedOn => de ? 'Basiert auf OpenStrap' : 'Based on OpenStrap';
  String get sourceCode => de ? 'Quellcode von Takt' : 'Takt source code';
  String get licenseLine =>
      de ? 'Lizenz: AGPL-3.0, Code offen' : 'License: AGPL-3.0, open source';
  String get legal => de
      ? '© OpenStrap-Beitragende und Felix Kramp. Ohne jede Gewähr, kein Medizinprodukt.'
      : '© OpenStrap contributors and Felix Kramp. No warranty, not a medical device.';
  String get display => de ? 'Anzeige' : 'Display';
  String get stripeTitle => de ? 'Displaystreifen' : 'Display stripe';
  String get stripeSub => de
      ? 'Zahlen weichen einem Strich auf dem Display aus'
      : 'Numbers move clear of a line on your screen';
  String get stripeHow => de
      ? 'Schieb die orange Linie genau auf den Strich in deinem Display. Danach rückt jede Zahl daneben.'
      : 'Move the orange line exactly onto the line on your screen. Every number then moves clear of it.';
  String get off => de ? 'aus' : 'off';
  String get save => de ? 'Speichern' : 'Save';
  String get remove => de ? 'Entfernen' : 'Remove';
  String get nudgeLeft => de ? 'Linie ein Stück nach links' : 'Move the line left a little';
  String get nudgeRight => de ? 'Linie ein Stück nach rechts' : 'Move the line right a little';
  String get newVersion => de ? 'Neue Version verfügbar' : 'New version available';
}
