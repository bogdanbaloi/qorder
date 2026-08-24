import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';
import '../../core/config/app_config.dart';
import '../../domain/config/venue_config_api.dart';
import '../../domain/diagnostics/app_logger.dart';
import '../../domain/identity/session_expired.dart';

const int _httpOk = 200;
const int _httpNotFound = 404;
const int _httpUnauthorized = 401;
const int _httpForbidden = 403;

/// Reads and writes a venue's config through the BFF (`/venues/:id/config`).
/// A fetch degrades open (a miss or an error returns null, so the caller keeps
/// its bundled asset). A save propagates its error, so the Settings screen can
/// tell the owner it did not persist (a wrong token gives a 403).
class RemoteVenueConfigApi implements VenueConfigApi {
  final String baseUrl;
  final http.Client client;

  /// The owner's bearer token, required for the write. Null when signed out.
  final String? authToken;

  final AppLogger logger;

  RemoteVenueConfigApi({
    required this.baseUrl,
    required this.client,
    this.authToken,
    this.logger = const SilentLogger(),
  });

  Uri _configUri(String venueId) =>
      Uri.parse('$baseUrl/venues/$venueId/config');

  @override
  Future<AppConfig?> fetch(String venueId) async {
    try {
      final res = await client
          .get(_configUri(venueId))
          .timeout(AppConstants.submitTimeout);
      if (res.statusCode == _httpNotFound) return null;
      if (res.statusCode != _httpOk) {
        logger.warning(
          'venue config fetch: HTTP ${res.statusCode} for $venueId',
        );
        return null;
      }
      return AppConfig.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } on Object catch (e, s) {
      // A miss or an unreachable backend keeps the bundled asset default.
      logger.warning(
        'venue config fetch failed for $venueId',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  @override
  Future<void> save(String venueId, AppConfig config) async {
    final res = await client
        .put(
          _configUri(venueId),
          headers: {
            'content-type': 'application/json',
            if (authToken != null) 'authorization': 'Bearer $authToken',
          },
          body: jsonEncode(config.toJson()),
        )
        .timeout(AppConstants.submitTimeout);
    if (res.statusCode == _httpUnauthorized ||
        res.statusCode == _httpForbidden) {
      // The token is dead or wrong: the caller signs out and re-authenticates.
      throw const SessionExpiredException();
    }
    if (res.statusCode != _httpOk) {
      throw Exception('save config failed: ${res.statusCode}');
    }
  }
}
