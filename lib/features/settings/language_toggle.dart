import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'language_controller.dart';

/// A small RO/EN toggle for an app bar. Shown on every surface (customer, staff,
/// owner) so each can switch language independently of the others.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    // The app-bar foreground colour, so the label stays readable in light and
    // dark alike (a hard-coded white vanished on a light bar).
    final onBar = Theme.of(context).colorScheme.onSurface;
    return TextButton(
      onPressed: () => ref.read(languageProvider.notifier).toggle(),
      child: Text(
        language.label,
        style: TextStyle(color: onBar, fontWeight: FontWeight.bold),
      ),
    );
  }
}
