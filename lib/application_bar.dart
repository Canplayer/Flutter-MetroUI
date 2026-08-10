// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/metro_theme_extensions.dart';
import 'package:metro_ui/widgets/metro_circle_button.dart';
import 'package:metro_ui/widgets/tile.dart';

// ---------------- 配置常量 ----------------
const double kMetroAppBarMiniHeight = 30.0 * 0.8; // 折叠时的 mini 条高度
const double kMetroAppBarNormalHeight = 72 * 0.8; // 正常模式下的折叠高度 (包含按钮)
const double kMetroAppBarMoreButtonSize =
    kMetroAppBarNormalHeight; // 更多(•••)按钮区域的尺寸
const double kMetroAppBarButtonSize = 48.125 * 0.8; // 环形按钮直径
// 按钮行内圆环顶部的固定间距：圆环垂直居中于按钮行（kMetroAppBarNormalHeight）时的上边距。
// 用固定间距（而非 Center 居中）定位圆环，按钮高度变化（文字显隐）不会使圆环上移。
const double kMetroAppBarButtonTopInset =
    (kMetroAppBarNormalHeight - kMetroAppBarButtonSize) / 2;
// 按钮文字区域高度（圆环底部间距 + 文字行高）
const double kMetroAppBarButtonLabelAreaHeight = 7 * 0.8 + 14;
// 按钮行总高：圆环定位间距 + 按钮 + 文字区域。
// 保证菜单展开后文字仍在按钮行命中区域内，点击文字也能触发按钮。
const double kMetroAppBarButtonRowHeight = kMetroAppBarButtonTopInset +
    kMetroAppBarButtonSize +
    kMetroAppBarButtonLabelAreaHeight;
// 按钮之间的原始视觉间距（原 Row spacing：36.25 * 0.8），现已吸收进按钮宽度。
// 按钮（Tile 层）宽度 = 圆环直径 + 该间距：按钮之间无额外间隔（Row 无 spacing），
// 圆环在按钮内居中 → 圆环中心距 = 按钮宽度 = 原来的 (直径 + spacing)，
// 圆环之间的视觉间距与最初布局完全一致；同时文字可用宽度 = 按钮宽度，
// 稍长的标签也能单行完整显示不换行。
const double kMetroAppBarButtonSpacing = 36.25 * 0.8;
const double kMetroAppBarButtonWidth =
    kMetroAppBarButtonSize + kMetroAppBarButtonSpacing;
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
  // 只反映 AppBar 的“外壳”结构（背景色、mini 模式），不包含 menuItems：
  // menuItems 是展开后才可见的内容。若算进 key，跨页面跳转时
  // （不同页面的 menuItems 往往不同）会触发整条 AppBar 的切换淡入淡出
  // （旧条下降 + 新条弹出），而不是连贯的“外壳不动、按钮行切换”。
  // 按钮行/菜单项变化由 MetroApplicationBarView 内部的 AnimatedSwitcher
  // （按钮行）与 Column 重建（菜单项，折叠时不可见）处理。
  return Object.hashAll([
    // bar.backgroundColor?.value,
    // bar.expandedBackgroundColor?.value,
    // bar.mini,
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
    final double circleSize = kMetroAppBarButtonSize;
    final bool isDisabled = onPressed == null;
    final bool labelVisible = _AppBarLabelVisibility.of(context);
    // 文字区域高度（圆环底部间距 + 文字行高），用于撑高按钮命中区域，
    // 保证菜单展开后点击文字也能触发按压/点击
    final double labelAreaHeight =
        labelVisible ? kMetroAppBarButtonLabelAreaHeight : 0.0;
    // 按钮（Tile 层）宽度 = 圆环直径 + 原按钮间距：
    // 圆环在按钮内居中、位置不变，圆环中心距保持最初的视觉间距；
    // 文字可用宽度 = 按钮宽度，单行完整显示。
    final double buttonWidth = kMetroAppBarButtonWidth;

    return Tile(
      // Tile 不再承担点击事件（保留其 3D 回弹/旋转动画），
      // 点击与按压状态由内部 MetroPressDetector 负责。
      child: MetroPressDetector(
        onPressed: onPressed,
        child: SizedBox(
          width: buttonWidth,
          height: circleSize + labelAreaHeight,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // 透明占位：撑满按钮的命中区域（覆盖下方文字，点击文字也能触发），
              // 圆环在按钮内居中，位置由按钮行的固定顶部间距决定，不受宽度变化影响
              SizedBox(
                width: buttonWidth,
                height: circleSize + labelAreaHeight,
              ),
              MetroCircleButton(
                icon: icon,
                borderColor: color,
                iconColor: iconColor,
                semanticLabel: label,
                // 纯图标模式：不嵌套自己的 Tile；通过 MetroPressScope 自动跟随
                // 外层 MetroPressDetector 的按压状态（手指在按钮上则亮）
                iconMode: true,
                // 禁用时强制不高亮，其余情况交给 MetroPressScope
                pressed: isDisabled ? false : null,
              ),
              // 文字部分：位于圆环下方（仅菜单展开时显示），
              // 可用宽度 = 按钮宽度，单行完整显示不换行
              if (labelVisible)
                Positioned(
                  top: circleSize + 7 * 0.8, // 圆环底部再往下 11.875*0.8 的位置
                  left: 0,
                  right: 0,
                  child: Center(
                    child: DefaultTextStyle(
                      style: (Theme.of(context).textTheme.bodyMedium ??
                              const TextStyle())
                          .copyWith(
                        color: Theme.of(context)
                                .extension<MetroAppBarTheme>()!
                                .buttonIconColor ??
                            Colors.white,
                        fontSize: 13 * 0.8,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                      child: Text(
                        label,
                        // 兜底：极端超长时也不折行（按文本边界裁剪）
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
    this.expandCurve,
    this.collapseCurve,
    this.expandDuration,
    this.collapseDuration,
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

  /// MetroAppBar的展开动画曲线
  final Curve? expandCurve;

  /// MetroAppBar的收缩动画曲线
  final Curve? collapseCurve;

  /// MetroAppBar的展开动画时间
  final Duration? expandDuration;

  /// MetroAppBar的收缩动画时间
  final Duration? collapseDuration;

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
            duration: const Duration(milliseconds: 200),
            switchInCurve: MetroCurves.appBarTranslateIn,
            switchOutCurve: MetroCurves.appBarTranslateIn,
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
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
  // --- AppBar 按钮切换 & 初始载入的动画体系配置 ---
  static const Duration btnOutgoingDuration =
      Duration(milliseconds: 100); // 退出时间
  static const Curve btnOutgoingCurve = Curves.easeIn; // 退出曲线
  static const double btnOutgoingDistance = 40.0; // 退出垂直距离 (向上移动)

  static const Duration btnIncomingDelay =
      Duration(milliseconds: 100); // 进入延迟时间
  static const Duration btnIncomingDuration =
      Duration(milliseconds: 400); // 进入动画时间
  static const Curve btnIncomingCurve =
      MetroCurves.appBarButtonTranslateIn; // 进入动画曲线
  static const double btnIncomingDistance = 50.0; // 进入垂直起始距离 (距下方)
  // ------------------------------------------------

  // --- Menu菜单展开/收起时(如向上滑引出更多项)，按钮行动画配置 ---
  static const Duration menuIncomingDuration = Duration(milliseconds: 200);
  static const Curve menuIncomingCurve = Curves.easeIn;
  static const double menuIncomingDistance = kMetroAppBarMiniHeight;

  static const Duration menuOutgoingDuration = Duration(milliseconds: 200);
  static const Curve menuOutgoingCurve = Curves.easeIn;
  static const double menuOutgoingDistance = kMetroAppBarMiniHeight;
  // ------------------------------------------------

  // --- 从 Mini 到非 Mini (或反之) 状态切换时，按钮行动画配置 ---
  static const Duration miniSwitchIncomingDuration =
      Duration(milliseconds: 400);
  static const Curve miniSwitchIncomingCurve =
      MetroCurves.appBarButtonTranslateIn;
  static const double miniSwitchIncomingDistance = 50;

  static const Duration miniSwitchOutgoingDuration =
      Duration(milliseconds: 400);
  static const Curve miniSwitchOutgoingCurve = Curves.easeIn;
  static const double miniSwitchOutgoingDistance = kMetroAppBarMiniHeight;
  // ------------------------------------------------

  late AnimationController _animationController; // 整体展开/收起（0=折叠, 1=完全展开）
  late AnimationController _buttonVisAnim; // 按钮行显隐（0=隐藏, 1=可见）
  late AnimationController _modeSwitchController; // mini/普通模式切换时的高度过渡
  bool _isDragging = false;
  bool _useExpandedChrome = false;
  bool _isFirstLoad = true; // 跟踪是否处于界面的第一帧以便播放初始进入动画
  bool _isTriggeredByMiniSwitch = false; // 判断动画触发缘由
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
      // 按钮行加高部分已由下方间距等量缩减，实际内容总高不变
      h += kMetroAppBarNormalHeight;
    }
    if (widget.bar.menuItems.isNotEmpty) {
      // 有buttons和没有的时候，菜单抬起的高度并不一致
      h += widget.bar.menuItems.length * _menuItemHeight +
          (widget.bar.buttons.isNotEmpty ? 118.75 * 0.8 : 161.25 * 0.8);
    } else {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
      }
    });

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
      duration: menuIncomingDuration,
      reverseDuration: menuOutgoingDuration,
      value: _isMiniMode ? 0.0 : 1.0, // 把控制行显隐的系统复原，其不应干扰子组件进场
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
      _isTriggeredByMiniSwitch = true;
      _buttonVisAnim.duration = miniSwitchIncomingDuration;
      _buttonVisAnim.reverseDuration = miniSwitchOutgoingDuration;

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

    _isTriggeredByMiniSwitch = false;
    _buttonVisAnim.duration = menuIncomingDuration;
    _buttonVisAnim.reverseDuration = menuOutgoingDuration;

    if (visible) {
      _buttonVisAnim.forward();
    } else {
      _buttonVisAnim.reverse();
    }
  }

  void _settleMenu(bool expand) {
    _setDragging(false);
    _setExpandedChromeVisible(expand);

    final theme = Theme.of(context).extension<MetroAppBarTheme>();
    final Curve eCurve =
        widget.bar.expandCurve ?? theme?.expandCurve ?? Curves.easeOut;
    final Curve cCurve =
        widget.bar.collapseCurve ?? theme?.collapseCurve ?? Curves.easeIn;
    final Duration eDur = widget.bar.expandDuration ??
        theme?.expandDuration ??
        const Duration(milliseconds: 250);
    final Duration cDur = widget.bar.collapseDuration ??
        theme?.collapseDuration ??
        const Duration(milliseconds: 250);

    if (expand) {
      _animationController.animateTo(1.0, duration: eDur, curve: eCurve);
    } else {
      _animationController.animateTo(0.0, duration: cDur, curve: cCurve);
    }
  }

  void _toggleMenu() {
    _settleMenu(!_useExpandedChrome);
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

        final double expandedH =
            _collapsedHeight + _animationController.value * _maxExpansionHeight;
        final Key buttonsContentKey = ValueKey<int>(_buttonsAnimRevision);

        final bool isRowExiting =
            _buttonVisAnim.status == AnimationStatus.reverse ||
                _buttonVisAnim.status == AnimationStatus.dismissed;

        // 获取当前的各类参数
        final Curve incomingCurve = _isTriggeredByMiniSwitch
            ? miniSwitchIncomingCurve
            : menuIncomingCurve;
        final Curve outgoingCurve = _isTriggeredByMiniSwitch
            ? miniSwitchOutgoingCurve
            : menuOutgoingCurve;
        final double incomingDistance = _isTriggeredByMiniSwitch
            ? miniSwitchIncomingDistance
            : menuIncomingDistance;
        final double outgoingDistance = _isTriggeredByMiniSwitch
            ? miniSwitchOutgoingDistance
            : menuOutgoingDistance;

        // 按钮行滑入/滑出动画（向上飞入，向下飞出）
        final Animation<Offset> buttonSlide = Tween<Offset>(
          begin: Offset(
              0,
              isRowExiting
                  ? (outgoingDistance / kMetroAppBarNormalHeight)
                  : (incomingDistance / kMetroAppBarNormalHeight)),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _buttonVisAnim,
          curve: incomingCurve,
          reverseCurve: outgoingCurve,
        ));

        return Container(
          color: bgColor,
          child: SafeArea(
            top: false,
            child: SizedBox(
                height: expandedH,
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none,
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
                            if (useExpandedChrome)
                              _closeMenu();
                            else
                              _toggleMenu();
                          },
                          child: Stack(
                            children: [
                              //if (_canExpand)
                              Positioned(
                                top: 11.875 * 0.8,
                                right: 23.75 * 0.8,
                                child: SizedBox(
                                  width: 41 * 0.625 * 0.8,
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
                                opacity: isRowExiting
                                    ? _buttonVisAnim
                                    : const AlwaysStoppedAnimation(1.0),
                                child: _AppBarLabelVisibility(
                                  show: showLabel,
                                  child: SizedBox(
                                    height: kMetroAppBarButtonRowHeight,
                                    child: Padding(
                                      // 圆环贴按钮顶部，用固定顶部间距定位圆环，
                                      // 按钮行高度变化（文字显隐）不会使圆环上移
                                      padding: EdgeInsets.only(
                                          top: kMetroAppBarButtonTopInset),
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Builder(
                                          builder: (context) {
                                            // --- 自动计算 ---
                                            // AnimatedSwitcher的duration控制进场，reverseDuration控制退场
                                            final Duration
                                                totalIncomingDuration =
                                                btnIncomingDelay +
                                                    btnIncomingDuration;
                                            final double incomingStartRatio =
                                                btnIncomingDelay
                                                        .inMilliseconds /
                                                    totalIncomingDuration
                                                        .inMilliseconds;

                                            return AnimatedSwitcher(
                                              duration: totalIncomingDuration,
                                              reverseDuration:
                                                  btnOutgoingDuration,
                                              layoutBuilder: (currentChild,
                                                  previousChildren) {
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
                                                    child.key ==
                                                        buttonsContentKey;
                                                if (isIncoming) {
                                                  return FadeTransition(
                                                    opacity: Tween<double>(
                                                      begin: 0.0,
                                                      end: 1.0,
                                                    ).animate(
                                                      CurvedAnimation(
                                                        parent: animation,
                                                        curve: Threshold(
                                                            incomingStartRatio),
                                                      ),
                                                    ),
                                                    child: SlideTransition(
                                                      position: Tween<Offset>(
                                                        begin: Offset(
                                                            0,
                                                            btnIncomingDistance /
                                                                kMetroAppBarNormalHeight),
                                                        end: Offset.zero,
                                                      ).animate(
                                                        CurvedAnimation(
                                                          parent: animation,
                                                          curve: Interval(
                                                            incomingStartRatio,
                                                            1.0,
                                                            curve:
                                                                btnIncomingCurve,
                                                          ),
                                                        ),
                                                      ),
                                                      child: child,
                                                    ),
                                                  );
                                                }

                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: SlideTransition(
                                                    position: Tween<Offset>(
                                                      begin: Offset(
                                                          0,
                                                          -btnOutgoingDistance /
                                                              kMetroAppBarNormalHeight),
                                                      end: Offset.zero,
                                                    ).animate(
                                                      CurvedAnimation(
                                                        parent: animation,
                                                        curve: btnOutgoingCurve,
                                                      ),
                                                    ),
                                                    child: child,
                                                  ),
                                                );
                                              },
                                              child: _isFirstLoad
                                                  ? const SizedBox.shrink(
                                                      key: ValueKey(
                                                          '__initial_empty__'))
                                                  : KeyedSubtree(
                                                      key: buttonsContentKey,
                                                      child: Row(
                                                        // 按钮之间无额外间隔：
                                                        // 按钮宽度 = 圆环直径 + 原间距，
                                                        // 圆环在按钮内居中，
                                                        // 圆环中心距由按钮自身宽度自然形成
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children:
                                                            widget.bar.buttons,
                                                      ),
                                                    ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          SizedBox(
                              height: widget.bar.buttons.isNotEmpty
                                  ? 24 * 0.8 -
                                      (kMetroAppBarButtonRowHeight -
                                          kMetroAppBarNormalHeight)
                                  : 66.25 * 0.8),

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
          style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
              .copyWith(
            color: fgColor,
            fontSize: 32 * 0.8,
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

/// 手指停留检测组件（对应 Windows Phone 原版图标按钮的按压行为）。
///
/// 行为规则：
/// - 手指按下 → 亮起（[MetroPressScope] 广播 true）
/// - 手指滑动离开组件范围（未抬起）→ 熄灭（广播 false）
/// - 手指未抬起、重新滑回组件范围 → 再次亮起
/// - 亮起状态下抬起手指 → 触发 [onPressed]
///
/// 通常与 [Tile] 搭配使用：Tile 负责 3D 回弹动画，本组件负责
/// 按压状态与点击事件，两者互不干扰（本组件使用原始指针事件 [Listener]，
/// 不参与手势竞技场，因此不会与外层 Tile 的手势竞争）。
class MetroPressDetector extends StatefulWidget {
  const MetroPressDetector({
    super.key,
    this.onPressed,
    required this.child,
  });

  /// 亮起状态下抬起手指时触发。
  final VoidCallback? onPressed;

  final Widget child;

  @override
  State<MetroPressDetector> createState() => _MetroPressDetectorState();
}

class _MetroPressDetectorState extends State<MetroPressDetector> {
  /// 当前跟踪的手指（多指时只跟踪第一个）。
  int? _activePointer;

  /// 手指是否停留在组件范围内（亮起状态）。
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  bool _contains(Offset localPosition) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return false;
    return localPosition.dx >= 0 &&
        localPosition.dx <= box.size.width &&
        localPosition.dy >= 0 &&
        localPosition.dy <= box.size.height;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (_activePointer != null) return; // 已有手指在跟踪
        _activePointer = event.pointer;
        _setPressed(true);
      },
      onPointerMove: (event) {
        if (event.pointer != _activePointer) return;
        _setPressed(_contains(event.localPosition));
      },
      onPointerUp: (event) {
        if (event.pointer != _activePointer) return;
        if (_isPressed) {
          widget.onPressed?.call();
        }
        _setPressed(false);
        _activePointer = null;
      },
      onPointerCancel: (event) {
        if (event.pointer != _activePointer) return;
        _setPressed(false);
        _activePointer = null;
      },
      child: MetroPressScope(
        isPressed: _isPressed,
        child: widget.child,
      ),
    );
  }
}

/// 向 [MetroPressDetector] 子树暴露按压状态的 InheritedWidget。
///
/// 子组件可通过 [maybeOf] 感知手指是否停留在组件范围内，
/// 从而实现按压高亮联动（如 [MetroCircleButton] 的 iconMode）。
class MetroPressScope extends InheritedWidget {
  const MetroPressScope({
    super.key,
    required this.isPressed,
    required super.child,
  });

  /// 手指当前是否停留在组件范围内。
  final bool isPressed;

  /// 获取最近的按压状态；不在任何 [MetroPressDetector] 内时返回 null。
  static bool? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MetroPressScope>()
        ?.isPressed;
  }

  @override
  bool updateShouldNotify(MetroPressScope oldWidget) =>
      oldWidget.isPressed != isPressed;
}
