import 'package:flutter/material.dart';

import '../../core/categories.dart';
import '../../core/theme.dart';
import 'l10n.dart';
import 'motion.dart';

/// Icon and colour of each [PhotoCategory] (ISKELET F12).
extension PhotoCategoryStyle on PhotoCategory {
  /// Category colour.
  Color get color => Color(colorValue);

  /// Category icon.
  IconData get icon => switch (this) {
    PhotoCategory.food => Icons.restaurant_rounded,
    PhotoCategory.view => Icons.landscape_rounded,
    PhotoCategory.travel => Icons.flight_takeoff_rounded,
    PhotoCategory.family => Icons.family_restroom_rounded,
    PhotoCategory.friends => Icons.groups_rounded,
    PhotoCategory.pet => Icons.pets_rounded,
    PhotoCategory.nature => Icons.park_rounded,
    PhotoCategory.sport => Icons.sports_soccer_rounded,
    PhotoCategory.work => Icons.work_rounded,
    PhotoCategory.study => Icons.school_rounded,
    PhotoCategory.celebration => Icons.celebration_rounded,
    PhotoCategory.love => Icons.favorite_rounded,
    PhotoCategory.home => Icons.weekend_rounded,
    PhotoCategory.art => Icons.palette_rounded,
    PhotoCategory.music => Icons.music_note_rounded,
    PhotoCategory.me => Icons.face_rounded,
  };
}

/// Small coloured circle with the category icon, for grid cells.
class CategoryBadge extends StatelessWidget {
  /// Creates the badge of [category].
  const CategoryBadge({super.key, required this.category, this.size = 16});

  /// Category shown.
  final PhotoCategory category;

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3)],
      ),
      child: Icon(category.icon, size: size * 0.62, color: Colors.white),
    );
  }
}

/// Pill with icon and name; filled with the category colour when selected.
class CategoryChip extends StatelessWidget {
  /// Creates a chip; [onTap] toggles the selection.
  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    this.onTap,
  });

  /// Category shown.
  final PhotoCategory category;

  /// Draws the filled, selected style.
  final bool selected;

  /// Called on tap; `null` makes the chip read-only.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = category.color;
    final foreground = selected ? Colors.white : p.onSurface;
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: PressScale(
        enabled: onTap != null,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.short,
            curve: AppMotion.curve,
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            decoration: BoxDecoration(
              color: selected ? color : color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.35),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.icon,
                  size: 18,
                  color: selected ? Colors.white : color,
                ),
                const SizedBox(width: 6),
                Text(
                  context.strings.categoryName(category),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling single-choice category picker.
///
/// Scrolls the current choice into view when it opens, so a saved
/// category is visible even if it sits at the end of the row.
class CategoryPicker extends StatefulWidget {
  /// Creates the picker; tapping the selected chip clears the choice.
  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Current choice.
  final PhotoCategory? selected;

  /// Called with the new choice, `null` when cleared.
  final ValueChanged<PhotoCategory?> onChanged;

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.selected == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _selectedKey.currentContext;
      if (target != null && mounted) {
        Scrollable.ensureVisible(target, alignment: 0.5);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // A Row (not a lazy list) so every chip, including the selected one,
    // exists and can be scrolled to; there are only a handful of them.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          for (final (i, c) in PhotoCategory.values.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            KeyedSubtree(
              key: c == widget.selected ? _selectedKey : null,
              child: CategoryChip(
                key: ValueKey('category-${c.id}'),
                category: c,
                selected: c == widget.selected,
                onTap: () => widget.onChanged(c == widget.selected ? null : c),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
