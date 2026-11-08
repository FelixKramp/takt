// Feature 02: Felix' Display hat einen weißen senkrechten Strich im rechten
// Drittel. In 0.1.2 verdeckte er die erste Ziffer der Schritte-Karte.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/takt/stripe/stripe.dart';

const gap = kStripeGap;

bool hits(Rect r, double x) => r.right > x - gap + 0.01 && r.left < x + gap - 0.01;

void main() {
  group('placeBlock', () {
    test('B4: ohne Streifen bleibt alles, wo es war', () {
      final p = placeBlock(boxW: 120, w: 60, preferred: 0, s: null);
      expect(p.dx, 0);
      expect(p.scale, 1);
    });

    test('B2: ein Streifen neben der Zahl ändert nichts', () {
      final p = placeBlock(boxW: 120, w: 60, preferred: 0, s: 100);
      expect(p.dx, 0);
      expect(p.scale, 1);
    });

    test('B2: Streifen auf der ersten Ziffer, die Zahl rückt nach rechts', () {
      final p = placeBlock(boxW: 120, w: 60, preferred: 0, s: 5);
      expect(p.scale, 1);
      expect(p.dx, greaterThanOrEqualTo(5 + gap));
      expect(p.dx + 60, lessThanOrEqualTo(120));
    });

    test('B2: Streifen am Ende, die Zahl rückt nach links', () {
      final p = placeBlock(boxW: 120, w: 60, preferred: 60, s: 110);
      expect(p.scale, 1);
      expect(p.dx + 60, lessThanOrEqualTo(110 - gap));
    });

    test('B3: passt auf keiner Seite, die Zahl schrumpft auf die größere', () {
      final p = placeBlock(boxW: 70, w: 60, preferred: 0, s: 30);
      expect(p.scale, lessThan(1));
      expect(p.scale, greaterThan(0));
      final right = p.dx + 60 * p.scale;
      expect(right <= 30 - gap + 0.01 || p.dx >= 30 + gap - 0.01, isTrue);
      expect(right, lessThanOrEqualTo(70.01));
    });
  });

  group('StripeDodge', () {
    Future<void> pump(WidgetTester t, Widget child) async {
      t.view.physicalSize = const Size(400, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      addTearDown(() => TaktStripe.fraction.value = null);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 200, top: 40),
              child: SizedBox(width: 160, child: child),
            ),
          ),
        ),
      ));
    }

    testWidgets('B4: ohne Streifen steht der Text genau wie ohne Hülle', (t) async {
      await pump(t, const StripeDodge(child: Text('1468', style: TextStyle(fontSize: 24))));
      final withHull = t.getRect(find.text('1468'));
      await pump(t, const Text('1468', style: TextStyle(fontSize: 24)));
      expect(withHull, t.getRect(find.text('1468')));
    });

    testWidgets('B2: Block, keine Ziffer auf dem Streifen', (t) async {
      TaktStripe.fraction.value = 205 / 400; // auf der ersten Ziffer
      await pump(t, const StripeDodge(child: Text('1468', style: TextStyle(fontSize: 24))));
      final ro = t.renderObject<RenderStripeDodge>(find.byType(StripeDodge));
      final rects = ro.paintedDigitRects();
      expect(rects, hasLength(4));
      for (final r in rects) {
        expect(hits(r, 205), isFalse, reason: '$r');
      }
    });

    testWidgets('B2: Zeile wird an der Wortgrenze geteilt', (t) async {
      TaktStripe.fraction.value = 260 / 400;
      await pump(
        t,
        const StripeDodge(
          line: true,
          child: Text('erkannt, 18:05, 1 Std 24 Min', style: TextStyle(fontSize: 13)),
        ),
      );
      final ro = t.renderObject<RenderStripeDodge>(find.byType(StripeDodge));
      final rects = ro.paintedDigitRects();
      expect(rects, hasLength(7));
      for (final r in rects) {
        expect(hits(r, 260), isFalse, reason: '$r');
        expect(r.right, lessThanOrEqualTo(360.01), reason: 'bleibt im Platz');
      }
    });

    testWidgets('B3: zu breit für beide Seiten, schrumpft statt verdeckt', (t) async {
      TaktStripe.fraction.value = 240 / 400;
      await pump(t, const StripeDodge(child: Text('88888', style: TextStyle(fontSize: 40))));
      final ro = t.renderObject<RenderStripeDodge>(find.byType(StripeDodge));
      final rects = ro.paintedDigitRects();
      expect(rects, hasLength(5));
      for (final r in rects) {
        expect(hits(r, 240), isFalse, reason: '$r');
        expect(r.left, greaterThanOrEqualTo(199.99));
        expect(r.right, lessThanOrEqualTo(360.01));
      }
    });

    testWidgets('B2: Querformat weicht nicht aus', (t) async {
      TaktStripe.fraction.value = 205 / 400;
      t.view.physicalSize = const Size(800, 400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(
        home: Scaffold(body: StripeDodge(child: Text('1468'))),
      ));
      final ro = t.renderObject<RenderStripeDodge>(find.byType(StripeDodge));
      expect(ro.stripeX, isNull);
      TaktStripe.fraction.value = null;
    });
  });
}
