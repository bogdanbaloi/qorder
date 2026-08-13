import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/local_store.dart';

/// Durable [LocalStore] backed by shared_preferences: NSUserDefaults on iOS,
/// SharedPreferences on Android, localStorage on web. Survives app kill and
/// reboot. Good enough for the small outbox in Phase 0. A transactional engine
/// (SQLite/Drift) can replace it behind the same interface for Phase 1+.
class PrefsLocalStore implements LocalStore {
  final SharedPreferences prefs;
  PrefsLocalStore(this.prefs);

  String _k(String box, String key) => '$box/$key';

  @override
  Future<void> put(String box, String key, Map<String, dynamic> value) async {
    await prefs.setString(_k(box, key), jsonEncode(value));
  }

  @override
  Future<Map<String, dynamic>?> get(String box, String key) async {
    // Re-read from the backing store so writes from another tab/instance are
    // seen (on web, shared_preferences caches localStorage in memory).
    await prefs.reload();
    final s = prefs.getString(_k(box, key));
    return s == null ? null : jsonDecode(s) as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> all(String box) async {
    await prefs.reload();
    final prefix = '$box/';
    return prefs
        .getKeys()
        .where((k) => k.startsWith(prefix))
        .map((k) => jsonDecode(prefs.getString(k)!) as Map<String, dynamic>)
        .toList();
  }

  @override
  Future<void> delete(String box, String key) async {
    await prefs.remove(_k(box, key));
  }
}
