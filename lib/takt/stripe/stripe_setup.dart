// Feature 02, B1: Lage des Displaystreifens einstellen. Eine orange Linie
// läuft über die ganze Höhe, der Schieberegler setzt sie grob, die Pfeile
// verschieben sie um einen halben Punkt.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ui2/ui2.dart';
import '../pult_tokens.dart';
import '../takt_text.dart';
import 'stripe.dart';

class StripeSetupScreen extends StatefulWidget {
  const StripeSetupScreen({super.key});

  @override
  State<StripeSetupScreen> createState() => _StripeSetupScreenState();
}

class _StripeSetupScreenState extends State<StripeSetupScreen> {
  late double _f = TaktStripe.fraction.value ?? 0.5;

  void _set(double f) => setState(() => _f = f.clamp(0.001, 0.999).toDouble());

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    final t = TaktText.of(c);
    final width = MediaQuery.sizeOf(c).width;
    final step = 0.5 / width;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(title: Text(t.stripeTitle)),
      body: Stack(
        children: [
          Positioned(
            left: S.x4,
            right: S.x4,
            bottom: S.x4,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.stripeHow, style: F.body.copyWith(color: p.ink)),
                  const SizedBox(height: S.x3),
                  Row(
                    children: [
                      _Nudge(
                        key: const ValueKey('stripe-left'),
                        icon: LucideIcons.chevronLeft,
                        label: t.nudgeLeft,
                        onTap: () => _set(_f - step),
                      ),
                      Expanded(
                        child: Slider(
                          value: _f,
                          min: 0.001,
                          max: 0.999,
                          activeColor: Pult.orange,
                          onChanged: _set,
                        ),
                      ),
                      _Nudge(
                        key: const ValueKey('stripe-right'),
                        icon: LucideIcons.chevronRight,
                        label: t.nudgeRight,
                        onTap: () => _set(_f + step),
                      ),
                    ],
                  ),
                  const SizedBox(height: S.x3),
                  BigButton(
                    t.save,
                    color: C.orange,
                    onTap: () {
                      TaktStripe.save(_f);
                      Navigator.of(c).maybePop();
                    },
                  ),
                  const SizedBox(height: S.x2),
                  BigButton(
                    t.remove,
                    color: C.orange,
                    soft: true,
                    onTap: () {
                      TaktStripe.clear();
                      Navigator.of(c).maybePop();
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            key: const ValueKey('stripe-line'),
            left: _f * width - 1,
            width: 2,
            top: 0,
            bottom: 0,
            child: const IgnorePointer(child: ColoredBox(color: Pult.orange)),
          ),
        ],
      ),
    );
  }
}

class _Nudge extends StatelessWidget {
  const _Nudge({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext c) {
    final p = P.of(c);
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: SizedBox(
        width: S.tap,
        height: S.tap,
        child: Icon(icon, size: 22, color: p.ink),
      ),
    );
  }
}
