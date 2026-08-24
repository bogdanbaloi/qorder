import '../../domain/platform/client_log_entry.dart';
import '../../domain/platform/operator_logs_source.dart';

/// No-backend operator logs: always empty. The offline admin screen shows the
/// "no recent errors" state.
class MockOperatorLogsSource implements OperatorLogsSource {
  const MockOperatorLogsSource();

  @override
  Future<List<ClientLogEntry>> recent(String operatorToken) async => const [];
}
