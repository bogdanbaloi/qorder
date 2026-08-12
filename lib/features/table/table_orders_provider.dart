import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/models/table_orders.dart';
import 'customer_provider.dart';
import 'table_controller.dart';

/// Reads what is currently on the customer's table (all phones, one table).
/// Refreshed after each submit via `ref.invalidate`.
final tableOrdersProvider = FutureProvider.autoDispose<TableOrders?>((
  ref,
) async {
  final table = ref.watch(tableProvider);
  if (table == null || !table.validated) return null;
  final service = ref.watch(orderingServiceProvider);
  final cfg = ref.watch(appConfigProvider);
  final myId = ref.watch(clientIdProvider);
  return service.tableOrders(cfg.venueId, table.number, myClientId: myId);
});
