// Feature 15: Radfahren über die Aktivitätserkennung des Handys.
// Alle Zeiten synthetisch.
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/takt/walk/phone_motion.dart';
import 'package:openstrap_edge/ui2/activity/catalogue.dart' show activityByName;

const t0 = 1700000000; // Sekunden
int ms(int minute) => (t0 + minute * 60) * 1000;
MotionEvent on(int minute, String type) => MotionEvent(ms(minute), type, true);
MotionEvent off(int minute, String type) => MotionEvent(ms(minute), type, false);

String? sport(List<MotionEvent> ev, int fromMin, int toMin, {int? nowMin}) => phoneSportFor(
  ev,
  t0 + fromMin * 60,
  t0 + toMin * 60,
  nowMs: nowMin == null ? null : ms(nowMin),
);

void main() {
  test('R1 – Handy meldet die ganze Zeit Fahrrad: Fahrt', () {
    expect(sport([on(0, 'walking'), on(3, 'bicycle'), on(28, 'walking')], 3, 28), 'cycling');
  });

  test('R2 – Handy meldet Gehen: bleibt ein Gang', () {
    expect(sport([on(0, 'walking'), off(30, 'walking')], 2, 25), isNull);
  });

  test('R3 – Fahrrad erst ab der Hälfte zählt, darunter nicht', () {
    expect(sport([on(0, 'walking'), on(10, 'bicycle'), on(30, 'still')], 0, 20), 'cycling');
    expect(sport([on(0, 'walking'), on(11, 'bicycle'), on(30, 'still')], 0, 20), isNull);
  });

  test('R4 – Ende einer Fahrt beendet die Spanne', () {
    expect(sport([on(0, 'bicycle'), off(5, 'bicycle')], 0, 20), isNull);
  });

  test('R5 – fehlendes Ende macht nicht den ganzen Tag zur Fahrt', () {
    final ev = [on(0, 'bicycle')];
    expect(sport(ev, 0, 20), 'cycling');
    expect(sport(ev, 300, 320), isNull, reason: 'höchstens 3 Stunden');
  });

  test('R6 – eine offene Fahrt reicht nicht über jetzt hinaus', () {
    expect(sport([on(0, 'walking'), on(15, 'bicycle')], 0, 25, nowMin: 16), isNull);
  });

  test('R7 – ohne Wechsel (iOS, keine Berechtigung) nichts', () {
    expect(sport(const [], 0, 20), isNull);
  });

  test('R8 – die native Liste wird gelesen, Kaputtes übersprungen', () {
    final ev = PhoneMotion.parse(
      '[{"ms":1,"type":"bicycle","enter":true},{"type":"x"},{"ms":2,"type":"walking","enter":false}]',
    );
    expect(ev, hasLength(2));
    expect(ev.first.type, 'bicycle');
    expect(ev.first.enter, isTrue);
    expect(ev.last.enter, isFalse);
    expect(PhoneMotion.parse(null), isEmpty);
  });

  test('R9 – cycling passt auf den Katalog', () {
    expect(activityByName('cycling'), isNotNull);
  });
}
