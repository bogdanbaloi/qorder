/// The base of the app's domain exceptions. Sealed, so a `switch` over it is
/// exhaustive: the compiler flags a new kind that a handler forgot. The subtypes
/// live here (a sealed type's subtypes must share its library), giving the app one
/// vocabulary for the errors it raises on purpose. Programming errors (an
/// `ArgumentError` for a bad argument) stay outside this: they are bugs to fix,
/// not conditions to handle.
sealed class AppException implements Exception {
  const AppException();
}

/// The backend rejected the token (401/403): the caller drops the session and
/// sends the user back to the access-code gate instead of failing silently with a
/// stale token.
class SessionExpiredException extends AppException {
  const SessionExpiredException();

  @override
  String toString() => 'SessionExpiredException';
}

/// A backend call failed: a non-success status, or a transport error. [operation]
/// names what failed (e.g. `save config`), and [statusCode] is the HTTP status
/// when there was one.
class BackendException extends AppException {
  final String operation;
  final int? statusCode;

  const BackendException(this.operation, {this.statusCode});

  @override
  String toString() => 'BackendException($operation'
      '${statusCode == null ? '' : ', status $statusCode'})';
}
