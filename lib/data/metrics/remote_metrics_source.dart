import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';
import '../../domain/metrics/metrics_source.dart';
import '../../domain/metrics/sales_metrics.dart';

const int _httpOk = 200;

/// Reads the owner sales metrics from the BFF's `GET /venues/:id/metrics`.
/// Degrades to empty metrics on any error, so the dashboard never breaks.
class RemoteMetricsSource implements MetricsSource {
  final String baseUrl;
  final http.Client client;

  /// The owner's bearer token; the BFF metrics route requires the owner role.
  final String? authToken;

  RemoteMetricsSource({
    required this.baseUrl,
    required this.client,
    this.authToken,
  });

  @override
  Future<SalesMetrics> salesMetrics(String venueId) async {
    try {
      final res = await client
          .get(
            Uri.parse('$baseUrl/venues/$venueId/metrics'),
            headers: {if (authToken != null) 'authorization': 'Bearer $authToken'},
          )
          .timeout(AppConstants.submitTimeout);
      if (res.statusCode != _httpOk) return const SalesMetrics.empty();
      return SalesMetrics.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    } on Exception {
      return const SalesMetrics.empty();
    }
  }
}
