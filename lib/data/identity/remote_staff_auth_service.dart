import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';
import '../../domain/identity/session.dart';
import '../../domain/identity/staff_auth_service.dart';

const int _httpOk = 200;

/// Verifies the access code against the BFF's `POST /venues/:id/staff/auth` and
/// returns the scoped token. Null on a wrong code or any error.
class RemoteStaffAuthService implements StaffAuthService {
  final String baseUrl;
  final http.Client client;

  RemoteStaffAuthService({required this.baseUrl, required this.client});

  @override
  Future<String?> authenticate(
    String venueId,
    AppRole role,
    String code,
  ) async {
    try {
      final res = await client
          .post(
            Uri.parse('$baseUrl/venues/$venueId/staff/auth'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({'role': role.name, 'code': code}),
          )
          .timeout(AppConstants.submitTimeout);
      if (res.statusCode != _httpOk) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['token'] as String?;
    } on Exception {
      return null;
    }
  }
}
