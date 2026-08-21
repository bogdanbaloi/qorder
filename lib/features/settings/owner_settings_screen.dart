import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import 'brand_palette.dart';
import 'language_controller.dart';
import 'language_toggle.dart';
import 'owner_settings_controller.dart';

const double _swatchSize = 44;
const double _swatchRadius = 8;
const double _swatchGap = 10;
const double _previewOuterRadius = 12;
const double _previewInnerRadius = 8;
const double _previewInnerPadding = 14;
const double _previewTitleSize = 18;
const double _spinnerSize = 18;
const double _selectedRingWidth = 3;

/// The owner Settings screen: edit the venue name and pick brand colours from a
/// palette (no hex typing), see a live preview and save. The write side of the
/// venue config, so a change persists server-side and takes effect with no app
/// release. The View is thin: it reads [ownerSettingsControllerProvider] and
/// forwards edits to it (MVVM).
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
        actions: const [LanguageToggle()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Preview(branding: draft, label: s.settingsPreview),
          const SizedBox(height: 20),
          TextFormField(
            initialValue: draft.venueName,
            decoration: InputDecoration(
              labelText: s.venueNameLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: controller.setVenueName,
          ),
          const SizedBox(height: 20),
          Text(
            s.brandColorsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          _ColorRow(
            label: s.colorBackground,
            value: draft.backgroundColor,
            onPick: (c) => controller.setColor(BrandColor.background, c),
          ),
          _ColorRow(
            label: s.colorSurface,
            value: draft.surfaceColor,
            onPick: (c) => controller.setColor(BrandColor.surface, c),
          ),
          _ColorRow(
            label: s.colorPrimary,
            value: draft.primaryColor,
            onPick: (c) => controller.setColor(BrandColor.primary, c),
          ),
          _ColorRow(
            label: s.colorAccent,
            value: draft.accentColor,
            onPick: (c) => controller.setColor(BrandColor.accent, c),
          ),
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

/// One editable brand colour: its label, the current colour as a large swatch,
/// and a tap that opens the palette picker. Owner-friendly, no hex.
class _ColorRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onPick;

  const _ColorRow({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          InkWell(
            borderRadius: BorderRadius.circular(_swatchRadius),
            onTap: () => _openPicker(context),
            child: _Swatch(color: value, selected: false),
          ),
        ],
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _PaletteSheet(
        title: label,
        selected: value,
        onPick: (color) {
          onPick(color);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

/// The palette grid shown in the bottom sheet. Tapping a swatch picks it.
class _PaletteSheet extends StatelessWidget {
  final String title;
  final int selected;
  final ValueChanged<int> onPick;

  const _PaletteSheet({
    required this.title,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: _swatchGap,
              runSpacing: _swatchGap,
              children: [
                for (final color in brandPalette)
                  InkWell(
                    key: ValueKey('swatch_$color'),
                    borderRadius: BorderRadius.circular(_swatchRadius),
                    onTap: () => onPick(color),
                    child: _Swatch(color: color, selected: color == selected),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A single colour square. A ring marks the currently selected one.
class _Swatch extends StatelessWidget {
  final int color;
  final bool selected;

  const _Swatch({required this.color, required this.selected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: _swatchSize,
      height: _swatchSize,
      decoration: BoxDecoration(
        color: Color(color),
        borderRadius: BorderRadius.circular(_swatchRadius),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? _selectedRingWidth : 1,
        ),
      ),
      child: selected
          ? Icon(Icons.check, color: scheme.onPrimary, size: _swatchSize / 2)
          : null,
    );
  }
}

/// A small live preview of the venue colours, so the owner sees the effect
/// before saving.
class _Preview extends StatelessWidget {
  final Branding branding;
  final String label;

  const _Preview({required this.branding, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(branding.backgroundColor),
            borderRadius: BorderRadius.circular(_previewOuterRadius),
          ),
          child: Container(
            padding: const EdgeInsets.all(_previewInnerPadding),
            decoration: BoxDecoration(
              color: Color(branding.surfaceColor),
              borderRadius: BorderRadius.circular(_previewInnerRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  branding.venueName,
                  style: TextStyle(
                    color: Color(branding.primaryColor),
                    fontWeight: FontWeight.bold,
                    fontSize: _previewTitleSize,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(branding.accentColor),
                    borderRadius: BorderRadius.circular(_swatchRadius),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
