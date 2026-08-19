import '../../core/config/app_config.dart';
import '../../domain/config/venue_config_source.dart';

/// Holds venue configs in memory, keyed by their venueId. The Phase-0 source:
/// the config lives in the binary. A remote source (our backend) replaces it
/// later behind the same [VenueConfigSource] port, without touching callers.
///
/// The venue list is authored (by us / an asset), not user input, so a duplicate
/// venueId simply keeps the last entry rather than being an error path.
class InMemoryVenueConfigSource implements VenueConfigSource {
  final Map<String, AppConfig> _byVenueId;

  InMemoryVenueConfigSource(List<AppConfig> venues)
    : _byVenueId = {for (final venue in venues) venue.venueId: venue};

  /// The single demo venue, matching the previously hard-wired config, so the
  /// default deployment behaves exactly as before this seam was introduced.
  factory InMemoryVenueConfigSource.demo() =>
      InMemoryVenueConfigSource(const [AppConfig.demo]);

  @override
  AppConfig? configFor(String venueId) => _byVenueId[venueId];
}
