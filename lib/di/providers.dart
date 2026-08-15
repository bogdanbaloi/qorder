import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/storage/local_store.dart';
import '../data/alerts/device_alert_signal.dart';
import '../data/menu/bundled_menu_repository.dart';
import '../data/notifications/logging_notifier.dart';
import '../data/ordering/mock_ordering_service.dart';
import '../data/ordering/remote_backend.dart';
import '../data/outbox/outbox_repository.dart';
import '../domain/acceptance/order_acceptance.dart';
import '../domain/alerts/alert_signal.dart';
import '../domain/notifications/order_notifier.dart';
import '../domain/repositories/menu_repository.dart';
import '../domain/repositories/outbox_repository.dart';
import '../domain/services/ordering_service.dart';
import '../domain/usecases/submit_order_use_case.dart';
import '../domain/waiter/waiter_request.dart';

/// Composition root: interfaces are bound to concrete implementations HERE,
/// in one place (like the HMI wiring). Tests override these to inject fakes.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.demo);

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return BundledMenuRepository(assetPath: cfg.menuAsset);
});

/// Phase 0: ONE in-memory backend implements both the customer-side
/// `OrderingService` and the waiter-side `OrderAcceptanceService`, so a waiter
/// accept and a customer status share state. The venue's `AcceptanceMode`
/// selects the policy. Phase 1 splits these behind the BFF/Ebriza.
final mockBackendProvider = Provider<MockOrderingService>((ref) {
  final mode = ref.watch(appConfigProvider).acceptanceMode;
  return MockOrderingService(
    acceptancePolicy: acceptancePolicyFor(mode),
    // Shared across browser tabs on the same device (localStorage on web), so
    // the customer tab and the waiter tab see the same awaiting orders.
    sharedStore: ref.watch(localStoreProvider),
  );
});

/// Shared HTTP client for the remote backend, closed with the container.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// The BFF-backed implementation of both order interfaces. Built only when a
/// BFF URL is configured (`AppConfig.useRemoteBackend`).
final remoteBackendProvider = Provider<RemoteBackend>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return RemoteBackend(
    baseUrl: cfg.backendBaseUrl,
    client: ref.watch(httpClientProvider),
  );
});

/// The backend seam: in-memory mock by default, the remote BFF when a URL is
/// configured. Consumers depend only on the interface (Dependency Inversion),
/// so nothing downstream changes when the backend is swapped (Open/Closed).
final orderingServiceProvider = Provider<OrderingService>((ref) {
  return ref.watch(appConfigProvider).useRemoteBackend
      ? ref.watch(remoteBackendProvider)
      : ref.watch(mockBackendProvider);
});

final orderAcceptanceServiceProvider = Provider<OrderAcceptanceService>((ref) {
  return ref.watch(appConfigProvider).useRemoteBackend
      ? ref.watch(remoteBackendProvider)
      : ref.watch(mockBackendProvider);
});

/// Customer-side waiter requests (raise). Same mock-vs-remote seam as ordering.
final waiterCallerProvider = Provider<WaiterCaller>((ref) {
  return ref.watch(appConfigProvider).useRemoteBackend
      ? ref.watch(remoteBackendProvider)
      : ref.watch(mockBackendProvider);
});

/// Waiter-side view of pending requests (list + resolve).
final waiterRequestBoardProvider = Provider<WaiterRequestBoard>((ref) {
  return ref.watch(appConfigProvider).useRemoteBackend
      ? ref.watch(remoteBackendProvider)
      : ref.watch(mockBackendProvider);
});

/// The staff attention signal (sound / vibration). Faked in tests.
final alertSignalProvider = Provider<AlertSignal>(
  (ref) => const DeviceAlertSignal(),
);

/// Local persistence engine. In-memory by default (tests); `main` overrides it
/// with a durable shared_preferences-backed store on device/web.
final localStoreProvider = Provider<LocalStore>((ref) => InMemoryLocalStore());

final outboxRepositoryProvider = Provider<OutboxRepository>(
  (ref) => LocalStoreOutboxRepository(ref.watch(localStoreProvider)),
);

/// The submit orchestration (bounded retry + timeout + idempotent outbox),
/// composed from its two ports. Depends on interfaces only, so it is unit-
/// testable without Riverpod (see `test/submit_order_use_case_test.dart`).
final submitOrderUseCaseProvider = Provider<SubmitOrderUseCase>(
  (ref) => SubmitOrderUseCase(
    ref.watch(orderingServiceProvider),
    ref.watch(outboxRepositoryProvider),
  ),
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
