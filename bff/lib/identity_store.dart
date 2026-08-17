import 'dart:math';

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

/// The customer identity PORT (Dependency Inversion). POS-agnostic: qorder owns
/// the OTP proof and the customerId; a POS (e.g. Ebriza) adapter can later map a
/// verified phone to its own client record behind this same seam. A persistent
/// implementation drops in behind this interface.
abstract interface class IdentityStore {
  /// Start a phone verification. Returns the challenge id and the code. Real SMS
  /// would send the code; the dev sender returns it so the demo works with no
  /// SMS provider.
  ({String challengeId, String code}) startChallenge(
    String phone, {
    required int nowMs,
  });

  /// Verify a code; returns the session, or null when the code is wrong/expired.
  /// A customer is created on first verify and reused (keyed by phone).
  CustomerSession? verify(String challengeId, String code, {required int nowMs});

  /// The customerId a token authenticates, or null. For request authorization.
  String? customerForToken(String token);
}

const int _otpTtlMs = 5 * 60 * 1000; // a code is valid for five minutes

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

  InMemoryIdentityStore({String Function()? codeGen, String Function()? tokenGen})
    : codeGen = codeGen ?? (() => _sixDigits(Random())),
      tokenGen = tokenGen ?? (() => _randomToken(Random()));

  int _seq = 0;
  final Map<String, OtpChallenge> _challenges = {};
  final Map<String, String> _customerByPhone = {};
  final Map<String, String> _customerByToken = {};

  @override
  ({String challengeId, String code}) startChallenge(
    String phone, {
    required int nowMs,
  }) {
    _seq += 1;
    final id = 'chg:$_seq';
    final code = codeGen();
    _challenges[id] = OtpChallenge(
      id: id,
      phone: phone,
      code: code,
      expiresAtMs: nowMs + _otpTtlMs,
    );
    return (challengeId: id, code: code);
  }

  @override
  CustomerSession? verify(
    String challengeId,
    String code, {
    required int nowMs,
  }) {
    final challenge = _challenges[challengeId];
    if (challenge == null) return null;
    if (nowMs > challenge.expiresAtMs) return null;
    if (challenge.code != code) return null;
    _challenges.remove(challengeId); // single-use

    final customerId = _customerByPhone.putIfAbsent(
      challenge.phone,
      () => 'cust:${challenge.phone}',
    );
    final token = tokenGen();
    _customerByToken[token] = customerId;
    return CustomerSession(
      customerId: customerId,
      phone: challenge.phone,
      token: token,
    );
  }

  @override
  String? customerForToken(String token) => _customerByToken[token];
}
