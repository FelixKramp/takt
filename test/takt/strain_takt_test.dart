// Feature 07, H6–H8: Strain im Takt-Design.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/data/day_label.dart';
import 'package:openstrap_edge/l10n/app_localizations.dart';
import 'package:openstrap_edge/takt/detail/value_card.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/ui2/activity/day_strain.dart';
import 'package:openstrap_edge/ui2/theme.dart';

Future<void> pump(WidgetTester t, {List<String>? days}) async {
  t.view.physicalSize = const Size(390, 2400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day);
  final start = day.add(const Duration(hours: 17)).millisecondsSinceEpoch ~/ 1000;
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: TaktLook(
      child: DayStrainDetail(
        data: DayStrainData(
          day: day,
          curve: [for (var i = 0; i < 96; i++) i * 0.13],
          strain: 12.4,
          zoneMin: const [120, 60, 25, 10, 2],
          peakHr: 171,
          wornMin: 900,
        ),
        acts: [(start, start + 84 * 60)],
        days: days,
      ),
    ),
  ));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('H6: Wert-Karte und Aktivität als Markierung auf der Kurve', (t) async {
    await pump(t);
    expect(find.text('strain'), findsOneWidget);
    expect(find.byType(TaktValueCard), findsOneWidget);
    expect(find.text('12.4'), findsWidgets);
    expect(find.text('heute'), findsOneWidget);
    expect(find.byKey(const ValueKey('takt-strain-act-0')), findsOneWidget);
  });

  testWidgets('H7: Zeit in Zonen und Spitzenpuls bleiben', (t) async {
    await pump(t);
    expect(find.textContaining('171'), findsWidgets);
  });

  testWidgets('H8: Pfeile neben dem Datum blättern zum Vortag', (t) async {
    final now = DateTime.now();
    final today = todayLabel();
    final yesterday = dayLabelOf(DateTime(now.year, now.month, now.day - 1));
    await pump(t, days: [today, yesterday]);
    expect(find.byKey(const ValueKey('takt-day-prev')), findsOneWidget);
  });
}
