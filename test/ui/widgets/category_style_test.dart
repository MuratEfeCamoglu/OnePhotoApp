import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/categories.dart';
import 'package:one_photo_app/ui/widgets/category_style.dart';

void main() {
  test('every category has an icon and an opaque colour', () {
    final icons = PhotoCategory.values.map((c) => c.icon).toSet();
    expect(icons, hasLength(PhotoCategory.values.length));
    for (final c in PhotoCategory.values) {
      expect(c.color.a, 1.0);
    }
  });

  Future<List<PhotoCategory?>> pumpPicker(
    WidgetTester tester,
    PhotoCategory? selected,
  ) async {
    final changes = <PhotoCategory?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryPicker(selected: selected, onChanged: changes.add),
        ),
      ),
    );
    return changes;
  }

  testWidgets('picker shows Turkish names with icons', (tester) async {
    await pumpPicker(tester, null);
    expect(find.text('Yemek'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
  });

  testWidgets('tapping a chip selects it', (tester) async {
    final changes = await pumpPicker(tester, null);
    await tester.tap(find.byKey(const ValueKey('category-food')));
    expect(changes, [PhotoCategory.food]);
  });

  testWidgets('tapping the selected chip clears the choice', (tester) async {
    final changes = await pumpPicker(tester, PhotoCategory.food);
    await tester.tap(find.byKey(const ValueKey('category-food')));
    expect(changes, [null]);
  });

  testWidgets('selected chip is filled with the category colour', (
    tester,
  ) async {
    await pumpPicker(tester, PhotoCategory.view);
    final box = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('category-view')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, PhotoCategory.view.color);
  });

  testWidgets('picker scrolls to reach the last category', (tester) async {
    await pumpPicker(tester, null);
    final last = find.byKey(
      ValueKey('category-${PhotoCategory.values.last.id}'),
    );
    await tester.scrollUntilVisible(
      last,
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(last, findsOneWidget);
  });

  testWidgets('badge draws the category icon on its colour', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: CategoryBadge(category: PhotoCategory.pet)),
      ),
    );
    expect(find.byIcon(Icons.pets_rounded), findsOneWidget);
    final box = tester.widget<Container>(find.byType(Container));
    expect((box.decoration! as BoxDecoration).color, PhotoCategory.pet.color);
  });
}
