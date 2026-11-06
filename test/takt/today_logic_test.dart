import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/takt/today/activity_items.dart';
import 'package:openstrap_edge/takt/today/dial_ring.dart';
import 'package:openstrap_edge/takt/today/pulse_state.dart';
import 'package:openstrap_edge/ui2/activity/catalogue.dart';

void main() {
  group('Drehregler', () {
    test('A2: Wert füllt die Teilstriche anteilig', () {
      expect(dialLitTicks(0.62), 30);
      expect(dialLitTicks(1.0), 48);
      expect(dialLitTicks(1.4), 48);
    });
    test('A20: Ohne Füllstand bleibt der Ring leer', () {
      expect(dialLitTicks(null), 0);
    });
  });

  group('Puls', () {
    final at = DateTime(2026, 11, 6, 14, 32);
    test('A6: Live-Wert hat Vorrang', () {
      final s = pulseStateOf(live: 72, last: LastPulse(70, at), paired: true, connected: true);
      expect(s.kind, PulseKind.live);
      expect(s.bpm, 72);
    });
    test('A18: Ohne Live-Wert bleibt der letzte Wert mit Grund', () {
      final s = pulseStateOf(live: null, last: LastPulse(70, at), paired: true, connected: false);
      expect(s.kind, PulseKind.stale);
      expect(s.bpm, 70);
      expect(s.at, at);
      expect(s.reason, PulseReason.notConnected);
    });
    test('A18: Verbunden ohne Messwert heißt nicht angelegt', () {
      final s = pulseStateOf(live: null, last: LastPulse(70, at), paired: true, connected: true);
      expect(s.reason, PulseReason.notWorn);
    });
    test('A7: Live-Strom läuft nur, solange der Puls sichtbar ist', () {
      var open = 0;
      final g = PulseStreamGate(retain: () => open++, release: () => open--);
      g.update(true);
      g.update(true);
      expect(open, 1);
      g.update(false);
      expect(open, 0);
    });
    test('A19: Nie gemessen zeigt keine Zahl', () {
      final s = pulseStateOf(live: null, last: null, paired: false, connected: false);
      expect(s.kind, PulseKind.never);
      expect(s.bpm, isNull);
      expect(s.reason, PulseReason.notPaired);
    });
  });

  group('Aktivitäten', () {
    final day = DateTime(2026, 11, 6);
    int ts(int h, [int m = 0]) => DateTime(2026, 11, 6, h, m).millisecondsSinceEpoch ~/ 1000;
    Map<String, dynamic> w(String id, int start, {String status = 'done'}) => {
          'id': id, 'start_ts': start, 'status': status, 'type': 'handball',
          'duration_min': 84, 'avg_hr': 148, 'strain': 11.2,
        };

    test('A8: Erkannte Workouts tragen die Markierung', () {
      final items = todayActivities([w('suggestion:abc', ts(18))], day);
      expect(items.single.detected, isTrue);
      expect(items.single.avgHr, 148);
      expect(items.single.strain, 11.2);
    });
    test('A10: Alle Quellen in einer Liste, neueste zuerst', () {
      final items = todayActivities([w('m1', ts(7, 40)), w('suggestion:b', ts(18)), w('m2', ts(12))], day);
      expect(items.map((e) => e.id), ['suggestion:b', 'm2', 'm1']);
      expect(items.last.detected, isFalse);
    });
    test('A10: Andere Tage und laufende Workouts fehlen', () {
      final yesterday = ts(18) - 86400;
      final items = todayActivities([w('alt', yesterday), w('live', ts(9), status: 'live')], day);
      expect(items, isEmpty);
    });
    test('A11: Handball steht im Katalog', () {
      expect(activityByName('handball')?.name, 'Handball');
    });
    test('A8: Unbekannte Sportart bleibt lesbar', () {
      expect(readableType('handball'), 'Handball');
      expect(readableType('table_tennis'), 'Table tennis');
    });
    test('A22: Höchstens fünf, Rest zählt als weitere', () {
      final items = todayActivities([for (var i = 0; i < 7; i++) w('w$i', ts(8 + i))], day);
      final v = visibleActivities(items);
      expect(v.shown.length, 5);
      expect(v.shown.first.id, 'w6');
      expect(v.hidden, 2);
    });
  });
}
