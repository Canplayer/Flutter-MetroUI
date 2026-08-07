import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:metro_ui/widgets/swipe_page_view.dart';

/// 标题指示器的对齐方式。
enum SwipeTitleAlign {
  /// 左对齐：当前标题左边缘对齐父容器左侧（默认）。
  start,

  /// 居中：当前标题水平居中于父容器。
  center,

  /// 右对齐：当前标题右边缘对齐父容器右侧。
  end,
}

/// 页面条目：一个标题 + 一个页面内容。
class SwipePageItem {
  const SwipePageItem({required this.title, required this.page});

  /// 标题（任意 Widget，例如 Text）。
  final Widget title;

  /// 页面内容。
  final Widget page;
}

/// [SwipePageIndicator] 的默认标题间距。
const double kSwipePageIndicatorTitleGap = 24.0;

/// [SwipePageIndicator] 的默认标题对齐方式。
const SwipeTitleAlign kSwipePageIndicatorAlign = SwipeTitleAlign.start;

/// [SwipePageIndicator] 独立使用时的默认飞出/飞入动画时长。
/// 注意：被 [SwipePagesBase] 组合时以 [SwipePageView] 的时长为准
/// （[kSwipePageViewFlyDuration]），以保证标题与页面动画同步。
const Duration kSwipePageIndicatorFlyDuration = Duration(milliseconds: 2000);

/// [SwipePageIndicator] 独立使用时的默认渐隐/渐显动画时长。
const Duration kSwipePageIndicatorFadeDuration = Duration(milliseconds: 200);

/// [SwipePages] 整体（标题 + 主体）的默认内边距：水平 18。
const EdgeInsetsGeometry kSwipePagesPadding = EdgeInsets.symmetric(horizontal: 18);

/// 组合组件（标题指示器 + 滑动翻页）的公共基类。
///
/// 持有标题/页面列表与全部动画、布局、回调参数。
/// 子类决定两者的布局方式：
/// - [SwipePages]：Column 上下布局（标题在页面上方）；
/// - [SwipeStackPages]：Stack 叠放布局（标题悬浮在页面顶部）。
///
/// 动画/布局参数均为可空，未指定时透传回落为子组件（[SwipePageView] /
/// [SwipePageIndicator]）各自的默认值常量，修改子组件默认值无需在此重复维护。
abstract class SwipePagesBase extends StatefulWidget {
  const SwipePagesBase({
    super.key,
    required this.items,
    this.initialPage,
    this.swipeThreshold,
    this.maxDragDistance,
    this.flyDistance,
    this.flyDuration,
    this.fadeDuration,
    this.snapBackDuration,
    this.titleGap,
    this.align,
    this.onPageChanged,
    this.onTransitionEnd,
    this.onSlideProgress,
  });

  /// 页面条目列表（标题 + 页面）。
  final List<SwipePageItem> items;

  /// 初始页码（可为负数），透传给 [SwipePageView]。
  final int? initialPage;

  /// 松手触发换页的最小位移（像素），透传给 [SwipePageView]。
  final double? swipeThreshold;

  /// 拖动过程中页面允许的最大位移（像素），透传给 [SwipePageView]。
  final double? maxDragDistance;

  /// 换页时页面飞出/飞入的位移（像素），透传给 [SwipePageView]。
  final double? flyDistance;

  /// 飞出/飞入动画时长，透传给 [SwipePageView] 与标题指示器。
  final Duration? flyDuration;

  /// 渐隐/渐显动画时长，透传给 [SwipePageView] 与标题指示器。
  final Duration? fadeDuration;

  /// 归位动画时长，透传给 [SwipePageView]。
  final Duration? snapBackDuration;

  /// 标题之间的间距，透传给标题指示器。
  final double? titleGap;

  /// 标题对齐方式（左/中/右），透传给标题指示器。
  final SwipeTitleAlign? align;

  /// 翻页回调（松手触发换页的瞬间），透传。
  final OnPageChanged? onPageChanged;

  /// 换页动画结束回调，透传。
  final OnTransitionEnd? onTransitionEnd;

  /// 滑动进度回调（-1.0 ~ 1.0），透传。
  final OnSlideProgress? onSlideProgress;
}

/// 组合组件：标题指示器 + 滑动翻页（Column 上下布局）。
///
/// 顶部是标题指示器，下方是 [SwipePageView]，两者自动同步：
/// - 拖动页面（不松手）时，标题条整体移动「对应方向目标标题的归位距离
///   × progress」，与 [SwipePageView.onSlideProgress] 对齐。
///   例：左对齐下向右滑（去上一页）移动量 = 上一页标题宽度（+间距），
///   向左滑（去下一页）移动量 = 当前标题宽度（+间距）；
/// - 松手触发换页时，下一个标题使用从快到慢的减速动画滑入
///   （[Curves.easeOutCubic]）；
/// - 同时显示三个标题：上一页 / 当前页 / 下一页；
/// - 只有两个页面（A、B，A 为当前）时显示 B A B；
/// - 只有一个页面时只显示一个标题。
///
/// 整个组件（标题 + 主体）默认带水平 18 的内边距（见 [kSwipePagesPadding]），
/// 可通过 [padding] 覆盖。
class SwipePages extends SwipePagesBase {
  const SwipePages({
    super.key,
    required super.items,
    super.initialPage,
    super.swipeThreshold,
    super.maxDragDistance,
    super.flyDistance,
    super.flyDuration,
    super.fadeDuration,
    super.snapBackDuration,
    super.titleGap,
    super.align,
    super.onPageChanged,
    super.onTransitionEnd,
    super.onSlideProgress,
    this.padding = kSwipePagesPadding,
  });

  /// 整体内边距（标题与主体统一内缩），默认水平 18。
  final EdgeInsetsGeometry padding;

  @override
  State<SwipePages> createState() => _SwipePagesState();
}

/// 组合组件：标题指示器 + 滑动翻页（Stack 叠放布局）。
///
/// 页面铺满整个区域，标题指示器以 [Stack] 方式悬浮在页面顶部
/// （[indicatorAlign] 控制顶部位置，[indicatorPadding] 控制边距）。
/// 点击上一页/下一页标题可切换到对应页面；标题之外的空白区域
/// 触摸穿透到页面（不会挡住拖动）。
///
/// 页面与标题的同步行为与 [SwipePages] 完全一致。
class SwipeStackPages extends SwipePagesBase {
  const SwipeStackPages({
    super.key,
    required super.items,
    super.initialPage,
    super.swipeThreshold,
    super.maxDragDistance,
    super.flyDistance,
    super.flyDuration,
    super.fadeDuration,
    super.snapBackDuration,
    super.titleGap,
    super.align,
    super.onPageChanged,
    super.onTransitionEnd,
    super.onSlideProgress,
    this.indicatorAlign = Alignment.topCenter,
    this.indicatorPadding = const EdgeInsets.all(8),
  });

  /// 标题指示器在 Stack 中的对齐位置，默认顶部居中。
  final AlignmentGeometry indicatorAlign;

  /// 标题指示器与容器边缘的间距，默认 8。
  final EdgeInsetsGeometry indicatorPadding;

  @override
  State<SwipeStackPages> createState() => _SwipeStackPagesState();
}

/// 页面与标题同步逻辑（[SwipePages] 与 [SwipeStackPages] 共用）。
///
/// 维护当前页索引、换页目标、滑动进度，并把 [SwipePageView] 的回调
/// 同步给 [SwipePageIndicator]。
mixin _SwipeSyncState<T extends SwipePagesBase> on State<T> {
  late int _currentIndex;
  int? _swapTarget;
  double _progress = 0;
  bool _swapping = false;

  /// 编程式换页控制器：点击标题时驱动 [SwipePageView] 播放换页动画。
  final SwipePageController _viewController = SwipePageController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPage ?? kSwipePageViewInitialPage;
  }

  void _handleSwapEnded() {
    if (!mounted) return;
    final target = _swapTarget;
    if (target == null) return;
    setState(() {
      _currentIndex = target;
      _swapTarget = null;
      _swapping = false;
      _progress = 0;
    });
  }

  /// 标题点击：切换到被点击的相邻页（上一页/下一页标题）。
  void _handleTitleTap(int index) {
    if (_swapping) return; // 换页动画播放中忽略
    if (index == _currentIndex) return; // 点击当前标题无操作
    _viewController.switchTo(index);
  }

  /// 构建标题指示器。
  Widget buildIndicator() {
    return SwipePageIndicator(
      titles: [for (final e in widget.items) e.title],
      currentIndex: _currentIndex,
      progress: _progress,
      swapTargetIndex: _swapTarget,
      titleGap: widget.titleGap ?? kSwipePageIndicatorTitleGap,
      align: widget.align ?? kSwipePageIndicatorAlign,
      flyDuration: widget.flyDuration ?? kSwipePageViewFlyDuration,
      fadeDuration: widget.fadeDuration ?? kSwipePageViewFadeDuration,
      onSwapEnded: _handleSwapEnded,
      onTitleTap: _handleTitleTap,
    );
  }

  /// 构建滑动翻页组件（无限滚动：任意 index 循环映射到有限页面）。
  Widget buildView() {
    final n = widget.items.length;
    return SwipePageView(
      controller: _viewController,
      initialPage: widget.initialPage ?? kSwipePageViewInitialPage,
      swipeThreshold: widget.swipeThreshold ?? kSwipePageViewSwipeThreshold,
      maxDragDistance: widget.maxDragDistance ?? kSwipePageViewMaxDragDistance,
      flyDistance: widget.flyDistance ?? kSwipePageViewFlyDistance,
      flyDuration: widget.flyDuration ?? kSwipePageViewFlyDuration,
      fadeDuration: widget.fadeDuration ?? kSwipePageViewFadeDuration,
      snapBackDuration:
          widget.snapBackDuration ?? kSwipePageViewSnapBackDuration,
      itemBuilder: (context, index) => widget.items[index % n].page,
      onPageChanged: (o, n) {
        setState(() {
          _swapTarget = n;
          _swapping = true;
        });
        widget.onPageChanged?.call(o, n);
      },
      onTransitionEnd: (o, n) {
        setState(() {
          _currentIndex = n;
          _swapTarget = null;
          _swapping = false;
          _progress = 0;
        });
        widget.onTransitionEnd?.call(o, n);
      },
      onSlideProgress: (p) {
        // 换页动画期间标题条由自身动画驱动，不再跟随 progress
        if (!_swapping) setState(() => _progress = p);
        widget.onSlideProgress?.call(p);
      },
    );
  }
}

class _SwipePagesState extends State<SwipePages>
    with _SwipeSyncState<SwipePages> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    // 整体内边距：标题与主体统一内缩
    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildIndicator(),
          Expanded(child: buildView()),
        ],
      ),
    );
  }
}

class _SwipeStackPagesState extends State<SwipeStackPages>
    with _SwipeSyncState<SwipeStackPages> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        // 底层：滑动翻页铺满整个区域
        buildView(),
        // 顶层：标题指示器悬浮在指定位置。标题区域响应点击（切换页面）；
        // 其余空白区域不吸收触摸（Stack 仅命中子组件），可穿透到页面拖动。
        Align(
          alignment: widget.indicatorAlign,
          child: Padding(
            padding: widget.indicatorPadding,
            child: buildIndicator(),
          ),
        ),
      ],
    );
  }
}

/// 标题指示器（可独立使用）。
///
/// 通过 [align] 控制当前标题的对齐方式（默认左对齐）：
/// - [SwipeTitleAlign.start]：当前标题左边缘对齐父容器左侧；
/// - [SwipeTitleAlign.center]：当前标题水平居中；
/// - [SwipeTitleAlign.end]：当前标题右边缘对齐父容器右侧。
///
/// 上一页标题在当前标题一侧、下一页标题在另一侧（非当前标题带 50%
/// 透明滤镜）。标题条整体随 [progress] 平移（移动距离 = 对应方向目标标题的
/// 归位距离 × progress，方向与手指一致；例如左对齐下右拖满时上一页标题
/// 恰好归位）；当 [swapTargetIndex] 非 null 且发生变化时，播放换页动画：
/// 旧标题条从拖动位置继续沿滑动方向推入，直到目标标题对齐到 [align] 指定
/// 的位置（[Curves.easeOutCubic] 减速）；新标题条从反方向同步推入并渐显，
/// 旧条渐隐。
///
/// 若只有两个页面，左右标题相同（A 当前时显示 B A B）；
/// 若只有一个页面，只显示当前标题。
///
/// 若提供 [onTitleTap]，点击上一页/下一页标题可触发回调（通常用于切换页面）。
class SwipePageIndicator extends StatefulWidget {
  const SwipePageIndicator({
    super.key,
    required this.titles,
    required this.currentIndex,
    this.progress = 0,
    this.swapTargetIndex,
    this.titleGap = kSwipePageIndicatorTitleGap,
    this.align = kSwipePageIndicatorAlign,
    this.flyDuration = kSwipePageIndicatorFlyDuration,
    this.fadeDuration = kSwipePageIndicatorFadeDuration,
    this.onSwapEnded,
    this.onTitleTap,
  });

  /// 所有标题（顺序与页面一一对应，可循环）。
  final List<Widget> titles;

  /// 当前页面索引（可为负数，内部循环映射）。
  final int currentIndex;

  /// 滑动进度 -1.0 ~ 1.0（拖动时），标题条跟随移动。
  final double progress;

  /// 换页目标索引：非 null 且发生变化时播放换页动画。
  final int? swapTargetIndex;

  /// 标题之间的间距。
  final double titleGap;

  /// 标题对齐方式（左/中/右），默认 [SwipeTitleAlign.start]。
  final SwipeTitleAlign align;

  /// 换页动画时长。
  final Duration flyDuration;

  /// 渐隐/渐显动画时长。
  final Duration fadeDuration;

  /// 换页动画结束回调。
  final VoidCallback? onSwapEnded;

  /// 标题点击回调：参数为被点击标题的索引（与当前页相邻：
  /// 上一页 = currentIndex-1，下一页 = currentIndex+1，当前 = currentIndex）。
  /// 为 null 时标题不响应点击。
  final ValueChanged<int>? onTitleTap;

  @override
  State<SwipePageIndicator> createState() => _SwipePageIndicatorState();
}

class _SwipePageIndicatorState extends State<SwipePageIndicator>
    with TickerProviderStateMixin {
  /// 已测量的标题宽度（key：标题在列表中的索引）。
  final Map<int, double> _widths = {};

  late final AnimationController _controller;
  late final Animation<double> _slide; // easeOutCubic 从快到慢
  late final Animation<double> _fade; // 渐显/渐隐（线性）

  bool _swapping = false;
  int _oldCurrent = 0;
  int _sign = 1; // +1: 换到上一页（标题条右推），-1: 换到下一页（左推）
  double _startX = 0; // 拖动结束时的标题条位移
  double _gapWidth = 0; // 目标标题归位所需位移

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.flyDuration)
      ..addListener(_onFrame)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _onSwapCompleted();
      });
    final fadeFraction =
        (widget.fadeDuration.inMilliseconds / widget.flyDuration.inMilliseconds)
            .clamp(0.0, 1.0);
    _slide = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, fadeFraction, curve: Curves.linear),
    );
  }

  @override
  void didUpdateWidget(SwipePageIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 检测到新的换页目标 → 播放换页动画
    if (widget.swapTargetIndex != null &&
        widget.swapTargetIndex != oldWidget.swapTargetIndex) {
      _startSwap();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startSwap() {
    final target = widget.swapTargetIndex!;
    _oldCurrent = widget.currentIndex;
    // 目标为上一页（target < current）→ 标题条向右推入（+1）；下一页 → 向左（-1）
    _sign = (widget.currentIndex - target) >= 0 ? 1 : -1;
    // 拖动结束时的标题条位移（与手指同向，= 对应方向归位距离 × progress）
    _startX = _dragOffset();
    // 换页动画的总推入距离：目标标题从当前位置归位到锚点所需位移
    _gapWidth = _gapForTarget(_oldCurrent, target, _sign);
    _swapping = true;
    _controller.forward(from: 0);
  }

  void _onFrame() => setState(() {});

  void _onSwapCompleted() {
    setState(() => _swapping = false);
    widget.onSwapEnded?.call();
  }

  int get _n => widget.titles.length;

  /// 已测量的标题宽度（Dart 的 % 结果恒非负，安全处理负数索引）。
  double _w(int index) => _widths[index % _n] ?? 0;

  /// 拖动时的标题条位移：整体移动「对应方向目标标题的归位距离 × progress」
  /// （方向与手指拖动方向一致）。
  ///
  /// 右拖（progress>0，去上一页）→ 移动量 = 上一页标题的归位距离；
  /// 左拖（progress<0，去下一页）→ 移动量 = 下一页标题的归位距离。
  /// 例如左对齐（start）下：右拖满 = w(prev)+gap，恰好让上一页标题归位；
  /// 左拖满 = w(cur)+gap。
  double _dragOffset() {
    if (_n <= 1) return 0; // 只有一个页面时标题不动
    final p = widget.progress;
    final cur = widget.currentIndex;
    if (p > 0) {
      return p * _gapForTarget(cur, cur - 1, 1); // 向右滑：去上一页
    }
    return p * _gapForTarget(cur, cur + 1, -1); // 向左滑：去下一页
  }

  /// 计算「目标标题归位所需的总位移」：目标标题从静止布局位置，移动到
  /// [SwipeTitleAlign] 锚点位置的距离（换页动画的推入距离即此值）。
  ///
  /// [current] 当前（旧）页索引，[target] 目标页索引，
  /// [sign] 滑动方向（+1 右滑去上一页，-1 左滑去下一页）。
  double _gapForTarget(int current, int target, int sign) {
    final wCur = _w(current);
    final wTarget = _w(target);
    switch (widget.align) {
      case SwipeTitleAlign.start:
        // 锚点 = 父容器左侧：右滑归位 w(target)+gap，左滑归位 w(cur)+gap
        return sign > 0 ? wTarget + widget.titleGap : wCur + widget.titleGap;
      case SwipeTitleAlign.center:
        // 锚点 = 父容器中心：左右对称，各归位 w/2 + w/2 + gap
        return wCur / 2 + wTarget / 2 + widget.titleGap;
      case SwipeTitleAlign.end:
        // 锚点 = 父容器右侧：右滑归位 w(cur)+gap，左滑归位 w(target)+gap
        return sign > 0 ? wCur + widget.titleGap : wTarget + widget.titleGap;
    }
  }

  /// 换页动画中旧标题条的位移：从拖动结束位置继续沿滑动方向推入，
  /// 直到目标标题左边缘对齐父容器左侧（位移终点 = sign × gapWidth）。
  double _oldOffset() {
    return _startX + (_sign * _gapWidth - _startX) * _slide.value;
  }

  /// 换页动画中新标题条的位移：与旧条同步移动，但整体偏置一个推入距离
  /// （从滑动方向的反方向推入，目标标题直接对齐父容器左侧）。
  double _newOffset() {
    return _oldOffset() - _sign * _gapWidth;
  }

  @override
  Widget build(BuildContext context) {
    if (_n == 0) return const SizedBox.shrink();

    // 注意：不使用 ClipRect 裁剪。超出容器范围的标题（上一页/下一页、
    // 拖动或换页时移出容器的标题）会照常绘制在容器之外。
    return Stack(
      // 标题条整体按对齐方式定位：当前标题对齐父容器左/中/右
      alignment: _barAlignment(),
      children: [
        if (!_swapping)
          _buildBar(widget.currentIndex, _dragOffset(), 1.0)
        else ...[
          _buildBar(_oldCurrent, _oldOffset(), 1 - _fade.value, tag: '-old'),
          _buildBar(
            widget.swapTargetIndex!,
            _newOffset(),
            _fade.value,
            tag: '-new',
          ),
        ],
      ],
    );
  }

  /// 对齐方式对应的 Stack alignment。
  Alignment _barAlignment() {
    switch (widget.align) {
      case SwipeTitleAlign.start:
        return Alignment.centerLeft;
      case SwipeTitleAlign.center:
        return Alignment.center;
      case SwipeTitleAlign.end:
        return Alignment.centerRight;
    }
  }

  /// 构建一个标题条：当前标题按 [widget.align] 对齐（100% 不透明），
  /// 上一页标题在当前标题一侧、下一页标题在另一侧（均 50% 不透明，
  /// 中间隔 titleGap）。
  Widget _buildBar(int curIndex, double offset, double opacity,
      {String tag = ''}) {
    final n = _n;
    final cur = curIndex % n;
    // 原始索引（可为负/越界），渲染与点击时内部取模映射到有限标题
    final prev = curIndex - 1;
    final next = curIndex + 1;

    final wCur = _w(cur);
    final wPrev = _w(prev);
    final wNext = _w(next);

    // prev/next 相对"当前标题锚点"的偏移（与对齐方式相关）
    late final double prevDx;
    late final double nextDx;
    switch (widget.align) {
      case SwipeTitleAlign.start:
        prevDx = -(wPrev + widget.titleGap); // prev 在当前左侧
        nextDx = wCur + widget.titleGap; // next 在当前右侧
      case SwipeTitleAlign.center:
        prevDx = -(wPrev / 2 + wCur / 2 + widget.titleGap);
        nextDx = wCur / 2 + wNext / 2 + widget.titleGap;
      case SwipeTitleAlign.end:
        prevDx = -(wCur + widget.titleGap); // prev 在当前左侧
        nextDx = wNext + widget.titleGap; // next 在当前右侧（屏幕外）
    }

    return Transform(
      key: ValueKey('bar-$cur$tag'),
      transform: Matrix4.translationValues(offset, 0, 0),
      child: SizedBox(
        width: double.infinity, // 标题条撑满父容器，对齐才准确
        child: Stack(
          alignment: _barAlignment(),
          children: [
            if (n > 1) ...[
              _positioned(prev, prevDx, opacity * 0.5), // 非当前：50% 透明
              _positioned(next, nextDx, opacity * 0.5), // 非当前：50% 透明
            ],
            _positioned(cur, 0, opacity), // 当前标题：对齐锚点
          ],
        ),
      ),
    );
  }

  Widget _positioned(int index, double dx, double opacity) {
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTitleTap == null
              ? null
              : () => widget.onTitleTap!(index),
          child: _MeasureSize(
            onSize: (size) {
              if (size.width != (_widths[index % _n] ?? -1)) {
                setState(() => _widths[index % _n] = size.width);
              }
            },
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: 57,
                //行间距
                height: 1,
                fontWeight: FontWeight.w300,
                overflow: TextOverflow.visible,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                letterSpacing: 0.3,
              ),
              child: widget.titles[index % _n],
            ),
          ),
        ),
      ),
    );
  }
}

/// 测量子组件尺寸并回调（尺寸变化时才回调）。
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onSize);
  }

  @override
  void updateRenderObject(
      BuildContext context, _MeasureSizeRenderObject renderObject) {
    renderObject.onSize = onSize;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onSize);

  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _last) return;
    _last = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(size));
  }
}
