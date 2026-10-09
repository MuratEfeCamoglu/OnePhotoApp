import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/core/categories.dart';
import 'package:one_photo_app/core/strings.dart';

void main() {
  test('offers the requested categories and more', () {
    expect(
      PhotoCategory.values,
      containsAll([
        PhotoCategory.food,
        PhotoCategory.view,
        PhotoCategory.travel,
        PhotoCategory.family,
        PhotoCategory.friends,
        PhotoCategory.pet,
      ]),
    );
    expect(PhotoCategory.values.length, greaterThan(6));
  });

  test('every category has its own colour', () {
    final colours = PhotoCategory.values.map((c) => c.colorValue).toSet();
    expect(colours, hasLength(PhotoCategory.values.length));
  });

  test('ids round-trip; unknown or empty ids mean no category', () {
    for (final c in PhotoCategory.values) {
      expect(PhotoCategory.fromId(c.id), c);
    }
    expect(PhotoCategory.fromId(null), isNull);
    expect(PhotoCategory.fromId('spaceship'), isNull);
  });

  test('every category is named in both languages', () {
    for (final c in PhotoCategory.values) {
      expect(Strings.tr.categoryName(c), isNotEmpty);
      expect(Strings.en.categoryName(c), isNotEmpty);
    }
    expect(Strings.tr.categoryName(PhotoCategory.pet), 'Evcil hayvan');
    expect(Strings.en.categoryName(PhotoCategory.friends), 'Friends');
  });
}
