import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/app/theme.dart';
import 'package:qorder/core/config/app_config.dart';
import 'package:qorder/di/providers.dart';
import 'package:qorder/domain/config/venue_config_api.dart';
import 'package:qorder/features/admin/admin_palette_controller.dart';
import 'package:qorder/features/settings/venue_palettes.dart';

// WCAG relative luminance and contrast ratio, so readability is computed, not
// eyeballed. Floors: 4.5 for body text, 3.0 for large/heading text.
double _channel(double v) =>
    v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

class _RecordingApi implements VenueConfigApi {
  AppConfig? saved;

  @override
  Future<AppConfig?> fetch(String venueId) async => saved;

  @override
  Future<void> save(String venueId, AppConfig config) async {
    saved = config;
  }
}

void main() {
  final base = AppConfig.demo.branding;

  // REQ-CFG-009: every predefined palette stays readable in both modes, so the
  // operator can pick any of them without composing an unreadable mix.
  test('every predefined palette is readable in light and dark', () {
    for (final palette in venuePalettes) {
      final branding = palette.applyTo(base);
      for (final mode in Brightness.values) {
        final scheme = buildTheme(branding, mode).colorScheme;
        final where = '${palette.name} (${mode.name})';
        expect(
          _contrast(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: 'body text on surface, $where',
        );
        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(3.0),
          reason: 'label on primary, $where',
        );
        expect(
          _contrast(scheme.primary, scheme.surface),
          greaterThanOrEqualTo(3.0),
          reason: 'heading on surface, $where',
        );
      }
    }
  });

  // REQ-CFG-009: each mode draws from its own background and surface pair, so a
  // venue keeps its dark and its light look.
  test('each mode uses its own background and surface pair', () {
    final carbon = venuePalettes.firstWhere((p) => p.name == 'Carbon');
    final branding = carbon.applyTo(base);

    final dark = buildTheme(branding, Brightness.dark);
    expect(dark.scaffoldBackgroundColor, Color(carbon.darkBackground));
    expect(dark.colorScheme.surface, Color(carbon.darkSurface));

    final light = buildTheme(branding, Brightness.light);
    expect(light.scaffoldBackgroundColor, Color(carbon.lightBackground));
    expect(light.colorScheme.surface, Color(carbon.lightSurface));
  });

  // REQ-CFG-009: the operator applies a whole palette to the active venue, and it
  // saves through the port and applies live to the running app.
  test('applying a palette saves it and applies live', () async {
    final api = _RecordingApi();
    final container = ProviderContainer(
      overrides: [venueConfigApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    final bordeaux = venuePalettes.firstWhere((p) => p.name == 'Bordeaux');
    await container.read(adminPaletteControllerProvider.notifier).apply(bordeaux);

    expect(api.saved, isNotNull);
    expect(bordeaux.matches(api.saved!.branding), isTrue);
    expect(
      container.read(appConfigProvider).branding.primaryColor,
      bordeaux.accent,
    );
  });
}
