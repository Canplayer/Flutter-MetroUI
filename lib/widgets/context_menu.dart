import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:metro_ui/metro_theme_extensions.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/tile.dart';

/// 一种长按调出的 Metro 风格上下文菜单。
/// 
/// 长按时，包裹的 [child] 保持原位，背景（通常是 [MetroPageScaffold]）拉远缩小。
/// 然后在 [child] 周围形成一条展开水平线，最后展开 [menu] 菜单，体验非常丝滑且有空间感。
class MetroContextMenu extends StatefulWidget {
  const MetroContextMenu({
    super.key,
    required this.child,
    required this.menu,
    this.pushBackDuration,
    this.pushBackCurve = Curves.linear,
    this.restoreDuration,
    this.restoreCurve = Curves.easeOutCubic,
  });

  /// 被包裹触发的组件
  final Widget child;

  /// 要展示的展开菜单
  final Widget menu;

  /// 背景 Z 轴向后推的动画时长
  final Duration? pushBackDuration;

  /// 背景向后推的动画曲线
  final Curve pushBackCurve;

  /// 背景 Z 轴恢复的动画时长
  final Duration? restoreDuration;

  /// 背景 Z 轴的恢复动画曲线
  final Curve restoreCurve;

  @override
  State<MetroContextMenu> createState() => _MetroContextMenuState();
}

class _MetroContextMenuState extends State<MetroContextMenu> {
  // 使用 GlobalKey，让 child 可以在当前 Widget 树和 Overlay 树之间完美转移而不丢失 State
  final GlobalKey _contentKey = GlobalKey();
  final GlobalKey<_ContextMenuOverlayState> _overlayKey = GlobalKey<_ContextMenuOverlayState>();
  
  bool _isOpen = false;
  bool _isDismissing = false;
  Size? _savedSize;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (_isOpen || _isDismissing) return;

    // 1. 通知 MetroPageScaffold 背景向后移动拉远
    final themeData = Theme.of(context).extension<MetroContextMenuThemeData>();
    final scaffoldState = MetroPageScaffold.maybeOf(context);
    if (scaffoldState != null) {
      scaffoldState.pushBackBackground(
        duration: widget.pushBackDuration ?? themeData?.pushBackDuration ?? const Duration(milliseconds: 500),
        curve: widget.pushBackCurve,
      );
    }

    // 2. 获取当前被按小部件相对于 Overlay 的真实坐标和尺寸 (解决 DPI 缩放带来的坐标漂移)
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    _savedSize = renderBox.size;

    final OverlayState overlayState = Overlay.of(context);
    final RenderBox overlayRenderBox = overlayState.context.findRenderObject() as RenderBox;

    final Offset localOffset = renderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
    final Rect targetRect = localOffset & _savedSize!;

    // 同样转化触摸点，保障点位对应 Overlay
    final Offset localTouchOffset = overlayRenderBox.globalToLocal(details.globalPosition);

    // 3. 捕获当前的上下文继承环境，防止转移到 Overlay 后丢失样式出现黄线
    final ThemeData theme = Theme.of(context);
    final TextStyle defaultTextStyle = DefaultTextStyle.of(context).style;
    final TextDirection directionality = Directionality.of(context);

    // 4. 在 Overlay 中放置内容
    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Theme(
          data: theme,
          child: Directionality(
            textDirection: directionality,
            child: DefaultTextStyle(
              style: defaultTextStyle,
              child: Material(
                type: MaterialType.transparency, // 消灭黄线双下划线
                child: _ContextMenuOverlay(
                  key: _overlayKey,
                  targetRect: targetRect,
                  touchOffset: localTouchOffset,
                  overlaySize: overlayRenderBox.size,
                  menu: Container(
                    color: Theme.of(context).extension<MetroContextMenuThemeData>()?.backgroundColor ?? Theme.of(context).colorScheme.surface,
                    child: widget.menu,
                  ),
                  themeData: themeData,
                  childClone: SizedBox(
                    width: _savedSize!.width,
                    height: _savedSize!.height,
                    // 原封不动地挂载原组件！
                    child: KeyedSubtree(
                      key: _contentKey,
                      child: widget.child,
                    ),
                  ),
                  onDismiss: _dismissMenu,
                ),
              ),
            ),
          ),
        );
      },
    );

    // 原位替换成空白占位，使得原组件从屏幕“消失”（因为它去 Overlay 里了）
    setState(() {
      _isOpen = true; 
    });

    overlayState.insert(_overlayEntry!);
  }

  void _dismissMenu() async {
    if (_isDismissing) return;
    
    // 进入隐藏菜单动画并等待背景回归
    setState(() {
      _isDismissing = true;
    });
    // 强制立即隐藏 Overlay 中的菜单，使它瞬间消失
    _overlayKey.currentState?.hideMenu();

    final themeData = Theme.of(context).extension<MetroContextMenuThemeData>();
    final scaffoldState = MetroPageScaffold.maybeOf(context);
    scaffoldState?.restoreBackground(
      duration: widget.restoreDuration ?? themeData?.restoreDuration ?? const Duration(milliseconds: 350),
      curve: widget.restoreCurve,
    );

    // 等待背景动画执行完毕后再销毁 Overlay 并放回原 Widget
    await Future.delayed(widget.restoreDuration ?? themeData?.restoreDuration ?? const Duration(milliseconds: 350));
    
    if (!mounted) return;

    _overlayEntry?.remove();
    _overlayEntry = null;

    setState(() {
      _isOpen = false; 
      _isDismissing = false; 
    });
  }

  @override
  Widget build(BuildContext context) {
    // 菜单打开时由于元件被送走了，用原来相同大小的位置撑场面，避免排版塌陷失效
    if (_isOpen && _savedSize != null) {
      return SizedBox(
        width: _savedSize!.width,
        height: _savedSize!.height,
      );
    }

    return GestureDetector(
      onLongPressStart: _handleLongPressStart,
      behavior: HitTestBehavior.opaque,
      child: KeyedSubtree(
        key: _contentKey,
        child: widget.child, 
      ),
    );
  }
}

class _ContextMenuOverlay extends StatefulWidget {
  const _ContextMenuOverlay({
    super.key,
    required this.targetRect,
    required this.touchOffset,
    required this.overlaySize,
    required this.menu,
    required this.childClone,
    required this.onDismiss,
    this.themeData,
  });

  final Rect targetRect;
  final Offset touchOffset;
  final Size overlaySize;
  final Widget menu;
  final Widget childClone;
  final VoidCallback onDismiss;
  final MetroContextMenuThemeData? themeData;

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lineAnimation;
  late Animation<double> _menuAnimation;
  
  bool _isHidden = false;

  void hideMenu() {
    if (!mounted) return;
    setState(() {
      _isHidden = true;
    });
  }

  @override
  void initState() {
    super.initState();
    final int lineMs = widget.themeData?.lineAnimationDuration?.inMilliseconds ?? 500;
    final int menuMs = widget.themeData?.menuAnimationDuration?.inMilliseconds ?? 400;
    final int totalMs = lineMs + menuMs;

    _controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: totalMs));

    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, lineMs / totalMs, curve: Curves.linear),
      ),
    );

    _menuAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(lineMs / totalMs, 1.0, curve: Curves.linear),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 简单预估菜单高度占用
    const double estimatedMenuHeight = 200.0;
    // 使用传入的准确 overlay 范围判定边界以解决 DPI 冲突问题
    final bool isUpward =
        widget.targetRect.bottom + estimatedMenuHeight > widget.overlaySize.height;

    // 线条高度位置
    final double lineTop =
        isUpward ? widget.targetRect.top - 1.0 : widget.targetRect.bottom;

    return Stack(
      children: [
        // 背景点击区域（透明用于消失事件）
        Positioned.fill(
          child: GestureDetector(
            onTap: _isHidden ? null : widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),

        // 直接承载原位 Widget 的移花接木版本，它在隐藏动画中会被单独保留悬浮
        Positioned(
          left: widget.targetRect.left,
          top: widget.targetRect.top,
          child: IgnorePointer(
            child: widget.childClone,
          ),
        ),

        // 如果正处于消散状态，瞬间隐藏横线和菜单（符合预期的瞬间消失）
        if (!_isHidden) ...[
          // 横线动画 500ms
          AnimatedBuilder(
            animation: _lineAnimation,
            builder: (context, child) {
              // 利用 lerpDouble，左右两端会同时向两边延伸到底
              final double left =
                  lerpDouble(widget.touchOffset.dx, 0.0, _lineAnimation.value)!;
              final double right = lerpDouble(
                  widget.overlaySize.width - widget.touchOffset.dx,
                  0.0,
                  _lineAnimation.value)!;

              if (_lineAnimation.value == 0) return const SizedBox.shrink();

              return Positioned(
                left: left,
                right: right,
                top: lineTop,
                height: 1.0,
                child: Container(
                  color: widget.themeData?.lineColor ?? Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),

          // 菜单动画 400ms 垂直展开（压扁后伸展动画）
          Positioned(
            left: 0,
            right: 0,
            top: isUpward ? null : lineTop + 1.0,
            bottom: isUpward ? (widget.overlaySize.height - lineTop) : null,
            child: AnimatedBuilder(
              animation: _menuAnimation,
              builder: (context, child) {
                if (_menuAnimation.value == 0) return const SizedBox.shrink();
                return Transform(
                  alignment: isUpward ? Alignment.bottomCenter : Alignment.topCenter,
                  transform: Matrix4.diagonal3Values(1.0, _menuAnimation.value, 1.0),
                  child: child,
                );
              },
              child: widget.menu,
            ),
          ),
        ]
      ],
    );
  }
}

/// 上下文菜单子项，专为 Metro 设计。
///
/// 常作为 [MetroContextMenu.menu] 的子元素（放入 Column 中等）出现。
class MetroContextMenuItem extends StatefulWidget {
  const MetroContextMenuItem({
    super.key,
    required this.child,
    this.onTap,
    this.height,
    this.textStyle,
    this.pressedBackgroundColor,
  });

  /// 菜单项的主体内容
  final Widget child;

  /// 点击回调
  final VoidCallback? onTap;

  /// 菜单项高度，若为空，尝试从主题获取 `itemHeight`，回退为 56.0
  final double? height;

  /// 菜单项文字样式，若为空，尝试从主题获取 `itemTextStyle`
  final TextStyle? textStyle;

  /// 菜单项按下时的背景颜色，若为空，使用默认的主题强调色
  final Color? pressedBackgroundColor;

  @override
  State<MetroContextMenuItem> createState() => _MetroContextMenuItemState();
}

class _MetroContextMenuItemState extends State<MetroContextMenuItem> {

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context).extension<MetroContextMenuThemeData>();
    final defaultItemHeight = widget.height ?? themeData?.itemHeight ?? 56.0;
    final defaultTextStyle = widget.textStyle ?? themeData?.itemTextStyle ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.w400);

    return Tile(
      onTap: widget.onTap,
      child: Container(
        height: defaultItemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.centerLeft,
        child: DefaultTextStyle(
          style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).merge(defaultTextStyle).copyWith(
            color: defaultTextStyle.color,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

