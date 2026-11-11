import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/swipe_page_view.dart';

/// 换页过程的两段动画：`SlideFull*FadeOut`(300ms) → 换内容 → `SlideFull*FadeIn`(500ms)。
///
/// 证据：`DefaultPivotPaneHost` 换 pane 的顺序为
/// `PlayHideAnimation` → `RequestSource(null)` → `UpdatePaneContents` →
/// `LoadSelectedPane`（`PIVOT 0x1234–0x125e`）；动画参数见
/// `Animations.uix` 的 `SlideFullLeftFadeOut/In`（`0x1283–0x1347`）。
Widget _host(OnTransitionEnd? onTransitionEnd) => MaterialApp(
  home: Scaffold(
    body: SwipePageView(
      onTransitionEnd: onTransitionEnd,
      itemBuilder: (context, index) => SizedBox.expand(
        key: ValueKey('page-$index'),
        child: Center(child: Text('page $index')),
      ),
    ),
  ),
);

double _left(WidgetTester tester, int index) =>
    tester.getTopLeft(find.byKey(ValueKey('page-$index'))).dx;

void main() {
  const pane = 800.0;

  Future<void> release(WidgetTester tester) async {
    final g = await tester.startGesture(const Offset(400, 300));
    await g.moveBy(const Offset(-300, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // 关掉快滑判定
    await g.up();
  }

  testWidgets('隐藏 300ms：旧内容飞到屏幕外，仍未换内容', (tester) async {
    await tester.pumpWidget(_host(null));

    await release(tester);
    await tester.pump(); // 启动隐藏
    await tester.pump(const Duration(milliseconds: 150));

    // 隐藏进行到一半：仍是旧内容，继续向左飞出。
    expect(find.text('page 0'), findsOneWidget);
    expect(find.text('page 1'), findsNothing);
    expect(_left(tester, 0), lessThan(-300));
    expect(_left(tester, 0), greaterThan(-pane));

    await tester.pumpAndSettle();
  });

  testWidgets('隐藏结束后新内容从反方向一屏处出发，500ms 内归位', (tester) async {
    final ended = <String>[];
    await tester.pumpWidget(_host((o, n) => ended.add('$o->$n')));

    await release(tester);
    await tester.pump(); // 启动隐藏
    await tester.pump(const Duration(milliseconds: 310)); // 隐藏结束

    // 内容已换页，新内容从右侧一屏处开始。
    expect(find.text('page 1'), findsOneWidget);
    expect(find.text('page 0'), findsNothing);
    expect(_left(tester, 1), closeTo(pane, 1.0));

    // 显示 500ms：250ms 时已过半程（Log(150) 前段快）。
    await tester.pump(const Duration(milliseconds: 250));
    expect(_left(tester, 1), lessThan(pane));
    expect(_left(tester, 1), greaterThan(0));

    await tester.pump(const Duration(milliseconds: 300));
    expect(_left(tester, 1), closeTo(0, 1.0));
    expect(ended, ['0->1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('透明度按 FadeOut 250ms / FadeIn 350ms 叠加', (tester) async {
    await tester.pumpWidget(_host(null));

    Opacity fade() => tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(SwipePageView),
            matching: find.byType(Opacity),
          )
          .first,
    );

    await release(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    // 隐藏阶段：250ms 内从 1 淡到 0。
    expect(fade().opacity, closeTo(0, 0.05));

    // 进入显示阶段：从 0 开始。
    await tester.pump(const Duration(milliseconds: 60));
    expect(fade().opacity, lessThan(0.2));
    // 380ms > FadeIn 的 350ms → 已完全显现。
    await tester.pump(const Duration(milliseconds: 380));
    expect(fade().opacity, closeTo(1, 0.02));

    await tester.pumpAndSettle();
  });
}
