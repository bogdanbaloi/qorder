import 'dart:math';

/// A cryptographically secure random source for unguessable ids.
final _rng = Random.secure();

/// A random hex token, so an id cannot be guessed or enumerated. Used to suffix
/// the order id: the per-venue sequence stays a readable display number, but the
/// lookup id carries this opaque part, so `GET /orders/:id/status` (public) cannot
/// be walked by counting sequences (REQ-SEC-003). Default 8 bytes (64 bits).
String secureToken({int bytes = 8}) => List<int>.generate(
  bytes,
  (_) => _rng.nextInt(256),
).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
