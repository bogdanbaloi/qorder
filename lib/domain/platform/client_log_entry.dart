import 'package:flutter/foundation.dart';

/// One client diagnostic the operator reads back: the level, the message and the
/// venue it came from. The read side of what the apps ship to `POST /logs`.
@immutable
class ClientLogEntry {
  final String level;
  final String message;
  final String? venueId;

  const ClientLogEntry({
    required this.level,
    required this.message,
    this.venueId,
  });

  factory ClientLogEntry.fromJson(Map<String, dynamic> json) => ClientLogEntry(
    level: json['level'] as String,
    message: json['message'] as String,
    venueId: json['venueId'] as String?,
  );
}
