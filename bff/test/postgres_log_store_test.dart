import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:qorder_bff/database.dart';
import 'package:qorder_bff/log_store.dart';
import 'package:qorder_bff/postgres_log_store.dart';
import 'package:test/test.dart';

/// Integration tests against a real Postgres. Set QORDER_DATABASE_URL to run.
void main() {
  final url = Platform.environment['QORDER_DATABASE_URL'];

  group('PostgresLogStore', () {
    late Pool<void> pool;
    late PostgresLogStore store;

    setUpAll(() async {
      pool = openDatabasePool(url!);
      await applyMigrations(pool);
      store = PostgresLogStore(pool);
    });

    setUp(() async {
      await pool.execute('DELETE FROM client_logs');
    });

    tearDownAll(() async {
      await pool.close();
    });

    test('add persists and recent returns newest first', () async {
      await store.add(const [
        ClientLogRecord(level: 'warning', message: 'first', venueId: 'demo'),
        ClientLogRecord(level: 'error', message: 'second'),
      ]);
      final recent = await store.recent(limit: 10);
      expect(recent.map((r) => r.message), ['second', 'first']);
      expect(recent.last.venueId, 'demo');
    });

    test('recent respects the limit', () async {
      await store.add([
        for (var i = 0; i < 5; i++)
          ClientLogRecord(level: 'warning', message: 'm$i'),
      ]);
      expect((await store.recent(limit: 2)).length, 2);
    });

    test('prune keeps only the newest rows', () async {
      await store.add([
        for (var i = 0; i < 6; i++)
          ClientLogRecord(level: 'warning', message: 'm$i'),
      ]);
      final removed = await store.prune(keepLast: 2);
      expect(removed, 4);
      final left = await store.recent(limit: 100);
      expect(left.map((r) => r.message), ['m5', 'm4']);
    });
  }, skip: url == null ? 'Set QORDER_DATABASE_URL to run' : false);
}
