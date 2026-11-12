import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/metro_scroll_behavior.dart';
import 'package:metro_ui/src/scrolling/uix_scroll_simulation.dart';

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/wp8_accordion_native.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  for (final c in fixture['cases'] as List) {
    test('original x86 pull=${c['pull']} velocity=${c['velocity']}', () {
      final sim = UixScrollSimulation(
        position: (c['pull'] as num).toDouble() * .8,
        velocity: (c['velocity'] as num).toDouble() * .8,
        minScrollExtent: -800,
        maxScrollExtent: 0,
      );
      for (final sample in c['samples'] as List) {
        final t = (sample['seconds'] as num).toDouble();
        expect(
          sim.x(t),
          closeTo((sample['position'] as num) * .8, .002),
          reason: 't=$t',
        );
        expect(
          sim.dx(t),
          closeTo((sample['velocity'] as num) * .8, .01),
          reason: 't=$t',
        );
      }
    });
  }

  test('recovery is independent of 30/60/120Hz and query order', () {
    UixScrollSimulation motion() => UixScrollSimulation(
      position: 80,
      velocity: 0,
      minScrollExtent: -800,
      maxScrollExtent: 0,
    );
    final results = <double>[];
    for (final hz in [30, 60, 120]) {
      final sim = motion();
      for (var frame = 0; frame < hz; frame++) {
        sim.dx(frame / hz);
        sim.isDone(frame / hz);
        sim.x(frame / hz);
      }
      results.add(sim.x(.1538));
      expect(sim.x(.0769), closeTo(25.350128 * .8, .001));
      expect(sim.x(1), 0);
      expect(sim.isDone(1), isTrue);
    }
    expect(results[0], results[1]);
    expect(results[1], results[2]);
  });

  for (final axis in Axis.values) {
    for (final reverse in [false, true]) {
      testWidgets(
        '$axis reverse=$reverse: clamped pixels, correct paint axis/edge, recovery',
        (tester) async {
          final controller = ScrollController();
          final item = GlobalKey();
          await tester.pumpWidget(
            _host(controller, axis: axis, reverse: reverse, itemKey: item),
          );
          final list = find.byType(ListView);
          final viewport = tester.getRect(list);
          final box = item.currentContext!.findRenderObject()! as RenderBox;
          final before = box.getTransformTo(null);
          final positive = !reverse;
          final drag = axis == Axis.vertical
              ? Offset(0, positive ? 240 : -240)
              : Offset(positive ? 240 : -240, 0);
          final gesture = await tester.startGesture(viewport.center);
          await gesture.moveBy(drag / 2);
          await tester.pump();
          await gesture.moveBy(drag / 2);
          await tester.pump();
          expect(controller.offset, 0);
          final after = box.getTransformTo(null);
          final index = axis == Axis.vertical ? 1 : 0;
          expect(after.entry(index, index), closeTo(1 - 125 / 1800, 1e-6));
          expect(
            after.entry(1 - index, 1 - index),
            closeTo(before.entry(1 - index, 1 - index), 1e-6),
          );
          final point = box.localToGlobal(Offset.zero);
          if (axis == Axis.vertical) {
            if (!reverse) {
              expect(point.dy, closeTo(viewport.top + 100, 1e-5));
            }
          } else if (!reverse) {
            expect(point.dx, closeTo(viewport.left + 100, 1e-5));
          }
          if (reverse) {
            final end = box.localToGlobal(
              axis == Axis.vertical
                  ? Offset(0, box.size.height)
                  : Offset(box.size.width, 0),
            );
            expect(
              axis == Axis.vertical ? end.dy : end.dx,
              closeTo(
                axis == Axis.vertical
                    ? viewport.bottom - 100
                    : viewport.right - 100,
                1e-5,
              ),
            );
          }
          await tester.pump(const Duration(milliseconds: 100));
          await gesture.up();
          await tester.pumpAndSettle();
          expect(box.getTransformTo(null).entry(index, index), 1);
          expect(controller.offset, 0);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
        },
      );
    }
  }

  for (final axis in Axis.values) {
    for (final reverse in [false, true]) {
      testWidgets(
        '$axis reverse=$reverse: maximum extent has matching opposite edge pivot',
        (tester) async {
          final c = ScrollController();
          final key = GlobalKey();
          await tester.pumpWidget(
            _host(
              c,
              axis: axis,
              reverse: reverse,
              itemKey: key,
              markerIndex: 29,
            ),
          );
          c.jumpTo(c.position.maxScrollExtent);
          await tester.pump();
          final viewport = tester.getRect(find.byType(ListView));
          final direction = reverse ? 1.0 : -1.0;
          final delta = axis == Axis.vertical
              ? Offset(0, direction * 120)
              : Offset(direction * 120, 0);
          final g = await tester.startGesture(viewport.center);
          await g.moveBy(delta);
          await tester.pump();
          await g.moveBy(delta);
          await tester.pump();
          expect(c.offset, c.position.maxScrollExtent);
          final box = key.currentContext!.findRenderObject()! as RenderBox;
          if (reverse) {
            final p = box.localToGlobal(Offset.zero);
            expect(
              axis == Axis.vertical ? p.dy : p.dx,
              closeTo(
                axis == Axis.vertical
                    ? viewport.top + 100
                    : viewport.left + 100,
                1e-5,
              ),
            );
          } else {
            final p = box.localToGlobal(
              axis == Axis.vertical
                  ? Offset(0, box.size.height)
                  : Offset(box.size.width, 0),
            );
            expect(
              axis == Axis.vertical ? p.dy : p.dx,
              closeTo(
                axis == Axis.vertical
                    ? viewport.bottom - 100
                    : viewport.right - 100,
                1e-5,
              ),
            );
          }
          await tester.pump(const Duration(milliseconds: 100));
          await g.up();
          await tester.pumpAndSettle();
          expect(
            box
                .getTransformTo(null)
                .entry(
                  axis == Axis.vertical ? 1 : 0,
                  axis == Axis.vertical ? 1 : 0,
                ),
            1,
          );
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        },
      );
    }
  }

  testWidgets('explicit NeverScrollable physics remains disabled', (
    tester,
  ) async {
    final c = ScrollController();
    await tester.pumpWidget(
      _host(c, physics: const NeverScrollableScrollPhysics()),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(c.offset, 0);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('reverse drag consumes the full uncapped raw distance', (
    tester,
  ) async {
    final c = ScrollController();
    await tester.pumpWidget(_host(c));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 250));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    expect(c.offset, 0);
    await gesture.moveBy(const Offset(0, -200));
    await tester.pump();
    expect(c.offset, greaterThan(0));
    await gesture.cancel();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('two lists do not share compression or disposal state', (
    tester,
  ) async {
    final a = ScrollController(), b = ScrollController();
    final keyA = GlobalKey(), keyB = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Expanded(child: _host(a, itemKey: keyA)),
            Expanded(child: _host(b, itemKey: keyB)),
          ],
        ),
      ),
    );
    final g = await tester.startGesture(
      tester.getCenter(find.byType(ListView).first),
    );
    await g.moveBy(const Offset(0, 20));
    await tester.pump();
    await g.moveBy(const Offset(0, 150));
    await tester.pump();
    final boxA = keyA.currentContext!.findRenderObject()! as RenderBox;
    final boxB = keyB.currentContext!.findRenderObject()! as RenderBox;
    expect(boxA.getTransformTo(null).entry(1, 1), lessThan(1));
    expect(boxB.getTransformTo(null).entry(1, 1), 1);
    await g.cancel();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    a.dispose();
    b.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'fling reaches the edge, compresses and settles under one activity',
    (tester) async {
      final c = ScrollController();
      final key = GlobalKey();
      await tester.pumpWidget(_host(c, itemKey: key));
      c.jumpTo(c.position.maxScrollExtent - 40);
      await tester.pump();
      await tester.fling(find.byType(ListView), const Offset(0, -180), 1500);
      await tester.pump(const Duration(milliseconds: 70));
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      // The raw offset remains separate; list pixels cannot leave the extent.
      expect(
        c.offset,
        inInclusiveRange(
          c.position.minScrollExtent,
          c.position.maxScrollExtent,
        ),
      );
      expect(c.position.isScrollingNotifier.value, isTrue);
      if (box != null) {
        expect(box.getTransformTo(null).entry(1, 1), lessThan(1));
      }
      await tester.pumpAndSettle();
      expect(c.position.isScrollingNotifier.value, isFalse);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('short list supports Accordion; wheel keeps bounded pixels', (
    tester,
  ) async {
    final c = ScrollController();
    final key = GlobalKey();
    await tester.pumpWidget(_host(c, itemKey: key, count: 1));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await g.moveBy(const Offset(0, 20));
    await tester.pump();
    await g.moveBy(const Offset(0, 100));
    await tester.pump();
    final box = key.currentContext!.findRenderObject()! as RenderBox;
    expect(c.offset, 0);
    expect(box.getTransformTo(null).entry(1, 1), lessThan(1));
    await g.cancel();
    await tester.pumpAndSettle();
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(find.byType(ListView)),
        scrollDelta: const Offset(0, 100),
      ),
    );
    await tester.pump();
    expect(c.offset, 0);
    expect(box.getTransformTo(null).entry(1, 1), 1);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
    'touch pauses recovery, re-grab uses physical drag distance, jumpTo clears it',
    (tester) async {
      final c = ScrollController();
      final key = GlobalKey();
      await tester.pumpWidget(_host(c, itemKey: key));
      final center = tester.getCenter(find.byType(ListView));
      final g = await tester.startGesture(center);
      await g.moveBy(const Offset(0, 20));
      await tester.pump();
      await g.moveBy(const Offset(0, 80));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      final box = key.currentContext!.findRenderObject()! as RenderBox;
      double raw() => (1 - box.getTransformTo(null).entry(1, 1)) * 1440;
      final before = raw();
      expect(before, greaterThan(0));
      final next = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 100));
      expect(raw(), closeTo(before, .001));
      await next.moveBy(const Offset(0, 20));
      await tester.pump();
      await next.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(raw(), closeTo(before + 20, .01));
      await tester.pump(const Duration(milliseconds: 100));
      await next.up();
      c.jumpTo(200);
      await tester.pump();
      expect(raw(), 0);
      expect(c.offset, 200);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'blank pulled strip remains draggable and touch/release resumes recovery',
    (tester) async {
      final c = ScrollController();
      final key = GlobalKey();
      await tester.pumpWidget(_host(c, itemKey: key));
      final viewport = tester.getRect(find.byType(ListView));
      final g = await tester.startGesture(viewport.center);
      await g.moveBy(const Offset(0, 20));
      await tester.pump();
      await g.moveBy(const Offset(0, 80));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      final box = key.currentContext!.findRenderObject()! as RenderBox;
      double scale() => box.getTransformTo(null).entry(1, 1);
      final before = scale();
      final hold = await tester.startGesture(
        Offset(viewport.center.dx, viewport.top + 5),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(scale(), before);
      await hold.up();
      await tester.pumpAndSettle();
      expect(scale(), 1);
      final pull = await tester.startGesture(viewport.center);
      await pull.moveBy(const Offset(0, 20));
      await tester.pump();
      await pull.moveBy(const Offset(0, 80));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await pull.up();
      await tester.pump();
      final strip = await tester.startGesture(
        Offset(viewport.center.dx, viewport.top + 5),
      );
      await strip.moveBy(const Offset(0, -20));
      await tester.pump();
      final held = scale();
      await strip.moveBy(const Offset(0, -20));
      await tester.pump();
      expect(scale(), greaterThan(held));
      expect(c.offset, 0);
      await strip.cancel();
      await tester.pumpAndSettle();
      expect(scale(), 1);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host(
  ScrollController controller, {
  Axis axis = Axis.vertical,
  bool reverse = false,
  GlobalKey? itemKey,
  int count = 30,
  int markerIndex = 0,
  ScrollPhysics? physics,
}) => MaterialApp(
  home: ScrollConfiguration(
    behavior: const MetroScrollBehavior(),
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 320,
        height: 400,
        child: ListView(
          controller: controller,
          physics: physics,
          scrollDirection: axis,
          reverse: reverse,
          padding: EdgeInsets.zero,
          children: List.generate(
            count,
            (i) => SizedBox(
              key: i == markerIndex ? itemKey : null,
              width: 100,
              height: 100,
              child: ColoredBox(color: i.isEven ? Colors.orange : Colors.blue),
            ),
          ),
        ),
      ),
    ),
  ),
);
