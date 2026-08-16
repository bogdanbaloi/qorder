import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/i18n/app_strings.dart';
import '../../di/providers.dart';
import '../../domain/models/cart.dart';
import '../../domain/models/order.dart';
import '../../domain/models/table_ref.dart';
import '../order/order_controller.dart';
import '../order/order_tracker.dart';
import '../settings/language_controller.dart';
import '../table/customer_provider.dart';
import '../table/table_controller.dart';
import '../table/table_orders_provider.dart';
import 'cart_controller.dart';

const double _priceColumnWidth = 72;

String _tableHelperText(AppStrings s, TableRef? table) {
  if (table == null || !table.validated) return s.tableEnterToSend;
  final source = table.source == TableSource.qr
      ? s.tableSourceQr
      : s.tableSourceManual;
  return s.tableKnownHelper(table.number, source);
}

String? _tableErrorText(AppStrings s, bool touched, TableRef? table) {
  if (touched && (table == null || !table.validated)) return s.tableInvalid;
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
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.orderTitle)),
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
    final s = ref.watch(stringsProvider);
    return ListView(
      children: [
        if (cart.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text(s.cartEmpty)),
          )
        else
          for (final line in cart.lines) _CartLineTile(line: line),
        const _MyOrders(),
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
    final s = ref.watch(stringsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: showForm
          ? const _OrderForm()
          : FilledButton.icon(
              onPressed: () => _goToMenu(context),
              icon: const Icon(Icons.restaurant_menu),
              label: Text(s.seeMenu),
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
    final s = ref.watch(stringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!cart.isEmpty) ...[
          Row(
            children: [
              Text(
                s.total,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                  ? s.nameRequiredLabel
                  : s.nameOptionalLabel,
              helperText: s.nameHelper,
              border: const OutlineInputBorder(),
              errorText: requireName && name.trim().isEmpty
                  ? s.nameRequiredError
                  : null,
            ),
            onChanged: (v) => ref.read(customerNameProvider.notifier).set(v),
          ),
          const SizedBox(height: 12),
          if (table != null && table.source == TableSource.qr)
            InputDecorator(
              decoration: InputDecoration(
                labelText: s.tableLabel,
                helperText: s.tableFromQrHelper,
                border: const OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    s.tableAt(table.number),
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
                labelText: s.tableNumberLabel,
                helperText: _tableHelperText(s, table),
                border: const OutlineInputBorder(),
                errorText: _tableErrorText(s, _tableTouched, table),
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
/// the customer's own entries highlighted. Polls so an order from another phone
/// on the same table shows up live (mirrors the waiter surface). Phase 1's BFF
/// will push instead of polling.
class _TableView extends ConsumerStatefulWidget {
  const _TableView();

  @override
  ConsumerState<_TableView> createState() => _TableViewState();
}

class _TableViewState extends ConsumerState<_TableView> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(
      const Duration(seconds: 2),
      (_) => ref.invalidate(tableOrdersProvider),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // .value keeps the last list visible during a refresh, so the view does
    // not flicker each poll.
    final data = ref.watch(tableOrdersProvider).value;
    if (data == null || data.entries.isEmpty) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;
    final s = ref.watch(stringsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.onTable(data.tableNumber),
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
                      text: '${e.name}${e.isMine ? ' ${s.you}' : ''}: ',
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

/// The customer's own orders, each with its live status, so they can follow
/// every order they placed and not only the last one.
class _MyOrders extends ConsumerWidget {
  const _MyOrders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderTrackerProvider);
    if (orders.isEmpty) return const SizedBox.shrink();
    final s = ref.watch(stringsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.myOrders, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          for (final order in orders)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.orderNumber(order.sequence),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _StatusSteps(stage: order.stage),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

const double _stepLabelSize = 11;

(String, IconData) _stepLabel(AppStrings s, OrderStage stage) =>
    switch (stage) {
      OrderStage.pendingAcceptance => (s.stepWaiting, Icons.hourglass_empty),
      OrderStage.received => (s.stepAccepted, Icons.thumb_up_alt_outlined),
      OrderStage.preparing => (s.stepPreparing, Icons.local_bar_outlined),
      OrderStage.done => (s.stepReady, Icons.check_circle_outline),
    };

/// The order's lifecycle as compact visual steps: finished ones are checked, the
/// current one is highlighted, so the customer sees progress at a glance.
class _StatusSteps extends ConsumerWidget {
  final OrderStage? stage;
  const _StatusSteps({required this.stage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final current = orderStepIndex(stage);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < orderStepStages.length; i++)
          Expanded(
            child: Column(
              children: [
                Icon(
                  i < current
                      ? Icons.check_circle
                      : _stepLabel(s, orderStepStages[i]).$2,
                  color: i <= current ? scheme.primary : scheme.outlineVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  _stepLabel(s, orderStepStages[i]).$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _stepLabelSize,
                    fontWeight: i == current
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: i <= current ? null : scheme.outline,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Asks the customer to confirm the order (table, items, total) before it is
/// sent, so an accidental tap never fires an order. Submits only on confirm.
Future<void> _confirmSubmit(BuildContext context, WidgetRef ref) async {
  final cart = ref.read(cartProvider);
  final table = ref.read(tableProvider);
  final name = ref.read(customerNameProvider).trim();
  final s = ref.read(stringsProvider);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.confirmSubmitTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (table != null)
            Text(
              s.tableAt(table.number),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (name.isNotEmpty) Text(name),
          const SizedBox(height: 8),
          for (final line in cart.lines)
            Text('${line.qty}x ${line.nameSnapshot}'),
          const Divider(),
          Text(
            s.totalLine(cart.subtotal.format()),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(s.back),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(s.send),
        ),
      ],
    ),
  );
  if (confirmed ?? false) {
    await ref.read(orderControllerProvider.notifier).submit();
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
    final s = ref.watch(stringsProvider);
    switch (order.phase) {
      case SubmitPhase.submitting:
        return FilledButton(onPressed: null, child: Text(s.sending));
      case SubmitPhase.confirmed:
        // The placed order and its live status now show in the "my orders"
        // section above; here we only offer to place another.
        return OutlinedButton(
          onPressed: () {
            notifier.reset();
            _goToMenu(context);
          },
          child: Text(s.newOrder),
        );
      case SubmitPhase.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.couldNotSend(order.failureReason ?? ''),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: notifier.resumePending,
              child: Text(s.retry),
            ),
          ],
        );
      case SubmitPhase.idle:
        return FilledButton(
          onPressed: canSubmit ? () => _confirmSubmit(context, ref) : null,
          child: Text(s.submitOrder),
        );
    }
  }
}
