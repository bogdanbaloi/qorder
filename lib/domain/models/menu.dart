import 'package:flutter/foundation.dart';

import '../../core/money.dart';
import '../pricing/promotion.dart';
import 'time_window.dart';

export 'time_window.dart';

@immutable
class OptionChoice {
  final String id;
  final String name;
  final Money priceDelta;

  const OptionChoice({
    required this.id,
    required this.name,
    required this.priceDelta,
  });

  factory OptionChoice.fromJson(Map<String, dynamic> j) => OptionChoice(
    id: j['id'] as String,
    name: j['name'] as String,
    priceDelta: Money((j['priceDeltaMinor'] as num?)?.toInt() ?? 0),
  );
}

@immutable
class OptionGroup {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<OptionChoice> choices;

  const OptionGroup({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.choices,
  });

  bool get isRequired => minSelect > 0;

  factory OptionGroup.fromJson(Map<String, dynamic> j) => OptionGroup(
    id: j['id'] as String,
    name: j['name'] as String,
    minSelect: (j['minSelect'] as num?)?.toInt() ?? 0,
    maxSelect: (j['maxSelect'] as num?)?.toInt() ?? 1,
    choices: (j['choices'] as List)
        .map((e) => OptionChoice.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

@immutable
class MenuItem {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final Money basePrice;
  final List<OptionGroup> options;
  final List<String> tags;
  final bool available;
  final String? imageUrl;
  final TimeWindow? availability; // time-of-day window, null = always

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.basePrice,
    this.description,
    this.options = const [],
    this.tags = const [],
    this.available = true,
    this.imageUrl,
    this.availability,
  });

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
    id: j['id'] as String,
    categoryId: j['categoryId'] as String,
    name: j['name'] as String,
    description: j['description'] as String?,
    basePrice: Money((j['basePriceMinor'] as num).toInt()),
    options:
        (j['options'] as List?)
            ?.map((e) => OptionGroup.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    tags: (j['tags'] as List?)?.map((e) => e as String).toList() ?? const [],
    available: j['available'] as bool? ?? true,
    imageUrl: j['imageUrl'] as String?,
    availability: j['availability'] == null
        ? null
        : TimeWindow.fromJson(j['availability'] as Map<String, dynamic>),
  );

  /// Whether the item can be ordered at [dt]: the manual flag AND its time
  /// window (if any). Pure, so the smart-hours behaviour is unit-tested.
  bool isAvailableAt(DateTime dt) =>
      available && (availability?.isAvailableAt(dt) ?? true);

  /// The options auto-selected when this item is added straight from the menu:
  /// the first choice of each required group (Phase 0 has no options sheet).
  /// This is a domain rule, so it lives on the model, not in a widget.
  List<OptionChoice> defaultSelectedOptions() => [
    for (final g in options)
      if (g.isRequired && g.choices.isNotEmpty) g.choices.first,
  ];

  /// Whether this item matches a lower-cased search query (name, description or
  /// a tag). Pure, so the menu filter is unit-tested.
  bool matches(String lowerQuery) =>
      name.toLowerCase().contains(lowerQuery) ||
      (description?.toLowerCase().contains(lowerQuery) ?? false) ||
      tags.any((t) => t.toLowerCase().contains(lowerQuery));
}

@immutable
class Category {
  final String id;
  final String name;
  final int sortOrder;
  final TimeWindow? availability;
  final List<MenuItem> items;
  final String? icon; // optional drink-type icon key (null = derived by name)

  const Category({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.items,
    this.availability,
    this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] as String,
    name: j['name'] as String,
    sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
    availability: j['availability'] == null
        ? null
        : TimeWindow.fromJson(j['availability'] as Map<String, dynamic>),
    items: (j['items'] as List)
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    icon: j['icon'] as String?,
  );
}

@immutable
class Menu {
  final String venueId;
  final int version;
  final List<Category> categories;
  final List<Promotion> promotions; // time-boxed price promotions (happy hour)

  const Menu({
    required this.venueId,
    required this.version,
    required this.categories,
    this.promotions = const [],
  });

  factory Menu.fromJson(Map<String, dynamic> j) => Menu(
    venueId: j['venueId'] as String,
    version: (j['version'] as num?)?.toInt() ?? 1,
    categories: (j['categories'] as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList(),
    promotions: ((j['promotions'] as List?) ?? const [])
        .map((e) => Promotion.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  /// A menu with only items matching [query] (case-insensitive), dropping any
  /// category left empty. A category whose NAME matches is kept whole (so a
  /// search for "vin" returns every wine, not only items with "vin" in the name).
  /// A blank query returns this menu unchanged. Pure, so it is unit-tested
  /// independently of the UI.
  Menu filtered(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return this;
    final cats = <Category>[
      for (final c in categories)
        if (c.name.toLowerCase().contains(q))
          c
        else if (c.items.any((i) => i.matches(q)))
          Category(
            id: c.id,
            name: c.name,
            sortOrder: c.sortOrder,
            availability: c.availability,
            icon: c.icon,
            items: c.items.where((i) => i.matches(q)).toList(),
          ),
    ];
    return Menu(
      venueId: venueId,
      version: version,
      categories: cats,
      promotions: promotions,
    );
  }
}
