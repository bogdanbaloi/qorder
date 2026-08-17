import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../di/providers.dart';
import '../session/session_controller.dart';
import '../settings/language_controller.dart';
import 'account_providers.dart';

/// A compact points badge for the app bar, shown only to a loyal customer while
/// a program is active, so their standing is visible during ordering (not hidden
/// in the account screen). Tap opens the account. Nothing for a normal customer.
class LoyaltyChip extends ConsumerWidget {
  static const double _starSize = 18;
  const LoyaltyChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyal = ref.watch(sessionProvider.select((x) => x.isLoyalCustomer));
    final hasProgram = ref.watch(
      appConfigProvider.select((c) => c.loyaltyProgram.isActive),
    );
    if (!loyal || !hasProgram) return const SizedBox.shrink();

    final s = ref.watch(stringsProvider);
    final points = ref
        .watch(loyaltyStatusProvider)
        .maybeWhen(data: (data) => data.points, orElse: () => 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ActionChip(
        avatar: const Icon(Icons.star, size: _starSize),
        label: Text('$points'),
        tooltip: s.rewards,
        onPressed: () => context.push(Routes.account),
      ),
    );
  }
}
