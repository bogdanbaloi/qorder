import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_controller.dart';
import '../waiter/waiter_providers.dart';
import 'owner_providers.dart';

const int _secondsPerMinute = 60;

/// The owner surface: a live operational snapshot (things waiting, in progress,
/// average acceptance and delivery times). Polls like the waiter surface so the
/// numbers stay current. Read-only. Owner-facing, so the text stays Romanian.
class OwnerDashboard extends ConsumerStatefulWidget {
  const OwnerDashboard({super.key});

  @override
  ConsumerState<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<OwnerDashboard> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) {
      ref.invalidate(waiterPendingProvider);
      ref.invalidate(waiterInProgressProvider);
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
    final metrics = ref.watch(venueMetricsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patron · sumar'),
        actions: [
          IconButton(
            tooltip: 'Ieși',
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MetricCard(
            label: 'De preluat',
            value: '${metrics.pending}',
            icon: Icons.hourglass_empty,
          ),
          _MetricCard(
            label: 'În lucru',
            value: '${metrics.inProgress}',
            icon: Icons.local_bar_outlined,
          ),
          _MetricCard(
            label: 'Cereri deschise',
            value: '${metrics.openRequests}',
            icon: Icons.room_service_outlined,
          ),
          _MetricCard(
            label: 'Timp mediu preluare',
            value: _formatDuration(metrics.avgAcceptance),
            icon: Icons.timer_outlined,
          ),
          _MetricCard(
            label: 'Timp mediu livrare la masă',
            value: _formatDuration(metrics.avgDelivery),
            icon: Icons.delivery_dining_outlined,
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration? d) {
  if (d == null) return '—';
  final seconds = d.inSeconds;
  if (seconds < _secondsPerMinute) return '${seconds}s';
  final minutes = seconds ~/ _secondsPerMinute;
  final rest = seconds % _secondsPerMinute;
  return rest == 0 ? '${minutes}m' : '${minutes}m ${rest}s';
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
