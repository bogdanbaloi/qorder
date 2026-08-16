import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/strings_en.dart';
import '../../core/i18n/strings_ro.dart';
import '../../di/providers.dart';

/// The current UI language. Defaults to Romanian, restored from storage on
/// launch and persisted on change, so a returning customer keeps their choice.
class LanguageController extends Notifier<AppLanguage> {
  static const _box = 'settings';
  static const _key = 'language';

  @override
  AppLanguage build() {
    unawaited(_restore());
    return AppLanguage.ro;
  }

  Future<void> _restore() async {
    final stored = await ref.read(localStoreProvider).get(_box, _key);
    final code = stored?['code'] as String?;
    if (code != null) state = AppLanguage.fromCode(code);
  }

  void set(AppLanguage language) {
    state = language;
    unawaited(
      ref.read(localStoreProvider).put(_box, _key, {'code': language.code}),
    );
  }

  void toggle() =>
      set(state == AppLanguage.ro ? AppLanguage.en : AppLanguage.ro);
}

final languageProvider = NotifierProvider<LanguageController, AppLanguage>(
  LanguageController.new,
);

/// The string table for the current language. Widgets watch this and read
/// labels off it, so no widget hard-codes a language.
final stringsProvider = Provider<AppStrings>((ref) {
  final language = ref.watch(languageProvider);
  return switch (language) {
    AppLanguage.ro => const StringsRo(),
    AppLanguage.en => const StringsEn(),
  };
});
