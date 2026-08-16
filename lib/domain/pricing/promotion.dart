import 'package:flutter/foundation.dart';

import '../models/time_window.dart';
import 'discount.dart';

/// A time-boxed price promotion (e.g. Happy Hour 17:00-19:00, 20% off beers).
/// Data, not code: it comes from the menu payload, so a venue turns it on
/// without a rebuild. Depends only on primitives (categoryId, tags), NOT on
/// MenuItem, so it stays free of the menu model (no import cycle).
@immutable
class Promotion {
  final String id;
  final String name; // shown on the badge, e.g. "Happy Hour"
  final TimeWindow window;
  final Discount discount;
  final Set<String> categoryIds; // empty = any category
  final Set<String> tags; // empty = any tag

  const Promotion({
    required this.id,
    required this.name,
    required this.window,
    required this.discount,
    this.categoryIds = const {},
    this.tags = const {},
  });

  bool isActiveAt(DateTime now) => window.isAvailableAt(now);

  /// Whether this promotion covers an item with the given category and tags.
  /// Empty scope sets mean "any", so scopes narrow, they never exclude by
  /// omission.
  bool covers({required String categoryId, required List<String> tags}) =>
      (categoryIds.isEmpty || categoryIds.contains(categoryId)) &&
      (this.tags.isEmpty || tags.any(this.tags.contains));

  factory Promotion.fromJson(Map<String, dynamic> j) => Promotion(
    id: j['id'] as String,
    name: j['name'] as String,
    window: TimeWindow.fromJson(j['window'] as Map<String, dynamic>),
    discount: Discount.fromJson(j['discount'] as Map<String, dynamic>),
    categoryIds: ((j['categoryIds'] as List?) ?? const [])
        .map((e) => e as String)
        .toSet(),
    tags: ((j['tags'] as List?) ?? const []).map((e) => e as String).toSet(),
  );
}
