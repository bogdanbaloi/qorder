/// A boundary-crossing result: success or an explicit, described failure.
///
/// We return values instead of throwing across layer boundaries. This is the
/// "explicit error handling at boundaries / degrade open" rule, idiomatic Dart.
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final String message;
  final Object? cause;
  const Err(this.message, {this.cause});
}
