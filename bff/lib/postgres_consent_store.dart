import 'package:postgres/postgres.dart';

import 'consent_store.dart';
import 'database.dart';

/// Postgres-backed consent, scoped by venue. Every statement runs through
/// [runInVenue], so Row-Level Security enforces the tenant boundary at the
/// database (ADR-0059) on top of the venue_id filter the port already mandates.
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
    await runInVenue(_db, venueId, (tx) async {
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
  ) {
    return runInVenue(_db, venueId, (tx) async {
      final rows = await tx.execute(
        Sql.named(
          'SELECT purpose, granted FROM consent '
          'WHERE venue_id = @v AND customer_id = @c ORDER BY purpose',
        ),
        parameters: {'v': venueId, 'c': customerId},
      );
      return [
        for (final row in rows) {'purpose': row[0], 'granted': row[1]},
      ];
    });
  }

  @override
  Future<void> eraseCustomer(String customerId) async {
    // Consent spans venues for a person, so erase across all of them.
    await runInVenue(_db, crossVenueScope, (tx) async {
      await tx.execute(
        Sql.named('DELETE FROM consent WHERE customer_id = @c'),
        parameters: {'c': customerId},
      );
    });
  }
}
