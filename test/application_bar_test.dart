import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/metro_theme_extensions.dart';
import 'package:metro_ui/widgets/metro_circle_button.dart';
import 'package:metro_ui/widgets/tile.dart';

void main() {
  Widget buildHost({required MetroApplicationBar bar}) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [
          MetroAppBarTheme(
            backgroundColor: Colors.black,
            buttonColor: Colors.white,
            buttonIconColor: Colors.white,
            menuItemColor: Colors.white,
          ),
        ],
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: MetroApplicationBarView(bar: bar),
        ),
      ),
    );
  }

  /// 点击应用栏右侧空白（••• 区域，避开居中按钮）展开菜单。
  Future<void> expandMenu(WidgetTester tester) async {
    final viewTopLeft =
        tester.getTopLeft(find.byType(MetroApplicationBarView));
    final size = tester.getSize(find.byType(MetroApplicationBarView));
    await tester.tapAt(
        viewTopLeft + Offset(size.width - 30, size.height - 30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('展开菜单后环形图标位置不变（仅文字出现）', (tester) async {
    final bar = MetroApplicationBar(
      buttons: [
        MetroAppBarButton(
          icon: const Icon(Icons.add),
          label: '新建',
          onPressed: () {},
        ),
        MetroAppBarButton(
          icon: const Icon(Icons.share),
          label: '分享',
          onPressed: () {},
        ),
      ],
      menuItems: [
        MetroAppBarMenuItem(label: '设置', onPressed: () {}),
      ],
    );

    await tester.pumpWidget(buildHost(bar: bar));
    // 等按钮初始进场动画播完（incomingDelay 100ms + incomingDuration 400ms）
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 折叠态：label 不可见，记录圆环相对应用栏顶部的偏移作为基准
    expect(find.text('新建'), findsNothing);
    expect(find.text('分享'), findsNothing);
    final collapsedViewTop =
        tester.getTopLeft(find.byType(MetroApplicationBarView)).dy;
    final collapsedOffset0 =
        tester.getTopLeft(find.byType(MetroCircleButton).at(0)).dy -
            collapsedViewTop;
    final collapsedOffset1 =
        tester.getTopLeft(find.byType(MetroCircleButton).at(1)).dy -
            collapsedViewTop;

    // 点击应用栏右侧空白（进入拖拽模式）展开菜单
    await expandMenu(tester);

    // 展开态：label 出现
    expect(find.text('新建'), findsOneWidget);
    expect(find.text('分享'), findsOneWidget);

    // 应用栏整体展开变高（底部贴屏、顶部上移），
    // 但圆环相对应用栏顶部的偏移必须与折叠态完全一致（栏内位置不变）
    final expandedViewTop =
        tester.getTopLeft(find.byType(MetroApplicationBarView)).dy;
    final expandedOffset0 =
        tester.getTopLeft(find.byType(MetroCircleButton).at(0)).dy -
            expandedViewTop;
    final expandedOffset1 =
        tester.getTopLeft(find.byType(MetroCircleButton).at(1)).dy -
            expandedViewTop;

    expect(expandedOffset0, closeTo(collapsedOffset0, 0.001),
        reason: '展开菜单后第一个圆环相对应用栏不应上移');
    expect(expandedOffset1, closeTo(collapsedOffset1, 0.001),
        reason: '展开菜单后第二个圆环相对应用栏不应上移');

    // 圆环之间的视觉间距保持最初布局的值（直径 38.5 + 原 spacing 29 = 67.5）
    final circleGap = tester
            .getCenter(find.byType(MetroCircleButton).at(1))
            .dx -
        tester.getCenter(find.byType(MetroCircleButton).at(0)).dx;
    expect(circleGap, closeTo(48.125 * 0.8 + 36.25 * 0.8, 0.5),
        reason: '圆环中心距应保持最初的视觉间距（当前 $circleGap）');

    // 文字出现在圆环下方
    final circle0Bottom =
        tester.getTopLeft(find.byType(MetroCircleButton).at(0)).dy +
            tester.getSize(find.byType(MetroCircleButton).at(0)).height;
    final labelTop = tester.getTopLeft(find.text('新建')).dy;
    expect(labelTop >= circle0Bottom, isTrue,
        reason: '文字应位于圆环下方');
  });

  testWidgets('点击按钮文字触发 onPressed（文字可点）', (tester) async {
    var pressed = 0;
    final bar = MetroApplicationBar(
      buttons: [
        MetroAppBarButton(
          icon: const Icon(Icons.add),
          label: '新建',
          onPressed: () => pressed++,
        ),
      ],
      menuItems: [
        MetroAppBarMenuItem(label: '设置', onPressed: () {}),
      ],
    );

    await tester.pumpWidget(buildHost(bar: bar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 展开菜单，使按钮文字可见
    await expandMenu(tester);

    expect(find.text('新建'), findsOneWidget);
    // 点击文字本身，应触发按钮的 onPressed
    await tester.tap(find.text('新建'));
    await tester.pump();
    expect(pressed, 1, reason: '点击按钮文字应触发 onPressed');
    // 消费 Tile 回弹的延迟定时器，避免测试结束时有 pending timer
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('稍长标签展开后不换行（单行显示）', (tester) async {
    // 4 个汉字：宽度（约 42px）超过圆环直径（38.5px），
    // 但不超过加宽后的文字可用宽度（38.5 + 8*2 = 54.5px）
    final bar = MetroApplicationBar(
      buttons: [
        MetroAppBarButton(
          icon: const Icon(Icons.star),
          label: '新建项目',
          onPressed: () {},
        ),
      ],
      menuItems: [
        MetroAppBarMenuItem(label: '设置', onPressed: () {}),
      ],
    );

    await tester.pumpWidget(buildHost(bar: bar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await expandMenu(tester);

    expect(find.text('新建项目'), findsOneWidget);
    // 单行高度（10.4px 字号约 10~14px）；若换行成两行会明显更高
    final textHeight = tester.getSize(find.text('新建项目')).height;
    expect(textHeight, lessThan(20),
        reason: '稍长标签不应换行（当前高度 $textHeight）');
    // Text 明确强制单行
    expect(tester.widget<Text>(find.text('新建项目')).maxLines, 1);
    // 按钮（Tile 层）宽度 = 圆环直径 + 原按钮间距（36.25*0.8），
    // 圆环在按钮内水平居中
    const double circleSize = 48.125 * 0.8;
    const double buttonWidth = circleSize + 36.25 * 0.8;
    final buttonSize = tester.getSize(find.byType(Tile).first);
    expect(buttonSize.width, closeTo(buttonWidth, 0.001),
        reason: '按钮宽度应为圆环直径 + 原按钮间距');
    final circleCenter =
        tester.getCenter(find.byType(MetroCircleButton).first).dx;
    final buttonLeft = tester.getTopLeft(find.byType(Tile).first).dx;
    final circleOffsetInButton = circleCenter - buttonLeft;
    expect(circleOffsetInButton, closeTo(buttonWidth / 2, 0.5),
        reason: '圆环应在加宽后的按钮内水平居中');
  });
}
