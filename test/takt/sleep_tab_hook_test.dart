// Feature 03, C9: Der Takt-Kopf ersetzt nur Abschnitt 1 des Schlaf-Screens,
// der Rest (Nacht, Vergleich, Signale) bleibt darunter.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/ui2/screens/sleep_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

const _onset = 1779229800; // 2026-05-19 22:30 UTC

Map<String, dynamic> _night() => {
      'has_sleep': true,
      'duration_min': 452,
      'in_bed_min': 486,
      'efficiency': 0.93,
      'onset_ts': _onset,
      'wake_ts': _onset + 486 * 60,
      'hypnogram': [
        {'t': _onset, 'stage': 'light'},
        {'t': _onset + 3600, 'stage': 'deep'},
        {'t': _onset + 7200, 'stage': 'rem'},
        {'t': _onset + 486 * 60, 'stage': 'awake'},
      ],
    };

Future<void> _pump(WidgetTester t, Widget w) async {
  t.view.physicalSize = const Size(390 * 3, 5200 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(theme: buildTheme(Brightness.light), home: w));
  await t.pumpAndSettle();
}

void main() {
  final d = SleepData(day: '2026-05-20', night: _night());

  testWidgets('ohne Kopf bleibt der Upstream-Screen wie er ist', (t) async {
    await _pump(t, SleepDetail(data: d));
    expect(find.text('Total sleep'), findsOneWidget);
    expect(find.text('No stage split for this night'), findsOneWidget);
  });

  testWidgets('C9: der Kopf ersetzt Abschnitt 1, der Rest bleibt', (t) async {
    String? seen;
    await _pump(
      t,
      SleepDetail(
        data: d,
        head: (day) {
          seen = day;
          return const Text('TAKT-KOPF');
        },
      ),
    );
    expect(find.text('TAKT-KOPF'), findsOneWidget);
    expect(seen, '2026-05-20', reason: 'der Kopf bekommt die gezeigte Nacht');
    expect(find.text('Total sleep'), findsNothing);
    expect(find.text('Did you sleep enough?'), findsNothing,
        reason: 'gehört zu Abschnitt 4 und braucht Verlauf');
    expect(find.text('No stage split for this night'), findsOneWidget,
        reason: 'Abschnitt 3 steht weiter darunter');
  });
}
