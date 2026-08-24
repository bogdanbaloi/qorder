import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/diagnostics/app_logger.dart';

/// The window and cap for shipping, so a runaway loop cannot flood the backend.
const Duration _throttleWindow = Duration(minutes: 1);
const int _maxPerWindow = 20;

/// A placeholder status for the swallowed-failure branch (never inspected).
const int _shipFailedStatus = 599;

/// Ships warning and error records to the BFF's `POST /logs`, so the operator
/// sees failures that happen on a patron's device (which never reach the server
/// otherwise). Debug and info are dropped. Shipping is fire-and-forget and its
/// own failure is swallowed, so a logging call never throws, blocks, or loops
/// back through this logger.
class RemoteLogger implements AppLogger {
  final String baseUrl;
  final http.Client client;

  /// The active venue, tagged on each record so the operator sees where a
  /// failure happened. Null before a venue is resolved.
  final String? venueId;

  RemoteLogger({required this.baseUrl, required this.client, this.venueId});

  int _sentInWindow = 0;
  DateTime? _windowStart;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < LogLevel.warning.index) return;
    if (!_allow()) return;
    final body = jsonEncode({
      'records': [
        {
          'level': level.name,
          'message': error == null ? message : '$message: $error',
          if (venueId != null) 'venueId': venueId,
        },
      ],
    });
    // Fire-and-forget: never await, never rethrow, never log our own failure.
    unawaited(
      client
          .post(
            Uri.parse('$baseUrl/logs'),
            headers: const {'content-type': 'application/json'},
            body: body,
          )
          .catchError((_) => http.Response('', _shipFailedStatus)),
    );
  }

  /// True while under the per-window cap, so a storm of errors cannot flood the
  /// network. The window resets once it elapses.
  bool _allow() {
    final now = DateTime.now();
    if (_windowStart == null ||
        now.difference(_windowStart!) > _throttleWindow) {
      _windowStart = now;
      _sentInWindow = 0;
    }
    if (_sentInWindow >= _maxPerWindow) return false;
    _sentInWindow++;
    return true;
  }
}
