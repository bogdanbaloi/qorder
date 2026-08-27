import 'dart:convert';

import 'package:qorder_bff/consent_store.dart';
import 'package:qorder_bff/identity_store.dart';
import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:qorder_bff/redemption_store.dart';
import 'package:qorder_bff/request_store.dart';
import 'package:qorder_bff/staff_auth_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// REQ-GDPR-001: a customer can have their data erased. Identity, redemptions and
/// consent are deleted; orders keep the anonymized sale record.
void main() {
  test('erasing a customer removes their PII across the stores', () async {
    final identity = InMemoryIdentityStore();
    final orders = InMemoryOrderStore();
    final redemptions = InMemoryRedemptionStore();
    final consent = InMemoryConsentStore();
    final api = OrderApi(
      orders,
      InMemoryWaiterRequestStore(),
      redemptions,
      identity,
      consent,
      InMemoryStaffAuthStore(codesByVenue: const {}),
    ).handler;

    // A signed-in customer with data across the stores.
    final challenge = await identity.startChallenge('0712345678', nowMs: 0);
    final session =
        await identity.verify(challenge!.challengeId, challenge.code, nowMs: 1);
    final id = session!.customerId;
    final token = session.token;

    await orders.submit(venueId: 'demo', order: {
      'tableNumber': 1,
      'clientId': id,
      'customerName': 'Alice',
      'lines': const [],
      'totalMinor': 100,
    });
    await redemptions.create(
      venueId: 'demo',
      clientId: id,
      reward: 'Beer',
      cost: 10,
    );
    await consent.setConsent('demo', id, [
      {'purpose': 'analytics', 'granted': true},
    ]);

    // Erase, authenticated as the data subject.
    final res = await api(
      Request(
        'POST',
        Uri.parse('http://x/customers/$id/erase'),
        headers: {'authorization': 'Bearer $token'},
      ),
    );
    expect(res.statusCode, 200);
    expect(jsonDecode(await res.readAsString()), {'erased': id});

    // Identity gone: the token no longer authenticates.
    expect(await identity.customerForToken(token), isNull);
    expect(await identity.isKnownCustomer(id), isFalse);
    // Consent and redemptions gone.
    expect(await consent.forCustomer('demo', id), isEmpty);
    expect(await redemptions.forCustomer('demo', id), isEmpty);
    // The order is kept but anonymized (no PII).
    final order = (await orders.forVenue('demo')).single;
    expect(order.customerName, isNull);
    expect(order.clientId, isNull);
  });

  test('a wrong token cannot erase another customer', () async {
    final identity = InMemoryIdentityStore();
    final api = OrderApi(
      InMemoryOrderStore(),
      InMemoryWaiterRequestStore(),
      InMemoryRedemptionStore(),
      identity,
      InMemoryConsentStore(),
      InMemoryStaffAuthStore(codesByVenue: const {}),
    ).handler;

    final challenge = await identity.startChallenge('0700000000', nowMs: 0);
    final session =
        await identity.verify(challenge!.challengeId, challenge.code, nowMs: 1);

    // No token for this known customer: refused.
    final res = await api(
      Request(
        'POST',
        Uri.parse('http://x/customers/${session!.customerId}/erase'),
      ),
    );
    expect(res.statusCode, 403);
  });
}
