import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/page_scaffold.dart';

/// 验证 MetroPageScaffold 推远动画（pushBackBackground）期间，
/// 页面半透明时透出的底色跟随主题背景（白主题白、黑主题黑），
/// 而不是桌面（黑）/ Web（白）等平台原生底色。
///
/// 该特性由 [MetroPageScaffold.enableZAxisEffect] 控制，默认不启用。
void main() {
  const Color white = Color(0xFFFFFFFF);
  const Color black = Color(0xFF000000);

  Future<void> pumpHost(
    WidgetTester tester, {
    required MetroThemeMode themeMode,
    required GlobalKey<MetroPageScaffoldState> scaffoldKey,
    bool enableZAxisEffect = true,
  }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MetroApp(
        themeMode: themeMode,
        home: MetroPageScaffold(
          key: scaffoldKey,
          enableZAxisEffect: enableZAxisEffect,
          body: const ColoredBox(color: Color(0xFF123456)),
        ),
      ),
    );
    // postFrameCallback：注册 AppBar + 播放进入动画
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// 获取 MetroPageScaffold 内部 Z 轴动画 Stack 中的背景垫层。
  Color? backgroundLayerColor(WidgetTester tester) {
    final Iterable<ColoredBox> boxes = tester.widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(MetroPageScaffold),
        matching: find.byType(ColoredBox),
      ),
    );
    for (final box in boxes) {
      if (box.color == white || box.color == black) {
        return box.color;
      }
    }
    return null;
  }

  testWidgets('白色主题：推远时透出的背景层为白色', (tester) async {
    final key = GlobalKey<MetroPageScaffoldState>();
    await pumpHost(tester, themeMode: MetroThemeMode.light, scaffoldKey: key);

    // 未推远时背景垫层即存在且为白色
    expect(backgroundLayerColor(tester), white);

    key.currentState!.pushBackBackground();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // 500ms 动画

    expect(backgroundLayerColor(tester), white,
        reason: '白色主题下推远动画透出的底色应为白色');
  });

  testWidgets('黑色主题：推远时透出的背景层为黑色', (tester) async {
    final key = GlobalKey<MetroPageScaffoldState>();
    await pumpHost(tester, themeMode: MetroThemeMode.dark, scaffoldKey: key);

    expect(backgroundLayerColor(tester), black);

    key.currentState!.pushBackBackground();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // 500ms 动画

    expect(backgroundLayerColor(tester), black,
        reason: '黑色主题下推远动画透出的底色应为黑色');
  });

  testWidgets('默认 false：不启用 Z 轴推远，无背景垫层且动画不生效', (tester) async {
    final key = GlobalKey<MetroPageScaffoldState>();
    await pumpHost(
      tester,
      themeMode: MetroThemeMode.dark,
      scaffoldKey: key,
      enableZAxisEffect: false,
    );

    // 未启用时不应存在背景垫层（纯白/纯黑 ColoredBox 是 Z 轴推远特性独有，
    // 页面自身的进入动画（MetroAnimatedPage 的 Transform）不会产生它）
    expect(backgroundLayerColor(tester), isNull,
        reason: 'enableZAxisEffect=false 时不应存在背景垫层');

    // 调用推远动画后依然没有任何变化（不产生视觉效果）
    key.currentState!.pushBackBackground();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(backgroundLayerColor(tester), isNull,
        reason: 'enableZAxisEffect=false 时调用 pushBackBackground 不应产生背景垫层');
  });
}
