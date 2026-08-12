import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/storage/local_store.dart';
import '../data/menu/bundled_menu_repository.dart';
import '../data/ordering/mock_ordering_service.dart';
import '../data/outbox/outbox_repository.dart';
import '../domain/repositories/menu_repository.dart';
import '../domain/services/ordering_service.dart';

/// Composition root: interfaces are bound to concrete implementations HERE,
/// in one place (like the HMI wiring). Tests override these to inject fakes.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.demo);

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return BundledMenuRepository(assetPath: cfg.menuAsset);
});

final orderingServiceProvider = Provider<OrderingService>(
  (ref) => MockOrderingService(),
);

/// Local persistence engine. In-memory by default (tests); `main` overrides it
/// with a durable shared_preferences-backed store on device/web.
final localStoreProvider = Provider<LocalStore>((ref) => InMemoryLocalStore());

final outboxRepositoryProvider = Provider<OutboxRepository>(
  (ref) => LocalStoreOutboxRepository(ref.watch(localStoreProvider)),
);
