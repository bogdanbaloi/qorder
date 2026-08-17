import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/acceptance/order_acceptance.dart';
import '../../domain/loyalty/redemption.dart';
import '../../domain/timing/order_progress.dart';
import '../../domain/waiter/waiter_request.dart';
import '../session/session_controller.dart';
import '../settings/language_controller.dart';
import '../settings/language_toggle.dart';
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
    _poll = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.invalidate(waiterPendingProvider);
      ref.invalidate(waiterRequestsProvider);
      ref.invalidate(waiterInProgressProvider);
      ref.invalidate(pendingRedemptionsProvider);
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
    final inProgress = ref.watch(waiterInProgressProvider).value ?? const [];
    final redemptions = ref.watch(pendingRedemptionsProvider).value ?? const [];
    final empty =
        pending.isEmpty &&
        requests.isEmpty &&
        inProgress.isEmpty &&
        redemptions.isEmpty;
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.waiterTitle),
        actions: [
          const LanguageToggle(),
          IconButton(
            tooltip: s.refresh,
            onPressed: () {
              ref.invalidate(waiterPendingProvider);
              ref.invalidate(waiterRequestsProvider);
              ref.invalidate(pendingRedemptionsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: s.logout,
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: empty
          ? Center(child: Text(s.nothingWaiting))
          : ListView(
              children: [
                if (requests.isNotEmpty) ...[
                  _SectionHeader(s.sectionRequests, requests.length),
                  for (final r in requests) _RequestTile(request: r),
                ],
                if (redemptions.isNotEmpty) ...[
                  _SectionHeader(s.rewardsToValidate, redemptions.length),
                  for (final r in redemptions)
                    _RedemptionValidateTile(redemption: r),
                ],
                if (pending.isNotEmpty) ...[
                  _SectionHeader(s.sectionNewOrders, pending.length),
                  for (final o in pending) _AwaitingTile(order: o),
                ],
                if (inProgress.isNotEmpty) ...[
                  _SectionHeader(s.sectionInProgress, inProgress.length),
                  for (final o in inProgress) _ProgressTile(order: o),
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
    final s = ref.watch(stringsProvider);
    final name = order.customerName?.trim();
    final who = (name == null || name.isEmpty) ? s.customerFallback : name;
    final waited = _waitedSince(order.createdAtMs);
    return ListTile(
      title: Text(
        '${s.tableAt(order.tableNumber)} · ${s.orderNumber(order.sequence)}',
      ),
      subtitle: Text(waited == null ? who : '$who · ${s.waitedFor(waited)}'),
      trailing: FilledButton(
        onPressed: () async {
          final service = ref.read(orderAcceptanceServiceProvider);
          await service.accept(order.serverOrderId);
          ref.invalidate(waiterPendingProvider);
        },
        child: Text(s.confirmOrder),
      ),
    );
  }
}

/// A section label with the count, so the waiter sees the load at a glance.
class _SectionHeader extends ConsumerWidget {
  final String label;
  final int count;
  const _SectionHeader(this.label, this.count);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        s.sectionCount(label, count),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

/// The raw waited duration ("12s"), or null when the time is unknown
/// (createdAtMs == 0). The caller wraps it with the localized "waited for" text.
String? _waitedSince(int createdAtMs) {
  if (createdAtMs == 0) return null;
  final ms = DateTime.now().millisecondsSinceEpoch - createdAtMs;
  return _fmtDuration(Duration(milliseconds: ms));
}

/// One table-to-waiter request, with the resolve action.
class _RequestTile extends ConsumerWidget {
  final WaiterRequest request;
  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isBill = request.kind == WaiterRequestKind.bill;
    final name = request.customerName?.trim();
    final who = (name == null || name.isEmpty) ? '' : ' · $name';
    final label = isBill ? s.bringBill : s.callWaiter;
    final waited = _waitedSince(request.createdAtMs);
    return ListTile(
      leading: Icon(isBill ? Icons.receipt_long : Icons.room_service),
      title: Text('${s.tableAt(request.tableNumber)}$who'),
      subtitle: Text(
        waited == null ? label : '$label · ${s.waitedFor(waited)}',
      ),
      trailing: OutlinedButton(
        onPressed: () async {
          await ref.read(waiterRequestBoardProvider).resolve(request.id);
          ref.invalidate(waiterRequestsProvider);
        },
        child: Text(s.resolve),
      ),
    );
  }
}

/// One reward redemption awaiting validation: shows the reward and the code the
/// customer presents; validating consumes it so the points stay spent.
class _RedemptionValidateTile extends ConsumerWidget {
  final Redemption redemption;
  const _RedemptionValidateTile({required this.redemption});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return ListTile(
      leading: const Icon(Icons.confirmation_number_outlined),
      title: Text(redemption.reward),
      subtitle: Text(redemption.code),
      trailing: FilledButton(
        onPressed: () async {
          await ref.read(redemptionBoardProvider).consume(redemption.code);
          ref.invalidate(pendingRedemptionsProvider);
        },
        child: Text(s.validate),
      ),
    );
  }
}

/// Format a duration compactly (seconds) for the waiter timings.
String _fmtDuration(Duration d) => '${d.inSeconds}s';

/// An accepted order being moved to the table: shows the acceptance time and,
/// once the drink is ready, how long it has been waiting, with Gata / Livrat.
class _ProgressTile extends ConsumerWidget {
  final ProgressOrder order;
  const _ProgressTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final board = ref.read(orderProgressProvider);
    final ready = order.stamps['ready'];
    final acceptance = order.timings.acceptance;
    final readyFor = ready == null
        ? null
        : Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - ready);
    final name = order.customerName?.trim();
    final who = (name == null || name.isEmpty) ? s.customerFallback : name;
    final parts = <String>[
      who,
      if (acceptance != null) s.acceptedIn(_fmtDuration(acceptance)),
      if (readyFor != null) s.readyFor(_fmtDuration(readyFor)),
    ];

    return ListTile(
      title: Text(
        '${s.tableAt(order.tableNumber)} · ${s.orderNumber(order.sequence)}',
      ),
      subtitle: Text(parts.join(' · ')),
      trailing: ready == null
          ? OutlinedButton(
              onPressed: () async {
                await board.markReady(order.serverOrderId);
                ref.invalidate(waiterInProgressProvider);
              },
              child: Text(s.markReady),
            )
          : FilledButton(
              onPressed: () async {
                await board.markDelivered(order.serverOrderId);
                ref.invalidate(waiterInProgressProvider);
              },
              child: Text(s.markDelivered),
            ),
    );
  }
}
