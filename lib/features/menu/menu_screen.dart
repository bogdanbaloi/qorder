import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../app/routes.dart';
import '../../di/providers.dart';
import '../../domain/models/menu.dart';
import '../../domain/pricing/menu_pricing.dart';
import '../../domain/pricing/promotion.dart';
import '../../domain/waiter/waiter_request.dart';
import '../cart/cart_controller.dart';
import '../order/order_status_banner.dart';
import '../settings/language_controller.dart';
import '../table/customer_provider.dart';
import '../table/table_controller.dart';
import 'category_icon.dart';
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
const double _categoryIconSize = 28;

class MenuScreen extends ConsumerStatefulWidget {
  final int? tableParam; // set when arriving via a /t/:table deep link
  const MenuScreen({super.key, this.tableParam});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _searchCtrl = TextEditingController();
  final _itemScrollController = ItemScrollController();
  String _query = '';

  /// Jump the list to a category by its index. Works even for categories far
  /// down a long menu that the lazy list has not built yet (unlike a GlobalKey).
  void _scrollToIndex(int index) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
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
    final s = ref.read(stringsProvider);
    final msg = kind == WaiterRequestKind.bill
        ? s.billOnTheWay
        : s.waiterNotified;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(menuProvider);
    final cart = ref.watch(cartProvider);
    final table = ref.watch(tableProvider);
    final s = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          table != null ? s.menuTitleForTable(table.number) : s.menuTitle,
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(languageProvider.notifier).toggle(),
            child: Text(
              language.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PopupMenuButton<WaiterRequestKind>(
            tooltip: s.callWaiter,
            icon: const Icon(Icons.room_service),
            enabled: table != null && table.validated,
            onSelected: _raiseRequest,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: WaiterRequestKind.callWaiter,
                child: Text(s.callWaiter),
              ),
              PopupMenuItem(
                value: WaiterRequestKind.bill,
                child: Text(s.bringBill),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: s.cart,
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
        AsyncData(:final value) => _buildMenu(value),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${s.couldNotLoadMenu}\n$error',
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
              label: Text(s.cartFab(cart.itemCount, cart.subtotal.format())),
            ),
    );
  }

  Widget _buildMenu(Menu menu) {
    final now = DateTime.now();
    final s = ref.watch(stringsProvider);
    final searching = _query.trim().isNotEmpty;
    final bands = ref.read(appConfigProvider).branding.alternatingCategoryBands;
    final categories = [...menu.filtered(_query).categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Flatten the menu into single, modestly sized rows (one header or one item
    // each). ScrollablePositionedList jumps to an index precisely only when the
    // rows are small, so a tall Column per category made the jumps land short.
    // Alternate categories carry an inverted band (dark text on primary) to
    // mirror the venue site.
    final rows = <_MenuRowData>[];
    final headerRowOf = <int>[]; // category index -> its header's row index
    for (var ci = 0; ci < categories.length; ci++) {
      final c = categories[ci];
      final available = c.availability?.isAvailableAt(now) ?? true;
      final inverted = bands && ci.isOdd;
      headerRowOf.add(rows.length);
      rows.add(_MenuRowData.header(c, available, inverted));
      for (final item in c.items) {
        rows.add(_MenuRowData.item(item, available, inverted));
      }
    }

    return Column(
      children: [
        const OrderStatusBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: s.searchHint,
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
                for (var i = 0; i < categories.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      label: Text(categories[i].name),
                      onPressed: () => _scrollToIndex(headerRowOf[i]),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: rows.isEmpty
              ? Center(child: Text(s.nothingFound))
              : ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemCount: rows.length + 1,
                  itemBuilder: (_, i) => _rowAt(rows, i, now, menu.promotions),
                ),
        ),
      ],
    );
  }

  /// The widget for flat row [i]: a category header, an item tile, or the bottom
  /// spacer past the end.
  Widget _rowAt(
    List<_MenuRowData> rows,
    int i,
    DateTime now,
    List<Promotion> promotions,
  ) {
    if (i >= rows.length) return const SizedBox(height: 80);
    final row = rows[i];
    final category = row.category;
    if (category != null) {
      return _CategoryHeader(
        category: category,
        now: now,
        inverted: row.inverted,
      );
    }
    return _ItemTile(
      item: row.item!,
      categoryAvailable: row.available,
      inverted: row.inverted,
      now: now,
      promotions: promotions,
    );
  }
}

/// One flattened menu row: a category header (when [category] is set) or an item
/// (when [item] is set). Flattening lets the list jump to a section precisely.
/// [inverted] selects the primary-coloured band (dark text) for that category.
@immutable
class _MenuRowData {
  final Category? category;
  final MenuItem? item;
  final bool available;
  final bool inverted;
  const _MenuRowData.header(this.category, this.available, this.inverted)
    : item = null;
  const _MenuRowData.item(this.item, this.available, this.inverted)
    : category = null;
}

/// A category header row: the name in the signature style, plus an availability
/// note when the category is outside its time window.
class _CategoryHeader extends ConsumerWidget {
  final Category category;
  final DateTime now;
  final bool inverted;
  const _CategoryHeader({
    required this.category,
    required this.now,
    required this.inverted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final fg = inverted ? scheme.surface : scheme.primary;
    final window = category.availability;
    final unavailable = window != null && !window.isAvailableAt(now);
    return ColoredBox(
      color: inverted ? scheme.primary : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          children: [
            SvgPicture.asset(
              categoryIconAsset(category),
              width: _categoryIconSize,
              height: _categoryIconSize,
              colorFilter: inverted
                  ? ColorFilter.mode(fg, BlendMode.srcIn)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: fg),
              ),
            ),
            if (unavailable)
              Text(
                s.unavailableNow,
                style: TextStyle(fontStyle: FontStyle.italic, color: fg),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemTile extends ConsumerWidget {
  final MenuItem item;
  final bool categoryAvailable;
  final bool inverted;
  final DateTime now;
  final List<Promotion> promotions;
  const _ItemTile({
    required this.item,
    required this.categoryAvailable,
    required this.inverted,
    required this.now,
    required this.promotions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final fg = inverted ? scheme.surface : scheme.primary;
    final available = categoryAvailable && item.isAvailableAt(now);
    final window = item.availability;
    final unavailableNow = window != null && !window.isAvailableAt(now);
    final availabilityNote = unavailableNow
        ? s.availableAt(window.hoursLabel)
        : null;
    final desc = item.description;
    final descStyle = inverted ? TextStyle(color: fg) : null;
    final noteStyle = TextStyle(
      fontStyle: FontStyle.italic,
      color: inverted ? fg : null,
    );
    final priced = priceItem(item, promotions, now);
    final showSubtitle =
        (desc != null && desc.isNotEmpty) ||
        item.tags.isNotEmpty ||
        availabilityNote != null ||
        priced.discounted;
    return ColoredBox(
      color: inverted ? scheme.primary : Colors.transparent,
      child: ListTile(
        leading: item.imageUrl == null ? null : _Thumb(url: item.imageUrl!),
        title: Text(
          item.name,
          style: TextStyle(color: fg, fontWeight: FontWeight.bold),
        ),
        subtitle: !showSubtitle
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (priced.discounted)
                    Text(
                      priced.promotion!.name,
                      style: TextStyle(
                        color: scheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (desc != null && desc.isNotEmpty)
                    Text(desc, style: descStyle),
                  if (availabilityNote != null)
                    Text(availabilityNote, style: noteStyle),
                  if (item.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: _badgeSpacing),
                      child: _TagBadges(tags: item.tags),
                    ),
                ],
              ),
        trailing: _PriceLabel(priced: priced, color: fg),
        enabled: available,
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) =>
              _ItemDetail(item: item, available: available, priced: priced),
        ),
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

/// The item price for a list row, with the base struck through and the reduced
/// price beneath it when a promotion (happy hour) applies.
class _PriceLabel extends StatelessWidget {
  final PricedItem priced;
  final Color color;
  const _PriceLabel({required this.priced, required this.color});

  @override
  Widget build(BuildContext context) {
    final boldColored = TextStyle(color: color, fontWeight: FontWeight.bold);
    if (!priced.discounted) {
      return Text(priced.effective.format(), style: boldColored);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          priced.base.format(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: color,
          ),
        ),
        Text(priced.effective.format(), style: boldColored),
      ],
    );
  }
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
  final PricedItem priced;
  const _ItemDetail({
    required this.item,
    required this.available,
    required this.priced,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final scheme = Theme.of(context).colorScheme;
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
          if (priced.discounted) ...[
            const SizedBox(height: 4),
            Text(
              priced.promotion!.name,
              style: TextStyle(
                color: scheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
              if (priced.discounted) ...[
                Text(
                  priced.base.format(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  priced.effective.format(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else
                Text(
                  priced.effective.format(),
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
                            content: Text(s.addedToCart(item.name)),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(s.addToCart),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
