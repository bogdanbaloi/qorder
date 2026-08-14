/// App-wide constants, centralized so business logic carries no magic literals.
class AppConstants {
  const AppConstants._();

  static const currency = 'RON';

  // Submit / retry policy.
  static const maxSubmitAttempts = 3;
  static const submitTimeout = Duration(seconds: 8);
  static const retryBackoffStep = Duration(milliseconds: 150);

  // Table number policy defaults.
  static const tableNumberMin = 1;
  static const tableNumberMax = 200;

  // Id prefixes.
  static const orderIdPrefix = 'ord-';
  static const idempotencyKeyPrefix = 'idem-';
  static const deviceIdPrefix = 'dev-';

  // Remote backend (BFF).
  static const httpOk = 200;
  static const statusPollInterval = Duration(milliseconds: 1500);
}
