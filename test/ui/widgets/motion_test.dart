import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/ui/widgets/motion.dart';

void main() {
  double scaleOf(WidgetTester tester) =>
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

  testWidgets('PressScale shrinks while pressed and restores on release', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: PressScale(
            child: ColoredBox(
              color: Colors.red,
              child: SizedBox.square(dimension: 40),
            ),
          ),
        ),
      ),
    );
    expect(scaleOf(tester), 1);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressScale)),
    );
    await tester.pump();
    expect(scaleOf(tester), 0.94);
    await gesture.up();
    await tester.pump();
    expect(scaleOf(tester), 1);
  });

  testWidgets('disabled PressScale never shrinks', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: PressScale(
            enabled: false,
            child: ColoredBox(
              color: Colors.red,
              child: SizedBox.square(dimension: 40),
            ),
          ),
        ),
      ),
    );
    await tester.startGesture(tester.getCenter(find.byType(PressScale)));
    await tester.pump();
    expect(scaleOf(tester), 1);
  });

  testWidgets('EntranceAnimation starts hidden and ends fully visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EntranceAnimation(
          delay: Duration(milliseconds: 100),
          child: Text('hi'),
        ),
      ),
    );
    double opacity() => tester
        .widget<Opacity>(
          find.ancestor(of: find.text('hi'), matching: find.byType(Opacity)),
        )
        .opacity;
    expect(opacity(), 0);
    await tester.pump(const Duration(milliseconds: 50));
    expect(opacity(), 0, reason: 'still inside the delay');
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });
}
