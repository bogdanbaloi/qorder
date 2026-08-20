import 'package:postgres/postgres.dart';

import 'consent_store.dart';

/// Postgres-backed consent, scoped by venue. Every statement filters on
/// venue_id, so one venue never reads or writes another's rows. The port
/// mandates venueId, so the tenant filter cannot be forgotten; Row-Level
/// Security is added as defence in depth in a later slice.
class PostgresConsentStore implements ConsentStore {
  final Pool<void> _db;

  PostgresConsentStore(this._db);

  @override
  Future<void> setConsent(
    String venueId,
    String customerId,
    List<Map<String, dynamic>> choices,
  ) async {
    // Replace the customer's prior choices for this venue atomically.
    await _db.runTx((tx) async {
      await tx.execute(
        Sql.named(
          'DELETE FROM consent WHERE venue_id = @v AND customer_id = @c',
        ),
        parameters: {'v': venueId, 'c': customerId},
      );
      for (final choice in choices) {
        await tx.execute(
          Sql.named(
            'INSERT INTO consent (venue_id, customer_id, purpose, granted) '
            'VALUES (@v, @c, @p, @g)',
          ),
          parameters: {
            'v': venueId,
            'c': customerId,
            'p': choice['purpose'],
            'g': choice['granted'],
          },
        );
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> forCustomer(
    String venueId,
    String customerId,
  ) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT purpose, granted FROM consent '
        'WHERE venue_id = @v AND customer_id = @c ORDER BY purpose',
      ),
      parameters: {'v': venueId, 'c': customerId},
    );
    return [
      for (final row in rows) {'purpose': row[0], 'granted': row[1]},
    ];
  }
}
