import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/metro_text_box.dart';
import 'package:metro_ui/widgets/metro_list_picker.dart';

void main() {
  testWidgets('text box edits text and reports changes', (tester) async {
    String? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MetroTextBox(onChanged: (s) => changed = s)),
      ),
    );
    await tester.enterText(find.byType(TextField), 'people');
    expect(changed, 'people');
  });
  testWidgets('list picker expands in place and selects', (tester) async {
    String? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MetroListPicker<String>(
            items: const ['a', 'b'],
            itemLabel: (x) => x,
            value: 'a',
            onChanged: (x) => chosen = x,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(MetroListPicker<String>));
    // ListPicker::Size animates 0 -> 0.25 s, so the rows appear over 250 ms.
    await tester.pumpAndSettle();
    expect(find.text('b'), findsOneWidget);
    await tester.tap(find.text('b'));
    await tester.pumpAndSettle();
    expect(chosen, 'b');
  });
  testWidgets('list picker opens route for more than five choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MetroListPicker<int>(
            items: const [1, 2, 3, 4, 5, 6],
            itemLabel: (x) => '$x',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.byType(MetroListPicker<int>));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(6));
  });
}
