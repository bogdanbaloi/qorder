import 'package:postgres/postgres.dart';

import 'log_store.dart';

/// Postgres-backed client logs. Global (operator-plane diagnostics), so it does
/// not go through the tenant `runInVenue` path: the pool inserts and reads
/// directly, like the identity store. `venue_id` is a plain filter column.
class PostgresLogStore implements LogStore {
  final Pool<void> _db;

  PostgresLogStore(this._db);

  @override
  Future<void> add(List<ClientLogRecord> records) async {
    if (records.isEmpty) return;
    await _db.runTx((tx) async {
      for (final record in records) {
        await tx.execute(
          Sql.named('''
            INSERT INTO client_logs (level, message, venue_id, context)
            VALUES (@level, @message, @venue, @context)
          '''),
          parameters: {
            'level': record.level,
            'message': record.message,
            'venue': record.venueId,
            'context': record.context,
          },
        );
      }
    });
  }

  @override
  Future<List<ClientLogRecord>> recent({int limit = 100}) async {
    final rows = await _db.execute(
      Sql.named('''
        SELECT level, message, venue_id, context
        FROM client_logs ORDER BY id DESC LIMIT @limit
      '''),
      parameters: {'limit': limit},
    );
    return [
      for (final row in rows)
        ClientLogRecord(
          level: row[0] as String,
          message: row[1] as String,
          venueId: row[2] as String?,
          context: row[3] as String?,
        ),
    ];
  }
}
