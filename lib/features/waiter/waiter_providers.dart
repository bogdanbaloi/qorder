import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/acceptance/order_acceptance.dart';

/// Orders waiting for a waiter to confirm, on the configured venue. Refreshed
/// via `ref.invalidate` after each accept. Read-only view over the waiter-side
/// `OrderAcceptanceService`, so the surface stays dumb.
final waiterPendingProvider = FutureProvider.autoDispose<List<AwaitingOrder>>((
  ref,
) async {
  final service = ref.watch(orderAcceptanceServiceProvider);
  final cfg = ref.watch(appConfigProvider);
  return service.pending(cfg.venueId);
});
