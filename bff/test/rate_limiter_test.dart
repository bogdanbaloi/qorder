import 'package:qorder_bff/rate_limiter.dart';
import 'package:test/test.dart';

/// REQ-OBS-004: the fixed-window limiter caps a caller and resets after the window.
void main() {
  final t0 = DateTime(2026, 1, 1, 12);

  test('allows up to the cap, then blocks within the window', () {
    final limiter = RateLimiter(
      maxPerWindow: 2,
      window: const Duration(minutes: 1),
    );
    expect(limiter.allow('ip', t0), isTrue);
    expect(limiter.allow('ip', t0), isTrue);
    expect(limiter.allow('ip', t0), isFalse);
  });

  test('resets after the window elapses', () {
    final limiter = RateLimiter(
      maxPerWindow: 1,
      window: const Duration(minutes: 1),
    );
    expect(limiter.allow('ip', t0), isTrue);
    expect(limiter.allow('ip', t0), isFalse);
    expect(limiter.allow('ip', t0.add(const Duration(minutes: 2))), isTrue);
  });

  test('tracks each key independently', () {
    final limiter = RateLimiter(
      maxPerWindow: 1,
      window: const Duration(minutes: 1),
    );
    expect(limiter.allow('a', t0), isTrue);
    expect(limiter.allow('b', t0), isTrue);
    expect(limiter.allow('a', t0), isFalse);
  });
}
