import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:qorder_bff/database.dart';
import 'package:qorder_bff/postgres_redemption_store.dart';
import 'package:test/test.dart';

/// Integration tests against a real Postgres. Set QORDER_DATABASE_URL to run.
void main() {
  final url = Platform.environment['QORDER_DATABASE_URL'];

  group('PostgresRedemptionStore', () {
    late Pool<void> pool;
    late PostgresRedemptionStore store;

    setUpAll(() async {
      pool = openDatabasePool(url!);
      await applyMigrations(pool);
      store = PostgresRedemptionStore(pool, codeFor: (seq) => 'CODE$seq');
    });

    setUp(() async {
      await pool.execute('DELETE FROM redemptions');
    });

    tearDownAll(() async {
      await pool.close();
    });

    test('create persists and forCustomer returns newest first', () async {
      await store.create(
        venueId: 'demo',
        clientId: 'me',
        reward: 'Beer',
        cost: 100,
      );
      await store.create(
        venueId: 'demo',
        clientId: 'me',
        reward: 'Platter',
        cost: 250,
      );
      final mine = await store.forCustomer('demo', 'me');
      expect(mine.length, 2);
      expect(mine.first.reward, 'Platter'); // newest first
      expect(mine.every((r) => !r.consumed), isTrue);
    });

    test('pending excludes consumed, consume validates by code', () async {
      final r = await store.create(
        venueId: 'demo',
        clientId: 'me',
        reward: 'Beer',
        cost: 100,
      );
      expect((await store.pending('demo')).length, 1);

      expect(await store.consume(r.code), isTrue);
      expect(await store.pending('demo'), isEmpty);
      // A second consume of the same code fails (already validated).
      expect(await store.consume(r.code), isFalse);
      expect(await store.consume('nope'), isFalse);
    });

    test('one venue never sees another venue redemptions (isolation)',
        () async {
      await store.create(
        venueId: 'venueA',
        clientId: 'c1',
        reward: 'Beer',
        cost: 100,
      );
      await store.create(
        venueId: 'venueB',
        clientId: 'c1',
        reward: 'Beer',
        cost: 100,
      );
      expect((await store.forCustomer('venueA', 'c1')).length, 1);
      expect((await store.pending('venueA')).length, 1);
      expect(await store.forCustomer('venueB', 'c2'), isEmpty);
    });

    test('relink moves redemptions across client_id', () async {
      await store.create(
        venueId: 'demo',
        clientId: 'anon',
        reward: 'Beer',
        cost: 100,
      );
      await store.relink('anon', 'cust:1');
      expect(await store.forCustomer('demo', 'anon'), isEmpty);
      expect((await store.forCustomer('demo', 'cust:1')).length, 1);
    });
  }, skip: url == null ? 'Set QORDER_DATABASE_URL to run' : false);
}
