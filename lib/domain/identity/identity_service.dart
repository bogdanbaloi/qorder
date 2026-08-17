import 'customer_identity.dart';

/// The customer sign-in PORT (Dependency Inversion). Phone + OTP (one-time
/// password by SMS) is the method: universal across web, Android, iOS and
/// Huawei. A mock (fixed code, no SMS) drives the demo and tests; the real
/// adapter (BFF + SMS) drops in behind this same interface.
abstract interface class IdentityService {
  /// Begin sign-in for a phone number; returns a challenge id to verify against.
  Future<String> startSignIn(String phone);

  /// Verify the OTP for a challenge; returns the proven identity. Throws when the
  /// code is wrong.
  Future<CustomerIdentity> verify(String challengeId, String code);
}
