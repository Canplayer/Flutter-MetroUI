import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/widgets/metro_list_picker.dart';
import 'package:metro_ui/widgets/metro_text_box.dart';

Widget _picker() => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 240,
        child: ListPicker<String>(
          items: const ['a', 'b'],
          itemLabel: (v) => v,
          onChanged: (_) {},
        ),
      ),
    ),
  ),
);

/// The drawn frame: the only Container inside an EditBox that paints a border.
Finder _frame() => find.descendant(
  of: find.byType(EditBox),
  matching: find.byWidgetPredicate(
    (w) => w is Container && w.foregroundDecoration != null,
  ),
);

void main() {
  testWidgets('EditBox frame is 48 design units tall (38.4 logical)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: EditBox(hintText: 'x')),
        ),
      ),
    );
    // ListPickerCollapsedHeight (42) + frame padding (3 + 3) = 48; the extra
    // 2 units of EditBoxStyle.MinimumSize are the anti-aliasing edges.
    expect(tester.getSize(_frame()).height, 48 * 0.8);
    // Plus EditBoxMargins 0,12,0,12 -> 0,9.6,0,9.6.
    expect(
      tester.getSize(find.byType(EditBox)).height,
      48 * 0.8 + 12 * 0.8 * 2,
    );
  });

  testWidgets('idle frame is a borderless translucent panel', (tester) async {
    // `EditBoxStyle`: the idle background is the 9-grid theme bitmap
    // (`ui.light.editbox.background.png` = black at alpha 38/255), which has no
    // ring at all. The accent ring belongs to `FocusedBackgroundImage`
    // (`MediumBorderAccentWhiteFill`) and only appears with key focus.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: EditBox(hintText: 'x')),
        ),
      ),
    );
    final frame = _frame();
    expect(tester.getSize(frame).height, 48 * 0.8);
    final container = tester.widget<Container>(frame);
    expect((container.decoration! as BoxDecoration).color, isNotNull);
    final border =
        (container.foregroundDecoration! as BoxDecoration).border as Border?;
    expect(border?.top.color.a ?? 0, 0, reason: 'idle EditBox has no ring');

    // The ring still covers the whole frame once focused.
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    final focusedContainer = tester.widget<Container>(_frame());
    expect((focusedContainer.decoration! as BoxDecoration).color, Colors.white);
    final focusedBorder =
        (focusedContainer.foregroundDecoration! as BoxDecoration).border
            as Border;
    expect(focusedBorder.top.width, 3 * 0.8);
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.border,
      InputBorder.none,
    );
  });

  testWidgets('the padded text block is centred, not top aligned', (
    tester,
  ) async {
    // `EditBoxPadding` (4 top / 10 bottom) is applied inside a horizontal
    // ScrollViewer, which centres its content on the cross axis.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: EditBox(hintText: 'x')),
        ),
      ),
    );
    final frameRect = tester.getRect(_frame());
    final textRect = tester.getRect(find.byType(TextField));
    const padTop = 4 * 0.8;
    const padBottom = 10 * 0.8;
    final above = textRect.top - frameRect.top - padTop;
    final below = frameRect.bottom - textRect.bottom - padBottom;
    expect(above, closeTo(below, 0.01));
    expect(above, greaterThan(0), reason: 'not flush with the top edge');
  });

  testWidgets('collapsed ListPicker matches the EditBox height', (
    tester,
  ) async {
    await tester.pumpWidget(_picker());
    expect(
      tester.getSize(find.byType(ListPicker<String>)).height,
      48 * 0.8 + 12 * 0.8 * 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('EditBox, Button and ListPicker share the same frame height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EditBox(hintText: 'x'),
                  MetroButton(onTap: () {}, child: const Text('b')),
                  ListPicker<String>(
                    items: const ['a', 'b'],
                    itemLabel: (v) => v,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final box = tester.getSize(find.byType(EditBox)).height;
    expect(tester.getSize(find.byType(MetroButton)).height, box);
    expect(tester.getSize(find.byType(ListPicker<String>)).height, box);
    // 48 design units of frame plus 12 units of margin on each side.
    expect(box, 48 * 0.8 + 12 * 0.8 * 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UIX FontSize is converted through 4/3', (tester) async {
    // UIXRender.dll multiplies the size field by the 4/3 double at 0x10019bc8.
    expect(uixFontSize(19), closeTo(20.2667, 1e-3));
    expect(
      uixFontSize(128),
      closeTo(136.533, 1e-3),
    ); // panorama title, measured ~135

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: EditBox(hintText: 'x')),
        ),
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).style!.fontSize,
      closeTo(uixFontSize(19), 1e-9),
    );

    await tester.pumpWidget(_picker());
    expect(
      tester.widget<Text>(find.text('a')).style!.fontSize,
      closeTo(uixFontSize(19), 1e-9),
    );
  });
}
