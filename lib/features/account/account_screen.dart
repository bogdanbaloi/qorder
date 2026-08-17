import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/history/past_order.dart';
import '../session/session_controller.dart';
import '../settings/language_controller.dart';
import '../settings/language_toggle.dart';
import '../table/customer_provider.dart';
import 'account_providers.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(s.account), actions: const [LanguageToggle()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: s.nameOptionalLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => ref.read(customerNameProvider.notifier).set(v),
          ),
          const SizedBox(height: 16),
          _LoyaltyCard(name: _name, loyal: loyal),
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
  final TextEditingController name;
  final bool loyal;
  const _LoyaltyCard({required this.name, required this.loyal});

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
                    ref.read(sessionProvider.notifier).leaveLoyal(),
                child: Text(s.leaveLoyalty),
              )
            else
              FilledButton.icon(
                onPressed: () {
                  ref.read(customerNameProvider.notifier).set(name.text);
                  ref.read(sessionProvider.notifier).enrollLoyal();
                },
                icon: const Icon(Icons.loyalty),
                label: Text(s.loyalEnroll),
              ),
          ],
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
