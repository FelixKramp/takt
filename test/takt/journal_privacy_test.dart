import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/data/csv_export.dart';
import 'package:openstrap_edge/data/recent_slice.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('13-3 / J20: Privatsphäre nach außen', () {
    test('CSV-Export für habits schließt priv_... Felder aus', () async {
      final db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE journal_metric (
            date TEXT NOT NULL,
            field TEXT NOT NULL,
            value REAL NOT NULL,
            at_min INTEGER,
            PRIMARY KEY (date, field)
          )
        ''');
        await db.execute('''
          CREATE TABLE journal_field_def (
            key TEXT PRIMARY KEY,
            label TEXT NOT NULL,
            kind TEXT NOT NULL,
            unit TEXT NOT NULL,
            max REAL NOT NULL,
            step REAL NOT NULL,
            has_time INTEGER NOT NULL DEFAULT 0,
            custom INTEGER NOT NULL DEFAULT 1
          )
        ''');
      });

      await db.insert('journal_metric', {'date': '2026-11-10', 'field': 'vitamin_d', 'value': 1.0});
      await db.insert('journal_metric', {'date': '2026-11-10', 'field': 'priv_solo', 'value': 1.0});
      await db.insert('journal_metric', {'date': '2026-11-10', 'field': 'priv_custom', 'value': 1.0});

      final habitSet = kCsvExportSets.firstWhere((s) => s.name == 'habits');
      final rows = await db.rawQuery(habitSet.sql);

      final fields = rows.map((r) => r['field'] as String).toList();
      expect(fields, contains('vitamin_d'));
      expect(fields, isNot(contains('priv_solo')));
      expect(fields, isNot(contains('priv_custom')));

      await db.close();
    });

    test('recent_slice WHERE-Klausel filtert priv_... aus journal_metric', () async {
      final db = await openDatabase(inMemoryDatabasePath, version: 1);
      final whereClause = await whereForTable(db, 'journal_metric', 0, 0, '2026-11-01');

      expect(whereClause, isNotNull);
      expect(whereClause, contains("field NOT LIKE 'priv_%'"));
      await db.close();
    });
  });
}
