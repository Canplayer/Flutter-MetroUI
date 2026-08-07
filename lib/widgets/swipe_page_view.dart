import 'package:flutter/material.dart';

/// 页面切换回调：返回 (旧页面索引, 新页面索引)。
///
/// 在**松手触发换页的那一刻**立即回调（此时换页动画刚开始播放），
/// 用于通知外部"发生了换页"。
typedef OnPageChanged = void Function(int oldIndex, int newIndex);

/// 换页动画结束回调：返回 (旧页面索引, 新页面索引)。
///
/// 在换页动画播放完毕后回调，用于通知外部"换页动画已结束"。
typedef OnTransitionEnd = void Function(int oldIndex, int newIndex);

/// 滑动进度回调：返回 -1.0 ~ 1.0。
///
/// - 拖动过程中：位移 / maxDragDistance（位移被钳制在 ±maxDragDistance）；
/// - 换页 / 归位动画过程中：从当前值平滑归零；
/// - 动画结束后：回调 0.0。
typedef OnSlideProgress = void Function(double progress);

/// 页面构建器。
typedef PageItemBuilder = Widget Function(BuildContext context, int index);

/// [SwipePageView] 的默认初始页码。
const int kSwipePageViewInitialPage = 0;

/// [SwipePageView] 的默认松手换页阈值（像素）。
const double kSwipePageViewSwipeThreshold = 90.0 / 0.8;

/// [SwipePageView] 的默认最大拖动位移（像素）。
const double kSwipePageViewMaxDragDistance = 320.0 / 0.8;

/// [SwipePageView] 的默认飞出/飞入位移（像素）。
const double kSwipePageViewFlyDistance = 320.0;

/// [SwipePageView] 的默认飞出/飞入动画时长。
const Duration kSwipePageViewFlyDuration = Duration(milliseconds: 300);

/// [SwipePageView] 的默认渐隐/渐显动画时长。
const Duration kSwipePageViewFadeDuration = Duration(milliseconds: 100);

/// [SwipePageView] 的默认归位动画时长。
const Duration kSwipePageViewSnapBackDuration = Duration(milliseconds: 200);

/// 编程式控制 [SwipePageView] 换页的控制器。
///
/// 创建后传入 [SwipePageView.controller] 即可使用。
/// 触发时机与 [SwipePageView.onPageChanged] 一致：
/// 调用 [switchTo] / [previous] / [next] 时立即回调。
class SwipePageController {
  _SwipePageViewState? _state;

  void _attach(_SwipePageViewState state) => _state = state;
  void _detach() => _state = null;

  /// 播放换页动画切换到 [index] 页（方向由相对位置自动决定；
  /// 若 [index] 为当前页或换页动画播放中则忽略）。
  void switchTo(int index) => _state?._switchTo(index);

  /// 切到上一页。
  void previous() => _state?._switchTo(_state!._currentIndex - 1);

  /// 切到下一页。
  void next() => _state?._switchTo(_state!._currentIndex + 1);
}

/// 简化版左右滑动翻页组件（不依赖标准 PageView，无惯性设计）。
///
/// ## 交互规则
/// - 屏幕上始终只显示当前页 A，手指拖动时 A 跟随手指水平移动；
/// - 拖动位移被限制在 `[-maxDragDistance, maxDragDistance]` 内（默认 320px），
///   超过该数值后页面不再移动（多手指接力、迟迟不松手也不会触发换页）；
/// - 多手指由 GestureDetector 的拖拽识别器原生接力处理：只要还有手指按住
///   屏幕，拖动就持续进行、不会触发换页；全部手指松开后才判定：
///   - 位移绝对值 < [swipeThreshold]（默认 50px）：归位回原位；
///   - 位移绝对值 >= [swipeThreshold]：播放换页动画。
///
/// ## 换页动画（播放速度与手指滑动速度无关）
/// 单个 [AnimationController] 驱动四个 [Interval] 子动画，A、B 两页同步运动：
/// 1. 页面 A 沿滑动方向飞出 [flyDistance]（默认 320px），时长 [flyDuration]，
///    使用从快到慢的 [Curves.easeOutCubic] 曲线（起始速度有限、尾部减速
///    肉眼可见；不要用 [Curves.decelerate]，其起始速度无穷大，动画会在
///    前几毫秒内瞬间完成，看起来像"瞬移"），同时叠加 [fadeDuration]
///    的渐隐动画（[Curves.easeInCubic] 先慢后快，保证 A 飞出过程清晰可见）；
/// 2. 页面 B 与 A **同时**从滑动方向的反方向 [flyDistance] 处滑入
///    （曲线与时长同 A），并同时叠加 [fadeDuration] 的渐显动画。
///    渐显与滑入必须同时启动：若先渐显、后滑入，B 会静止停在屏幕边缘
///    渐显，产生"先闪一下再飞入"的割裂感。
///
/// ## 其他特性
/// - 支持无限滚动：[itemBuilder] 的 index 可以是任意整数；
/// - 通过 [onPageChanged] 在松手触发换页时监听翻页（动画刚开始即回调）；
///   通过 [onTransitionEnd] 监听换页动画播放完毕；
///   通过 [onSlideProgress] 监听滑动距离。
class SwipePageView extends StatefulWidget {
  const SwipePageView({
    super.key,
    required this.itemBuilder,
    this.onPageChanged,
    this.onTransitionEnd,
    this.onSlideProgress,
    this.controller,
    this.initialPage = kSwipePageViewInitialPage,
    this.swipeThreshold = kSwipePageViewSwipeThreshold,
    this.maxDragDistance = kSwipePageViewMaxDragDistance,
    this.flyDistance = kSwipePageViewFlyDistance,
    this.flyDuration = kSwipePageViewFlyDuration,
    this.fadeDuration = kSwipePageViewFadeDuration,
    this.snapBackDuration = kSwipePageViewSnapBackDuration,
  });

  /// 页面构建器。index 可以是任意整数，超出当前页范围时同样会被调用，
  /// 由使用者决定如何呈现（实现无限滚动）。
  final PageItemBuilder itemBuilder;

  /// 翻页回调：松手触发换页的瞬间回调 (旧页索引, 新页索引)，
  /// 见 [OnPageChanged]。
  final OnPageChanged? onPageChanged;

  /// 换页动画结束回调：动画播放完毕后回调 (旧页索引, 新页索引)，
  /// 见 [OnTransitionEnd]。
  final OnTransitionEnd? onTransitionEnd;

  /// 滑动进度回调：-1.0 ~ 1.0，见 [OnSlideProgress]。
  final OnSlideProgress? onSlideProgress;

  /// 编程式换页控制器（可选），见 [SwipePageController]。
  final SwipePageController? controller;

  /// 初始页码（可为负数）。
  final int initialPage;

  /// 松手触发换页的最小位移（像素），见构造参数默认值。
  final double swipeThreshold;

  /// 拖动过程中页面允许的最大位移（像素）；
  /// 归一化进度 = 位移 / maxDragDistance。
  final double maxDragDistance;

  /// 换页时页面飞出/飞入的位移（像素）。
  final double flyDistance;

  /// 飞出/飞入动画时长。
  final Duration flyDuration;

  /// 渐隐/渐显动画时长。
  final Duration fadeDuration;

  /// 归位动画时长。
  final Duration snapBackDuration;

  @override
  State<SwipePageView> createState() => _SwipePageViewState();
}

class _SwipePageViewState extends State<SwipePageView>
    with TickerProviderStateMixin {
  late int _currentIndex;
  double _dragOffset = 0.0; // 当前拖拽偏移量，限制在 ±maxDragDistance

  // 状态标识
  bool _isTransitioning = false; // 换页动画播放中
  bool _isSnappingBack = false; // 归位动画播放中

  // 动画控制器
  late AnimationController _transitionController;
  late AnimationController _snapController;

  // 换页动画（单控制器 + Interval 分段）
  late Animation<double> _pageASlide; // A 飞出：0~flyDuration easeOutCubic
  late Animation<double> _pageAFade; // A 渐隐：0~fadeDuration easeInCubic
  late Animation<double> _pageBFade; // B 渐显：0~fadeDuration linear
  late Animation<double> _pageBSlide; // B 滑入：0~flyDuration easeOutCubic

  // 换页动画的临时状态
  int _targetIndex = 0;
  double _startDragOffset = 0.0;
  int _slideDirection = 0; // 1: 向右滑(上一页), -1: 向左滑(下一页)

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPage;
    widget.controller?._attach(this);

    // ── 换页过渡动画控制器（总时长 = flyDuration） ──────────────────────────
    _transitionController = AnimationController(
      vsync: this,
      duration: widget.flyDuration,
    );

    // 渐显/渐隐时长占动画总时长的比例（默认 50/100 = 0.5）
    final fadeFraction =
        (widget.fadeDuration.inMilliseconds / widget.flyDuration.inMilliseconds)
            .clamp(0.0, 1.0);

    // A 沿滑动方向飞出：从快到慢（easeOutCubic 起始速度有限，减速肉眼可见）
    _pageASlide = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    );
    // A 渐隐：easeInCubic 先慢后快 → A 飞出过程清晰可见
    _pageAFade = CurvedAnimation(
      parent: _transitionController,
      curve: Interval(0.0, fadeFraction, curve: Curves.easeInCubic),
    );
    // B 渐显：与滑入同时进行，避免"先静止在屏幕边缘闪现、再飞入"
    _pageBFade = CurvedAnimation(
      parent: _transitionController,
      curve: Interval(0.0, fadeFraction, curve: Curves.linear),
    );
    // B 从反方向滑入：从快到慢，曲线与 A 相同
    _pageBSlide = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    );

    _transitionController.addListener(_onTransitionFrame);
    _transitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onTransitionCompleted();
      }
    });

    // ── 归位动画控制器 ──────────────────────────────────────────────────────
    _snapController = AnimationController(
      vsync: this,
      duration: widget.snapBackDuration,
    );

    _snapController.addListener(_onSnapFrame);
    _snapController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSnappingBack = false;
          _dragOffset = 0.0;
        });
        _notifyProgress(0.0);
      }
    });
  }

  @override
  void didUpdateWidget(SwipePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _transitionController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  /// 通知外部滑动进度 (-1.0 ~ 1.0)。
  void _notifyProgress(double progress) {
    widget.onSlideProgress?.call(progress.clamp(-1.0, 1.0));
  }

  // ── 手势处理 ──────────────────────────────────────────────────────────────

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isTransitioning) return; // 换页动画期间忽略手势

    if (_isSnappingBack) {
      // 归位中再次拖动：从当前位置继续
      _snapController.stop();
      _isSnappingBack = false;
    }

    setState(() {
      _dragOffset = (_dragOffset + (details.primaryDelta ?? 0))
          .clamp(-widget.maxDragDistance, widget.maxDragDistance)
          .toDouble();
    });
    _notifyProgress(_dragOffset / widget.maxDragDistance);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isTransitioning) return;

    if (_dragOffset.abs() < widget.swipeThreshold) {
      _startSnapBack(); // < 50px：归位回原位
    } else {
      _startPageTransition(); // >= 50px：触发换页
    }
  }

  void _handleDragCancel() {
    if (_isTransitioning) return;
    _startSnapBack(); // 手势被系统取消时直接归位
  }

  // ── 归位 ──────────────────────────────────────────────────────────────────

  void _startSnapBack() {
    _isSnappingBack = true;
    _startDragOffset = _dragOffset;
    _snapController.forward(from: 0.0);
  }

  void _onSnapFrame() {
    final t = Curves.easeOut.transform(_snapController.value);
    setState(() {
      _dragOffset = _startDragOffset * (1.0 - t);
    });
    _notifyProgress(_dragOffset / widget.maxDragDistance);
  }

  // ── 换页 ──────────────────────────────────────────────────────────────────

  /// 编程式换页：播放切换到 [target] 页的动画（无拖拽起始偏移，
  /// 由 [SwipePageController] 触发）。
  void _switchTo(int target) {
    if (_isTransitioning) return; // 换页动画播放中忽略
    if (target == _currentIndex) return; // 目标即当前页，无操作

    _isTransitioning = true;
    _startDragOffset = 0;
    // 目标为上一页（target < current）→ 向右飞出；下一页 → 向左
    _slideDirection = target < _currentIndex ? 1 : -1;
    _targetIndex = target;

    // 触发换页 → 立即回调（动画刚开始播放）
    widget.onPageChanged?.call(_currentIndex, _targetIndex);

    _transitionController.forward(from: 0.0);
  }

  void _startPageTransition() {
    _isTransitioning = true;
    _startDragOffset = _dragOffset;

    // 向右滑 (_dragOffset > 0)：目标页是上一页；向左滑：下一页
    _slideDirection = _dragOffset > 0 ? 1 : -1;
    _targetIndex = _slideDirection > 0 ? _currentIndex - 1 : _currentIndex + 1;

    // 松手触发换页 → 立即回调（动画刚开始播放）
    widget.onPageChanged?.call(_currentIndex, _targetIndex);

    _transitionController.forward(from: 0.0);
  }

  void _onTransitionFrame() {
    // 进度从当前拖拽值平滑归零
    _notifyProgress(
      _startDragOffset * (1.0 - _transitionController.value) /
          widget.maxDragDistance,
    );
    setState(() {});
  }

  void _onTransitionCompleted() {
    final oldIndex = _currentIndex;
    final newIndex = _targetIndex;

    setState(() {
      _currentIndex = newIndex;
      _isTransitioning = false;
      _dragOffset = 0.0;
    });

    _transitionController.reset();
    _notifyProgress(0.0);
    // 换页动画播放完毕 → 回调结束事件
    widget.onTransitionEnd?.call(oldIndex, newIndex);
  }

  // ── 渲染 ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      onHorizontalDragCancel: _handleDragCancel,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        // 不裁切：页面滑出容器边缘时完整渲染，不会被切断
        clipBehavior: Clip.none,
        children: [
          if (!_isTransitioning) ...[
            // 静止 / 拖动 / 归位：只渲染当前页 A
            _buildPage(_currentIndex, _dragOffset, 1.0),
          ] else ...[
            // 换页动画：B 在底层，A 在上层飞出
            _buildPageB(),
            _buildPageA(),
          ],
        ],
      ),
    );
  }

  Widget _buildPage(int index, double offset, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: widget.itemBuilder(context, index),
      ),
    );
  }

  /// 构建飞出的页面 A。
  Widget _buildPageA() {
    // 向滑动方向飞出 flyDistance，easeOutCubic 从快到慢
    final offsetX = _startDragOffset +
        _slideDirection * widget.flyDistance * _pageASlide.value;
    // 50ms 渐隐，easeInCubic 先慢后快
    final opacity = (1.0 - _pageAFade.value).clamp(0.0, 1.0);
    return _buildPage(_currentIndex, offsetX, opacity);
  }

  /// 构建飞入的页面 B。
  Widget _buildPageB() {
    // 从滑动方向的反方向 flyDistance 处滑向屏幕中心
    final offsetX =
        -_slideDirection * widget.flyDistance * (1.0 - _pageBSlide.value);
    // 50ms 渐显，与滑入同时进行
    final opacity = _pageBFade.value.clamp(0.0, 1.0);
    return _buildPage(_targetIndex, offsetX, opacity);
  }
}
