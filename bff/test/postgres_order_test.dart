import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:qorder_bff/database.dart';
import 'package:qorder_bff/models.dart';
import 'package:qorder_bff/postgres_order_store.dart';
import 'package:test/test.dart';

/// Integration tests against a real Postgres. Set QORDER_DATABASE_URL (the local
/// docker one) to run them; without it the group is skipped.
Map<String, dynamic> _order(
  String key, {
  int table = 5,
  String client = 'me',
  int total = 1000,
}) =>
    {
      'idempotencyKey': key,
      'tableNumber': table,
      'clientId': client,
      'customerName': 'Andrei',
      'totalMinor': total,
      'lines': [
        {'name': 'Beer', 'qty': 1},
      ],
    };

void main() {
  final url = Platform.environment['QORDER_DATABASE_URL'];

  group('PostgresOrderStore', () {
    late Pool<void> pool;
    late PostgresOrderStore store;

    setUpAll(() async {
      pool = openDatabasePool(url!);
      await applyMigrations(pool);
      store = PostgresOrderStore(pool);
    });

    setUp(() async {
      await pool.execute('DELETE FROM orders');
      await pool.execute('DELETE FROM venue_order_counters');
    });

    tearDownAll(() async {
      await pool.close();
    });

    test('submit persists the order and reads it back', () async {
      final placed = await store.submit(venueId: 'demo', order: _order('k1'));
      expect(placed.stage, OrderStage.pendingAcceptance);
      expect(placed.sequence, 1);
      // The sequence is the readable number; the id carries an opaque suffix, so
      // it is not the guessable `BFF-demo-1` (REQ-SEC-003).
      expect(placed.serverOrderId, startsWith('BFF-demo-1-'));

      final fetched = await store.status(placed.serverOrderId);
      expect(fetched!.tableNumber, 5);
      expect(fetched.totalMinor, 1000);
      expect(fetched.lines, isNotEmpty);
      expect(fetched.stamps.containsKey('submitted'), isTrue);
    });

    test('each venue numbers its orders from 1', () async {
      final a = await store.submit(venueId: 'venueA', order: _order('k1'));
      final b = await store.submit(venueId: 'venueB', order: _order('k1'));
      final a2 = await store.submit(venueId: 'venueA', order: _order('k2'));
      expect(a.sequence, 1);
      expect(b.sequence, 1);
      expect(a2.sequence, 2);
    });

    test('idempotent per venue: the same key returns the same order', () async {
      final a = await store.submit(venueId: 'demo', order: _order('dup'));
      final b = await store.submit(venueId: 'demo', order: _order('dup'));
      expect(b.serverOrderId, a.serverOrderId);
      expect((await store.forVenue('demo')).length, 1);
    });

    test('lifecycle: pending -> accept -> ready -> delivered', () async {
      final placed = await store.submit(venueId: 'demo', order: _order('k1'));
      expect((await store.pending('demo')).length, 1);

      final accepted = await store.accept('demo', placed.serverOrderId);
      expect(accepted!.stage, OrderStage.received);
      expect(accepted.stamps.containsKey('accepted'), isTrue);
      expect(await store.pending('demo'), isEmpty);
      expect((await store.inProgress('demo')).length, 1);

      final ready = await store.markReady('demo', placed.serverOrderId);
      expect(ready!.stage, OrderStage.done);
      expect(ready.stamps.containsKey('ready'), isTrue);

      final delivered = await store.markDelivered('demo', placed.serverOrderId);
      expect(delivered!.stage, OrderStage.delivered);
      expect(delivered.stamps.containsKey('delivered'), isTrue);
      expect(await store.inProgress('demo'), isEmpty);
    });

    test('accept on an unknown id returns null', () async {
      expect(await store.accept('demo', 'nope'), isNull);
    });

    test('a venue cannot accept another venue order (RLS)', () async {
      final placed = await store.submit(venueId: 'demo', order: _order('x1'));
      // A staff scoped to another venue sees nothing to accept.
      expect(await store.accept('other', placed.serverOrderId), isNull);
      // The order is still pending under its own venue.
      expect((await store.pending('demo')).length, 1);
    });

    test('one venue never sees another venue orders (tenant isolation)',
        () async {
      await store.submit(venueId: 'venueA', order: _order('k1', client: 'c1'));
      await store.submit(venueId: 'venueB', order: _order('k1', client: 'c1'));

      // A's queries return only A's single order, never B's, though B has an
      // identical order on the same table and client.
      expect((await store.forVenue('venueA')).length, 1);
      expect((await store.pending('venueA')).length, 1);
      expect((await store.forTable('venueA', 5)).length, 1);
      expect((await store.forCustomer('venueA', 'c1')).length, 1);
      expect(await store.forCustomer('venueB', 'c2'), isEmpty);
    });

    test('relink moves a customer orders across client_id', () async {
      await store.submit(venueId: 'demo', order: _order('k1', client: 'anon'));
      await store.relink('anon', 'cust:1');
      expect(await store.forCustomer('demo', 'anon'), isEmpty);
      expect((await store.forCustomer('demo', 'cust:1')).length, 1);
    });
  }, skip: url == null ? 'Set QORDER_DATABASE_URL to run' : false);
}
