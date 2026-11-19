import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/pivot.dart';

void main() {
  double alpha(WidgetTester tester, int slot) => tester
      .widget<Opacity>(find.byKey(ValueKey('pivot-header-slot-$slot')))
      .opacity;
  for (final count in [2, 3]) {
    testWidgets(
      '$count panes: backward wrap hides only copies beyond native range',
      (tester) async {
        var current = 0;
        int? target;
        late StateSetter update;
        final taps = <int>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 500,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return PivotHeader(
                      titles: [
                        for (var i = 0; i < count; i++)
                          SizedBox(
                            width: 100,
                            child: Text(String.fromCharCode(65 + i)),
                          ),
                      ],
                      currentIndex: current,
                      swapTargetIndex: target,
                      titleGap: 24,
                      onTitleTap: taps.add,
                      onSwapEnded: () => update(() {
                        current = target!;
                        target = null;
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(alpha(tester, 0), 1);
        expect(alpha(tester, 1), 1);
        update(() {
          target = -1;
        });
        await tester.pump();
        expect(alpha(tester, -1), 1);
        expect(alpha(tester, 0), 1);
        // Two panes: the second B must be hidden even while its slot is on screen.
        // Three panes: this B is still within the C,A,B cycle and must remain.
        expect(alpha(tester, 1), count == 2 ? 0 : 1);
        if (count == 2) {
          await tester.tapAt(
            tester.getCenter(find.byKey(const ValueKey('pivot-header-slot-1'))),
          );
          expect(taps, isEmpty);
        }
        await tester.pump(const Duration(milliseconds: 250));
        expect(alpha(tester, 1), count == 2 ? 0 : 1);
        await tester.pumpAndSettle();
        expect(alpha(tester, -1), 1);
        expect(alpha(tester, 0), 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('non-interactive header paints only selected slot', (
    tester,
  ) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PivotHeader(
          interactive: false,
          currentIndex: 0,
          onTitleTap: taps.add,
          titles: const [
            SizedBox(width: 100, child: Text('A')),
            SizedBox(width: 100, child: Text('B')),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(alpha(tester, -1), 0);
    expect(alpha(tester, 0), 1);
    expect(alpha(tester, 1), 0);
    await tester.tapAt(const Offset(150, 30));
    expect(taps, isEmpty);
  });
}
