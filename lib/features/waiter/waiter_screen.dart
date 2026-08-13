import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/acceptance/order_acceptance.dart';
import 'waiter_providers.dart';

/// The waiter surface: lists orders awaiting confirmation and accepts them. It
/// consumes only the waiter-side `OrderAcceptanceService` (via providers), never
/// the customer submit side, so the two roles stay decoupled.
///
/// Phase 0 auto-refreshes on a timer to pick up orders submitted in another tab
/// (the demo shares state via localStorage). Phase 1's BFF pushes instead of
/// polling. A manual refresh is also available.
class WaiterScreen extends ConsumerStatefulWidget {
  const WaiterScreen({super.key});

  @override
  ConsumerState<WaiterScreen> createState() => _WaiterScreenState();
}

class _WaiterScreenState extends ConsumerState<WaiterScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(
      const Duration(seconds: 2),
      (_) => ref.invalidate(waiterPendingProvider),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(waiterPendingProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ospătar · comenzi noi'),
        actions: [
          IconButton(
            tooltip: 'Reîmprospătează',
            onPressed: () => ref.invalidate(waiterPendingProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
