// Gerätetest 2026-11-07: Edge's "Datenbank exportieren" file reached Takt
// without its `.db` suffix (Android's save/share round trip drops it). The
// router decided by name, sent the SQLite file to the NOOP importer, and the
// user read "That database is not a NOOP backup — it has no `hrSample` table
// (found: android_metadata, samples, decoded_onehz, …)". A17 needs that file
// to restore, whatever it is called.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openstrap_edge/state/app_state.dart';
import 'package:openstrap_edge/ui2/onboarding/welcome.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Spy extends AppState {
  _Spy() : super.forTesting();

  final edge = <String>[];
  final noop = <String>[];

  @override
  Future<int> importEdgeBackup(String path) async {
    edge.add(path);
    return 1;
  }

  @override
  Future<int> importNoopCsv(String path,
      {void Function(int days)? onProgress}) async {
    noop.add(path);
    return 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tmp;
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('takt_edge_db_');
  });
  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  Future<String> sqliteWith(String name, List<String> tables) async {
    final path = '${tmp.path}/$name';
    final db = await openDatabase(path);
    for (final t in tables) {
      await db.execute('CREATE TABLE $t (ts INTEGER)');
    }
    await db.close();
    return path;
  }

  test('A17: an Edge database without .db in its name restores as a backup',
      () async {
    final app = _Spy();
    final path = await sqliteWith('openstrap_export_1762531200000',
        ['android_metadata', 'samples', 'decoded_onehz', 'decoded_rr']);

    final out = await runImport(app, [path]);

    expect(app.edge, [path]);
    expect(app.noop, isEmpty);
    expect(out.source, contains('OpenStrap backup'));
  });

  test('A17: a NOOP database without a suffix still goes to NOOP', () async {
    final app = _Spy();
    final path = await sqliteWith('noop-backup', ['hrSample', 'sleepSession']);

    await runImport(app, [path]);

    expect(app.noop, [path]);
    expect(app.edge, isEmpty);
  });
}
