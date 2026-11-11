import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/widgets/pivot_pane_view.dart';

export 'pivot_pane_view.dart' show PivotTransition, PivotController;

/// 标题指示器的对齐方式。
enum PivotHeaderAlignment {
  /// 左对齐：当前标题左边缘对齐父容器左侧（默认）。
  start,

  /// 居中：当前标题水平居中于父容器。
  center,

  /// 右对齐：当前标题右边缘对齐父容器右侧。
  end,
}

/// 页面条目：一个标题 + 一个页面内容。
class PivotItem {
  const PivotItem({required this.title, required this.page});

  /// 标题（任意 Widget，例如 Text）。
  final Widget title;

  /// 页面内容。
  final Widget page;
}

/// `Constants.PivotHeaderSpacing` = 24（480 设计单位）× 0.8 [读出]。
///
/// `PIVOT 0x45–0x66`：标题条的 `FlowLayout.Spacing` 与 `RepeatGap` 都取这个值。
/// 东亚语言版本改用 `PivotEAHeaderSpacing` = 40（× 0.8 = 32）。
const double kPivotHeaderTitleGap = 24 * uixScale;

/// `Constants.PivotEAHeaderSpacing` = 40 × 0.8 [读出]。
const double kPivotHeaderEATitleGap = 40 * uixScale;

/// `Constants.PivotHeaderFontSize` = 54（点）× 4/3 × 0.8 [读出]。
///
/// `PivotStyle.HeaderFont` = `FontFaceSemiLight` @ 该字号；项目字体把
/// SemiLight 注册在 `w300`。
const double kPivotHeaderFontSize = 54 * (4 / 3) * uixScale;

/// `ThemeResources.PivotColorDark` = `0x66FFFFFF`（白 40%）[读出]。
///
/// 未选中标题的颜色；选中项用 `SystemColors.TextHighColor`。
const Color kPivotHeaderIdleColorDark = Color(0x66FFFFFF);

/// `ThemeResources.PivotColorLight` = `0x33000000`（黑 20%）[读出]。
const Color kPivotHeaderIdleColorLight = Color(0x33000000);

/// [PivotHeader] 的默认标题对齐方式。
const PivotHeaderAlignment kPivotHeaderAlign = PivotHeaderAlignment.start;

/// [PivotHeader] 独立使用时的默认飞出/飞入动画时长。
/// 注意：被 [PivotBase] 组合时以 [PivotPaneView] 的时长为准
/// （[kPivotPaneViewMoveDuration]），以保证标题与页面动画同步。
const Duration kPivotHeaderFlyDuration = kPivotPaneViewMoveDuration;

/// [PivotHeader] 独立使用时的默认渐隐/渐显动画时长。
const Duration kPivotHeaderFadeDuration = Duration(milliseconds: 200);

/// `Constants.HorizontalPagePadding` = 24 × 0.8 = 19.2 [读出]。
///
/// `Styles.PageMargins` 只设置 Left；Right 是另一个独立资源。
const EdgeInsetsGeometry kPivotPadding = EdgeInsets.only(left: 24 * uixScale);

/// 组合组件（标题指示器 + 滑动翻页）的公共基类。
///
/// 持有标题/页面列表与全部动画、布局、回调参数。
/// 子类决定两者的布局方式：
/// - [Pivot]：Column 上下布局（标题在页面上方）；
/// - [PivotStack]：Stack 叠放布局（标题悬浮在页面顶部）。
///
/// 动画/布局参数均为可空，未指定时透传回落为子组件（[PivotPaneView] /
/// [PivotHeader]）各自的默认值常量，修改子组件默认值无需在此重复维护。
abstract class PivotBase extends StatefulWidget {
  const PivotBase({
    super.key,
    required this.items,
    this.initialPage,
    this.transition = PivotTransition.contentChange,
    this.swipeThreshold,
    this.maxDragDistance,
    this.flyDistance,
    this.flyDuration,
    this.fadeDuration,
    this.snapBackDuration,
    this.hideDuration,
    this.showDuration,
    this.titleGap,
    this.align,
    this.onPageChanged,
    this.onTransitionEnd,
    this.onSlideProgress,
  });

  /// 页面条目列表（标题 + 页面）。
  final List<PivotItem> items;

  final PivotTransition transition;

  /// 初始页码（可为负数），透传给 [PivotPaneView]。
  final int? initialPage;

  /// 松手触发换页的最小位移（像素），透传给 [PivotPaneView]。
  final double? swipeThreshold;

  /// 拖动过程中页面允许的最大位移（像素），透传给 [PivotPaneView]。
  final double? maxDragDistance;

  /// 换页时页面飞出/飞入的位移（像素），透传给 [PivotPaneView]。
  final double? flyDistance;

  /// 飞出/飞入动画时长，透传给 [PivotPaneView] 与标题指示器。
  final Duration? flyDuration;

  /// 渐隐/渐显动画时长，透传给 [PivotPaneView] 与标题指示器。
  final Duration? fadeDuration;

  /// 归位动画时长，透传给 [PivotPaneView]。
  final Duration? snapBackDuration;

  /// 旧内容飞出时长，透传给 [PivotPaneView]（`SlideFull*FadeOut`，300 ms）。
  final Duration? hideDuration;

  /// 新内容飞入时长，透传给 [PivotPaneView]（`SlideFull*FadeIn`，500 ms）。
  final Duration? showDuration;

  /// 标题之间的间距，透传给标题指示器。
  final double? titleGap;

  /// 标题对齐方式（左/中/右），透传给标题指示器。
  final PivotHeaderAlignment? align;

  /// 翻页回调（松手触发换页的瞬间），透传。
  final OnPageChanged? onPageChanged;

  /// 换页动画结束回调，透传。
  final OnTransitionEnd? onTransitionEnd;

  /// 滑动进度回调（-1.0 ~ 1.0），透传。
  final OnSlideProgress? onSlideProgress;
}

/// 组合组件：标题指示器 + 滑动翻页（Column 上下布局）。
///
/// 顶部是标题指示器，下方是 [PivotPaneView]，两者自动同步：
/// - 拖动页面（不松手）时，标题条整体移动「对应方向目标标题的归位距离
///   × progress」，与 [PivotPaneView.onSlideProgress] 对齐。
///   例：左对齐下向右滑（去上一页）移动量 = 上一页标题宽度（+间距），
///   向左滑（去下一页）移动量 = 当前标题宽度（+间距）；
/// - 松手触发换页时，下一个标题使用从快到慢的减速动画滑入
///   （[Curves.easeOutCubic]）；
/// - 同时显示三个标题：上一页 / 当前页 / 下一页；
/// - 只有两个页面（A、B，A 为当前）时显示 B A B；
/// - 只有一个页面时只显示一个标题。
///
/// 默认左侧内缩19.2，标题与内容之间留22.4（480资源×0.8），
/// 可通过 [padding] 覆盖。
class Pivot extends PivotBase {
  const Pivot({
    super.key,
    required super.items,
    super.initialPage,
    super.transition,
    super.swipeThreshold,
    super.maxDragDistance,
    super.flyDistance,
    super.flyDuration,
    super.fadeDuration,
    super.snapBackDuration,
    super.hideDuration,
    super.showDuration,
    super.titleGap,
    super.align,
    super.onPageChanged,
    super.onTransitionEnd,
    super.onSlideProgress,
    this.padding = kPivotPadding,
  });

  /// 整体内边距（标题与主体统一内缩），默认水平 18。
  final EdgeInsetsGeometry padding;

  @override
  State<Pivot> createState() => _PivotState();
}

/// 组合组件：标题指示器 + 滑动翻页（Stack 叠放布局）。
///
/// 页面铺满整个区域，标题指示器以 [Stack] 方式悬浮在页面顶部
/// （[indicatorAlign] 控制顶部位置，[indicatorPadding] 控制边距）。
/// 点击上一页/下一页标题可切换到对应页面；标题之外的空白区域
/// 触摸穿透到页面（不会挡住拖动）。
///
/// 页面与标题的同步行为与 [Pivot] 完全一致。
class PivotStack extends PivotBase {
  const PivotStack({
    super.key,
    required super.items,
    super.initialPage,
    super.transition,
    super.swipeThreshold,
    super.maxDragDistance,
    super.flyDistance,
    super.flyDuration,
    super.fadeDuration,
    super.snapBackDuration,
    super.hideDuration,
    super.showDuration,
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
  State<PivotStack> createState() => _PivotStackState();
}

/// 页面与标题同步逻辑（[Pivot] 与 [PivotStack] 共用）。
///
/// 维护当前页索引、换页目标、滑动进度，并把 [PivotPaneView] 的回调
/// 同步给 [PivotHeader]。
mixin _PivotSyncState<T extends PivotBase> on State<T> {
  late int _currentIndex;
  int? _swapTarget;
  double _progress = 0;
  bool _swapping = false;

  /// 编程式换页控制器：点击标题时驱动 [PivotPaneView] 播放换页动画。
  final PivotController _viewController = PivotController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPage ?? kPivotPaneViewInitialPage;
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
    return PivotHeader(
      titles: [for (final e in widget.items) e.title],
      clipBehavior: Clip.none,
      currentIndex: _currentIndex,
      progress: _progress,
      swapTargetIndex: _swapTarget,
      titleGap:
          widget.titleGap ??
          ([
                'zh',
                'ja',
                'ko',
              ].contains(Localizations.localeOf(context).languageCode)
              ? kPivotHeaderEATitleGap
              : kPivotHeaderTitleGap),
      align: widget.align ?? kPivotHeaderAlign,
      flyDuration: widget.flyDuration ?? kPivotPaneViewMoveDuration,
      fadeDuration: widget.fadeDuration ?? Duration.zero,
      onSwapEnded: _handleSwapEnded,
      onTitleTap: _handleTitleTap,
    );
  }

  /// 构建滑动翻页组件（无限滚动：任意 index 循环映射到有限页面）。
  Widget buildView() {
    final n = widget.items.length;
    return PivotPaneView(
      controller: _viewController,
      clipBehavior: Clip.none,
      transition: widget.transition,
      hideDuration: widget.hideDuration ?? kPivotPaneViewHideDuration,
      showDuration: widget.showDuration ?? kPivotPaneViewShowDuration,
      initialPage: widget.initialPage ?? kPivotPaneViewInitialPage,
      // null 表示沿用系统值：33% × 一页宽 / 一页宽。
      swipeThreshold: widget.swipeThreshold,
      maxDragDistance: widget.maxDragDistance,
      flyDistance: widget.flyDistance ?? 0,
      flyDuration: widget.flyDuration ?? kPivotPaneViewMoveDuration,
      fadeDuration: widget.fadeDuration ?? Duration.zero,
      snapBackDuration: widget.snapBackDuration ?? kPivotPaneViewMoveDuration,
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

class _PivotState extends State<Pivot> with _PivotSyncState<Pivot> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    // 整体内边距：标题与主体统一内缩
    return ClipRect(
      child: Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildIndicator(),
            const SizedBox(height: 28 * uixScale),
            Expanded(child: buildView()),
          ],
        ),
      ),
    );
  }
}

class _PivotStackState extends State<PivotStack>
    with _PivotSyncState<PivotStack> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return ClipRect(
      child: Stack(
        clipBehavior: Clip.none,
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
      ),
    );
  }
}

/// 标题指示器（可独立使用）。
///
/// 通过 [align] 控制当前标题的对齐方式（默认左对齐）：
/// - [PivotHeaderAlignment.start]：当前标题左边缘对齐父容器左侧；
/// - [PivotHeaderAlignment.center]：当前标题水平居中；
/// - [PivotHeaderAlignment.end]：当前标题右边缘对齐父容器右侧。
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
class PivotHeader extends StatefulWidget {
  const PivotHeader({
    super.key,
    required this.titles,
    required this.currentIndex,
    this.progress = 0,
    this.clipBehavior = Clip.hardEdge,
    this.swapTargetIndex,
    this.titleGap = kPivotHeaderTitleGap,
    this.align = kPivotHeaderAlign,
    this.flyDuration = kPivotHeaderFlyDuration,
    this.fadeDuration = kPivotHeaderFadeDuration,
    this.onSwapEnded,
    this.onTitleTap,
  });

  /// 所有标题（顺序与页面一一对应，可循环）。
  final List<Widget> titles;
  final Clip clipBehavior;

  /// 当前页面索引（可为负数，内部循环映射）。
  final int currentIndex;

  /// 滑动进度 -1.0 ~ 1.0（拖动时），标题条跟随移动。
  final double progress;

  /// 换页目标索引：非 null 且发生变化时播放换页动画。
  final int? swapTargetIndex;

  /// 标题之间的间距。
  final double titleGap;

  /// 标题对齐方式（左/中/右），默认 [PivotHeaderAlignment.start]。
  final PivotHeaderAlignment align;

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
  State<PivotHeader> createState() => _PivotHeaderState();
}

class _PivotHeaderState extends State<PivotHeader>
    with TickerProviderStateMixin {
  /// 已测量的标题宽度（key：标题在列表中的索引）。
  final Map<int, double> _widths = {};

  /// 已测量的标题高度；Stack 必须有确定高度，先用估计值占位。
  double _titleHeight = kPivotHeaderFontSize * 1.43;

  late final AnimationController _controller;

  /// `PivotMove`：500 ms、`Log(150)`（[kPivotPaneViewMoveCurve]）。
  late final Animation<double> _slide;

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
    _slide = CurvedAnimation(
      parent: _controller,
      curve: kPivotPaneViewMoveCurve,
    );
  }

  @override
  void didUpdateWidget(PivotHeader oldWidget) {
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
  /// [PivotHeaderAlignment] 锚点位置的距离（换页动画的推入距离即此值）。
  ///
  /// [current] 当前（旧）页索引，[target] 目标页索引，
  /// [sign] 滑动方向（+1 右滑去上一页，-1 左滑去下一页）。
  double _gapForTarget(int current, int target, int sign) {
    final wCur = _w(current);
    final wTarget = _w(target);
    switch (widget.align) {
      case PivotHeaderAlignment.start:
        // 锚点 = 父容器左侧：右滑归位 w(target)+gap，左滑归位 w(cur)+gap
        return sign > 0 ? wTarget + widget.titleGap : wCur + widget.titleGap;
      case PivotHeaderAlignment.center:
        // 锚点 = 父容器中心：左右对称，各归位 w/2 + w/2 + gap
        return wCur / 2 + wTarget / 2 + widget.titleGap;
      case PivotHeaderAlignment.end:
        // 锚点 = 父容器右侧：右滑归位 w(cur)+gap，左滑归位 w(target)+gap
        return sign > 0 ? wCur + widget.titleGap : wTarget + widget.titleGap;
    }
  }

  /// 换页动画中标题条的位移：从拖动结束位置继续沿滑动方向移动，
  /// 直到目标标题归位到锚点（位移终点 = sign × gapWidth）。
  double _swapOffset() {
    return _startX + (_sign * _gapWidth - _startX) * _slide.value;
  }

  /// 标题按周期重复：一个周期 = n 个标题 + n 个间距。
  double get _periodWidth {
    var sum = 0.0;
    for (var i = 0; i < _n; i++) {
      sum += _w(i) + widget.titleGap;
    }
    return sum;
  }

  /// 第 [k] 个槽位（可为任意整数）相对第 0 个槽位左边的累计宽度。
  ///
  /// 标题以 [periodWidth] 为周期重复，所以槽位坐标可以直接按周期换算，
  /// 连续平移到任何位置都不会有"某个标题瞬移"的接缝。
  double _slotX(int k) {
    final n = _n;
    final period = _periodWidth;
    final cycle = (k / n).floor();
    final rest = k - cycle * n;
    var x = cycle * period;
    for (var i = 0; i < rest; i++) {
      x += _w(i) + widget.titleGap;
    }
    return x;
  }

  /// 当前标题左边缘的锚点位置（相对父容器）。
  double _anchorX(double width) {
    return switch (widget.align) {
      PivotHeaderAlignment.start => 0.0,
      PivotHeaderAlignment.center => (width - _w(widget.currentIndex)) / 2,
      PivotHeaderAlignment.end => width - _w(widget.currentIndex),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_n == 0) return const SizedBox.shrink();
    final cur = widget.currentIndex;
    final offset = _swapping ? _swapOffset() : _dragOffset();

    // 系统里标题条是一个横向 ScrollViewer 里的 Repeater（连续条），
    // 超出视口的部分被裁掉；拖动/换页时旧标题从边缘移出、新标题从另一侧
    // 移入，没有任何淡入淡出。这里同样只渲染连续槽位，避免"三选一"布局
    // 在换页瞬间让最外侧标题从左跳到右。
    return ClipRect(
      clipBehavior: widget.clipBehavior,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final anchor = _anchorX(constraints.maxWidth);
          final base = _slotX(cur);
          // 槽位坐标用的是全局累计宽度，换页那一刻不会出现标题瞬移；
          // 换页期间再多画「前进方向」上的一个槽位，否则它在提交的瞬间
          // 会从无到有地冒到屏幕边缘（就是观众看到的"标题跳一下"）。
          var lo = _n > 1 ? cur - 1 : cur;
          var hi = _n > 1 ? cur + 1 : cur;
          if (_swapping && _n > 2) {
            if (_sign < 0) {
              hi = cur + 2;
            } else {
              lo = cur - 2;
            }
          }
          return SizedBox(
            height: _titleHeight,
            child: Transform.translate(
              // 用取模后的标题索引做 key（负页码也能得到 0..n-1）。
              key: ValueKey('bar-${cur % _n}'),
              offset: Offset(offset, 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var k = lo; k <= hi; k++)
                    Positioned(
                      left: anchor + _slotX(k) - base,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        // Selection commits on release; layout retains the old anchor
                        // until the title motion has finished.
                        child: _title(
                          k,
                          selected: k == (widget.swapTargetIndex ?? cur),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _title(int index, {required bool selected}) {
    final theme = Theme.of(context);
    final selectedColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final idleColor = theme.brightness == Brightness.dark
        ? kPivotHeaderIdleColorDark
        : kPivotHeaderIdleColorLight;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTitleTap == null ? null : () => widget.onTitleTap!(index),
      child: _MeasureSize(
        onSize: (size) {
          final changedWidth = size.width != (_widths[index % _n] ?? -1);
          final changedHeight = size.height != _titleHeight;
          if (!changedWidth && !changedHeight) return;
          setState(() {
            if (changedWidth) _widths[index % _n] = size.width;
            if (changedHeight) _titleHeight = size.height;
          });
        },
        child: DefaultTextStyle.merge(
          style: TextStyle(
            // PivotStyle.HeaderFont：FontFaceSemiLight（项目注册为 w300）
            fontSize: kPivotHeaderFontSize,
            fontWeight: FontWeight.w300,
            overflow: TextOverflow.visible,
            color: selected ? selectedColor : idleColor,
            // Constants.PivotHeaderCharacterSpacing = 0.0（非东亚语言）
            letterSpacing: 0,
          ),
          child: widget.titles[index % _n],
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
    BuildContext context,
    _MeasureSizeRenderObject renderObject,
  ) {
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
