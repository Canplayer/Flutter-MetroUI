import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/metro_list_picker.dart';
import 'package:metro_ui/widgets/tile.dart';

/// True when any `Transform` inside [scope] rotates or skews, i.e. the UIX 3D
/// tilt is currently applied.
///
/// A pure translation does not count: `UixOpticalText` shifts labels by a
/// fraction of a pixel to centre their cap box, which is not a tilt.
bool _isTilted(WidgetTester tester, Finder scope) {
  final transforms = tester.widgetList<Transform>(
    find.descendant(of: scope, matching: find.byType(Transform)),
  );
  return transforms.any((t) {
    final m = t.transform;
    // Tile builds `identity .. setEntry(2,3,z) .. rotateX .. rotateY`, so the
    // perspective/rotation entries tell a tilt apart from a plain xy shift.
    final pureTranslation =
        m.entry(0, 0) == 1 &&
        m.entry(0, 1) == 0 &&
        m.entry(1, 0) == 0 &&
        m.entry(1, 1) == 1 &&
        m.entry(2, 2) == 1 &&
        m.entry(2, 3) == 0 &&
        m.entry(3, 2) == 0;
    return !pureTranslation;
  });
}

Widget _host({ValueChanged<String>? onChanged}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 240,
        child: ListPicker<String>(
          items: const ['a', 'b', 'c'],
          itemLabel: (v) => v,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  ),
);

Finder get _picker => find.byType(ListPicker<String>);

Container _frame(WidgetTester tester) => tester.widget<Container>(
  find.descendant(of: _picker, matching: find.byType(Container)).first,
);

/// The frame fill stays a background decoration.
Color? _fill(WidgetTester tester) =>
    (_frame(tester).decoration! as BoxDecoration).color;

/// The border is painted in the foreground so that it overlays the padding
/// instead of taking layout space, like the 9-grid `MediumBorder` bitmap.
Color _border(WidgetTester tester) =>
    ((_frame(tester).foregroundDecoration! as BoxDecoration).border! as Border)
        .top
        .color;

void main() {
  testWidgets('collapsed frame tilts while pressed and clears on release', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    // `ListPicker` derives from `Button.uix!TiltBase`; `TiltUpImmediately` is
    // true there, so the tilt must be gone as soon as the pointer is released.
    expect(_isTilted(tester, _picker), isFalse);

    final gesture = await tester.startGesture(tester.getCenter(_picker));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_isTilted(tester, _picker), isTrue);

    await gesture.up();
    await tester.pump();
    expect(_isTilted(tester, _picker), isFalse);
    await tester.pumpAndSettle();
  });

  testWidgets('each row tilts while pressed and animates back', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(_picker);
    await tester.pumpAndSettle();

    final row = find.text('c');
    final gesture = await tester.startGesture(tester.getCenter(row));
    await tester.pump(const Duration(milliseconds: 60));
    // `ListPickerItem` derives from `List.uix!TiltListItem`, which keeps
    // `TiltUpImmediately = false`, so the return keeps its own animation.
    expect(_isTilted(tester, find.byType(Tile)), isTrue);

    // Moving past the touch slop cancels the tap without selecting a row.
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 120));
    expect(_isTilted(tester, find.byType(Tile)), isTrue);
    await tester.pumpAndSettle();
    expect(_isTilted(tester, find.byType(Tile)), isFalse);
    // Still expanded: the drag must not have selected anything.
    expect(find.text('c'), findsOneWidget);
  });

  testWidgets('empty row space selects without tilting', (tester) async {
    String? chosen;
    await tester.pumpWidget(_host(onChanged: (v) => chosen = v));
    await tester.tap(_picker);
    await tester.pumpAndSettle();

    final rowCenter = tester.getCenter(find.text('c'));
    final pickerBox = tester.getRect(_picker);
    // Far right of the row: outside the label text.
    final gesture = await tester.startGesture(
      Offset(pickerBox.right - 20, rowCenter.dy),
    );
    await tester.pump(const Duration(milliseconds: 60));
    expect(_isTilted(tester, find.byType(Tile)), isFalse);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(chosen, 'c');
  });

  testWidgets('the list is not painted behind the placeholder', (tester) async {
    // `ListUI.Alpha = !Placeholder.Visible`: with nothing selected the placeholder
    // owns the collapsed frame, so the row underneath must stay invisible
    // instead of showing both labels on top of each other.
    await tester.pumpWidget(_host());
    Opacity listAlpha() => tester.widget<Opacity>(
      find.ancestor(of: find.text('a'), matching: find.byType(Opacity)).last,
    );
    expect(listAlpha().opacity, 0);

    await tester.tap(_picker);
    await tester.pumpAndSettle();
    expect(listAlpha().opacity, 1);
  });

  group('frame appearance state machine', () {
    final scheme = ThemeData.light().colorScheme;

    testWidgets('idle: foreground border, no fill', (tester) async {
      await tester.pumpWidget(_host());
      expect(_fill(tester), isNull);
      expect(_border(tester), scheme.onSurface);
    });

    testWidgets('pressing already shows the focused frame', (tester) async {
      await tester.pumpWidget(_host());
      final gesture = await tester.startGesture(tester.getCenter(_picker));
      await tester.pump();
      // ListPicker.private_UpdateAppearance: Clicking && ExpandsInPlace ->
      // FocusedBackgroundImage (MediumBorderAccentWhiteFill).
      expect(_border(tester), scheme.primary);
      expect(_fill(tester), Colors.white);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_fill(tester), Colors.white);
    });

    testWidgets('rows switch to dark text while the frame is white', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      Color rowColor() => tester.widget<Text>(find.text('b')).style!.color!;
      // Collapsed, unfilled frame: rows use Style.Foreground.
      expect(rowColor(), scheme.onSurface);

      final gesture = await tester.startGesture(tester.getCenter(_picker));
      await tester.pump();
      // Pressed frame is already the white accent panel, so the rows must use
      // PressedForeground (black) instead of the (dark-theme) foreground.
      expect(_fill(tester), Colors.white);
      expect(rowColor(), Colors.black);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(rowColor(), Colors.black);
    });

    testWidgets('a pressed selected row is black, not accent', (tester) async {
      String? value;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 240,
                child: StatefulBuilder(
                  builder: (context, setState) => ListPicker<String>(
                    items: const ['a', 'b', 'c'],
                    itemLabel: (v) => v,
                    value: value,
                    onChanged: (v) => setState(() => value = v),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(_picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('b'));
      await tester.pumpAndSettle();
      expect(value, 'b');

      // Re-open: the selected row is accent while idle.
      await tester.tap(_picker);
      await tester.pumpAndSettle();
      Color rowColor(String label) =>
          tester.widget<Text>(find.text(label)).style!.color!;
      expect(rowColor('b'), scheme.primary);

      // ListPickerItem.private_UpdateAppearance checks Clicking before
      // Expanded, so holding the selected row turns it black.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('b')),
      );
      await tester.pump();
      expect(rowColor('b'), Colors.black);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('collapsing restores the normal frame immediately', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.tap(_picker);
      await tester.pumpAndSettle();
      expect(_fill(tester), Colors.white);

      // Tapping the frame collapses; the state machine leaves `Expanded`, so the
      // fill and border revert on the very first frame of the shrink.
      await tester.tapAt(tester.getCenter(_picker));
      await tester.pump();
      expect(_fill(tester), isNull);
      expect(_border(tester), scheme.onSurface);
      await tester.pumpAndSettle();
    });
  });
}
