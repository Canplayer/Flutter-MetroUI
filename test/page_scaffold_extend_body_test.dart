import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/page_scaffold.dart';

/// 验证 MetroPageScaffold.extendBodyToApplicationBar 的行为。
///
/// 场景说明：屏幕逻辑尺寸 800x600，body 底部放置一个贴底的标记块。
/// - extendBodyToApplicationBar=true（默认）：body 延伸到 AppBar 下方，不被抬升。
/// - false 且当前页面存在 AppBar：抬升高度 = 折叠高度（mini/非 mini）+ 底部安全区。
/// - false 但当前页面无 AppBar：不抬升（不生效）。
void main() {
  const double screenHeight = 600.0;

  Future<void> pumpHost(
    WidgetTester tester, {
    required MetroApplicationBar? applicationBar,
    bool extendBodyToApplicationBar = true,
    double bottomPadding = 0.0,
  }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding =
        FakeViewPadding(left: 0, top: 0, right: 0, bottom: bottomPadding);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MetroApp(
        home: MetroPageScaffold(
          extendBodyToApplicationBar: extendBodyToApplicationBar,
          applicationBar: applicationBar,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              key: const Key('bottom-marker'),
              width: 40,
              height: 20,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );

    // postFrameCallback：注册 AppBar 到全局控制器 + 播放进入动画
    await tester.pump();
    // 推进进入动画（含多段动画链）完成
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  double markerBottomY(WidgetTester tester) {
    return tester.getBottomLeft(find.byKey(const Key('bottom-marker'))).dy;
  }

  MetroApplicationBar normalBar() => MetroApplicationBar(
        buttons: [
          const MetroAppBarButton(
            icon: Icon(Icons.add),
            label: '新建',
            onPressed: null,
          ),
        ],
      );

  testWidgets('默认 true：body 延伸到 AppBar 下方，不抬升', (tester) async {
    await pumpHost(tester, applicationBar: normalBar());

    expect(markerBottomY(tester), closeTo(screenHeight, 0.01),
        reason: '默认 true 时 body 底部应贴屏，不被 AppBar 让出');
  });

  testWidgets('false + 非 mini：抬升到正常折叠高度', (tester) async {
    await pumpHost(
      tester,
      applicationBar: normalBar(),
      extendBodyToApplicationBar: false,
    );

    expect(markerBottomY(tester), closeTo(screenHeight - 57.6, 0.01),
        reason: '非 mini 折叠高度 kMetroAppBarNormalHeight = 72*0.8 = 57.6');
  });

  testWidgets('false + mini：抬升到 mini 折叠高度', (tester) async {
    await pumpHost(
      tester,
      applicationBar: MetroApplicationBar(
        mini: true,
        buttons: [const MetroAppBarButton(icon: Icon(Icons.add), label: '新建')],
      ),
      extendBodyToApplicationBar: false,
    );

    expect(markerBottomY(tester), closeTo(screenHeight - 24.0, 0.01),
        reason: 'mini 折叠高度 kMetroAppBarMiniHeight = 30*0.8 = 24.0');
  });

  testWidgets('false + 无按钮（自动按 mini 处理）：抬升到 mini 折叠高度',
      (tester) async {
    await pumpHost(
      tester,
      applicationBar: const MetroApplicationBar(),
      extendBodyToApplicationBar: false,
    );

    expect(markerBottomY(tester), closeTo(screenHeight - 24.0, 0.01),
        reason: 'buttons 为空时自动按 mini 模式处理');
  });

  testWidgets('false + 当前页面无 AppBar：不生效，不抬升', (tester) async {
    await pumpHost(
      tester,
      applicationBar: null,
      extendBodyToApplicationBar: false,
    );

    expect(markerBottomY(tester), closeTo(screenHeight, 0.01),
        reason: '当前页面不存在 Application Bar 时不应抬升');
  });

  testWidgets('false + 非 mini + 底部安全区：抬升高度含安全区', (tester) async {
    await pumpHost(
      tester,
      applicationBar: normalBar(),
      extendBodyToApplicationBar: false,
      bottomPadding: 34.0,
    );

    expect(markerBottomY(tester), closeTo(screenHeight - 57.6 - 34.0, 0.01),
        reason: '抬升高度 = 折叠高度 + 底部安全区（34）');
  });
}
