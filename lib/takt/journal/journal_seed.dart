import 'package:sqflite/sqflite.dart';
import '../../data/journal_fields.dart';

/// Legt beim ersten Start die 5 Standardfelder in `journal_field_def` an,
/// wenn sie noch nicht existieren. Bestehende Felder werden nicht überschrieben.
Future<void> journalSeed(DatabaseExecutor db) async {
  final seedFields = <JournalFieldSpec>[
    const JournalFieldSpec(
      key: 'vitamin_d',
      label: 'Vitamin D genommen',
      kind: JournalFieldKind.dose,
      unit: '',
      max: 1.0,
      step: 1.0,
      custom: true,
    ),
    const JournalFieldSpec(
      key: 'read_evening',
      label: 'Gelesen',
      kind: JournalFieldKind.dose,
      unit: '',
      max: 1.0,
      step: 1.0,
      custom: true,
    ),
    const JournalFieldSpec(
      key: 'meat',
      label: 'Fleisch gegessen',
      kind: JournalFieldKind.dose,
      unit: '',
      max: 1.0,
      step: 1.0,
      custom: true,
    ),
    const JournalFieldSpec(
      key: 'priv_solo',
      label: 'Private Frage',
      kind: JournalFieldKind.dose,
      unit: '',
      max: 1.0,
      step: 1.0,
      custom: true,
    ),
    const JournalFieldSpec(
      key: 'feeling',
      label: 'Wie fühlst du dich?',
      kind: JournalFieldKind.rating,
      unit: '',
      max: 4.0,
      step: 1.0,
      custom: true,
    ),
  ];

  for (final f in seedFields) {
    final existing = await db.query(
      'journal_field_def',
      where: 'key = ?',
      whereArgs: [f.key],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert(
        'journal_field_def',
        {
          'key': f.key,
          'label': f.label,
          'kind': f.kind.name,
          'unit': f.unit,
          'max_value': f.max,
          'step': f.step,
          'has_time': f.hasTime ? 1 : 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
