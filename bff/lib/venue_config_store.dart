/// The venue configuration store PORT. Holds one opaque JSON document per venue
/// (the client's AppConfig). The BFF does not read inside the document, so the
/// client owns its shape and this stays a plain key-value seam. An in-memory
/// implementation serves dev and tests. PostgresVenueConfigStore persists it.
abstract interface class VenueConfigStore {
  /// The saved document for [venueId], or null when none has been written yet
  /// (the client then falls back to its bundled asset).
  Future<Map<String, dynamic>?> get(String venueId);

  /// Writes (replaces) the document for [venueId].
  Future<void> put(String venueId, Map<String, dynamic> doc);
}

/// In-memory venue config, for dev and tests without a database. Not durable:
/// a restart forgets edits, which is fine off a real deployment.
class InMemoryVenueConfigStore implements VenueConfigStore {
  final Map<String, Map<String, dynamic>> _byVenue = {};

  @override
  Future<Map<String, dynamic>?> get(String venueId) async => _byVenue[venueId];

  @override
  Future<void> put(String venueId, Map<String, dynamic> doc) async {
    _byVenue[venueId] = doc;
  }
}
