import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// REQ-PWA-001: the web app is installable (add to home screen) and branded, so a
/// venue owner or staff can put it on their phone and it looks like an app.
void main() {
  test('the web manifest is installable and branded', () {
    final manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;

    // Installable, full-screen (no browser chrome).
    expect(manifest['display'], 'standalone');
    expect(manifest['name'], 'qorder');
    expect(manifest['icons'] as List, isNotEmpty);
    // Real content, not the Flutter template defaults.
    expect(manifest['description'], isNot('A new Flutter project.'));
    expect(manifest['theme_color'], isNot('#0175C2'));
  });

  test('index.html carries the install and mobile meta tags', () {
    final html = File('web/index.html').readAsStringSync();

    expect(html, contains('rel="manifest"'));
    expect(html, contains('name="theme-color"'));
    expect(html, contains('name="viewport"'));
    // Full-screen install on iOS and Android.
    expect(html, contains('apple-mobile-web-app-capable'));
    expect(html, contains('mobile-web-app-capable'));
    expect(html, isNot(contains('A new Flutter project.')));
  });
}
