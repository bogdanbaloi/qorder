/// A one-shot attention signal for staff (sound / vibration). Behind an
/// interface so the surface stays dumb, a richer channel (web audio, a browser
/// notification) can be swapped in (Dependency Inversion), and it is faked in
/// tests.
abstract interface class AlertSignal {
  /// Fire the alert once.
  Future<void> fire();
}
