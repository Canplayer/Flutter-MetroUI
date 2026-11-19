import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/uix_metrics.dart';

void main() {
  test('WP8 480 design units map to 384 logical pixels', () {
    expect(480 * uixScale, 384);
    expect(uixFontSize(50), closeTo(160 / 3, .000001));
  });
}
