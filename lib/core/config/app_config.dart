import 'package:flutter/foundation.dart';

import '../../domain/acceptance/order_acceptance.dart';
import '../../domain/notifications/order_notifier.dart';
import '../app_constants.dart';

/// Branding is DATA, not code. A new venue is a new [Branding] + menu, no rewrite.
/// Colors are extracted from the venue site (policy vs mechanism).
@immutable
class Branding {
  final String venueName;
  final int backgroundColor; // 0xAARRGGBB
  final int surfaceColor;
  final int primaryColor; // accent used for actions/prices
  final int accentColor; // secondary highlight (e.g. "NEW" badges)
  final String?
  displayFont; // bundled font family for headings (null = default)

  /// When true, menu categories alternate between a dark band (primary text) and
  /// a primary-coloured band (dark text), mirroring the venue site. Off by
  /// default, so a plainer venue keeps a single dark background.
  final bool alternatingCategoryBands;

  const Branding({
    required this.venueName,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.primaryColor,
    required this.accentColor,
    this.displayFont,
    this.alternatingCategoryBands = false,
  });
}

/// Policy for what counts as a valid table number. Configurable, not hard-coded.
/// A real backend (Ebriza `List tables`) will later replace the range with the
/// actual known table set. The submit gate does not change.
@immutable
class TableNumberPolicy {
  final int min;
  final int max;
  const TableNumberPolicy({
    this.min = AppConstants.tableNumberMin,
    this.max = AppConstants.tableNumberMax,
  });

  bool isValid(int n) => n >= min && n <= max;
}

@immutable
class AppConfig {
  final String venueId; // extensibility seam: multi-venue ready
  final Branding branding;
  final TableNumberPolicy tablePolicy;
  final String menuAsset; // Phase 0 source. Phase 1 swaps to a remote endpoint
  final Map<String, bool> featureFlags;
  final NotificationTarget notificationTarget;
  final AcceptanceMode acceptanceMode;

  /// When true, the customer must enter a name before submitting, so the shared
  /// table shows who ordered what.
  final bool requireCustomerName;

  /// Base URL of the BFF. Empty = the in-memory mock backend. Set it to run
  /// against the real server (customer and waiter sync across devices).
  final String backendBaseUrl;

  const AppConfig({
    required this.venueId,
    required this.branding,
    required this.tablePolicy,
    required this.menuAsset,
    this.featureFlags = const {},
    this.notificationTarget = NotificationTarget.both,
    this.acceptanceMode = AcceptanceMode.auto,
    this.requireCustomerName = false,
    this.backendBaseUrl = '',
  });

  bool isEnabled(String flag) => featureFlags[flag] ?? false;

  /// True when a BFF URL is configured, so the app talks to the real server.
  bool get useRemoteBackend => backendBaseUrl.isNotEmpty;

  /// The BFF URL, passed at build/run time and NOT hard-coded in the repo:
  /// `flutter run --dart-define=QORDER_BFF_URL=http://<lan-ip>:8080`.
  static const _bffUrl = String.fromEnvironment('QORDER_BFF_URL');

  /// The single configured venue for now. Adding another pub = another config.
  static const AppConfig demo = AppConfig(
    venueId: 'demo',
    branding: Branding(
      venueName: 'Demo Pub',
      // Tokens read off the venue site: dark carbon background, a strong orange
      // for headings/prices/actions, and a bright yellow for NEW / signature.
      backgroundColor: 0xFF2A2A2C, // dark charcoal (carbon texture)
      surfaceColor: 0xFF1E1E20, // slightly darker for cards/sheets
      primaryColor: 0xFFF26A21, // signature orange
      accentColor: 0xFFFFD400, // bright yellow highlight
      displayFont: 'Chakra Petch', // techno headings, close to the site font
      alternatingCategoryBands: true, // orange/dark bands like the site
    ),
    tablePolicy: TableNumberPolicy(),
    menuAsset: 'assets/menu/demo.json',
    featureFlags: {'payment': false, 'callWaiter': false},
    acceptanceMode: AcceptanceMode.waiterConfirm,
    requireCustomerName: true,
    backendBaseUrl: _bffUrl,
  );
}
