import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/money.dart';
import 'package:qorder/domain/models/menu.dart';
import 'package:qorder/features/cart/cart_controller.dart';

// REQ-CART-001: cart math sums lines with options and quantity.
void main() {
  test('subtotal sums unit + option deltas times qty', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const beer = MenuItem(
      id: 'b',
      categoryId: 'x',
      name: 'Beer',
      basePrice: Money(1000),
      options: [
        OptionGroup(
          id: 's',
          name: 'size',
          minSelect: 1,
          maxSelect: 1,
          choices: [OptionChoice(id: 'l', name: '1L', priceDelta: Money(200))],
        ),
      ],
    );

    container
        .read(cartProvider.notifier)
        .addItem(
          beer,
          options: const [
            OptionChoice(id: 'l', name: '1L', priceDelta: Money(200)),
          ],
          qty: 2,
        );

    final cart = container.read(cartProvider);
    expect(cart.itemCount, 2);
    expect(cart.subtotal.amountMinor, 2400); // (1000 + 200) * 2
  });

  // The default-option rule lives on the domain model and is applied by
  // addMenuItem, so a menu tap needs no options logic in the widget.
  test('addMenuItem auto-selects the required option groups only', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const nachos = MenuItem(
      id: 'n',
      categoryId: 'x',
      name: 'Nachos',
      basePrice: Money(1500),
      options: [
        OptionGroup(
          id: 'sauce',
          name: 'Sauce',
          minSelect: 1,
          maxSelect: 1,
          choices: [
            OptionChoice(id: 'mild', name: 'Mild', priceDelta: Money(0)),
            OptionChoice(id: 'hot', name: 'Hot', priceDelta: Money(100)),
          ],
        ),
        OptionGroup(
          id: 'extra',
          name: 'Extra',
          minSelect: 0,
          maxSelect: 1,
          choices: [
            OptionChoice(id: 'cheese', name: 'Cheese', priceDelta: Money(300)),
          ],
        ),
      ],
    );

    // Domain rule: first choice of the required group, optional group skipped.
    expect(nachos.defaultSelectedOptions().map((o) => o.id).toList(), ['mild']);

    container.read(cartProvider.notifier).addMenuItem(nachos);
    final line = container.read(cartProvider).lines.single;
    expect(line.selectedOptions.map((o) => o.id).toList(), ['mild']);
    expect(line.unitWithOptions.amountMinor, 1500); // mild delta is 0
  });

  test('changeQty to zero removes the line', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const item = MenuItem(
      id: 'i',
      categoryId: 'c',
      name: 'Coffee',
      basePrice: Money(890),
    );

    container.read(cartProvider.notifier).addItem(item);
    final lineId = container.read(cartProvider).lines.first.id;
    container.read(cartProvider.notifier).changeQty(lineId, 0);

    expect(container.read(cartProvider).isEmpty, true);
  });
}
