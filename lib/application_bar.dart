// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:metro_ui/metro_theme_extensions.dart';
import 'package:metro_ui/widgets/tile.dart';

// ---------------- 配置常量 ----------------
const double kMetroAppBarMiniHeight = 30.0 * 0.8; // 折叠时的 mini 条高度
const double kMetroAppBarNormalHeight = 71.875 * 0.8; // 正常模式下的折叠高度 (包含按钮)
const double kMetroAppBarMoreButtonSize =
    kMetroAppBarNormalHeight; // 更多(•••)按钮区域的尺寸
// ----------------------------------------

bool _isMiniModeFor(MetroApplicationBar bar) {
  return bar.mini || bar.buttons.isEmpty;
}

double _collapsedHeightFor(MetroApplicationBar bar) {
  return _isMiniModeFor(bar)
      ? kMetroAppBarMiniHeight
      : kMetroAppBarNormalHeight;
}

int _widgetVisualSignature(Widget widget) {
  if (widget is MetroAppBarButton) {
    return Object.hash(
      widget.key,
      widget.label,
      widget.onPressed != null,
      _widgetVisualSignature(widget.icon),
    );
  }

  if (widget is Icon) {
    return Object.hash(
      widget.key,
      widget.icon,
      widget.size,
      widget.color,
      widget.semanticLabel,
      widget.textDirection,
    );
  }

  return Object.hash(widget.runtimeType, widget.key);
}

int _buttonsVisualSignature(List<Widget> buttons) {
  return Object.hashAll(buttons.map(_widgetVisualSignature));
}

int _barStructureKey(MetroApplicationBar bar) {
  return Object.hashAll([
    bar.backgroundColor?.value,
    bar.menuItems.length,
    ...bar.menuItems.map((item) => item.label),
  ]);
}

// ─────────────────────────── 数据模型 ───────────────────────────

/// Windows Phone Application Bar 的图标按钮。
///
/// 对应 WP 原版的 ApplicationBarIconButton，按钮会显示在底部菜单栏的左侧。
/// 最多建议放置 4 个按钮，超出的按钮在小屏设备上可能被遮挡。
class MetroAppBarButton extends StatelessWidget {
  const MetroAppBarButton({
    super.key,
    required this.icon,
    this.color,
    this.iconColor,
    required this.label,
    this.onPressed,
  });

  /// 按钮图标，建议使用 [Icon] 组件。
  final Widget icon;

  /// 环形颜色
  final Color? color;

  /// 图标颜色
  final Color? iconColor;

  /// 按钮标签，用于无障碍提示（Tooltip）。
  final String label;

  /// 按钮点击回调，为 null 时按钮显示为禁用状态。
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final double circleSize = 48.125 * 0.8;
    return Semantics(
      label: label,
      button: true,
      child: Tile(
        onTap: onPressed,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 圆环主体：在 Stack 中居中
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color ??
                      Theme.of(context)
                          .extension<MetroAppBarTheme>()!
                          .buttonColor ??
                      Colors.white,
                  width: 5 * 0.625 * 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: IconTheme(
                data: IconThemeData(
                  color: Theme.of(context)
                          .extension<MetroAppBarTheme>()!
                          .buttonIconColor ??
                      Colors.white,
                  size: 24,
                ),
                child: icon,
              ),
            ),
            // 文字部分：定位在圆环下方，偏移固定距离（仅菜单展开时显示）
            if (_AppBarLabelVisibility.of(context))
              Positioned(
                top: circleSize + 7 * 0.8, // 圆环底部再往下 11.875*0.8 的位置
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: Theme.of(context)
                            .extension<MetroAppBarTheme>()!
                            .buttonIconColor ??
                        Colors.white,
                    fontSize: 13 * 0.8,
                    fontFamily: 'Segoe UI',
                    package: 'metro_ui',
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                  child: Text(
                    label,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Windows Phone Application Bar 的文本菜单项。
///
/// 对应 WP 原版的 ApplicationBarMenuItem，菜单项会在点击「•••」后
/// 从底部弹出，显示在菜单栏上方。
class MetroAppBarMenuItem {
  const MetroAppBarMenuItem({
    required this.label,
    this.onPressed,
  });

  /// 菜单项文本。
  final String label;

  /// 菜单项点击回调。
  final VoidCallback? onPressed;
}

/// Windows Phone 风格的底部 Application Bar 配置。
///
/// 在 [MetroPageScaffold.applicationBar] 中传入此对象，
/// 框架会自动在页面切换时实现跨页面渐变过渡效果。
///
/// 示例：
/// ```dart
/// MetroPageScaffold(
///   applicationBar: MetroApplicationBar(
///     buttons: [
///       MetroAppBarButton(
///         icon: Icon(Icons.add),
///         label: '新建',
///         onPressed: () { ... },
///       ),
///     ],
///     menuItems: [
///       MetroAppBarMenuItem(label: '设置', onPressed: () { ... }),
///     ],
///   ),
///   body: ...,
/// )
/// ```
class MetroApplicationBar {
  const MetroApplicationBar({
    this.buttons = const <Widget>[],
    this.menuItems = const [],
    this.backgroundColor,
    this.expandedBackgroundColor,
    this.buttonColor,
    this.buttonIconColor,
    this.menuItemTextColor,
    this.mini = false,
  });

  /// 显示在菜单栏左侧的按钮 Widget 列表，建议最多 4 个。
  final List<Widget> buttons;

  /// 点击「•••」后展开的文本菜单项列表。
  final List<MetroAppBarMenuItem> menuItems;

  /// 菜单栏折叠时的背景色，默认为半透明黑。
  final Color? backgroundColor;

  /// 菜单栏展开后的背景色，默认为纯黑。
  final Color? expandedBackgroundColor;

  /// 环形按钮的颜色与展开按钮的颜色
  final Color? buttonColor;

  /// 环形按钮中icon的颜色
  final Color? buttonIconColor;

  /// 菜单item文字的颜色
  final Color? menuItemTextColor;

  /// mini 模式：折叠时仅露出顶部条高，向上拖拽后才显示按钮行（同时伴随动画）。
  /// 非 mini 模式：折叠时默认露出足够高度（按钮行始终可见），向上拖拽仅展开菜单项。
  /// 当 [buttons] 为空时，会自动按 mini 模式处理。
  final bool mini;
}

// ─────────────────────────── 全局控制器 ───────────────────────────

/// 全局 Application Bar 状态控制器。
///
/// 由 [MetroAppBarScope] 管理生命周期，由 [MetroPageScaffold] 在路由
/// 生命周期中自动调用 [setAppBar]，外部一般不需要直接操作此类。
class MetroAppBarController extends ChangeNotifier {
  MetroApplicationBar? _currentBar;

  MetroApplicationBar? get currentBar => _currentBar;

  /// 切换当前 Application Bar 配置，若与当前相同则忽略。
  void setAppBar(MetroApplicationBar? bar) {
    if (_currentBar == bar) return;
    _currentBar = bar;
    notifyListeners();
  }
}

// ─────────────────────────── InheritedNotifier 作用域 ───────────────────────────

/// 将 [MetroAppBarController] 暴露给子树，由 [MetroApp] 在顶层注入。
class MetroAppBarScope extends InheritedNotifier<MetroAppBarController> {
  const MetroAppBarScope({
    super.key,
    required MetroAppBarController controller,
    required super.child,
  }) : super(notifier: controller);

  /// 获取控制器并建立依赖关系（适合在 [build] 中使用）。
  static MetroAppBarController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MetroAppBarScope>()
        ?.notifier;
  }

  /// 获取控制器但不建立依赖（适合在回调/生命周期方法中使用）。
  static MetroAppBarController? controllerOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<MetroAppBarScope>()?.notifier;
  }
}

// ─────────────────────────── 渲染层 ───────────────────────────

/// 全局悬浮的 Application Bar 渲染容器，由 [MetroApp] 在 Navigator 外部管理。
///
/// 此组件接收 [MetroAppBarController]，并通过 [AnimatedSwitcher] 在不同页面
/// 的 Application Bar 之间实现平滑的渐变切换效果。
class MetroApplicationBarOverlay extends StatelessWidget {
  const MetroApplicationBarOverlay({
    super.key,
    required this.controller,
  });

  final MetroAppBarController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final bar = controller.currentBar;
        // bar 为 null 时立即忽略所有指针事件，避免淡出动画期间遮挡底部内容
        return IgnorePointer(
          ignoring: bar == null,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: bar != null
                ? MetroApplicationBarView(
                    // 仅 buttons 变化时不触发整条 Application Bar 的切换淡入淡出。
                    key: ValueKey<int>(_barStructureKey(bar)),
                    bar: bar,
                  )
                : const SizedBox.shrink(key: ValueKey('__no_bar__')),
          ),
        );
      },
    );
  }
}

/// Windows Phone 风格底部 Application Bar 的具体渲染组件。
///
/// 使用 [ObjectKey] 绑定到 [MetroApplicationBar] 实例，
/// 每次页面切换都会创建新的 State，从而自动收起菜单。
class MetroApplicationBarView extends StatefulWidget {
  const MetroApplicationBarView({
    super.key,
    required this.bar,
  });

  final MetroApplicationBar bar;

  @override
  State<MetroApplicationBarView> createState() =>
      _MetroApplicationBarViewState();
}

class _MetroApplicationBarViewState extends State<MetroApplicationBarView>
    with TickerProviderStateMixin {
  late AnimationController _animationController; // 整体展开/收起（0=折叠, 1=完全展开）
  late AnimationController _buttonVisAnim; // 按钮行显隐（0=隐藏, 1=可见）
  late AnimationController _modeSwitchController; // mini/普通模式切换时的高度过渡
  bool _isDragging = false;
  bool _useExpandedChrome = false;
  double _modeFromCollapsedHeight = kMetroAppBarNormalHeight;
  double _modeToCollapsedHeight = kMetroAppBarNormalHeight;
  int _buttonsSignature = 0;
  int _buttonsAnimRevision = 0;

  final double _menuItemHeight = 68.125 * 0.8; // 菜单项固定高度

  bool get _isMiniMode => _isMiniModeFor(widget.bar);

  double get _targetCollapsedHeight => _collapsedHeightFor(widget.bar);

  /// 折叠状态下的默认可见高度
  double get _collapsedHeight {
    final double t = Curves.easeOutCubic.transform(_modeSwitchController.value);
    return _modeFromCollapsedHeight +
        (_modeToCollapsedHeight - _modeFromCollapsedHeight) * t;
  }

  double get _totalContentHeight {
    double h = 0;
    if (widget.bar.buttons.isNotEmpty) {
      h += kMetroAppBarNormalHeight;
    }
    if (widget.bar.menuItems.isNotEmpty) {
      // 有buttons和没有的时候，菜单抬起的高度并不一致
      h += widget.bar.menuItems.length * _menuItemHeight + (widget.bar.buttons.isNotEmpty ? 118.75 * 0.8 : 161.25* 0.8);
    }
    else {
      // 就算没有菜单项，mini 模式下也要抬起一点高度以露出按钮
      h += 30 * 0.8;
     }
    return h;
  }

  double get _maxExpansionHeight => _totalContentHeight - _collapsedHeight;

  bool get _canExpand => _maxExpansionHeight > 0;

  @override
  void initState() {
    super.initState();
    final double initialCollapsedHeight = _targetCollapsedHeight;
    _modeFromCollapsedHeight = initialCollapsedHeight;
    _modeToCollapsedHeight = initialCollapsedHeight;
    _modeSwitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1.0,
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _buttonVisAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: _isMiniMode ? 0.0 : 1.0, // mini 初始隐藏；非 mini 始终可见
    );
    _buttonsSignature = _buttonsVisualSignature(widget.bar.buttons);
  }

  @override
  void didUpdateWidget(covariant MetroApplicationBarView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final double targetCollapsedHeight = _targetCollapsedHeight;
    if ((targetCollapsedHeight - _modeToCollapsedHeight).abs() > 0.001) {
      _modeFromCollapsedHeight = _collapsedHeight;
      _modeToCollapsedHeight = targetCollapsedHeight;
      _modeSwitchController
        ..stop()
        ..value = 0.0
        ..forward();
    }

    final bool wasMiniMode = _isMiniModeFor(oldWidget.bar);
    if (wasMiniMode != _isMiniMode) {
      if (_isMiniMode) {
        if (_animationController.value == 0 && !_useExpandedChrome) {
          _buttonVisAnim.reverse();
        }
      } else {
        _buttonVisAnim.forward();
      }
    }

    final int nextButtonsSignature =
        _buttonsVisualSignature(widget.bar.buttons);
    if (nextButtonsSignature != _buttonsSignature) {
      _buttonsSignature = nextButtonsSignature;
      _buttonsAnimRevision += 1;
    }
  }

  @override
  void dispose() {
    _modeSwitchController.dispose();
    _animationController.dispose();
    _buttonVisAnim.dispose();
    super.dispose();
  }

  void _setDragging(bool dragging) {
    if (_isDragging == dragging) return;
    setState(() {
      _isDragging = dragging;
    });
  }

  void _setExpandedChromeVisible(bool visible) {
    if (_useExpandedChrome == visible) return;
    setState(() {
      _useExpandedChrome = visible;
    });
    if (!_isMiniMode) return;
    if (visible) {
      _buttonVisAnim.forward();
    } else {
      _buttonVisAnim.reverse();
    }
  }

  void _settleMenu(bool expand) {
    _setDragging(false);
    _setExpandedChromeVisible(expand);
    if (expand) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _toggleMenu() {
    if (_animationController.status == AnimationStatus.completed ||
        _animationController.status == AnimationStatus.forward) {
      _settleMenu(false);
    } else {
      _settleMenu(true);
    }
  }

  void _closeMenu() {
    _settleMenu(false);
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (!_canExpand) return;
    _setDragging(true);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_canExpand) return;
    _setDragging(true);
    final double delta = -details.primaryDelta!;
    final double valueDelta = delta / _maxExpansionHeight;
    _animationController.value =
        (_animationController.value + valueDelta).clamp(0.0, 1.0);
    if (_animationController.value > 0) {
      _setExpandedChromeVisible(true);
    }
  }

  void _onVerticalDragCancel() {
    if (!_canExpand) return;
    final bool expand = _animationController.value > 0.5;
    _settleMenu(expand);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_canExpand) return;
    final bool expand;
    if (details.primaryVelocity! < -300) {
      expand = true;
    } else if (details.primaryVelocity! > 300) {
      expand = false;
    } else {
      expand = _animationController.value > 0.5;
    }
    _settleMenu(expand);
  }

  @override
  Widget build(BuildContext context) {
    //const Color fgColor = Colors.white;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _animationController,
        _buttonVisAnim,
        _modeSwitchController,
      ]),
      builder: (context, _) {
        final bool isDragged = _isDragging && _animationController.value > 0;
        final bool useExpandedChrome = _useExpandedChrome || isDragged;
        // label 仅在：手指在屏幕上 或 菜单未彻底收起 时显示
        final bool showLabel = _isDragging || _animationController.value > 0;

        final Color collapsedBg = widget.bar.backgroundColor ??
            Theme.of(context).extension<MetroAppBarTheme>()!.backgroundColor ??
            Colors.black;
        final Color expandedBg = widget.bar.expandedBackgroundColor ??
            Theme.of(context)
                .extension<MetroAppBarTheme>()!
                .expandedBackgroundColor ??
            Colors.black.withAlpha(200);

        final Color bgColor = useExpandedChrome ? expandedBg : collapsedBg;

        final double expandedH = _collapsedHeight +
            Curves.easeOut.transform(_animationController.value) *
                _maxExpansionHeight;
        final Key buttonsContentKey = ValueKey<int>(_buttonsAnimRevision);

        // 按钮行滑入/滑出动画（向上飞入，向下飞出）
        final Animation<Offset> buttonSlide = Tween<Offset>(
          begin: const Offset(0, 1), // 隐藏在自身高度下方
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _buttonVisAnim,
          curve: Curves.easeOut,
        ));

        return Container(
          color: bgColor,
          child: SafeArea(
            top: false,
            child: ClipRect(
              child: SizedBox(
                  height: expandedH,
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: Stack(
                      children: [
                        // 拖拽区域 + ••• 按钮（覆盖折叠状态的完整可见高度）
                        // 此区域应该在底层，内容在此之上操作优先级更高
                        Positioned(
                          left: 0,
                          top: 0,
                          right: 0,
                          height: _collapsedHeight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onVerticalDragStart: _onVerticalDragStart,
                            onVerticalDragUpdate: _onVerticalDragUpdate,
                            onVerticalDragCancel: _onVerticalDragCancel,
                            onVerticalDragEnd: _onVerticalDragEnd,
                            onTap: () {
                              if (useExpandedChrome) _closeMenu();
                              else _toggleMenu();
                            },
                            child: Stack(
                              children: [
                                //if (_canExpand)
                                  Positioned(
                                    top: 11.875 * 0.8,
                                    right: 23.75 * 0.8,
                                    child: SizedBox(
                                      width: 41* 0.625 * 0.8,
                                      height: 9 * 0.625 * 0.8,
                                      child: FittedBox(
                                        // 自动等比缩放并居中
                                        fit: BoxFit.contain,
                                        child: CustomPaint(
                                          size: const Size(41, 9),
                                          painter: _ThreeDotsP(
                                              color: Theme.of(context)
                                                      .extension<
                                                          MetroAppBarTheme>()!
                                                      .buttonIconColor ??
                                                  Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // 内容列（撑开 Stack 的完整布局高度）
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 按钮行
                            if (widget.bar.buttons.isNotEmpty)
                              SlideTransition(
                                position: buttonSlide,
                                child: FadeTransition(
                                  opacity: _buttonVisAnim,
                                  child: _AppBarLabelVisibility(
                                    show: showLabel,
                                    child: SizedBox(
                                      height: kMetroAppBarNormalHeight,
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 700),
                                          reverseDuration:
                                              const Duration(milliseconds: 100),
                                          layoutBuilder:
                                              (currentChild, previousChildren) {
                                            return Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                ...previousChildren,
                                                if (currentChild != null)
                                                  currentChild,
                                              ],
                                            );
                                          },
                                          transitionBuilder:
                                              (child, animation) {
                                            final bool isIncoming =
                                                child.key == buttonsContentKey;
                                            if (isIncoming) {
                                              return FadeTransition(
                                                opacity: Tween<double>(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ).animate(
                                                  CurvedAnimation(
                                                    parent: animation,
                                                    curve: const Interval(
                                                        0.0, 0.25,
                                                        curve: Curves.linear),
                                                  ),
                                                ),
                                                child: SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(0, 1),
                                                    end: Offset.zero,
                                                  ).animate(
                                                    CurvedAnimation(
                                                      parent: animation,
                                                      curve: Curves.elasticOut,
                                                    ),
                                                  ),
                                                  child: child,
                                                ),
                                              );
                                            }

                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                          child: KeyedSubtree(
                                            key: buttonsContentKey,
                                            child: Row(
                                              spacing: 36.25 * 0.8,
                                              mainAxisSize: MainAxisSize.min,
                                              children: widget.bar.buttons,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            SizedBox(height: widget.bar.buttons.isNotEmpty ? 24 * 0.8: 66.25 * 0.8),

                            // 菜单项列
                            ...widget.bar.menuItems.map(
                              (item) => SizedBox(
                                height: _menuItemHeight,
                                child: _MetroMenuItemTile(
                                  item: item,
                                  fgColor: widget.bar.menuItemTextColor ??
                                      Theme.of(context)
                                          .extension<MetroAppBarTheme>()!
                                          .menuItemColor ??
                                      Colors.white,
                                  onTap: () {
                                    _closeMenu();
                                    item.onPressed?.call();
                                  },
                                ),
                              ),
                            ),

                            if (widget.bar.menuItems.isNotEmpty)
                              const SizedBox(height: 16),
                          ],
                        ),
                      ],
                    ),
                  )),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────── 内部子组件 ───────────────────────────

/// 向按钮行的子树（[MetroAppBarButton]）传递 label 可见状态。
/// show=true 时立即显示 label，show=false 时立即隐藏，无动画。
class _AppBarLabelVisibility extends InheritedWidget {
  const _AppBarLabelVisibility({
    required this.show,
    required super.child,
  });

  final bool show;

  /// 返回最近祖先的 show 值；若不在菜单栏内则默认 true（独立使用时 label 始终可见）。
  static bool of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_AppBarLabelVisibility>()
            ?.show ??
        true;
  }

  @override
  bool updateShouldNotify(_AppBarLabelVisibility oldWidget) =>
      oldWidget.show != show;
}

class _MetroMenuItemTile extends StatelessWidget {
  const _MetroMenuItemTile({
    required this.item,
    required this.fgColor,
    required this.onTap,
  });

  final MetroAppBarMenuItem item;
  final Color fgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tile(
      onTap: onTap,
      //behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 0),
        alignment: Alignment.centerLeft,
        child: DefaultTextStyle(
          style: TextStyle(
            color: fgColor,
            fontSize: 32 * 0.8,
            fontFamily: 'Segoe UI',
            package: 'metro_ui',
            fontWeight: FontWeight.w300,
            //字宽
            //letterSpacing: 0.1,
          ),
          child: Text(
            item.label,
          ),
        ),
      ),
    );
  }
}

class _ThreeDotsP extends CustomPainter {
  const _ThreeDotsP({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double r = 4.5; // 直径 9
    const double gap = 7;
    const double step = r * 2 + gap; // 16
    final double cy = size.height / 2;
    final paint = Paint()..color = color;
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(r + i * step, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_ThreeDotsP oldDelegate) => oldDelegate.color != color;
}
