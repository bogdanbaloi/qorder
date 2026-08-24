import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../di/providers.dart';
import '../../domain/identity/session_expired.dart';
import '../../domain/loyalty/loyalty_program.dart';
import '../../domain/loyalty/reward_tier.dart';
import '../session/session_controller.dart';

/// Which brand colour an edit targets, so one setter covers all four.
enum BrandColor { background, surface, primary, accent }

/// The owner Settings view state: the edited [Branding] draft plus the save
/// lifecycle. Immutable, so the View rebuilds from a new value (MVVM).
@immutable
class OwnerSettingsState {
  final Branding draft;
  final LoyaltyProgram loyalty;
  final bool saving;
  final bool savedOk;
  final bool saveFailed;

  const OwnerSettingsState({
    required this.draft,
    required this.loyalty,
    this.saving = false,
    this.savedOk = false,
    this.saveFailed = false,
  });

  OwnerSettingsState copyWith({
    Branding? draft,
    LoyaltyProgram? loyalty,
    bool? saving,
    bool? savedOk,
    bool? saveFailed,
  }) => OwnerSettingsState(
    draft: draft ?? this.draft,
    loyalty: loyalty ?? this.loyalty,
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
  OwnerSettingsState build() {
    final cfg = ref.read(appConfigProvider);
    return OwnerSettingsState(draft: cfg.branding, loyalty: cfg.loyaltyProgram);
  }

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

  void setPointsRate(int rate) => _setLoyalty(
    state.loyalty.copyWith(pointsPerMajorUnit: rate < 1 ? 1 : rate),
  );

  void addTier() => _setLoyalty(
    state.loyalty.copyWith(
      tiers: [
        ...state.loyalty.tiers,
        const RewardTier(thresholdPoints: 100, reward: ''),
      ],
    ),
  );

  void updateTier(int index, {int? thresholdPoints, String? reward}) {
    final tiers = [...state.loyalty.tiers];
    tiers[index] = tiers[index].copyWith(
      thresholdPoints: thresholdPoints,
      reward: reward,
    );
    _setLoyalty(state.loyalty.copyWith(tiers: tiers));
  }

  void removeTier(int index) {
    final tiers = [...state.loyalty.tiers]..removeAt(index);
    _setLoyalty(state.loyalty.copyWith(tiers: tiers));
  }

  void _setLoyalty(LoyaltyProgram loyalty) => state = state.copyWith(
    loyalty: loyalty,
    savedOk: false,
    saveFailed: false,
  );

  Future<void> save() async {
    final cfg = ref.read(appConfigProvider);
    final updated = cfg.copyWith(
      branding: state.draft,
      loyaltyProgram: state.loyalty,
    );
    state = state.copyWith(saving: true, savedOk: false, saveFailed: false);
    try {
      final api = ref.read(venueConfigApiProvider);
      await api.save(cfg.venueId, updated);
      // Apply live to the running app, so the edit shows without a reload.
      ref.read(liveVenueConfigProvider.notifier).set(updated);
      // Re-read, so the draft shows exactly what the backend now holds.
      final confirmed = await api.fetch(cfg.venueId);
      state = state.copyWith(
        saving: false,
        savedOk: true,
        draft: confirmed?.branding ?? state.draft,
        loyalty: confirmed?.loyaltyProgram ?? state.loyalty,
      );
    } on SessionExpiredException {
      // The token is dead: drop the session, so the guard shows the code gate
      // and the owner re-authenticates instead of a stuck "could not save".
      state = state.copyWith(saving: false);
      ref.read(sessionProvider.notifier).signOut();
    } on Object catch (_) {
      state = state.copyWith(saving: false, saveFailed: true);
    }
  }
}

final ownerSettingsControllerProvider =
    NotifierProvider.autoDispose<OwnerSettingsController, OwnerSettingsState>(
      OwnerSettingsController.new,
    );
