import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../di/providers.dart';
import '../../domain/history/past_order.dart';
import '../../domain/loyalty/redemption.dart';
import '../session/session_controller.dart';
import '../settings/language_controller.dart';
import '../settings/app_bar_toggles.dart';
import '../table/customer_provider.dart';
import 'account_providers.dart';

/// Back to the menu (where a loyal customer picks a table and orders). Pops to
/// the menu it came from, or navigates there if opened directly.
void _goToMenu(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(Routes.menu);
  }
}

/// The customer's account / loyalty home: their name, loyalty status (enrol or
/// leave here, not as a nag in the ordering flow), and, for a loyal customer,
/// their order history. The proper home for the loyal features.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.text = ref.read(customerNameProvider);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final loyal = ref.watch(sessionProvider.select((x) => x.isLoyalCustomer));
    final hasProgram = ref.watch(
      appConfigProvider.select((c) => c.loyaltyProgram.isActive),
    );
    final name = ref.watch(customerNameProvider).trim();
    return Scaffold(
      appBar: AppBar(title: Text(s.account), actions: const [AppBarToggles()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (loyal && name.isNotEmpty) ...[
            Text(
              s.greeting(name),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
          ],
          if (loyal) ...[
            // A clear path back to ordering: the account is for points/history,
            // the menu is where a loyal customer picks a table and orders.
            FilledButton.icon(
              onPressed: () => _goToMenu(context),
              icon: const Icon(Icons.restaurant_menu),
              label: Text(s.seeMenu),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: s.nameOptionalLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => ref.read(customerNameProvider.notifier).set(v),
          ),
          const SizedBox(height: 16),
          _LoyaltyCard(loyal: loyal),
          if (loyal && hasProgram) ...[
            const SizedBox(height: 16),
            const _RewardsCard(),
            const _Redemptions(),
          ],
          if (loyal) ...[
            const SizedBox(height: 16),
            _SectionLabel(s.orderHistory),
            const _History(),
          ],
        ],
      ),
    );
  }
}

class _LoyaltyCard extends ConsumerWidget {
  final bool loyal;
  const _LoyaltyCard({required this.loyal});

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
            Row(
              children: [
                Icon(
                  Icons.loyalty,
                  color: loyal ? scheme.primary : scheme.outline,
                ),
                const SizedBox(width: 10),
                Text(
                  loyal ? s.loyalCustomer : s.becomeLoyal,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(s.loyalIntro),
            const SizedBox(height: 12),
            if (loyal)
              OutlinedButton(
                onPressed: () =>
                    ref.read(sessionProvider.notifier).signOut(),
                child: Text(s.signOutAccount),
              )
            else
              FilledButton.icon(
                onPressed: () => context.push(Routes.signIn),
                icon: const Icon(Icons.login),
                label: Text(s.signInWithPhone),
              ),
          ],
        ),
      ),
    );
  }
}

/// Points + reward-ladder progress for a loyal customer. Reads the derived
/// [loyaltyStatusProvider]; the earning rule lives in the Domain policy.
class _RewardsCard extends ConsumerWidget {
  static const double _barHeight = 8;
  const _RewardsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final tiers = ref.watch(
      appConfigProvider.select((c) => c.loyaltyProgram.tiers),
    );
    final status = ref.watch(loyaltyStatusProvider);
    return status.maybeWhen(
      data: (data) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(s.rewards, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                s.points(data.points),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(_barHeight),
                child: LinearProgressIndicator(
                  value: data.progress,
                  minHeight: _barHeight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.nextTier == null
                    ? s.allRewardsUnlocked
                    : s.pointsToNext(data.pointsToNext, data.nextTier!.reward),
              ),
              const SizedBox(height: 12),
              for (final tier in tiers)
                _TierRow(
                  reward: tier.reward,
                  threshold: tier.thresholdPoints,
                  unlocked: data.points >= tier.thresholdPoints,
                  onRedeem: data.points >= tier.thresholdPoints
                      ? () => _redeem(
                          context,
                          ref,
                          tier.reward,
                          tier.thresholdPoints,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
      orElse: SizedBox.shrink,
    );
  }

  /// Spend points on a reward, then show the customer the code to give the staff.
  /// A failure surfaces as a SnackBar; the points economy stays server-recorded.
  Future<void> _redeem(
    BuildContext context,
    WidgetRef ref,
    String reward,
    int cost,
  ) async {
    final s = ref.read(stringsProvider);
    final cfg = ref.read(appConfigProvider);
    final key = ref.read(loyaltyKeyProvider);
    try {
      final redemption = await ref
          .read(rewardRedeemerProvider)
          .redeem(cfg.venueId, key, reward: reward, cost: cost);
      ref.invalidate(redemptionsProvider);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(s.redeemCodeTitle),
          content: Text(
            redemption.code,
            textAlign: TextAlign.center,
            style: Theme.of(dialogContext).textTheme.headlineMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.gotIt),
            ),
          ],
        ),
      );
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.redeemFailed)));
    }
  }
}

class _TierRow extends ConsumerWidget {
  static const double _iconSize = 20;
  final String reward;
  final int threshold;
  final bool unlocked;

  /// Non-null when the reward is affordable now; tapping spends the points.
  final VoidCallback? onRedeem;
  const _TierRow({
    required this.reward,
    required this.threshold,
    required this.unlocked,
    this.onRedeem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outline,
            size: _iconSize,
            color: unlocked ? scheme.primary : scheme.outline,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(reward)),
          if (onRedeem != null)
            FilledButton(onPressed: onRedeem, child: Text(s.redeem))
          else
            Text(
              '$threshold ${s.pointsLabel}',
              style: TextStyle(color: scheme.outline),
            ),
        ],
      ),
    );
  }
}

/// The customer's redemptions: the pending ones show the code to give the staff,
/// the validated ones read as used. Hidden until there is at least one.
class _Redemptions extends ConsumerWidget {
  const _Redemptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final redemptions = ref
        .watch(redemptionsProvider)
        .maybeWhen(data: (list) => list, orElse: () => const <Redemption>[]);
    if (redemptions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _SectionLabel(s.myRedemptions),
        for (final redemption in redemptions)
          _RedemptionTile(redemption: redemption),
      ],
    );
  }
}

class _RedemptionTile extends ConsumerWidget {
  final Redemption redemption;
  const _RedemptionTile({required this.redemption});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final used = redemption.consumed;
    return Card(
      child: ListTile(
        leading: Icon(
          used ? Icons.check_circle : Icons.confirmation_number_outlined,
          color: used ? scheme.outline : scheme.primary,
        ),
        title: Text(redemption.reward),
        subtitle: Text(
          used ? s.redemptionUsed : '${s.redemptionPending} · ${redemption.code}',
        ),
      ),
    );
  }
}

class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final history = ref.watch(orderHistoryProvider);
    return history.when(
      data: (orders) => orders.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(s.noHistoryYet),
            )
          : Column(children: [for (final o in orders) _HistoryTile(order: o)]),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(s.noHistoryYet),
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  static const int _twoDigits = 2;
  final PastOrder order;
  const _HistoryTile({required this.order});

  /// Locale-neutral `yyyy-MM-dd` (matches the backend's daily-series format), so
  /// two orders on different days read differently. Blank when the stamp is
  /// missing, so the subtitle then falls back to the table alone.
  String _dayLabel() {
    if (order.submittedAtMs == 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(order.submittedAtMs);
    final month = d.month.toString().padLeft(_twoDigits, '0');
    final day = d.day.toString().padLeft(_twoDigits, '0');
    return '${d.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final table = s.tableAt(order.tableNumber);
    final date = _dayLabel();
    final subtitle = date.isEmpty ? table : '$table · $date';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long),
        title: Text(s.orderNumber(order.sequence)),
        subtitle: Text(subtitle),
        trailing: Text(
          order.total.format(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
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
