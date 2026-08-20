import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:qorder_bff/database.dart';
import 'package:qorder_bff/postgres_identity_store.dart';
import 'package:test/test.dart';

/// Integration tests against a real Postgres. Set QORDER_DATABASE_URL to run.
void main() {
  final url = Platform.environment['QORDER_DATABASE_URL'];
  final now = DateTime(2026, 8, 17, 12).millisecondsSinceEpoch;

  group('PostgresIdentityStore', () {
    late Pool<void> pool;
    late PostgresIdentityStore store;
    var tokenSeq = 0;

    setUpAll(() async {
      pool = openDatabasePool(url!);
      await applyMigrations(pool);
    });

    setUp(() async {
      tokenSeq = 0;
      await pool.execute('DELETE FROM auth_tokens');
      await pool.execute('DELETE FROM customers');
      await pool.execute('DELETE FROM otp_challenges');
      await pool.execute('DELETE FROM otp_starts');
      // A fresh token per sign-in, since the token is a primary key.
      store = PostgresIdentityStore(
        pool,
        codeGen: () => '123456',
        tokenGen: () => 'tok-${++tokenSeq}',
      );
    });

    tearDownAll(() async {
      await pool.close();
    });

    test('verify returns a session keyed by phone', () async {
      final started = (await store.startChallenge('0740', nowMs: now))!;
      expect(started.code, '123456');

      final session = await store.verify(
        started.challengeId,
        '123456',
        nowMs: now,
      );
      expect(session!.customerId, 'cust:0740');
      expect(await store.customerForToken(session.token), 'cust:0740');
      expect(await store.isKnownCustomer('cust:0740'), isTrue);
      expect(await store.isKnownCustomer('anon-device'), isFalse);
    });

    test('the same phone maps to the same customer', () async {
      final a = (await store.startChallenge('0740', nowMs: now))!;
      final first = (await store.verify(a.challengeId, '123456', nowMs: now))!;
      final b = (await store.startChallenge('0740', nowMs: now))!;
      final second = (await store.verify(b.challengeId, '123456', nowMs: now))!;
      expect(second.customerId, first.customerId);
      expect(second.token, isNot(first.token)); // a fresh token each sign-in
    });

    test('a wrong, expired or reused code returns null', () async {
      final started = (await store.startChallenge('0740', nowMs: now))!;
      expect(await store.verify(started.challengeId, '000000', nowMs: now),
          isNull);

      final expired = (await store.startChallenge('0741', nowMs: now))!;
      final later = now + 10 * 60 * 1000;
      expect(await store.verify(expired.challengeId, '123456', nowMs: later),
          isNull);

      final ok = (await store.startChallenge('0742', nowMs: now))!;
      expect(
          await store.verify(ok.challengeId, '123456', nowMs: now), isNotNull);
      expect(await store.verify(ok.challengeId, '123456', nowMs: now), isNull);
    });

    test('startChallenge is rate limited per phone', () async {
      for (var i = 0; i < 5; i++) {
        expect(await store.startChallenge('0799', nowMs: now), isNotNull);
      }
      expect(await store.startChallenge('0799', nowMs: now), isNull); // 6th
      expect(
          await store.startChallenge('0700', nowMs: now), isNotNull); // other
    });
  }, skip: url == null ? 'Set QORDER_DATABASE_URL to run' : false);
}
