// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

// ─────────────────────────── 数据模型 ───────────────────────────

/// Windows Phone Application Bar 的图标按钮。
///
/// 对应 WP 原版的 ApplicationBarIconButton，按钮会显示在底部菜单栏的左侧。
/// 最多建议放置 4 个按钮，超出的按钮在小屏设备上可能被遮挡。
class MetroAppBarButton {
  const MetroAppBarButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  /// 按钮图标，建议使用 [Icon] 组件。
  final Widget icon;

  /// 按钮标签，用于无障碍提示（Tooltip）。
  final String label;

  /// 按钮点击回调，为 null 时按钮显示为禁用状态。
  final VoidCallback? onPressed;
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
    this.buttons = const [],
    this.menuItems = const [],
    this.backgroundColor,
    this.mini = false,
  });

  /// 显示在菜单栏左侧的图标按钮列表，建议最多 4 个。
  final List<MetroAppBarButton> buttons;

  /// 点击「•••」后展开的文本菜单项列表。
  final List<MetroAppBarMenuItem> menuItems;

  /// 菜单栏背景色，默认为未展开时半透明黑、展开后纯黑。
  final Color? backgroundColor;

  /// mini 模式：折叠时仅露出 30px 的底部条，向上拖拽后才显示按钮行（同时伴随动画）。
  /// 非 mini 模式：折叠时默认露出 78px（按钮行始终可见），向上拖拽仅展开菜单项。
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
                    key: ObjectKey(bar),
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
  bool _isDragging = false;
  bool _useExpandedChrome = false;

  final double _kMiniStripH = 30.0; // ••• 条固定高度
  final double _topBarHeight = 50.0;
  final double _menuItemHeight = 56.0;

  /// 折叠状态下的默认可见高度：mini 30px，非 mini 78px。
  double get _collapsedHeight => widget.bar.mini ? 30.0 : 78.0;

  double get _totalContentHeight {
    double h = _kMiniStripH;
    if (widget.bar.buttons.isNotEmpty) h += _topBarHeight;
    if (widget.bar.menuItems.isNotEmpty) {
      h += widget.bar.menuItems.length * _menuItemHeight + 16.0;
    }
    return h;
  }

  double get _maxExpansionHeight => _totalContentHeight - _collapsedHeight;

  bool get _canExpand => _maxExpansionHeight > 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _buttonVisAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.bar.mini ? 0.0 : 1.0, // mini 初始隐藏；非 mini 始终可见
    );
  }

  @override
  void dispose() {
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
    if (!widget.bar.mini) return;
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
    const Color fgColor = Colors.white;

    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _buttonVisAnim]),
      builder: (context, _) {
        final bool isDragged = _isDragging && _animationController.value > 0;
        final bool useExpandedChrome = _useExpandedChrome || isDragged;
        final Color bgColor = widget.bar.backgroundColor ??
            (useExpandedChrome
                ? const Color(0xFF000000)
                : const Color.fromARGB(139, 0, 0, 0));

        final double totalH = _totalContentHeight;
        final double expandedH = _collapsedHeight +
            Curves.easeOut.transform(_animationController.value) *
                _maxExpansionHeight;
        final double heightFactor = totalH > 0 ? expandedH / totalH : 1.0;

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
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: heightFactor,
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
                        },
                        child: Stack(
                          children: [
                            if (_canExpand)
                              Positioned(
                                top: 0,
                                right: 0,
                                height: _kMiniStripH,
                                child: _MetroMoreButton(
                                  fgColor: fgColor,
                                  onTap: _toggleMenu,
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
                        //SizedBox(height: _kMiniStripH), // ••• 条占位
                        if (widget.bar.buttons.isNotEmpty)
                          // ClipRect 限制滑动动画的溢出范围
                          ClipRect(
                            child: SlideTransition(
                              position: buttonSlide,
                              child: FadeTransition(
                                opacity: _buttonVisAnim,
                                child: SizedBox(
                                  height: _topBarHeight,
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: widget.bar.buttons
                                          .map((btn) => _MetroBarIconButton(
                                                btn: btn,
                                                fgColor: fgColor,
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ...widget.bar.menuItems.map(
                          (item) => SizedBox(
                            height: _menuItemHeight,
                            child: _MetroMenuItemTile(
                              item: item,
                              fgColor: fgColor,
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
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────── 内部子组件 ───────────────────────────

class _MetroBarIconButton extends StatelessWidget {
  const _MetroBarIconButton({
    required this.btn,
    required this.fgColor,
  });

  final MetroAppBarButton btn;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: btn.label,
      button: true,
      child: GestureDetector(
        onTap: btn.onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: fgColor, width: 2.0),
              ),
              alignment: Alignment.center,
              child: IconTheme(
                data: IconThemeData(color: fgColor, size: 24),
                child: btn.icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetroMoreButton extends StatelessWidget {
  const _MetroMoreButton({
    required this.fgColor,
    required this.onTap,
  });

  final Color fgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Center(
          child: Icon(
            Icons.more_horiz,
            color: fgColor,
            size: 28,
          ),
        ),
      ),
    );
  }
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Text(
          item.label,
          style: TextStyle(
            color: fgColor,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
