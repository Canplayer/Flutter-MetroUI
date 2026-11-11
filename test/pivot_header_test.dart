import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/pivot_pane_view.dart';
import 'package:metro_ui/widgets/pivot.dart';

void main() {
  Widget buildHost({
    List<PivotItem>? items,
    PivotHeaderAlignment align = PivotHeaderAlignment.start,
    double titleGap = 24.0,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    OnPageChanged? onPageChanged,
    OnSlideProgress? onSlideProgress,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Pivot(
          items:
              items ??
              [
                const PivotItem(
                  title: Text('A'),
                  page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
                ),
                const PivotItem(
                  title: Text('B'),
                  page: ColoredBox(
                    color: Colors.green,
                    child: SizedBox.expand(),
                  ),
                ),
                const PivotItem(
                  title: Text('C'),
                  page: ColoredBox(
                    color: Colors.blue,
                    child: SizedBox.expand(),
                  ),
                ),
              ],
          // 显式指定参数，与默认值解耦
          swipeThreshold: 50,
          maxDragDistance: 150,
          flyDuration: const Duration(milliseconds: 100),
          fadeDuration: const Duration(milliseconds: 50),
          snapBackDuration: const Duration(milliseconds: 120),
          // 换页是「隐藏 → 换内容 → 显示」两段，缩短以便单次 pump 覆盖；
          // 源码值在 pivot_transition_test.dart 里校验。
          hideDuration: const Duration(milliseconds: 100),
          showDuration: const Duration(milliseconds: 100),
          align: align,
          titleGap: titleGap,
          padding: padding,
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

  testWidgets('松手提交换页立即改变标题颜色，位置继续动画', (tester) async {
    await tester.pumpWidget(buildHost());
    await tester.pumpAndSettle();
    Color? color(String title) =>
        DefaultTextStyle.of(tester.element(find.text(title).first)).style.color;
    final active = color('A');
    final inactive = color('B');
    expect(active, isNot(inactive));
    final gesture = await tester.startGesture(const Offset(400, 300));
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(color('A'), active);
    expect(color('B'), inactive);
    final releaseOffset = barOffset(tester, 'bar-0');
    await gesture.up();
    await tester.pump();
    expect(color('B'), active);
    expect(color('A'), inactive);
    expect(barOffset(tester, 'bar-0'), closeTo(releaseOffset, .001));
    await tester.pump(const Duration(milliseconds: 40));
    expect(color('B'), active);
    expect(find.byKey(const ValueKey('bar-0')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(color('B'), active);
    expect(tester.takeException(), isNull);
  });

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
    await tester.pumpWidget(
      buildHost(
        items: [
          const PivotItem(
            title: Text('A'),
            page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('A'), findsOneWidget);
    // 只有一个标题，无左右标题
    expect(find.byKey(const ValueKey('bar-0')), findsOneWidget);
  });

  testWidgets('双页：当前 A 时显示 B A B', (tester) async {
    await tester.pumpWidget(
      buildHost(
        items: [
          const PivotItem(
            title: Text('A'),
            page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
          ),
          const PivotItem(
            title: Text('B'),
            page: ColoredBox(color: Colors.green, child: SizedBox.expand()),
          ),
        ],
      ),
    );
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
    expect(tester.getTopRight(find.text('C')).dx, closeTo(aLeft - 24, 1));

    // B 在 A 右侧：B 左边缘 ≈ A 右边缘 + titleGap(24)
    final aRight = tester.getTopRight(find.text('A')).dx;
    expect(tester.getTopLeft(find.text('B')).dx, closeTo(aRight + 24, 1));
  });

  testWidgets('Pivot 默认整体内边距：水平 19.2（HorizontalPagePadding）', (tester) async {
    // 不指定 padding → 使用默认 EdgeInsets.symmetric(horizontal: 24*0.8)
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Pivot(
            items: [
              PivotItem(
                title: Text('A'),
                page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
              ),
              PivotItem(
                title: Text('B'),
                page: ColoredBox(color: Colors.green, child: SizedBox.expand()),
              ),
            ],
            swipeThreshold: 50,
            maxDragDistance: 150,
          ),
        ),
      ),
    );
    await tester.pump(); // 等待宽度测量

    // 整体内缩 19.2：当前标题 A 左边缘 = 19.2（而非 0）
    expect(
      tester.getTopLeft(find.text('A')).dx,
      closeTo(kPivotPadding.resolve(TextDirection.ltr).left, 0.6),
    );
  });

  testWidgets('center 模式：当前标题水平居中于父容器', (tester) async {
    await tester.pumpWidget(buildHost(align: PivotHeaderAlignment.center));
    await tester.pump(); // 等待宽度测量

    // 测试屏幕宽 800，当前标题 A 的中心应在 400 附近
    expect(tester.getCenter(find.text('A')).dx, closeTo(400, 2));

    // 左侧标题 C 在 A 左侧（间隔 gap），右侧标题 B 在 A 右侧
    final aLeft = tester.getTopLeft(find.text('A')).dx;
    expect(tester.getTopRight(find.text('C')).dx, closeTo(aLeft - 24, 1));
    expect(
      tester.getTopLeft(find.text('B')).dx,
      closeTo(tester.getTopRight(find.text('A')).dx + 24, 1),
    );
  });

  testWidgets('end 模式：当前标题右对齐父容器右侧', (tester) async {
    await tester.pumpWidget(buildHost(align: PivotHeaderAlignment.end));
    await tester.pump(); // 等待宽度测量

    // 测试屏幕宽 800，当前标题 A 右边缘应在 800 附近
    expect(tester.getTopRight(find.text('A')).dx, closeTo(800, 1));

    // 左侧标题 C 在 A 左侧（间隔 gap），B 在屏幕外（A 右侧）
    final aLeft = tester.getTopLeft(find.text('A')).dx;
    expect(tester.getTopRight(find.text('C')).dx, closeTo(aLeft - 24, 1));
    expect(tester.getTopLeft(find.text('B')).dx, greaterThan(800));
  });

  testWidgets('center 模式：换页动画结束后新标题仍居中', (tester) async {
    await tester.pumpWidget(buildHost(align: PivotHeaderAlignment.center));
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
    await tester.pumpWidget(buildHost(align: PivotHeaderAlignment.end));
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

  testWidgets('非当前标题用 PivotColor，当前标题用 TextHighColor', (tester) async {
    // PivotStyle：选中 SelectedPivotColor = TextHighColor（白），
    // 未选中 PivotColor = ThemeResources.PivotColorDark(0x67FFFFFF)/Light。
    // 两者字号相同，只有颜色不同；系统不用透明度滤镜。
    await tester.pumpWidget(buildHost());
    await tester.pump(); // 等待宽度测量

    Color colorOf(String text) {
      final textFinder = find.descendant(
        of: find.byKey(const ValueKey('bar-0')),
        matching: find.text(text),
      );
      final widget = tester.widget<Text>(textFinder);
      final inherited = DefaultTextStyle.of(tester.element(textFinder)).style;
      return widget.style?.color ?? inherited.color!;
    }

    final idle =
        ThemeData.estimateBrightnessForColor(
              Scaffold.of(tester.element(find.text('A')))
                      .widget
                      .backgroundColor ??
                  Colors.white,
            ) ==
            Brightness.dark
        ? kPivotHeaderIdleColorDark
        : kPivotHeaderIdleColorLight;
    expect(colorOf('B'), idle);
    expect(colorOf('C'), idle);
    expect(colorOf('A'), isNot(idle));
  });

  testWidgets('松手换页后标题组更新，新标题条停在中心', (tester) async {
    final changed = <String>[];
    await tester.pumpWidget(
      buildHost(
        onPageChanged: (o, n) {
          changed.add('$o->$n');
        },
      ),
    );
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

  testWidgets('PivotStack：标题悬浮在页面顶部，拖动换页同步', (tester) async {
    final changed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PivotStack(
            items: const [
              PivotItem(
                title: Text('A'),
                page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
              ),
              PivotItem(
                title: Text('B'),
                page: ColoredBox(color: Colors.green, child: SizedBox.expand()),
              ),
              PivotItem(
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
      ),
    );
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

  testWidgets('PivotStack：indicatorAlign 控制标题悬浮位置', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PivotStack(
            items: [
              PivotItem(
                title: Text('A'),
                page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
              ),
              PivotItem(
                title: Text('B'),
                page: ColoredBox(color: Colors.green, child: SizedBox.expand()),
              ),
            ],
            align: PivotHeaderAlignment.start,
            indicatorAlign: Alignment.topLeft,
            indicatorPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
    await tester.pump();

    // 左对齐 + topLeft：当前标题 A 左边缘贴容器左上角
    expect(tester.getTopLeft(find.text('A')).dx, closeTo(0, 1));
    expect(tester.getTopLeft(find.text('A')).dy, closeTo(0, 1));
  });

  testWidgets('点击半透明标题切换到对应页（Pivot）', (tester) async {
    final changed = <String>[];
    await tester.pumpWidget(
      buildHost(onPageChanged: (o, n) => changed.add('$o->$n')),
    );
    await tester.pump(); // 等待宽度测量

    // 当前 A，点击下一页标题 B → 切到第 1 页
    await tester.tap(find.text('B'));
    await tester.pump(); // 触发换页
    // 换页是「隐藏 → 换内容 → 显示」两段，等到全部结束
    await tester.pumpAndSettle();

    expect(changed, ['0->1']);
    expect(find.text('B'), findsOneWidget);

    // 现在当前 B（start 对齐下 prev 标题 A 在屏幕外），点击下一页标题 C
    // → 切到第 2 页
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(changed, ['0->1', '1->2']);
  });

  testWidgets('PivotStack：点击悬浮标题切换到对应页', (tester) async {
    final changed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PivotStack(
            items: const [
              PivotItem(
                title: Text('A'),
                page: ColoredBox(color: Colors.red, child: SizedBox.expand()),
              ),
              PivotItem(
                title: Text('B'),
                page: ColoredBox(color: Colors.green, child: SizedBox.expand()),
              ),
              PivotItem(
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
      ),
    );
    await tester.pump(); // 等待宽度测量

    // 当前 A（start 对齐下 prev 标题 C 在屏幕外），点击下一页标题 B
    // → 切到第 1 页
    await tester.tap(find.text('B'));
    await tester.pump(); // 触发换页
    await tester.pump(const Duration(milliseconds: 300)); // 动画结束

    expect(changed, ['0->1']);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('换页动画期间：单条标题整体向右推入，到达后换成新条', (tester) async {
    // 系统是一个横向 ScrollViewer：标题条整体平移，没有任何淡入淡出。
    await tester.pumpWidget(buildHost());
    await tester.pump();

    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(60, 0));
    await tester.pump();
    await g.up();

    // 换页动画刚开始：仍只有一条标题条，且键仍是旧页码
    await tester.pump();
    expect(find.byKey(const ValueKey('bar-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-0-old')), findsNothing);

    // 推进 20ms：右滑 → 上一页，整体继续向右推入（offset 增大）
    await tester.pump(const Duration(milliseconds: 20));
    expect(barOffset(tester, 'bar-0'), greaterThan(0));

    // 动画结束后换成新页码的标题条，位移归零
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('bar-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-0')), findsNothing);
    expect(barOffset(tester, 'bar-2'), closeTo(0, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('换页过程中标题条连续：没有任何标题在提交瞬间瞬移', (tester) async {
    // 回归：旧实现只画 [prev, cur, next]，提交换页时"再下一个"标题会从
    // 屏幕左侧凭空跳到右侧，肉眼看到标题跳一下。现在槽位坐标用全局累计
    // 宽度，换页期间还多画一个前进方向的槽位，因此每个标题的 x 必须连续。
    await tester.pumpWidget(buildHost());
    await tester.pump(); // 等待宽度测量

    /// 取 [text] 所有实例的左边（可能有重复的同名标题，排序后逐个比较）。
    List<double> lefts(String text) {
      final xs =
          find
              .text(text)
              .evaluate()
              .map(
                (e) => (e.renderObject! as RenderBox)
                    .localToGlobal(Offset.zero)
                    .dx,
              )
              .toList()
            ..sort();
      return xs;
    }

    final g = await tester.startGesture(const Offset(400, 300));
    await g.moveBy(const Offset(-40, 0));
    await tester.pump();
    await g.up();
    await tester.pump();

    // 采样换页全过程：相邻两帧之间，同名标题的每一个可见实例都不应跳变。
    final before = {
      for (final t in ['A', 'B', 'C']) t: lefts(t),
    };
    var prev = before;
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final now = {
        for (final t in ['A', 'B', 'C']) t: lefts(t),
      };
      for (final t in ['A', 'B', 'C']) {
        final a = prev[t]!;
        final b = now[t]!;
        // 同名实例数量变化说明有实例凭空出现/消失（只允许出现在屏幕外）。
        if (a.length == b.length && a.isNotEmpty) {
          for (var k = 0; k < a.length; k++) {
            expect(
              (b[k] - a[k]).abs(),
              lessThan(120),
              reason: '$t 第 $k 个实例在 50ms 内跳变 ${(b[k] - a[k])}',
            );
          }
        }
      }
      prev = now;
    }
    await tester.pumpAndSettle();
  });
}
