import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
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
    final summary = orders
        .map((o) {
          final stage = o.stage;
          final label = stage == null ? '' : ' · ${orderStageLabel(s, stage)}';
          return '#${o.sequence}$label';
        })
        .join('    ');
    return Material(
      color: scheme.secondaryContainer,
      child: InkWell(
        onTap: () => context.push(Routes.cart),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: scheme.onSecondaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${s.myOrders}:  $summary',
                  style: TextStyle(color: scheme.onSecondaryContainer),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSecondaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
