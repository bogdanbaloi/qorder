import '../../core/config/app_config.dart';

/// The venue configuration PORT (Dependency Inversion). qorder is multi-tenant:
/// a running app resolves which venue it is (from the QR link) and loads that
/// venue's [AppConfig] through this seam. An in-memory / asset implementation
/// serves it now; a remote implementation (our backend) drops in behind the same
/// interface later, so the config becomes editable data with no app release. The
/// config is DATA, not code, and this is the read side of it (the owner Settings
/// screen is the write side of the same document).
abstract interface class VenueConfigSource {
  /// The configuration for [venueId], or null when the venue is unknown, so the
  /// caller can show a clear "unknown venue" path instead of guessing a default.
  AppConfig? configFor(String venueId);
}
