// Takt: Android's save and share round trip can drop the `.db` from Edge's
// "Datenbank exportieren" file. The router in welcome.dart decided by name and
// sent such a file to the NOOP importer. A plain SQLite file that holds
// OpenStrap's tables and not NOOP's `hrSample` is an OpenStrap database,
// whatever it is called.

import 'package:sqflite/sqflite.dart';

import '../import/import_container.dart';

Future<bool> isUnnamedEdgeDatabase(String path) async {
  if (await sniffFile(path) != ImportContainer.sqlite) return false;
  Database? db;
  try {
    db = await openDatabase(path, readOnly: true, singleInstance: false);
    final rows = await db
        .rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'");
    final names = {for (final r in rows) r['name']};
    return !names.contains('hrSample') &&
        (names.contains('samples') || names.contains('day_result'));
  } catch (_) {
    // Unreadable: leave it to the importer that owns the message.
    return false;
  } finally {
    await db?.close();
  }
}
