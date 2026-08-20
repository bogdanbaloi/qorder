/// Usage for one venue: how many orders it has taken and how many distinct
/// users (client ids) placed them.
class VenueUsage {
  final String venueId;
  final int orders;
  final int users;

  VenueUsage({
    required this.venueId,
    required this.orders,
    required this.users,
  });

  Map<String, dynamic> toJson() => {
        'venueId': venueId,
        'orders': orders,
        'users': users,
      };
}

/// A cross-venue operator snapshot: which venues are active and their usage. This
/// is the OPERATOR plane (our own evidence), distinct from the per-venue owner
/// dashboard.
class PlatformMetrics {
  final List<VenueUsage> venues;

  PlatformMetrics(this.venues);

  int get venueCount => venues.length;

  Map<String, dynamic> toJson() => {
        'venueCount': venueCount,
        'venues': [for (final venue in venues) venue.toJson()],
      };
}

/// The operator-metrics PORT (Dependency Inversion). A Postgres implementation
/// aggregates across every venue; a null implementation is used with no database.
abstract interface class PlatformMetricsStore {
  /// A snapshot of active venues and their usage, ordered by venueId.
  Future<PlatformMetrics> snapshot();
}

/// Used when there is no database: operator evidence needs durable cross-venue
/// data, so with only the in-memory stores it reports nothing.
class EmptyPlatformMetricsStore implements PlatformMetricsStore {
  @override
  Future<PlatformMetrics> snapshot() async => PlatformMetrics(const []);
}
