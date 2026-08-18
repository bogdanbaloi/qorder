import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../domain/models/order.dart';
import '../settings/language_controller.dart';
import 'order_status_labels.dart';
import 'order_tracker.dart';

/// A slim, tappable banner shown on the menu while the customer has active
/// orders. It summarises each order's status ("#5 · În pregătire") so the
/// customer follows progress without leaving the menu, and tapping opens the
/// cart for the full per-order steppers.
class OrderStatusBanner extends ConsumerWidget {
  const OrderStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderTrackerProvider);
    if (orders.isEmpty) return const SizedBox.shrink();
    final s = ref.watch(stringsProvider);
    final scheme = Theme.of(context).colorScheme;
    // When an order is ready, the banner turns green so the payoff is obvious.
    final anyReady = orders.any(
      (o) => o.stage == OrderStage.done || o.stage == OrderStage.delivered,
    );
    final bg = anyReady ? Colors.green.shade700 : scheme.secondaryContainer;
    final fg = anyReady ? Colors.white : scheme.onSecondaryContainer;
    final leadingIcon = anyReady ? Icons.check_circle : Icons.receipt_long;
    final summary = orders
        .map((o) {
          final stage = o.stage;
          final label = stage == null ? '' : ' · ${orderStageLabel(s, stage)}';
          return '#${o.sequence}$label';
        })
        .join('    ');
    return Material(
      color: bg,
      child: InkWell(
        onTap: () => context.push(Routes.cart),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(leadingIcon, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${s.myOrders}:  $summary',
                  style: TextStyle(color: fg),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
