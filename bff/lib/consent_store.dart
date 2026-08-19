/// The consent PORT. Consent is stored per VENUE (each venue is the data
/// controller for its own customers) and per purpose, so it is auditable and
/// withdrawable. Async, so a persistent (Postgres) implementation drops in
/// behind this interface without changing callers.
abstract interface class ConsentStore {
  /// Record a customer's consent choices for a venue. Each choice is
  /// {purpose, granted}. Replaces the prior choices for that (venue, customer).
  Future<void> setConsent(
    String venueId,
    String customerId,
    List<Map<String, dynamic>> choices,
  );

  /// A customer's consent choices at a venue (empty when none recorded).
  Future<List<Map<String, dynamic>>> forCustomer(
    String venueId,
    String customerId,
  );
}

class InMemoryConsentStore implements ConsentStore {
  final Map<String, List<Map<String, dynamic>>> _byKey = {};

  String _key(String venueId, String customerId) => '$venueId/$customerId';

  @override
  Future<void> setConsent(
    String venueId,
    String customerId,
    List<Map<String, dynamic>> choices,
  ) async {
    _byKey[_key(venueId, customerId)] = [
      for (final c in choices) Map<String, dynamic>.from(c),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> forCustomer(
    String venueId,
    String customerId,
  ) async =>
      _byKey[_key(venueId, customerId)] ?? const [];
}
