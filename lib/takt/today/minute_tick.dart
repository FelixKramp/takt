// Baut alle 30 Sekunden neu, damit „vor 2 Min" nicht stehen bleibt.
import 'dart:async';

import 'package:flutter/widgets.dart';

class MinuteTick extends StatefulWidget {
  const MinuteTick({super.key, required this.builder, this.onTick});
  final WidgetBuilder builder;
  final VoidCallback? onTick;

  @override
  State<MinuteTick> createState() => _MinuteTickState();
}

class _MinuteTickState extends State<MinuteTick> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      widget.onTick?.call();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => widget.builder(c);
}
