import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/swipe_page_view.dart';

void main() {
  Widget buildHost({
    OnPageChanged? onPageChanged,
    OnTransitionEnd? onTransitionEnd,
    OnSlideProgress? onSlideProgress,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SwipePageView(
          // 显式指定参数，与默认值解耦，保证测试稳定
          swipeThreshold: 50,
          maxDragDistance: 150,
          flyDuration: const Duration(milliseconds: 100),
          fadeDuration: const Duration(milliseconds: 50),
          snapBackDuration: const Duration(milliseconds: 120),
          onPageChanged: onPageChanged,
          onTransitionEnd: onTransitionEnd,
          onSlideProgress: onSlideProgress,
          itemBuilder: (context, index) => ColoredBox(
            color: index.isEven ? Colors.red : Colors.blue,
            child: Center(child: Text('page $index')),
          ),
        ),
      ),
    );
  }

  testWidgets('位移小于阈值：松手归位，不换页', (tester) async {
    final changed = <String>[];
    final transitionEnded = <String>[];
    final progresses = <double>[];
    await tester.pumpWidget(
      buildHost(
        onPageChanged: (o, n) => changed.add('$o->$n'),
        onTransitionEnd: (o, n) => transitionEnded.add('$o->$n'),
        onSlideProgress: (p) => progresses.add(p),
      ),
    );

    expect(find.text('page 0'), findsOneWidget);

    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(30, 0)); // 30px < 50
    await tester.pump();
    await g.up();

    // 等待归位动画结束（第一次 pump 启动 ticker，第二次推进完成）
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 仍然停留在第 0 页
    expect(find.text('page 0'), findsOneWidget);
    expect(find.text('page -1'), findsNothing);
    expect(changed, isEmpty); // 未触发翻页
    expect(transitionEnded, isEmpty); // 未触发动画结束
    // 拖动过程进度 30/150=0.2，归位结束后归零
    expect(progresses, contains(0.2));
    expect(progresses.last, 0.0);
  });

  testWidgets('位移达到阈值：松手立即触发 onPageChanged，动画结束后触发 onTransitionEnd', (tester) async {
    final changed = <String>[];
    final transitionEnded = <String>[];
    await tester.pumpWidget(
      buildHost(
        onPageChanged: (o, n) => changed.add('$o->$n'),
        onTransitionEnd: (o, n) => transitionEnded.add('$o->$n'),
      ),
    );

    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(60, 0)); // 60px >= 50
    await tester.pump();
    await g.up();

    // 松手后手势竞技场解析 → 立即回调 onPageChanged，动画刚开始
    await tester.pump();
    expect(changed, ['0->-1']); // 换页事件：松手即触发
    expect(transitionEnded, isEmpty); // 动画尚未结束
    expect(find.text('page 0'), findsOneWidget); // A 仍在飞出中

    // 等待换页动画结束（100ms）
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('page -1'), findsOneWidget);
    expect(find.text('page 0'), findsNothing);
    expect(transitionEnded, ['0->-1']); // 动画结束事件
  });

  testWidgets('拖动距离被钳制在 150px（归一化 progress 不超 1）', (tester) async {
    final progresses = <double>[];
    await tester.pumpWidget(
      buildHost(
        onSlideProgress: (p) => progresses.add(p),
      ),
    );

    final g = await tester.startGesture(const Offset(200, 300));
    // 一次拖出远超 150 的距离
    await g.moveBy(const Offset(300, 0));
    await tester.pump();

    expect(progresses.last, 1.0); // 150/150 = 1

    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // 位移足够，仍然换页
    expect(find.text('page -1'), findsOneWidget);
  });

  testWidgets('双指接力：只要还有手指按住就不触发换页，全部松开才触发', (tester) async {
    final changed = <String>[];
    final transitionEnded = <String>[];
    final progresses = <double>[];
    await tester.pumpWidget(
      buildHost(
        onPageChanged: (o, n) => changed.add('$o->$n'),
        onTransitionEnd: (o, n) => transitionEnded.add('$o->$n'),
        onSlideProgress: (p) => progresses.add(p),
      ),
    );

    final g1 = await tester.startGesture(const Offset(200, 300));
    await g1.moveBy(const Offset(40, 0));
    await tester.pump();

    // 第二根手指按下
    final g2 = await tester.createGesture();
    await g2.down(const Offset(250, 300));
    await tester.pump();

    // 主手指抬起，第二根手指仍在屏幕 → 此时不应触发换页
    await g1.up();
    await tester.pump();
    expect(changed, isEmpty);
    expect(transitionEnded, isEmpty);

    // 继续拖（超过 150 会被钳制），仍未松手 → 不换页
    await g2.moveBy(const Offset(300, 0));
    await tester.pump();
    expect(progresses.last, 1.0);
    expect(changed, isEmpty);

    // 第二根手指也抬起 → 全部松开，松手瞬间触发换页
    await g2.up();
    await tester.pump();
    expect(changed, ['0->-1']); // 换页事件：全部松手即触发

    // 等待动画结束
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('page -1'), findsOneWidget);
    expect(transitionEnded, ['0->-1']);
  });

  testWidgets('向左滑换到下一页：松手即触发换页事件', (tester) async {
    final changed = <String>[];
    await tester.pumpWidget(
      buildHost(
        onPageChanged: (o, n) => changed.add('$o->$n'),
      ),
    );

    final g = await tester.startGesture(const Offset(200, 300));
    await g.moveBy(const Offset(-60, 0));
    await tester.pump();
    await g.up();

    await tester.pump();
    expect(changed, ['0->1']); // 松手即触发

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('page 1'), findsOneWidget);
    expect(find.text('page 0'), findsNothing);
  });
}
