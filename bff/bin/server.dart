import 'dart:async';
import 'dart:io';

import 'package:qorder_bff/consent_store.dart';
import 'package:qorder_bff/database.dart';
import 'package:qorder_bff/identity_store.dart';
import 'package:qorder_bff/log_store.dart';
import 'package:qorder_bff/logging.dart';
import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:qorder_bff/platform_metrics.dart';
import 'package:qorder_bff/postgres_consent_store.dart';
import 'package:qorder_bff/postgres_identity_store.dart';
import 'package:qorder_bff/postgres_order_store.dart';
import 'package:qorder_bff/postgres_platform_metrics_store.dart';
import 'package:qorder_bff/postgres_redemption_store.dart';
import 'package:qorder_bff/postgres_log_store.dart';
import 'package:qorder_bff/postgres_venue_config_store.dart';
import 'package:qorder_bff/redemption_store.dart';
import 'package:qorder_bff/request_store.dart';
import 'package:qorder_bff/staff_auth_store.dart';
import 'package:qorder_bff/venue_config_store.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Client-log retention: keep the newest rows, pruned on this cadence.
const int _logRetainRows = 10000;
const Duration _logPruneInterval = Duration(hours: 6);

Future<void> main() async {
  final log = BffLog();
  // Per-venue staff/owner codes. A real deploy loads these per venue (or from the
  // POS user directory); the demo mirrors the app's AppConfig.demo codes.
  final staffAuth = InMemoryStaffAuthStore(
    codesByVenue: {
      'demo': {'staff': '2468', 'owner': '1357'},
    },
  );

  // Orders and consent persist to Postgres when a database is configured,
  // otherwise the in-memory stores (dev/tests without a DB). The remaining stores
  // migrate next, each behind its own port, so this stays incremental.
  final databaseUrl = Platform.environment['QORDER_DATABASE_URL'];
  final OrderStore orders;
  final ConsentStore consent;
  final RedemptionStore redemptions;
  final IdentityStore identity;
  final PlatformMetricsStore platformMetrics;
  final VenueConfigStore venueConfig;
  final LogStore logs;
  if (databaseUrl != null && databaseUrl.isNotEmpty) {
    final pool = openDatabasePool(databaseUrl);
    await applyMigrations(pool);
    orders = PostgresOrderStore(pool);
    consent = PostgresConsentStore(pool);
    redemptions = PostgresRedemptionStore(pool);
    identity = PostgresIdentityStore(pool);
    platformMetrics = PostgresPlatformMetricsStore(pool);
    venueConfig = PostgresVenueConfigStore(pool);
    logs = PostgresLogStore(pool);
    log.info('storage: Postgres (identity global)');
  } else {
    orders = InMemoryOrderStore();
    consent = InMemoryConsentStore();
    redemptions = InMemoryRedemptionStore();
    identity = InMemoryIdentityStore();
    platformMetrics = EmptyPlatformMetricsStore();
    venueConfig = InMemoryVenueConfigStore();
    logs = InMemoryLogStore();
    log.info(
        'storage: in-memory (no QORDER_DATABASE_URL, data is not durable)');
  }

  // The operator (cross-venue) surface is off until an operator token is set.
  final api = OrderApi(
    orders,
    InMemoryWaiterRequestStore(),
    redemptions,
    identity,
    consent,
    staffAuth,
    platformMetrics: platformMetrics,
    operatorToken: Platform.environment['QORDER_OPERATOR_TOKEN'],
    venueConfig: venueConfig,
    log: log,
    logs: logs,
  );
  // HOST=0.0.0.0 to expose on the LAN so phones can reach the laptop.
  final host = Platform.environment['HOST'] ?? '127.0.0.1';
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await shelf_io.serve(api.handler, host, port);
  log.info('listening on http://${server.address.host}:${server.port}');

  // Retention: bound the client-log table now and on a slow cadence.
  await logs.prune(keepLast: _logRetainRows);
  Timer.periodic(_logPruneInterval, (_) async {
    final removed = await logs.prune(keepLast: _logRetainRows);
    if (removed > 0) log.info('pruned $removed old client logs');
  });
}
