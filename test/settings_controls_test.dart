import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/list_item.dart';
import 'package:metro_ui/widgets/toggle_switch.dart';

void main() {
  testWidgets(
    'list entries expose header/subheader and disabled taps are ignored',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              DoubleLineListItem(
                headerText: 'Wi-Fi',
                subHeaderText: '已开启',
                onTap: () => taps++,
              ),
              SingleLineListItem(
                headerText: '关于',
                enabled: false,
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Wi-Fi'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      await tester.tap(find.text('关于'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(find.text('已开启'), findsOneWidget);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'settings switch status, hit area and long text in $brightness',
      (tester) async {
        var value = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: StatefulBuilder(
              builder: (context, update) => Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 320,
                  child: ToggleSwitch(
                    label: '自动调整屏幕亮度和显示效果',
                    description: '根据周围光线自动调整亮度。',
                    value: value,
                    onLabel: '开启',
                    offLabel: '关闭',
                    onChanged: (v) => update(() => value = v),
                  ),
                ),
              ),
            ),
          ),
        );
        final size = tester.getSize(find.byType(ToggleSwitchBase));
        expect(size.width, closeTo(108.8, 1e-8));
        expect(size.height, closeTo(73.6, 1e-8));
        expect(find.text('关闭'), findsOneWidget);
        await tester.tap(find.byType(ToggleSwitchBase));
        await tester.pumpAndSettle();
        expect(value, isTrue);
        expect(find.text('开启'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('switch drag changes state and cancel restores position', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, update) => Center(
            child: ToggleSwitchBase(
              value: value,
              onChanged: (v) => update(() => value = v),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ToggleSwitchBase)),
    );
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(value, isTrue);
    final cancel = await tester.startGesture(
      tester.getCenter(find.byType(ToggleSwitchBase)),
    );
    await cancel.moveBy(const Offset(-25, 0));
    await cancel.cancel();
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });
  testWidgets(
    'description is optional and disabled settings switch ignores taps',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ToggleSwitch(value: true, label: '位置', onLabel: '开启'),
        ),
      );
      await tester.tap(find.byType(ToggleSwitchBase));
      await tester.pumpAndSettle();
      expect(find.text('开启'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
