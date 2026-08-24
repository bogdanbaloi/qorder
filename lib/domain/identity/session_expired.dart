/// Thrown by an authenticated remote call when the backend rejects the token
/// (401/403), so the caller can drop the session and send the user back to the
/// access-code gate instead of failing silently with a stale token.
class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => 'SessionExpiredException';
}
