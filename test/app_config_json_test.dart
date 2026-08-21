import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/config/app_config.dart';

/// REQ-CFG-004: a config round-trips through toJson/fromJson, so the owner
/// Settings screen and the backend read back exactly what was written.
void main() {
  test('AppConfig round-trips through toJson and fromJson', () {
    // Start from the demo, but drop the deployment overlay (not venue data).
    final original = AppConfig.demo.copyWith(backendBaseUrl: '');
    final restored = AppConfig.fromJson(original.toJson());

    expect(restored.venueId, original.venueId);
    expect(restored.branding.venueName, original.branding.venueName);
    expect(
      restored.branding.backgroundColor,
      original.branding.backgroundColor,
    );
    expect(restored.branding.surfaceColor, original.branding.surfaceColor);
    expect(restored.branding.primaryColor, original.branding.primaryColor);
    expect(restored.branding.accentColor, original.branding.accentColor);
    expect(restored.branding.displayFont, original.branding.displayFont);
    expect(
      restored.branding.alternatingCategoryBands,
      original.branding.alternatingCategoryBands,
    );
    expect(restored.tablePolicy.min, original.tablePolicy.min);
    expect(restored.tablePolicy.max, original.tablePolicy.max);
    expect(restored.menuAsset, original.menuAsset);
    expect(restored.acceptanceMode, original.acceptanceMode);
    expect(restored.requireCustomerName, original.requireCustomerName);
    expect(restored.staffAccessCode, original.staffAccessCode);
    expect(restored.ownerAccessCode, original.ownerAccessCode);
    expect(
      restored.loyaltyProgram.tiers.length,
      original.loyaltyProgram.tiers.length,
    );
    expect(
      restored.loyaltyProgram.tiers.first.reward,
      original.loyaltyProgram.tiers.first.reward,
    );
  });

  test('colours are written as readable 0xAARRGGBB hex', () {
    final json = AppConfig.demo.branding.toJson();
    expect(json['primaryColor'], '0xFFF26A21');
    expect(json['backgroundColor'], '0xFF2A2A2C');
  });
}
