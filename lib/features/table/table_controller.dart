import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/models/table_ref.dart';
import '../cart/cart_controller.dart';

/// Holds the current table reference. Set from the QR deep link (Phase 2) or
/// from manual entry (the guaranteed fallback). Validation uses the configured
/// policy; a live backend will later validate against Ebriza `List tables`.
class TableController extends Notifier<TableRef?> {
  @override
  TableRef? build() => null;

  void setFromQr(int number) {
    final policy = ref.read(appConfigProvider).tablePolicy;
    state = TableRef(
      number: number,
      source: TableSource.qr,
      validated: policy.isValid(number),
    );
  }

  void setManual(int number) {
    final policy = ref.read(appConfigProvider).tablePolicy;
    state = TableRef(
      number: number,
      source: TableSource.manual,
      validated: policy.isValid(number),
    );
  }

  void clear() => state = null;
}

final tableProvider = NotifierProvider<TableController, TableRef?>(
  TableController.new,
);

/// Submit is gated on: a validated table AND a non-empty cart.
final canSubmitProvider = Provider<bool>((ref) {
  final table = ref.watch(tableProvider);
  final cart = ref.watch(cartProvider);
  return table != null && table.validated && !cart.isEmpty;
});
