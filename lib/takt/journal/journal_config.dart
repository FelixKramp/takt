import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum JournalSection { yesterday, today }

@immutable
class JournalQuestion {
  const JournalQuestion({
    required this.key,
    required this.defaultLabel,
    this.customLabel,
    required this.section,
    this.showInSheet = true,
    this.hidden = false,
    this.isPrivate = false,
    this.isRating = false,
    this.max = 1.0,
    this.step = 1.0,
  });

  final String key;
  final String defaultLabel;
  final String? customLabel;
  final JournalSection section;
  final bool showInSheet;
  final bool hidden;
  final bool isPrivate;
  final bool isRating;
  final double max;
  final double step;

  String get label => (customLabel != null && customLabel!.trim().isNotEmpty)
      ? customLabel!
      : defaultLabel;

  JournalQuestion copyWith({
    String? customLabel,
    bool? showInSheet,
    bool? hidden,
    String? defaultLabel,
    JournalSection? section,
  }) {
    return JournalQuestion(
      key: key,
      defaultLabel: defaultLabel ?? this.defaultLabel,
      customLabel: customLabel ?? this.customLabel,
      section: section ?? this.section,
      showInSheet: showInSheet ?? this.showInSheet,
      hidden: hidden ?? this.hidden,
      isPrivate: isPrivate,
      isRating: isRating,
      max: max,
      step: step,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'defaultLabel': defaultLabel,
        'customLabel': customLabel,
        'section': section.name,
        'showInSheet': showInSheet,
        'hidden': hidden,
        'isPrivate': isPrivate,
        'isRating': isRating,
        'max': max,
        'step': step,
      };

  factory JournalQuestion.fromJson(Map<String, dynamic> json) {
    final key = json['key'] as String;
    final isPriv = (json['isPrivate'] as bool?) ?? key.startsWith('priv_');
    return JournalQuestion(
      key: key,
      defaultLabel: json['defaultLabel'] as String? ?? key,
      customLabel: json['customLabel'] as String?,
      section: (json['section'] as String?) == 'today'
          ? JournalSection.today
          : JournalSection.yesterday,
      showInSheet: json['showInSheet'] as bool? ?? true,
      hidden: json['hidden'] as bool? ?? false,
      isPrivate: isPriv,
      isRating: json['isRating'] as bool? ?? false,
      max: (json['max'] as num?)?.toDouble() ?? 1.0,
      step: (json['step'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class JournalConfig {
  JournalConfig(List<JournalQuestion> questions)
      : _questions = List.of(questions);

  static const kPrefKey = 'takt.journal.config.v1';

  final List<JournalQuestion> _questions;
  List<JournalQuestion> get questions => List.unmodifiable(_questions);

  JournalQuestion? question(String key) {
    try {
      return _questions.firstWhere((q) => q.key == key);
    } catch (_) {
      return null;
    }
  }

  List<JournalQuestion> get activeQuestions =>
      _questions.where((q) => !q.hidden).toList();

  List<JournalQuestion> get sheetQuestionsYesterday => _questions
      .where((q) => !q.hidden && q.showInSheet && q.section == JournalSection.yesterday)
      .toList();

  List<JournalQuestion> get sheetQuestionsToday => _questions
      .where((q) => !q.hidden && q.showInSheet && q.section == JournalSection.today)
      .toList();

  static const standardQuestions = <JournalQuestion>[
    JournalQuestion(
      key: 'vitamin_d',
      defaultLabel: 'Vitamin D genommen',
      section: JournalSection.yesterday,
      max: 1.0,
      step: 1.0,
    ),
    JournalQuestion(
      key: 'read_evening',
      defaultLabel: 'Gelesen',
      section: JournalSection.yesterday,
      max: 1.0,
      step: 1.0,
    ),
    JournalQuestion(
      key: 'meat',
      defaultLabel: 'Fleisch gegessen',
      section: JournalSection.yesterday,
      max: 1.0,
      step: 1.0,
    ),
    JournalQuestion(
      key: 'priv_solo',
      defaultLabel: 'Private Frage',
      section: JournalSection.yesterday,
      isPrivate: true,
      max: 1.0,
      step: 1.0,
    ),
    JournalQuestion(
      key: 'feeling',
      defaultLabel: 'Wie fühlst du dich?',
      section: JournalSection.today,
      isRating: true,
      max: 4.0,
      step: 1.0,
    ),
  ];

  static Future<JournalConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kPrefKey);
    if (raw == null || raw.isEmpty) {
      return JournalConfig(List.of(standardQuestions));
    }
    try {
      final list = jsonDecode(raw) as List;
      final parsed = <JournalQuestion>[];
      final seenKeys = <String>{};
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final q = JournalQuestion.fromJson(item);
          parsed.add(q);
          seenKeys.add(q.key);
        }
      }
      // Wenn neue Standardfragen im Code ergänzt wurden, hinzufügen:
      for (final std in standardQuestions) {
        if (!seenKeys.contains(std.key)) {
          parsed.add(std);
        }
      }
      return JournalConfig(parsed);
    } catch (_) {
      return JournalConfig(List.of(standardQuestions));
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode([for (final q in _questions) q.toJson()]);
    await prefs.setString(kPrefKey, encoded);
  }

  Future<void> setDisplayName(String key, String? displayName) async {
    final updated = [
      for (final q in _questions)
        if (q.key == key) q.copyWith(customLabel: displayName) else q,
    ];
    _questions
      ..clear()
      ..addAll(updated);
    await save();
  }

  Future<void> setShowInSheet(String key, bool show) async {
    final updated = [
      for (final q in _questions)
        if (q.key == key) q.copyWith(showInSheet: show) else q,
    ];
    _questions
      ..clear()
      ..addAll(updated);
    await save();
  }

  Future<void> setHidden(String key, bool hidden) async {
    final updated = [
      for (final q in _questions)
        if (q.key == key) q.copyWith(hidden: hidden) else q,
    ];
    _questions
      ..clear()
      ..addAll(updated);
    await save();
  }

  Future<JournalQuestion> addCustomQuestion({
    required String name,
    required JournalSection section,
    required bool isPrivate,
  }) async {
    // Generiere stabilen Schlüssel:
    final clean = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final base = clean.isEmpty ? 'q' : clean;
    final prefix = isPrivate ? 'priv_' : 'custom_';
    var key = '$prefix$base';
    var counter = 1;
    while (_questions.any((q) => q.key == key)) {
      key = '$prefix${base}_$counter';
      counter++;
    }

    final newQ = JournalQuestion(
      key: key,
      defaultLabel: name,
      section: section,
      isPrivate: isPrivate,
      showInSheet: true,
      hidden: false,
      max: 1.0,
      step: 1.0,
    );
    _questions.add(newQ);
    await save();
    return newQ;
  }
}
