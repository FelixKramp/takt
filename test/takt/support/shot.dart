// Bildschirmfotos aus Widget-Tests, mit den echten Schriften. Nur mit
// TAKT_SHOTS=1, sonst tut `shot` nichts. Ablage: build/shots/<name>.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final bool shotsOn = Platform.environment['TAKT_SHOTS'] == '1';

Future<void> loadRealFonts() async {
  Future<void> load(String family, Iterable<String> paths) async {
    final l = FontLoader(family);
    for (final p in paths) {
      l.addFont(File(p).readAsBytes().then((b) => ByteData.sublistView(Uint8List.fromList(b))));
    }
    await l.load();
  }

  final manrope = Directory('assets/fonts/Manrope')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.ttf'))
      .map((f) => f.path)
      .toList();
  for (final fam in ['Manrope', '.SF Pro Text', 'Roboto']) {
    await load(fam, manrope);
  }
  await load('Doto', ['assets/fonts/Doto/Doto.ttf']);
  final home = Platform.environment['HOME'];
  final lucide = Directory('$home/.pub-cache/hosted/pub.dev')
      .listSync()
      .whereType<Directory>()
      .where((d) => d.path.contains('lucide_icons_flutter-'))
      .map((d) => '${d.path}/assets/lucide.ttf')
      .where((p) => File(p).existsSync())
      .toList();
  if (lucide.isNotEmpty) await load('packages/lucide_icons_flutter/Lucide', [lucide.last]);
}

/// Fotografiert das erste RenderRepaintBoundary oberhalb von [f].
Future<void> shot(WidgetTester t, Finder f, String name) async {
  if (!shotsOn) return;
  var ro = t.renderObject(f);
  while (ro is! RenderRepaintBoundary) {
    ro = ro.parent! as RenderObject;
  }
  final boundary = ro;
  await t.runAsync(() async {
    final ui.Image img = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/shots/$name.png');
    await out.parent.create(recursive: true);
    await out.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
