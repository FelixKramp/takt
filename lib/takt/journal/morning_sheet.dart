import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../ui2/grammar.dart' show Pressable;
import '../../ui2/theme.dart';
import '../header.dart' show dayShortLabel;
import '../look.dart';
import '../pult_tokens.dart';
import '../stripe/stripe.dart';
import 'briefing_link.dart';
import 'journal_config.dart';
import 'journal_text.dart';

class MorningSheet extends StatefulWidget {
  const MorningSheet({
    super.key,
    required this.config,
    required this.calYesterday,
    required this.calToday,
    this.initialYesterdayAnswers = const {},
    this.initialTodayAnswers = const {},
    required this.onSave,
    required this.onDismiss,
    this.onOpenFullJournal,
  });

  final JournalConfig config;
  final String calYesterday;
  final String calToday;
  final Map<String, double> initialYesterdayAnswers;
  final Map<String, double> initialTodayAnswers;
  final Future<void> Function(
    Map<String, double> yesterday,
    Map<String, double> today,
  ) onSave;
  final Future<void> Function() onDismiss;
  final VoidCallback? onOpenFullJournal;

  @override
  State<MorningSheet> createState() => _MorningSheetState();
}

class _MorningSheetState extends State<MorningSheet> {
  late final Map<String, double> _yesterdayAnswers;
  late final Map<String, double> _todayAnswers;
  bool _saving = false;
  String? _error;
  String? _briefingLink;

  @override
  void initState() {
    super.initState();
    _yesterdayAnswers = Map.of(widget.initialYesterdayAnswers);
    _todayAnswers = Map.of(widget.initialTodayAnswers);
    loadBriefingLink().then((v) {
      if (mounted && v != null) setState(() => _briefingLink = v);
    });
  }

  void _toggleYesterday(String key, double value) {
    setState(() {
      if (_yesterdayAnswers[key] == value) {
        _yesterdayAnswers.remove(key);
      } else {
        _yesterdayAnswers[key] = value;
      }
    });
  }

  void _toggleToday(String key, double value) {
    setState(() {
      if (_todayAnswers[key] == value) {
        _todayAnswers.remove(key);
      } else {
        _todayAnswers[key] = value;
      }
    });
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_yesterdayAnswers, _todayAnswers);
      if (mounted) {
        setState(() => _saving = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = JournalText.of(context).saveError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final t = JournalText.of(context);
    final de = t.de;

    final yQuestions = widget.config.sheetQuestionsYesterday;
    final tQuestions = widget.config.sheetQuestionsToday;

    final yLabel = dayShortLabel(widget.calYesterday, de);
    final tLabel = dayShortLabel(widget.calToday, de);

    final totalCount = yQuestions.length + tQuestions.length;
    final answeredCount = yQuestions.where((q) => _yesterdayAnswers.containsKey(q.key)).length +
        tQuestions.where((q) => _todayAnswers.containsKey(q.key)).length;
    final allDone = totalCount > 0 && answeredCount == totalCount;
    final anim = motion(context, Motion.fast);

    return TaktLook(
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(R.md)),
          border: Border(top: BorderSide(color: p.line, width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(S.x3, S.x2, S.x3, S.x3),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pult-Griffmulde + Kopfzeile mit Punktmatrix-Zähler
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.line,
                    borderRadius: R.rSm,
                  ),
                ),
              ),
              const SizedBox(height: S.x2),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      de ? 'Morgenblatt' : 'Morning check',
                      style: F.t2.copyWith(color: p.ink),
                    ),
                  ),
                  if (totalCount > 0) ...[
                    const SizedBox(width: S.x2),
                    AnimatedContainer(
                      duration: anim,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Pult.lcdBg,
                        borderRadius: R.rSm,
                        border: Border.all(
                          color: allDone ? C.green : Pult.lcdFrame,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: anim,
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: allDone ? C.green : Pult.lcdInk,
                              boxShadow: [
                                BoxShadow(
                                  color: (allDone ? C.green : Pult.lcdInk).withValues(alpha: 0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 7),
                          StripeDodge(
                            reserve: 0,
                            child: Text(
                              '$answeredCount/$totalCount',
                              style: Pult.digits(
                                15,
                                allDone ? C.green : Pult.lcdInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: S.x2),

              // Morgenbriefing (J30): nur mit Link, sonst keine Lücke
              if (_briefingLink != null) ...[
                BriefingListenRow(url: _briefingLink!),
                const SizedBox(height: S.x2),
              ],

              // Gestern Section (J2)
              if (yQuestions.isNotEmpty) ...[
                _SectionHeader(
                  label: '${t.yesterday} ($yLabel)',
                  accent: Pult.orangeFor(p.dark),
                ),
                const SizedBox(height: S.x1 + 2),
                for (var i = 0; i < yQuestions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 5),
                  _HabitSwitchRow(
                    questionKey: yQuestions[i].key,
                    label: yQuestions[i].label,
                    currentValue: _yesterdayAnswers[yQuestions[i].key],
                    onSelect: (v) => _toggleYesterday(yQuestions[i].key, v),
                    yesText: t.yes,
                    noText: t.no,
                  ),
                ],
                const SizedBox(height: S.x2 + 2),
              ],

              // Heute Section (J3)
              if (tQuestions.isNotEmpty) ...[
                _SectionHeader(
                  label: '${t.today} ($tLabel)',
                  accent: p.on(C.teal),
                ),
                const SizedBox(height: S.x1 + 2),
                for (var i = 0; i < tQuestions.length; i++) ...[
                  if (i > 0) const SizedBox(height: S.x1 + 2),
                  if (tQuestions[i].isRating) ...[
                    Text(
                      tQuestions[i].label,
                      style: F.body.copyWith(color: p.ink, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: S.x1 + 2),
                    _FeelingRow(
                      currentValue: _todayAnswers[tQuestions[i].key]?.toInt(),
                      onSelect: (v) => _toggleToday(tQuestions[i].key, v.toDouble()),
                      t: t,
                    ),
                  ] else ...[
                    _HabitSwitchRow(
                      questionKey: tQuestions[i].key,
                      label: tQuestions[i].label,
                      currentValue: _todayAnswers[tQuestions[i].key],
                      onSelect: (v) => _toggleToday(tQuestions[i].key, v),
                      yesText: t.yes,
                      noText: t.no,
                    ),
                  ],
                ],
                const SizedBox(height: S.x3),
              ],

              // Fehlerzeile (J23)
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(S.x2),
                  decoration: BoxDecoration(
                    color: p.wash(C.red, strength: 1),
                    borderRadius: R.rSm,
                    border: Border.all(color: p.on(C.red).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _error!,
                          style: F.cap.copyWith(color: p.on(C.red)),
                        ),
                      ),
                      const SizedBox(width: S.x2),
                      Pressable(
                        onTap: _handleSave,
                        child: Text(
                          t.retry,
                          style: F.cap.copyWith(
                            color: p.on(C.red),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: S.x3),
              ],

              // Aktionen (J5, J7)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Pressable(
                      onTap: widget.onDismiss,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: S.x2 + 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.bg,
                          borderRadius: R.rSm,
                          border: Border.all(color: p.line),
                        ),
                        child: Text(
                          t.later,
                          style: F.body.copyWith(color: p.ink2, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: S.x2),
                  Expanded(
                    flex: 3,
                    child: Pressable(
                      onTap: _handleSave,
                      child: AnimatedContainer(
                        duration: anim,
                        padding: const EdgeInsets.symmetric(vertical: S.x2 + 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Pult.orange,
                          borderRadius: R.rSm,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: C.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.check, size: 17, color: C.white),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      t.done,
                                      overflow: TextOverflow.ellipsis,
                                      style: F.body.copyWith(
                                        color: C.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: S.x2),

              // Link "Journal öffnen" (J7)
              if (widget.onOpenFullJournal != null)
                Center(
                  child: Pressable(
                    onTap: widget.onOpenFullJournal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: S.x1),
                      child: Text(
                        t.openJournal,
                        style: F.cap.copyWith(
                          color: p.ink2,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: R.rPill,
          ),
        ),
        const SizedBox(width: S.x2),
        Expanded(
          child: StripeDodge(
            line: true,
            child: Text(
              label,
              style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitSwitchRow extends StatelessWidget {
  const _HabitSwitchRow({
    required this.questionKey,
    required this.label,
    required this.currentValue,
    required this.onSelect,
    required this.yesText,
    required this.noText,
  });

  final String questionKey;
  final String label;
  final double? currentValue;
  final void Function(double) onSelect;
  final String yesText;
  final String noText;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final anim = motion(context, Motion.fast);
    final isYes = currentValue == 1.0;
    final isNo = currentValue == 0.0;
    final wideStack = bigText(context) || MediaQuery.sizeOf(context).width < 330;

    final led = AnimatedContainer(
      duration: anim,
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isYes
            ? Pult.orange
            : isNo
                ? p.ink3
                : p.card,
        border: Border.all(
          color: isYes
              ? Pult.orange
              : isNo
                  ? p.ink3
                  : p.line,
          width: 1.5,
        ),
        boxShadow: isYes
            ? [
                BoxShadow(
                  color: Pult.orange.withValues(alpha: 0.45),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );

    final buttons = _YesNoButtons(
      questionKey: questionKey,
      currentValue: currentValue,
      onSelect: onSelect,
      yesText: yesText,
      noText: noText,
    );

    return AnimatedContainer(
      duration: anim,
      padding: const EdgeInsets.symmetric(horizontal: S.x2 + 2, vertical: 6),
      decoration: BoxDecoration(
        color: isYes
            ? p.wash(C.orange, strength: 0.7)
            : isNo
                ? p.card2
                : p.bg,
        borderRadius: R.rSm,
        border: Border.all(
          color: isYes ? Pult.orange.withValues(alpha: 0.5) : p.line,
        ),
      ),
      child: wideStack
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    led,
                    const SizedBox(width: S.x2),
                    Expanded(
                      child: Text(
                        label,
                        style: F.body.copyWith(color: p.ink, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: S.x2),
                Align(alignment: Alignment.centerRight, child: buttons),
              ],
            )
          : Row(
              children: [
                led,
                const SizedBox(width: S.x2),
                Expanded(
                  child: Text(
                    label,
                    style: F.body.copyWith(
                      color: p.ink,
                      fontWeight: isYes ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: S.x2),
                buttons,
              ],
            ),
    );
  }
}

class _YesNoButtons extends StatelessWidget {
  const _YesNoButtons({
    required this.questionKey,
    required this.currentValue,
    required this.onSelect,
    required this.yesText,
    required this.noText,
  });

  final String questionKey;
  final double? currentValue;
  final void Function(double) onSelect;
  final String yesText;
  final String noText;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final anim = motion(context, Motion.fast);
    final isYes = currentValue == 1.0;
    final isNo = currentValue == 0.0;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: R.rSm,
        border: Border.all(color: p.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pressable(
            key: ValueKey('sheet-btn-$questionKey-yes'),
            onTap: () => onSelect(1.0),
            child: AnimatedScale(
              scale: isYes ? 1.0 : 0.96,
              duration: anim,
              child: AnimatedContainer(
                duration: anim,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isYes ? Pult.orange : p.card.withValues(alpha: 0),
                  borderRadius: R.rSm,
                ),
                child: Text(
                  yesText,
                  style: F.cap.copyWith(
                    color: isYes ? C.white : p.ink2,
                    fontWeight: isYes ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Pressable(
            key: ValueKey('sheet-btn-$questionKey-no'),
            onTap: () => onSelect(0.0),
            child: AnimatedScale(
              scale: isNo ? 1.0 : 0.96,
              duration: anim,
              child: AnimatedContainer(
                duration: anim,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isNo
                      ? (p.dark ? p.card2 : C.n800)
                      : p.card.withValues(alpha: 0),
                  borderRadius: R.rSm,
                  border: isNo && p.dark ? Border.all(color: p.ink3) : null,
                ),
                child: Text(
                  noText,
                  style: F.cap.copyWith(
                    color: isNo ? (p.dark ? p.ink : C.white) : p.ink2,
                    fontWeight: isNo ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeelingRow extends StatelessWidget {
  const _FeelingRow({
    required this.currentValue,
    required this.onSelect,
    required this.t,
  });

  final int? currentValue;
  final void Function(int) onSelect;
  final JournalText t;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final anim = motion(context, Motion.fast);
    final options = [
      (1, t.feelingBad, LucideIcons.frown, C.red),
      (2, t.feelingMeh, LucideIcons.meh, C.orange),
      (3, t.feelingGood, LucideIcons.smile, C.teal),
      (4, t.feelingGreat, LucideIcons.laugh, C.green),
    ];

    Widget keyCap(({int val, String label, IconData icon, Color tone}) opt) {
      final selected = currentValue == opt.val;
      final fg = p.on(opt.tone);
      return Pressable(
        key: ValueKey('sheet-btn-feeling-${opt.val}'),
        onTap: () => onSelect(opt.val),
        child: AnimatedScale(
          scale: selected ? 1.02 : 0.97,
          duration: anim,
          child: AnimatedContainer(
            duration: anim,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? p.wash(opt.tone, strength: 1) : p.card,
              borderRadius: R.rSm,
              border: Border.all(
                color: selected ? fg : p.line,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: anim,
                  width: selected ? 24 : 14,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: selected ? opt.tone : p.line,
                    borderRadius: R.rPill,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: opt.tone.withValues(alpha: 0.45),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 5),
                Icon(
                  opt.icon,
                  size: 18,
                  color: selected ? fg : p.ink3,
                ),
                const SizedBox(height: 3),
                Text(
                  opt.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: F.cap.copyWith(
                    color: selected ? fg : p.ink2,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final stacked = bigText(context) || MediaQuery.sizeOf(context).width < 330;

    return Container(
      padding: const EdgeInsets.all(S.x1 + 2),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: R.rMd,
        border: Border.all(color: p.line),
      ),
      child: stacked
          ? Column(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 2; i++) ...[
                      if (i > 0) const SizedBox(width: S.x1),
                      Expanded(
                        child: keyCap((
                          val: options[i].$1,
                          label: options[i].$2,
                          icon: options[i].$3,
                          tone: options[i].$4,
                        )),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: S.x1),
                Row(
                  children: [
                    for (var i = 2; i < 4; i++) ...[
                      if (i > 2) const SizedBox(width: S.x1),
                      Expanded(
                        child: keyCap((
                          val: options[i].$1,
                          label: options[i].$2,
                          icon: options[i].$3,
                          tone: options[i].$4,
                        )),
                      ),
                    ],
                  ],
                ),
              ],
            )
          : Row(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(width: S.x1),
                  Expanded(
                    child: keyCap((
                      val: options[i].$1,
                      label: options[i].$2,
                      icon: options[i].$3,
                      tone: options[i].$4,
                    )),
                  ),
                ],
              ],
            ),
    );
  }
}
