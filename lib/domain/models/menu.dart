import 'package:flutter/foundation.dart';

import '../../core/money.dart';

/// A time window during which a category is available (e.g. Morning Deal
/// Mon-Fri 09:00-16:00). Days are 1=Mon..7=Sun. Minutes are from midnight.
@immutable
class TimeWindow {
  final List<int> daysOfWeek;
  final int startMinutes;
  final int endMinutes;

  const TimeWindow({
    required this.daysOfWeek,
    required this.startMinutes,
    required this.endMinutes,
  });

  bool isAvailableAt(DateTime dt) {
    if (!daysOfWeek.contains(dt.weekday)) return false;
    final m = dt.hour * 60 + dt.minute;
    return m >= startMinutes && m <= endMinutes;
  }

  factory TimeWindow.fromJson(Map<String, dynamic> j) => TimeWindow(
    daysOfWeek: (j['daysOfWeek'] as List)
        .map((e) => (e as num).toInt())
        .toList(),
    startMinutes: (j['startMinutes'] as num).toInt(),
    endMinutes: (j['endMinutes'] as num).toInt(),
  );
}

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

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.basePrice,
    this.description,
    this.options = const [],
    this.tags = const [],
    this.available = true,
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
  );

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

  const Category({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.items,
    this.availability,
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
  );
}

@immutable
class Menu {
  final String venueId;
  final int version;
  final List<Category> categories;

  const Menu({
    required this.venueId,
    required this.version,
    required this.categories,
  });

  factory Menu.fromJson(Map<String, dynamic> j) => Menu(
    venueId: j['venueId'] as String,
    version: (j['version'] as num?)?.toInt() ?? 1,
    categories: (j['categories'] as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  /// A menu with only items matching [query] (case-insensitive), dropping any
  /// category left empty. A blank query returns this menu unchanged. Pure, so
  /// it is unit-tested independently of the UI.
  Menu filtered(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return this;
    final cats = <Category>[
      for (final c in categories)
        if (c.items.any((i) => i.matches(q)))
          Category(
            id: c.id,
            name: c.name,
            sortOrder: c.sortOrder,
            availability: c.availability,
            items: c.items.where((i) => i.matches(q)).toList(),
          ),
    ];
    return Menu(venueId: venueId, version: version, categories: cats);
  }
}
