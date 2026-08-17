import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings.dart';
import '../../domain/metrics/metrics_insights.dart';
import '../../domain/metrics/sales_metrics.dart';
import '../session/session_controller.dart';
import '../settings/language_controller.dart';
import '../settings/language_toggle.dart';
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
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.ownerTitle),
        actions: [
          const LanguageToggle(),
          IconButton(
            tooltip: s.logout,
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel(s.today),
          ...sales.when(
            data: (m) => _todaySection(m, s),
            loading: () => const [
              Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
            ],
            error: (_, _) => [ListTile(title: Text(s.statsUnavailable))],
          ),
          const SizedBox(height: 8),
          _SectionLabel(s.now),
          _MetricCard(
            label: s.toAccept,
            value: '${live.pending}',
            icon: Icons.hourglass_empty,
          ),
          _MetricCard(
            label: s.sectionInProgress,
            value: '${live.inProgress}',
            icon: Icons.local_bar_outlined,
          ),
          _MetricCard(
            label: s.openRequestsLabel,
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

/// The "Azi" cards + charts, built from the sales metrics. Kept a small builder
/// so `build` stays short; the day comparison is derived once.
List<Widget> _todaySection(SalesMetrics m, AppStrings s) {
  final comparison = dayOverDay(m.history);
  return [
    _MetricCard(
      label: s.ordersToday,
      value: '${m.ordersToday}',
      icon: Icons.receipt_long,
    ),
    _MetricCard(
      label: s.revenueToday,
      value: m.revenueToday.format(),
      icon: Icons.payments_outlined,
    ),
    _MetricCard(
      label: s.avgOrderValue,
      value: averageOrderValue(m).format(),
      icon: Icons.sell_outlined,
    ),
    _MetricCard(
      label: s.avgAcceptanceLabel,
      value: _formatDuration(m.avgAcceptance),
      icon: Icons.timer_outlined,
    ),
    _MetricCard(
      label: s.avgDeliveryLabel,
      value: _formatDuration(m.avgDelivery),
      icon: Icons.delivery_dining_outlined,
    ),
    if (comparison != null)
      _DayComparisonCard(comparison: comparison, label: s.vsPreviousDay),
    if (m.history.isNotEmpty)
      _BarChart(title: s.revenuePerDay, bars: _dailyBars(m.history)),
    if (m.hourly.isNotEmpty)
      _BarChart(title: s.salesByHour, bars: _hourlyBars(m.hourly)),
    if (m.topProducts.isNotEmpty)
      _TopProducts(products: m.topProducts, title: s.topProducts),
  ];
}

/// A signed integer for a delta, e.g. `+2` / `-1` / `0`.
String _signed(int n) => n >= 0 ? '+$n' : '$n';

/// A signed whole-percent for a ratio, e.g. `+15%` / `-8%`.
String _signedPercent(double ratio) {
  final percent = (ratio * 100).round();
  return percent >= 0 ? '+$percent%' : '$percent%';
}

List<_Bar> _dailyBars(List<DailyMetric> history) {
  final days = history.length > _maxChartDays
      ? history.sublist(history.length - _maxChartDays)
      : history;
  return [for (final d in days) _Bar(_dayLabel(d.date), d.revenue.amountMinor)];
}

List<_Bar> _hourlyBars(List<HourlyMetric> hourly) => [
  for (final h in hourly) _Bar('${h.hour}', h.revenue.amountMinor),
];

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

/// One column of a [_BarChart]: an x-axis [label] and a [value] (in bani for
/// revenue). Bar height is proportional to the tallest bar in the chart.
@immutable
class _Bar {
  final String label;
  final int value;
  const _Bar(this.label, this.value);
}

/// A hand-drawn bar chart (no chart library), reused for daily revenue and the
/// hourly breakdown. Bar heights are proportional to the tallest bar.
class _BarChart extends StatelessWidget {
  static const double _barGap = 3;
  static const double _barRadius = 3;
  static const int _minMax = 1; // avoids divide-by-zero on an all-zero chart
  final List<_Bar> bars;
  final String title;
  const _BarChart({required this.bars, required this.title});

  @override
  Widget build(BuildContext context) {
    final maxValue = bars
        .map((b) => b.value)
        .fold<int>(_minMax, (m, v) => v > m ? v : m);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: _chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bar in bars)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _barGap,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: _chartHeight * bar.value / maxValue,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(_barRadius),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bar.label,
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

/// The most-recent-day movement: revenue delta (with a percent when available)
/// and the orders delta, coloured up/down.
class _DayComparisonCard extends ConsumerWidget {
  final DayComparison comparison;
  final String label;
  const _DayComparisonCard({required this.comparison, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final up = comparison.revenueDelta.amountMinor >= 0;
    final ratio = comparison.revenueRatio;
    final percent = ratio == null ? '' : ' (${_signedPercent(ratio)})';
    return Card(
      child: ListTile(
        leading: Icon(
          up ? Icons.trending_up : Icons.trending_down,
          color: up ? scheme.primary : scheme.error,
        ),
        title: Text(label),
        subtitle: Text('${_signed(comparison.ordersDelta)} ${s.ordersWord}'),
        trailing: Text(
          '${comparison.revenueDelta.format()}$percent',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: up ? scheme.primary : scheme.error,
          ),
        ),
      ),
    );
  }
}

/// The best-selling products by units sold.
class _TopProducts extends ConsumerWidget {
  final List<ProductCount> products;
  final String title;
  const _TopProducts({required this.products, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final p in products)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(p.name)),
                    Text(
                      s.units(p.qty),
                      style: TextStyle(color: scheme.outline),
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
