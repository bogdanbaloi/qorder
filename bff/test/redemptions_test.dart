import 'package:qorder_bff/redemption_store.dart';
import 'package:test/test.dart';

// The redemption store: a customer spends points on a reward, gets a code, and
// the staff validate it. Codes are deterministic here for the test.
void main() {
  InMemoryRedemptionStore store() =>
      InMemoryRedemptionStore(codeFor: (seq) => 'CODE$seq');

  test('create returns a pending redemption with a code', () {
    final s = store();
    final r = s.create(
      venueId: 'demo',
      clientId: 'me',
      reward: 'Beer',
      cost: 100,
    );
    expect(r.code, 'CODE1');
    expect(r.consumed, isFalse);
    expect(r.cost, 100);
  });

  test('forCustomer returns only that client, newest first', () {
    final s = store();
    s.create(venueId: 'demo', clientId: 'me', reward: 'Beer', cost: 100);
    s.create(venueId: 'demo', clientId: 'other', reward: 'Platter', cost: 250);
    s.create(venueId: 'demo', clientId: 'me', reward: 'Platter', cost: 250);

    final mine = s.forCustomer('demo', 'me');
    expect(mine.length, 2);
    expect(mine.first.code, 'CODE3'); // newest first
    expect(mine.every((r) => r.clientId == 'me'), isTrue);
  });

  test('pending excludes consumed, and consume validates by code', () {
    final s = store();
    final r = s.create(
      venueId: 'demo',
      clientId: 'me',
      reward: 'Beer',
      cost: 100,
    );
    expect(s.pending('demo').length, 1);

    expect(s.consume(r.code), isTrue);
    expect(s.pending('demo'), isEmpty);
    // A second consume of the same code fails (already validated).
    expect(s.consume(r.code), isFalse);
    expect(s.consume('nope'), isFalse);
  });
}
