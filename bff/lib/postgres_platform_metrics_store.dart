import 'package:postgres/postgres.dart';

import 'database.dart';
import 'platform_metrics.dart';

/// Postgres-backed operator metrics. Aggregates across every venue from the
/// orders table: order count and distinct users (client ids) per venue. Reads
/// cross-venue on purpose (the operator plane), so it runs under
/// [crossVenueScope], the one path Row-Level Security opens to every venue.
class PostgresPlatformMetricsStore implements PlatformMetricsStore {
  final Pool<void> _db;

  PostgresPlatformMetricsStore(this._db);

  @override
  Future<PlatformMetrics> snapshot() {
    return runInVenue(_db, crossVenueScope, (tx) async {
      final rows = await tx.execute(
        Sql.named('''
          SELECT venue_id,
                 count(*) AS orders,
                 count(DISTINCT client_id) AS users
          FROM orders
          GROUP BY venue_id
          ORDER BY venue_id
        '''),
      );
      return PlatformMetrics([
        for (final row in rows)
          VenueUsage(
            venueId: row.toColumnMap()['venue_id'] as String,
            orders: (row.toColumnMap()['orders'] as num).toInt(),
            users: (row.toColumnMap()['users'] as num).toInt(),
          ),
      ]);
    });
  }
}
