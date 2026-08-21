import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/i18n/app_strings.dart';
import 'language_controller.dart';
import 'language_toggle.dart';
import 'owner_settings_controller.dart';

const double _swatchSize = 36;
const double _swatchRadius = 6;
const double _previewOuterRadius = 12;
const double _previewInnerRadius = 8;
const double _previewInnerPadding = 14;
const double _previewTitleSize = 18;
const double _spinnerSize = 18;

/// The owner Settings screen: edit the venue name and brand colours, see a live
/// preview and save. The write side of the venue config, so a change persists
/// server-side and takes effect with no app release. The View is thin: it reads
/// [ownerSettingsControllerProvider] and forwards edits to it (MVVM).
class OwnerSettingsScreen extends ConsumerStatefulWidget {
  const OwnerSettingsScreen({super.key});

  @override
  ConsumerState<OwnerSettingsScreen> createState() =>
      _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends ConsumerState<OwnerSettingsScreen> {
  final _invalid = <BrandColor>{};

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 8),
          _colorField(
            s,
            controller,
            BrandColor.background,
            s.colorBackground,
            draft.backgroundColor,
          ),
          _colorField(
            s,
            controller,
            BrandColor.surface,
            s.colorSurface,
            draft.surfaceColor,
          ),
          _colorField(
            s,
            controller,
            BrandColor.primary,
            s.colorPrimary,
            draft.primaryColor,
          ),
          _colorField(
            s,
            controller,
            BrandColor.accent,
            s.colorAccent,
            draft.accentColor,
          ),
          const SizedBox(height: 20),
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

  Widget _colorField(
    AppStrings s,
    OwnerSettingsController controller,
    BrandColor which,
    String label,
    int value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: _swatchSize,
            height: _swatchSize,
            decoration: BoxDecoration(
              color: Color(value),
              borderRadius: BorderRadius.circular(_swatchRadius),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: colorToHex(value),
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                errorText: _invalid.contains(which) ? s.colorInvalid : null,
              ),
              onChanged: (text) {
                final parsed = tryParseColorHex(text);
                setState(() {
                  if (parsed == null) {
                    _invalid.add(which);
                  } else {
                    _invalid.remove(which);
                  }
                });
                if (parsed != null) controller.setColor(which, parsed);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(String text, Color color) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Text(text, style: TextStyle(color: color)),
  );
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
