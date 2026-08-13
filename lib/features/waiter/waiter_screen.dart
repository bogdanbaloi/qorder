import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/acceptance/order_acceptance.dart';
import 'waiter_providers.dart';

/// The waiter surface: lists orders awaiting confirmation and accepts them. It
/// consumes only the waiter-side `OrderAcceptanceService` (via providers), never
/// the customer submit side, so the two roles stay decoupled.
class WaiterScreen extends ConsumerWidget {
  const WaiterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(waiterPendingProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ospătar · comenzi noi')),
      body: switch (pending) {
        AsyncData(:final value) =>
          value.isEmpty
              ? const Center(child: Text('Nicio comandă în așteptare'))
              : ListView(
                  children: [for (final o in value) _AwaitingTile(order: o)],
                ),
        AsyncError(:final error) => Center(child: Text('Eroare: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// One order awaiting confirmation, with the accept action.
class _AwaitingTile extends ConsumerWidget {
  final AwaitingOrder order;
  const _AwaitingTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = order.customerName?.trim();
    final who = (name == null || name.isEmpty) ? 'Client' : name;
    return ListTile(
      title: Text('Masa ${order.tableNumber} · comanda #${order.sequence}'),
      subtitle: Text(who),
      trailing: FilledButton(
        onPressed: () async {
          final service = ref.read(orderAcceptanceServiceProvider);
          await service.accept(order.serverOrderId);
          ref.invalidate(waiterPendingProvider);
        },
        child: const Text('Confirmă'),
      ),
    );
  }
}
