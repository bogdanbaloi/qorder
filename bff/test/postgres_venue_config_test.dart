import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:qorder_bff/database.dart';
import 'package:qorder_bff/postgres_venue_config_store.dart';
import 'package:test/test.dart';

/// Integration tests against a real Postgres. Set QORDER_DATABASE_URL to run.
void main() {
  final url = Platform.environment['QORDER_DATABASE_URL'];

  group('PostgresVenueConfigStore', () {
    late Pool<void> pool;
    late PostgresVenueConfigStore store;

    setUpAll(() async {
      pool = openDatabasePool(url!);
      await applyMigrations(pool);
      store = PostgresVenueConfigStore(pool);
    });

    setUp(() async {
      await pool.execute('DELETE FROM venue_config');
    });

    tearDownAll(() async {
      await pool.close();
    });

    test('put then get returns the saved document', () async {
      await store.put('demo', {
        'branding': {'venueName': 'Demo', 'primaryColor': '0xFFF26A21'},
      });
      final doc = await store.get('demo');
      expect((doc!['branding'] as Map)['venueName'], 'Demo');
    });

    test('get returns null when nothing is saved', () async {
      expect(await store.get('demo'), isNull);
    });

    test('put replaces the prior document', () async {
      await store.put('demo', {'venueName': 'Old'});
      await store.put('demo', {'venueName': 'New'});
      expect((await store.get('demo'))!['venueName'], 'New');
    });

    test('one venue never reads another venue config (isolation)', () async {
      await store.put('venueA', {'venueName': 'A'});
      await store.put('venueB', {'venueName': 'B'});
      expect((await store.get('venueA'))!['venueName'], 'A');
      expect((await store.get('venueB'))!['venueName'], 'B');
    });
  }, skip: url == null ? 'Set QORDER_DATABASE_URL to run' : false);
}
