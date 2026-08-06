import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/swipe_page_view.dart';
import 'package:metro_ui/widgets/swipe_title_indicator.dart';

void main() {
  Widget buildHost({
    List<SwipePageItem>? items,
    SwipeTitleAlign align = SwipeTitleAlign.start,
    double titleGap = 24.0,
    OnPageChanged? onPageChanged,
    OnSlideProgress? onSlideProgress,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SwipePages(
          items: items ??
              [
                const SwipePageItem(
                  title: Text('A'),
                  page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
                ),
                const SwipePageItem(
                  title: Text('B'),
                  page: ColoredBox(color: Colors.green, child: SizedBox.expand()),
                ),
                const SwipePageItem(
                  title: Text('C'),
                  page: ColoredBox(color: Colors.blue, child: SizedBox.expand()),
                ),
              ],
          // 显式指定参数，与默认值解耦
          swipeThreshold: 50,
          maxDragDistance: 150,
          flyDuration: const Duration(milliseconds: 100),
          fadeDuration: const Duration(milliseconds: 50),
          snapBackDuration: const Duration(milliseconds: 120),
          align: align,
          titleGap: titleGap,
          onPageChanged: onPageChanged,
          onSlideProgress: onSlideProgress,
        ),
      ),
    );
  }

  /// 读取标题条 Transform 的水平位移。
  double barOffset(WidgetTester tester, String key) {
    final t = tester.widget<Transform>(find.byKey(ValueKey(key)));
    return t.transform.getTranslation().x;
  }

  testWidgets('三页：同时显示上一页/当前页/下一页三个标题', (tester) async {
    await tester.pumpWidget(buildHost());
    await tester.pump(); // 等待宽度测量

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    // 当前页索引 0 → 中心标题为 A（bar-0）
    expect(find.byKey(const ValueKey('bar-0')), findsOneWidget);
  });

  testWidgets('单页：只显示一个标题', (tester) async {
    await tester.pumpWidget(buildHost(items: [
      const SwipePageItem(
        title: Text('A'),
        page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
      ),
    ]));
    await tester.pump();

    expect(find.text('A'), findsOneWidget);
    // 只有一个标题，无左右标题
    expect(find.byKey(const ValueKey('bar-0')), findsOneWidget);
  });

  testWidgets('双页：当前 A 时显示 B A B', (tester) async {
    await tester.pumpWidget(buildHost(items: [
      const SwipePageItem(
        title: Text('A'),
        page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
      ),
      const SwipePageItem(
        title: Text('B'),
        page: ColoredBox(color: Colors.green, child: SizedBox.expand()),
      ),
    ]));
    await tester.pump();

    expect(find.text('A'), findsOneWidget); // 中心
    expect(find.text('B'), findsNWidgets(2)); // 左右都是 B
  });

  testWidgets('拖动（不松手）时标题条跟随移动：右拖右移，方向与手指一致', (tester) async {
    await tester.pumpWidget(buildHost());
    await tester.pump(); // 等待宽度测量

    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(60, 0)); // progress = 60/150 = 0.4
    await tester.pump();

    // 标题条整体移动「当前标题宽度 × progress」，右拖（progress>0）→ 右移（正）
    final offset = barOffset(tester, 'bar-0');
    expect(offset, greaterThan(0));

    await g.up();
    await tester.pump();
  });

  testWidgets('当前标题左对齐父容器左侧', (tester) async {
    await tester.pumpWidget(buildHost());
    await tester.pump(); // 等待宽度测量

    // bar-0：C(左) A(中) B(右)
    // A 左边缘对齐父容器左侧（x ≈ 0）
    expect(tester.getTopLeft(find.text('A')).dx, closeTo(0, 1));

    // C 在 A 左侧：C 右边缘 ≈ A 左边缘 - titleGap(24)
    final aLeft = tester.getTopLeft(find.text('A')).dx;
    expect(tester.getTopRight(find.text('C')).dx,
        closeTo(aLeft - 24, 1));

    // B 在 A 右侧：B 左边缘 ≈ A 右边缘 + titleGap(24)
    final aRight = tester.getTopRight(find.text('A')).dx;
    expect(tester.getTopLeft(find.text('B')).dx,
        closeTo(aRight + 24, 1));
  });

  testWidgets('center 模式：当前标题水平居中于父容器', (tester) async {
    await tester.pumpWidget(buildHost(align: SwipeTitleAlign.center));
    await tester.pump(); // 等待宽度测量

    // 测试屏幕宽 800，当前标题 A 的中心应在 400 附近
    expect(tester.getCenter(find.text('A')).dx, closeTo(400, 2));

    // 左侧标题 C 在 A 左侧（间隔 gap），右侧标题 B 在 A 右侧
    final aLeft = tester.getTopLeft(find.text('A')).dx;
    expect(tester.getTopRight(find.text('C')).dx, closeTo(aLeft - 24, 1));
    expect(tester.getTopLeft(find.text('B')).dx,
        closeTo(tester.getTopRight(find.text('A')).dx + 24, 1));
  });

  testWidgets('end 模式：当前标题右对齐父容器右侧', (tester) async {
    await tester.pumpWidget(buildHost(align: SwipeTitleAlign.end));
    await tester.pump(); // 等待宽度测量

    // 测试屏幕宽 800，当前标题 A 右边缘应在 800 附近
    expect(tester.getTopRight(find.text('A')).dx, closeTo(800, 1));

    // 左侧标题 C 在 A 左侧（间隔 gap），B 在屏幕外（A 右侧）
    final aLeft = tester.getTopLeft(find.text('A')).dx;
    expect(tester.getTopRight(find.text('C')).dx, closeTo(aLeft - 24, 1));
    expect(tester.getTopLeft(find.text('B')).dx, greaterThan(800));
  });

  testWidgets('center 模式：换页动画结束后新标题仍居中', (tester) async {
    await tester.pumpWidget(buildHost(align: SwipeTitleAlign.center));
    await tester.pump();

    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(60, 0)); // 右滑 → 上一页（C）
    await tester.pump();
    await g.up();

    await tester.pump(); // 触发换页
    await tester.pump(const Duration(milliseconds: 300)); // 动画结束

    // 新当前标题 C 中心应仍在父容器中心（400）
    expect(find.text('C'), findsOneWidget);
    expect(tester.getCenter(find.text('C')).dx, closeTo(400, 2));
  });

  testWidgets('end 模式：换页动画结束后新标题仍右对齐', (tester) async {
    await tester.pumpWidget(buildHost(align: SwipeTitleAlign.end));
    await tester.pump();

    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(-60, 0)); // 左滑 → 下一页（B）
    await tester.pump();
    await g.up();

    await tester.pump(); // 触发换页
    await tester.pump(const Duration(milliseconds: 300)); // 动画结束

    // 新当前标题 B 右边缘应仍在父容器右侧（800）
    expect(find.text('B'), findsOneWidget);
    expect(tester.getTopRight(find.text('B')).dx, closeTo(800, 2));
  });

  testWidgets('start 模式右拖满：标题移动量 = 上一个标题宽度（恰好归位）', (tester) async {
    await tester.pumpWidget(buildHost(titleGap: 0));
    await tester.pump(); // 等待宽度测量

    final wPrev = tester.getSize(find.text('C')).width; // A 的上一页是 C
    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(150, 0)); // progress = 150/150 = 1
    await tester.pump();

    // 右拖满：移动量 = 上一个标题宽度 → C 恰好处于归位位置
    expect(barOffset(tester, 'bar-0'), closeTo(wPrev, 1));

    await g.up();
    await tester.pump();
  });

  testWidgets('start 模式左拖满：标题移动量 = 当前标题宽度', (tester) async {
    await tester.pumpWidget(buildHost(titleGap: 0));
    await tester.pump(); // 等待宽度测量

    final wCur = tester.getSize(find.text('A')).width;
    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(-150, 0)); // progress = -1
    await tester.pump();

    expect(barOffset(tester, 'bar-0'), closeTo(-wCur, 1));

    await g.up();
    await tester.pump();
  });

  testWidgets('右拖满且带 titleGap：移动量 = 上一个标题宽度 + 间距', (tester) async {
    await tester.pumpWidget(buildHost(titleGap: 24));
    await tester.pump(); // 等待宽度测量

    final wPrev = tester.getSize(find.text('C')).width;
    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(150, 0)); // progress = 1
    await tester.pump();

    expect(barOffset(tester, 'bar-0'), closeTo(wPrev + 24, 1));

    await g.up();
    await tester.pump();
  });

  testWidgets('非当前页标题带 50% 透明滤镜', (tester) async {
    await tester.pumpWidget(buildHost());
    await tester.pump(); // 等待宽度测量

    // 三页：bar-0 为中心（A），左右为 B、C
    // 遍历所有 Opacity 找到对应标题：中心 100%，左右 50%
    double opacityOf(String text) {
      // 找到包含该文本的标题，再找其最近的 Opacity 祖先
      final textFinder = find.descendant(
        of: find.byKey(const ValueKey('bar-0')),
        matching: find.text(text),
      );
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(of: textFinder, matching: find.byType(Opacity))
            .first,
      );
      return opacity.opacity;
    }

    expect(opacityOf('A'), 1.0); // 当前标题 100%
    expect(opacityOf('B'), 0.5); // 非当前 50%
    expect(opacityOf('C'), 0.5); // 非当前 50%
  });

  testWidgets('松手换页后标题组更新，新标题条停在中心', (tester) async {
    final changed = <String>[];
    await tester.pumpWidget(buildHost(onPageChanged: (o, n) {
      changed.add('$o->$n');
    }));
    await tester.pump();

    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(60, 0)); // 右滑 → 上一页
    await tester.pump();
    await g.up();

    await tester.pump(); // 触发换页
    await tester.pump(const Duration(milliseconds: 300)); // 动画结束

    // 新当前索引 -1 → 中心标题为 C（(-1)%3 = 2），显示 B C A
    expect(changed, ['0->-1']);
    expect(find.byKey(const ValueKey('bar-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-0')), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    // 动画结束后新条停在中心（位移为 0）
    expect(barOffset(tester, 'bar-2'), 0);
  });

  testWidgets('SwipeStackPages：标题悬浮在页面顶部，拖动换页同步', (tester) async {
    final changed = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SwipeStackPages(
          items: const [
            SwipePageItem(
              title: Text('A'),
              page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
            ),
            SwipePageItem(
              title: Text('B'),
              page: ColoredBox(color: Colors.green, child: SizedBox.expand()),
            ),
            SwipePageItem(
              title: Text('C'),
              page: ColoredBox(color: Colors.blue, child: SizedBox.expand()),
            ),
          ],
          swipeThreshold: 50,
          maxDragDistance: 150,
          flyDuration: const Duration(milliseconds: 100),
          fadeDuration: const Duration(milliseconds: 50),
          snapBackDuration: const Duration(milliseconds: 120),
          onPageChanged: (o, n) => changed.add('$o->$n'),
        ),
      ),
    ));
    await tester.pump(); // 等待宽度测量

    // 三个标题同时显示（悬浮在页面之上）
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);

    // 标题位于屏幕顶部区域（A 标题的 y 坐标很小）
    expect(tester.getTopLeft(find.text('A')).dy, lessThan(100));

    // 从标题之外的页面区域拖动（标题区域本身响应点击，不挡页面其余区域）
    final g = await tester.startGesture(const Offset(200, 400));
    await g.moveBy(const Offset(60, 0)); // 右滑 → 上一页
    await tester.pump();
    await g.up();

    await tester.pump(); // 触发换页
    await tester.pump(const Duration(milliseconds: 300)); // 动画结束

    expect(changed, ['0->-1']);
    // 新当前页 C 成为中心标题
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('SwipeStackPages：indicatorAlign 控制标题悬浮位置', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SwipeStackPages(
          items: [
            SwipePageItem(
              title: Text('A'),
              page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
            ),
            SwipePageItem(
              title: Text('B'),
              page: ColoredBox(color: Colors.green, child: SizedBox.expand()),
            ),
          ],
          align: SwipeTitleAlign.start,
          indicatorAlign: Alignment.topLeft,
          indicatorPadding: EdgeInsets.zero,
        ),
      ),
    ));
    await tester.pump();

    // 左对齐 + topLeft：当前标题 A 左边缘贴容器左上角
    expect(tester.getTopLeft(find.text('A')).dx, closeTo(0, 1));
    expect(tester.getTopLeft(find.text('A')).dy, closeTo(0, 1));
  });

  testWidgets('点击半透明标题切换到对应页（SwipePages）', (tester) async {
    final changed = <String>[];
    await tester.pumpWidget(
      buildHost(onPageChanged: (o, n) => changed.add('$o->$n')),
    );
    await tester.pump(); // 等待宽度测量

    // 当前 A，点击下一页标题 B → 切到第 1 页
    await tester.tap(find.text('B'));
    await tester.pump(); // 触发换页
    await tester.pump(const Duration(milliseconds: 300)); // 动画结束

    expect(changed, ['0->1']);
    expect(find.text('B'), findsOneWidget);

    // 现在当前 B（start 对齐下 prev 标题 A 在屏幕外），点击下一页标题 C
    // → 切到第 2 页
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(changed, ['0->1', '1->2']);
  });

  testWidgets('SwipeStackPages：点击悬浮标题切换到对应页', (tester) async {
    final changed = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SwipeStackPages(
          items: const [
            SwipePageItem(
              title: Text('A'),
              page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
            ),
            SwipePageItem(
              title: Text('B'),
              page: ColoredBox(color: Colors.green, child: SizedBox.expand()),
            ),
            SwipePageItem(
              title: Text('C'),
              page: ColoredBox(color: Colors.blue, child: SizedBox.expand()),
            ),
          ],
          swipeThreshold: 50,
          maxDragDistance: 150,
          flyDuration: const Duration(milliseconds: 100),
          fadeDuration: const Duration(milliseconds: 50),
          snapBackDuration: const Duration(milliseconds: 120),
          onPageChanged: (o, n) => changed.add('$o->$n'),
        ),
      ),
    ));
    await tester.pump(); // 等待宽度测量

    // 当前 A（start 对齐下 prev 标题 C 在屏幕外），点击下一页标题 B
    // → 切到第 1 页
    await tester.tap(find.text('B'));
    await tester.pump(); // 触发换页
    await tester.pump(const Duration(milliseconds: 300)); // 动画结束

    expect(changed, ['0->1']);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('换页动画期间：整体向右推入，新条从左侧滑入，旧条渐隐新条渐显', (tester) async {
    await tester.pumpWidget(buildHost());
    await tester.pump();

    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(60, 0));
    await tester.pump();
    await g.up();

    // 换页动画刚开始：新旧两条同时存在
    await tester.pump();
    expect(find.byKey(const ValueKey('bar-0-old')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-2-new')), findsOneWidget);

    // 推进 20ms，动画进行中
    await tester.pump(const Duration(milliseconds: 20));

    // 右滑 → 上一页：整体向右推入（旧条继续右移，offset > 0）
    final oldOffset = barOffset(tester, 'bar-0-old');
    final newOffset = barOffset(tester, 'bar-2-new');
    expect(oldOffset, greaterThan(0)); // 向右推入
    expect(newOffset, lessThan(oldOffset)); // 新条位于旧条左侧（从左侧推入）

    // 旧条渐隐（opacity < 1）、新条渐显（opacity > 0 且 < 1）
    final oldOpacity = tester
        .widget<Opacity>(find
            .ancestor(
              of: find.descendant(
                of: find.byKey(const ValueKey('bar-0-old')),
                matching: find.text('A'),
              ),
              matching: find.byType(Opacity),
            )
            .first)
        .opacity;
    final newOpacity = tester
        .widget<Opacity>(find
            .ancestor(
              of: find.descendant(
                of: find.byKey(const ValueKey('bar-2-new')),
                matching: find.text('C'),
              ),
              matching: find.byType(Opacity),
            )
            .first)
        .opacity;
    expect(oldOpacity, lessThan(1.0)); // 旧条渐隐（C 渐变消失）
    expect(newOpacity, greaterThan(0.0)); // 新条渐显（D 渐变显示）
    expect(newOpacity, lessThan(1.0));

    // 动画结束后只剩新条
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('bar-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-0-old')), findsNothing);
    expect(find.byKey(const ValueKey('bar-2-new')), findsNothing);
  });
}
