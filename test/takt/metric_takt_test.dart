// Feature 07, H2–H5: HRV, Ruhepuls und Schritte im Takt-Design.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/detail/value_card.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/ui2/live_hr.dart' show LiveHrCard;
import 'package:openstrap_edge/ui2/screens/metric_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

List<({int t, double v})> pts(int n, double base) {
  final now = DateTime.now();
  return [
    for (var i = 0; i < n; i++)
      (
        t: DateTime(now.year, now.month, now.day - (n - 1 - i), 12).millisecondsSinceEpoch ~/ 1000,
        v: base + (i % 5) * 2.0,
      ),
  ];
}

Future<void> pump(WidgetTester t, String key, double base) async {
  t.view.physicalSize = const Size(390, 3200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: TaktLook(
        child: MetricDetail(key, data: MetricData(series: pts(30, base), daysAvailable: 30))),
  ));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('H3: HRV mit Wert-Karte „heute“, Spanne in Punktziffern, Alle Messwerte', (t) async {
    await pump(t, 'hrv', 60);
    expect(find.byType(TaktValueCard), findsOneWidget);
    expect(find.text('hrv'), findsOneWidget);
    expect(find.text('heute'), findsOneWidget);
    expect(find.text('Alle Messwerte'), findsOneWidget);
    expect(find.text('Nerd stats'), findsNothing);
    final lowest = find.text('60').first;
    expect(t.widget<Text>(lowest).style?.fontFamily, 'Doto');
  });

  testWidgets('H4: Ruhepuls ohne Live-Puls', (t) async {
    await pump(t, 'resting_hr', 50);
    expect(find.byType(TaktValueCard), findsOneWidget);
    expect(find.byType(LiveHrCard), findsNothing);
  });

  testWidgets('H5: Schritte mit Wert-Karte', (t) async {
    await pump(t, 'steps', 8000);
    expect(find.byType(TaktValueCard), findsOneWidget);
  });
}
