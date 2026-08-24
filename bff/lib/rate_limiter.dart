/// A fixed-window, in-memory rate limiter keyed by a caller id (an IP for the
/// public log endpoint). Bounds how often one caller can hit a route, so the
/// unauthenticated `POST /logs` cannot be flooded. In-memory is enough for a
/// single instance. A shared store would be needed across replicas.
class RateLimiter {
  final int maxPerWindow;
  final Duration window;

  final Map<String, _Bucket> _buckets = {};

  RateLimiter({required this.maxPerWindow, required this.window});

  /// Whether [key] may proceed at [now]. Counts the call when it is allowed.
  bool allow(String key, DateTime now) {
    final bucket = _buckets[key];
    if (bucket == null || now.difference(bucket.start) > window) {
      _buckets[key] = _Bucket(now);
      return true;
    }
    if (bucket.count >= maxPerWindow) return false;
    bucket.count++;
    return true;
  }
}

class _Bucket {
  final DateTime start;
  int count = 1;
  _Bucket(this.start);
}
