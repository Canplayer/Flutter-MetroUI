import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/uix_typography.dart';
import 'package:metro_ui/widgets/page_header.dart';
import 'package:metro_ui/widgets/uix_text.dart';

void main() {
  testWidgets('PageHeader lays out the system title and single-pivot header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(384, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MetroApp(
        home: MetroPageScaffold(
          disableDefaultPushAnimation: true,
          header: MetroPageHeader(
            title: Text('SETTINGS'),
            singlePivotHeader: Text('phone'),
          ),
          body: SizedBox.expand(key: ValueKey('body')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final lines = find.byType(UixText);
    expect(lines, findsNWidgets(2));
    final title = tester.getRect(lines.at(0));
    final singlePivotHeader = tester.getRect(lines.at(1));
    final body = tester.getRect(find.byKey(const ValueKey('body')));
    expect(title.left, closeTo(24 * uixScale, .001));
    expect(title.top, closeTo(56 * uixScale, .001));
    expect(singlePivotHeader.top - title.bottom, closeTo(24 * uixScale, .001));
    expect(body.top - singlePivotHeader.bottom, closeTo(56 * uixScale, .001));

    final titleStyle = DefaultTextStyle.of(tester.element(lines.at(0))).style;
    final headerStyle = DefaultTextStyle.of(tester.element(lines.at(1))).style;
    expect(titleStyle.fontSize, uixFontSize(17));
    expect(titleStyle.fontWeight, UixFontWeight.semiBold);
    expect(headerStyle.fontSize, uixFontSize(54));
    expect(headerStyle.fontWeight, UixFontWeight.semiLight);
  });
}
