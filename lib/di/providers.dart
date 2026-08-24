import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/storage/local_store.dart';
import '../data/alerts/device_alert_signal.dart';
import '../data/config/in_memory_venue_config_source.dart';
import '../data/config/mock_venue_config_api.dart';
import '../data/config/remote_venue_config_api.dart';
import '../data/diagnostics/composite_logger.dart';
import '../data/diagnostics/console_logger.dart';
import '../data/diagnostics/remote_logger.dart';
import '../data/history/mock_history_source.dart';
import '../data/history/remote_history_source.dart';
import '../data/identity/mock_consent_source.dart';
import '../data/identity/mock_identity_service.dart';
import '../data/identity/mock_staff_auth_service.dart';
import '../data/identity/remote_consent_source.dart';
import '../data/identity/remote_identity_service.dart';
import '../data/identity/remote_staff_auth_service.dart';
import '../data/loyalty/mock_redemption_source.dart';
import '../data/loyalty/remote_redemption_source.dart';
import '../data/menu/bundled_menu_repository.dart';
import '../data/metrics/mock_metrics_source.dart';
import '../data/metrics/remote_metrics_source.dart';
import '../data/notifications/logging_notifier.dart';
import '../data/ordering/mock_ordering_service.dart';
import '../data/ordering/remote_backend.dart';
import '../data/outbox/outbox_repository.dart';
import '../data/platform/mock_operator_logs_source.dart';
import '../data/platform/mock_platform_metrics_source.dart';
import '../data/platform/remote_operator_logs_source.dart';
import '../data/platform/remote_platform_metrics_source.dart';
import '../domain/acceptance/order_acceptance.dart';
import '../domain/alerts/alert_signal.dart';
import '../domain/config/venue_config_api.dart';
import '../domain/config/venue_config_source.dart';
import '../domain/diagnostics/app_logger.dart';
import '../domain/history/history_source.dart';
import '../domain/identity/consent_source.dart';
import '../domain/identity/identity_service.dart';
import '../domain/identity/staff_auth_service.dart';
import '../domain/loyalty/redemption_source.dart';
import '../domain/metrics/metrics_source.dart';
import '../domain/notifications/order_notifier.dart';
import '../domain/platform/operator_logs_source.dart';
import '../domain/platform/platform_metrics_source.dart';
import '../domain/repositories/menu_repository.dart';
import '../domain/repositories/outbox_repository.dart';
import '../domain/services/ordering_service.dart';
import '../domain/timing/order_progress.dart';
import '../domain/usecases/submit_order_use_case.dart';
import '../domain/waiter/waiter_request.dart';
import '../features/session/session_controller.dart';

/// Composition root: interfaces are bound to concrete implementations HERE,
/// in one place (like the HMI wiring). Tests override these to inject fakes.
/// The venue registry: resolves a venueId to its [AppConfig]. In-memory now (the
/// config lives in the binary); a remote source drops in behind the port. Tests
/// override this to inject a fake set of venues.
final venueConfigSourceProvider = Provider<VenueConfigSource>(
  (ref) => InMemoryVenueConfigSource.demo(),
);

/// The venue this running app is acting as. Defaults to the demo venue; the QR
/// deep link (`/v/:venue/t/:table`) sets it via [ActiveVenue.set]. A tiny
/// controller, because a plain provider could only ever be a constant.
class ActiveVenue extends Notifier<String> {
  @override
  String build() => AppConfig.demo.venueId;

  /// Point the app at [venueId] (from the link). Idempotent.
  void set(String venueId) => state = venueId;
}

final activeVenueIdProvider = NotifierProvider<ActiveVenue, String>(
  ActiveVenue.new,
);

/// The active venue's config, resolved through [venueConfigSourceProvider]. Falls
/// back to the demo config if the active venue is unknown: a safety net only, as
/// the link resolver surfaces an unknown venue before routing in a later slice.
final appConfigProvider = Provider<AppConfig>((ref) {
  final venueId = ref.watch(activeVenueIdProvider);
  final source = ref.watch(venueConfigSourceProvider);
  return source.configFor(venueId) ?? AppConfig.demo;
});

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return BundledMenuRepository(
    assetPath: cfg.menuAsset,
    logger: ref.watch(loggerProvider),
  );
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

/// The app logger. The console always; when a backend is configured, also a
/// remote sink that ships warnings and errors to the BFF, so the operator sees
/// failures that happen on a patron's device. Data sources take it, so a
/// degrade-open catch logs why it degraded instead of swallowing the error.
final loggerProvider = Provider<AppLogger>((ref) {
  final console = ConsoleLogger();
  final cfg = ref.watch(appConfigProvider);
  if (!cfg.useRemoteBackend) return console;
  return CompositeLogger([
    console,
    RemoteLogger(
      baseUrl: cfg.backendBaseUrl,
      client: ref.watch(httpClientProvider),
      venueId: cfg.venueId,
    ),
  ]);
});

/// The BFF-backed implementation of both order interfaces. Built only when a
/// BFF URL is configured (`AppConfig.useRemoteBackend`).
final remoteBackendProvider = Provider<RemoteBackend>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return RemoteBackend(
    baseUrl: cfg.backendBaseUrl,
    client: ref.watch(httpClientProvider),
    authToken: ref.watch(sessionTokenProvider),
    logger: ref.watch(loggerProvider),
  );
});

/// Owner sales metrics: the BFF endpoint when a URL is configured, else the mock
/// (which reports empty, since the in-app backend keeps no history).
final metricsSourceProvider = Provider<MetricsSource>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return cfg.useRemoteBackend
      ? RemoteMetricsSource(
          baseUrl: cfg.backendBaseUrl,
          client: ref.watch(httpClientProvider),
          authToken: ref.watch(sessionTokenProvider),
        )
      : const MockMetricsSource();
});

/// Operator (cross-venue) metrics: the BFF `/platform/metrics` when a URL is
/// configured, else the mock (empty, since the in-app backend keeps no data). The
/// operator token is passed at call time from the admin screen, not from here.
final platformMetricsSourceProvider = Provider<PlatformMetricsSource>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return cfg.useRemoteBackend
      ? RemotePlatformMetricsSource(
          baseUrl: cfg.backendBaseUrl,
          client: ref.watch(httpClientProvider),
        )
      : MockPlatformMetricsSource();
});

/// The operator's view of recent client diagnostics: the BFF `GET /logs` when a
/// URL is configured, else an empty mock.
final operatorLogsSourceProvider = Provider<OperatorLogsSource>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return cfg.useRemoteBackend
      ? RemoteOperatorLogsSource(
          baseUrl: cfg.backendBaseUrl,
          client: ref.watch(httpClientProvider),
        )
      : const MockOperatorLogsSource();
});

/// The customer's order history: the BFF when a URL is configured, else the mock
/// (empty, since the in-app backend keeps no history).
final historySourceProvider = Provider<HistorySource>((ref) {
  final cfg = ref.watch(appConfigProvider);
  final token = ref.watch(sessionTokenProvider);
  return cfg.useRemoteBackend
      ? RemoteHistorySource(
          baseUrl: cfg.backendBaseUrl,
          client: ref.watch(httpClientProvider),
          authToken: token,
        )
      : const MockHistorySource();
});

/// One remote redemption adapter, shared by the customer and staff seams below
/// (it implements both interfaces). Built only when a BFF URL is configured.
final _remoteRedemptionSourceProvider = Provider<RemoteRedemptionSource>((ref) {
  final cfg = ref.watch(appConfigProvider);
  final token = ref.watch(sessionTokenProvider);
  return RemoteRedemptionSource(
    baseUrl: cfg.backendBaseUrl,
    client: ref.watch(httpClientProvider),
    authToken: token,
  );
});

/// Customer sign-in (phone + OTP): the BFF when a URL is configured, else the
/// mock (fixed demo code, no SMS). The BFF issues the code via a dev sender for
/// now; a real SMS adapter drops in behind the same port later.
final identityServiceProvider = Provider<IdentityService>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return cfg.useRemoteBackend
      ? RemoteIdentityService(
          baseUrl: cfg.backendBaseUrl,
          client: ref.watch(httpClientProvider),
        )
      : const MockIdentityService();
});

/// Staff/owner sign-in: the BFF (verifies the code, issues a scoped token) when a
/// URL is configured, else the mock (checks the config code locally).
final staffAuthServiceProvider = Provider<StaffAuthService>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return cfg.useRemoteBackend
      ? RemoteStaffAuthService(
          baseUrl: cfg.backendBaseUrl,
          client: ref.watch(httpClientProvider),
        )
      : MockStaffAuthService(
          staffCode: cfg.staffAccessCode,
          ownerCode: cfg.ownerAccessCode,
        );
});

/// The current session's bearer token (customer or staff/owner), for authorized
/// requests to the BFF. Null when anonymous.
final sessionTokenProvider = Provider<String?>(
  (ref) => ref.watch(sessionProvider.select((s) => s.token)),
);

/// The owner Settings write side. Remote (BFF, owner-authenticated) when a URL is
/// configured, else an in-memory mock so the offline demo still round-trips. The
/// mock is kept as one instance, so a saved edit is re-fetchable in the session.
final _mockVenueConfigApiProvider = Provider<MockVenueConfigApi>(
  (ref) => MockVenueConfigApi(),
);

final venueConfigApiProvider = Provider<VenueConfigApi>((ref) {
  final cfg = ref.watch(appConfigProvider);
  if (!cfg.useRemoteBackend) return ref.watch(_mockVenueConfigApiProvider);
  return RemoteVenueConfigApi(
    baseUrl: cfg.backendBaseUrl,
    client: ref.watch(httpClientProvider),
    authToken: ref.watch(sessionTokenProvider),
    logger: ref.watch(loggerProvider),
  );
});

/// The customer's per-venue, per-purpose consent: persisted on the BFF when a URL
/// is configured, else in the in-memory mock.
final consentSourceProvider = Provider<ConsentSource>((ref) {
  final cfg = ref.watch(appConfigProvider);
  final token = ref.watch(sessionTokenProvider);
  return cfg.useRemoteBackend
      ? RemoteConsentSource(
          baseUrl: cfg.backendBaseUrl,
          client: ref.watch(httpClientProvider),
          authToken: token,
        )
      : MockConsentSource();
});

/// Customer-side reward redemption (spend points, read own redemptions).
final rewardRedeemerProvider = Provider<RewardRedeemer>((ref) {
  return ref.watch(appConfigProvider).useRemoteBackend
      ? ref.watch(_remoteRedemptionSourceProvider)
      : const MockRedemptionSource();
});

/// Staff-side redemption board (list pending, validate a code).
final redemptionBoardProvider = Provider<RedemptionBoard>((ref) {
  return ref.watch(appConfigProvider).useRemoteBackend
      ? ref.watch(_remoteRedemptionSourceProvider)
      : const MockRedemptionSource();
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

/// Waiter-side order progress (in-progress list + mark ready / delivered).
final orderProgressProvider = Provider<OrderProgress>((ref) {
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
