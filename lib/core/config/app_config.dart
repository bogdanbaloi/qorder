import 'package:flutter/foundation.dart';

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

  const Branding({
    required this.venueName,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.primaryColor,
    required this.accentColor,
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

  const AppConfig({
    required this.venueId,
    required this.branding,
    required this.tablePolicy,
    required this.menuAsset,
    this.featureFlags = const {},
    this.notificationTarget = NotificationTarget.both,
  });

  bool isEnabled(String flag) => featureFlags[flag] ?? false;

  /// The single configured venue for now. Adding another pub = another config.
  static const AppConfig demo = AppConfig(
    venueId: 'demo',
    branding: Branding(
      venueName: 'Demo Pub',
      backgroundColor: 0xFF383E42, // charcoal, from the site
      surfaceColor: 0xFF2A2F33,
      primaryColor: 0xFFFF7239, // signature orange
      accentColor: 0xFFE9FF06, // neon yellow
    ),
    tablePolicy: TableNumberPolicy(),
    menuAsset: 'assets/menu/demo.json',
    featureFlags: {'payment': false, 'callWaiter': false},
  );
}
