import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/db.dart';
import '../../l10n/decimal_text.dart' show displayFixed;
import '../../ui2/grammar.dart' show Pressable, Surface;
import '../../ui2/revision.dart';
import '../../ui2/screens/home_screen.dart' show repoOf;
import '../../ui2/theme.dart';
import '../pult_tokens.dart';
import '../stripe/stripe.dart';
import 'briefing_link.dart';
import 'journal_config.dart';
import 'journal_evidence.dart';
import 'journal_text.dart';
import 'morning_sheet_flow.dart';
import 'new_question_sheet.dart';

class JournalTab extends StatefulWidget {
  const JournalTab({super.key});

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> with RevisionReload {
  /// Gerätetest 14.11.: Der Tab bleibt im Gesundheit-Tab am Leben. Ohne
  /// Neuladen zeigte er nach einem Morgenblatt auf Heute oder einer neu
  /// berechneten Nacht weiter den alten Stand („Ja 0 von 5“).
  @override
  void reload() => _load();

  JournalConfig? _config;
  List<HabitAnalysis> _analyses = const [];
  String? _briefingLink;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = repoOf(context);
    final token = beginRead(#journal);
    JournalConfig? config;
    try {
      config = await JournalConfig.load();
      final briefingLink = await loadBriefingLink();

      final metricsByDay = await LocalDb.journalMetricsByDay();
      final imported = await LocalDb.importedDates();

      final outcomeMaps = <String, Map<String, double>>{};
      const outcomeKeys = ['readiness', 'rmssd', 'rhr', 'efficiency'];
      final allExcluded = Set<String>.of(imported);

      for (final key in outcomeKeys) {
        final notOurs = await LocalDb.metricNotOursDates(key);
        allExcluded.addAll(notOurs);

        final map = <String, double>{};
        final series = await LocalDb.metricSeries(key);
        for (final row in series) {
          final d = row['date'] as String?;
          final v = (row['value'] as num?)?.toDouble();
          if (d != null && v != null && !imported.contains(d) && !notOurs.contains(d)) {
            map[d] = v;
          }
        }
        outcomeMaps[key] = map;
      }

      List<Map<String, dynamic>> numericInsights = const [];
      if (repo != null) {
        try {
          final res = await repo.getJournalInsights();
          final numIns = res['numeric_insights'];
          if (numIns is List) {
            numericInsights = [
              for (final item in numIns)
                if (item is Map) item.cast<String, dynamic>(),
            ];
          }
        } catch (_) {}
      }

      // Rechnen der Evidenz:
      final rawMetrics = <String, Map<String, double>>{};
      for (final entry in metricsByDay.entries) {
        rawMetrics[entry.key] = {
          for (final f in entry.value.entries) f.key: f.value.value,
        };
      }

      final analyses = computeJournalEvidence(
        questions: config.activeQuestions,
        metricsByDay: rawMetrics,
        outcomeMaps: outcomeMaps,
        numericInsights: numericInsights,
        excludedDates: allExcluded,
      );

      if (stillNewest(#journal, token)) {
        setState(() {
          _config = config;
          _briefingLink = briefingLink;
          _analyses = analyses;
          _loading = false;
        });
      }
    } catch (_) {
      if (stillNewest(#journal, token)) {
        setState(() {
          _config ??= config;
          _loading = false;
        });
      }
    }
  }

  Future<void> _openCompose() async {
    await openMorningSheetManually(context);
    _load();
  }

  Future<void> _editBriefingLink() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BriefingLinkSheet(current: _briefingLink),
    );
    final link = await loadBriefingLink();
    if (mounted) setState(() => _briefingLink = link);
  }

  Future<void> _openNewQuestion() async {
    if (_config == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewQuestionSheet(
        config: _config!,
        onCreated: (_) => _load(),
      ),
    );
    _load();
  }

  Future<void> _openEditQuestion(JournalQuestion q) async {
    if (_config == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditQuestionSheet(
        config: _config!,
        question: q,
        onChanged: _load,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final t = JournalText.of(context);

    if (_loading && _config == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(S.x5),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final questions = _config?.questions ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Ganz oben: "Heute eintragen" Pult-Aktion (J27)
        Pressable(
          key: const ValueKey('journal-log-today-btn'),
          onTap: _openCompose,
          child: Container(
            padding: const EdgeInsets.all(S.x3),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: R.rMd,
              border: Border.all(color: Pult.orange.withValues(alpha: 0.45)),
              boxShadow: p.el(1),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Pult.orange,
                    borderRadius: R.rSm,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.slidersHorizontal,
                    color: C.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: S.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.logToday,
                        style: F.head.copyWith(
                          color: p.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.de ? 'Gestern & Befinden erfassen' : 'Log habits & mood',
                        style: F.cap.copyWith(color: p.ink2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: S.x2),
                Icon(LucideIcons.chevronRight, size: 18, color: Pult.orangeFor(p.dark)),
              ],
            ),
          ),
        ),
        const SizedBox(height: S.x2),
        // Morgenbriefing (J28, J29): Link nach Google Drive
        if (_briefingLink != null)
          BriefingListenRow(url: _briefingLink!, onEdit: _editBriefingLink)
        else
          BriefingSetupRow(onTap: _editBriefingLink),
        const SizedBox(height: S.x4),

        // 2. Auswertung "Was tut mir gut" (J12-J17)
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: Pult.orange,
                borderRadius: R.rPill,
              ),
            ),
            const SizedBox(width: S.x2),
            Expanded(
              child: Text(t.whatHelpsMe, style: F.t2.copyWith(color: p.ink)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(t.disclaimer, style: F.cap.copyWith(color: p.ink2)),
        const SizedBox(height: S.x3),

        if (_analyses.isEmpty)
          Surface(
            pad: const EdgeInsets.all(S.x3),
            child: Text(
              t.tooFewDays,
              style: F.body.copyWith(color: p.ink2),
            ),
          )
        else
          for (final a in _analyses) ...[
            _HabitEvidenceCard(
              analysis: a,
              t: t,
              onTap: () => _openEditQuestion(a.question),
            ),
            const SizedBox(height: S.x2),
          ],
        const SizedBox(height: S.x5),

        // 3. Fragenliste & Eigene Fragen (J9-J11, J27)
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: S.x2,
          runSpacing: S.x2,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: p.on(C.teal),
                    borderRadius: R.rPill,
                  ),
                ),
                const SizedBox(width: S.x2),
                Flexible(
                  child: Text(
                    t.de ? 'Gewohnheiten' : 'Habits',
                    style: F.t2.copyWith(color: p.ink),
                  ),
                ),
              ],
            ),
            Pressable(
              key: const ValueKey('journal-add-custom-question-btn'),
              onTap: _openNewQuestion,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: p.wash(C.orange, strength: 0.8),
                  borderRadius: R.rPill,
                  border: Border.all(color: Pult.orange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 15, color: Pult.orangeFor(p.dark)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        t.customQuestion,
                        style: F.cap.copyWith(
                          color: Pult.orangeFor(p.dark),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: S.x3),

        for (final q in questions) ...[
          _QuestionConfigTile(
            question: q,
            t: t,
            onTap: () => _openEditQuestion(q),
            onToggleSheet: (val) async {
              await _config?.setShowInSheet(q.key, val);
              setState(() {});
            },
          ),
          const SizedBox(height: S.x2),
        ],
        const SizedBox(height: S.x5),
      ],
    );
  }
}

class _HabitEvidenceCard extends StatelessWidget {
  const _HabitEvidenceCard({
    required this.analysis,
    required this.t,
    required this.onTap,
  });

  final HabitAnalysis analysis;
  final JournalText t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final q = analysis.question;
    final rComp = analysis.readinessComparison;

    final (badgeText, rawTone, badgeInk) = switch (analysis.impact) {
      HabitImpact.helps => (t.helps, C.teal, p.on(C.teal)),
      HabitImpact.costs => (t.costs, C.red, p.on(C.red)),
      HabitImpact.noDifference => (t.noDifference, p.ink3, p.ink2),
      HabitImpact.tooFewDays => (t.tooFewDays, p.ink3, p.ink2),
    };

    return Surface(
      onTap: onTap,
      pad: const EdgeInsets.all(S.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Frage-Label + Pult-LED-Badge
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: S.x2,
            runSpacing: S.x1,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rawTone,
                    ),
                  ),
                  const SizedBox(width: S.x2),
                  Flexible(
                    child: Text(
                      q.label,
                      style: F.head.copyWith(color: p.ink, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: p.wash(rawTone, strength: 1),
                  borderRadius: R.rPill,
                  border: Border.all(color: rawTone.withValues(alpha: 0.35)),
                ),
                child: Text(
                  badgeText,
                  style: F.cap.copyWith(
                    color: badgeInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: S.x2),

          // Wenn genug Tage: Batterie-Vergleich mit Balken & Punktmatrix-Delta (J12)
          if (analysis.hasEnoughDays && rComp != null) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: S.x2,
              runSpacing: 4,
              children: [
                Text(t.batteryNextMorning, style: F.cap.copyWith(color: p.ink2)),
                StripeDodge(
                  line: true,
                  child: Text(
                    t.diffPoints(rComp.diff),
                    style: Pult.digits(
                      18,
                      rComp.diff >= 0 ? p.on(C.teal) : p.on(C.red),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: S.x2),
            _CompareTrack(
              label: t.yes,
              avgPct: rComp.yesAvg,
              days: analysis.yesCount,
              daysSuffix: t.daysCount,
              accent: rComp.diff >= 0 ? C.teal : Pult.orange,
            ),
            const SizedBox(height: S.x1),
            _CompareTrack(
              label: t.no,
              avgPct: rComp.noAvg,
              days: analysis.noCount,
              daysSuffix: t.daysCount,
              accent: p.ink3,
            ),
            const SizedBox(height: S.x2),
            _SubMetricsRow(analysis: analysis, t: t),
          ] else ...[
            // Wenn zu wenig Tage (J13): Pult-LED-Fortschrittsreihe + Zählstand
            _DayProgressPips(
              yesLabel: t.yes,
              noLabel: t.no,
              yesCount: analysis.yesCount,
              noCount: analysis.noCount,
            ),
            const SizedBox(height: S.x1 + 2),
            StripeDodge(
              line: true,
              child: Text(
                t.countStatus(analysis.yesCount, 5, analysis.noCount, 5),
                style: F.cap.copyWith(color: p.ink2),
              ),
            ),
          ],
          if (analysis.waitingCount > 0) ...[
            const SizedBox(height: S.x1),
            StripeDodge(
              line: true,
              child: Text(
                t.waiting(analysis.waitingCount),
                key: ValueKey('journal-waiting-${analysis.question.key}'),
                style: F.cap.copyWith(color: p.ink3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompareTrack extends StatelessWidget {
  const _CompareTrack({
    required this.label,
    required this.avgPct,
    required this.days,
    required this.daysSuffix,
    required this.accent,
  });

  final String label;
  final double avgPct;
  final int days;
  final String daysSuffix;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final fill = (avgPct / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: S.x2, vertical: 7),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: R.rSm,
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: S.x2,
            runSpacing: 2,
            children: [
              StripeDodge(
                line: true,
                child: Text(
                  '$label · ${displayFixed(avgPct, 0)} %',
                  style: F.cap.copyWith(color: p.ink, fontWeight: FontWeight.w600),
                ),
              ),
              StripeDodge(
                line: true,
                child: Text(
                  '$days $daysSuffix',
                  style: F.cap.copyWith(color: p.ink3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: R.rPill,
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 5,
              backgroundColor: p.track,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayProgressPips extends StatelessWidget {
  const _DayProgressPips({
    required this.yesLabel,
    required this.noLabel,
    required this.yesCount,
    required this.noCount,
  });

  final String yesLabel;
  final String noLabel;
  final int yesCount;
  final int noCount;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    Widget row(String label, int count, Color lit) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: F.cap.copyWith(color: p.ink2, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          for (var i = 0; i < 5; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: 11,
              height: 6,
              decoration: BoxDecoration(
                color: i < count ? lit : p.track,
                borderRadius: R.rPill,
              ),
            ),
          ],
        ],
      );
    }

    return Wrap(
      spacing: S.x3,
      runSpacing: S.x1,
      children: [
        row(yesLabel, yesCount, Pult.orange),
        row(noLabel, noCount, p.ink2),
      ],
    );
  }
}

class _SubMetricsRow extends StatelessWidget {
  const _SubMetricsRow({required this.analysis, required this.t});

  final HabitAnalysis analysis;
  final JournalText t;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final items = <Widget>[];

    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius: R.rSm,
            border: Border.all(color: p.line),
          ),
          child: StripeDodge(
            line: true,
            child: Text(text, style: F.cap.copyWith(color: p.ink2)),
          ),
        );

    final hrv = analysis.hrvComparison;
    if (hrv != null) {
      items.add(chip('${t.hrv}: ${hrv.diff >= 0 ? '+' : ''}${displayFixed(hrv.diff, 1)} ms'));
    }

    final rhr = analysis.rhrComparison;
    if (rhr != null) {
      items.add(chip('${t.rhr}: ${rhr.diff >= 0 ? '+' : ''}${displayFixed(rhr.diff, 1)} bpm'));
    }

    final eff = analysis.efficiencyComparison;
    if (eff != null) {
      items.add(chip('${t.sleepEfficiency}: ${eff.diff >= 0 ? '+' : ''}${displayFixed(eff.diff, 1)} %'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: S.x1 + 2,
      runSpacing: S.x1,
      children: items,
    );
  }
}

class _QuestionConfigTile extends StatelessWidget {
  const _QuestionConfigTile({
    required this.question,
    required this.t,
    required this.onTap,
    required this.onToggleSheet,
  });

  final JournalQuestion question;
  final JournalText t;
  final VoidCallback onTap;
  final void Function(bool) onToggleSheet;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final active = question.showInSheet && !question.hidden;

    return Surface(
      onTap: onTap,
      pad: const EdgeInsets.symmetric(horizontal: S.x3, vertical: S.x2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Pult.orange : p.line,
            ),
          ),
          const SizedBox(width: S.x2),
          if (question.isPrivate) ...[
            Icon(LucideIcons.lock, size: 15, color: p.ink3),
            const SizedBox(width: S.x1),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.label,
                  style: F.body.copyWith(
                    color: question.hidden ? p.ink2 : p.ink,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    decoration: question.hidden ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (question.customLabel != null && question.customLabel!.isNotEmpty)
                  Text(
                    '(${question.defaultLabel})',
                    style: F.cap.copyWith(color: p.ink2),
                  ),
              ],
            ),
          ),
          const SizedBox(width: S.x2),
          Switch.adaptive(
            value: active,
            activeTrackColor: Pult.orange,
            onChanged: question.hidden ? null : onToggleSheet,
          ),
        ],
      ),
    );
  }
}
