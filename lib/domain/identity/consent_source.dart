import 'consent.dart';

/// The consent PORT. Consent is recorded per VENUE (each venue is the data
/// controller for its own customers) and per purpose. The mock records nothing;
/// the real adapter persists it on the BFF against the customer's identity.
abstract interface class ConsentSource {
  Future<void> setConsent(
    String venueId,
    String customerId,
    List<Consent> choices,
  );

  Future<List<Consent>> forCustomer(String venueId, String customerId);
}
