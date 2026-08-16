import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/core/i18n/app_strings.dart';
import 'package:qorder/core/i18n/strings_en.dart';
import 'package:qorder/core/i18n/strings_ro.dart';
import 'package:qorder/features/settings/language_controller.dart';

// REQ-I18N-001: the UI language is toggleable (Romanian default), each language
// a separate string table, so adding one never touches a widget.
void main() {
  test('defaults to Romanian', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(languageProvider), AppLanguage.ro);
    expect(container.read(stringsProvider), isA<StringsRo>());
  });

  test('toggle flips to English and back', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(languageProvider.notifier).toggle();
    expect(container.read(languageProvider), AppLanguage.en);
    expect(container.read(stringsProvider), isA<StringsEn>());
    expect(container.read(stringsProvider).addToCart, 'Add to cart');

    container.read(languageProvider.notifier).toggle();
    expect(container.read(languageProvider), AppLanguage.ro);
    expect(container.read(stringsProvider).addToCart, 'Adaugă în coș');
  });

  test('fromCode falls back to Romanian for an unknown code', () {
    expect(AppLanguage.fromCode('en'), AppLanguage.en);
    expect(AppLanguage.fromCode('fr'), AppLanguage.ro);
    expect(AppLanguage.fromCode(null), AppLanguage.ro);
  });

  test('parameterised strings render in both languages', () {
    const ro = StringsRo();
    const en = StringsEn();
    expect(ro.menuTitleForTable(7), 'Meniu · Masa 7');
    expect(en.menuTitleForTable(7), 'Menu · Table 7');
    expect(ro.availableAt('06:00-12:00'), 'disponibil 06:00-12:00');
    expect(en.availableAt('06:00-12:00'), 'available 06:00-12:00');
  });
}
