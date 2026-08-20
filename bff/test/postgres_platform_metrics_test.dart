import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:qorder_bff/database.dart';
import 'package:qorder_bff/postgres_order_store.dart';
import 'package:qorder_bff/postgres_platform_metrics_store.dart';
import 'package:test/test.dart';

/// Integration tests against a real Postgres. Set QORDER_DATABASE_URL to run.
void main() {
  final url = Platform.environment['QORDER_DATABASE_URL'];

  Map<String, dynamic> order(String key, String client) => {
        'idempotencyKey': key,
        'tableNumber': 5,
        'clientId': client,
        'lines': <dynamic>[],
      };

  group('PostgresPlatformMetricsStore', () {
    late Pool<void> pool;
    late PostgresOrderStore orders;
    late PostgresPlatformMetricsStore metrics;

    setUpAll(() async {
      pool = openDatabasePool(url!);
      await applyMigrations(pool);
      orders = PostgresOrderStore(pool);
      metrics = PostgresPlatformMetricsStore(pool);
    });

    setUp(() async {
      await pool.execute('DELETE FROM orders');
      await pool.execute('DELETE FROM venue_order_counters');
    });

    tearDownAll(() async {
      await pool.close();
    });

    test('aggregates orders and distinct users per venue', () async {
      await orders.submit(venueId: 'venueA', order: order('a1', 'c1'));
      await orders.submit(venueId: 'venueA', order: order('a2', 'c1'));
      await orders.submit(venueId: 'venueA', order: order('a3', 'c2'));
      await orders.submit(venueId: 'venueB', order: order('b1', 'c9'));

      final snap = await metrics.snapshot();
      expect(snap.venueCount, 2);

      final a = snap.venues.firstWhere((v) => v.venueId == 'venueA');
      expect(a.orders, 3);
      expect(a.users, 2); // c1 and c2 are distinct

      final b = snap.venues.firstWhere((v) => v.venueId == 'venueB');
      expect(b.orders, 1);
      expect(b.users, 1);
    });

    test('reports nothing when there are no orders', () async {
      final snap = await metrics.snapshot();
      expect(snap.venueCount, 0);
      expect(snap.venues, isEmpty);
    });
  }, skip: url == null ? 'Set QORDER_DATABASE_URL to run' : false);
}
