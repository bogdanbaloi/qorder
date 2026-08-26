import 'package:flutter/foundation.dart';

import '../../domain/acceptance/order_acceptance.dart';
import '../../domain/loyalty/loyalty_program.dart';
import '../../domain/loyalty/reward_tier.dart';
import '../../domain/notifications/order_notifier.dart';
import '../app_constants.dart';

/// Branding is DATA, not code. A new venue is a new [Branding] + menu, no rewrite.
/// Colors are extracted from the venue site (policy vs mechanism).
@immutable
class Branding {
  final String venueName;
  final int backgroundColor; // 0xAARRGGBB, dark-mode background
  final int surfaceColor; // dark-mode cards/sheets
  final int lightBackgroundColor; // light-mode background
  final int lightSurfaceColor; // light-mode cards/sheets
  final int primaryColor; // brand accent (seeds the Material 3 scheme)
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
    this.lightBackgroundColor = _defaultLightBackground,
    this.lightSurfaceColor = _defaultLightSurface,
    this.displayFont,
    this.alternatingCategoryBands = false,
  });

  factory Branding.fromJson(Map<String, dynamic> json) => Branding(
    venueName: json['venueName'] as String,
    backgroundColor: _parseColor(json['backgroundColor']),
    surfaceColor: _parseColor(json['surfaceColor']),
    primaryColor: _parseColor(json['primaryColor']),
    accentColor: _parseColor(json['accentColor']),
    // The light pair is optional, so an older saved config or asset stays valid
    // and falls back to a clean neutral light.
    lightBackgroundColor: json['lightBackgroundColor'] == null
        ? _defaultLightBackground
        : _parseColor(json['lightBackgroundColor']),
    lightSurfaceColor: json['lightSurfaceColor'] == null
        ? _defaultLightSurface
        : _parseColor(json['lightSurfaceColor']),
    displayFont: json['displayFont'] as String?,
    alternatingCategoryBands:
        json['alternatingCategoryBands'] as bool? ?? false,
  );

  /// The inverse of [Branding.fromJson]. Colours are written as `0xAARRGGBB` hex
  /// strings, the human-editable form `fromJson` reads back. Round-trips.
  Map<String, dynamic> toJson() => {
    'venueName': venueName,
    'backgroundColor': colorToHex(backgroundColor),
    'surfaceColor': colorToHex(surfaceColor),
    'lightBackgroundColor': colorToHex(lightBackgroundColor),
    'lightSurfaceColor': colorToHex(lightSurfaceColor),
    'primaryColor': colorToHex(primaryColor),
    'accentColor': colorToHex(accentColor),
    if (displayFont != null) 'displayFont': displayFont,
    'alternatingCategoryBands': alternatingCategoryBands,
  };

  Branding copyWith({
    String? venueName,
    int? backgroundColor,
    int? surfaceColor,
    int? lightBackgroundColor,
    int? lightSurfaceColor,
    int? primaryColor,
    int? accentColor,
    String? displayFont,
    bool? alternatingCategoryBands,
  }) => Branding(
    venueName: venueName ?? this.venueName,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    surfaceColor: surfaceColor ?? this.surfaceColor,
    lightBackgroundColor: lightBackgroundColor ?? this.lightBackgroundColor,
    lightSurfaceColor: lightSurfaceColor ?? this.lightSurfaceColor,
    primaryColor: primaryColor ?? this.primaryColor,
    accentColor: accentColor ?? this.accentColor,
    displayFont: displayFont ?? this.displayFont,
    alternatingCategoryBands:
        alternatingCategoryBands ?? this.alternatingCategoryBands,
  );
}

/// Neutral light-mode defaults, used when a config predates the light pair.
const int _defaultLightBackground = 0xFFF7F5F2;
const int _defaultLightSurface = 0xFFFFFFFF;

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

  factory TableNumberPolicy.fromJson(Map<String, dynamic> json) =>
      TableNumberPolicy(
        min: (json['min'] as num?)?.toInt() ?? AppConstants.tableNumberMin,
        max: (json['max'] as num?)?.toInt() ?? AppConstants.tableNumberMax,
      );

  Map<String, dynamic> toJson() => {'min': min, 'max': max};

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

  /// The codes that unlock the staff and owner surfaces, until real auth
  /// (Ebriza). Config-driven, so each venue sets its own.
  final String staffAccessCode;
  final String ownerAccessCode;

  /// The loyalty program (points + reward ladder). Empty by default, so a venue
  /// that runs no loyalty scheme shows no rewards.
  final LoyaltyProgram loyaltyProgram;

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
    this.staffAccessCode = '0000',
    this.ownerAccessCode = '0000',
    this.loyaltyProgram = const LoyaltyProgram(),
  });

  /// Reads a venue config from JSON, so a venue is DATA (an asset now, our
  /// backend later) rather than a compile-time constant. Optional fields fall
  /// back to the same defaults as the constructor. `backendBaseUrl` is a
  /// deployment concern overlaid at load time, so it defaults to empty here.
  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
    venueId: json['venueId'] as String,
    branding: Branding.fromJson(json['branding'] as Map<String, dynamic>),
    tablePolicy: json['tablePolicy'] == null
        ? const TableNumberPolicy()
        : TableNumberPolicy.fromJson(
            json['tablePolicy'] as Map<String, dynamic>,
          ),
    menuAsset: json['menuAsset'] as String,
    featureFlags:
        (json['featureFlags'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as bool),
        ) ??
        const {},
    notificationTarget: _notificationTargetFromName(
      json['notificationTarget'] as String?,
    ),
    acceptanceMode: _acceptanceModeFromName(json['acceptanceMode'] as String?),
    requireCustomerName: json['requireCustomerName'] as bool? ?? false,
    backendBaseUrl: json['backendBaseUrl'] as String? ?? '',
    staffAccessCode: json['staffAccessCode'] as String? ?? _defaultAccessCode,
    ownerAccessCode: json['ownerAccessCode'] as String? ?? _defaultAccessCode,
    loyaltyProgram: json['loyaltyProgram'] == null
        ? const LoyaltyProgram()
        : LoyaltyProgram.fromJson(
            json['loyaltyProgram'] as Map<String, dynamic>,
          ),
  );

  /// The inverse of [AppConfig.fromJson]. Writes the same document shape the
  /// factory reads, so a config round-trips through the owner Settings screen and
  /// the backend. `backendBaseUrl` is a deployment overlay, not venue data, so it
  /// is left out (the factory defaults it and the loader overlays it). The staff
  /// and owner access codes are secrets, not customer-facing config, so they are
  /// left out too: they never travel on a write or sit in the stored document, so
  /// the open read cannot leak them (REQ-SEC-008). The backend verifies codes from
  /// its own staff auth store. The offline mock reads them from the bundled asset
  /// (the factory still parses them).
  Map<String, dynamic> toJson() => {
    'venueId': venueId,
    'branding': branding.toJson(),
    'tablePolicy': tablePolicy.toJson(),
    'menuAsset': menuAsset,
    'featureFlags': featureFlags,
    'notificationTarget': notificationTarget.name,
    'acceptanceMode': acceptanceMode.name,
    'requireCustomerName': requireCustomerName,
    'loyaltyProgram': loyaltyProgram.toJson(),
  };

  /// A copy with selected fields replaced. Used to overlay the deployment
  /// `backendBaseUrl` at load time, and by the owner Settings screen later.
  AppConfig copyWith({
    String? venueId,
    Branding? branding,
    TableNumberPolicy? tablePolicy,
    String? menuAsset,
    Map<String, bool>? featureFlags,
    NotificationTarget? notificationTarget,
    AcceptanceMode? acceptanceMode,
    bool? requireCustomerName,
    String? backendBaseUrl,
    String? staffAccessCode,
    String? ownerAccessCode,
    LoyaltyProgram? loyaltyProgram,
  }) => AppConfig(
    venueId: venueId ?? this.venueId,
    branding: branding ?? this.branding,
    tablePolicy: tablePolicy ?? this.tablePolicy,
    menuAsset: menuAsset ?? this.menuAsset,
    featureFlags: featureFlags ?? this.featureFlags,
    notificationTarget: notificationTarget ?? this.notificationTarget,
    acceptanceMode: acceptanceMode ?? this.acceptanceMode,
    requireCustomerName: requireCustomerName ?? this.requireCustomerName,
    backendBaseUrl: backendBaseUrl ?? this.backendBaseUrl,
    staffAccessCode: staffAccessCode ?? this.staffAccessCode,
    ownerAccessCode: ownerAccessCode ?? this.ownerAccessCode,
    loyaltyProgram: loyaltyProgram ?? this.loyaltyProgram,
  );

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
      lightBackgroundColor: 0xFFF7F5F2, // warm neutral for light mode
      lightSurfaceColor: 0xFFFFFFFF, // white cards in light mode
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
    staffAccessCode: '2468',
    ownerAccessCode: '1357',
    // 1 point per leu spent. Reward text is venue content (stays as written).
    loyaltyProgram: LoyaltyProgram(
      tiers: [
        RewardTier(thresholdPoints: 100, reward: 'O bere din partea casei'),
        RewardTier(thresholdPoints: 250, reward: 'Un platou la alegere'),
        RewardTier(thresholdPoints: 500, reward: 'Reducere 20% la comandă'),
      ],
    ),
  );
}

/// The access code assumed when a venue config omits one.
const String _defaultAccessCode = '0000';

/// Base for parsing a hex colour string (`0xAARRGGBB` / `#AARRGGBB`).
const int _hexRadix = 16;

/// Reads a colour that may be a raw int or a hex string, so a venue config is
/// human-editable (`"0xFF2A2A2C"`) as well as machine-writable.
int _parseColor(Object? value) {
  if (value is num) return value.toInt();
  final text = (value as String).replaceFirst('0x', '').replaceFirst('#', '');
  return int.parse(text, radix: _hexRadix);
}

/// The number of hex digits in an `AARRGGBB` colour.
const int _argbHexDigits = 8;

/// The inverse of [_parseColor]: an `0xAARRGGBB` int to its `0x`-prefixed,
/// 8-digit, upper-case hex string, so a written config reads back identically.
String colorToHex(int argb) =>
    '0x${argb.toRadixString(_hexRadix).toUpperCase().padLeft(_argbHexDigits, '0')}';

/// Parses a [NotificationTarget] from its name, defaulting to [both] for an
/// unknown or missing value (forgiving of a hand-edited config).
NotificationTarget _notificationTargetFromName(String? name) =>
    NotificationTarget.values.firstWhere(
      (target) => target.name == name,
      orElse: () => NotificationTarget.both,
    );

/// Parses an [AcceptanceMode] from its name, defaulting to [auto] for an unknown
/// or missing value.
AcceptanceMode _acceptanceModeFromName(String? name) => AcceptanceMode.values
    .firstWhere((mode) => mode.name == name, orElse: () => AcceptanceMode.auto);
