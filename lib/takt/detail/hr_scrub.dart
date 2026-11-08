// Feature 09, W4 bis W7: eine Pulskurve, die man ablesen kann. Finger
// auflegen und wischen zeigt Uhrzeit und Puls der Minute darüber. Der Wert
// bleibt nach dem Loslassen stehen. Beim Nachtragen kommen ein hinterlegter
// Zeitraum und die Knöpfe „Beginn hier“ und „Ende hier“ dazu.

import 'package:flutter/material.dart';

import '../../data/journal_fields.dart' show formatMinuteOfDay;
import '../../ui2/charts.dart' show AxisSpec, LineChart;
import '../../ui2/grammar.dart' show ChartFrame;
import '../../l10n/app_localizations.dart';
import '../../ui2/theme.dart';
import '../pult_tokens.dart';
import '../stripe/stripe.dart';
import '../takt_text.dart';

String _clock(DateTime d) => formatMinuteOfDay(d.hour * 60 + d.minute);

class TaktHrScrub extends StatefulWidget {
  const TaktHrScrub({
    super.key,
    required this.hr,
    required this.t0,
    required this.title,
    this.xLabels,
    this.footnote,
    this.window,
    this.onStart,
    this.onEnd,
    this.height = 130,
  });

  /// Ein Wert pro Minute, null ohne Messung. [hr] Index 0 ist [t0].
  final List<double?> hr;
  final DateTime t0;
  final String title;

  /// Ohne Angabe die Uhrzeit des ersten und letzten Punkts.
  final List<String>? xLabels;
  final String? footnote;

  /// Hinterlegter Zeitraum als Anteil 0…1 der Breite (W6).
  final (double, double)? window;

  /// Zeigt nach dem Antippen „Beginn hier“ und „Ende hier“ (W7).
  final ValueChanged<DateTime>? onStart, onEnd;
  final double height;

  @override
  State<TaktHrScrub> createState() => _TaktHrScrubState();
}

class _TaktHrScrubState extends State<TaktHrScrub> {
  int? _held;

  int get _n => widget.hr.length;

  @override
  void didUpdateWidget(TaktHrScrub old) {
    super.didUpdateWidget(old);
    // Neue Kurve (beim Nachtragen nach einer neuen Zeit): Die alte Minute
    // passt nicht mehr dazu.
    if (old.t0 != widget.t0 || old.hr.length != widget.hr.length) _held = null;
  }

  DateTime _at(int i) => widget.t0.add(Duration(minutes: i));

  int _index(double v) => (v * (_n - 1)).round().clamp(0, _n - 1);

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    final ink = Pult.orangeFor(p.dark);
    final axis = AxisSpec.of(widget.hr.whereType<double>());
    final held = _held;
    final sel = held == null || _n < 2 ? null : held / (_n - 1);
    final w = widget.window;

    Widget plot = Stack(children: [
      if (w != null)
        Positioned.fill(
          child: CustomPaint(
            key: const ValueKey('takt-hr-window'),
            painter: _WindowPainter(w.$1, w.$2, ink.withValues(alpha: .12)),
          ),
        ),
      Positioned.fill(
        child: CustomPaint(
          painter: LineChart(widget.hr, ink, axis: axis, selectedX: sel),
        ),
      ),
    ]);
    if (_n >= 2) {
      // Prüfung 09: Nur waagrechtes Wischen und Antippen lesen ab. Ein
      // senkrechter Wisch scrollt die Seite, ohne eine Minute zu setzen, und
      // ein schräger Wisch scrollt nicht mit. OpenStraps `Scrubber` hört auf
      // jeden Fingerkontakt und kann das nicht trennen.
      String describe(int i) {
        final bpm = widget.hr[i];
        return '${_clock(_at(i))}, ${bpm == null ? t.noReading : '${bpm.round()} bpm'}';
      }

      final up = ((held ?? -1) + 1).clamp(0, _n - 1);
      final down = ((held ?? _n) - 1).clamp(0, _n - 1);
      final inner = plot;
      plot = Semantics(
        label: widget.title,
        slider: true,
        value: held == null
            ? (AppLocalizations.of(c)?.scrubberNothingSelected ?? 'Nothing selected')
            : describe(held),
        increasedValue: describe(up),
        decreasedValue: describe(down),
        onIncrease: () => setState(() => _held = up),
        onDecrease: () => setState(() => _held = down),
        child: LayoutBuilder(
          key: const ValueKey('takt-hr-scrub'),
          builder: (_, box) {
            void set(Offset o) => setState(() =>
                _held = _index(box.maxWidth <= 0 ? 0 : (o.dx / box.maxWidth).clamp(0.0, 1.0)));
            return GestureDetector(
              // Der Screenreader nutzt die Schritte des Schiebereglers oben,
              // nicht Tippen und Wischen.
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              onTapUp: (e) => set(e.localPosition),
              onHorizontalDragStart: (e) => set(e.localPosition),
              onHorizontalDragUpdate: (e) => set(e.localPosition),
              child: inner,
            );
          },
        ),
      );
    }

    final bpm = held == null ? null : widget.hr[held];
    final readout = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 34),
      child: held == null
          ? Align(
              alignment: Alignment.centerLeft,
              child: StripeDodge(
                line: true,
                child: Text(t.scrubHint, style: F.cap.copyWith(color: p.ink3)),
              ),
            )
          // Prüfung 09: Bei großer Schrift und schmalem Handy werden beide
          // Seiten kleiner gerechnet statt abgeschnitten.
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: StripeDodge(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: KeyedSubtree(
                        key: const ValueKey('takt-hr-time'),
                        child: Text(_clock(_at(held)), style: Pult.digits(22, p.ink)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: S.x3),
                Flexible(
                  child: StripeDodge(
                    align: 1,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          KeyedSubtree(
                            key: const ValueKey('takt-hr-bpm'),
                            child: Text(bpm == null ? '–' : '${bpm.round()}',
                                style: Pult.digits(22, p.ink)),
                          ),
                          const SizedBox(width: S.x1),
                          Text(bpm == null ? t.noReading : 'bpm',
                              style: F.cap.copyWith(color: p.ink2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );

    final last = _at(_n - 1);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      readout,
      const SizedBox(height: S.x2),
      ChartFrame(
        title: widget.title,
        unit: 'bpm',
        height: widget.height,
        yAxis: axis,
        xLabels: widget.xLabels ?? [_clock(widget.t0), _clock(last)],
        footnote: widget.footnote,
        series: widget.hr,
        child: plot,
      ),
      if (held != null && (widget.onStart != null || widget.onEnd != null)) ...[
        const SizedBox(height: S.x3),
        Row(children: [
          if (widget.onStart != null)
            Expanded(
              child: TextButton(
                key: const ValueKey('takt-hr-set-start'),
                onPressed: () => widget.onStart!(_at(held)),
                child: Text(t.startHere),
              ),
            ),
          if (widget.onStart != null && widget.onEnd != null) const SizedBox(width: S.x2),
          if (widget.onEnd != null)
            Expanded(
              child: TextButton(
                key: const ValueKey('takt-hr-set-end'),
                onPressed: () => widget.onEnd!(_at(held)),
                child: Text(t.endHere),
              ),
            ),
        ]),
      ],
    ]);
  }
}

class _WindowPainter extends CustomPainter {
  _WindowPainter(this.a, this.b, this.color);
  final double a, b;
  final Color color;

  @override
  void paint(Canvas cv, Size s) {
    final l = (a.clamp(0.0, 1.0)) * s.width;
    final r = (b.clamp(0.0, 1.0)) * s.width;
    if (r <= l) return;
    cv.drawRect(Rect.fromLTRB(l, 0, r, s.height), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WindowPainter o) => o.a != a || o.b != b || o.color != color;
}
