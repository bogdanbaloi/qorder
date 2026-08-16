import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/domain/models/menu.dart';

void main() {
  // REQ-MENU-001: the shipped menu asset parses into the model, every category
  // has items and every item has a positive price.
  test('assets/menu/demo.json parses into a Menu', () {
    final raw = File('assets/menu/demo.json').readAsStringSync();
    final menu = Menu.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(menu.categories, isNotEmpty);
    expect(menu.categories.every((c) => c.items.isNotEmpty), true);

    final items = menu.categories.expand((c) => c.items).toList();
    expect(items.length, greaterThan(100));
    expect(items.every((i) => i.basePrice.amountMinor > 0), true);
    // Search still works over the real data.
    expect(menu.filtered('ursus').categories, isNotEmpty);
  });
}
