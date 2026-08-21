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

/// The venue sentinel that opens Row-Level Security to every venue, for the
/// operator plane (cross-venue reads). Must match the policy in
/// `migrations/0005_rls.sql`.
const String crossVenueScope = '__all__';

/// Runs [body] in a transaction scoped to [venueId] for Row-Level Security.
///
/// Drops to the non-superuser role `qorder_app` so RLS is enforced (a superuser
/// bypasses it) and sets `app.venue_id` for the policy. Both are `SET LOCAL`, so
/// they reset when the transaction ends. Pass [crossVenueScope] for a deliberate
/// cross-venue operation. Tenant stores route every statement through this, so a
/// forgotten `WHERE venue_id` cannot leak another venue's rows.
Future<T> runInVenue<T>(
  Pool<void> db,
  String venueId,
  Future<T> Function(Session tx) body,
) {
  return db.runTx((tx) async {
    await tx.execute('SET LOCAL ROLE qorder_app');
    await tx.execute(
      Sql.named("SELECT set_config('app.venue_id', @v, true)"),
      parameters: {'v': venueId},
    );
    return body(tx);
  });
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
