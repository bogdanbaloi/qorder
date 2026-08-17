import '../../domain/identity/customer_identity.dart';
import '../../domain/identity/identity_service.dart';

/// A demo sign-in with no SMS: any phone starts a challenge, and a fixed code
/// verifies it. Lets the whole flow run locally, free, and in tests. The real
/// SMS-backed adapter (BFF) drops in behind the same port in a later slice.
class MockIdentityService implements IdentityService {
  /// The one code the demo accepts. Real OTP is random and sent by SMS.
  static const demoCode = '000000';

  const MockIdentityService();

  @override
  Future<SignInChallenge> startSignIn(String phone) async =>
      SignInChallenge(challengeId: 'challenge:$phone', devHint: demoCode);

  @override
  Future<CustomerIdentity> verify(
    String challengeId,
    String code, {
    String? clientId,
  }) async {
    if (code != demoCode) throw Exception('wrong code');
    final phone = challengeId.replaceFirst('challenge:', '');
    return CustomerIdentity(
      customerId: 'cust:$phone',
      phone: phone,
      token: 'mock-token',
    );
  }
}
