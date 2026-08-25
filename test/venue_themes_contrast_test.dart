import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/features/settings/venue_themes.dart';

// WCAG relative luminance + contrast ratio, computed (not eyeballed), so a badly
// readable theme fails the build instead of shipping.
double _channel(int c) {
  final s = c / 255.0;
  return s <= 0.03928 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(int argb) {
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return 0.2126 * _channel(r) + 0.7152 * _channel(g) + 0.0722 * _channel(b);
}

double _contrast(int a, int b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = max(la, lb);
  final lo = min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // REQ-CFG-007: every curated theme is readable, so the owner cannot land on an
  // unreadable palette (which raw colour pickers allowed).
  for (final theme in venueThemes) {
    test('theme "${theme.name}" is readable', () {
      // The app derives text colour from the background brightness.
      final dark =
          ThemeData.estimateBrightnessForColor(Color(theme.background)) ==
          Brightness.dark;
      const white = 0xFFFFFF;
      const black = 0x000000;
      final text = dark ? white : black;

      // Body text on the background: the 4.5 AA floor.
      expect(
        _contrast(text, theme.background),
        greaterThanOrEqualTo(4.5),
        reason: 'text on background',
      );
      // Body text on cards (surface).
      expect(
        _contrast(text, theme.surface),
        greaterThanOrEqualTo(4.5),
        reason: 'text on surface',
      );
      // The primary accent titles sit on the surface: the 3.0 large-text floor.
      expect(
        _contrast(theme.primary, theme.surface),
        greaterThanOrEqualTo(3.0),
        reason: 'primary on surface',
      );
    });
  }
}
