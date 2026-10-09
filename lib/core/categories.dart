/// App-provided photo categories (ISKELET F12); the user picks at most one.
///
/// The stored id is [name], so values may be appended but never renamed.
enum PhotoCategory {
  food(0xFFF97316),
  view(0xFF0EA5E9),
  travel(0xFF6366F1),
  family(0xFFEC4899),
  friends(0xFFF59E0B),
  pet(0xFFB45309),
  nature(0xFF22C55E),
  sport(0xFFEF4444),
  work(0xFF64748B),
  study(0xFF8B5CF6),
  celebration(0xFFD946EF),
  love(0xFFE11D48),
  home(0xFF14B8A6),
  art(0xFF0891B2),
  music(0xFF7C3AED),
  me(0xFF84CC16);

  const PhotoCategory(this.colorValue);

  /// ARGB colour of the category.
  final int colorValue;

  /// Value stored in the database.
  String get id => name;

  /// Category for a stored [id]; `null` when empty or unknown.
  static PhotoCategory? fromId(String? id) {
    for (final c in values) {
      if (c.id == id) return c;
    }
    return null;
  }
}
