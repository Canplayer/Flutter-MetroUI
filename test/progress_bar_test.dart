import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/progress_bar.dart';

const _logHalf = 0.7597469266479578; // UixLog(10) at t = 0.5
const _expHalf = 0.2402530733520421; // UixExp(10) at t = 0.5

Future<_Bitmap> _capture(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.descendant(
      of: find.byType(ProgressBar),
      matching: find.byType(RepaintBoundary),
    ),
  );
  late _Bitmap bitmap;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    bitmap = _Bitmap(image.width, image.height, data!);
    image.dispose();
  });
  return bitmap;
}

class _Bitmap {
  _Bitmap(this.width, this.height, this.data);

  final int width;
  final int height;
  final ByteData data;

  Color at(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      data.getUint8(i + 3),
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  }
}

const _red = Color(0xFFFF0000);
const _track = Color(0xFF0000FF);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 100, child: child)),
  ),
);

void main() {
  group('decoded 4.4 s timeline', () {
    test('the five tracks are staggered by 0.2 s', () {
      for (var i = 0; i < 5; i++) {
        expect(ProgressBarTimeline.delays[i], closeTo(0.2 * i, 1e-9));
      }
    });

    test('keyframe values land on the decoded times', () {
      expect(ProgressBarTimeline.offsetFraction(0, 0), 0);
      expect(ProgressBarTimeline.offsetFraction(0.5, 0), closeTo(0.4, 1e-9));
      expect(ProgressBarTimeline.offsetFraction(2.0, 0), closeTo(0.65, 1e-9));
      expect(ProgressBarTimeline.offsetFraction(2.6, 0), closeTo(1.4, 1e-9));
      expect(ProgressBarTimeline.offsetFraction(3.6, 0), closeTo(1.4, 1e-9));
      expect(ProgressBarTimeline.offsetFraction(4.39, 0), closeTo(1.4, 1e-9));
    });

    test('Log(10) drives 0 -> 0.4 and Exp(10) drives 0.65 -> 1.4', () {
      expect(
        ProgressBarTimeline.offsetFraction(0.25, 0),
        closeTo(0.4 * _logHalf, 1e-9),
      );
      expect(
        ProgressBarTimeline.offsetFraction(2.3, 0),
        closeTo(0.65 + 0.75 * _expHalf, 1e-9),
      );
    });

    test('a delayed track is held before its first keyframe', () {
      expect(ProgressBarTimeline.offsetFraction(0, 1), closeTo(1.4, 1e-9));
      expect(ProgressBarTimeline.offsetFraction(0.2, 1), 0);
      expect(ProgressBarTimeline.offsetFraction(0.7, 1), closeTo(0.4, 1e-9));
    });
  });

  testWidgets('determinate bar paints track and indicator', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProgressBar(value: 0.5, foreground: _red, background: _track),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(ProgressBar)), const Size(100, 3.2));

    final bitmap = await _capture(tester);
    expect(bitmap.at(20, 1), _red);
    expect(bitmap.at(70, 1), _track);
  });

  testWidgets('a value change is interpolated over 150 ms', (tester) async {
    await tester.pumpWidget(
      _host(
        const ProgressBar(value: 0.2, foreground: _red, background: _track),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _host(
        const ProgressBar(value: 1.0, foreground: _red, background: _track),
      ),
    );
    await tester.pump(const Duration(milliseconds: 75));
    final bitmap = await _capture(tester);
    // 0.2 + (1.0 - 0.2) * 0.5 = 0.6 -> the 70 px sample is still track.
    expect(bitmap.at(55, 1), _red);
    expect(bitmap.at(70, 1), _track);

    await tester.pump(const Duration(milliseconds: 75));
    expect((await _capture(tester)).at(95, 1), _red);
  });

  testWidgets('indeterminate squares follow the decoded positions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ProgressBar(foreground: _red, background: _track, height: 4)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final bitmap = await _capture(tester);
    // Square 0: left = -4 + 0.4 * 100 = 36.
    expect(bitmap.at(38, 2), _red);
    // Square 2: left = 4 + 0.4 * Log(10)(0.2) * 100 = 20.4 at local 0.1 s.
    expect(bitmap.at(22, 2), _red);
    expect(bitmap.at(5, 2), _track);
    expect(bitmap.at(60, 2), _track);
  });

  testWidgets('switching to determinate stops the loop', (tester) async {
    await tester.pumpWidget(
      _host(const ProgressBar(foreground: _red, background: _track)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(
      _host(const ProgressBar(value: 1, foreground: _red, background: _track)),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(ProgressBar)), const Size(100, 3.2));
    expect(tester.takeException(), isNull);
  });
}
