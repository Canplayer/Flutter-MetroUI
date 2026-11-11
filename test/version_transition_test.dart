import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/metro_theme_extensions.dart';

void main() {
  for (final version in MetroDesignVersion.values) {
    testWidgets('$version Application Bar retains or replaces page host', (
      tester,
    ) async {
      final controller = MetroAppBarController();
      controller.setAppBar(const MetroApplicationBar(), owner: Object());
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [MetroSystemThemeData(version: version)],
          ),
          home: Align(
            alignment: Alignment.bottomCenter,
            child: MetroApplicationBarOverlay(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final previous = tester.state(find.byType(MetroApplicationBarView));
      controller.beginNavigation(continuous: version == MetroDesignVersion.wp7);
      expect(controller.currentBar == null, version != MetroDesignVersion.wp7);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      controller.setAppBar(const MetroApplicationBar(), owner: Object());
      await tester.pumpAndSettle();
      expect(
        identical(previous, tester.state(find.byType(MetroApplicationBarView))),
        version == MetroDesignVersion.wp7,
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }
  test('UIX EaseIn/Out matches original x86 evaluator samples', () {
    const times = [0.1, 0.25, 0.5, 0.75, 0.9];
    const incoming = [
      0.14332989667847595,
      0.35832473635673523,
      0.7166494727134705,
      0.9319241649834895,
      0.9815855729114111,
    ];
    const outgoing = [
      0.04657371175168601,
      0.17217723833553175,
      0.7166494727134705,
      0.8583247363567352,
      0.9433298810314881,
    ];
    for (var i = 0; i < times.length; i++) {
      expect(
        const UixEaseIn(10, .5).transform(times[i]),
        closeTo(incoming[i], 1e-7),
      );
      expect(
        const UixEaseOut(10, .5).transform(times[i]),
        closeTo(outgoing[i], 1e-7),
      );
    }
  });
  testWidgets('no theme animation preserves overlay and custom builder', (
    tester,
  ) async {
    bool built = false;
    await tester.pumpWidget(
      MetroApp(
        version: MetroDesignVersion.wp81,
        themeAnimationStyle: AnimationStyle.noAnimation,
        builder: (context, child) {
          built = true;
          return child!;
        },
        home: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    expect(built, isTrue);
    expect(find.byType(MetroApplicationBarOverlay), findsOneWidget);
    final context = tester.element(find.byType(MetroApplicationBarOverlay));
    expect(MetroSystemThemeData.of(context).version, MetroDesignVersion.wp81);
  });
  for (final version in MetroDesignVersion.values) {
    testWidgets('$version uses version timing, depth and linear alpha track', (
      tester,
    ) async {
      final config = MetroPageThemeData.forVersion(version);
      final key = GlobalKey<MetroAnimatedPageState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [config]),
          home: SizedBox(
            width: 384,
            child: MetroAnimatedPage(key: key, child: const Text('page')),
          ),
        ),
      );
      double alpha() => tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;
      key.currentState!.didPush();
      await tester.pump();
      expect(alpha(), 0);
      await tester.pump(const Duration(milliseconds: 5));
      expect(alpha(), closeTo(.5, .001));
      await tester.pump(config.inDuration - const Duration(milliseconds: 5));
      expect(alpha(), 1);
      key.currentState!.didPop();
      await tester.pump();
      await tester.pump(config.outAlphaHold);
      expect(alpha(), 1);
      await tester.pump(config.outDuration - config.outAlphaHold);
      expect(alpha(), 0);
      await key.currentState!.didFinish();
      await tester.pump();
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Opacity)),
        findsNothing,
      );
      expect(config.pivotDepth, version == MetroDesignVersion.wp81 ? 80 : 0);
    });
  }
}
