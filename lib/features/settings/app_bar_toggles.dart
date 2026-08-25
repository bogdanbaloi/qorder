import 'package:flutter/material.dart';

import 'language_toggle.dart';
import 'theme_mode_toggle.dart';

/// The standard app-bar controls every surface shares: light/dark mode then
/// language. One widget, so a new global control is added in a single place
/// rather than edited into every screen.
class AppBarToggles extends StatelessWidget {
  const AppBarToggles({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [ThemeModeToggle(), LanguageToggle()],
  );
}
