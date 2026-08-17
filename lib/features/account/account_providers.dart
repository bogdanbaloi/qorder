import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/history/past_order.dart';
import '../table/customer_provider.dart';

/// The signed-in customer's order history, from the backend (empty from the
/// in-app mock, which keeps no history). Keyed by the anonymous client id.
final orderHistoryProvider = FutureProvider.autoDispose<List<PastOrder>>((
  ref,
) async {
  final source = ref.watch(historySourceProvider);
  final cfg = ref.watch(appConfigProvider);
  final clientId = ref.watch(clientIdProvider);
  return source.orders(cfg.venueId, clientId);
});
