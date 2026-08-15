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

/// Height of the horizontal category jump-bar.
const double _categoryBarHeight = 44;
const double _thumbSize = 48;
const double _thumbRadius = 6;
const double _cornerRadius = 12;
const double _sheetImageHeight = 160;
const double _placeholderHeight = 120;
const double _placeholderIconSize = 40;
const double _badgeSpacing = 4;

class MenuScreen extends ConsumerStatefulWidget {
  final int? tableParam; // set when arriving via a /t/:table deep link
  const MenuScreen({super.key, this.tableParam});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  String _query = '';

  GlobalKey _keyFor(String categoryId) =>
      _categoryKeys.putIfAbsent(categoryId, GlobalKey.new);

  void _scrollToCategory(String categoryId) {
    final ctx = _keyFor(categoryId).currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
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
        AsyncData(:final value) => _buildMenu(context, value),
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

  Widget _buildMenu(BuildContext context, Menu menu) {
    final now = DateTime.now();
    final searching = _query.trim().isNotEmpty;
    final allCategories = [...menu.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final filtered = [...menu.filtered(_query).categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Caută în meniu',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searching
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        if (!searching)
          SizedBox(
            height: _categoryBarHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final c in allCategories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      label: Text(c.name),
                      onPressed: () => _scrollToCategory(c.id),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Nimic găsit'))
              : ListView(
                  controller: _scrollController,
                  children: [
                    for (final c in filtered) ...[
                      Padding(
                        key: _keyFor(c.id),
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
                ),
        ),
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
    final desc = item.description;
    final showSubtitle =
        (desc != null && desc.isNotEmpty) || item.tags.isNotEmpty;
    return ListTile(
      leading: item.imageUrl == null ? null : _Thumb(url: item.imageUrl!),
      title: Text(item.name),
      subtitle: !showSubtitle
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (desc != null && desc.isNotEmpty) Text(desc),
                if (item.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _TagBadges(tags: item.tags),
                  ),
              ],
            ),
      trailing: Text(item.basePrice.format()),
      enabled: available && item.available,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => _ItemDetail(item: item, available: available),
      ),
    );
  }
}

/// A small item thumbnail. Falls back to an icon if the image fails to load.
class _Thumb extends StatelessWidget {
  final String url;
  const _Thumb({required this.url});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(_thumbRadius),
    child: Image.network(
      url,
      width: _thumbSize,
      height: _thumbSize,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(Icons.restaurant),
    ),
  );
}

/// The item's tags rendered as small badges (dietary / marketing).
class _TagBadges extends StatelessWidget {
  final List<String> tags;
  const _TagBadges({required this.tags});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: _badgeSpacing,
    runSpacing: _badgeSpacing,
    children: [
      for (final t in tags)
        Chip(
          label: Text(t),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
    ],
  );
}

/// Placeholder shown when an item has no image (or it fails to load).
class _NoImage extends StatelessWidget {
  const _NoImage();

  @override
  Widget build(BuildContext context) => Container(
    height: _placeholderHeight,
    width: double.infinity,
    alignment: Alignment.center,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Icon(
      Icons.restaurant_menu,
      size: _placeholderIconSize,
      color: Theme.of(context).colorScheme.outline,
    ),
  );
}

/// The item detail sheet: photo, description, badges, price and an add button.
class _ItemDetail extends ConsumerWidget {
  final MenuItem item;
  final bool available;
  const _ItemDetail({required this.item, required this.available});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAdd = available && item.available;
    final desc = item.description;
    final url = item.imageUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_cornerRadius),
            child: url == null
                ? const _NoImage()
                : Image.network(
                    url,
                    height: _sheetImageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _NoImage(),
                  ),
          ),
          const SizedBox(height: 12),
          Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
          if (desc != null && desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc),
          ],
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            _TagBadges(tags: item.tags),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                item.basePrice.format(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: canAdd
                    ? () {
                        final messenger = ScaffoldMessenger.of(context);
                        ref.read(cartProvider.notifier).addMenuItem(item);
                        Navigator.of(context).pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('${item.name} adăugat'),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Adaugă în coș'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
