import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/app/theme.dart';
import 'package:qorder/core/config/app_config.dart';
import 'package:qorder/features/settings/theme_mode_controller.dart';

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

void main() {
  final branding = AppConfig.demo.branding;

  // REQ-CFG-008: the theme is built for a light and a dark mode from the same
  // venue accent, so each stays readable (Material 3 derives the surfaces).
  test('both modes are readable and distinct', () {
    for (final mode in Brightness.values) {
      final scheme = buildTheme(branding, mode).colorScheme;
      expect(scheme.brightness, mode);
      // Body text on the surface.
      expect(
        _contrast(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      // Label text on a filled primary control (e.g. the Save button).
      expect(
        _contrast(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(3.0),
      );
      // Headings and prices are drawn in the brand primary on the surface.
      expect(
        _contrast(scheme.primary, scheme.surface),
        greaterThanOrEqualTo(3.0),
      );
    }

    final light = buildTheme(branding, Brightness.light).colorScheme.surface;
    final dark = buildTheme(branding, Brightness.dark).colorScheme.surface;
    expect(light, isNot(dark));
  });

  // REQ-CFG-008: the mode is a per-user choice, following the system by default
  // and switchable, so owner and customer each set their own look.
  test('theme mode follows the system by default and switches', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);

    container.read(themeModeProvider.notifier).set(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    container.read(themeModeProvider.notifier).set(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
