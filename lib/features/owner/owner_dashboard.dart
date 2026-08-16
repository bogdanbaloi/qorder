import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/metrics/sales_metrics.dart';
import '../session/session_controller.dart';
import '../waiter/waiter_providers.dart';
import 'owner_providers.dart';

const int _secondsPerMinute = 60;
const double _chartHeight = 120;
const int _maxChartDays = 7;
const int _isoDayStart = 5; // index of "MM-DD" in a "YYYY-MM-DD" date

/// The owner surface: today's orders + revenue and the average acceptance and
/// delivery times (from the backend, which keeps past orders), a daily history
/// chart, and a live "now" snapshot. Polls so the numbers stay current.
/// Read-only, owner-facing, so the text stays Romanian.
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
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      ref.invalidate(waiterPendingProvider);
      ref.invalidate(waiterInProgressProvider);
      ref.invalidate(waiterRequestsProvider);
      ref.invalidate(salesMetricsProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(venueMetricsProvider);
    final sales = ref.watch(salesMetricsProvider);
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
          const _SectionLabel('Azi'),
          ...sales.when(
            data: (s) => [
              _MetricCard(
                label: 'Comenzi azi',
                value: '${s.ordersToday}',
                icon: Icons.receipt_long,
              ),
              _MetricCard(
                label: 'Încasări azi',
                value: s.revenueToday.format(),
                icon: Icons.payments_outlined,
              ),
              _MetricCard(
                label: 'Timp mediu preluare',
                value: _formatDuration(s.avgAcceptance),
                icon: Icons.timer_outlined,
              ),
              _MetricCard(
                label: 'Timp mediu livrare la masă',
                value: _formatDuration(s.avgDelivery),
                icon: Icons.delivery_dining_outlined,
              ),
              if (s.history.isNotEmpty) _DailyChart(history: s.history),
            ],
            loading: () => const [
              Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
            ],
            error: (_, _) => const [
              ListTile(title: Text('Statisticile nu sunt disponibile')),
            ],
          ),
          const SizedBox(height: 8),
          const _SectionLabel('Acum'),
          _MetricCard(
            label: 'De preluat',
            value: '${live.pending}',
            icon: Icons.hourglass_empty,
          ),
          _MetricCard(
            label: 'În lucru',
            value: '${live.inProgress}',
            icon: Icons.local_bar_outlined,
          ),
          _MetricCard(
            label: 'Cereri deschise',
            value: '${live.openRequests}',
            icon: Icons.room_service_outlined,
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
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

/// A hand-drawn bar chart of daily revenue (last [_maxChartDays] days), no chart
/// library. Bar heights are proportional to the busiest day.
class _DailyChart extends StatelessWidget {
  final List<DailyMetric> history;
  const _DailyChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final days = history.length > _maxChartDays
        ? history.sublist(history.length - _maxChartDays)
        : history;
    final maxRevenue = days
        .map((d) => d.revenue.amountMinor)
        .fold<int>(1, (m, v) => v > m ? v : m);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Încasări pe zi',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height:
                                  _chartHeight *
                                  d.revenue.amountMinor /
                                  maxRevenue,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dayLabel(d.date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _dayLabel(String date) =>
    date.length >= _isoDayStart ? date.substring(_isoDayStart) : date;
