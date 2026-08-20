import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:qorder_bff/database.dart';
import 'package:qorder_bff/postgres_consent_store.dart';
import 'package:test/test.dart';

/// Integration tests against a real Postgres. Set QORDER_DATABASE_URL (the local
/// docker one, `postgres://postgres:postgres@localhost:5432/qorder`) to run them;
/// without it the group is skipped so the in-memory suite stays runnable with no
/// database.
void main() {
  final url = Platform.environment['QORDER_DATABASE_URL'];

  group('PostgresConsentStore', () {
    late Pool<void> pool;
    late PostgresConsentStore store;

    setUpAll(() async {
      pool = openDatabasePool(url!);
      await applyMigrations(pool);
      store = PostgresConsentStore(pool);
    });

    setUp(() async {
      await pool.execute('DELETE FROM consent');
    });

    tearDownAll(() async {
      await pool.close();
    });

    test('records and reads a customer consent at a venue', () async {
      await store.setConsent('demo', 'c1', [
        {'purpose': 'loyalty', 'granted': true},
        {'purpose': 'marketing', 'granted': false},
      ]);
      expect(await store.forCustomer('demo', 'c1'), [
        {'purpose': 'loyalty', 'granted': true},
        {'purpose': 'marketing', 'granted': false},
      ]);
    });

    test('setConsent replaces the prior choices', () async {
      await store.setConsent('demo', 'c1', [
        {'purpose': 'loyalty', 'granted': true},
      ]);
      await store.setConsent('demo', 'c1', [
        {'purpose': 'loyalty', 'granted': false},
      ]);
      expect(await store.forCustomer('demo', 'c1'), [
        {'purpose': 'loyalty', 'granted': false},
      ]);
    });

    test('one venue never sees another venue rows (tenant isolation)',
        () async {
      await store.setConsent('venueA', 'c1', [
        {'purpose': 'loyalty', 'granted': true},
      ]);
      await store.setConsent('venueB', 'c1', [
        {'purpose': 'marketing', 'granted': true},
      ]);

      expect(await store.forCustomer('venueA', 'c1'), [
        {'purpose': 'loyalty', 'granted': true},
      ]);
      expect(await store.forCustomer('venueB', 'c1'), [
        {'purpose': 'marketing', 'granted': true},
      ]);
      // A's key does not exist under B, so a cross-tenant read is empty.
      expect(await store.forCustomer('venueA', 'c2'), isEmpty);
    });
  },
      skip: url == null
          ? 'Set QORDER_DATABASE_URL to run (see bff/docker-compose.yml)'
          : false);
}
