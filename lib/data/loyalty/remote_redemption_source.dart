import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';
import '../../domain/loyalty/redemption.dart';
import '../../domain/loyalty/redemption_source.dart';

const int _httpOk = 200;

/// Talks to the BFF's redemption routes. Reads degrade to an empty list on error
/// (the account/staff screens never break); writes (redeem / consume) throw on
/// failure, so the caller can tell the user it did not go through.
class RemoteRedemptionSource implements RewardRedeemer, RedemptionBoard {
  final String baseUrl;
  final http.Client client;

  /// The signed-in customer's bearer token; the BFF authorizes a known
  /// customer's redemption reads/writes against it. Null when anonymous.
  final String? authToken;

  RemoteRedemptionSource({
    required this.baseUrl,
    required this.client,
    this.authToken,
  });

  Map<String, String> get _auth =>
      {if (authToken != null) 'authorization': 'Bearer $authToken'};

  @override
  Future<Redemption> redeem(
    String venueId,
    String clientId, {
    required String reward,
    required int cost,
  }) async {
    final res = await client
        .post(
          Uri.parse('$baseUrl/venues/$venueId/customers/$clientId/redemptions'),
          headers: {'content-type': 'application/json', ..._auth},
          body: jsonEncode({'reward': reward, 'cost': cost}),
        )
        .timeout(AppConstants.submitTimeout);
    if (res.statusCode != _httpOk) {
      throw Exception('redeem failed: ${res.statusCode}');
    }
    return Redemption.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<List<Redemption>> forCustomer(String venueId, String clientId) =>
      _list('$baseUrl/venues/$venueId/customers/$clientId/redemptions');

  @override
  Future<List<Redemption>> pending(String venueId) =>
      _list('$baseUrl/venues/$venueId/redemptions/pending');

  @override
  Future<void> consume(String code) async {
    final res = await client
        .post(Uri.parse('$baseUrl/redemptions/$code/consume'))
        .timeout(AppConstants.submitTimeout);
    if (res.statusCode != _httpOk) {
      throw Exception('validate failed: ${res.statusCode}');
    }
  }

  Future<List<Redemption>> _list(String url) async {
    try {
      final res = await client
          .get(Uri.parse(url), headers: _auth)
          .timeout(AppConstants.submitTimeout);
      if (res.statusCode != _httpOk) return const [];
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => Redemption.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception {
      return const [];
    }
  }
}
