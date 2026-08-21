import 'package:flutter/foundation.dart';

/// Usage for one venue in the operator view: order count and distinct users.
@immutable
class VenueUsage {
  final String venueId;
  final int orders;
  final int users;

  const VenueUsage({
    required this.venueId,
    required this.orders,
    required this.users,
  });

  factory VenueUsage.fromJson(Map<String, dynamic> json) => VenueUsage(
    venueId: json['venueId'] as String,
    orders: (json['orders'] as num).toInt(),
    users: (json['users'] as num).toInt(),
  );
}

/// The cross-venue operator snapshot: active venues and their usage. The operator
/// plane (our own evidence), distinct from the per-venue owner dashboard.
@immutable
class PlatformMetrics {
  final int venueCount;
  final List<VenueUsage> venues;

  const PlatformMetrics({required this.venueCount, required this.venues});

  const PlatformMetrics.empty() : venueCount = 0, venues = const [];

  factory PlatformMetrics.fromJson(Map<String, dynamic> json) =>
      PlatformMetrics(
        venueCount: (json['venueCount'] as num).toInt(),
        venues: ((json['venues'] as List?) ?? const [])
            .map((e) => VenueUsage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
