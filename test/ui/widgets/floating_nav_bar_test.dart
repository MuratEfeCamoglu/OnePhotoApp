import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/ui/widgets/floating_nav_bar.dart';

void main() {
  Future<List<String>> pump(
    WidgetTester tester, {
    bool cameraEnabled = true,
    HomeTab selected = HomeTab.timeline,
  }) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingNavBar(
            selected: selected,
            onHome: () => calls.add('home'),
            onGallery: () => calls.add('gallery'),
            onCamera: cameraEnabled ? () => calls.add('camera') : null,
            onSettings: () => calls.add('settings'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  double x(WidgetTester tester, String key) =>
      tester.getCenter(find.byKey(ValueKey(key))).dx;

  testWidgets('order: home, gallery, camera, settings (F13)', (tester) async {
    await pump(tester);
    expect(x(tester, 'home-button'), lessThan(x(tester, 'gallery-button')));
    expect(x(tester, 'gallery-button'), lessThan(x(tester, 'camera-button')));
    expect(x(tester, 'camera-button'), lessThan(x(tester, 'settings-button')));
    expect(find.byIcon(Icons.photo_camera), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);
  });

  testWidgets('each button calls its callback', (tester) async {
    final calls = await pump(tester);
    for (final key in [
      'home-button',
      'gallery-button',
      'camera-button',
      'settings-button',
    ]) {
      await tester.tap(find.byKey(ValueKey(key)));
    }
    await tester.pumpAndSettle();
    expect(calls, ['home', 'gallery', 'camera', 'settings']);
  });

  testWidgets('the selected tab is highlighted', (tester) async {
    await pump(tester, selected: HomeTab.gallery);
    bool selected(String key) {
      final box = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final color = (box.decoration! as BoxDecoration).color!;
      return color != Colors.transparent;
    }

    expect(selected('gallery-button'), isTrue);
    expect(selected('home-button'), isFalse);
  });

  testWidgets('disabled camera does nothing and looks faded', (tester) async {
    final calls = await pump(tester, cameraEnabled: false);
    await tester.tap(find.byKey(const ValueKey('camera-button')));
    expect(calls, isEmpty);
    final fade = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byKey(const ValueKey('camera-button')),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(fade.opacity, 0.5);
  });

  testWidgets('shows localized tooltips', (tester) async {
    await pump(tester);
    expect(find.byTooltip('Ana sayfa'), findsOneWidget);
    expect(find.byTooltip('Galeri'), findsOneWidget);
    expect(find.byTooltip('Ayarlar'), findsOneWidget);
  });
}
