import 'dart:math';

import 'package:postgres/postgres.dart';

import 'identity_store.dart';

/// Postgres-backed identity. GLOBAL, not tenant-scoped: the tables carry no
/// venue_id, because a person is the same at any venue. Per-venue data links to
/// the customer by customer_id.
class PostgresIdentityStore implements IdentityStore {
  final Pool<void> _db;

  /// Injected so tests are deterministic; production uses random values.
  final String Function() codeGen;
  final String Function() tokenGen;

  PostgresIdentityStore(this._db,
      {String Function()? codeGen, String Function()? tokenGen})
      : codeGen = codeGen ?? _sixDigits,
        tokenGen = tokenGen ?? _randomToken;

  @override
  Future<({String challengeId, String code})?> startChallenge(
    String phone, {
    required int nowMs,
  }) async {
    return _db.runTx((tx) async {
      final recent = await tx.execute(
        Sql.named(
          'SELECT count(*) FROM otp_starts '
          'WHERE phone = @p AND started_at_ms > @cutoff::bigint',
        ),
        parameters: {'p': phone, 'cutoff': nowMs - identityRateWindowMs},
      );
      if ((recent.first[0] as num).toInt() >= identityMaxStartsPerWindow) {
        return null; // rate limited
      }
      await tx.execute(
        Sql.named(
          'INSERT INTO otp_starts (phone, started_at_ms) '
          'VALUES (@p, @now::bigint)',
        ),
        parameters: {'p': phone, 'now': nowMs},
      );
      final code = codeGen();
      final rows = await tx.execute(
        Sql.named('''
          INSERT INTO otp_challenges (phone, code, expires_at_ms)
          VALUES (@phone, @code, @exp::bigint)
          RETURNING challenge_id
        '''),
        parameters: {
          'phone': phone,
          'code': code,
          'exp': nowMs + identityOtpTtlMs,
        },
      );
      return (challengeId: rows.first[0] as String, code: code);
    });
  }

  @override
  Future<CustomerSession?> verify(
    String challengeId,
    String code, {
    required int nowMs,
  }) async {
    return _db.runTx((tx) async {
      final found = await tx.execute(
        Sql.named(
          'SELECT phone, code, expires_at_ms FROM otp_challenges '
          'WHERE challenge_id = @id',
        ),
        parameters: {'id': challengeId},
      );
      if (found.isEmpty) return null;
      final challenge = found.first.toColumnMap();
      if ((challenge['code'] as String) != code) return null;
      if (nowMs > (challenge['expires_at_ms'] as num).toInt()) return null;

      final phone = challenge['phone'] as String;
      // Single-use: spend the challenge.
      await tx.execute(
        Sql.named('DELETE FROM otp_challenges WHERE challenge_id = @id'),
        parameters: {'id': challengeId},
      );
      // Get-or-create the customer, keyed by phone.
      final customerId = 'cust:$phone';
      await tx.execute(
        Sql.named('''
          INSERT INTO customers (customer_id, phone, created_at_ms)
          VALUES (@cid, @phone, @now::bigint)
          ON CONFLICT (customer_id) DO NOTHING
        '''),
        parameters: {'cid': customerId, 'phone': phone, 'now': nowMs},
      );
      final token = tokenGen();
      await tx.execute(
        Sql.named('''
          INSERT INTO auth_tokens (token, customer_id, created_at_ms)
          VALUES (@token, @cid, @now::bigint)
        '''),
        parameters: {'token': token, 'cid': customerId, 'now': nowMs},
      );
      return CustomerSession(
        customerId: customerId,
        phone: phone,
        token: token,
      );
    });
  }

  @override
  Future<String?> customerForToken(String token) async {
    final rows = await _db.execute(
      Sql.named('SELECT customer_id FROM auth_tokens WHERE token = @t'),
      parameters: {'t': token},
    );
    return rows.isEmpty ? null : rows.first[0] as String;
  }

  @override
  Future<bool> isKnownCustomer(String key) async {
    final rows = await _db.execute(
      Sql.named('SELECT 1 FROM customers WHERE customer_id = @k'),
      parameters: {'k': key},
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> eraseCustomer(String customerId) async {
    // Global tables (a person is the same at any venue), so no venue scope.
    await _db.runTx((tx) async {
      await tx.execute(
        Sql.named('DELETE FROM auth_tokens WHERE customer_id = @c'),
        parameters: {'c': customerId},
      );
      await tx.execute(
        Sql.named('DELETE FROM customers WHERE customer_id = @c'),
        parameters: {'c': customerId},
      );
    });
  }
}

String _sixDigits() =>
    (Random().nextInt(900000) + 100000).toString(); // 100000..999999

String _randomToken() {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  const length = 32;
  final rng = Random();
  return List.generate(
    length,
    (_) => alphabet[rng.nextInt(alphabet.length)],
  ).join();
}
