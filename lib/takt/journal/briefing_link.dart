import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui2/grammar.dart' show Pressable;
import '../../ui2/theme.dart';
import '../look.dart';
import '../pult_tokens.dart';
import 'journal_text.dart';

/// Wo der Link liegt. Nur auf dem Gerät, in keinem Export, Bericht oder
/// KI-Chat (J32): Er steht in den App-Einstellungen, nicht in der Datenbank.
const String kBriefingLinkKey = 'takt.journal.briefing_url';

/// Nimmt nur https-Links auf drive.google.com an (J28), sonst null.
String? normalizeBriefingLink(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final u = Uri.tryParse(s);
  if (u == null || u.scheme != 'https' || u.host != 'drive.google.com') return null;
  if (u.path.length <= 1) return null;
  return u.toString();
}

Future<String?> loadBriefingLink() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(kBriefingLinkKey);
    return (v == null || v.isEmpty) ? null : v;
  } catch (_) {
    return null;
  }
}

Future<void> saveBriefingLink(String? url) async {
  final prefs = await SharedPreferences.getInstance();
  if (url == null || url.isEmpty) {
    await prefs.remove(kBriefingLinkKey);
  } else {
    await prefs.setString(kBriefingLinkKey, url);
  }
}

Future<bool> _launchExternal(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

/// Öffnet den Link außerhalb der App. In Tests austauschbar.
Future<bool> Function(Uri) briefingLauncher = _launchExternal;

/// Öffnet den Link und meldet einen Fehlschlag (J31) mit einer Zeile, ohne dass
/// das Blatt oder der Tab etwas verliert.
Future<void> openBriefing(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await briefingLauncher(Uri.parse(url));
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(JournalText.of(context).briefingOpenFailed)),
    );
  }
}

/// „Morgenbriefing anhören“ als schmale Zeile. Mit [onEdit] steht daneben ein
/// Stift (Journal-Tab), im Morgenblatt nicht.
class BriefingListenRow extends StatelessWidget {
  const BriefingListenRow({super.key, required this.url, this.onEdit});

  final String url;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final t = JournalText.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(S.x3, S.x2, S.x2, S.x2),
      decoration: BoxDecoration(
        color: p.card2,
        borderRadius: R.rMd,
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              key: const ValueKey('briefing-listen'),
              onTap: () => openBriefing(context, url),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Row(
                  children: [
                    Icon(LucideIcons.headphones, size: 20, color: p.ink),
                    const SizedBox(width: S.x2),
                    Expanded(
                      child: Text(
                        t.briefingListen,
                        style: F.body.copyWith(color: p.ink, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onEdit != null)
            Pressable(
              key: const ValueKey('briefing-edit'),
              onTap: onEdit!,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(LucideIcons.pencil, size: 18, color: p.ink2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Zeile für „noch kein Link“: öffnet das Einrichten (J28).
class BriefingSetupRow extends StatelessWidget {
  const BriefingSetupRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final t = JournalText.of(context);
    return Pressable(
      key: const ValueKey('briefing-setup'),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            Icon(LucideIcons.headphones, size: 18, color: p.ink2),
            const SizedBox(width: S.x2),
            Expanded(
              child: Text(t.briefingSetup, style: F.cap.copyWith(color: p.ink2)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blatt zum Einfügen, Ändern oder Entfernen des Links (J28).
class BriefingLinkSheet extends StatefulWidget {
  const BriefingLinkSheet({super.key, this.current});

  final String? current;

  @override
  State<BriefingLinkSheet> createState() => _BriefingLinkSheetState();
}

class _BriefingLinkSheetState extends State<BriefingLinkSheet> {
  late final TextEditingController _c = TextEditingController(text: widget.current ?? '');
  bool _invalid = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = normalizeBriefingLink(_c.text);
    if (url == null) {
      setState(() => _invalid = true);
      return;
    }
    await saveBriefingLink(url);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _remove() async {
    await saveBriefingLink(null);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final t = JournalText.of(context);
    return TaktLook(
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(R.md)),
        ),
        padding: EdgeInsets.fromLTRB(
          S.x3,
          S.x2,
          S.x3,
          MediaQuery.viewInsetsOf(context).bottom + S.x4,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.ink2.withValues(alpha: 0.3),
                    borderRadius: R.rSm,
                  ),
                ),
              ),
              const SizedBox(height: S.x3),
              Text(
                t.briefingLinkTitle,
                style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: S.x1),
              Text(t.briefingLinkHint, style: F.cap.copyWith(color: p.ink2)),
              const SizedBox(height: S.x3),
              TextField(
                key: const ValueKey('briefing-link-field'),
                controller: _c,
                autofocus: true,
                keyboardType: TextInputType.url,
                style: F.body.copyWith(color: p.ink),
                onChanged: (_) {
                  if (_invalid) setState(() => _invalid = false);
                },
                decoration: InputDecoration(
                  hintText: 'https://drive.google.com/…',
                  hintStyle: F.body.copyWith(color: p.ink2.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: p.card2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(R.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x2),
                ),
              ),
              if (_invalid) ...[
                const SizedBox(height: S.x1),
                Text(
                  t.briefingInvalid,
                  key: const ValueKey('briefing-link-invalid'),
                  style: F.cap.copyWith(color: Pult.orangeFor(p.dark)),
                ),
              ],
              const SizedBox(height: S.x3),
              Pressable(
                key: const ValueKey('briefing-link-save'),
                onTap: _save,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.card2,
                    borderRadius: R.rMd,
                    border: Border.all(color: p.ink3, width: 1.5),
                  ),
                  child: Text(
                    t.save,
                    style: F.body.copyWith(color: p.ink, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (widget.current != null) ...[
                const SizedBox(height: S.x1),
                Pressable(
                  key: const ValueKey('briefing-link-remove'),
                  onTap: _remove,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    child: Text(t.briefingRemove, style: F.cap.copyWith(color: p.ink2)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
