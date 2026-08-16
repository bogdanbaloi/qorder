import '../../domain/models/menu.dart';

const _iconDir = 'assets/icons';

/// The bundled drink-type icon (the venue site's own SVGs) for a menu category.
/// Uses the category's explicit [Category.icon] key when set, otherwise derives
/// one from the name. Pure, so the mapping is unit-tested and a venue can
/// override any category from data.
String categoryIconAsset(Category category) =>
    '$_iconDir/${category.icon ?? _iconKeyForName(category.name)}.svg';

String _iconKeyForName(String name) {
  final n = name.toUpperCase();
  bool has(List<String> words) => words.any(n.contains);

  if (has(['MORNING', 'COFFEE', 'TEA', 'ICED', 'ESPRESSO'])) return 'coffee1';
  if (has(['SOFT', 'FRESH', 'SUC'])) return 'coffee1';
  if (has(['VIN', 'WINE', 'SPUMANT', 'PROSECCO'])) return 'wine1';
  if (has(['BEER', 'BERE', 'DEAL', 'DRAUGHT', 'PILSNER', 'URSUS'])) {
    return 'beer1';
  }
  if (has([
    'RUM',
    'WHISKY',
    'WHISKEY',
    'VODKA',
    'GIN',
    'COGNAC',
    'BRANDY',
    'LIQUEUR',
    'DIGESTIVE',
    'TEQUILA',
  ])) {
    return 'rum-mug1';
  }
  return 'shots1'; // cocktails, shots, "drinks", metal, brutal, food
}
