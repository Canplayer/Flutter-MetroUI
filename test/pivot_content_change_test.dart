import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/pivot_pane_view.dart';

void main() {
  testWidgets(
    'UIX content change loads incoming while outgoing track is active',
    (tester) async {
      final controller = PivotController();
      final ended = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: PivotPaneView(
            controller: controller,
            onTransitionEnd: (_, index) => ended.add(index),
            itemBuilder: (_, index) => Center(child: Text('pane $index')),
          ),
        ),
      );
      controller.next();
      await tester.pump();
      expect(find.text('pane 0'), findsOneWidget);
      expect(find.text('pane 1'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('pane 0'), findsNothing);
      expect(ended, isEmpty);
      await tester.pump(const Duration(milliseconds: 201));
      expect(ended, [1]);
      expect(tester.takeException(), isNull);
    },
  );
}
