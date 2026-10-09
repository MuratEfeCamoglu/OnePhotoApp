import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_photo_app/ui/widgets/splash_gate.dart';

class _Counted extends StatefulWidget {
  const _Counted();

  static int built = 0;

  @override
  State<_Counted> createState() => _CountedState();
}

class _CountedState extends State<_Counted> {
  @override
  void initState() {
    super.initState();
    _Counted.built++;
  }

  @override
  Widget build(BuildContext context) => const Text('home');
}

void main() {
  setUp(() => _Counted.built = 0);

  Future<void> pump(
    WidgetTester tester, {
    bool enabled = true,
    bool disableAnimations = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: SplashGate(enabled: enabled, child: const _Counted()),
        ),
      ),
    );
  }

  Finder intro() => find.byWidgetPredicate(
    (w) => w is ColoredBox && w.color.toARGB32() == 0xFFC2410C,
  );

  testWidgets('waits on the static splash, warming the screen behind it', (
    tester,
  ) async {
    await pump(tester);
    expect(intro(), findsOneWidget);
    // Built and painted once behind the opaque intro before animating.
    expect(_Counted.built, 1);
    // The title is still fully transparent on the static picture.
    final title = tester.widget<Text>(find.text('OnePhoto'));
    expect(title.style!.color!.a, 0);
  });

  testWidgets('hides the screen while the animation runs', (tester) async {
    await pump(tester);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('home'), findsNothing, reason: 'offstage');
  });

  testWidgets('starts animating only after waitFor completes', (tester) async {
    final work = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: SplashGate(waitFor: work.future, child: const _Counted()),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(intro(), findsOneWidget, reason: 'still waiting');
    expect(tester.hasRunningAnimations, isFalse);
    work.complete();
    await tester.pumpAndSettle();
    expect(intro(), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('shows the title, then reveals the screen', (tester) async {
    await pump(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('OnePhoto'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(find.text('OnePhoto'), findsNothing);
    expect(_Counted.built, 1, reason: 'not rebuilt from scratch');
  });

  testWidgets('finishes in about a second', (tester) async {
    await pump(tester);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(SplashGate.duration + const Duration(milliseconds: 50));
    await tester.pump();
    expect(find.text('home'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('tapping skips to the reveal', (tester) async {
    await pump(tester);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byType(SplashGate), warnIfMissed: false);
    await tester.pump();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('disabled gate shows the screen at once', (tester) async {
    await pump(tester, enabled: false);
    expect(find.text('home'), findsOneWidget);
    expect(intro(), findsNothing);
  });

  testWidgets('reduced motion skips the animation', (tester) async {
    await pump(tester, disableAnimations: true);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('home'), findsOneWidget);
    expect(intro(), findsNothing);
  });

  testWidgets('title uses the app text style, not the debug fallback', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump(const Duration(milliseconds: 400));
    final style = DefaultTextStyle.of(tester.element(find.text('OnePhoto')));
    expect(style.style.decoration, isNot(TextDecoration.underline));
    expect(
      find.ancestor(of: find.text('OnePhoto'), matching: find.byType(Material)),
      findsWidgets,
    );
  });
}
