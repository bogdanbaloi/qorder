/// One client diagnostic record shipped from an app.
class ClientLogRecord {
  final String level;
  final String message;
  final String? venueId;
  final String? context;

  const ClientLogRecord({
    required this.level,
    required this.message,
    this.venueId,
    this.context,
  });

  Map<String, dynamic> toJson() => {
        'level': level,
        'message': message,
        if (venueId != null) 'venueId': venueId,
        if (context != null) 'context': context,
      };
}

/// The client-log store PORT. Persists diagnostics shipped from the apps and
/// reads the most recent back for the operator. Operator-plane, not tenant data,
/// so it is global. An in-memory implementation serves dev and tests;
/// PostgresLogStore persists it.
abstract interface class LogStore {
  Future<void> add(List<ClientLogRecord> records);

  /// The most recent records, newest first, capped at [limit].
  Future<List<ClientLogRecord>> recent({int limit});
}

/// In-memory client logs, for dev and tests without a database. Not durable.
class InMemoryLogStore implements LogStore {
  final List<ClientLogRecord> _records = [];

  @override
  Future<void> add(List<ClientLogRecord> records) async {
    _records.addAll(records);
  }

  @override
  Future<List<ClientLogRecord>> recent({int limit = 100}) async {
    final from = _records.length > limit ? _records.length - limit : 0;
    return _records.sublist(from).reversed.toList();
  }
}
