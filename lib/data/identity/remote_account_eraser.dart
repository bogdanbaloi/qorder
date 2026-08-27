import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';
import '../../domain/errors/app_exception.dart';
import '../../domain/identity/account_eraser.dart';

const int _httpOk = 200;

/// Erases the customer's data through the BFF (`POST /customers/:id/erase`),
/// authenticated with the customer's token. Throws on failure so the caller can
/// tell the user it did not go through.
class RemoteAccountEraser implements AccountEraser {
  final String baseUrl;
  final http.Client client;
  final String? authToken;

  RemoteAccountEraser({
    required this.baseUrl,
    required this.client,
    this.authToken,
  });

  @override
  Future<void> erase(String customerId) async {
    final res = await client
        .post(
          Uri.parse('$baseUrl/customers/$customerId/erase'),
          headers: {
            if (authToken != null) 'authorization': 'Bearer $authToken',
          },
        )
        .timeout(AppConstants.submitTimeout);
    if (res.statusCode != _httpOk) {
      throw BackendException('erase account', statusCode: res.statusCode);
    }
  }
}

/// Offline default: there is no backend to erase against, so the client-side
/// sign-out (which drops the local identity and name) is the whole erasure.
class MockAccountEraser implements AccountEraser {
  const MockAccountEraser();

  @override
  Future<void> erase(String customerId) => Future<void>.value();
}
