import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';
import '../../domain/identity/consent.dart';
import '../../domain/identity/consent_source.dart';

const int _httpOk = 200;

/// Persists the customer's per-venue consent on the BFF. Reads degrade to an
/// empty list on error; the write throws so the sign-in flow can react.
class RemoteConsentSource implements ConsentSource {
  final String baseUrl;
  final http.Client client;

  /// The signed-in customer's bearer token; consent is a known-customer write, so
  /// the BFF authorizes against it.
  final String? authToken;

  RemoteConsentSource({
    required this.baseUrl,
    required this.client,
    this.authToken,
  });

  Map<String, String> get _auth =>
      {if (authToken != null) 'authorization': 'Bearer $authToken'};

  @override
  Future<void> setConsent(
    String venueId,
    String customerId,
    List<Consent> choices,
  ) async {
    final res = await client
        .post(
          Uri.parse('$baseUrl/venues/$venueId/customers/$customerId/consent'),
          headers: {'content-type': 'application/json', ..._auth},
          body: jsonEncode({'choices': [for (final c in choices) c.toJson()]}),
        )
        .timeout(AppConstants.submitTimeout);
    if (res.statusCode != _httpOk) throw Exception('consent failed');
  }

  @override
  Future<List<Consent>> forCustomer(String venueId, String customerId) async {
    try {
      final res = await client
          .get(
            Uri.parse('$baseUrl/venues/$venueId/customers/$customerId/consent'),
            headers: _auth,
          )
          .timeout(AppConstants.submitTimeout);
      if (res.statusCode != _httpOk) return const [];
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => Consent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception {
      return const [];
    }
  }
}
