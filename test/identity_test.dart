import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/data/identity/mock_consent_source.dart';
import 'package:qorder/data/identity/mock_identity_service.dart';
import 'package:qorder/domain/identity/consent.dart';
import 'package:qorder/domain/identity/customer_identity.dart';
import 'package:qorder/features/account/account_providers.dart';
import 'package:qorder/features/session/session_controller.dart';
import 'package:qorder/features/table/customer_provider.dart';

// REQ-IDENT-001: phone sign-in (mock OTP), the effective loyalty key falls back
// to the anonymous client id, and consent is recorded per venue and purpose.
void main() {
  group('mock identity service', () {
    const service = MockIdentityService();

    test('verify with the demo code returns an identity from the phone', () async {
      final challenge = await service.startSignIn('0740');
      final identity = await service.verify(challenge, MockIdentityService.demoCode);
      expect(identity.customerId, 'cust:0740');
      expect(identity.phone, '0740');
      expect(identity.token, isNotEmpty);
    });

    test('verify with a wrong code throws', () async {
      final challenge = await service.startSignIn('0740');
      expect(() => service.verify(challenge, '123456'), throwsException);
    });
  });

  test('the loyalty key is the client id when anonymous, the customerId when signed in', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final clientId = container.read(clientIdProvider);
    expect(container.read(loyaltyKeyProvider), clientId);

    container.read(sessionProvider.notifier).signInCustomer(
      const CustomerIdentity(customerId: 'cust:1', phone: '1', token: 't'),
    );
    expect(container.read(loyaltyKeyProvider), 'cust:1');
  });

  test('consent is recorded per venue and purpose', () async {
    final source = MockConsentSource();
    await source.setConsent('demo', 'cust:1', const [
      Consent(purpose: ConsentPurpose.loyalty, granted: true),
      Consent(purpose: ConsentPurpose.marketing, granted: false),
    ]);
    final stored = await source.forCustomer('demo', 'cust:1');
    expect(stored.length, 2);
    expect(stored.firstWhere((c) => c.purpose == ConsentPurpose.marketing).granted, isFalse);
    // A different venue has none (isolation).
    expect(await source.forCustomer('other', 'cust:1'), isEmpty);
  });
}
