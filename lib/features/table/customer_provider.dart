import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_constants.dart';
import '../../di/providers.dart';

/// The optional name the customer types, shown on the shared table so the bar
/// and the others know who ordered what. Persisted through the [LocalStore] port
/// and restored on launch, so a returning customer keeps their name.
class CustomerNameController extends Notifier<String> {
  static const _box = 'settings';
  static const _key = 'customerName';

  @override
  String build() {
    unawaited(_restore());
    return '';
  }

  Future<void> _restore() async {
    final stored = await ref.read(localStoreProvider).get(_box, _key);
    final name = stored?['value'] as String?;
    if (name != null && name.isNotEmpty) state = name;
  }

  void set(String value) {
    state = value;
    unawaited(ref.read(localStoreProvider).put(_box, _key, {'value': value}));
  }
}

final customerNameProvider = NotifierProvider<CustomerNameController, String>(
  CustomerNameController.new,
);

/// Anonymous per-session device id, used to mark "which orders are mine" on the
/// shared table. In production this is persisted per device.
final clientIdProvider = Provider<String>(
  (ref) =>
      '${AppConstants.deviceIdPrefix}${DateTime.now().microsecondsSinceEpoch}',
);
