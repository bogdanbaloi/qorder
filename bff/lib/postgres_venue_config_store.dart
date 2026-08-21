import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'database.dart';
import 'venue_config_store.dart';

/// Postgres-backed venue config, one JSON document per venue. Runs through
/// [runInVenue], so Row-Level Security enforces the tenant boundary at the
/// database (ADR-0059): the owner reads and writes only their own venue.
class PostgresVenueConfigStore implements VenueConfigStore {
  final Pool<void> _db;

  PostgresVenueConfigStore(this._db);

  @override
  Future<Map<String, dynamic>?> get(String venueId) {
    return runInVenue(_db, venueId, (tx) async {
      final rows = await tx.execute(
        Sql.named('SELECT doc FROM venue_config WHERE venue_id = @v'),
        parameters: {'v': venueId},
      );
      if (rows.isEmpty) return null;
      return _asMap(rows.first.toColumnMap()['doc']);
    });
  }

  @override
  Future<void> put(String venueId, Map<String, dynamic> doc) {
    return runInVenue(_db, venueId, (tx) async {
      await tx.execute(
        Sql.named('''
          INSERT INTO venue_config (venue_id, doc, updated_at)
          VALUES (@v, @doc::jsonb, now())
          ON CONFLICT (venue_id)
            DO UPDATE SET doc = @doc::jsonb, updated_at = now()
        '''),
        parameters: {'v': venueId, 'doc': jsonEncode(doc)},
      );
    });
  }

  /// jsonb comes back decoded (a Map) or, defensively, as a string to decode.
  Map<String, dynamic> _asMap(Object? value) => value is String
      ? jsonDecode(value) as Map<String, dynamic>
      : (value as Map).cast<String, dynamic>();
}
