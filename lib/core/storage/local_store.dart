/// The storage engine PORT: raw, boxed key/value persistence of JSON maps.
///
/// This is the swappable seam (Dependency Inversion). Phase 0 ships an
/// in-memory implementation (tests) and a shared_preferences one (device/web).
/// A transactional engine (SQLite/Drift, with schema migrations) drops in
/// behind this same interface later, without touching the repositories on top.
abstract interface class LocalStore {
  Future<void> put(String box, String key, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> get(String box, String key);
  Future<List<Map<String, dynamic>>> all(String box);
  Future<void> delete(String box, String key);
}

/// In-memory implementation for tests and the web demo. Insertion order is
/// preserved (Dart maps are ordered), which gives FIFO for `all`.
class InMemoryLocalStore implements LocalStore {
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};

  Map<String, Map<String, dynamic>> _boxOf(String box) =>
      _data.putIfAbsent(box, () => <String, Map<String, dynamic>>{});

  @override
  Future<void> put(String box, String key, Map<String, dynamic> value) async {
    _boxOf(box)[key] = Map<String, dynamic>.from(value);
  }

  @override
  Future<Map<String, dynamic>?> get(String box, String key) async {
    final v = _boxOf(box)[key];
    return v == null ? null : Map<String, dynamic>.from(v);
  }

  @override
  Future<List<Map<String, dynamic>>> all(String box) async =>
      _boxOf(box).values.map((v) => Map<String, dynamic>.from(v)).toList();

  @override
  Future<void> delete(String box, String key) async {
    _boxOf(box).remove(key);
  }
}
