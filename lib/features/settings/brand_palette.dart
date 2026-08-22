/// A curated set of venue brand colours the owner picks from, so nobody types a
/// hex code. Opaque ARGB ints (`0xFFRRGGBB`). Kept small and tasteful, so venues
/// stay coherent. The order groups neutrals, warm, then cool tones.
const List<int> brandPalette = [
  // Neutrals and darks (backgrounds, cards)
  0xFF0F1115,
  0xFF1E1E20,
  0xFF2A2A2C,
  0xFF3A3A3C,
  0xFF9E9E9E,
  0xFFF5F5F5,
  // Warm (signature accents)
  0xFFF26A21,
  0xFFFF7043,
  0xFFFFC107,
  0xFFFFD400,
  0xFFE53935,
  0xFFD81B60,
  // Cool (secondary accents)
  0xFF8E24AA,
  0xFF5E35B1,
  0xFF3949AB,
  0xFF3AA0FF,
  0xFF039BE5,
  0xFF00ACC1,
  0xFF00897B,
  0xFF43A047,
  0xFF7CB342,
  0xFF6D4C41,
];
