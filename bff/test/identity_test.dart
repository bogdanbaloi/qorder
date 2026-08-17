import 'package:qorder_bff/consent_store.dart';
import 'package:qorder_bff/identity_store.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:test/test.dart';

// The identity backend: OTP start/verify (deterministic here), a customer is
// created per phone, tokens map back to the customer, and merge re-keys the
// anonymous device's orders to the customerId.
void main() {
  InMemoryIdentityStore idStore() => InMemoryIdentityStore(
    codeGen: () => '123456',
    tokenGen: () => 'tok-1',
  );

  final now = DateTime(2026, 8, 17, 12).millisecondsSinceEpoch;

  test('verify with the right code returns a session keyed by phone', () {
    final s = idStore();
    final started = s.startChallenge('0740', nowMs: now);
    expect(started.code, '123456');

    final session = s.verify(started.challengeId, '123456', nowMs: now);
    expect(session, isNotNull);
    expect(session!.customerId, 'cust:0740');
    expect(session.token, 'tok-1');
    expect(s.customerForToken('tok-1'), 'cust:0740');
  });

  test('a wrong or expired code returns null, and a code is single-use', () {
    final s = idStore();
    final started = s.startChallenge('0740', nowMs: now);
    expect(s.verify(started.challengeId, '000000', nowMs: now), isNull); // wrong

    final expired = s.startChallenge('0741', nowMs: now);
    final later = now + 10 * 60 * 1000; // 10 minutes later
    expect(s.verify(expired.challengeId, '123456', nowMs: later), isNull);

    final ok = s.startChallenge('0742', nowMs: now);
    expect(s.verify(ok.challengeId, '123456', nowMs: now), isNotNull);
    expect(s.verify(ok.challengeId, '123456', nowMs: now), isNull); // reused
  });

  test('the same phone maps to the same customer', () {
    final s = idStore();
    final a = s.startChallenge('0740', nowMs: now);
    final first = s.verify(a.challengeId, '123456', nowMs: now)!;
    final b = s.startChallenge('0740', nowMs: now);
    final second = s.verify(b.challengeId, '123456', nowMs: now)!;
    expect(second.customerId, first.customerId);
  });

  test('relink moves the anonymous orders to the customerId', () {
    final orders = InMemoryOrderStore();
    orders.submit(
      venueId: 'demo',
      order: {'idempotencyKey': 'k1', 'tableNumber': 5, 'clientId': 'anon'},
    );
    expect(orders.forCustomer('demo', 'anon').length, 1);

    orders.relink('anon', 'cust:0740');
    expect(orders.forCustomer('demo', 'anon'), isEmpty);
    expect(orders.forCustomer('demo', 'cust:0740').length, 1);
  });

  test('consent is stored per venue and customer', () {
    final c = InMemoryConsentStore();
    c.setConsent('demo', 'cust:0740', [
      {'purpose': 'loyalty', 'granted': true},
      {'purpose': 'marketing', 'granted': false},
    ]);
    expect(c.forCustomer('demo', 'cust:0740').length, 2);
    expect(c.forCustomer('other', 'cust:0740'), isEmpty);
  });
}
