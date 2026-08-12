import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The optional name the customer types, shown on the shared table so the bar
/// and the others know who ordered what.
class CustomerNameController extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final customerNameProvider = NotifierProvider<CustomerNameController, String>(
  CustomerNameController.new,
);

/// Anonymous per-session device id, used to mark "which orders are mine" on the
/// shared table. In production this is persisted per device.
final clientIdProvider = Provider<String>(
  (ref) => 'dev-${DateTime.now().microsecondsSinceEpoch}',
);
