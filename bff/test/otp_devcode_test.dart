import 'dart:convert';

import 'package:qorder_bff/consent_store.dart';
import 'package:qorder_bff/identity_store.dart';
import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:qorder_bff/redemption_store.dart';
import 'package:qorder_bff/request_store.dart';
import 'package:qorder_bff/sms_sender.dart';
import 'package:qorder_bff/staff_auth_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// REQ-SEC-001: the OTP code must not be exposed in production. It is echoed as
/// `devCode` only when a deployment opts in, so the default is safe.
Handler _handler({required bool exposeDevCode}) => OrderApi(
      InMemoryOrderStore(),
      InMemoryWaiterRequestStore(),
      InMemoryRedemptionStore(),
      InMemoryIdentityStore(),
      InMemoryConsentStore(),
      InMemoryStaffAuthStore(codesByVenue: const {}),
      sms: exposeDevCode ? const DevSmsSender() : const SilentSmsSender(),
      exposeDevCode: exposeDevCode,
    ).handler;

Future<Map<String, dynamic>> _otpStart(Handler handler) async {
  final res = await handler(
    Request(
      'POST',
      Uri.parse('http://x/auth/otp/start'),
      body: jsonEncode({'phone': '0712345678'}),
    ),
  );
  return jsonDecode(await res.readAsString()) as Map<String, dynamic>;
}

void main() {
  test('the OTP code is not exposed by default (production safe)', () async {
    final body = await _otpStart(_handler(exposeDevCode: false));
    expect(body.containsKey('devCode'), isFalse);
  });

  test('the demo can opt in to exposing the OTP code', () async {
    final body = await _otpStart(_handler(exposeDevCode: true));
    expect(body['devCode'], isNotNull);
  });
}
