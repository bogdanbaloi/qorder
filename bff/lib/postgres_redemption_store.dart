import 'package:postgres/postgres.dart';

import 'database.dart';
import 'models.dart';
import 'redemption_store.dart';

/// Postgres-backed reward redemptions, scoped by venue. Venue-scoped operations
/// run through [runInVenue], so Row-Level Security enforces the tenant boundary
/// at the database (ADR-0059). Consume looks a code up globally (the staff type
/// a code with no venue), so it runs under [crossVenueScope].
class PostgresRedemptionStore implements RedemptionStore {
  final Pool<void> _db;

  /// Injectable so tests get deterministic codes; production uses the random one.
  final String Function(int sequence) codeFor;

  PostgresRedemptionStore(this._db, {this.codeFor = defaultRedemptionCode});

  int _codeSeq = 0;

  int _now() => DateTime.now().millisecondsSinceEpoch;

  @override
  Future<BffRedemption> create({
    required String venueId,
    required String clientId,
    required String reward,
    required int cost,
  }) async {
    _codeSeq += 1;
    return runInVenue(_db, venueId, (tx) async {
      final rows = await tx.execute(
        Sql.named('''
          INSERT INTO redemptions
            (venue_id, client_id, reward, cost, code, created_at_ms)
          VALUES (@v, @c, @r, @cost, @code, @now::bigint)
          RETURNING *
        '''),
        parameters: {
          'v': venueId,
          'c': clientId,
          'r': reward,
          'cost': cost,
          'code': codeFor(_codeSeq),
          'now': _now(),
        },
      );
      return _toRedemption(rows.first.toColumnMap());
    });
  }

  @override
  Future<List<BffRedemption>> forCustomer(String venueId, String clientId) =>
      _query(
        venueId,
        'SELECT * FROM redemptions WHERE venue_id = @v AND client_id = @c '
        'ORDER BY seq DESC',
        {'v': venueId, 'c': clientId},
      );

  @override
  Future<List<BffRedemption>> pending(String venueId) => _query(
        venueId,
        'SELECT * FROM redemptions WHERE venue_id = @v AND NOT consumed '
        'ORDER BY seq ASC',
        {'v': venueId},
      );

  @override
  Future<bool> consume(String code) async {
    // The staff type a code with no venue, so the lookup spans venues.
    return runInVenue(_db, crossVenueScope, (tx) async {
      // Consume exactly one pending redemption with this code (the oldest).
      final rows = await tx.execute(
        Sql.named('''
          UPDATE redemptions SET consumed = true
          WHERE id = (
            SELECT id FROM redemptions WHERE code = @code AND NOT consumed
            ORDER BY seq LIMIT 1
          )
          RETURNING id
        '''),
        parameters: {'code': code},
      );
      return rows.isNotEmpty;
    });
  }

  @override
  Future<void> relink(String oldClientId, String newClientId) async {
    // A client id is global (identity merge), so relink spans venues.
    await runInVenue(_db, crossVenueScope, (tx) async {
      await tx.execute(
        Sql.named(
          'UPDATE redemptions SET client_id = @new WHERE client_id = @old',
        ),
        parameters: {'new': newClientId, 'old': oldClientId},
      );
    });
  }

  @override
  Future<void> eraseCustomer(String customerId) async {
    await runInVenue(_db, crossVenueScope, (tx) async {
      await tx.execute(
        Sql.named('DELETE FROM redemptions WHERE client_id = @c'),
        parameters: {'c': customerId},
      );
    });
  }

  Future<List<BffRedemption>> _query(
    String venueScope,
    String sql,
    Map<String, Object?> params,
  ) {
    return runInVenue(_db, venueScope, (tx) async {
      final rows = await tx.execute(Sql.named(sql), parameters: params);
      return [for (final row in rows) _toRedemption(row.toColumnMap())];
    });
  }

  BffRedemption _toRedemption(Map<String, dynamic> row) => BffRedemption(
        id: row['id'] as String,
        venueId: row['venue_id'] as String,
        clientId: row['client_id'] as String,
        reward: row['reward'] as String,
        cost: (row['cost'] as num).toInt(),
        code: row['code'] as String,
        createdAtMs: (row['created_at_ms'] as num).toInt(),
        consumed: row['consumed'] as bool,
      );
}
