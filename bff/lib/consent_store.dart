/// The consent PORT. Consent is stored per VENUE (each venue is the data
/// controller for its own customers) and per purpose, so it is auditable and
/// withdrawable. A persistent implementation drops in behind this interface.
abstract interface class ConsentStore {
  /// Record a customer's consent choices for a venue. Each choice is
  /// {purpose, granted}. Replaces the prior choices for that (venue, customer).
  void setConsent(
    String venueId,
    String customerId,
    List<Map<String, dynamic>> choices,
  );

  /// A customer's consent choices at a venue (empty when none recorded).
  List<Map<String, dynamic>> forCustomer(String venueId, String customerId);
}

class InMemoryConsentStore implements ConsentStore {
  final Map<String, List<Map<String, dynamic>>> _byKey = {};

  String _key(String venueId, String customerId) => '$venueId/$customerId';

  @override
  void setConsent(
    String venueId,
    String customerId,
    List<Map<String, dynamic>> choices,
  ) {
    _byKey[_key(venueId, customerId)] = [
      for (final c in choices) Map<String, dynamic>.from(c),
    ];
  }

  @override
  List<Map<String, dynamic>> forCustomer(String venueId, String customerId) =>
      _byKey[_key(venueId, customerId)] ?? const [];
}
