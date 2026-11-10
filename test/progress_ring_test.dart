import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/progress_ring.dart';

void main() {
  testWidgets('inactive ring retains resource size and active ring animates', (
    t,
  ) async {
    await t.pumpWidget(const MaterialApp(home: Center(child: ProgressRing())));
    expect(t.getSize(find.byType(ProgressRing)), const Size(46, 46));
    expect(
      find.descendant(
        of: find.byType(ProgressRing),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    await t.pumpWidget(
      const MaterialApp(home: Center(child: ProgressRing(isActive: true))),
    );
    await t.pump(const Duration(milliseconds: 433));
    expect(
      find.descendant(
        of: find.byType(ProgressRing),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox());
    expect(t.takeException(), isNull);
  });
}
