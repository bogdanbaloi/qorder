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
  /// token scoped to (venue, role), or null when the code is wrong.
  String? authenticate(String venueId, String role, String code);

  /// The claims a token carries, or null.
  StaffClaims? claims(String token);
}

String _randomToken() {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  const length = 32;
  final rng = Random();
  return List.generate(
    length,
    (_) => alphabet[rng.nextInt(alphabet.length)],
  ).join();
}

class InMemoryStaffAuthStore implements StaffAuthStore {
  /// venueId -> { 'staff': code, 'owner': code }. Per-venue config; a real deploy
  /// loads it from a store / the POS user directory.
  final Map<String, Map<String, String>> codesByVenue;
  final String Function() tokenGen;

  InMemoryStaffAuthStore({
    required this.codesByVenue,
    String Function()? tokenGen,
  }) : tokenGen = tokenGen ?? _randomToken;

  final Map<String, StaffClaims> _byToken = {};

  @override
  String? authenticate(String venueId, String role, String code) {
    final expected = codesByVenue[venueId]?[role];
    if (expected == null || expected != code) return null;
    final token = tokenGen();
    _byToken[token] = StaffClaims(venueId, role);
    return token;
  }

  @override
  StaffClaims? claims(String token) => _byToken[token];
}
