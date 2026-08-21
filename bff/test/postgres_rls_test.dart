import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:qorder_bff/database.dart';
import 'package:qorder_bff/postgres_order_store.dart';
import 'package:test/test.dart';

/// Integration tests for Row-Level Security (ADR-0059, REQ-PERSIST-005). These
/// prove the DATABASE itself refuses a cross-venue row, even when the SQL
/// carries no venue filter, so a forgotten `WHERE venue_id` cannot leak a tenant.
/// Set QORDER_DATABASE_URL (the local docker one) to run them. Without it the
/// group is skipped.
void main() {
  final url = Platform.environment['QORDER_DATABASE_URL'];

  group('Row-Level Security', () {
    late Pool<void> pool;
    late PostgresOrderStore store;

    setUpAll(() async {
      pool = openDatabasePool(url!);
      await applyMigrations(pool);
      store = PostgresOrderStore(pool);
    });

    setUp(() async {
      // The raw pool is the table owner, so it bypasses RLS and can wipe all.
      await pool.execute('DELETE FROM orders');
      await pool.execute('DELETE FROM venue_order_counters');
    });

    tearDownAll(() async {
      await pool.close();
    });

    Future<void> seed(String venue) async {
      await store.submit(
        venueId: venue,
        order: {'tableNumber': 1, 'lines': const [], 'clientId': 'c-$venue'},
      );
    }

    test('a venue-scoped session sees only its own rows, filter or not',
        () async {
      await seed('venueA');
      await seed('venueB');

      // A bare SELECT with NO venue filter: only RLS can scope this.
      final scoped = await runInVenue(pool, 'venueA', (tx) async {
        final rows = await tx.execute('SELECT venue_id FROM orders');
        return [for (final row in rows) row[0] as String];
      });
      expect(scoped, ['venueA']);
    });

    test('the cross-venue sentinel sees every venue', () async {
      await seed('venueA');
      await seed('venueB');

      final all = await runInVenue(pool, crossVenueScope, (tx) async {
        final rows = await tx.execute('SELECT DISTINCT venue_id FROM orders');
        return {for (final row in rows) row[0] as String};
      });
      expect(all, {'venueA', 'venueB'});
    });

    test('an insert tagged with the wrong venue is refused by the policy',
        () async {
      // Under venueA scope, insert a row tagged venueB. WITH CHECK blocks it.
      await expectLater(
        runInVenue(pool, 'venueA', (tx) async {
          await tx.execute('''
            INSERT INTO orders (server_order_id, venue_id, table_number,
              sequence, stage, total_minor)
            VALUES ('x', 'venueB', 1, 1, 'received', 0)
          ''');
        }),
        throwsA(isA<Exception>()),
      );
    });
  }, skip: url == null ? 'Set QORDER_DATABASE_URL to run' : false);
}
