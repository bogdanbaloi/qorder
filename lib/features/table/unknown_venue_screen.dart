import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings.dart';
import '../settings/language_controller.dart';

/// Shown when a QR link names a venue we do not know. A dead end by design: no
/// menu is loaded for an unknown venue, so the customer is asked to rescan
/// rather than being shown a wrong venue's menu.
class UnknownVenueScreen extends ConsumerWidget {
  static const double _iconSize = 56;

  final String? venueId;
  const UnknownVenueScreen({this.venueId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.unknownVenueTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: _iconSize,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                s.unknownVenueTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(s.unknownVenueBody, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
