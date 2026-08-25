import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings.dart';
import '../../di/providers.dart';
import '../../domain/platform/client_log_entry.dart';
import '../../domain/platform/platform_metrics.dart';
import '../settings/app_bar_toggles.dart';
import '../settings/language_controller.dart';
import '../settings/venue_palettes.dart';
import 'admin_palette_controller.dart';
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
        actions: const [AppBarToggles()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _PaletteSection(),
          const Divider(height: 32),
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

const double _paletteThumbWidth = 96;
const double _paletteThumbHeight = 48;
const double _paletteThumbRadius = 10;
const double _paletteThumbGap = 12;
const double _paletteRingWidth = 3;

/// The operator's venue-palette picker for the active venue. Tapping a palette
/// applies the whole thing (accent plus the dark and light pairs) and saves it,
/// so the venue brand is set here, not by the owner (ADR-0065).
class _PaletteSection extends ConsumerWidget {
  const _PaletteSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final branding = ref.watch(appConfigProvider).branding;
    final state = ref.watch(adminPaletteControllerProvider);
    final controller = ref.read(adminPaletteControllerProvider.notifier);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.paletteTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(s.paletteHint, style: TextStyle(color: muted)),
        const SizedBox(height: 12),
        Wrap(
          spacing: _paletteThumbGap,
          runSpacing: _paletteThumbGap,
          children: [
            for (final palette in venuePalettes)
              _PaletteThumb(
                palette: palette,
                selected: palette.matches(branding),
                onTap: state.saving ? null : () => controller.apply(palette),
              ),
          ],
        ),
        if (state.savedOk)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              s.settingsSaved,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        if (state.saveFailed)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              s.settingsSaveFailed,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}

/// One palette as a three-stripe swatch (dark base, accent, light base) with its
/// name, ringed when it is the venue's active palette.
class _PaletteThumb extends StatelessWidget {
  final VenuePalette palette;
  final bool selected;
  final VoidCallback? onTap;

  const _PaletteThumb({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(_paletteThumbRadius),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _paletteThumbWidth,
            height: _paletteThumbHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_paletteThumbRadius),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? _paletteRingWidth : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ColoredBox(color: Color(palette.darkBackground)),
                ),
                Expanded(child: ColoredBox(color: Color(palette.accent))),
                Expanded(
                  child: ColoredBox(color: Color(palette.lightBackground)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: _paletteThumbWidth,
            child: Text(
              palette.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
