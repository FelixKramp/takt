// Takt: Android's save and share round trip can drop the `.db` from Edge's
// "Datenbank exportieren" file. The router in welcome.dart decided by name and
// sent such a file to the NOOP importer. A plain SQLite file that holds
// OpenStrap's tables and not NOOP's `hrSample` is an OpenStrap database,
// whatever it is called.

import 'dart:io';

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

/// Runs [run] with a private copy of the database file at [path] and deletes
/// the copy afterwards. The restore attaches the picked file and reads it
/// through a second connection; on the phone those two locked each other out
/// (SQLITE_BUSY, Gerätetest 2026-11-07). With the copy, every file has exactly
/// one connection.
Future<T> withPrivateCopy<T>(
    String path, Future<T> Function(String copy) run) async {
  final dir = await Directory.systemTemp.createTemp('takt_src_');
  try {
    final copy = '${dir.path}/source.db';
    await File(path).copy(copy);
    return await run(copy);
  } finally {
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
    } catch (_) {
      /* the OS reclaims the temp dir eventually */
    }
  }
}
