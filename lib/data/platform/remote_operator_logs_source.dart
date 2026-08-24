import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';
import '../../domain/platform/client_log_entry.dart';
import '../../domain/platform/operator_logs_source.dart';

const int _httpOk = 200;

/// Reads recent client diagnostics from the BFF's `GET /logs`. Errors propagate
/// (like the metrics source), so the admin screen can tell the operator the
/// token is wrong or the backend is unreachable.
class RemoteOperatorLogsSource implements OperatorLogsSource {
  final String baseUrl;
  final http.Client client;

  RemoteOperatorLogsSource({required this.baseUrl, required this.client});

  @override
  Future<List<ClientLogEntry>> recent(String operatorToken) async {
    final res = await client
        .get(
          Uri.parse('$baseUrl/logs'),
          headers: {'authorization': 'Bearer $operatorToken'},
        )
        .timeout(AppConstants.submitTimeout);
    if (res.statusCode != _httpOk) {
      throw Exception('operator logs failed: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List;
    return [
      for (final entry in list)
        ClientLogEntry.fromJson(entry as Map<String, dynamic>),
    ];
  }
}
