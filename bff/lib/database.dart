import 'dart:io';

import 'package:postgres/postgres.dart';

const int _defaultPort = 5432;
const int _maxConnections = 8;

/// Opens a Postgres connection pool from a `postgres://user:pass@host:port/db`
/// URL (QORDER_DATABASE_URL). A pool, so concurrent requests do not serialise on
/// a single connection. SSL is required for a managed host and disabled for a
/// local one, so the same code targets local Docker and Neon/Supabase.
Pool<void> openDatabasePool(String url) {
  final uri = Uri.parse(url);
  final userInfo = uri.userInfo.split(':');
  final isLocal = uri.host == 'localhost' || uri.host == '127.0.0.1';
  final endpoint = Endpoint(
    host: uri.host,
    port: uri.hasPort ? uri.port : _defaultPort,
    database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'qorder',
    username: userInfo.isNotEmpty ? Uri.decodeComponent(userInfo.first) : null,
    password: userInfo.length > 1 ? Uri.decodeComponent(userInfo[1]) : null,
  );
  return Pool.withEndpoints(
    [endpoint],
    settings: PoolSettings(
      sslMode: isLocal ? SslMode.disable : SslMode.require,
      maxConnectionCount: _maxConnections,
    ),
  );
}

/// Applies the SQL migration files in [dir] in filename order. Idempotent: the
/// migrations use `CREATE TABLE IF NOT EXISTS`, so re-running is safe. A real
/// migration ledger (applied-versions table) lands when the schema grows.
Future<void> applyMigrations(Session db, {String dir = 'migrations'}) async {
  final files = Directory(dir)
      .listSync()
      .whereType<File>()
      .where(
        (file) => file.path.endsWith('.sql'),
      )
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    await db.execute(file.readAsStringSync(), queryMode: QueryMode.simple);
  }
}
