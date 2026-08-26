import 'dart:math';

/// OTP timing, shared by the in-memory and Postgres stores.
const int identityOtpTtlMs = 5 * 60 * 1000; // a code is valid for five minutes
const int identityRateWindowMs = 10 * 60 * 1000; // rate-limit window
const int identityMaxStartsPerWindow = 5; // challenges per phone per window

/// A pending phone verification: the [code] is checked against, and it expires.
class OtpChallenge {
  final String id;
  final String phone;
  final String code;
  final int expiresAtMs;

  OtpChallenge({
    required this.id,
    required this.phone,
    required this.code,
    required this.expiresAtMs,
  });
}

/// A verified customer session: the stable [customerId] their loyalty follows,
/// and the [token] their app sends on authenticated requests.
class CustomerSession {
  final String customerId;
  final String phone;
  final String token;

  CustomerSession({
    required this.customerId,
    required this.phone,
    required this.token,
  });
}

/// The customer identity PORT (Dependency Inversion). Identity is GLOBAL, not
/// tenant-scoped: a person is the same at any venue. Async, so a persistent
/// (Postgres) implementation drops in behind this interface. POS-agnostic: qorder
/// owns the OTP proof and the customerId; a POS (e.g. Ebriza) adapter can later
/// map a verified phone to its own client record behind the same seam.
abstract interface class IdentityStore {
  /// Start a phone verification. Returns the challenge id and the code, or null
  /// when the phone has asked too often (rate limited, so a bad actor cannot burn
  /// the SMS budget). Real SMS sends the code; the dev sender returns it so the
  /// demo works with no SMS provider.
  Future<({String challengeId, String code})?> startChallenge(
    String phone, {
    required int nowMs,
  });

  /// Verify a code; returns the session, or null when the code is wrong/expired.
  /// A customer is created on first verify and reused (keyed by phone).
  Future<CustomerSession?> verify(
    String challengeId,
    String code, {
    required int nowMs,
  });

  /// The customerId a token authenticates, or null. For request authorization.
  Future<String?> customerForToken(String token);

  /// Whether [key] is a customerId this store issued (vs an anonymous clientId).
  /// Customer-scoped reads for a known customer require a matching token.
  Future<bool> isKnownCustomer(String key);

  /// Deletes a customer's identity and tokens (GDPR erasure, REQ-GDPR-001), so
  /// the phone no longer maps to them and their tokens stop authenticating.
  Future<void> eraseCustomer(String customerId);
}

String _sixDigits(Random rng) =>
    (rng.nextInt(900000) + 100000).toString(); // 100000..999999

String _randomToken(Random rng) {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  const length = 32;
  return List.generate(
    length,
    (_) => alphabet[rng.nextInt(alphabet.length)],
  ).join();
}

class InMemoryIdentityStore implements IdentityStore {
  /// Injected so tests are deterministic; production uses random values.
  final String Function() codeGen;
  final String Function() tokenGen;

  InMemoryIdentityStore({
    String Function()? codeGen,
    String Function()? tokenGen,
  })  : codeGen = codeGen ?? (() => _sixDigits(Random())),
        tokenGen = tokenGen ?? (() => _randomToken(Random()));

  int _seq = 0;
  final Map<String, OtpChallenge> _challenges = {};
  final Map<String, String> _customerByPhone = {};
  final Map<String, String> _customerByToken = {};
  final Set<String> _customerIds = {};
  final Map<String, List<int>> _startsByPhone = {};

  @override
  Future<({String challengeId, String code})?> startChallenge(
    String phone, {
    required int nowMs,
  }) async {
    final recent = (_startsByPhone[phone] ?? const <int>[])
        .where((t) => nowMs - t < identityRateWindowMs)
        .toList();
    if (recent.length >= identityMaxStartsPerWindow) {
      return null; // rate limited
    }
    _startsByPhone[phone] = [...recent, nowMs];

    _seq += 1;
    final id = 'chg:$_seq';
    final code = codeGen();
    _challenges[id] = OtpChallenge(
      id: id,
      phone: phone,
      code: code,
      expiresAtMs: nowMs + identityOtpTtlMs,
    );
    return (challengeId: id, code: code);
  }

  @override
  Future<CustomerSession?> verify(
    String challengeId,
    String code, {
    required int nowMs,
  }) async {
    final challenge = _challenges[challengeId];
    if (challenge == null) return null;
    if (nowMs > challenge.expiresAtMs) return null;
    if (challenge.code != code) return null;
    _challenges.remove(challengeId); // single-use

    final customerId = _customerByPhone.putIfAbsent(
      challenge.phone,
      () => 'cust:${challenge.phone}',
    );
    _customerIds.add(customerId);
    final token = tokenGen();
    _customerByToken[token] = customerId;
    return CustomerSession(
      customerId: customerId,
      phone: challenge.phone,
      token: token,
    );
  }

  @override
  Future<String?> customerForToken(String token) async =>
      _customerByToken[token];

  @override
  Future<bool> isKnownCustomer(String key) async => _customerIds.contains(key);

  @override
  Future<void> eraseCustomer(String customerId) async {
    _customerByPhone.removeWhere((_, id) => id == customerId);
    _customerByToken.removeWhere((_, id) => id == customerId);
    _customerIds.remove(customerId);
  }
}
