import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../di/providers.dart';
import '../../domain/models/cart.dart';
import '../../domain/models/order.dart';
import '../../domain/models/table_ref.dart';
import '../order/order_controller.dart';
import '../table/customer_provider.dart';
import '../table/table_controller.dart';
import '../table/table_orders_provider.dart';
import 'cart_controller.dart';

const double _priceColumnWidth = 72;

String _tableHelperText(TableRef? table) {
  if (table == null || !table.validated) {
    return 'Introdu numărul mesei ca să poți trimite';
  }
  final source = table.source == TableSource.qr ? 'din QR' : 'introdusă manual';
  return 'Masa ${table.number} · $source';
}

String? _tableErrorText(bool touched, TableRef? table) {
  if (touched && (table == null || !table.validated)) {
    return 'Număr de masă invalid';
  }
  return null;
}

void _goToMenu(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(Routes.menu);
  }
}

/// The cart page shell. It only composes the pieces (Single Responsibility).
/// Each piece below owns its own concern.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comanda')),
      body: const Column(
        children: [
          Expanded(child: _CartList()),
          Divider(height: 1),
          _CartBottom(),
        ],
      ),
    );
  }
}

/// The scrollable content: cart lines (or an empty note) + the shared table view.
class _CartList extends ConsumerWidget {
  const _CartList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return ListView(
      children: [
        if (cart.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Coșul e gol')),
          )
        else
          for (final line in cart.lines) _CartLineTile(line: line),
        const _TableView(),
      ],
    );
  }
}

/// Bottom bar: the order form when there are items (or an order in progress),
/// otherwise just a way back to the menu.
class _CartBottom extends ConsumerWidget {
  const _CartBottom();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartEmpty = ref.watch(cartProvider).isEmpty;
    final phase = ref.watch(orderControllerProvider).phase;
    final showForm = !cartEmpty || phase != SubmitPhase.idle;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: showForm
          ? const _OrderForm()
          : FilledButton.icon(
              onPressed: () => _goToMenu(context),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Vezi meniul'),
            ),
    );
  }
}

/// The order form: total, customer name, table number, submit/status. Owns its
/// own text controllers.
class _OrderForm extends ConsumerStatefulWidget {
  const _OrderForm();

  @override
  ConsumerState<_OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends ConsumerState<_OrderForm> {
  final _tableCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  /// True once the customer has typed in the table field, so the "invalid
  /// table" error only shows after they interacted (not on an empty pristine
  /// field). Explicit UI state, so we do not force a rebuild off the controller.
  bool _tableTouched = false;

  @override
  void initState() {
    super.initState();
    final t = ref.read(tableProvider);
    if (t != null) _tableCtrl.text = t.number.toString();
    _nameCtrl.text = ref.read(customerNameProvider);
    _tableTouched = _tableCtrl.text.trim().isNotEmpty;
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
    final requireName = ref.watch(appConfigProvider).requireCustomerName;
    final name = ref.watch(customerNameProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!cart.isEmpty) ...[
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
            decoration: InputDecoration(
              labelText: requireName
                  ? 'Numele tău (necesar)'
                  : 'Numele tău (opțional)',
              helperText: 'Apare pe masă, ca să se știe cine a comandat',
              border: const OutlineInputBorder(),
              errorText: requireName && name.trim().isEmpty
                  ? 'Scrie un nume ca să poți trimite'
                  : null,
            ),
            onChanged: (v) => ref.read(customerNameProvider.notifier).set(v),
          ),
          const SizedBox(height: 12),
          if (table != null && table.source == TableSource.qr)
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Masa',
                helperText: 'Din codul QR de pe masă, nu se poate schimba',
                border: OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Masa ${table.number}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            TextField(
              controller: _tableCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Numărul mesei',
                helperText: _tableHelperText(table),
                border: const OutlineInputBorder(),
                errorText: _tableErrorText(_tableTouched, table),
              ),
              onChanged: (v) {
                final n = int.tryParse(v.trim());
                if (n == null) {
                  ref.read(tableProvider.notifier).clear();
                } else {
                  ref.read(tableProvider.notifier).setManual(n);
                }
                setState(() => _tableTouched = v.trim().isNotEmpty);
              },
            ),
          const SizedBox(height: 12),
        ],
        _SubmitArea(order: order, canSubmit: canSubmit),
      ],
    );
  }
}

/// One cart line: name, unit price, quantity stepper, line total.
class _CartLineTile extends ConsumerWidget {
  final CartLine line;
  const _CartLineTile({required this.line});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);
    return ListTile(
      title: Text(line.nameSnapshot),
      subtitle: Text(line.unitWithOptions.format()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => cart.changeQty(line.id, line.qty - 1),
          ),
          Text('${line.qty}'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => cart.changeQty(line.id, line.qty + 1),
          ),
          SizedBox(
            width: _priceColumnWidth,
            child: Text(line.lineTotal.format(), textAlign: TextAlign.right),
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

/// The submit button, or the confirmation / retry once an order was sent.
class _SubmitArea extends ConsumerWidget {
  final OrderUiState order;
  final bool canSubmit;
  const _SubmitArea({required this.order, required this.canSubmit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(orderControllerProvider.notifier);
    switch (order.phase) {
      case SubmitPhase.submitting:
        return const FilledButton(
          onPressed: null,
          child: Text('Se trimite...'),
        );
      case SubmitPhase.confirmed:
        final stageText = switch (order.stage) {
          OrderStage.pendingAcceptance => 'Așteaptă confirmarea ospătarului',
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
              onPressed: () {
                notifier.reset();
                _goToMenu(context);
              },
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
              onPressed: notifier.resumePending,
              child: const Text('Reîncearcă'),
            ),
          ],
        );
      case SubmitPhase.idle:
        return FilledButton(
          onPressed: canSubmit ? notifier.submit : null,
          child: const Text('Trimite comanda'),
        );
    }
  }
}
