import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings.dart';
import '../../domain/platform/client_log_entry.dart';
import '../../domain/platform/platform_metrics.dart';
import '../settings/language_controller.dart';
import '../settings/language_toggle.dart';
import 'admin_providers.dart';

const double _chipAlpha = 0.15;
const double _chipRadius = 6;

/// The operator cockpit: enter the platform (operator) token and see cross-venue
/// usage (venues, orders, distinct users). Separate from the owner dashboard,
/// which is a single venue's view. This is our own evidence across every venue.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _token = TextEditingController();

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  void _load() =>
      ref.read(operatorTokenProvider.notifier).set(_token.text.trim());

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final metrics = ref.watch(platformMetricsProvider);
    final logs = ref.watch(operatorLogsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminTitle),
        actions: const [LanguageToggle()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _token,
                  obscureText: true,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    labelText: s.operatorTokenLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: _load, child: Text(s.loadMetrics)),
            ],
          ),
          const SizedBox(height: 16),
          metrics.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => _message(context, s.operatorLoadError),
            data: (m) => _table(context, s, m),
          ),
          const SizedBox(height: 24),
          Text(
            s.recentLogsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          logs.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => _message(context, s.operatorLoadError),
            data: (entries) => _logs(context, s, entries),
          ),
        ],
      ),
    );
  }

  Widget _logs(BuildContext context, AppStrings s, List<ClientLogEntry> logs) {
    if (logs.isEmpty) return _message(context, s.noRecentLogs);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (final entry in logs)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: ListTile(
                dense: true,
                leading: _levelChip(context, entry.level),
                title: Text(entry.message),
                subtitle: entry.venueId == null ? null : Text(entry.venueId!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _levelChip(BuildContext context, String level) {
    final scheme = Theme.of(context).colorScheme;
    final color = level == 'error' ? scheme.error : scheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _chipAlpha),
        borderRadius: BorderRadius.circular(_chipRadius),
      ),
      child: Text(
        level,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }

  Widget _table(BuildContext context, AppStrings s, PlatformMetrics metrics) {
    if (metrics.venues.isEmpty) return _message(context, s.noOperatorData);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.venueCountLabel(metrics.venueCount),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              _row(
                context,
                s.venueColumn,
                s.ordersColumn,
                s.usersColumn,
                header: true,
              ),
              for (final venue in metrics.venues)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  child: _row(
                    context,
                    venue.venueId,
                    '${venue.orders}',
                    '${venue.users}',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String venue,
    String orders,
    String users, {
    bool header = false,
  }) {
    // The venue name column is wider than the two numeric columns.
    const venueColumnFlex = 3;
    final style = header
        ? Theme.of(context).textTheme.labelMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: venueColumnFlex,
            child: Text(venue, style: style),
          ),
          Expanded(
            child: Text(orders, style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            child: Text(users, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _message(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}
