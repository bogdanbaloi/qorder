import 'package:postgres/postgres.dart';

import 'models.dart';
import 'redemption_store.dart';

/// Postgres-backed reward redemptions, scoped by venue. Every read filters on
/// venue_id. Consume looks a code up globally, since the code is the handle the
/// staff type and it is not shown with a venue. RLS follows as defence in depth.
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
    final rows = await _db.execute(
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
  }

  @override
  Future<List<BffRedemption>> forCustomer(String venueId, String clientId) =>
      _query(
        'SELECT * FROM redemptions WHERE venue_id = @v AND client_id = @c '
        'ORDER BY seq DESC',
        {'v': venueId, 'c': clientId},
      );

  @override
  Future<List<BffRedemption>> pending(String venueId) => _query(
        'SELECT * FROM redemptions WHERE venue_id = @v AND NOT consumed '
        'ORDER BY seq ASC',
        {'v': venueId},
      );

  @override
  Future<bool> consume(String code) async {
    // Consume exactly one pending redemption with this code (the oldest).
    final rows = await _db.execute(
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
  }

  @override
  Future<void> relink(String oldClientId, String newClientId) async {
    await _db.execute(
      Sql.named(
        'UPDATE redemptions SET client_id = @new WHERE client_id = @old',
      ),
      parameters: {'new': newClientId, 'old': oldClientId},
    );
  }

  Future<List<BffRedemption>> _query(
    String sql,
    Map<String, Object?> params,
  ) async {
    final rows = await _db.execute(Sql.named(sql), parameters: params);
    return [for (final row in rows) _toRedemption(row.toColumnMap())];
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
