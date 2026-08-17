import '../../domain/identity/consent.dart';
import '../../domain/identity/consent_source.dart';

/// Records consent in memory for the demo (lost on restart); the seam is here so
/// the sign-in flow captures explicit, per-purpose consent from day one. The real
/// adapter persists it on the BFF, per venue, with a timestamp and terms version.
class MockConsentSource implements ConsentSource {
  final Map<String, List<Consent>> _byKey = {};

  String _key(String venueId, String customerId) => '$venueId/$customerId';

  @override
  Future<void> setConsent(
    String venueId,
    String customerId,
    List<Consent> choices,
  ) async {
    _byKey[_key(venueId, customerId)] = List.of(choices);
  }

  @override
  Future<List<Consent>> forCustomer(String venueId, String customerId) async =>
      _byKey[_key(venueId, customerId)] ?? const [];
}
