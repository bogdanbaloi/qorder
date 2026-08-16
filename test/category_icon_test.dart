import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/domain/models/menu.dart';
import 'package:qorder/features/menu/category_icon.dart';

Category cat(String name, {String? icon}) =>
    Category(id: 'x', name: name, sortOrder: 0, items: const [], icon: icon);

// REQ-MENU-005: each category shows a drink-type icon (the venue site's SVGs),
// derived from the name or overridden from data.
void main() {
  test('derives an icon by drink type from the name', () {
    expect(categoryIconAsset(cat('COFFEE')), 'assets/icons/coffee1.svg');
    expect(categoryIconAsset(cat('ICED COFFEE')), 'assets/icons/coffee1.svg');
    expect(categoryIconAsset(cat('SOFT DRINKS')), 'assets/icons/coffee1.svg');
    expect(categoryIconAsset(cat('LIVE BEERS')), 'assets/icons/beer1.svg');
    expect(categoryIconAsset(cat('HARD DEAL')), 'assets/icons/beer1.svg');
    expect(categoryIconAsset(cat('VIN ALB')), 'assets/icons/wine1.svg');
    expect(categoryIconAsset(cat('WHISKY')), 'assets/icons/rum-mug1.svg');
    expect(categoryIconAsset(cat('HARD GINS')), 'assets/icons/rum-mug1.svg');
    expect(categoryIconAsset(cat('DEATH DRINKS')), 'assets/icons/shots1.svg');
  });

  test('an explicit icon key overrides the derivation', () {
    expect(
      categoryIconAsset(cat('DEATH DRINKS', icon: 'beer1')),
      'assets/icons/beer1.svg',
    );
  });
}
