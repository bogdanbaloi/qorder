import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/loyalty/loyalty_program.dart';
import 'app_bar_toggles.dart';
import 'language_controller.dart';
import 'owner_settings_controller.dart';

const double _spinnerSize = 18;
const double _tierGap = 10;
const double _thresholdFieldWidth = 92;
const double _cardRadius = 12;
const double _cardPadding = 16;
const double _previewTitleSize = 18;
const double _badgeRadius = 8;

/// The owner Settings screen: edit the venue name and the loyalty program, and
/// save. The venue palette is not edited here (it is an operator concern, a
/// bespoke look is a paid service, ADR-0064). Light and dark are a per-user
/// choice on the top bar. The View is thin: it reads
/// [ownerSettingsControllerProvider] and forwards edits to it (MVVM).
class OwnerSettingsScreen extends ConsumerWidget {
  const OwnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final state = ref.watch(ownerSettingsControllerProvider);
    final controller = ref.read(ownerSettingsControllerProvider.notifier);
    final draft = state.draft;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.settingsTitle),
        actions: const [AppBarToggles()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Preview(venueName: draft.venueName, label: s.settingsPreview),
          const SizedBox(height: 20),
          TextFormField(
            initialValue: draft.venueName,
            decoration: InputDecoration(
              labelText: s.venueNameLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: controller.setVenueName,
          ),
          const SizedBox(height: 24),
          _Note(title: s.appearanceTitle, body: s.appearanceHint),
          const SizedBox(height: 16),
          _Note(title: s.customDesignTitle, body: s.customDesignHint),
          const SizedBox(height: 24),
          const _LoyaltySection(),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.saving ? null : controller.save,
            child: state.saving
                ? const SizedBox(
                    height: _spinnerSize,
                    width: _spinnerSize,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(s.saveSettings),
          ),
          if (state.savedOk)
            _message(s.settingsSaved, Theme.of(context).colorScheme.primary),
          if (state.saveFailed)
            _message(s.settingsSaveFailed, Theme.of(context).colorScheme.error),
        ],
      ),
    );
  }

  Widget _message(String text, Color color) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Text(text, style: TextStyle(color: color)),
  );
}

/// A titled explanatory card. Used for the settings the owner does not edit here
/// (appearance and bespoke design), so the screen says where each lives.
class _Note extends StatelessWidget {
  final String title;
  final String body;

  const _Note({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// The loyalty editor: points-per-unit plus the reward ladder (threshold and
/// text per tier, add and remove). Stateful, so each field keeps a text
/// controller synced to the ViewModel, which avoids cursor jumps while editing
/// a list that grows and shrinks.
class _LoyaltySection extends ConsumerStatefulWidget {
  const _LoyaltySection();

  @override
  ConsumerState<_LoyaltySection> createState() => _LoyaltySectionState();
}

class _LoyaltySectionState extends ConsumerState<_LoyaltySection> {
  final _points = TextEditingController();
  final _thresholds = <TextEditingController>[];
  final _rewards = <TextEditingController>[];

  @override
  void dispose() {
    _points.dispose();
    for (final c in _thresholds) {
      c.dispose();
    }
    for (final c in _rewards) {
      c.dispose();
    }
    super.dispose();
  }

  // Keep the field controllers in step with the ViewModel by value, so a live
  // edit does not reset the cursor and an add or remove shifts text correctly.
  void _sync(LoyaltyProgram loyalty) {
    final rate = '${loyalty.pointsPerMajorUnit}';
    if (_points.text != rate) _points.text = rate;
    final tiers = loyalty.tiers;
    while (_thresholds.length < tiers.length) {
      _thresholds.add(TextEditingController());
      _rewards.add(TextEditingController());
    }
    while (_thresholds.length > tiers.length) {
      _thresholds.removeLast().dispose();
      _rewards.removeLast().dispose();
    }
    for (var i = 0; i < tiers.length; i++) {
      final threshold = '${tiers[i].thresholdPoints}';
      if (_thresholds[i].text != threshold) _thresholds[i].text = threshold;
      if (_rewards[i].text != tiers[i].reward) {
        _rewards[i].text = tiers[i].reward;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final loyalty = ref.watch(
      ownerSettingsControllerProvider.select((state) => state.loyalty),
    );
    final controller = ref.read(ownerSettingsControllerProvider.notifier);
    _sync(loyalty);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.loyaltyTitle, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        TextField(
          controller: _points,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: s.pointsPerUnitLabel,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => controller.setPointsRate(int.tryParse(v) ?? 1),
        ),
        const SizedBox(height: 12),
        if (loyalty.tiers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(s.noRewardsYet, style: TextStyle(color: muted)),
          ),
        for (var i = 0; i < loyalty.tiers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: _tierGap),
            child: Row(
              children: [
                SizedBox(
                  width: _thresholdFieldWidth,
                  child: TextField(
                    controller: _thresholds[i],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.rewardThresholdLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => controller.updateTier(
                      i,
                      thresholdPoints: int.tryParse(v) ?? 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _rewards[i],
                    decoration: InputDecoration(
                      labelText: s.rewardLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => controller.updateTier(i, reward: v),
                  ),
                ),
                IconButton(
                  tooltip: s.removeReward,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => controller.removeTier(i),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: controller.addTier,
            icon: const Icon(Icons.add),
            label: Text(s.addReward),
          ),
        ),
      ],
    );
  }
}

/// A small live preview of the venue name in the active theme, so the owner sees
/// the current look (which follows the light/dark choice and the venue palette).
class _Preview extends StatelessWidget {
  final String venueName;
  final String label;

  const _Preview({required this.venueName, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(_cardPadding),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                venueName,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: _previewTitleSize,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.secondary,
                  borderRadius: BorderRadius.circular(_badgeRadius),
                ),
                child: Text(
                  'NEW',
                  style: TextStyle(
                    color: scheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
