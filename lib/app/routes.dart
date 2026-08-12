/// Route paths, in one place, so there are no route strings scattered around
/// (a typo in a literal path would only fail at runtime. A constant fails at
/// compile time).
class Routes {
  const Routes._();

  static const menu = '/menu';
  static const cart = '/cart';
  static const table = '/t/:table';

  /// Path parameter name used by [table].
  static const tableParam = 'table';
}
