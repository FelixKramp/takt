// Feature 06, T1: Die Takt-Haut gilt nur innerhalb von TaktLook.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/takt/look.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';
import 'package:openstrap_edge/ui2/grammar.dart';
import 'package:openstrap_edge/ui2/theme.dart';

Widget host(Widget w) => MaterialApp(
    theme: buildTheme(Brightness.light), home: Scaffold(body: Column(children: [w])));

BoxDecoration deco(WidgetTester t) => t
    .widgetList<Container>(find.descendant(of: find.byType(Surface), matching: find.byType(Container)))
    .first
    .decoration! as BoxDecoration;

void main() {
  testWidgets('F3–F12 Grundlage: Surface ohne TaktLook bleibt wie bisher', (t) async {
    await t.pumpWidget(host(const Surface(child: Text('x'))));
    final d = deco(t);
    expect(d.border, isNull);
    expect(d.boxShadow, isNotEmpty);
  });

  testWidgets('F3–F12 Grundlage: Surface in TaktLook ist eine Takt-Karte', (t) async {
    await t.pumpWidget(host(const TaktLook(child: Surface(child: Text('x')))));
    final d = deco(t);
    final b = d.border! as Border;
    expect(b.bottom.width, 3);
    expect(b.top.width, 1);
    expect(d.boxShadow ?? const [], isEmpty);
  });

  testWidgets('F10, F13: InlineMetrics in TaktLook mit Punktziffern im Streifen', (t) async {
    await t.pumpWidget(host(const TaktLook(
        child: InlineMetrics([('Puls im Schlaf', '54 bpm', Colors.red)]))));
    final txt = t.widget<Text>(find.text('54 bpm'));
    expect(txt.style?.fontFamily, 'Doto');
    expect(find.ancestor(of: find.text('54 bpm'), matching: find.byType(StripeDodge)),
        findsOneWidget);
    expect(find.text('Puls im Schlaf'), findsOneWidget);
  });
}
