import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/toggle_switch.dart';

void main() {
  testWidgets('thumb and track share the same vertical center', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: Colors.black,
              child: ToggleSwitchBase(
                value: false,
                thumbColor: Colors.white,
                borderColor: Colors.white,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 5);
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      double center(double x) {
        final rows = <int>[];
        for (var y = 0; y < image.height; y++) {
          final at = (y * image.width + (x * 5).round()) * 4;
          if (pixels.getUint8(at) > 240) rows.add(y);
        }
        expect(rows, isNotEmpty);
        return (rows.first + rows.last) / 10;
      }

      expect(center(26), closeTo(center(50), .21));
      image.dispose();
    });
  });
}
