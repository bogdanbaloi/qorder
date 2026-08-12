import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/order.dart';
import '../../domain/models/table_ref.dart';
import '../order/order_controller.dart';
import '../table/customer_provider.dart';
import '../table/table_controller.dart';
import '../table/table_orders_provider.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _tableCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = ref.read(tableProvider);
    if (t != null) _tableCtrl.text = t.number.toString();
    _nameCtrl.text = ref.read(customerNameProvider);
  }

  @override
  void dispose() {
    _tableCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final table = ref.watch(tableProvider);
    final canSubmit = ref.watch(canSubmitProvider);
    final order = ref.watch(orderControllerProvider);
    final tableTouched = _tableCtrl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Comanda')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                if (cart.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Coșul e gol')),
                  )
                else
                  for (final line in cart.lines)
                    ListTile(
                      title: Text(line.nameSnapshot),
                      subtitle: Text(line.unitWithOptions.format()),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .changeQty(line.id, line.qty - 1),
                          ),
                          Text('${line.qty}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .changeQty(line.id, line.qty + 1),
                          ),
                          SizedBox(
                            width: 72,
                            child: Text(
                              line.lineTotal.format(),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                const _TableView(),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      cart.subtotal.format(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Numele tău (opțional)',
                    helperText: 'Apare pe masă, ca să se știe cine a comandat',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      ref.read(customerNameProvider.notifier).set(v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tableCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Numărul mesei',
                    helperText: table != null && table.validated
                        ? 'Masa ${table.number} · ${table.source == TableSource.qr ? 'din QR' : 'introdusă manual'}'
                        : 'Introdu numărul mesei ca să poți trimite',
                    border: const OutlineInputBorder(),
                    errorText:
                        tableTouched && (table == null || !table.validated)
                        ? 'Număr de masă invalid'
                        : null,
                  ),
                  onChanged: (v) {
                    final n = int.tryParse(v.trim());
                    if (n == null) {
                      ref.read(tableProvider.notifier).clear();
                    } else {
                      ref.read(tableProvider.notifier).setManual(n);
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                _SubmitArea(order: order, canSubmit: canSubmit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows everything ordered on the current table (all phones), names shown,
/// the customer's own entries highlighted.
class _TableView extends ConsumerWidget {
  const _TableView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = switch (ref.watch(tableOrdersProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (data == null || data.entries.isEmpty) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pe masa ${data.tableNumber}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          for (final e in data.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '${e.name}${e.isMine ? ' (tu)' : ''}: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: e.isMine ? primary : null,
                      ),
                    ),
                    TextSpan(
                      text: e.lines
                          .map((l) => '${l.qty}x ${l.name}')
                          .join(', '),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubmitArea extends ConsumerWidget {
  final OrderUiState order;
  final bool canSubmit;
  const _SubmitArea({required this.order, required this.canSubmit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (order.phase) {
      case SubmitPhase.submitting:
        return const FilledButton(
          onPressed: null,
          child: Text('Se trimite...'),
        );
      case SubmitPhase.confirmed:
        final stageText = switch (order.stage) {
          OrderStage.received => 'Preluată de bar',
          OrderStage.preparing => 'În pregătire',
          OrderStage.done => 'Gata',
          null => 'Trimisă',
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Comandă #${order.sequence} · $stageText',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  ref.read(orderControllerProvider.notifier).reset(),
              child: const Text('Comandă nouă'),
            ),
          ],
        );
      case SubmitPhase.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nu am putut trimite: ${order.failureReason ?? ''}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () =>
                  ref.read(orderControllerProvider.notifier).resumePending(),
              child: const Text('Reîncearcă'),
            ),
          ],
        );
      case SubmitPhase.idle:
        return FilledButton(
          onPressed: canSubmit
              ? () => ref.read(orderControllerProvider.notifier).submit()
              : null,
          child: const Text('Trimite comanda'),
        );
    }
  }
}
