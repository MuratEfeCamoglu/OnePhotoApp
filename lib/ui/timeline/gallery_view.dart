import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/categories.dart';
import '../../core/date_key.dart';
import '../../core/theme.dart';
import '../../data/entry.dart';
import '../../state/timeline_controller.dart';
import '../day_detail/day_preview.dart';
import '../widgets/category_style.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/l10n.dart';
import '../widgets/motion.dart';

/// Hero tag of a gallery tile; distinct from the grid cell's tag because
/// both tabs stay in the tree.
String galleryHeroTag(String dateKey) => 'gallery-$dateKey';

/// All photos as a 3 column grid, newest first (ISKELET F13).
class GalleryView extends StatefulWidget {
  /// Creates the gallery over [controller]'s entries.
  const GalleryView({
    super.key,
    required this.controller,
    this.scroll,
    this.onSettings,
  });

  /// Source of entries.
  final TimelineController controller;

  /// Lets the bottom bar scroll the gallery back to the top.
  final ScrollController? scroll;

  /// Opens settings from the top-right button; hidden when `null`.
  final VoidCallback? onSettings;

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  PhotoCategory? _filter;

  // Tiles animate in on the first screenful only (see timeline).
  bool _introDone = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.strings;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final all = widget.controller.entriesNewestFirst;
        final used = {
          for (final e in all)
            if (e.category != null) e.category!,
        };
        // A filter whose last photo was deleted would show nothing.
        final filter = used.contains(_filter) ? _filter : null;
        final shown = filter == null
            ? all
            : all.where((e) => e.category == filter).toList();
        return CustomScrollView(
          controller: widget.scroll,
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.galleryTitle,
                              style: AppText.appTitle.copyWith(
                                fontSize: 32,
                                color: p.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedSwitcher(
                              duration: AppMotion.short,
                              child: Text(
                                s.photoCount(shown.length),
                                key: ValueKey(shown.length),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: p.dayMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onSettings != null)
                        SettingsButton(onPressed: widget.onSettings),
                    ],
                  ),
                ),
              ),
            ),
            if (used.isNotEmpty)
              SliverToBoxAdapter(
                child: _FilterRow(
                  categories: [
                    for (final c in PhotoCategory.values)
                      if (used.contains(c)) c,
                  ],
                  selected: filter,
                  onChanged: (c) => setState(() => _filter = c),
                ),
              ),
            if (all.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyGallery(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    if (!_introDone) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _introDone = true,
                      );
                    }
                    return EntranceAnimation(
                      key: ValueKey(shown[i].dateKey),
                      enabled: !_introDone,
                      delay: Duration(milliseconds: 30 * math.min(i, 9)),
                      offset: 12,
                      child: _GalleryTile(
                        entry: shown[i],
                        controller: widget.controller,
                      ),
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    AppDimens.navBarClearance +
                    MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<PhotoCategory> categories;
  final PhotoCategory? selected;
  final ValueChanged<PhotoCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final allSelected = selected == null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          PressScale(
            child: GestureDetector(
              key: const ValueKey('filter-all'),
              onTap: () => onChanged(null),
              child: AnimatedContainer(
                duration: AppMotion.short,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: allSelected ? p.onSurface : p.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.strings.allCategories,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: allSelected ? p.background : p.onSurface,
                  ),
                ),
              ),
            ),
          ),
          for (final c in categories) ...[
            const SizedBox(width: 8),
            CategoryChip(
              key: ValueKey('filter-${c.id}'),
              category: c,
              selected: c == selected,
              onTap: () => onChanged(c == selected ? null : c),
            ),
          ],
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.entry, required this.controller});

  final Entry entry;
  final TimelineController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final file = controller.fileFor(entry);
    final category = entry.category;
    final broken = ColoredBox(
      color: p.surface,
      child: Center(
        child: Icon(Icons.broken_image, size: 28, color: p.dayMuted),
      ),
    );
    return PressScale(
      scale: 0.95,
      child: GestureDetector(
        key: ValueKey('gallery-${entry.dateKey}'),
        onTap: () => showDayPreview(
          context,
          controller,
          entry.dateKey,
          heroTag: galleryHeroTag(entry.dateKey),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (controller.fileExists(entry))
                Hero(
                  tag: galleryHeroTag(entry.dateKey),
                  child: Image.file(
                    file,
                    cacheWidth: 360,
                    filterQuality: FilterQuality.low,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stack) => broken,
                  ),
                )
              else
                broken,
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [AppColors.photoScrim, Color(0x00000000)],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 6,
                child: Text(
                  formatDayMonth(entry.dateKey, strings: context.strings),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Color(0x80000000), offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ),
              if (category != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: CategoryBadge(category: category, size: 18),
                ),
              if (entry.hasNote)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(
                    Icons.sticky_note_2_rounded,
                    size: 14,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Color(0x99000000), offset: Offset(0, 1)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.strings;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 56, color: p.dayMuted),
          const SizedBox(height: 12),
          Text(
            s.galleryEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: p.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.galleryEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: p.dayMuted),
          ),
        ],
      ),
    );
  }
}
