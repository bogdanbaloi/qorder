import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/storage/local_store.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/features/table/customer_provider.dart';

// REQ-CART-002: the customer name persists across sessions via the LocalStore
// port, so a returning customer keeps their name.
void main() {
  test('name set in one session is restored in the next', () async {
    final store = InMemoryLocalStore();

    final first = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    first.read(customerNameProvider.notifier).set('Andrei');
    await pumpEventQueue();
    first.dispose();

    final second = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    addTearDown(second.dispose);
    // build() starts the async restore, so it is empty synchronously then filled.
    expect(second.read(customerNameProvider), '');
    await pumpEventQueue();
    expect(second.read(customerNameProvider), 'Andrei');
  });
}
