import 'package:qorder_bff/staff_auth_store.dart';
import 'package:test/test.dart';

/// REQ-SEC-007: a staff/owner token expires after its lifetime, so a leaked token
/// is not valid forever.
void main() {
  InMemoryStaffAuthStore store() => InMemoryStaffAuthStore(
        codesByVenue: {
          'demo': {'staff': '2468', 'owner': '1357'},
        },
        tokenTtl: const Duration(hours: 12),
      );

  test('a valid token carries its venue and role', () {
    final s = store();
    final token = s.authenticate('demo', 'staff', '2468', nowMs: 0)!;
    final claims = s.claims(token, nowMs: 1000);
    expect(claims, isNotNull);
    expect(claims!.venueId, 'demo');
    expect(claims.role, 'staff');
  });

  test('a token expires after its TTL', () {
    final s = store();
    final token = s.authenticate('demo', 'owner', '1357', nowMs: 0)!;

    // Within the lifetime it still authenticates.
    expect(s.claims(token, nowMs: const Duration(hours: 11).inMilliseconds),
        isNotNull);
    // Past the lifetime it no longer does.
    expect(s.claims(token, nowMs: const Duration(hours: 13).inMilliseconds),
        isNull);
  });

  test('a wrong code issues no token', () {
    expect(store().authenticate('demo', 'owner', '0000'), isNull);
  });
}
