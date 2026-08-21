import '../../core/config/app_config.dart';

/// The WRITE side of the venue config (the owner Settings screen), paired with
/// the read-only [VenueConfigSource]. Reads and writes a venue's saved config on
/// the backend, so an owner edit persists server-side and takes effect with no
/// app release.
abstract interface class VenueConfigApi {
  /// The venue's saved config, or null when none has been written yet (the
  /// caller then keeps its bundled asset default).
  Future<AppConfig?> fetch(String venueId);

  /// Persists [config] for [venueId]. Owner-authenticated on the backend.
  Future<void> save(String venueId, AppConfig config);
}
