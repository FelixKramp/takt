// Feature 02, Displaystreifen: Manche Displays haben einen festen senkrechten
// Strich, der Pixel verdeckt. Wer seine Lage einstellt, bekommt jede Zahl im
// Takt-Design so gesetzt, dass der Strich keine Ziffer trifft. Ohne
// Einstellung reicht [StripeDodge] Layout und Zeichnen unverändert durch.
//
// Designregel (B5): Jede Zahl, die Takt zeigt, steht in einem [StripeDodge].
// Einzelwerte als Block, Zeilen mit Zahlen darin mit `line: true`.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../state/prefs.dart';

/// Abstand zu beiden Seiten der Streifenmitte, in logischen Pixeln.
const double kStripeGap = 6;

/// Zusätzlicher Platz für eine Zahl ohne Breitenvorgabe (etwa in einer Zeile
/// neben anderem Inhalt). Fest, damit die Zeile auch bei großer Schrift nicht
/// überläuft. Reicht er nicht, schrumpft die Zahl (B3).
const double kStripeReserve = 2 * kStripeGap + 24;

/// Die eingestellte Lage des Streifens als Anteil der Bildschirmbreite im
/// Hochformat. `null` heißt aus.
class TaktStripe {
  TaktStripe._();

  static const String key = 'takt.stripe_x';
  static final ValueNotifier<double?> fraction = ValueNotifier<double?>(null);

  /// Liest die gespeicherte Lage aus den Prefs. Braucht `Prefs.ensureLoaded`.
  static void load() {
    final raw = Prefs.getString(key, '');
    final v = double.tryParse(raw);
    fraction.value = (v != null && v > 0 && v < 1) ? v : null;
  }

  static void save(double f) {
    final v = f.clamp(0.001, 0.999).toDouble();
    Prefs.setString(key, v.toString());
    fraction.value = v;
  }

  static void clear() {
    Prefs.setString(key, '');
    fraction.value = null;
  }
}

@immutable
class Placement {
  const Placement(this.dx, this.scale);
  final double dx, scale;
  @override
  String toString() => 'Placement($dx, $scale)';
}

/// Wohin ein Wert der Breite [w] in einem Platz `[0, boxW]` rückt, wenn der
/// Streifen bei [s] liegt (lokal, `null` heißt aus). [preferred] ist seine
/// Lage ohne Streifen. Passt er auf keiner Seite, schrumpft er auf die größere.
Placement placeBlock({
  required double boxW,
  required double w,
  required double preferred,
  required double? s,
  double gap = kStripeGap,
}) {
  if (s == null || w <= 0) return Placement(preferred, 1);
  final lo = s - gap, hi = s + gap;
  if (preferred + w <= lo || preferred >= hi) return Placement(preferred, 1);
  final leftRoom = lo.clamp(0.0, boxW).toDouble();
  final rightStart = hi.clamp(0.0, boxW).toDouble();
  final rightRoom = boxW - rightStart;
  Placement? best;
  void consider(Placement p) {
    if (best == null ||
        (p.dx - preferred).abs() < (best!.dx - preferred).abs()) {
      best = p;
    }
  }

  if (w <= leftRoom) consider(Placement(math.min(preferred, leftRoom - w), 1));
  if (w <= rightRoom) consider(Placement(math.max(preferred, rightStart), 1));
  if (best != null) return best!;
  if (leftRoom >= rightRoom) return Placement(0, leftRoom / w);
  return Placement(rightStart, rightRoom / w);
}

/// Hülle um eine Zahl (Block) oder eine Textzeile mit Zahlen (`line: true`).
class StripeDodge extends StatelessWidget {
  const StripeDodge({
    super.key,
    required this.child,
    this.align = 0,
    this.line = false,
    this.reserve,
  });

  final Widget child;

  /// Lage ohne Streifen, 0 links, 0.5 Mitte, 1 rechts. Nur für Block.
  final double align;

  /// Teilt eine Textzeile an der Wortgrenze vor dem Streifen. Das Kind muss
  /// dann direkt ein `Text` sein.
  final bool line;

  /// Zusätzlicher Platz, wenn die Hülle keine Breitenvorgabe bekommt. `null`
  /// heißt [kStripeReserve].
  final double? reserve;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ValueListenableBuilder<double?>(
      valueListenable: TaktStripe.fraction,
      builder: (_, f, _) => _StripeDodgeBox(
        stripeX: f == null || size.width > size.height ? null : f * size.width,
        align: align,
        line: line,
        reserve: reserve,
        child: child,
      ),
    );
  }
}

class _StripeDodgeBox extends SingleChildRenderObjectWidget {
  const _StripeDodgeBox({
    required this.stripeX,
    required this.align,
    required this.line,
    required this.reserve,
    required super.child,
  });

  final double? stripeX;
  final double align;
  final bool line;
  final double? reserve;

  @override
  RenderStripeDodge createRenderObject(BuildContext context) =>
      RenderStripeDodge(
        stripeX: stripeX,
        align: align,
        line: line,
        reserve: reserve,
      );

  @override
  void updateRenderObject(BuildContext context, RenderStripeDodge r) {
    r
      ..stripeX = stripeX
      ..align = align
      ..line = line
      ..reserve = reserve;
  }
}

/// Ein Stück des Kindes: [src] im Kind-Koordinatensystem, gezeichnet mit [m].
class _Seg {
  _Seg(this.src, this.m);
  final Rect src;
  final Matrix4 m;
}

class RenderStripeDodge extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  RenderStripeDodge({
    double? stripeX,
    double align = 0,
    bool line = false,
    double? reserve,
  }) : _stripeX = stripeX,
       _align = align,
       _line = line,
       _reserve = reserve;

  double? _stripeX;
  double? get stripeX => _stripeX;
  set stripeX(double? v) {
    if (v == _stripeX) return;
    _stripeX = v;
    markNeedsLayout();
  }

  double _align;
  set align(double v) {
    if (v == _align) return;
    _align = v;
    markNeedsPaint();
  }

  bool _line;
  set line(bool v) {
    if (v == _line) return;
    _line = v;
    markNeedsLayout();
  }

  double? _reserve;
  set reserve(double? v) {
    if (v == _reserve) return;
    _reserve = v;
    markNeedsLayout();
  }

  bool get _on => _stripeX != null;

  RenderParagraph? get _paragraph {
    final c = child;
    return _line && c is RenderParagraph ? c : null;
  }

  // Intrinsische Maße wie das Kind, damit Zeilen und Spalten gleich rechnen.
  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMinIntrinsicWidth(height) ?? 0;
  @override
  double computeMaxIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(height) ?? 0;
  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(width) ?? 0;
  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(width) ?? 0;

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      child?.getDistanceToActualBaseline(baseline);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child;
    if (c == null) return constraints.smallest;
    if (!_on) return c.getDryLayout(constraints);
    final cs = c.getDryLayout(_line ? constraints : constraints.loosen());
    return _sizeFor(constraints, cs);
  }

  Size _sizeFor(BoxConstraints constraints, Size cs) {
    final double w;
    if (constraints.hasBoundedWidth) {
      w = constraints.maxWidth;
    } else if (_line) {
      w = cs.width;
    } else {
      w = cs.width + (_reserve ?? kStripeReserve);
    }
    return constraints.constrain(Size(w, cs.height));
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    if (!_on) {
      c.layout(constraints, parentUsesSize: true);
      size = c.size;
      return;
    }
    c.layout(_line ? constraints : constraints.loosen(), parentUsesSize: true);
    size = _sizeFor(constraints, c.size);
  }

  // ── Plan: welche Stücke des Kindes wohin ──────────────────────────────────

  List<_Seg> _plan() {
    final c = child!;
    final all = Rect.largest;
    if (!_on || !attached) return [_Seg(all, Matrix4.identity())];
    final s = _stripeX! - localToGlobal(Offset.zero).dx;
    final p = _paragraph;
    if (p == null) {
      // Mit der gezeichneten Ausdehnung rechnen: Glyphen ragen teils über
      // die Box ihres Absatzes hinaus.
      final ext = _extent(c);
      final w = ext.width;
      final pl = placeBlock(
        boxW: size.width,
        w: w,
        preferred: (size.width - c.size.width) * _align + ext.left,
        s: s,
      );
      return [_Seg(all, _blockMatrix(pl, ext.left, c.size.height))];
    }
    return _linePlan(p, s);
  }

  /// Box des Kindes vereint mit allen Glyphen darin, in Kind-Koordinaten.
  Rect _extent(RenderBox c) {
    var r = Offset.zero & c.size;
    void visit(RenderObject o) {
      if (o is RenderParagraph) {
        final n = o.text.toPlainText(includeSemanticsLabels: false).length;
        final toChild = o == c ? Matrix4.identity() : o.getTransformTo(c);
        for (final b in o.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: n),
        )) {
          r = r.expandToInclude(MatrixUtils.transformRect(toChild, b.toRect()));
        }
      }
      o.visitChildren(visit);
    }

    visit(c);
    return r;
  }

  /// Bildet den linken Rand [left] der Ausdehnung auf `pl.dx` ab.
  Matrix4 _blockMatrix(Placement pl, double left, double h) {
    final dy = h * (1 - pl.scale) / 2;
    return Matrix4.translationValues(pl.dx - pl.scale * left, dy, 0)
      ..multiply(Matrix4.diagonal3Values(pl.scale, pl.scale, 1));
  }

  /// Zeichen der Zeile als (Index, Rechteck), gruppiert nach Textzeile.
  List<List<(int, Rect)>> _lines(RenderParagraph p) {
    final text = p.text.toPlainText(includeSemanticsLabels: false);
    final lines = <List<(int, Rect)>>[];
    for (var i = 0; i < text.length; i++) {
      final boxes = p.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      if (boxes.isEmpty) continue;
      final r = boxes.first.toRect();
      if (lines.isEmpty ||
          (r.center.dy - lines.last.first.$2.center.dy).abs() > r.height / 2) {
        lines.add([]);
      }
      lines.last.add((i, r));
    }
    return lines;
  }

  List<_Seg> _linePlan(RenderParagraph p, double s) {
    final text = p.text.toPlainText(includeSemanticsLabels: false);
    final lo = s - kStripeGap, hi = s + kStripeGap;
    final lines = _lines(p);
    if (lines.isEmpty) return [_Seg(Rect.largest, Matrix4.identity())];
    bool space(int i) => text[i].trim().isEmpty;

    // Eine Zeile: erst als Ganzes ausweichen, ohne zu schrumpfen.
    if (lines.length == 1) {
      final l = lines.first;
      final left = l.first.$2.left, right = l.last.$2.right;
      final pl = placeBlock(
        boxW: size.width,
        w: right - left,
        preferred: left,
        s: s,
      );
      if (pl.scale == 1) {
        return [
          _Seg(Rect.largest, Matrix4.translationValues(pl.dx - left, 0, 0)),
        ];
      }
    }

    final segs = <_Seg>[];
    for (var n = 0; n < lines.length; n++) {
      final l = lines[n];
      final top = n == 0
          ? -1e9
          : (lines[n - 1].first.$2.bottom + l.first.$2.top) / 2;
      final bottom = n == lines.length - 1
          ? 1e9
          : (l.first.$2.bottom + lines[n + 1].first.$2.top) / 2;
      final k = l.indexWhere(
        (e) => !space(e.$1) && e.$2.right > lo && e.$2.left < hi,
      );
      if (k < 0) {
        segs.add(
          _Seg(Rect.fromLTRB(-1e9, top, 1e9, bottom), Matrix4.identity()),
        );
        continue;
      }
      var ws = k;
      while (ws > 0 && !space(l[ws - 1].$1)) {
        ws--;
      }
      final bx = l[ws].$2.left;
      final restW = l.last.$2.right - bx;
      final room = size.width - hi;
      final scale = room <= 0
          ? 0.3
          : math.max(0.3, math.min(1.0, room / restW));
      final cy = l.first.$2.center.dy;
      final m = Matrix4.translationValues(hi, cy, 0)
        ..multiply(Matrix4.diagonal3Values(scale, scale, 1))
        ..multiply(Matrix4.translationValues(-bx, -cy, 0));
      segs.add(_Seg(Rect.fromLTRB(-1e9, top, bx, bottom), Matrix4.identity()));
      segs.add(_Seg(Rect.fromLTRB(bx, top, 1e9, bottom), m));
    }
    return segs;
  }

  // ── Zeichnen, Treffer, Transformation ─────────────────────────────────────

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    if (!_on) {
      context.paintChild(c, offset);
      return;
    }
    final segs = _plan();
    if (c.needsCompositing || c.isRepaintBoundary) {
      // Kann nicht in Stücken gezeichnet werden: als Ganzes verschieben.
      context.pushTransform(
        needsCompositing,
        offset,
        segs.first.m,
        (ctx, o) => ctx.paintChild(c, o),
      );
      return;
    }
    for (final seg in segs) {
      final canvas = context.canvas;
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.transform(seg.m.storage);
      if (seg.src != Rect.largest) canvas.clipRect(seg.src);
      context.paintChild(c, Offset.zero);
      context.canvas.restore();
    }
  }

  Matrix4 get _childMatrix {
    if (!_on || _paragraph != null || child == null) return Matrix4.identity();
    return _plan().first.m;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_childMatrix);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    return result.addWithPaintTransform(
      transform: _childMatrix,
      position: position,
      hitTest: (r, p) => c.hitTest(r, position: p),
    );
  }

  /// Wo die Ziffern tatsächlich gezeichnet werden, in globalen Koordinaten.
  /// Für Tests und die Prüfung von B2.
  List<Rect> paintedDigitRects() {
    final c = child;
    if (c == null) return const [];
    final segs = _plan();
    final out = <Rect>[];
    void visit(RenderObject o) {
      if (o is RenderParagraph) {
        final text = o.text.toPlainText(includeSemanticsLabels: false);
        final toChild = o == c ? Matrix4.identity() : o.getTransformTo(c);
        for (var i = 0; i < text.length; i++) {
          if (!RegExp(r'\d').hasMatch(text[i])) continue;
          final boxes = o.getBoxesForSelection(
            TextSelection(baseOffset: i, extentOffset: i + 1),
          );
          if (boxes.isEmpty) continue;
          final r = MatrixUtils.transformRect(toChild, boxes.first.toRect());
          final seg = segs.firstWhere(
            (sg) => sg.src.contains(r.center),
            orElse: () => segs.first,
          );
          final mine = MatrixUtils.transformRect(seg.m, r);
          out.add(mine.shift(localToGlobal(Offset.zero)));
        }
      }
      o.visitChildren(visit);
    }

    visit(c);
    return out;
  }
}
