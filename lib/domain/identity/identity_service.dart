import 'customer_identity.dart';

/// The result of starting sign-in: a challenge to verify against, plus an
/// optional [devHint] (the code) so a demo with no SMS can show it. A real SMS
/// adapter leaves [devHint] null and sends the code by text instead.
class SignInChallenge {
  final String challengeId;
  final String? devHint;
  const SignInChallenge({required this.challengeId, this.devHint});
}

/// The customer sign-in PORT (Dependency Inversion). Phone + OTP (one-time
/// password by SMS) is the method: universal across web, Android, iOS and
/// Huawei. A mock (fixed code, no SMS) drives the demo and tests; the real
/// adapter (BFF + SMS) drops in behind this same interface.
abstract interface class IdentityService {
  /// Begin sign-in for a phone number; returns the challenge to verify against.
  Future<SignInChallenge> startSignIn(String phone);

  /// Verify the OTP for a challenge; returns the proven identity. [clientId] is
  /// the caller's anonymous key, sent so the backend can merge their pre-sign-in
  /// orders to the identity. Throws when the code is wrong.
  Future<CustomerIdentity> verify(
    String challengeId,
    String code, {
    String? clientId,
  });
}
