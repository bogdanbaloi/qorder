import 'session.dart';

/// The staff/owner sign-in PORT: exchange a venue access code for a scoped token.
/// The remote adapter verifies against the BFF; the mock checks the configured
/// code locally (no backend). Same token seam as the customer identity.
abstract interface class StaffAuthService {
  /// Returns a token when the code is right for [role] at [venueId], else null.
  Future<String?> authenticate(String venueId, AppRole role, String code);
}
