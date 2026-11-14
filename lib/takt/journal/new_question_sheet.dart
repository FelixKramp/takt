import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/db.dart';
import '../../data/journal_fields.dart';
import '../../ui2/grammar.dart' show Pressable;
import '../../ui2/theme.dart';
import '../look.dart';
import '../pult_tokens.dart';
import 'journal_config.dart';
import 'journal_text.dart';

/// Blatt zum Anlegen einer eigenen Frage (J9, J20).
class NewQuestionSheet extends StatefulWidget {
  const NewQuestionSheet({
    super.key,
    required this.config,
    this.onCreated,
  });

  final JournalConfig config;
  final void Function(JournalQuestion)? onCreated;

  @override
  State<NewQuestionSheet> createState() => _NewQuestionSheetState();
}

class _NewQuestionSheetState extends State<NewQuestionSheet> {
  final _controller = TextEditingController();
  JournalSection _section = JournalSection.yesterday;
  bool _isPrivate = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      final q = await widget.config.addCustomQuestion(
        name: name,
        section: _section,
        isPrivate: _isPrivate,
      );

      // In journal_field_def speichern:
      final db = await LocalDb.instance;
      await db.insert(
        'journal_field_def',
        {
          'key': q.key,
          'label': q.defaultLabel,
          'kind': JournalFieldKind.dose.name,
          'unit': '',
          'max_value': 1.0,
          'step': 1.0,
          'has_time': 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      widget.onCreated?.call(q);
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).maybePop(q);
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
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
                t.newQuestionTitle,
                style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: S.x3),

              // Name der Frage
              Text(t.questionName, style: F.cap.copyWith(color: p.ink2)),
              const SizedBox(height: S.x1),
              TextField(
                key: const ValueKey('new-question-name-field'),
                controller: _controller,
                autofocus: true,
                style: F.body.copyWith(color: p.ink),
                decoration: InputDecoration(
                  hintText: t.questionNameHint,
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
              const SizedBox(height: S.x3),

              // Bezug: Gestern oder Heute (J9)
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      key: const ValueKey('new-question-section-yesterday'),
                      onTap: () => setState(() => _section = JournalSection.yesterday),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _section == JournalSection.yesterday ? Pult.orange : p.card2,
                          borderRadius: R.rSm,
                        ),
                        child: Text(
                          t.yesterday,
                          style: F.cap.copyWith(
                            color: _section == JournalSection.yesterday ? Colors.white : p.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: S.x2),
                  Expanded(
                    child: Pressable(
                      key: const ValueKey('new-question-section-today'),
                      onTap: () => setState(() => _section = JournalSection.today),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _section == JournalSection.today ? Pult.orange : p.card2,
                          borderRadius: R.rSm,
                        ),
                        child: Text(
                          t.today,
                          style: F.cap.copyWith(
                            color: _section == JournalSection.today ? Colors.white : p.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: S.x3),

              // Privat Schalter (J20)
              Pressable(
                key: const ValueKey('new-question-private-toggle'),
                onTap: () => setState(() => _isPrivate = !_isPrivate),
                child: Container(
                  padding: const EdgeInsets.all(S.x2),
                  decoration: BoxDecoration(
                    color: p.card2,
                    borderRadius: R.rSm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPrivate ? Icons.lock : Icons.lock_open,
                        size: 20,
                        color: _isPrivate ? Pult.orange : p.ink2,
                      ),
                      const SizedBox(width: S.x2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.markAsPrivate,
                              style: F.body.copyWith(
                                color: p.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              t.privateHint,
                              style: F.cap.copyWith(color: p.ink2),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isPrivate,
                        activeTrackColor: Pult.orange,
                        onChanged: (v) => setState(() => _isPrivate = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: S.x4),

              // Speichern / Abbrechen
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: S.x3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.card2,
                          borderRadius: R.rSm,
                        ),
                        child: Text(t.cancel, style: F.body.copyWith(color: p.ink2)),
                      ),
                    ),
                  ),
                  const SizedBox(width: S.x3),
                  Expanded(
                    child: Pressable(
                      key: const ValueKey('new-question-save-btn'),
                      onTap: _handleSave,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: S.x3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Pult.orange,
                          borderRadius: R.rSm,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                t.save,
                                style: F.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blatt zum Bearbeiten des Anzeigenamens / Ein-Ausschalten / Ausblenden (J10, J11).
class EditQuestionSheet extends StatefulWidget {
  const EditQuestionSheet({
    super.key,
    required this.config,
    required this.question,
    this.onChanged,
  });

  final JournalConfig config;
  final JournalQuestion question;
  final VoidCallback? onChanged;

  @override
  State<EditQuestionSheet> createState() => _EditQuestionSheetState();
}

class _EditQuestionSheetState extends State<EditQuestionSheet> {
  late final TextEditingController _controller;
  late bool _showInSheet;
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.question.customLabel ?? '');
    _showInSheet = widget.question.showInSheet;
    _hidden = widget.question.hidden;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final customName = _controller.text.trim();
    await widget.config.setDisplayName(widget.question.key, customName.isEmpty ? null : customName);
    await widget.config.setShowInSheet(widget.question.key, _showInSheet);
    await widget.config.setHidden(widget.question.key, _hidden);
    widget.onChanged?.call();
    if (mounted) Navigator.of(context).pop();
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
                widget.question.defaultLabel,
                style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: S.x3),

              // Anzeigename (J10)
              Text(t.displayName, style: F.cap.copyWith(color: p.ink2)),
              const SizedBox(height: S.x1),
              TextField(
                key: const ValueKey('edit-question-display-name-field'),
                controller: _controller,
                style: F.body.copyWith(color: p.ink),
                decoration: InputDecoration(
                  hintText: widget.question.defaultLabel,
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
              const SizedBox(height: S.x3),

              // Im Morgenblatt zeigen (J11)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.showInMorningSheet, style: F.body.copyWith(color: p.ink)),
                  Switch.adaptive(
                    key: const ValueKey('edit-question-show-in-sheet-switch'),
                    value: _showInSheet,
                    activeTrackColor: Pult.orange,
                    onChanged: (v) => setState(() => _showInSheet = v),
                  ),
                ],
              ),
              const SizedBox(height: S.x2),

              // Ausblenden / Löschen (J11)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _hidden ? t.unhideQuestion : t.hideQuestion,
                    style: F.body.copyWith(color: _hidden ? Pult.orange : p.on(C.red)),
                  ),
                  Switch.adaptive(
                    key: const ValueKey('edit-question-hidden-switch'),
                    value: _hidden,
                    activeTrackColor: p.on(C.red),
                    onChanged: (v) => setState(() => _hidden = v),
                  ),
                ],
              ),
              const SizedBox(height: S.x4),

              // Speichern
              Pressable(
                key: const ValueKey('edit-question-save-btn'),
                onTap: _handleSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: S.x3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Pult.orange,
                    borderRadius: R.rSm,
                  ),
                  child: Text(
                    t.save,
                    style: F.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
