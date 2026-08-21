import '../../core/config/app_config.dart';
import '../../domain/config/venue_config_api.dart';

/// In-memory venue config for the no-backend demo and for tests. A saved edit is
/// re-fetchable within the session, so the Settings round-trip works offline.
/// Not durable, which mirrors the mock backend everywhere else.
class MockVenueConfigApi implements VenueConfigApi {
  final Map<String, AppConfig> _byVenue = {};

  @override
  Future<AppConfig?> fetch(String venueId) async => _byVenue[venueId];

  @override
  Future<void> save(String venueId, AppConfig config) async {
    _byVenue[venueId] = config;
  }
}
