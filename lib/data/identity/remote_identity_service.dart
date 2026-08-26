import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';
import '../../domain/errors/app_exception.dart';
import '../../domain/identity/customer_identity.dart';
import '../../domain/identity/identity_service.dart';

const int _httpOk = 200;

/// Talks to the BFF's OTP routes. `startSignIn` returns the challenge (with the
/// dev code while there is no SMS); `verify` proves the phone and returns the
/// identity, passing the anonymous clientId so the backend merges past orders.
class RemoteIdentityService implements IdentityService {
  final String baseUrl;
  final http.Client client;

  RemoteIdentityService({required this.baseUrl, required this.client});

  @override
  Future<SignInChallenge> startSignIn(String phone) async {
    final res = await client
        .post(
          Uri.parse('$baseUrl/auth/otp/start'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(AppConstants.submitTimeout);
    if (res.statusCode != _httpOk) {
      throw BackendException('sign-in start', statusCode: res.statusCode);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return SignInChallenge(
      challengeId: json['challengeId'] as String,
      devHint: json['devCode'] as String?,
    );
  }

  @override
  Future<CustomerIdentity> verify(
    String challengeId,
    String code, {
    String? clientId,
  }) async {
    final res = await client
        .post(
          Uri.parse('$baseUrl/auth/otp/verify'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'challengeId': challengeId,
            'code': code,
            'clientId': ?clientId,
          }),
        )
        .timeout(AppConstants.submitTimeout);
    if (res.statusCode != _httpOk) {
      throw BackendException('verify', statusCode: res.statusCode);
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return CustomerIdentity(
      customerId: json['customerId'] as String,
      phone: json['phone'] as String? ?? '',
      token: json['token'] as String? ?? '',
    );
  }
}
