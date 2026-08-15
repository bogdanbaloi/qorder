import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../di/providers.dart';
import '../../domain/models/menu.dart';
import '../../domain/waiter/waiter_request.dart';
import '../cart/cart_controller.dart';
import '../table/customer_provider.dart';
import '../table/table_controller.dart';
import 'menu_view_model.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final int? tableParam; // set when arriving via a /t/:table deep link
  const MenuScreen({super.key, this.tableParam});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  @override
  void initState() {
    super.initState();
    final t = widget.tableParam;
    if (t != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tableProvider.notifier).setFromQr(t);
      });
    }
  }

  /// Pings the waiter for the current table (call over / bring the bill). Needs
  /// a validated table, the app-bar action is disabled otherwise.
  Future<void> _raiseRequest(WaiterRequestKind kind) async {
    final table = ref.read(tableProvider);
    if (table == null || !table.validated) return;
    final cfg = ref.read(appConfigProvider);
    final name = ref.read(customerNameProvider).trim();
    await ref
        .read(waiterCallerProvider)
        .raise(
          venueId: cfg.venueId,
          tableNumber: table.number,
          kind: kind,
          customerName: name.isEmpty ? null : name,
        );
    if (!mounted) return;
    final msg = kind == WaiterRequestKind.bill
        ? 'Am cerut nota. Ospătarul vine.'
        : 'Ospătarul a fost anunțat.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(menuProvider);
    final cart = ref.watch(cartProvider);
    final table = ref.watch(tableProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(table != null ? 'Meniu · Masa ${table.number}' : 'Meniu'),
        actions: [
          PopupMenuButton<WaiterRequestKind>(
            tooltip: 'Cheamă ospătarul',
            icon: const Icon(Icons.room_service),
            enabled: table != null && table.validated,
            onSelected: _raiseRequest,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: WaiterRequestKind.callWaiter,
                child: Text('Cheamă ospătarul'),
              ),
              PopupMenuItem(
                value: WaiterRequestKind.bill,
                child: Text('Adu nota'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Coș',
              onPressed: () => context.push(Routes.cart),
              icon: Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_cart),
              ),
            ),
          ),
        ],
      ),
      body: switch (async) {
        AsyncData(:final value) => _MenuList(menu: value),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Nu am putut încărca meniul.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(Routes.cart),
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                'Coș (${cart.itemCount}) · ${cart.subtotal.format()}',
              ),
            ),
    );
  }
}

class _MenuList extends StatelessWidget {
  final Menu menu;
  const _MenuList({required this.menu});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final categories = [...menu.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ListView(
      children: [
        for (final c in categories) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    c.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (c.availability != null &&
                    !c.availability!.isAvailableAt(now))
                  const Text(
                    'indisponibil acum',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          for (final item in c.items)
            _ItemTile(
              item: item,
              available: c.availability?.isAvailableAt(now) ?? true,
            ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

class _ItemTile extends ConsumerWidget {
  final MenuItem item;
  final bool available;
  const _ItemTile({required this.item, required this.available});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(item.name),
      subtitle: item.description == null ? null : Text(item.description!),
      trailing: Text(item.basePrice.format()),
      enabled: available && item.available,
      onTap: () {
        ref.read(cartProvider.notifier).addMenuItem(item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} adăugat'),
            duration: const Duration(milliseconds: 700),
          ),
        );
      },
    );
  }
}
