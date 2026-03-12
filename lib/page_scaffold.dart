// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/application_bar.dart';

import 'route_aware_provider.dart';

class _BodyBuilder extends StatelessWidget {
  const _BodyBuilder({
    required this.body,
    this.stackPanel,
    this.onWillPop,
    this.onDidPop,
    required this.animatedPageKey,
    required this.backButtonAlignment,
  });

  final Widget body;
  final Widget? stackPanel;
  final Future<bool> Function()? onWillPop;
  final Future<void> Function()? onDidPop;
  final GlobalKey<MetroAnimatedPageState> animatedPageKey;
  final AlignmentGeometry backButtonAlignment;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData metrics = MediaQuery.of(context);

    final double bottom = metrics.padding.bottom;
    final double top = metrics.padding.top;

    // 构建实际内容：如果有 stackPanel，则使用 Column 布局
    Widget content = body;
    if (stackPanel != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stackPanel!,
          Expanded(child: body),
        ],
      );
    }

    // 添加返回按钮逻辑
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    final bool canPop = route?.canPop ?? false;
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;

    if (canPop && !isAndroid) {
      content = Stack(
        fit: StackFit.loose,
        children: [
          content,
          Align(
            alignment: backButtonAlignment,
            child: Transform.translate(
              offset: const Offset(-20, 20),
              child: Opacity(
                opacity: 0.7,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.maybePop(context);
                  },
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/ic_back.svg',
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurface,
                          BlendMode.srcIn,
                        ),
                        package: 'metro_ui',
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return MediaQuery(
      data: metrics.copyWith(
        padding: metrics.padding.copyWith(
          top: top,
          bottom: bottom,
        ),
      ),

      //全局3D坐标观察点固定到屏幕中心
      //不要问我为什么是0.00078，我一点一点调出来的，我也不知道这个该怎么换算和为什么是这个值
      child: PopScope(
          canPop: onWillPop != null,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              return; // Pop 已发生，我们不做任何事
            }
            // 拦截返回事件
            final bool shouldPop =
                onWillPop != null ? await onWillPop!() : true;
            if (shouldPop) {
              // 如果允许退出，则播放退出动画
              if (onDidPop != null) {
                debugPrint('开始退出动画');
                await onDidPop!();
              } else {
                await animatedPageKey.currentState?.didPop();
              }

              // 动画完成后，手动退出页面
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: MetroAnimatedPage(
            key: animatedPageKey,
            child: content,
          ),
        ),
    );
  }
}

/// 提供 Metro UI 风格的页面视觉布局结构。
///
/// 此类主要负责提供基础的页面结构与安全区域（SafeArea）处理，例如：
/// 自动处理并避让系统刘海、状态栏、以及当软键盘弹出时的底部收缩。
/// 这是构筑 Metro 风格应用的顶层容器级组件。
///
/// 另请参见：
///
///  * [MetroPageScaffoldState]，与此组件关联的状态类。
class MetroPageScaffold extends StatefulWidget {
  /// 创建 Metro Design 小部件的视觉脚手架。
  const MetroPageScaffold({
    super.key,
    this.body,
    this.stackPanel,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.onWillPop,
    this.onDidPop,
    this.onDidPush,
    this.onDidPushNext,
    this.onDidPopNext,
    this.backButtonAlignment = Alignment.bottomLeft,
    this.applicationBar,
  });

  /// 返回按钮的对齐方式，当页面被推入导航栈具有上层页面时，会自动显示返回按钮。
  ///
  /// 默认显示在左下角 [Alignment.bottomLeft]。
  final AlignmentGeometry backButtonAlignment;

  /// 整个页面的主要内容。
  ///
  /// 如果 [resizeToAvoidBottomInset] 为 false，
  /// 则当屏幕键盘出现时，主体内容不会在底部退缩调整大小以避开键盘。
  final Widget? body;

  /// 显示在页面顶部的面板组件。
  ///
  /// 如果提供，将显示在 [body] 上方的固定位置。通常用于显示页面的大标题或重要的操作入口。
  final Widget? stackPanel;

  /// 页面框架最底层的背景颜色。
  final Color? backgroundColor;

  /// 如果为 true，页面主体当屏幕键盘出现时，将自动调整安全边距以避免被屏幕键盘等系统UI遮挡。
  ///
  /// 默认为 true。
  final bool? resizeToAvoidBottomInset;

  /// 是否将此页面的排版适配拓展至屏幕顶部边缘。
  ///
  /// 此属性默认值为 true。表明页面会自动计算并占据顶部系统状态栏（StatusBar）相应的留白与插槽。
  final bool primary;

  /// 当页面即将退出时调用，允许开发者执行自定义逻辑。
  /// 返回 true 表示允许退出，返回 false 表示阻止退出。
  final Future<bool> Function()? onWillPop;

  ///当路由发生时，会调用对于的方法，此处的方法建议不要产生任何业务逻辑而是纯粹的UI操作，否则会导致业务逻辑和UI耦合
  //当页面进入时调用
  final VoidCallback? onDidPush;
  //当页面退出时调用
  final Future<void> Function()? onDidPop;

  /// 当页面进入下一个页面时调用
  /// 设计目的是为了播放一段动画然后再进入下一个页面。不建议在这个方法中进行任何业务逻辑处理
  /// 你可以在[metroPagePush]中使用[dataToPass]参数传递泛型数据到此处
  /// 详细使用案例请参考demo
  final Future<void> Function<T>(T)? onDidPushNext;

  //当页面从下一个页面退出时调用
  final VoidCallback? onDidPopNext;

  /// Windows Phone 风格的底部 Application Bar 配置。
  ///
  /// 当页面成为顶层路由时，此菜单会自动显示并渐变淘入。
  /// 切换到其他页面时，该菜单会渐变消失，新页面的菜单在动画完成后显示。
  final MetroApplicationBar? applicationBar;

  /// 从最接近的此类实例中查找 [MetroPageScaffoldState]。
  ///
  /// 如果没有此类实例包含给定的上下文，在调试模式下会导致断言，在发布模式下会抛出异常。
  ///
  /// 此方法可能会很耗时（它会遍历元素树）。
  ///
  /// {@tool dartpad}
  /// [MetroPageScaffold.of] 函数的典型用法是在 [MetroPageScaffold] 子小部件的 `build` 方法中调用它。
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold.of.0.dart 中的代码 **
  /// {@end-tool}
  ///
  /// {@tool dartpad}
  /// 当 [MetroPageScaffold] 实际上是在同一个 `build` 函数中创建时，`build` 函数的 `context` 参数不能用于查找 [MetroPageScaffold]（因为它在返回的小部件树中位于小部件的“上方”）。在这种情况下，可以使用以下技术与 [Builder] 提供一个新的作用域，其中包含“在”[MetroPageScaffold] 下的 [BuildContext]：
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold.of.1.dart 中的代码 **
  /// {@end-tool}
  ///
  /// 更有效的解决方案是将你的构建函数拆分为几个小部件。这会引入一个新的上下文，你可以从中获取 [MetroPageScaffold]。在这种解决方案中，你会有一个外部小部件来创建由新内部小部件实例填充的 [MetroPageScaffold]，然后在这些内部小部件中使用 [MetroPageScaffold.of]。
  ///
  /// 一个不太优雅但更快捷的解决方案是为 [MetroPageScaffold] 分配一个 [GlobalKey]，然后使用 `key.currentState` 属性来获取 [MetroPageScaffoldState]，而不是使用 [MetroPageScaffold.of] 函数。
  ///
  /// 如果范围内没有 [MetroPageScaffold]，则会抛出异常。要在没有 [MetroPageScaffold] 时返回 null，请使用 [maybeOf]。
  static MetroPageScaffoldState of(BuildContext context) {
    final MetroPageScaffoldState? result =
        context.findAncestorStateOfType<MetroPageScaffoldState>();
    if (result != null) {
      return result;
    }
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(
        'Scaffold.of() called with a context that does not contain a Scaffold.',
      ),
      ErrorDescription(
        'No Scaffold ancestor could be found starting from the context that was passed to Scaffold.of(). '
        'This usually happens when the context provided is from the same StatefulWidget as that '
        'whose build function actually creates the Scaffold widget being sought.',
      ),
      ErrorHint(
        'There are several ways to avoid this problem. The simplest is to use a Builder to get a '
        'context that is "under" the Scaffold. For an example of this, please see the '
        'documentation for Scaffold.of():\n'
        '  https://api.flutter.dev/flutter/material/Scaffold/of.html',
      ),
      ErrorHint(
        'A more efficient solution is to split your build function into several widgets. This '
        'introduces a new context from which you can obtain the Scaffold. In this solution, '
        'you would have an outer widget that creates the Scaffold populated by instances of '
        'your new inner widgets, and then in these inner widgets you would use Scaffold.of().\n'
        'A less elegant but more expedient solution is assign a GlobalKey to the Scaffold, '
        'then use the key.currentState property to obtain the ScaffoldState rather than '
        'using the Scaffold.of() function.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// 从最接近的此类实例中查找 [MetroPageScaffoldState]。
  ///
  /// 如果没有此类实例包含给定的上下文，将返回 null。
  /// 要抛出异常，请使用 [of] 而不是此函数。
  ///
  /// 此方法可能会很耗时（它会遍历元素树）。
  ///
  /// 另请参见:
  ///
  ///  * [of]，这是一个类似的函数，但如果没有实例包含给定的上下文，它会抛出异常。其文档中还包括一些示例代码。
  static MetroPageScaffoldState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<MetroPageScaffoldState>();
  }

  @override
  MetroPageScaffoldState createState() => MetroPageScaffoldState();
}

/// [MetroPageScaffold] 的状态。
///
/// 可以使用 [MetroPageScaffold.of] 从当前的 [BuildContext] 中获取 [MetroPageScaffoldState]。
class MetroPageScaffoldState extends State<MetroPageScaffold>
    with TickerProviderStateMixin, RouteAware {
  final GlobalKey _bodyKey = GlobalKey();
  bool _hasPanorama = false;

  // 用于控制 MetroAnimatedPage 的动画
  final GlobalKey<MetroAnimatedPageState> _metroAnimatedPageKey =
      GlobalKey<MetroAnimatedPageState>();

  // 内部方法
  //late _ScaffoldGeometryNotifier _geometryNotifier;

  bool get _resizeToAvoidBottomInset {
    return widget.resizeToAvoidBottomInset ?? true;
  }

  /// 播放 MetroAnimatedPage 的默认退出动画。
  Future<void> playDefaultPushNextAnimation() async {
    await _metroAnimatedPageKey.currentState?.didPushNext();
  }

  /// 播放 MetroAnimatedPage 的默认进入动画。
  Future<void> playDefaultPushAnimation() async {
    await _metroAnimatedPageKey.currentState?.didPush();
  }

  /// 没有动画的时候的播放内容
  Future<void> playNonePushAnimation() async {
    await _metroAnimatedPageKey.currentState?.didFinish();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 登记当前页面的 Application Bar
      _updateApplicationBar();

      if (widget.onDidPush != null) {
        playNonePushAnimation();
        widget.onDidPush?.call();
      } else {
        // 播放默认的进入动画
        playDefaultPushAnimation();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 订阅路由变化
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(MetroPageScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.applicationBar != oldWidget.applicationBar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateApplicationBar();
      });
    }
  }

  @override
  void dispose() {
    //_geometryNotifier.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // @override
  // void didPush() {
  //   // 页面被推入，调用外部传入的回调
  //   //widget.onDidPush?.call();
  //   super.didPush();
  // }

  // @override
  // void didPop() {
  //   // 页面被弹出，调用外部传入的回调
  //   widget.onDidPop?.call();
  //   //super.didPop();
  // }

  // @override
  // void didPushNext() {
  //   // 新页面覆盖上来，调用外部传入的回调
  //   widget.onDidPushNext?.call(null);
  //   super.didPushNext();
  // }

  @override
  void didPopNext() {
    // 从下一页返回到本页，把本页的 Application Bar 重新显示
    _updateApplicationBar();
    widget.onDidPopNext?.call();
    _metroAnimatedPageKey.currentState?.didPopNext();
    super.didPopNext();
  }

  /// 将当前页面的 Application Bar 注册到全局控制器。
  void _updateApplicationBar() {
    if (!mounted) return;
    MetroAppBarScope.controllerOf(context)?.setAppBar(widget.applicationBar);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasDirectionality(context));
    final ThemeData themeData = Theme.of(context);

    Widget? body = widget.body == null
        ? null
        : NotificationListener<MetroPanoramaDetectNotification>(
            onNotification: (notification) {
              // 如果发现内部含有一个 Panorama！我们取消默认动画
              if (!_hasPanorama) {
                _hasPanorama = true;
                // 你可以在这里静默停止动画，或者将其重置
                _metroAnimatedPageKey.currentState?.didFinish(); // 停止推场动画
              }
              return true; // 拦截阻止冒泡
            },
            child: _BodyBuilder(
              body: KeyedSubtree(key: _bodyKey, child: widget.body!),
              stackPanel: widget.stackPanel,
              onWillPop: widget.onWillPop,
              onDidPop: widget.onDidPop,
              animatedPageKey: _metroAnimatedPageKey,
              backButtonAlignment: widget.backButtonAlignment,
            ),
          );

    if (body != null) {
      MediaQueryData data = MediaQuery.of(context).removePadding(
        removeTop: true,
      );
      if (_resizeToAvoidBottomInset) {
        data = data.removeViewInsets(removeBottom: true);
      }
      body = MediaQuery(data: data, child: body);
    }

    // The minimum insets for contents of the Scaffold to keep visible.
    final EdgeInsets minInsets = MediaQuery.paddingOf(context).copyWith(
      bottom: _resizeToAvoidBottomInset
          ? MediaQuery.viewInsetsOf(context).bottom
          : 0.0,
    );

    return ScrollNotificationObserver(
      child: Material(
        color: widget.backgroundColor ?? themeData.scaffoldBackgroundColor,
        child: Padding(
          padding: EdgeInsets.only(bottom: math.max(0.0, minInsets.bottom)),
          child: body,
        ),
      ),
    );
  }
}

// 用于特殊字组件通知父组件无需播放动画，直接完成页面切换
// 例如panorama页面自带了自己的动画，所以在进入panorama页面时不需要MetroPageScaffold再播放一段动画了
class MetroPanoramaDetectNotification extends Notification {
  const MetroPanoramaDetectNotification();
}
