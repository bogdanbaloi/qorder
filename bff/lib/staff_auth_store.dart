import 'dart:math';

/// What a staff/owner token authenticates: the venue it is scoped to and the
/// role. A staff at one venue cannot act on another (per-tenant isolation).
class StaffClaims {
  final String venueId;
  final String role;

  StaffClaims(this.venueId, this.role);
}

/// The staff/owner auth PORT. Verifies a venue's access code for a role and
/// issues a scoped token. POS-agnostic and on the same token seam as the customer
/// identity; a real staff directory (Ebriza users) drops in behind it later.
abstract interface class StaffAuthStore {
  /// Verify [code] against the venue's configured code for [role]; returns a
  /// token scoped to (venue, role), or null when the code is wrong. [nowMs] is
  /// the issue time (defaults to now), used to stamp the token's expiry.
  String? authenticate(String venueId, String role, String code, {int? nowMs});

  /// The claims a token carries, or null when it is unknown or expired. [nowMs]
  /// defaults to now.
  StaffClaims? claims(String token, {int? nowMs});
}

/// A secure random token, so it cannot be guessed. `Random.secure()`, not the
/// predictable `Random()`.
String _randomToken() {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  const length = 32;
  final rng = Random.secure();
  return List.generate(
    length,
    (_) => alphabet[rng.nextInt(alphabet.length)],
  ).join();
}

/// The default lifetime of a staff/owner token. Long enough for a shift, short
/// enough that a leaked token is not valid forever (REQ-SEC-007).
const Duration _defaultTokenTtl = Duration(hours: 12);

/// A token's claims plus when it expires.
class _Session {
  final StaffClaims claims;
  final int expiresAtMs;

  _Session(this.claims, this.expiresAtMs);
}

class InMemoryStaffAuthStore implements StaffAuthStore {
  /// venueId -> { 'staff': code, 'owner': code }. Per-venue config; a real deploy
  /// loads it from a store / the POS user directory.
  final Map<String, Map<String, String>> codesByVenue;
  final String Function() tokenGen;

  /// How long an issued token stays valid.
  final Duration tokenTtl;

  InMemoryStaffAuthStore({
    required this.codesByVenue,
    String Function()? tokenGen,
    Duration? tokenTtl,
  })  : tokenGen = tokenGen ?? _randomToken,
        tokenTtl = tokenTtl ?? _defaultTokenTtl;

  final Map<String, _Session> _byToken = {};

  int _now(int? nowMs) => nowMs ?? DateTime.now().millisecondsSinceEpoch;

  @override
  String? authenticate(String venueId, String role, String code, {int? nowMs}) {
    final expected = codesByVenue[venueId]?[role];
    if (expected == null || expected != code) return null;
    final token = tokenGen();
    _byToken[token] = _Session(
      StaffClaims(venueId, role),
      _now(nowMs) + tokenTtl.inMilliseconds,
    );
    return token;
  }

  @override
  StaffClaims? claims(String token, {int? nowMs}) {
    final session = _byToken[token];
    if (session == null) return null;
    if (_now(nowMs) >= session.expiresAtMs) {
      _byToken.remove(token); // evict the expired token
      return null;
    }
    return session.claims;
  }
}
