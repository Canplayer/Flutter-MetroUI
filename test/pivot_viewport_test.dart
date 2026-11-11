import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/pivot.dart';

void main() {
  testWidgets(
    'dragging page paints through padding but stays inside viewport',
    (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 384,
                height: 400,
                child: Pivot(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  items: const [
                    PivotItem(
                      title: Text('A'),
                      page: ColoredBox(color: Colors.red),
                    ),
                    PivotItem(
                      title: Text('B'),
                      page: ColoredBox(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(const Offset(200, 250));
      await gesture.moveBy(const Offset(-70, 0));
      await tester.pump();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final offset = (250 * image.width + 10) * 4;
        expect(pixels.getUint8(offset), 244);
        expect(pixels.getUint8(offset + 1), 67);
        expect(pixels.getUint8(offset + 2), 54);
        image.dispose();
      });
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
