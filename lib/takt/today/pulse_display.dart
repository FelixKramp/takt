// Das Puls-Display: Live-Wert, sonst der letzte Wert in Grau mit Uhrzeit und Grund.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../state/app_state.dart';
import '../../state/clock_format.dart' show formatClockOf;
import '../../ui2/profile/devices.dart' show MyDevices;
import '../../ui2/screens/home_screen.dart' show go;
import '../../ui2/ui2.dart';
import '../pult_tokens.dart';
import '../takt_text.dart';
import 'pulse_state.dart';
import 'visibility.dart';

const _kLastPulse = 'takt.last_pulse';
const kPulseHeight = 112.0;

/// Der echte Puls: besitzt den Live-Strom, solange er zu sehen ist.
class PulseDisplay extends StatefulWidget {
  const PulseDisplay({super.key});

  @override
  State<PulseDisplay> createState() => _PulseDisplayState();
}

class _PulseDisplayState extends State<PulseDisplay> with WidgetsBindingObserver {
  PulseStreamGate? _gate;
  LastPulse? _last;
  DateTime? _savedAt;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    taktTodayVisible.addListener(_sync);
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final last = LastPulse.decode(prefs.getString(_kLastPulse));
    if (mounted && _last == null) setState(() => _last = last);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gate == null) {
      final app = context.read<AppState>();
      _gate = PulseStreamGate(retain: app.retainLiveHrView, release: app.releaseLiveHrView);
    }
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    _gate?.update(_foreground && taktTodayVisible.value && current);
  }

  void _remember(int bpm) {
    final now = DateTime.now();
    _last = LastPulse(bpm, now);
    final saved = _savedAt;
    if (saved != null && now.difference(saved).inSeconds < 60) return;
    _savedAt = now;
    final encoded = _last!.encode();
    unawaited(SharedPreferences.getInstance()
        .then((p) => p.setString(_kLastPulse, encoded)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    taktTodayVisible.removeListener(_sync);
    _gate?.update(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final live = c.select<AppState, int?>((a) => a.liveHr);
    final paired = c.select<AppState, bool>((a) => a.isPaired);
    final connected = c.select<AppState, bool>((a) => a.isConnected);
    c.select<AppState, int>((a) => a.liveHrTraceRev);
    if (live != null) _remember(live);
    return PulseView(
      state: pulseStateOf(live: live, last: _last, paired: paired, connected: connected),
      trace: c.read<AppState>().liveHrTrace(),
      onPair: () => go(c, const MyDevices()),
    );
  }
}

/// Reine Darstellung, dadurch ohne Band testbar. Die Höhe bleibt in jedem
/// Zustand gleich, damit der Screen beim Trennen nicht springt.
class PulseView extends StatelessWidget {
  const PulseView({super.key, required this.state, this.trace = const [], this.onPair});

  final PulseState state;
  final List<int> trace;
  final VoidCallback? onPair;

  bool get _canPair =>
      state.kind == PulseKind.never &&
      state.reason == PulseReason.notPaired &&
      onPair != null;

  String _reason(TaktText t) => switch (state.reason) {
        PulseReason.notPaired => t.notPaired,
        PulseReason.notConnected => t.notConnected,
        PulseReason.notWorn =>
          state.kind == PulseKind.never ? t.waitingForPulse : t.notWorn,
        null => '',
      };

  @override
  Widget build(BuildContext c) {
    final t = TaktText.of(c);
    final live = state.kind == PulseKind.live;
    final ink = live ? Pult.lcdInk : Pult.lcdDim;
    final at = state.at;
    final lines = <String>[
      if (live) t.live,
      if (at != null) t.lastAt(formatClockOf(at)),
      if (!live) _reason(t),
    ];
    final body = Row(children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(state.bpm == null ? '--' : '${state.bpm}', style: Pult.digits(72, ink)),
      ),
      const SizedBox(width: S.x3),
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final line in lines) Text(line, style: F.cap.copyWith(color: ink)),
            if (_canPair)
              Text(t.pairBand, style: F.cap.copyWith(color: Pult.lcdInk)),
          ]),
        ),
      ),
      if (live && trace.length > 1)
        Semantics(
          label: t.pulseTrace,
          child: SizedBox(
            width: 112,
            height: 56,
            child: CustomPaint(painter: _TracePainter(trace)),
          ),
        ),
    ]);
    final box = Container(
      height: kPulseHeight,
      padding: const EdgeInsets.symmetric(horizontal: S.x4, vertical: S.x2),
      decoration: BoxDecoration(
        color: Pult.lcdBg,
        borderRadius: R.rSm,
        border: Border.all(color: Pult.lcdFrame, width: 3),
      ),
      child: body,
    );
    return _canPair
        ? Pressable(onTap: onPair, child: box)
        : box;
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter(this.trace);
  final List<int> trace;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = trace.reduce((a, b) => a < b ? a : b).toDouble();
    final hi = trace.reduce((a, b) => a > b ? a : b).toDouble();
    final span = (hi - lo).clamp(10.0, 200.0);
    final paint = Paint()..color = Pult.lcdInk;
    for (var i = 0; i < trace.length; i += 2) {
      final x = i / (trace.length - 1) * size.width;
      final y = size.height - (trace[i] - lo) / span * size.height;
      canvas.drawCircle(Offset(x, y.clamp(1.0, size.height - 1)), 1.3, paint);
    }
  }

  @override
  bool shouldRepaint(_TracePainter o) => !identical(o.trace, trace);
}
