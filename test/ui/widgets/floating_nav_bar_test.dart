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
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  double x(WidgetTester tester, String key) =>
      tester.getCenter(find.byKey(ValueKey(key))).dx;

  testWidgets('order: home, camera (centre), gallery (F13)', (tester) async {
    await pump(tester);
    expect(x(tester, 'home-button'), lessThan(x(tester, 'camera-button')));
    expect(x(tester, 'camera-button'), lessThan(x(tester, 'gallery-button')));
    expect(find.byKey(const ValueKey('settings-button')), findsNothing);
    final centre = tester.getSize(find.byType(Scaffold)).width / 2;
    expect(x(tester, 'camera-button'), closeTo(centre, 1));
  });

  testWidgets('each button calls its callback', (tester) async {
    final calls = await pump(tester);
    for (final key in ['home-button', 'camera-button', 'gallery-button']) {
      await tester.tap(find.byKey(ValueKey(key)));
    }
    await tester.pumpAndSettle();
    expect(calls, ['home', 'camera', 'gallery']);
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
  });

  testWidgets('SettingsButton opens settings and has a tooltip', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: SettingsButton(onPressed: () => taps++)),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('settings-button')));
    expect(taps, 1);
    expect(find.byTooltip('Ayarlar'), findsOneWidget);
  });
}
