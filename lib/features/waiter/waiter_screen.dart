import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/acceptance/order_acceptance.dart';
import '../../domain/waiter/waiter_request.dart';
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
    _poll = Timer.periodic(const Duration(seconds: 2), (_) {
      ref.invalidate(waiterPendingProvider);
      ref.invalidate(waiterRequestsProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Buzz + sound when the count of things needing the waiter grows (a new
    // order or request), so staff do not have to stare at the screen.
    ref.listen<int>(waiterAlertCountProvider, (prev, next) {
      if (prev != null && next > prev) {
        ref.read(alertSignalProvider).fire();
      }
    });
    // .value keeps the last lists visible during a refresh, so the surface does
    // not flicker each poll.
    final pending = ref.watch(waiterPendingProvider).value ?? const [];
    final requests = ref.watch(waiterRequestsProvider).value ?? const [];
    final empty = pending.isEmpty && requests.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ospătar · comenzi noi'),
        actions: [
          IconButton(
            tooltip: 'Reîmprospătează',
            onPressed: () {
              ref.invalidate(waiterPendingProvider);
              ref.invalidate(waiterRequestsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: empty
          ? const Center(child: Text('Nimic în așteptare'))
          : ListView(
              children: [
                if (requests.isNotEmpty) ...[
                  const _SectionHeader('Cereri'),
                  for (final r in requests) _RequestTile(request: r),
                ],
                if (pending.isNotEmpty) ...[
                  const _SectionHeader('Comenzi noi'),
                  for (final o in pending) _AwaitingTile(order: o),
                ],
              ],
            ),
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

/// A small section label between the request list and the order list.
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

/// One table-to-waiter request, with the resolve action.
class _RequestTile extends ConsumerWidget {
  final WaiterRequest request;
  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBill = request.kind == WaiterRequestKind.bill;
    final name = request.customerName?.trim();
    final who = (name == null || name.isEmpty) ? '' : ' · $name';
    return ListTile(
      leading: Icon(isBill ? Icons.receipt_long : Icons.room_service),
      title: Text('Masa ${request.tableNumber}$who'),
      subtitle: Text(isBill ? 'Cere nota' : 'Cheamă ospătarul'),
      trailing: OutlinedButton(
        onPressed: () async {
          await ref.read(waiterRequestBoardProvider).resolve(request.id);
          ref.invalidate(waiterRequestsProvider);
        },
        child: const Text('Rezolvă'),
      ),
    );
  }
}
