import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/message_box.dart';
import 'package:metro_ui/widgets/metro_circle_button.dart';

void main() {
  const messageBox = MetroMessageBox(
    title: 'Confirm action',
    message: 'Continue?',
    confirmLabel: 'confirm',
    cancelLabel: 'cancel',
  );

  Finder panel() => find
      .descendant(
        of: find.byType(MetroMessageBox),
        matching: find.byType(ColoredBox),
      )
      .first;

  for (final useMetroApp in [false, true]) {
    testWidgets('MessageBox respects safe area (MetroApp: $useMetroApp)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 820);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 52, left: 11, right: 17);
      addTearDown(tester.view.reset);
      late BuildContext pageContext;
      final page = Builder(
        builder: (context) {
          pageContext = context;
          return const SizedBox.expand();
        },
      );
      await tester.pumpWidget(
        useMetroApp
            ? MetroApp(useWVGAMode: true, home: page)
            : MaterialApp(home: page),
      );

      final result = messageBox.show(pageContext);
      await tester.pumpAndSettle();

      final background = tester.getRect(panel());
      expect(background.top, closeTo(0, 0.01));
      expect(background.left, closeTo(0, 0.01));
      expect(background.right, closeTo(420, 0.01));

      final scrollView = find.descendant(
        of: find.byType(MetroMessageBox),
        matching: find.byType(SingleChildScrollView),
      );
      final content = tester.getRect(scrollView);
      expect(content.top, closeTo(52, 0.01));
      expect(content.left, closeTo(11, 0.01));
      expect(content.right, closeTo(403, 0.01));
      await tester.tap(find.text('confirm'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });
  }

  testWidgets('MessageBox blocks Application Bar until it finishes closing', (
    tester,
  ) async {
    late BuildContext pageContext;
    var presses = 0;
    await tester.pumpWidget(
      MetroApp(
        home: MetroPageScaffold(
          disableDefaultPushAnimation: true,
          body: Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
          applicationBar: MetroApplicationBar(
            buttons: [
              MetroAppBarButton(
                icon: const Icon(Icons.add),
                label: 'command',
                onPressed: () => presses++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final command = tester.getCenter(find.byType(MetroCircleButton));
    await tester.tapAt(command);
    await tester.pumpAndSettle();
    expect(presses, 1);

    final result = messageBox.show(pageContext);
    await tester.pump();
    await tester.tapAt(command);
    expect(presses, 1);
    await tester.pumpAndSettle();
    await tester.tapAt(command);
    expect(presses, 1);

    await tester.tap(find.text('cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(MetroMessageBox), findsOneWidget);
    await tester.tapAt(command);
    expect(presses, 1);
    await tester.pumpAndSettle();
    expect(await result, isFalse);
    expect(find.byType(MetroMessageBox), findsNothing);

    await tester.tapAt(command);
    await tester.pumpAndSettle();
    expect(presses, 2);
  });
}
