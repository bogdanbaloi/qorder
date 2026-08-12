import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/order.dart';
import '../../domain/models/table_ref.dart';
import '../order/order_controller.dart';
import '../table/table_controller.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _tableCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = ref.read(tableProvider);
    if (t != null) _tableCtrl.text = t.number.toString();
  }

  @override
  void dispose() {
    _tableCtrl.dispose();
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
            child: cart.isEmpty
                ? const Center(child: Text('Coșul e gol'))
                : ListView(
                    children: [
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
                  ref.read(orderControllerProvider.notifier).submit(),
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
