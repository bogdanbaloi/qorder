import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'database.dart';
import 'models.dart';
import 'order_store.dart';

/// Postgres-backed orders, scoped by venue. Venue-scoped operations run through
/// [runInVenue], so Row-Level Security enforces the tenant boundary at the
/// database (ADR-0059). The staff mutations (accept, the stage stamps) carry the
/// venue from the staff token, so RLS refuses another venue's order. Two paths
/// stay under [crossVenueScope] by design: the public `status` poll (the
/// customer has only the order id) and `relink` (a client id spans venues).
/// Identity links a customer's orders by client_id, global by design.
class PostgresOrderStore implements OrderStore {
  final Pool<void> _db;

  /// Whether a submitted order waits for a waiter before it is processed.
  final bool requiresWaiter;

  PostgresOrderStore(this._db, {this.requiresWaiter = true});

  int _now() => DateTime.now().millisecondsSinceEpoch;

  @override
  Future<BffOrder> submit({
    required String venueId,
    required Map<String, dynamic> order,
  }) async {
    final key = order['idempotencyKey'] as String?;
    return runInVenue(_db, venueId, (tx) async {
      if (key != null) {
        final existing = await tx.execute(
          Sql.named(
            'SELECT * FROM orders WHERE venue_id = @v AND idempotency_key = @k',
          ),
          parameters: {'v': venueId, 'k': key},
        );
        if (existing.isNotEmpty) return _toOrder(existing.first.toColumnMap());
      }
      // Atomic per-venue sequence: each venue numbers its orders from 1.
      final seqRow = await tx.execute(
        Sql.named('''
          INSERT INTO venue_order_counters (venue_id, last_seq) VALUES (@v, 1)
          ON CONFLICT (venue_id)
            DO UPDATE SET last_seq = venue_order_counters.last_seq + 1
          RETURNING last_seq
        '''),
        parameters: {'v': venueId},
      );
      final sequence = (seqRow.first[0] as num).toInt();
      final now = _now();
      final requiresWaiter = this.requiresWaiter;
      final stage =
          requiresWaiter ? OrderStage.pendingAcceptance : OrderStage.received;
      // Auto mode has no waiter step, so it is accepted at submit.
      final stamps = requiresWaiter
          ? {'submitted': now}
          : {'submitted': now, 'accepted': now};
      final inserted = await tx.execute(
        Sql.named('''
          INSERT INTO orders (server_order_id, venue_id, table_number, sequence,
            stage, lines, customer_name, client_id, idempotency_key, total_minor,
            stamps)
          VALUES (@id, @v, @tbl, @seq, @stage, @lines::jsonb, @name, @client,
            @key, @total, @stamps::jsonb)
          RETURNING *
        '''),
        parameters: {
          'id': 'BFF-$venueId-$sequence',
          'v': venueId,
          'tbl': (order['tableNumber'] as num).toInt(),
          'seq': sequence,
          'stage': stage.name,
          'lines': jsonEncode((order['lines'] as List?) ?? const []),
          'name': order['customerName'],
          'client': order['clientId'],
          'key': key,
          'total': (order['totalMinor'] as num?)?.toInt() ?? 0,
          'stamps': jsonEncode(stamps),
        },
      );
      return _toOrder(inserted.first.toColumnMap());
    });
  }

  @override
  Future<List<BffOrder>> pending(String venueId) => _query(
        venueId,
        "SELECT * FROM orders WHERE venue_id = @v AND stage = 'pendingAcceptance'",
        {'v': venueId},
      );

  @override
  Future<BffOrder?> accept(String venueId, String serverOrderId) async {
    return runInVenue(_db, venueId, (tx) async {
      final rows = await tx.execute(
        Sql.named('SELECT * FROM orders WHERE server_order_id = @id'),
        parameters: {'id': serverOrderId},
      );
      if (rows.isEmpty) return null;
      var order = _toOrder(rows.first.toColumnMap());
      if (order.stage == OrderStage.pendingAcceptance) {
        final updated = await tx.execute(
          Sql.named('''
            UPDATE orders SET stage = 'received',
              stamps = stamps || jsonb_build_object('accepted', @now::bigint)
            WHERE server_order_id = @id RETURNING *
          '''),
          parameters: {'id': serverOrderId, 'now': _now()},
        );
        order = _toOrder(updated.first.toColumnMap());
      }
      return order;
    });
  }

  @override
  Future<BffOrder?> status(String serverOrderId) => _one(
          crossVenueScope, 'SELECT * FROM orders WHERE server_order_id = @id', {
        'id': serverOrderId,
      });

  @override
  Future<List<BffOrder>> forTable(String venueId, int tableNumber) => _query(
        venueId,
        'SELECT * FROM orders WHERE venue_id = @v AND table_number = @t',
        {'v': venueId, 't': tableNumber},
      );

  @override
  Future<BffOrder?> markReady(String venueId, String serverOrderId) => _stamp(
        venueId,
        serverOrderId,
        stage: OrderStage.done,
        event: 'ready',
      );

  @override
  Future<BffOrder?> markDelivered(String venueId, String serverOrderId) =>
      _stamp(
        venueId,
        serverOrderId,
        stage: OrderStage.delivered,
        event: 'delivered',
      );

  @override
  Future<List<BffOrder>> inProgress(String venueId) => _query(
        venueId,
        "SELECT * FROM orders WHERE venue_id = @v AND stamps ? 'accepted' "
        "AND NOT (stamps ? 'delivered')",
        {'v': venueId},
      );

  @override
  Future<List<BffOrder>> forVenue(String venueId) => _query(
        venueId,
        'SELECT * FROM orders WHERE venue_id = @v',
        {'v': venueId},
      );

  @override
  Future<List<BffOrder>> forCustomer(String venueId, String clientId) => _query(
        venueId,
        'SELECT * FROM orders WHERE venue_id = @v AND client_id = @c '
        "ORDER BY (stamps->>'submitted')::bigint DESC",
        {'v': venueId, 'c': clientId},
      );

  @override
  Future<void> relink(String oldClientId, String newClientId) async {
    // A client id is global (identity merge), so relink spans venues.
    await runInVenue(_db, crossVenueScope, (tx) async {
      await tx.execute(
        Sql.named('UPDATE orders SET client_id = @new WHERE client_id = @old'),
        parameters: {'new': newClientId, 'old': oldClientId},
      );
    });
  }

  /// putIfAbsent the [event] stamp (so re-marking keeps the first time) and set
  /// the [stage]. `build_object || stamps` keeps an existing stamp, since the
  /// right operand wins on a key clash.
  Future<BffOrder?> _stamp(
    String venueScope,
    String serverOrderId, {
    required OrderStage stage,
    required String event,
  }) async {
    // Scoped to the staff token's venue, so RLS refuses another venue's order.
    return runInVenue(_db, venueScope, (tx) async {
      final rows = await tx.execute(
        Sql.named('''
          UPDATE orders SET stage = @stage,
            stamps = jsonb_build_object(@event::text, @now::bigint) || stamps
          WHERE server_order_id = @id RETURNING *
        '''),
        parameters: {
          'stage': stage.name,
          'event': event,
          'now': _now(),
          'id': serverOrderId,
        },
      );
      return rows.isEmpty ? null : _toOrder(rows.first.toColumnMap());
    });
  }

  Future<List<BffOrder>> _query(
    String venueScope,
    String sql,
    Map<String, Object?> params,
  ) {
    return runInVenue(_db, venueScope, (tx) async {
      final rows = await tx.execute(Sql.named(sql), parameters: params);
      return [for (final row in rows) _toOrder(row.toColumnMap())];
    });
  }

  Future<BffOrder?> _one(
    String venueScope,
    String sql,
    Map<String, Object?> params,
  ) {
    return runInVenue(_db, venueScope, (tx) async {
      final rows = await tx.execute(Sql.named(sql), parameters: params);
      return rows.isEmpty ? null : _toOrder(rows.first.toColumnMap());
    });
  }

  BffOrder _toOrder(Map<String, dynamic> row) {
    final lines = (_decodeJson(row['lines']) as List?) ?? const [];
    final stampsRaw = (_decodeJson(row['stamps']) as Map?) ?? const {};
    return BffOrder(
      serverOrderId: row['server_order_id'] as String,
      venueId: row['venue_id'] as String,
      tableNumber: (row['table_number'] as num).toInt(),
      sequence: (row['sequence'] as num).toInt(),
      stage: OrderStage.values.byName(row['stage'] as String),
      lines: lines,
      customerName: row['customer_name'] as String?,
      clientId: row['client_id'] as String?,
      idempotencyKey: row['idempotency_key'] as String?,
      totalMinor: (row['total_minor'] as num).toInt(),
      stamps: {
        for (final entry in stampsRaw.entries)
          entry.key as String: (entry.value as num).toInt(),
      },
    );
  }

  Object? _decodeJson(Object? value) =>
      value is String ? jsonDecode(value) : value;
}
