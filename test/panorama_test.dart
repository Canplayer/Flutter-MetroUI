import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/panorama.dart';

/// 依据 WP8 `UIXMobile` Panorama 的静态分析结果校验布局、视差与吸附：
/// 设计宽度 480×0.8 = 384，Pane 宽 408×0.8 = 326.4，
/// 间距/右侧预露 24×0.8 = 19.2，归位 800ms Log(300)。
List<MetroPanoramaItem> _items({double wideWidth = 0}) => [
  for (int i = 0; i < 4; i++)
    MetroPanoramaItem(
      title: Text('header$i'),
      width: i == 2 ? wideWidth : 0,
      child: Text('body$i'),
    ),
];

Future<void> _pump(
  WidgetTester tester,
  List<MetroPanoramaItem> items, {
  Widget title = const Text('photos'),
}) async {
  tester.view.physicalSize = const Size(384, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 384,
          height: 800,
          child: MetroPanorama(title: title, items: items),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _pixels(WidgetTester tester) {
  final ScrollableState scrollable = tester.state<ScrollableState>(
    find.byType(Scrollable).first,
  );
  return scrollable.position.pixels;
}

/// 返回所有标题副本的左边缘（升序）。
List<double> _titleCopyLefts(WidgetTester tester, [String text = 'photos']) {
  final List<double> lefts = [
    for (final Element element in find.text(text).evaluate())
      (element.renderObject! as RenderBox).localToGlobal(Offset.zero).dx,
  ]..sort();
  return lefts;
}

/// 返回离视口最近的标题副本的左边缘；全部飞出时返回 NaN。
double _visibleTitleLeft(WidgetTester tester, [String text = 'photos']) {
  double? best;
  double bestDistance = double.infinity;
  for (final Element element in find.text(text).evaluate()) {
    final RenderBox box = element.renderObject! as RenderBox;
    final Offset origin = box.localToGlobal(Offset.zero);
    if (origin.dx + box.size.width <= 0 || origin.dx >= 384) continue;
    if (origin.dx.abs() < bestDistance) {
      bestDistance = origin.dx.abs();
      best = origin.dx;
    }
  }
  return best ?? double.nan;
}

Future<void> _drag(WidgetTester tester, double dx) async {
  await tester.drag(find.byType(MetroPanorama), Offset(dx, 0));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Pane 宽度 326.4、间距与右侧预露 19.2（408/24 × 0.8）', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _items());

    expect(tester.getTopLeft(find.text('header0')).dx, closeTo(19.2, 0.6));

    // 第 2 个 Pane 的 header 起点 = 345.6 + 19.2 = 364.8，屏宽 384
    final double header1Left = tester.getTopLeft(find.text('header1')).dx;
    expect(header1Left, closeTo(364.8, 0.6));
    expect(384.0 - header1Left, closeTo(19.2, 0.6));
  });

  testWidgets('布局常量与 WP8 480×800 资源一致（×0.8）', (WidgetTester tester) async {
    await _pump(tester, _items());

    // 大标题：层 top = −75×0.8，文本再 +41×0.8，左边距 0（贴左边缘）
    final Rect titleRect = tester.getRect(find.text('photos').first);
    expect(titleRect.left, closeTo(0.0, 0.5));
    expect(titleRect.top, closeTo((-75 + 41) * 0.8, 0.5));

    // Pane 内容顶部 = PanoramaVScrollContentMargins.top(198)×0.8
    expect(tester.getTopLeft(find.text('header0')).dy, closeTo(198 * 0.8, 0.5));

    // Pane 标题字号 = PanoramaGroupHeaderFontSize(50)×0.8
    final DefaultTextStyle headerStyle = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('header0'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    expect(headerStyle.style.fontSize, closeTo(50 * 0.8, 0.01));
  });

  testWidgets('可见宽度规则：未过半吸附回原页，过半吸附到下一页', (WidgetTester tester) async {
    await _pump(tester, _items());

    // 阈值 = 345.6 + 163.2 = 508.8（含触摸 slop）
    await _drag(tester, -220);
    expect(_pixels(tester), closeTo(345.6, 1.0));

    await _drag(tester, -220);
    expect(_pixels(tester), closeTo(691.2, 1.0));

    // 反向拖动不足时回到当前 Pane
    await _drag(tester, 150);
    expect(_pixels(tester), closeTo(691.2, 1.0));
  });

  testWidgets('松手归位为 800ms，曲线 Log(300)', (WidgetTester tester) async {
    await _pump(tester, _items());

    await tester.drag(find.byType(MetroPanorama), const Offset(-220, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final double half = _pixels(tester);
    // Log(300) 前快后慢：t=0.5 已完成约 94.5%，但尚未结束
    expect(half, greaterThan(300.0));
    expect(half, lessThan(345.0));

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(_pixels(tester), closeTo(345.6, 1.0));
  });

  testWidgets('拖动按 D/T 连续视差，松手按 Pane 宽度累加的目标定位', (WidgetTester tester) async {
    await _pump(tester, _items());

    // TitleWidth = max(实测排版宽度, 屏宽)，D = TitleWidth − 4⌊屏宽/5⌋
    final double titleWidth = tester.getSize(find.text('photos').first).width;
    final double travel = math.max(titleWidth, 384.0) - 76 * 4;
    // T = Σ Pane.MaxWidth + (n − 1) × ContentSpacing
    final double ratio = travel / (4 * 326.4 + 3 * 19.2);

    // 拖到第二页刚好对齐的位置但不松手
    final TestGesture gesture = await tester.startGesture(
      const Offset(60, 400),
    );
    await gesture.moveBy(const Offset(-364, 0));
    await tester.pump();
    final double released = _pixels(tester);
    final double during = _visibleTitleLeft(tester);
    expect(during, closeTo(0 - released * ratio, 0.8));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_pixels(tester), closeTo(345.6, 1.0));

    // 锁定目标只累加 Pane 宽度（不含间距）→ 比松手位置略靠右
    final double settled = _visibleTitleLeft(tester);
    expect(settled, closeTo(0 - 326.4 * ratio, 0.8));
    expect(settled - during, closeTo((released - 326.4) * ratio, 0.3));
  });

  testWidgets('普通 Pane 的标题没有额外视差，只随 Pane 移动', (WidgetTester tester) async {
    await _pump(tester, _items());

    final double before = tester.getTopLeft(find.text('header0')).dx;
    final double p0 = _pixels(tester);

    final TestGesture gesture = await tester.startGesture(
      const Offset(300, 400),
    );
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();

    final double during = tester.getTopLeft(find.text('header0')).dx;
    final double dragged = _pixels(tester) - p0;
    expect(dragged, greaterThan(50.0));
    expect(during, closeTo(before - dragged, 0.6));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('TitleWidth 取实测排版宽度（超过屏宽时）', (WidgetTester tester) async {
    const String longTitle = 'a very long panorama title that overflows';
    await _pump(tester, _items(), title: const Text(longTitle));

    final double measured = tester.getSize(find.text(longTitle).first).width;
    expect(measured, greaterThan(384.0));
    final double travel = measured - 76 * 4;

    final double ratio = travel / (4 * 326.4 + 3 * 19.2);
    await _drag(tester, -220);
    // 锁定目标 = −Σ Pane 宽度 × D / T
    expect(
      _visibleTitleLeft(tester, longTitle),
      closeTo(0 - 326.4 * ratio, 0.8),
    );
  });

  testWidgets('宽 Pane 的标题额外偏移 = d / 1.18', (WidgetTester tester) async {
    await _pump(tester, _items(wideWidth: 800));

    await _drag(tester, -220);
    await _drag(tester, -220);
    expect(_pixels(tester), closeTo(691.2, 1.0));

    final double before = tester.getTopLeft(find.text('header2')).dx;
    final double p0 = _pixels(tester);

    final TestGesture gesture = await tester.startGesture(
      const Offset(300, 400),
    );
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();

    final double during = tester.getTopLeft(find.text('header2')).dx;
    final double dragged = _pixels(tester) - p0;
    expect(dragged, greaterThan(50.0));
    expect(during, closeTo(before - dragged + dragged / 1.18, 1.0));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('首尾按相邻页处理：第一页 ↔ 最后一页', (WidgetTester tester) async {
    await _pump(tester, _items());

    // 第一页往回拖 100px：不足阈值，回到第一页（不能跨整轮）
    await _drag(tester, 100);
    expect(_pixels(tester), closeTo(0.0, 1.0));

    // 往回拖过阈值：只后退一页到最后一个 Pane（-1 → 取模显示末页）
    await _drag(tester, 250);
    expect(_pixels(tester), closeTo(-345.6, 1.0));

    // 再往前拖一页：回到第一页
    await _drag(tester, -220);
    expect(_pixels(tester), closeTo(0.0, 1.0));

    // 一路推进到末页
    await _drag(tester, -220);
    expect(_pixels(tester), closeTo(345.6, 1.0));
    await _drag(tester, -220);
    expect(_pixels(tester), closeTo(691.2, 1.0));
    await _drag(tester, -220);
    expect(_pixels(tester), closeTo(1036.8, 1.0));

    // 末页继续前进 → 下一轮的第一页（4 → 取模显示 0）
    await _drag(tester, -220);
    expect(_pixels(tester), closeTo(1382.4, 1.0));

    // 跨代之后标题回到第一页的锁定位置，循环接缝处不跳变
    expect(_visibleTitleLeft(tester), closeTo(0.0, 2.5));
  });

  testWidgets('首跨末：拖动小幅视差，松手后标题飞出并由相邻副本接替', (WidgetTester tester) async {
    await _pump(tester, _items());

    final double titleWidth = tester.getSize(find.text('photos').first).width;
    final double travel = math.max(titleWidth, 384.0) - 76 * 4;
    final double ratio = travel / (4 * 326.4 + 3 * 19.2);
    final double start = _visibleTitleLeft(tester);
    expect(start, closeTo(0.0, 0.6)); // 标题贴左边缘（margin.left = 0）

    // 按住向右拖：拖动阶段只按 D/T 累计（很小），且方向向右
    final TestGesture gesture = await tester.startGesture(
      const Offset(100, 400),
    );
    await gesture.moveBy(const Offset(250, 0));
    await tester.pump();
    final double dragged = -_pixels(tester);
    expect(dragged, greaterThan(200.0));
    expect(_visibleTitleLeft(tester), closeTo(start + dragged * ratio, 0.8));
    final List<double> before = _titleCopyLefts(tester);
    await gesture.up();

    // 松手：目标在前一代（相距一个循环周期），整层向右平移一个周期左右，
    // 即当前标题从右侧飞出、另一份从左侧进入。
    for (int i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    final List<double> after = _titleCopyLefts(tester);
    expect(after.first - before.first, greaterThan(300.0));
    expect(after.last - before.last, greaterThan(300.0));

    await tester.pumpAndSettle();
    expect(_pixels(tester), closeTo(-345.6, 1.0));
    // 末页锁定位置 = −Σ(前 3 个 Pane 宽度) × D / T
    expect(_visibleTitleLeft(tester), closeTo(0 - 3 * 326.4 * ratio, 0.8));
  });

  testWidgets('倒退进入宽 Pane 时右锁定', (WidgetTester tester) async {
    await _pump(tester, _items(wideWidth: 800));

    await _drag(tester, -220);
    await _drag(tester, -220);
    await tester.fling(find.byType(MetroPanorama), const Offset(-100, 0), 1200);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(MetroPanorama), const Offset(-260, 0), 1200);
    await tester.pumpAndSettle();
    expect(_pixels(tester), closeTo(1510.4, 1.0));

    // 往回拖：前一个 Pane 比屏幕宽 → 右锁定（691.2 + 473.6）
    await _drag(tester, 250);
    expect(_pixels(tester), closeTo(1164.8, 1.0));

    // 标题目标由所选 Pane 的锁定比例单独算出（累加前 2 个 Pane 的 MaxWidth），
    // 不是把正向目标镜像过来
    final double titleWidth = tester.getSize(find.text('photos').first).width;
    final double travel = math.max(titleWidth, 384.0) - 76 * 4;
    final double ratio = travel / (345.6 + 345.6 + 800 + 345.6 + 3 * 19.2);
    expect(_visibleTitleLeft(tester), closeTo(0 - 2 * 326.4 * ratio, 1.0));
  });

  testWidgets('宽 Pane 内部可停住，快速甩动吸附到右锁定点', (WidgetTester tester) async {
    await _pump(tester, _items(wideWidth: 800));

    await _drag(tester, -220);
    await _drag(tester, -220);
    expect(_pixels(tester), closeTo(691.2, 1.0));

    // 慢速停在宽 Pane 内部：不强制吸附
    await _drag(tester, -300);
    expect(_pixels(tester), greaterThan(691.2 + 100));
    expect(_pixels(tester), lessThan(691.2 + 473.6 - 100));

    // 快甩：先锁到右锁定点（内部范围 819.2 − (384 − 38.4) = 473.6）
    await tester.fling(find.byType(MetroPanorama), const Offset(-100, 0), 1200);
    await tester.pumpAndSettle();
    expect(_pixels(tester), closeTo(691.2 + 473.6, 1.0));

    // 再甩一次进入下一个 Pane
    await tester.fling(find.byType(MetroPanorama), const Offset(-260, 0), 1200);
    await tester.pumpAndSettle();
    expect(_pixels(tester), closeTo(691.2 + 819.2, 1.0));
  });
}
