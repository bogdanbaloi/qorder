import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/storage/local_store.dart';
import '../data/menu/bundled_menu_repository.dart';
import '../data/notifications/logging_notifier.dart';
import '../data/ordering/mock_ordering_service.dart';
import '../data/outbox/outbox_repository.dart';
import '../domain/notifications/order_notifier.dart';
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

/// Shared record of routed notifications (Phase 0). Phase 1 replaces the
/// logging notifiers with real waiter-push and tablet (Ebriza) notifiers.
final notificationLogProvider = Provider<NotificationLog>(
  (ref) => NotificationLog(),
);

/// Builds the order notifier from the configured target (waiter / tablet /
/// both). Swapping the target is config. Adding a channel is a new class.
final orderNotifierProvider = Provider<OrderNotifier>((ref) {
  final log = ref.watch(notificationLogProvider);
  final target = ref.watch(appConfigProvider).notificationTarget;
  return buildOrderNotifier(
    target,
    waiter: LoggingOrderNotifier(NotificationChannels.waiter, log),
    tablet: LoggingOrderNotifier(NotificationChannels.tablet, log),
  );
});
