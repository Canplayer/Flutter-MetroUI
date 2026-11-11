import 'package:flutter/material.dart';
import 'package:metro_ui/animations.dart';

/// 页面切换回调：返回 (旧页面索引, 新页面索引)。
///
/// 在**松手决定换页的那一刻**立即回调（此时归位动画刚开始播放），
/// 用于通知外部"发生了换页"。
typedef OnPageChanged = void Function(int oldIndex, int newIndex);

/// 换页动画结束回调：返回 (旧页面索引, 新页面索引)。
///
/// 在页面归位到新位置后回调。
typedef OnTransitionEnd = void Function(int oldIndex, int newIndex);

/// 滑动进度回调：返回 -1.0 ~ 1.0。
///
/// - 拖动过程中：位移 / [PivotPaneView.maxDragDistance]（默认一页宽）；
/// - 归位 / 换页动画过程中：从当前位置平滑到终点；
/// - 动画结束后：回调 0.0。
typedef OnSlideProgress = void Function(double progress);

/// 页面构建器。
typedef PageItemBuilder = Widget Function(BuildContext context, int index);

/// [PivotPaneView] 的默认初始页码。
const int kPivotPaneViewInitialPage = 0;

/// `Pivot.uix!StaticResources::PanPercentThreshold` = **0.33** [读出]。
///
/// 松手判定不看绝对像素，而看「已划过一页的比例」是否超过 33%。
const double kPivotPaneViewPanPercentThreshold = 0.33;

/// `Animations.uix!Pivot::PivotMove`：**500 ms**、`Log(150)` [读出]。
///
/// 系统用一个 500 ms 的 `PivotMove` 把标题条从拖动位置送回目标位置；
/// 页面与标题条同步，所以页面归位也用同样的时长与曲线。
const Duration kPivotPaneViewMoveDuration = Duration(milliseconds: 500);

/// `PivotMove` 的插值曲线 `Log(150)` [读出]。
const Curve kPivotPaneViewMoveCurve = MetroCurves.metroTranslateIn;

/// `Animations.uix!SlideFull*FadeOut`：**300 ms**、`Log(150)` [读出]。
const Duration kPivotPaneViewHideDuration = Duration(milliseconds: 300);

/// `Animations.uix!SlideFull*FadeIn`：**500 ms**、`Log(150)` [读出]。
const Duration kPivotPaneViewShowDuration = Duration(milliseconds: 500);

/// `Animations.uix!FadeOut`：250 ms `Log(150)` 1→0 [读出]。
const Duration kPivotPaneViewFadeOutDuration = Duration(milliseconds: 250);

/// `Animations.uix!FadeIn`：350 ms `Log(150)` 0→1 [读出]。
const Duration kPivotPaneViewFadeInDuration = Duration(milliseconds: 350);

/// 判定为「快滑（flick）」的速度阈值，单位 逻辑像素/秒。
///
/// 系统 `Pivot` 用的是 `Flicker` 手势：`Flicker.Invoked` 一触发就
/// **不看位移**，直接按 `Velocity.X` 的符号决定方向
/// （`PIVOT 0x2f9–0x327`：`Velocity.X > 0` → 上一页，否则下一页）。
/// 但 `Flicker` 内部的速度阈值在原生手势识别器里（`uixrender` 的
/// `SpGestureRecognizerGetFlickInfo` 只转发），本镜像没有读出具体数值。
///
/// 0.5 px/ms（= 500 px/s）是 WP 触摸栈常用的快滑起点，属**近似值**，
/// 可用 [PivotPaneView.flickVelocity] 覆盖。
const double kPivotPaneViewFlickVelocity = 500.0;

/// 编程式控制 [PivotPaneView] 换页的控制器。
///
/// 创建后传入 [PivotPaneView.controller] 即可使用。
/// 触发时机与 [PivotPaneView.onPageChanged] 一致：
/// 调用 [switchTo] / [previous] / [next] 时立即回调。
class PivotController {
  _PivotPaneViewState? _state;

  void _attach(_PivotPaneViewState state) => _state = state;
  void _detach() => _state = null;

  /// 播放换页动画切换到 [index] 页（方向由相对位置自动决定；
  /// 若 [index] 为当前页或换页动画播放中则忽略）。
  void switchTo(int index) => _state?._switchTo(index);

  /// 切到上一页。
  void previous() => _state?._switchTo(_state!._currentIndex - 1);

  /// 切到下一页。
  void next() => _state?._switchTo(_state!._currentIndex + 1);
}

/// Windows Phone 8 Pivot 的滑动翻页部分（`Pivot.uix`）。
///
/// `DefaultPivotPaneHost` attaches hide, calls ForceContentChange, then loads
/// the replacement without awaiting the hide duration. Content-change tracks
/// overlap. Flutter retains the outgoing subtree until its track finishes.
/// This does not reproduce the native renderer's content snapshot mechanism.
///
/// 换页用的两条动画在 `PivotAnimations`（`ANIMATIONS 0x2404–0x245e`）里按
/// `PivotNavigationDirection` 二选一：
///
/// | | 方向 | 动画 | X 位移 | 时长 | 曲线 |
/// |---|---|---|---|---|---|
/// | 隐藏 | — | `SlideFullLeftFadeOut` | 0 → −1 屏 | **300 ms** | Log(150) |
/// | 隐藏 | — | `SlideFullRightFadeOut` | 0 → +1 屏 | **300 ms** | Log(150) |
/// | 显示 | — | `SlideFullLeftFadeIn` | +1 屏 → 0 | **500 ms** | Log(150) |
/// | 显示 | — | `SlideFullRightFadeIn` | −1 屏 → 0 | **500 ms** | Log(150) |
///
/// 各自还叠了一条透明度动画：`FadeOut` = 250 ms `Log(150)` 1→0，
/// `FadeIn` = 350 ms `Log(150)` 0→1。
///
/// ## 拖动：内容跟随手指 1:1 [读出]
///
/// `PIVOT 0x424–0x498` 在 `PivotData.Dragging` 变化时给 `PivotPane` 播放
/// `PaneAnimation`，其 `TimeSource = ScrollRootRelativeTo`（由滚动偏移驱动），
/// 关键帧 X：滚动 0 → `+PaneWidth`，滚动 `2*PaneWidth` → `−PaneWidth`。
/// 拖动一屏正好位移一屏，**线性**跟随手指。
///
/// 滚动根 `MinimumSize = (PaneWidth * 3, 1)`（`PIVOT 0x35f–0x377`）只提供
/// 拖动量程：可拖动范围是 ±一屏。
///
/// ## 松手判定 [读出] `PIVOT 0x2f9–0x423`
///
/// 两套判定互斥，**先快滑、后位移**：
///
/// 1. `Flicker.Invoked`（快滑）→ 不看位移，
///    `Velocity.X > 0` 去上一页，否则去下一页；
/// 2. 否则（`!Flicked`）用滚动位置算归一化中心
///    `delta = (ViewNear + ViewFar) / 2 - 0.5`，
///    阈值 `threshold = PanPercentThreshold / 3`，
///    `delta > threshold` → 上一页，`delta < -threshold` → 下一页，
///    其余归位。
///
/// 除以 3 是把「三屏宽量程」的归一化坐标折回「一屏」，
/// 等价于 **划过一屏的 33%** 就换页。
///
/// ## 回弹
///
/// 未换页时 `ScrollModel.ScrollToPosition(0.5)` 回到中间，用 `PivotMove`
/// ——**500 ms、Log(150)**（`ANIMATIONS 0x151–0x191`）。
/// Content-change and sequential timing modes; native scheduling remains under investigation.
enum PivotTransition { contentChange, sequential }

class PivotPaneView extends StatefulWidget {
  const PivotPaneView({
    super.key,
    required this.itemBuilder,
    this.onPageChanged,
    this.onTransitionEnd,
    this.onSlideProgress,
    this.controller,
    this.clipBehavior = Clip.hardEdge,
    this.transition = PivotTransition.contentChange,
    this.initialPage = kPivotPaneViewInitialPage,
    this.swipeThreshold,
    this.maxDragDistance,
    this.flickVelocity = kPivotPaneViewFlickVelocity,
    this.flyDuration = kPivotPaneViewMoveDuration,
    this.snapBackDuration = kPivotPaneViewMoveDuration,
    this.hideDuration = kPivotPaneViewHideDuration,
    this.showDuration = kPivotPaneViewShowDuration,
    this.fadeDuration = Duration.zero,
    this.flyDistance = 0,
  });

  /// 页面构建器。index 可以是任意整数，超出当前页范围时同样会被调用，
  /// 由使用者决定如何呈现（实现无限滚动）。
  final PageItemBuilder itemBuilder;
  final Clip clipBehavior;

  final PivotTransition transition;

  /// 翻页回调：松手决定换页的瞬间回调 (旧页索引, 新页索引)，见 [OnPageChanged]。
  final OnPageChanged? onPageChanged;

  /// 换页动画结束回调，见 [OnTransitionEnd]。
  final OnTransitionEnd? onTransitionEnd;

  /// 滑动进度回调：-1.0 ~ 1.0，见 [OnSlideProgress]。
  final OnSlideProgress? onSlideProgress;

  /// 编程式换页控制器（可选），见 [PivotController]。
  final PivotController? controller;

  /// 初始页码（可为负数）。
  final int initialPage;

  /// 松手换页的位移阈值，单位逻辑像素。
  ///
  /// 为 null（默认）时按系统的 `PanPercentThreshold` 计算：
  /// **33% × 一页宽**（[kPivotPaneViewPanPercentThreshold]）。
  final double? swipeThreshold;

  /// 归一化进度的分母，单位逻辑像素。
  ///
  /// 为 null（默认）时等于一页宽——系统的滚动坐标本来就以页为单位，
  /// 拖动范围也是 ±一页。
  final double? maxDragDistance;

  /// 快滑判定速度阈值（逻辑像素/秒），见 [kPivotPaneViewFlickVelocity]。
  final double flickVelocity;

  /// 换页归位动画时长（默认 500 ms，见 [kPivotPaneViewMoveDuration]）。
  final Duration flyDuration;

  /// 归位动画时长（默认 500 ms，未换页时的 `PivotMove`）。
  final Duration snapBackDuration;

  /// 旧内容飞出时长（默认 300 ms，`SlideFull*FadeOut`）。
  final Duration hideDuration;

  /// 新内容飞入时长（默认 500 ms，`SlideFull*FadeIn`）。
  final Duration showDuration;

  /// 已不参与渲染。淡出淡入由 `SlideFull*Fade*` 自带的
  /// `FadeOut`/`FadeIn`（250/350 ms）决定，见 [kPivotPaneViewFadeOutDuration]。
  final Duration fadeDuration;

  /// 已不参与渲染。系统的飞出距离固定为**一屏**（`Magnitude = 1.0`）。
  final double flyDistance;

  @override
  State<PivotPaneView> createState() => _PivotPaneViewState();
}

class _PivotPaneViewState extends State<PivotPaneView>
    with TickerProviderStateMixin {
  late int _currentIndex;

  /// 当前内容的横向位移，单位逻辑像素，范围 [-pane, +pane]。
  double _offset = 0.0;
  Widget? _outgoing;
  double _outgoingStart = 0;
  int _direction = 1;
  bool _concurrent = false;

  /// 最近一次布局得到的一屏宽（= 视口宽）。
  double _paneWidth = 0.0;

  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: widget.snapBackDuration,
  );

  double _from = 0;
  double _to = 0;

  bool _hiding = false;
  bool _showing = false;

  /// 正在换到的页码；null 表示只是回弹。
  int? _pendingIndex;

  /// 换页起始页码（内容换掉后 `_currentIndex` 已是新页，回调仍要报旧页）。
  int? _fromIndex;

  bool get _moving => _move.isAnimating;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPage;
    widget.controller?._attach(this);
    _move.addListener(_onMoveFrame);
    _move.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onMoveCompleted();
    });
  }

  @override
  void didUpdateWidget(PivotPaneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _move.dispose();
    super.dispose();
  }

  double get _progressDenominator =>
      widget.maxDragDistance ?? (_paneWidth > 0 ? _paneWidth : 1.0);

  double get _threshold =>
      widget.swipeThreshold ?? kPivotPaneViewPanPercentThreshold * _paneWidth;

  void _notifyProgress(double progress) {
    widget.onSlideProgress?.call(progress.clamp(-1.0, 1.0));
  }

  // ── 手势 ────────────────────────────────────────────────────────────────

  void _handleDragUpdate(DragUpdateDetails details) {
    // 隐藏/显示阶段不接受新手势。
    if (_moving && _pendingIndex != null) return;

    if (_moving) {
      _move.stop();
      _pendingIndex = null;
    }

    final pane = _paneWidth;
    setState(() {
      _offset = (_offset + (details.primaryDelta ?? 0)).clamp(-pane, pane);
    });
    _notifyProgress(_offset / _progressDenominator);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_moving && _pendingIndex != null) return;

    final pane = _paneWidth;
    if (pane <= 0) return;

    final velocity = details.primaryVelocity ?? 0;

    // 1) 快滑：只看方向，不看位移（PIVOT 0x2f9–0x327）。
    if (velocity.abs() >= widget.flickVelocity) {
      _startNavigation(velocity > 0 ? -1 : 1);
      return;
    }

    // 2) 位移阈值：划过一屏的 33%（PIVOT 0x3aa–0x413）。
    if (_offset.abs() >= _threshold) {
      _startNavigation(_offset > 0 ? -1 : 1);
      return;
    }

    _startSnapBack();
  }

  void _handleDragCancel() {
    if (_moving && _pendingIndex != null) return;
    _startSnapBack();
  }

  // ── 回弹 / 换页 ─────────────────────────────────────────────────────────

  void _startSnapBack() {
    if (_offset == 0) {
      _notifyProgress(0);
      return;
    }
    _pendingIndex = null;
    _hiding = false;
    _showing = false;
    _beginMove(0.0, widget.snapBackDuration);
  }

  /// [direction]：+1 去下一页（内容左移），-1 去上一页（内容右移）。
  void _startNavigation(int direction) {
    final target = _currentIndex + direction;
    _pendingIndex = target;
    _fromIndex = _currentIndex;
    widget.onPageChanged?.call(_currentIndex, target);
    _direction = direction;
    _concurrent = widget.transition == PivotTransition.contentChange;
    if (_concurrent) {
      _outgoing = KeyedSubtree(
        key: ValueKey(_currentIndex),
        child: widget.itemBuilder(context, _currentIndex),
      );
      _outgoingStart = _offset;
      setState(() {
        _currentIndex = target;
        _offset = direction > 0 ? _paneWidth : -_paneWidth;
        _hiding = false;
        _showing = true;
      });
      _beginMove(
        0,
        widget.showDuration > widget.hideDuration
            ? widget.showDuration
            : widget.hideDuration,
      );
    } else {
      _hiding = true;
      _showing = false;
      _beginMove(direction > 0 ? -_paneWidth : _paneWidth, widget.hideDuration);
    }
  }

  /// 编程式换页。系统 Pivot 只支持相邻翻页，跨页直接落位。
  void _switchTo(int target) {
    if (_moving) return;
    if (target == _currentIndex) return;
    final direction = target < _currentIndex ? -1 : 1;
    if (target != _currentIndex + direction) {
      final oldIndex = _currentIndex;
      setState(() {
        _currentIndex = target;
        _offset = 0;
      });
      widget.onPageChanged?.call(oldIndex, target);
      widget.onTransitionEnd?.call(oldIndex, target);
      return;
    }
    _startNavigation(direction);
  }

  void _beginMove(double to, Duration duration) {
    _move.stop();
    _move.duration = duration;
    _from = _offset;
    _to = to;
    _move.forward(from: 0);
  }

  void _onMoveFrame() {
    final elapsed = _move.value * _move.duration!.inMicroseconds;
    final progress = _concurrent && _showing
        ? (elapsed /
                  (widget.showDuration.inMicroseconds == 0
                      ? 1
                      : widget.showDuration.inMicroseconds))
              .clamp(0.0, 1.0)
        : _move.value;
    final t = kPivotPaneViewMoveCurve.transform(progress);
    setState(() {
      _offset = _from + (_to - _from) * t;
    });
    _notifyProgress(_offset / _progressDenominator);
  }

  void _onMoveCompleted() {
    final target = _pendingIndex;
    if (target == null) {
      // 回弹：终点就是 0。
      setState(() {
        _offset = 0;
        _hiding = false;
        _showing = false;
      });
      _notifyProgress(0);
      return;
    }

    if (_hiding) {
      // 隐藏播完 → 换内容 → 播显示（DefaultPivotPaneHost 的顺序）。
      final pane = _paneWidth;
      final direction = target > _currentIndex ? 1 : -1;
      setState(() {
        _currentIndex = target;
        // 新内容从反方向一屏处出发。
        _offset = direction > 0 ? pane : -pane;
        _hiding = false;
        _showing = true;
      });
      _from = _offset;
      _to = 0;
      _move.duration = widget.showDuration;
      _move.forward(from: 0);
      return;
    }

    final oldIndex = _fromIndex ?? _currentIndex;
    setState(() {
      _offset = 0;
      _pendingIndex = null;
      _fromIndex = null;
      _showing = false;
      _outgoing = null;
      _concurrent = false;
    });
    _from = 0;
    _to = 0;
    _move.reset();
    _notifyProgress(0);
    widget.onTransitionEnd?.call(oldIndex, target);
  }

  /// 当前帧的透明度，来源 `SlideFull*Fade*` 叠加的 `FadeOut` / `FadeIn`。
  double get _opacity {
    if (_hiding) {
      final span = _move.duration!.inMicroseconds == 0
          ? 1.0
          : kPivotPaneViewFadeOutDuration.inMicroseconds /
                _move.duration!.inMicroseconds;
      final t = (span <= 0 ? 1.0 : (_move.value / span)).clamp(0.0, 1.0);
      return 1.0 - kPivotPaneViewMoveCurve.transform(t).clamp(0.0, 1.0);
    }
    if (_showing) {
      final span = _move.duration!.inMicroseconds == 0
          ? 1.0
          : kPivotPaneViewFadeInDuration.inMicroseconds /
                _move.duration!.inMicroseconds;
      final t = (span <= 0 ? 1.0 : (_move.value / span)).clamp(0.0, 1.0);
      return kPivotPaneViewMoveCurve.transform(t).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  // ── 渲染 ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      onHorizontalDragCancel: _handleDragCancel,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pane = constraints.maxWidth;
          if (pane != _paneWidth) _paneWidth = pane;
          // 系统任一时刻只有一份内容；飞出屏幕的部分要被裁掉。
          final elapsed = _move.value * (_move.duration?.inMicroseconds ?? 0);
          final hideT =
              (elapsed /
                      (widget.hideDuration.inMicroseconds == 0
                          ? 1
                          : widget.hideDuration.inMicroseconds))
                  .clamp(0.0, 1.0);
          final fadeT = (elapsed / kPivotPaneViewFadeOutDuration.inMicroseconds)
              .clamp(0.0, 1.0);
          return ClipRect(
            clipBehavior: widget.clipBehavior,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                if (_outgoing != null && hideT < 1)
                  IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(
                        _outgoingStart +
                            (-_direction * pane - _outgoingStart) *
                                kPivotPaneViewMoveCurve.transform(hideT),
                        0,
                      ),
                      child: Opacity(
                        opacity: 1 - kPivotPaneViewMoveCurve.transform(fadeT),
                        child: _outgoing,
                      ),
                    ),
                  ),
                Transform.translate(
                  offset: Offset(_offset, 0),
                  child: Opacity(
                    opacity: _opacity,
                    child: KeyedSubtree(
                      key: ValueKey(_currentIndex),
                      child: widget.itemBuilder(context, _currentIndex),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
