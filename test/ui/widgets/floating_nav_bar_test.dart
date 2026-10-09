import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/ui/widgets/floating_nav_bar.dart';

void main() {
  Future<List<String>> pump(
    WidgetTester tester, {
    bool cameraEnabled = true,
  }) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingNavBar(
            onHome: () => calls.add('home'),
            onCamera: cameraEnabled ? () => calls.add('camera') : null,
            onSettings: () => calls.add('settings'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('has home, camera and settings buttons in that order', (
    tester,
  ) async {
    await pump(tester);
    final home = tester.getCenter(find.byKey(const ValueKey('home-button')));
    final camera = tester.getCenter(
      find.byKey(const ValueKey('camera-button')),
    );
    final settings = tester.getCenter(
      find.byKey(const ValueKey('settings-button')),
    );
    expect(home.dx, lessThan(camera.dx));
    expect(camera.dx, lessThan(settings.dx));
    expect(find.byIcon(Icons.photo_camera), findsOneWidget);
  });

  testWidgets('each button calls its callback', (tester) async {
    final calls = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('home-button')));
    await tester.tap(find.byKey(const ValueKey('camera-button')));
    await tester.tap(find.byKey(const ValueKey('settings-button')));
    await tester.pumpAndSettle();
    expect(calls, ['home', 'camera', 'settings']);
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
    expect(find.byTooltip('Ayarlar'), findsOneWidget);
  });
}
