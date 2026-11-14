import 'package:flutter/widgets.dart';

class JournalText {
  const JournalText(this.locale);

  final Locale? locale;
  bool get de => locale?.languageCode == 'de';

  static JournalText of(BuildContext context) {
    return JournalText(Localizations.localeOf(context));
  }

  String get yesterday => de ? 'Gestern' : 'Yesterday';
  String get today => de ? 'Heute' : 'Today';
  String get yes => de ? 'Ja' : 'Yes';
  String get no => de ? 'Nein' : 'No';
  String get howDoYouFeel => de ? 'Wie fühlst du dich?' : 'How do you feel?';
  String get feelingBad => de ? 'schlecht' : 'bad';
  String get feelingMeh => de ? 'geht so' : 'meh';
  String get feelingGood => de ? 'gut' : 'good';
  String get feelingGreat => de ? 'sehr gut' : 'great';
  String get done => de ? 'Fertig' : 'Done';
  String get later => de ? 'Später' : 'Later';
  String get openJournal => de ? 'Journal öffnen' : 'Open journal';
  String get logToday => de ? 'Heute eintragen' : 'Log today';
  String get saveError => de ? 'Speichern fehlgeschlagen' : 'Save failed';
  String get retry => de ? 'Nochmal' : 'Retry';
  String get customQuestion => de ? 'Eigene Frage' : 'Custom question';
  String get newQuestionTitle => de ? 'Neue Frage anlegen' : 'New question';
  String get questionName => de ? 'Name der Frage' : 'Question name';
  String get questionNameHint => de ? 'z. B. Kalt geduscht' : 'e.g. Cold shower';
  String get refersToYesterday => de ? 'Bezieht sich auf gestern' : 'Refers to yesterday';
  String get refersToToday => de ? 'Bezieht sich auf heute' : 'Refers to today';
  String get markAsPrivate => de ? 'Als privat markieren' : 'Mark as private';
  String get privateHint => de
      ? 'Private Antworten verlassen dieses Gerät nie (kein Export, keine Berichte).'
      : 'Private answers never leave this device (no export, no reports).';
  String get showInMorningSheet => de ? 'Im Morgenblatt zeigen' : 'Show in morning sheet';
  String get displayName => de ? 'Anzeigename' : 'Display name';
  String get save => de ? 'Speichern' : 'Save';
  String get cancel => de ? 'Abbrechen' : 'Cancel';
  String get deleteQuestion => de ? 'Frage löschen' : 'Delete question';
  String get hideQuestion => de ? 'Frage ausblenden' : 'Hide question';
  String get unhideQuestion => de ? 'Wieder einblenden' : 'Unhide';

  // Morgenbriefing-Link (J28–J31)
  String get briefingListen => de ? 'Morgenbriefing anhören' : 'Listen to morning briefing';
  String get briefingSetup => de ? 'Morgenbriefing-Link einrichten' : 'Set up morning briefing link';
  String get briefingLinkTitle => de ? 'Morgenbriefing-Link' : 'Morning briefing link';
  String get briefingLinkHint => de
      ? 'Link zur Datei „Heute.m4a“ in Google Drive. Er bleibt auf diesem Gerät.'
      : 'Link to the file "Heute.m4a" in Google Drive. It stays on this device.';
  String get briefingInvalid => de ? 'Das ist kein Google-Drive-Link' : 'That is not a Google Drive link';
  String get briefingOpenFailed => de ? 'Link konnte nicht geöffnet werden' : 'Could not open the link';
  String get briefingRemove => de ? 'Link entfernen' : 'Remove link';

  // Auswertung
  String get whatHelpsMe => de ? 'Was tut mir gut' : 'What works for me';
  String get helps => de ? 'Hilft' : 'Helps';
  String get costs => de ? 'Kostet' : 'Costs';
  String get noDifference => de ? 'Kein Unterschied erkennbar' : 'No clear difference';
  String get tooFewDays => de ? 'Zu wenig Tage' : 'Too few days';
  String get disclaimer => de
      ? 'Geht zusammen mit, nicht verursacht durch. An einem Tag kommen viele Dinge zusammen.'
      : 'Goes together with, not caused by. Many things happen on any given day.';
  String get batteryNextMorning => de ? 'Batterie am Morgen danach' : 'Battery next morning';
  String get hrv => de ? 'HRV' : 'HRV';
  String get rhr => de ? 'Ruhepuls' : 'Resting HR';
  String get sleepEfficiency => de ? 'Schlafeffizienz' : 'Sleep efficiency';
  String get daysCount => de ? 'Tage' : 'days';

  String countStatus(int yes, int yesGoal, int no, int noGoal) =>
      de ? 'Ja $yes von $yesGoal, Nein $no von $noGoal' : 'Yes $yes of $yesGoal, No $no of $noGoal';

  String waiting(int n) => de
      ? (n == 1
          ? '1 Eintrag wartet auf die Nacht danach'
          : '$n Einträge warten auf die Nacht danach')
      : (n == 1 ? '1 entry waits for the night after' : '$n entries wait for the night after');

  String diffPoints(double diff) {
    final sign = diff > 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)} %';
  }
}
