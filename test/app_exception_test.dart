import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/domain/errors/app_exception.dart';

/// The app's exception taxonomy: a sealed base, so a handler that switches over
/// it is exhaustive, with the two kinds the app actually raises.
void main() {
  test('BackendException carries the operation and status', () {
    const e = BackendException('save config', statusCode: 500);
    expect(e.operation, 'save config');
    expect(e.statusCode, 500);
    expect(e, isA<AppException>());
    expect(e, isA<Exception>());
  });

  test('SessionExpiredException is an AppException', () {
    expect(const SessionExpiredException(), isA<AppException>());
  });

  test('a sealed switch handles every kind exhaustively', () {
    // No default branch: the compiler enforces a case for each subtype, so a new
    // kind cannot be added without a handler.
    String kind(AppException e) => switch (e) {
      SessionExpiredException() => 'session',
      BackendException() => 'backend',
    };
    expect(kind(const SessionExpiredException()), 'session');
    expect(kind(const BackendException('x', statusCode: 404)), 'backend');
  });
}
