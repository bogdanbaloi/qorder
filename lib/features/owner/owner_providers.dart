import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/metrics/venue_metrics.dart';
import '../waiter/waiter_providers.dart';

/// The owner's live snapshot, derived from the same data the waiter surface
/// uses (pending orders, in-progress orders with timings, open requests). No new
/// backend endpoint: the dashboard is a read-only view over existing providers.
final venueMetricsProvider = Provider.autoDispose<VenueMetrics>((ref) {
  final pending = ref.watch(waiterPendingProvider).value ?? const [];
  final inProgress = ref.watch(waiterInProgressProvider).value ?? const [];
  final requests = ref.watch(waiterRequestsProvider).value ?? const [];
  return computeVenueMetrics(
    pending: pending.length,
    openRequests: requests.length,
    inProgressTimings: [for (final order in inProgress) order.timings],
  );
});
