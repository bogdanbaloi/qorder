import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'language_controller.dart';
import 'theme_mode_controller.dart';

/// A light/dark toggle for an app bar. Shown on every surface (customer, staff,
/// owner) so each user picks their own mode (REQ-CFG-008). It flips to the
/// opposite of what is on screen now, so one tap always changes the look even
/// when the app is following the system.
class ThemeModeToggle extends ConsumerWidget {
  const ThemeModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? s.themeModeLight : s.themeModeDark,
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref
          .read(themeModeProvider.notifier)
          .set(isDark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}
