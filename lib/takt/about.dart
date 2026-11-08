// Herkunft, Lizenz und Update-Hinweis in den Einstellungen.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ui2/profile/profile.dart' show SetRow, settingsGroup;
import '../ui2/ui2.dart';
import 'brand.dart';
import 'stripe/stripe.dart';
import 'stripe/stripe_setup.dart';
import 'takt_text.dart';
import 'update_check.dart';

void _open(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

class TaktAboutGroup extends StatelessWidget {
  const TaktAboutGroup({super.key});

  @override
  Widget build(BuildContext c) {
    final t = TaktText.of(c);
    return ValueListenableBuilder<TaktUpdate?>(
      valueListenable: taktUpdate,
      builder: (c, update, _) => settingsGroup(c, t.about, [
        if (update != null)
          SetRow(LucideIcons.download, C.orange, t.newVersion,
              sub: update.tag, onTap: () => _open(update.url)),
        SetRow(LucideIcons.heartPulse, C.n500, t.basedOn,
            sub: kUpstreamUrl, onTap: () => _open(kUpstreamUrl)),
        SetRow(LucideIcons.code, C.n500, t.sourceCode,
            sub: t.licenseLine, onTap: () => _open(kSourceUrl)),
        SetRow(LucideIcons.scale, C.n500, t.legal,
            chevron: false, onTap: () => _open('$kSourceUrl/blob/main/LICENSE')),
      ]),
    );
  }
}

/// Feature 02: Zeile „Displaystreifen" in den Einstellungen.
class TaktDisplayGroup extends StatelessWidget {
  const TaktDisplayGroup({super.key});

  @override
  Widget build(BuildContext c) {
    final t = TaktText.of(c);
    return ValueListenableBuilder<double?>(
      valueListenable: TaktStripe.fraction,
      builder: (c, f, _) => settingsGroup(c, t.display, [
        SetRow(LucideIcons.ruler, C.orange, t.stripeTitle,
            sub: t.stripeSub,
            value: f == null ? t.off : '${(f * 100).round()} %',
            onTap: () => Navigator.of(c).push(
                MaterialPageRoute<void>(builder: (_) => const StripeSetupScreen()))),
      ]),
    );
  }
}
