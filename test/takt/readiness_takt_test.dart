// Feature 07, H9–H11: Erholung im Takt-Design.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/models/metric.dart';
import 'package:openstrap_edge/takt/detail/band_row.dart';
import 'package:openstrap_edge/takt/detail/value_card.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/ui2/screens/driver_breakdown.dart';
import 'package:openstrap_edge/ui2/screens/readiness_detail.dart';
import 'package:openstrap_edge/ui2/theme.dart';

void main() {
  testWidgets('H9, H10: Wert mit Stufe, Bausteine als Zeilen mit Band', (t) async {
    t.view.physicalSize = const Size(390, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final breakdown = [
      {'label': 'hrv', 'used': true, 'weight': .4, 'weighted_contribution': -6.2, 'past_mdc': true},
      {'label': 'rhr', 'used': true, 'weight': .3, 'weighted_contribution': 3.1, 'past_mdc': false},
    ];
    final facts = driverFacts(breakdown: breakdown, baselines: const {
      'hrv': {'value': 41.2, 'baseline': 58.4, 'spread': 6.1, 'delta': -17.2},
      'resting_hr': {'value': 54.0, 'baseline': 53.0, 'spread': 2.0, 'delta': 1.0},
    });
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: TaktLook(
        child: ReadinessDetail(
          data: ReadinessData(
            readiness: Metric.parse({'value': 62, 'unit': '%'}),
            breakdown: breakdown,
            inputsUsed: 2,
            series: [for (var i = 0; i < 20; i++) 50.0 + i],
          ),
          facts: facts,
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.text('erholung'), findsOneWidget);
    expect(find.byType(TaktValueCard), findsOneWidget);
    expect(find.text('62'), findsWidgets);
    expect(find.byType(TaktBandRow), findsNWidgets(2));
    expect(find.byKey(const ValueKey('takt-band-0')), findsOneWidget);
    expect(find.textContaining('niedriger als üblich'), findsOneWidget);
    expect(find.text('im üblichen Bereich'), findsOneWidget);
  });
}
