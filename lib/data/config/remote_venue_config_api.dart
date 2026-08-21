import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_constants.dart';
import '../../core/config/app_config.dart';
import '../../domain/config/venue_config_api.dart';

const int _httpOk = 200;
const int _httpNotFound = 404;

/// Reads and writes a venue's config through the BFF (`/venues/:id/config`).
/// A fetch degrades open (a miss or an error returns null, so the caller keeps
/// its bundled asset). A save propagates its error, so the Settings screen can
/// tell the owner it did not persist (a wrong token gives a 403).
class RemoteVenueConfigApi implements VenueConfigApi {
  final String baseUrl;
  final http.Client client;

  /// The owner's bearer token, required for the write. Null when signed out.
  final String? authToken;

  RemoteVenueConfigApi({
    required this.baseUrl,
    required this.client,
    this.authToken,
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
      if (res.statusCode != _httpOk) return null;
      return AppConfig.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } on Object catch (_) {
      // A miss or an unreachable backend keeps the bundled asset default.
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
    if (res.statusCode != _httpOk) {
      throw Exception('save config failed: ${res.statusCode}');
    }
  }
}
