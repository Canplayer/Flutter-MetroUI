import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderAbstractViewport, RenderObject;
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/page_scaffold.dart';
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
    final viewTopLeft = tester.getTopLeft(find.byType(MetroApplicationBarView));
    final size = tester.getSize(find.byType(MetroApplicationBarView));
    await tester.tapAt(viewTopLeft + Offset(size.width - 30, size.height - 30));
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
      menuItems: [MetroAppBarMenuItem(label: '设置', onPressed: () {})],
    );

    await tester.pumpWidget(buildHost(bar: bar));
    // 等按钮初始进场动画播完（incomingDelay 100ms + incomingDuration 400ms）
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 折叠态：label 不可见，记录圆环相对应用栏顶部的偏移作为基准
    expect(find.text('新建'), findsNothing);
    expect(find.text('分享'), findsNothing);
    final collapsedViewTop = tester
        .getTopLeft(find.byType(MetroApplicationBarView))
        .dy;
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
    final expandedViewTop = tester
        .getTopLeft(find.byType(MetroApplicationBarView))
        .dy;
    final expandedOffset0 =
        tester.getTopLeft(find.byType(MetroCircleButton).at(0)).dy -
        expandedViewTop;
    final expandedOffset1 =
        tester.getTopLeft(find.byType(MetroCircleButton).at(1)).dy -
        expandedViewTop;

    expect(
      expandedOffset0,
      closeTo(collapsedOffset0, 0.001),
      reason: '展开菜单后第一个圆环相对应用栏不应上移',
    );
    expect(
      expandedOffset1,
      closeTo(collapsedOffset1, 0.001),
      reason: '展开菜单后第二个圆环相对应用栏不应上移',
    );

    // 圆环之间的视觉间距保持最初布局的值（直径 38.5 + 原 spacing 29 = 67.5）
    final circleGap =
        tester.getCenter(find.byType(MetroCircleButton).at(1)).dx -
        tester.getCenter(find.byType(MetroCircleButton).at(0)).dx;
    expect(
      circleGap,
      closeTo(48.125 * 0.8 + 36.25 * 0.8, 0.5),
      reason: '圆环中心距应保持最初的视觉间距（当前 $circleGap）',
    );

    // 文字出现在圆环下方
    final circle0Bottom =
        tester.getTopLeft(find.byType(MetroCircleButton).at(0)).dy +
        tester.getSize(find.byType(MetroCircleButton).at(0)).height;
    final labelTop = tester.getTopLeft(find.text('新建')).dy;
    expect(labelTop >= circle0Bottom, isTrue, reason: '文字应位于圆环下方');
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
      menuItems: [MetroAppBarMenuItem(label: '设置', onPressed: () {})],
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
      menuItems: [MetroAppBarMenuItem(label: '设置', onPressed: () {})],
    );

    await tester.pumpWidget(buildHost(bar: bar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await expandMenu(tester);

    expect(find.text('新建项目'), findsOneWidget);
    // 单行高度（10.4px 字号约 10~14px）；若换行成两行会明显更高
    final textHeight = tester.getSize(find.text('新建项目')).height;
    expect(textHeight, lessThan(20), reason: '稍长标签不应换行（当前高度 $textHeight）');
    // Text 明确强制单行
    expect(tester.widget<Text>(find.text('新建项目')).maxLines, 1);
    // 按钮（Tile 层）宽度 = 圆环直径 + 原按钮间距（36.25*0.8），
    // 圆环在按钮内水平居中
    const double circleSize = 48.125 * 0.8;
    const double buttonWidth = circleSize + 36.25 * 0.8;
    final buttonSize = tester.getSize(find.byType(Tile).first);
    expect(
      buttonSize.width,
      closeTo(buttonWidth, 0.001),
      reason: '按钮宽度应为圆环直径 + 原按钮间距',
    );
    final circleCenter = tester
        .getCenter(find.byType(MetroCircleButton).first)
        .dx;
    final buttonLeft = tester.getTopLeft(find.byType(Tile).first).dx;
    final circleOffsetInButton = circleCenter - buttonLeft;
    expect(
      circleOffsetInButton,
      closeTo(buttonWidth / 2, 0.5),
      reason: '圆环应在加宽后的按钮内水平居中',
    );
  });
  testWidgets('菜单项拥有独立于栏的入场轨道', (tester) async {
    final bar = MetroApplicationBar(
      menuOrientation: MetroAppBarOrientation.portrait,
      buttons: [
        MetroAppBarButton(
          icon: const Icon(Icons.add),
          label: 'button',
          onPressed: () {},
        ),
      ],
      menuItems: [MetroAppBarMenuItem(label: 'menu item', onPressed: () {})],
    );
    await tester.pumpWidget(buildHost(bar: bar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final topLeft = tester.getTopLeft(find.byType(MetroApplicationBarView));
    final size = tester.getSize(find.byType(MetroApplicationBarView));
    await tester.tapAt(topLeft + Offset(size.width - 30, size.height - 30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final start =
        tester.getTopLeft(find.text('menu item')).dy -
        tester.getTopLeft(find.byType(MetroApplicationBarView)).dy;
    await tester.pump(const Duration(milliseconds: 100));
    final middle =
        tester.getTopLeft(find.text('menu item')).dy -
        tester.getTopLeft(find.byType(MetroApplicationBarView)).dy;
    await tester.pumpAndSettle();
    final end =
        tester.getTopLeft(find.text('menu item')).dy -
        tester.getTopLeft(find.byType(MetroApplicationBarView)).dy;
    expect(start, greaterThan(middle));
    expect(middle, greaterThan(end));
  });

  testWidgets('禁用菜单项不会关闭菜单', (tester) async {
    final bar = MetroApplicationBar(
      buttons: [
        MetroAppBarButton(
          icon: const Icon(Icons.add),
          label: 'button',
          onPressed: () {},
        ),
      ],
      menuItems: const [MetroAppBarMenuItem(label: 'disabled')],
    );
    await tester.pumpWidget(buildHost(bar: bar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await expandMenu(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('disabled'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('button'), findsOneWidget);
  });

  testWidgets('应用栏按钮颜色覆盖传递到圆形按钮', (tester) async {
    final bar = MetroApplicationBar(
      buttonColor: Colors.red,
      buttonIconColor: Colors.green,
      buttons: [
        MetroAppBarButton(
          icon: const Icon(Icons.add),
          label: 'button',
          onPressed: () {},
        ),
      ],
    );
    await tester.pumpWidget(buildHost(bar: bar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final circle = tester.widget<MetroCircleButton>(
      find.byType(MetroCircleButton),
    );
    expect(circle.borderColor, Colors.red);
    expect(circle.iconColor, Colors.green);
  });

  testWidgets('切换页面拥有者关闭菜单，同一页面更新保持状态', (tester) async {
    final controller = MetroAppBarController();
    final ownerA = Object();
    final ownerB = Object();
    MetroApplicationBar bar(String label) => MetroApplicationBar(
      buttons: [
        MetroAppBarButton(
          icon: const Icon(Icons.add),
          label: label,
          onPressed: () {},
        ),
      ],
      menuItems: [MetroAppBarMenuItem(label: 'menu', onPressed: () {})],
    );
    controller.setAppBar(bar('A'), owner: ownerA);
    await tester.pumpWidget(
      MaterialApp(
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
            child: MetroApplicationBarOverlay(controller: controller),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final top = tester.getTopLeft(find.byType(MetroApplicationBarView));
    final size = tester.getSize(find.byType(MetroApplicationBarView));
    await tester.tapAt(top + Offset(size.width - 30, size.height - 30));
    await tester.pumpAndSettle();
    expect(controller.isExpanded, isTrue);
    controller.setAppBar(bar('A2'), owner: ownerA);
    await tester.pumpAndSettle();
    expect(controller.isExpanded, isTrue);
    controller.setAppBar(bar('B'), owner: ownerB);
    await tester.pumpAndSettle();
    expect(controller.isExpanded, isFalse);
    expect(find.text('B'), findsNothing);
  });
  testWidgets('点击页面背景只收起应用栏', (tester) async {
    var bodyTaps = 0;
    await tester.pumpWidget(
      MetroApp(
        home: MetroPageScaffold(
          disableDefaultPushAnimation: true,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => bodyTaps++,
            child: const SizedBox.expand(),
          ),
          applicationBar: MetroApplicationBar(
            buttons: [
              MetroAppBarButton(
                icon: const Icon(Icons.add),
                label: 'button',
                onPressed: () {},
              ),
            ],
            menuItems: [MetroAppBarMenuItem(label: 'item', onPressed: () {})],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final top = tester.getTopLeft(find.byType(MetroApplicationBarView));
    final size = tester.getSize(find.byType(MetroApplicationBarView));
    await tester.tapAt(top + Offset(size.width - 30, size.height - 30));
    await tester.pumpAndSettle();
    expect(find.text('button'), findsOneWidget);
    await tester.tapAt(const Offset(50, 100));
    await tester.pumpAndSettle();
    expect(bodyTaps, 0);
    expect(find.text('button'), findsNothing);
  });

  testWidgets('短屏幕上的长菜单可以滚动', (tester) async {
    tester.view.physicalSize = const Size(384, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bar = MetroApplicationBar(
      buttons: [
        MetroAppBarButton(
          icon: const Icon(Icons.add),
          label: 'button',
          onPressed: () {},
        ),
      ],
      menuItems: List.generate(
        12,
        (i) => MetroAppBarMenuItem(label: 'item$i', onPressed: () {}),
      ),
    );
    await tester.pumpWidget(buildHost(bar: bar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final top = tester.getTopLeft(find.byType(MetroApplicationBarView));
    final size = tester.getSize(find.byType(MetroApplicationBarView));
    await tester.tapAt(top + Offset(size.width - 30, size.height - 20));
    await tester.pumpAndSettle();
    final scroll = find.byType(SingleChildScrollView);
    expect(scroll, findsOneWidget);
    await tester.drag(scroll, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position
          .pixels,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('返回键先关闭菜单', (tester) async {
    await tester.pumpWidget(
      MetroApp(
        home: MetroPageScaffold(
          disableDefaultPushAnimation: true,
          body: const SizedBox.expand(),
          applicationBar: MetroApplicationBar(
            buttons: [
              MetroAppBarButton(
                icon: const Icon(Icons.add),
                label: 'button',
                onPressed: () {},
              ),
            ],
            menuItems: [MetroAppBarMenuItem(label: 'item', onPressed: () {})],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final top = tester.getTopLeft(find.byType(MetroApplicationBarView));
    final size = tester.getSize(find.byType(MetroApplicationBarView));
    await tester.tapAt(top + Offset(size.width - 30, size.height - 30));
    await tester.pumpAndSettle();
    expect(find.text('button'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('button'), findsNothing);
    expect(find.byType(MetroPageScaffold), findsOneWidget);
  });
  for (final orientation in [
    MetroAppBarOrientation.landscape90,
    MetroAppBarOrientation.landscape270,
  ]) {
    testWidgets('菜单横屏动画方向 $orientation', (tester) async {
      final bar = MetroApplicationBar(
        menuOrientation: orientation,
        buttons: [
          MetroAppBarButton(
            icon: const Icon(Icons.add),
            label: 'button',
            onPressed: () {},
          ),
        ],
        menuItems: [
          MetroAppBarMenuItem(label: 'landscape item', onPressed: () {}),
        ],
      );
      await tester.pumpWidget(buildHost(bar: bar));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final top = tester.getTopLeft(find.byType(MetroApplicationBarView));
      final size = tester.getSize(find.byType(MetroApplicationBarView));
      await tester.tapAt(top + Offset(size.width - 30, size.height - 30));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      final start = tester.getTopLeft(find.text('landscape item')).dx;
      await tester.pumpAndSettle();
      final end = tester.getTopLeft(find.text('landscape item')).dx;
      if (orientation == MetroAppBarOrientation.landscape90) {
        expect(start, greaterThan(end));
      } else {
        expect(start, lessThan(end));
      }
    });
  }

  testWidgets('Pivot 按钮切换使用水平轨道', (tester) async {
    MetroApplicationBar bar(IconData icon) => MetroApplicationBar(
      buttonTransition: MetroAppBarButtonTransition.pivotForward,
      buttons: [
        MetroAppBarButton(icon: Icon(icon), label: 'button', onPressed: () {}),
      ],
    );
    await tester.pumpWidget(buildHost(bar: bar(Icons.add)));
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildHost(bar: bar(Icons.star)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final start = tester.getTopLeft(find.byIcon(Icons.star)).dx;
    await tester.pumpAndSettle();
    final end = tester.getTopLeft(find.byIcon(Icons.star)).dx;
    expect(start, greaterThan(end));
  });

  testWidgets('从折叠态短距离向上拖可展开菜单', (tester) async {
    final bar = MetroApplicationBar(
      buttons: [
        MetroAppBarButton(
          icon: const Icon(Icons.add),
          label: 'button',
          onPressed: () {},
        ),
      ],
      menuItems: [MetroAppBarMenuItem(label: 'item', onPressed: () {})],
    );
    await tester.pumpWidget(buildHost(bar: bar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final top = tester.getTopLeft(find.byType(MetroApplicationBarView));
    final size = tester.getSize(find.byType(MetroApplicationBarView));
    await tester.dragFrom(
      top + Offset(size.width - 30, size.height - 30),
      const Offset(0, -35),
    );
    await tester.pumpAndSettle();
    expect(find.text('button'), findsOneWidget);
  });

  testWidgets('文本菜单按索引依次飞入', (tester) async {
    final bar = MetroApplicationBar(
      menuOrientation: MetroAppBarOrientation.portrait,
      buttons: [
        MetroAppBarButton(
          icon: const Icon(Icons.add),
          label: 'button',
          onPressed: () {},
        ),
      ],
      menuItems: [
        for (int i = 0; i < 3; i++)
          MetroAppBarMenuItem(label: 'stagger$i', onPressed: () {}),
      ],
    );
    await tester.pumpWidget(buildHost(bar: bar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final top = tester.getTopLeft(find.byType(MetroApplicationBarView));
    final size = tester.getSize(find.byType(MetroApplicationBarView));
    await tester.tapAt(top + Offset(size.width - 30, size.height - 30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final gapDuring =
        tester.getTopLeft(find.text('stagger1')).dy -
        tester.getTopLeft(find.text('stagger0')).dy;
    final gapNext =
        tester.getTopLeft(find.text('stagger2')).dy -
        tester.getTopLeft(find.text('stagger1')).dy;
    await tester.pumpAndSettle();
    final gapEnd =
        tester.getTopLeft(find.text('stagger1')).dy -
        tester.getTopLeft(find.text('stagger0')).dy;
    expect(gapDuring, greaterThan(gapEnd + 1));
    expect(gapNext, closeTo(gapEnd, .1));
  });
  testWidgets('自定义主内容替代按钮行并保留菜单入口', (tester) async {
    tester.view.physicalSize = const Size(384, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final textController = TextEditingController();
    addTearDown(textController.dispose);
    var clicked = 0;
    final bar = MetroApplicationBar(
      buttons: [
        MetroAppBarButton(
          icon: const Icon(Icons.add),
          label: 'old',
          onPressed: () {},
        ),
      ],
      customContent: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('address'),
              controller: textController,
            ),
          ),
          IconButton(
            key: const ValueKey('custom-action'),
            onPressed: () => clicked++,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      menuItems: [MetroAppBarMenuItem(label: 'settings', onPressed: () {})],
    );
    await tester.pumpWidget(buildHost(bar: bar));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      metroAppBarCollapsedHeight(bar),
      closeTo(kMetroAppBarNormalHeight, .01),
    );
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byKey(const ValueKey('address')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('address')),
      'https://example.com',
    );
    await tester.tap(find.byKey(const ValueKey('custom-action')));
    await tester.pump();
    expect(clicked, 1);
    final textRight = tester
        .getBottomRight(find.byKey(const ValueKey('custom-action')))
        .dx;
    final barRight = tester
        .getBottomRight(find.byType(MetroApplicationBarView))
        .dx;
    expect(barRight - textRight, closeTo(kMetroAppBarMoreButtonSize, 1));
    await expandMenu(tester);
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsOneWidget);
    expect(textController.text, 'https://example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('仅自定义内容时使用普通栏高度并保留状态', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    Widget host() => buildHost(
      bar: MetroApplicationBar(
        customContent: TextField(key: const ValueKey('address'), controller: c),
        menuItems: [MetroAppBarMenuItem(label: 'item', onPressed: () {})],
      ),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(MetroApplicationBarView)).height,
      closeTo(kMetroAppBarNormalHeight, .01),
    );
    await tester.enterText(find.byKey(const ValueKey('address')), 'example');
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(c.text, 'example');
    expect(tester.takeException(), isNull);
  });

  testWidgets('MetroApp 自定义栏支持地址输入框', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      MetroApp(
        home: MetroPageScaffold(
          disableDefaultPushAnimation: true,
          body: const SizedBox.expand(),
          applicationBar: MetroApplicationBar(
            customContent: TextField(
              key: const ValueKey('address'),
              controller: c,
            ),
            menuItems: [MetroAppBarMenuItem(label: 'item', onPressed: () {})],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const ValueKey('address')),
      'https://example.com',
    );
    expect(c.text, 'https://example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('自定义输入切回普通按钮时正确释放 Overlay', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      buildHost(
        bar: MetroApplicationBar(
          customContent: TextField(
            key: const ValueKey('address'),
            controller: c,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('address')), 'hello');
    await tester.pumpWidget(
      buildHost(
        bar: MetroApplicationBar(
          buttons: [
            MetroAppBarButton(
              icon: const Icon(Icons.add),
              label: 'new',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('自定义内容可通过控制器打开和关闭菜单', (tester) async {
    await tester.pumpWidget(
      MetroApp(
        home: MetroPageScaffold(
          disableDefaultPushAnimation: true,
          body: const SizedBox.expand(),
          applicationBar: MetroApplicationBar(
            customContent: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    MetroAppBarScope.controllerOf(context)?.openMenu(),
                child: const Text('open custom'),
              ),
            ),
            menuItems: [
              MetroAppBarMenuItem(label: 'custom menu item', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open custom'));
    await tester.pumpAndSettle();
    expect(find.text('custom menu item'), findsOneWidget);
    final scope = tester.element(find.text('open custom'));
    final controller = MetroAppBarScope.controllerOf(scope)!;
    expect(controller.isExpanded, isTrue);
    controller.closeMenu();
    await tester.pumpAndSettle();
    expect(controller.isExpanded, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('飞入的长菜单不被滚动视口裁切，稳定后恢复裁切', (tester) async {
    tester.view.physicalSize = const Size(384, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bar = MetroApplicationBar(
      menuOrientation: MetroAppBarOrientation.portrait,
      buttons: [
        MetroAppBarButton(
          icon: const Icon(Icons.add),
          label: 'button',
          onPressed: () {},
        ),
      ],
      menuItems: List.generate(
        15,
        (i) => MetroAppBarMenuItem(label: 'clip-item-$i', onPressed: () {}),
      ),
    );
    await tester.pumpWidget(buildHost(bar: bar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final view = find.byType(MetroApplicationBarView);
    final top = tester.getTopLeft(view);
    final size = tester.getSize(view);
    await tester.tapAt(top + Offset(size.width - 30, size.height - 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    Rect? viewportClip() {
      RenderObject child = tester.renderObject(find.text('clip-item-0'));
      while (child.parent is RenderObject) {
        final parent = child.parent! as RenderObject;
        if (parent is RenderAbstractViewport)
          return parent.describeApproximatePaintClip(child);
        child = parent;
      }
      fail('未找到菜单滚动视口');
    }

    expect(viewportClip(), isNull, reason: '飞入阶段应允许菜单项画到视口之外');
    await tester.pumpAndSettle();
    expect(viewportClip(), isNotNull, reason: '长菜单稳定后应重新裁切滚动视口');
    final scroll = find.byType(SingleChildScrollView);
    await tester.drag(scroll, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(viewportClip(), isNotNull);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
