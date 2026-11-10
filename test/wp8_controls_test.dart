import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/tile.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/widgets/metro_circle_button.dart';
import 'package:metro_ui/widgets/switcher.dart';

Matrix4 _tileMatrix(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .descendant(of: find.byType(Tile), matching: find.byType(Transform))
          .first,
    )
    .transform;

bool _tilted(WidgetTester tester) {
  final m = _tileMatrix(tester);
  return m.entry(2, 3) != 0 || m.entry(0, 2) != 0 || m.entry(2, 0) != 0;
}

void main() {
  testWidgets('tile reports press and release and invokes tap once', (
    tester,
  ) async {
    var taps = 0;
    final states = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Tile(
            onTap: () => taps++,
            onTouch: states.add,
            child: const SizedBox(width: 100, height: 80),
          ),
        ),
      ),
    );
    final g = await tester.startGesture(tester.getCenter(find.byType(Tile)));
    await tester.pump();
    expect(states, [true]);
    await g.up();
    await tester.pump();
    expect(states, [true, false]);
    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 500));
  });
  testWidgets('button and circle button tolerate absent optional data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            const MetroButton(),
            MetroCircleButton(icon: const Icon(Icons.add), onPressed: () {}),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('switch tap asks for opposite value', (tester) async {
    bool? value;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: CustomSwitch(value: false, onChanged: (v) => value = v),
        ),
      ),
    );
    await tester.tap(find.byType(CustomSwitch));
    await tester.pump();
    expect(value, isTrue);
  });
  testWidgets('disabled switch is visually dim and ignores taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: CustomSwitch(value: false))),
    );
    final opacity = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(CustomSwitch),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, 0.4);
    await tester.tap(find.byType(CustomSwitch));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('tile cancels press when scroll wins gesture', (tester) async {
    final states = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            Tile(
              onTap: () {},
              onTouch: states.add,
              child: const SizedBox(height: 100),
            ),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    );
    final g = await tester.startGesture(tester.getCenter(find.byType(Tile)));
    await g.moveBy(const Offset(0, -20));
    await tester.pump();
    await g.moveBy(const Offset(0, -20));
    await tester.pump();
    await g.moveBy(const Offset(0, -20));
    await tester.pump();
    expect(states, [true, false]);
    // The list moved under the pointer, so sliding back over the tile must not
    // re-acquire the press while the scroll owns the gesture.
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(states, [true, false]);
    await g.up();
    await tester.pump(const Duration(milliseconds: 500));
  });
  testWidgets('tile keeps tilting while the pointer slides inside', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Tile(
            onTap: () {},
            child: const SizedBox(width: 200, height: 200),
          ),
        ),
      ),
    );
    final g = await tester.startGesture(tester.getCenter(find.byType(Tile)));
    await tester.pump(const Duration(milliseconds: 60));
    final centeredZ = _tileMatrix(tester).entry(2, 3);
    expect(_tilted(tester), isTrue);

    await g.moveBy(const Offset(90, 0));
    await tester.pump();
    final moved = _tileMatrix(tester);
    expect(_tilted(tester), isTrue);
    expect(moved.entry(2, 3), lessThan(centeredZ));
    expect(moved.entry(0, 2).abs() + moved.entry(2, 0).abs(), greaterThan(0));

    await g.up();
    await tester.pump(const Duration(milliseconds: 600));
  });
  testWidgets('tile clears outside and tilts again when the pointer returns', (
    tester,
  ) async {
    final states = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Tile(
            allowBack: false,
            onTap: () {},
            onTouch: states.add,
            child: const SizedBox(width: 200, height: 200),
          ),
        ),
      ),
    );
    final g = await tester.startGesture(tester.getCenter(find.byType(Tile)));
    await tester.pump(const Duration(milliseconds: 60));
    expect(states, [true]);
    expect(_tilted(tester), isTrue);

    await g.moveBy(const Offset(0, 160));
    await tester.pump();
    expect(states, [true, false]);
    expect(_tilted(tester), isFalse);

    await g.moveBy(const Offset(0, -80));
    await tester.pump();
    // Re-acquisition is validated after the frame settles, so it lands on the
    // following frame.
    await tester.pump();
    expect(states, [true, false, true]);
    expect(_tilted(tester), isTrue);

    await g.up();
    await tester.pump();
    expect(states, [true, false, true, false]);
    expect(_tilted(tester), isFalse);
  });
}
