// Feature 05: Texte für Gesundheit, Erscheinungsbild und die Stress-Tür.
// Wie `TaktText`: Deutsch und Englisch, alles andere fällt auf Englisch zurück.
// Eigene Datei, damit `takt_text.dart` nicht von mehreren Seiten angefasst wird.
import '../takt_text.dart';

extension TaktHealthText on TaktText {
  // Erscheinungsbild (Profil und Einstellungen)
  String get appearanceSystem => 'System';
  String get appearanceLight => de ? 'Hell' : 'Light';
  String get appearanceDark => de ? 'Dunkel' : 'Dark';

  // G26: Der Stresswert der Nacht (Baevsky) und der Tagesstress sind zwei
  // verschiedene Dinge. Die Tür vom einen zum anderen sagt das.
  String get dayStressDoor => de ? 'Tagesstress ansehen' : 'See daytime stress';
  String get dayStressDoorSub => de
      ? 'Herzfrequenz-Modell über den Tag, eine andere Skala als der Stresswert der Nacht'
      : 'A heart-rate model through the day, a different scale from the overnight stress level';
}
