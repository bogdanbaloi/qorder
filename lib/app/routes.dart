/// Route paths, in one place, so there are no route strings scattered around
/// (a typo in a literal path would only fail at runtime. A constant fails at
/// compile time).
class Routes {
  const Routes._();

  static const menu = '/menu';
  static const cart = '/cart';
  static const table = '/t/:table';

  /// The waiter surface (Phase 0: same app; Phase 1 a separate waiter build).
  static const waiter = '/waiter';

  /// The owner dashboard (behind the owner access code).
  static const owner = '/owner';

  /// The customer's account / loyalty screen.
  static const account = '/me';

  /// Path parameter name used by [table].
  static const tableParam = 'table';
}
