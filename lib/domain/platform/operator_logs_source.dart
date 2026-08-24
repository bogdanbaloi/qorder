import 'client_log_entry.dart';

/// Reads the recent client diagnostics for the operator (the read side of the
/// apps shipping to `POST /logs`). Behind the operator token, cross-venue.
abstract interface class OperatorLogsSource {
  Future<List<ClientLogEntry>> recent(String operatorToken);
}
