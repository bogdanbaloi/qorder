import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result.dart';
import '../../di/providers.dart';
import '../../domain/models/menu.dart';

/// Presentation-layer entry point for the menu. The View watches this and
/// never talks to the repository directly (UI independent of data source).
final menuProvider = FutureProvider<Menu>((ref) async {
  final repo = ref.watch(menuRepositoryProvider);
  final cfg = ref.watch(appConfigProvider);
  final result = await repo.loadMenu(cfg.venueId);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final message) => throw Exception(message),
  };
});
