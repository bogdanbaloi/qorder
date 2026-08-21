import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../di/providers.dart';

/// Which brand colour an edit targets, so one setter covers all four.
enum BrandColor { background, surface, primary, accent }

/// The owner Settings view state: the edited [Branding] draft plus the save
/// lifecycle. Immutable, so the View rebuilds from a new value (MVVM).
@immutable
class OwnerSettingsState {
  final Branding draft;
  final bool saving;
  final bool savedOk;
  final bool saveFailed;

  const OwnerSettingsState({
    required this.draft,
    this.saving = false,
    this.savedOk = false,
    this.saveFailed = false,
  });

  OwnerSettingsState copyWith({
    Branding? draft,
    bool? saving,
    bool? savedOk,
    bool? saveFailed,
  }) => OwnerSettingsState(
    draft: draft ?? this.draft,
    saving: saving ?? this.saving,
    savedOk: savedOk ?? this.savedOk,
    saveFailed: saveFailed ?? this.saveFailed,
  );
}

/// The owner Settings ViewModel. Seeds a draft from the active venue's current
/// branding, edits it and saves through [venueConfigApiProvider] (the backend
/// when configured, else the in-memory mock). On save it re-fetches, so the
/// draft reflects exactly what persisted.
class OwnerSettingsController extends Notifier<OwnerSettingsState> {
  @override
  OwnerSettingsState build() =>
      OwnerSettingsState(draft: ref.read(appConfigProvider).branding);

  void setVenueName(String name) => state = state.copyWith(
    draft: state.draft.copyWith(venueName: name),
    savedOk: false,
    saveFailed: false,
  );

  void setColor(BrandColor which, int argb) {
    final draft = switch (which) {
      BrandColor.background => state.draft.copyWith(backgroundColor: argb),
      BrandColor.surface => state.draft.copyWith(surfaceColor: argb),
      BrandColor.primary => state.draft.copyWith(primaryColor: argb),
      BrandColor.accent => state.draft.copyWith(accentColor: argb),
    };
    state = state.copyWith(draft: draft, savedOk: false, saveFailed: false);
  }

  Future<void> save() async {
    final cfg = ref.read(appConfigProvider);
    state = state.copyWith(saving: true, savedOk: false, saveFailed: false);
    try {
      final api = ref.read(venueConfigApiProvider);
      await api.save(cfg.venueId, cfg.copyWith(branding: state.draft));
      // Re-read, so the draft shows exactly what the backend now holds.
      final confirmed = await api.fetch(cfg.venueId);
      state = state.copyWith(
        saving: false,
        savedOk: true,
        draft: confirmed?.branding ?? state.draft,
      );
    } on Object catch (_) {
      state = state.copyWith(saving: false, saveFailed: true);
    }
  }
}

final ownerSettingsControllerProvider =
    NotifierProvider.autoDispose<OwnerSettingsController, OwnerSettingsState>(
      OwnerSettingsController.new,
    );
