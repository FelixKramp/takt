import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/models/activity_suggestion.dart';
import 'package:openstrap_edge/takt/takt_text.dart';
import 'package:openstrap_edge/takt/today/auto_confirm.dart';
import 'package:openstrap_edge/takt/today/freshness.dart';
import 'package:openstrap_edge/takt/update_check.dart';

ActivitySuggestion s(String id, ActivityKind k) =>
    ActivitySuggestion(id: id, kind: k, startTs: 10, endTs: 20, revision: 1);

void main() {
  const de = TaktText(true);
  final now = DateTime(2026, 11, 6, 12);

  test('A13: Frische steht in Worten da', () {
    expect(freshnessText(now.subtract(const Duration(seconds: 20)), now, de), 'gerade eben');
    expect(freshnessText(now.subtract(const Duration(minutes: 2)), now, de), 'vor 2 Min');
    expect(freshnessText(now.subtract(const Duration(hours: 3)), now, de), 'vor 3 Std');
    expect(freshnessText(null, now, de), 'noch keine Daten');
  });

  test('A12: Sync startet beim Öffnen, aber nicht bei jedem Tabwechsel', () {
    final gate = SyncOnOpenGate();
    expect(gate.shouldSync(now, paired: true), isTrue);
    expect(gate.shouldSync(now.add(const Duration(minutes: 1)), paired: true), isFalse);
    expect(gate.shouldSync(now.add(const Duration(minutes: 6)), paired: true), isTrue);
  });

  test('A12: Ohne gekoppeltes Band kein Sync', () {
    expect(SyncOnOpenGate().shouldSync(now, paired: false), isFalse);
  });

  test('A8: Erkannte Workouts werden bestätigt, Nickerchen nicht', () async {
    final done = <String>[];
    final left = await autoConfirmWorkouts(
      pending: () async => [s('w', ActivityKind.workout), s('n', ActivityKind.nap)],
      confirm: (x) async => done.add(x.id),
    );
    expect(done, ['w']);
    expect(left, isEmpty);
  });

  test('A8: Scheitert das Bestätigen, bleibt das Workout sichtbar', () async {
    final left = await autoConfirmWorkouts(
      pending: () async => [s('w', ActivityKind.workout)],
      confirm: (x) async => throw const ActivityReviewException('Überlappung'),
    );
    expect(left.single.id, 'w');
  });

  group('Update-Prüfung', () {
    test('A25: Neueres Release wird erkannt', () {
      expect(isNewerVersion('0.1.0', 'v0.2.0'), isTrue);
      expect(isNewerVersion('0.1.9', 'v0.1.10'), isTrue);
      expect(isNewerVersion('0.2.0', 'v0.2.0'), isFalse);
      expect(isNewerVersion('1.0.0', 'v0.9.9'), isFalse);
      expect(isNewerVersion('0.1.0', 'kaputt'), isFalse);
    });
    test('A25: Höchstens einmal am Tag', () {
      expect(shouldCheckUpdate(null, now), isTrue);
      expect(shouldCheckUpdate(now.subtract(const Duration(hours: 5)), now), isFalse);
      expect(shouldCheckUpdate(now.subtract(const Duration(hours: 25)), now), isTrue);
    });
  });
}
