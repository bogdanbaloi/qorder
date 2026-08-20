import 'package:qorder_bff/consent_store.dart';
import 'package:qorder_bff/identity_store.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:test/test.dart';

// The identity backend: OTP start/verify (deterministic here), a customer is
// created per phone, tokens map back to the customer, and merge re-keys the
// anonymous device's orders to the customerId.
void main() {
  InMemoryIdentityStore idStore() =>
      InMemoryIdentityStore(codeGen: () => '123456', tokenGen: () => 'tok-1');

  final now = DateTime(2026, 8, 17, 12).millisecondsSinceEpoch;

  test('verify with the right code returns a session keyed by phone', () async {
    final s = idStore();
    final started = (await s.startChallenge('0740', nowMs: now))!;
    expect(started.code, '123456');

    final session = await s.verify(started.challengeId, '123456', nowMs: now);
    expect(session, isNotNull);
    expect(session!.customerId, 'cust:0740');
    expect(session.token, 'tok-1');
    expect(await s.customerForToken('tok-1'), 'cust:0740');
  });

  test('a wrong, expired or reused code returns null', () async {
    final s = idStore();
    final started = (await s.startChallenge('0740', nowMs: now))!;
    expect(await s.verify(started.challengeId, '000000', nowMs: now), isNull);

    final expired = (await s.startChallenge('0741', nowMs: now))!;
    final later = now + 10 * 60 * 1000; // 10 minutes later
    expect(await s.verify(expired.challengeId, '123456', nowMs: later), isNull);

    final ok = (await s.startChallenge('0742', nowMs: now))!;
    expect(await s.verify(ok.challengeId, '123456', nowMs: now), isNotNull);
    expect(await s.verify(ok.challengeId, '123456', nowMs: now), isNull);
  });

  test('startChallenge is rate limited per phone', () async {
    final s = idStore();
    for (var i = 0; i < 5; i++) {
      expect(await s.startChallenge('0799', nowMs: now), isNotNull);
    }
    expect(await s.startChallenge('0799', nowMs: now), isNull); // 6th refused
    expect(
        await s.startChallenge('0700', nowMs: now), isNotNull); // other phone
  });

  test('the same phone maps to the same customer', () async {
    final s = idStore();
    final a = (await s.startChallenge('0740', nowMs: now))!;
    final first = (await s.verify(a.challengeId, '123456', nowMs: now))!;
    final b = (await s.startChallenge('0740', nowMs: now))!;
    final second = (await s.verify(b.challengeId, '123456', nowMs: now))!;
    expect(second.customerId, first.customerId);
  });

  test('relink moves the anonymous orders to the customerId', () async {
    final orders = InMemoryOrderStore();
    await orders.submit(
      venueId: 'demo',
      order: {'idempotencyKey': 'k1', 'tableNumber': 5, 'clientId': 'anon'},
    );
    expect((await orders.forCustomer('demo', 'anon')).length, 1);

    await orders.relink('anon', 'cust:0740');
    expect(await orders.forCustomer('demo', 'anon'), isEmpty);
    expect((await orders.forCustomer('demo', 'cust:0740')).length, 1);
  });

  test('consent is stored per venue and customer', () async {
    final c = InMemoryConsentStore();
    await c.setConsent('demo', 'cust:0740', [
      {'purpose': 'loyalty', 'granted': true},
      {'purpose': 'marketing', 'granted': false},
    ]);
    expect((await c.forCustomer('demo', 'cust:0740')).length, 2);
    expect(await c.forCustomer('other', 'cust:0740'), isEmpty);
  });
}
