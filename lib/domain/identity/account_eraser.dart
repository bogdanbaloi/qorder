/// Erases the signed-in customer's data on the backend (GDPR right to erasure).
/// The client pairs this with a sign-out that drops the local copy, so the erase
/// covers both the server and the device.
abstract interface class AccountEraser {
  Future<void> erase(String customerId);
}
