import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';
import '../../domain/errors/app_exception.dart';
import '../../domain/platform/platform_metrics.dart';
import '../../domain/platform/platform_metrics_source.dart';

const int _httpOk = 200;

/// Reads the operator snapshot from the BFF's `GET /platform/metrics`. Errors
/// propagate (unlike the degrade-open sources), so the admin screen can tell the
/// operator the token is wrong or the backend is unreachable.
class RemotePlatformMetricsSource implements PlatformMetricsSource {
  final String baseUrl;
  final http.Client client;

  RemotePlatformMetricsSource({required this.baseUrl, required this.client});

  @override
  Future<PlatformMetrics> snapshot(String operatorToken) async {
    final res = await client
        .get(
          Uri.parse('$baseUrl/platform/metrics'),
          headers: {'authorization': 'Bearer $operatorToken'},
        )
        .timeout(AppConstants.submitTimeout);
    if (res.statusCode != _httpOk) {
      throw BackendException('platform metrics', statusCode: res.statusCode);
    }
    return PlatformMetrics.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}
