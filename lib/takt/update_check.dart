// Fragt höchstens einmal am Tag die GitHub-Releases von Takt ab. Das ist die
// einzige Netzabfrage von Takt selbst, sie enthält keine Gesundheitsdaten.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand.dart';

const _kCheckedAt = 'takt.update_checked_at';
const _kLatestTag = 'takt.update_latest_tag';
const _kLatestUrl = 'takt.update_latest_url';

bool isNewerVersion(String current, String tag) {
  List<int>? parts(String v) {
    final clean = v.replaceFirst(RegExp('^v'), '').split('+').first.split('.');
    final nums = clean.map(int.tryParse).toList();
    return nums.contains(null) ? null : nums.cast<int>();
  }

  final a = parts(current), b = parts(tag);
  if (a == null || b == null) return false;
  for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return y > x;
  }
  return false;
}


bool shouldCheckUpdate(DateTime? last, DateTime now) =>
    last == null || now.difference(last) >= const Duration(hours: 24);

class TaktUpdate {
  const TaktUpdate(this.tag, this.url);
  final String tag, url;
}

/// Hält das Ergebnis für die Einstellungen bereit.
final ValueNotifier<TaktUpdate?> taktUpdate = ValueNotifier(null);

Future<void> refreshTaktUpdate({DateTime? now}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final clock = now ?? DateTime.now();
    final ms = prefs.getInt(_kCheckedAt);
    final last = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    if (shouldCheckUpdate(last, clock)) {
      final res = await http
          .get(Uri.parse(kReleasesApi), headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
      await prefs.setInt(_kCheckedAt, clock.millisecondsSinceEpoch);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        await prefs.setString(_kLatestTag, '${body['tag_name']}');
        await prefs.setString(_kLatestUrl, '${body['html_url']}');
      }
    }
    final tag = prefs.getString(_kLatestTag);
    final url = prefs.getString(_kLatestUrl);
    if (tag == null || url == null) return;
    final info = await PackageInfo.fromPlatform();
    taktUpdate.value = isNewerVersion(info.version, tag) ? TaktUpdate(tag, url) : null;
  } catch (_) {
    // Kein Netz oder kein Release: dann gibt es einfach keinen Hinweis.
  }
}
