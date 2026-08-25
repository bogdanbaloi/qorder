import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../settings/venue_palettes.dart';
import 'admin_providers.dart';

/// The save lifecycle for the admin palette picker. Immutable, so the View
/// rebuilds from a new value (MVVM).
@immutable
class AdminPaletteState {
  final bool saving;
  final bool savedOk;
  final bool saveFailed;

  const AdminPaletteState({
    this.saving = false,
    this.savedOk = false,
    this.saveFailed = false,
  });

  AdminPaletteState copyWith({
    bool? saving,
    bool? savedOk,
    bool? saveFailed,
  }) => AdminPaletteState(
    saving: saving ?? this.saving,
    savedOk: savedOk ?? this.savedOk,
    saveFailed: saveFailed ?? this.saveFailed,
  );
}

/// The operator sets the active venue's palette (ADR-0065). It applies the whole
/// palette to the venue's branding, saves it through [venueConfigApiProvider] and
/// pushes it into the session-live override, so the app re-themes at once. The
/// write authenticates as the operator (a superadmin over every venue), so the
/// backend accepts it (ADR-0066). It round-trips offline against the mock.
class AdminPaletteController extends Notifier<AdminPaletteState> {
  @override
  AdminPaletteState build() => const AdminPaletteState();

  Future<void> apply(VenuePalette palette) async {
    final cfg = ref.read(appConfigProvider);
    final updated = cfg.copyWith(branding: palette.applyTo(cfg.branding));
    state = state.copyWith(saving: true, savedOk: false, saveFailed: false);
    try {
      await ref.read(adminVenueConfigApiProvider).save(cfg.venueId, updated);
      // Apply live to the running app, so the palette shows without a reload.
      ref.read(liveVenueConfigProvider.notifier).set(updated);
      state = state.copyWith(saving: false, savedOk: true);
    } on Object catch (_) {
      state = state.copyWith(saving: false, saveFailed: true);
    }
  }
}

final adminPaletteControllerProvider =
    NotifierProvider.autoDispose<AdminPaletteController, AdminPaletteState>(
      AdminPaletteController.new,
    );
