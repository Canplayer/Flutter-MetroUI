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
  });

  /// 显示在菜单栏左侧的图标按钮列表，建议最多 4 个。
  final List<MetroAppBarButton> buttons;

  /// 点击「•••」后展开的文本菜单项列表。
  final List<MetroAppBarMenuItem> menuItems;

  /// 菜单栏背景色，默认跟随当前主题（暗色为黑色，亮色为白色）。
  final Color? backgroundColor;
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
    return context
        .getInheritedWidgetOfExactType<MetroAppBarScope>()
        ?.notifier;
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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final double _topBarHeight = 50.0;
  final double _menuItemHeight = 56.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_animationController.status == AnimationStatus.completed ||
        _animationController.status == AnimationStatus.forward) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  void _closeMenu() {
    _animationController.reverse();
  }

  double get _maxExpansionHeight =>
      widget.bar.menuItems.length * _menuItemHeight + 16.0;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (widget.bar.menuItems.isEmpty) return;
    // 向上滑动对应负的 delta，换算为正的增长比例
    final double delta = -details.primaryDelta!;
    final double valueDelta = delta / _maxExpansionHeight;
    _animationController.value += valueDelta;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (widget.bar.menuItems.isEmpty) return;
    if (details.primaryVelocity! < -300) {
      _animationController.forward(); // 向上快滑，展开
    } else if (details.primaryVelocity! > 300) {
      _animationController.reverse(); // 向下快滑，收起
    } else {
      if (_animationController.value > 0.5) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.bar.backgroundColor ?? const Color(0xE6000000);
    const Color fgColor = Colors.white;

    return Container(
      color: bgColor,
      child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶层按钮排区域
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                onTap: () {
                  if (_animationController.value > 0) _closeMenu();
                },
                child: SizedBox(
                  height: _topBarHeight,
                  child: Stack(
                    children: [
                      // 居中安排的图标按钮们
                      Center(
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
                      // 右侧固定展示的「•••」展开图标
                      if (widget.bar.menuItems.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: _MetroMoreButton(
                            fgColor: fgColor,
                            isOpen: false, // 废弃该参数引用
                            onTap: _toggleMenu,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 底部抽屉的菜单项，依赖容器扩大而被往上推
              if (widget.bar.menuItems.isNotEmpty)
                ClipRect(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Align(
                        alignment: Alignment.topCenter,
                        heightFactor: Curves.easeOut
                            .transform(_animationController.value),
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
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
    required this.isOpen,
    required this.onTap,
  });

  final Color fgColor;
  final bool isOpen;
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
