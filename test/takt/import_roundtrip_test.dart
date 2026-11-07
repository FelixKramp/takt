// Gerätetest 2026-11-07: Edge's "Datenbank exportieren" file, imported into
// Takt 0.1.1, failed with "database is locked (code 5 SQLITE_BUSY)" while
// paging imported_measurement from the source. The export is a VACUUM INTO
// copy of a WAL database, so the file arrives in WAL mode. These tests run
// that exact round trip: export a populated database, import it fresh.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/data/db.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common/sqflite_logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tmp;
  late String dbDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    LocalDb.dbName = 'takt_roundtrip_test.db';
    dbDir = await databaseFactory.getDatabasesPath();
    tmp = await Directory.systemTemp.createTemp('takt_roundtrip_');
  });

  tearDownAll(() async {
    await LocalDb.close();
    await databaseFactory.deleteDatabase(p.join(dbDir, LocalDb.dbName));
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<Database> freshLocal() async {
    await LocalDb.close();
    await databaseFactory.deleteDatabase(p.join(dbDir, LocalDb.dbName));
    SharedPreferences.setMockInitialValues({});
    return LocalDb.instance;
  }

  Future<String> populatedExport() async {
    final db = await freshLocal();
    const t0 = 1790000000;
    for (var i = 0; i < 300; i++) {
      await db.insert('decoded_onehz', {
        'device_id': '', 'ts_ms': (t0 + i) * 1000, 'rec_ts': t0 + i,
        'counter': i, 'hr': 60 + i % 20,
      });
    }
    for (var i = 0; i < 5; i++) {
      await db.insert('imported_measurement', {
        'uuid': 'm$i', 'ts': t0 + i * 60, 'kind': 'resting_hr',
        'value': 55.0 + i, 'unit': 'bpm', 'source': 'test',
      });
    }
    final out = await LocalDb.exportCopy(into: tmp);
    await LocalDb.close();
    // The phone hands the file over without its suffix.
    final renamed = p.join(tmp.path, 'openstrap_export_${p.basename(out).hashCode}');
    await File(out).rename(renamed);
    return renamed;
  }

  test('A17: an exported database imports into a fresh install', () async {
    final path = await populatedExport();
    final db = await freshLocal();

    final counts = await LocalDb.importFromDbFile(path);

    expect(counts['imported_measurement'], 5);
    expect((await db.query('imported_measurement')).length, 5);
    expect((await db.query('decoded_onehz')).length, 300);
  });

  test('A17: the import works while the source is open in WAL mode', () async {
    final path = await populatedExport();
    // A WAL source with a live writer next to it, as the picker's copy can be.
    final other = await databaseFactoryFfi.openDatabase(path);
    await other.rawQuery('PRAGMA journal_mode=WAL');
    await other.rawQuery('SELECT COUNT(*) FROM imported_measurement');
    final db = await freshLocal();
    try {
      final counts = await LocalDb.importFromDbFile(path);
      expect(counts['imported_measurement'], 5);
      expect((await db.query('decoded_onehz')).length, 300);
    } finally {
      await other.close();
    }
  });

  // On the phone the reader connection and the ATTACH of the same file locked
  // each other out. Desktop SQLite does not reproduce that, so this holds the
  // structure that rules it out: the restore reads the picked file through one
  // connection only, and its second reader works on a private copy.
  test('A17: the restore opens no second connection on the picked file',
      () async {
    final path = await populatedExport();
    await freshLocal();
    final opened = <String>[];
    // ignore: experimental_member_use
    databaseFactory = SqfliteDatabaseFactoryLogger(
      databaseFactoryFfi,
      options: SqfliteLoggerOptions(
        type: SqfliteDatabaseFactoryLoggerType.all,
        log: (e) {
          if (e is SqfliteLoggerDatabaseOpenEvent) opened.add(e.path ?? '');
        },
      ),
    );
    try {
      final counts = await LocalDb.importFromDbFile(path);
      expect(counts['imported_measurement'], 5);
      expect(opened, isNot(contains(path)));
      expect(File(path).existsSync(), isTrue, reason: 'the original stays');
      final copies = opened.where((o) => o.contains('takt_src_')).toList();
      expect(copies, isNotEmpty);
      expect(copies.where((c) => File(c).existsSync()), isEmpty,
          reason: 'the private copy is deleted');
    } finally {
      databaseFactory = databaseFactoryFfi;
    }
  });
}
