import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/animations.dart';

/// `UIXRender.dll` 0x10026202: SCurve is `Exp` on the lower half and `Log` on
/// the upper half, joined at 0.5. Expectations below are computed from that
/// formula (not from the Dart implementation).
double _expected(double t, double w) {
  double f(double x, double b) => (math.pow(b, x) - 1) / (b - 1);
  return t < 0.5 ? 0.5 * f(2 * t, w) : 0.5 + 0.5 * f(2 * t - 1, 1 / w);
}

void main() {
  group('UixSCurve', () {
    test('matches the decoded piecewise formula', () {
      const curve = UixSCurve(10);
      for (final t in [0.0, 0.05, 0.1, 0.25, 0.4, 0.5, 0.6, 0.75, 0.9, 1.0]) {
        expect(
          curve.transform(t),
          closeTo(_expected(t, 10), 1e-12),
          reason: 't=$t',
        );
      }
    });

    test('is symmetric around the midpoint', () {
      const curve = UixSCurve(10);
      for (final t in [0.05, 0.1, 0.2, 0.3, 0.45]) {
        expect(curve.transform(t) + curve.transform(1 - t), closeTo(1, 1e-12));
      }
      expect(curve.transform(0.5), closeTo(0.5, 1e-12));
    });

    test('is flat at both ends and steepest at 0.5', () {
      const curve = UixSCurve(10);
      expect(curve.transform(0.01), lessThan(0.01));
      expect(curve.transform(0.99), greaterThan(0.99));
      double slope(double t) =>
          (curve.transform(t + 0.001) - curve.transform(t - 0.001)) / 0.002;
      expect(slope(0.5), greaterThan(slope(0.2)));
      expect(slope(0.5), greaterThan(slope(0.8)));
    });

    test('quarter points for weight 10', () {
      const curve = UixSCurve(10);
      expect(curve.transform(0.25), closeTo(0.120126537, 1e-9));
      expect(curve.transform(0.75), closeTo(0.879873463, 1e-9));
    });
  });
}
