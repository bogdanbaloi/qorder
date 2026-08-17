import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';
import '../../domain/history/history_source.dart';
import '../../domain/history/past_order.dart';

const int _httpOk = 200;

/// Reads the customer's order history from the BFF's
/// `GET /venues/:id/customers/:clientId/orders`. Degrades to an empty list on
/// any error, so the account screen never breaks.
class RemoteHistorySource implements HistorySource {
  final String baseUrl;
  final http.Client client;

  RemoteHistorySource({required this.baseUrl, required this.client});

  @override
  Future<List<PastOrder>> orders(String venueId, String clientId) async {
    try {
      final res = await client
          .get(Uri.parse('$baseUrl/venues/$venueId/customers/$clientId/orders'))
          .timeout(AppConstants.submitTimeout);
      if (res.statusCode != _httpOk) return const [];
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => PastOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception {
      return const [];
    }
  }
}
