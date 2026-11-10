import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/metro_theme_extensions.dart';
import 'package:metro_ui/page_scaffold.dart';

/// 三层视差中，大标题层与背景层相对内容的当前偏移。
class PanoramaParallax {
  /// 大标题层偏移（屏幕坐标，负值向左）。
  final double titleOffset;

  /// 背景层偏移（屏幕坐标，负值向左）。
  final double backgroundOffset;

  const PanoramaParallax(this.titleOffset, this.backgroundOffset);
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSize({required this.onChange, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _oldSize) return;
    _oldSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(size);
    });
  }
}

/// Panorama 的全部布局、动画与手势参数。
///
/// 数值取自 WP8 `UIXMobile` Panorama 在 480×800 资源下的常量，
/// 并按本库统一的 0.8 缩放换算（设计宽度 480 × 0.8 = 384）。
class PanoramaConfig {
  // ── 布局常量（WP8 PanoramaStyle / CONSTANTS）─────────────────────────────────
  /// Pane 锁定在左侧时，其左边缘与屏幕左边缘的距离（WP8: 24）。
  final double leftLockAlignmentOffset;

  /// Pane 锁定在右侧时，其右边缘与屏幕右边缘的距离（WP8: 48）。
  final double rightLockAlignmentOffset;

  /// 相邻 Pane 之间的间距（WP8: PanoramaContentSpacing = 24）。
  final double contentSpacing;

  /// 屏幕右侧预留、用于露出下一 Pane 的宽度（WP8: PanoramaRightEdgeBleedIn = 24）。
  final double rightEdgeBleedIn;

  /// Pane 的默认最大宽度（WP8: PanoramaDefaultPaneMaxWidth = 408）。
  final double defaultPaneMaxWidth;

  /// Pane 标题在 Pane 内移动时右侧保留的边距（WP8: PanoramaHeaderRightParallaxMargin = 30）。
  final double headerRightParallaxMargin;

  /// 大标题文本排版宽度的回退值（实测宽度优先）。
  ///
  /// 视差用的 `TitleWidth = max(文本排版宽度, 屏宽)`；
  /// 副本周期 = 文本排版宽度 + 屏宽（WP8 在标题文本右 margin 上追加一个 ScreenWidth）。
  final double titleTextWidth;

  /// 背景层宽度（WP8 480 宽资源常量 1000）。
  final double backgroundLayerWidth;

  // ── 视差因子 ─────────────────────────────────────────────────────────────────
  /// 大标题视差因子初值（WP8: ParallaxTitleFactor = 5.5）。
  ///
  /// 运行时会被 `T / D` 覆盖：T 是一轮内容的行程，
  /// D = 层宽 − 4 × ⌊屏宽 / 5⌋。也就是每轮内容行程中该层移动 D。
  final double titleParallaxInitialFactor;

  /// 背景视差因子初值（WP8: ParallaxBackgroundFactor = 9.5）。
  final double backgroundParallaxInitialFactor;

  // ── 进场动画 ─────────────────────────────────────────────────────────────────
  /// 3D 旋转入场动画时长（WP8: 500 ms）。
  final Duration rotationDuration;

  /// 平移入场动画时长（WP8: 1000 ms）。
  final Duration translationDuration;

  /// 旋转入场的起始角度（度，负值=向右倾倒；WP8: −120°）。
  final double rotationStartDegrees;

  /// 背景进场时的最大平移距离（像素，tv 从 1→0；WP8 480 宽资源为 1200）。
  final double backgroundEntryTranslate;

  /// 大标题进场时的最大平移距离（像素；WP8 480 宽资源为 2000）。
  final double titleEntryTranslate;

  /// 内容区进场时的最大平移距离（像素；WP8 480 宽资源为 1500）。
  final double contentEntryTranslate;

  // ── 3D 透视旋转 ───────────────────────────────────────────────────────────────
  /// 旋转中心相对组件宽度的比例（WP8 CenterPointPercent.X = −0.5）。
  final double rotationCenterXPercent;

  /// 3D 旋转入场曲线（WP8: Log，权重 10）。
  final Curve rotationCurve;

  // ── 大标题布局 ───────────────────────────────────────────────────────────────
  /// 副本周期的额外余量（像素，加在 `文本排版宽度 + 屏宽` 之后，默认 0）。
  ///
  /// 结构依据：WP8 标题文本的右 margin = ScreenWidth，因此相邻副本间距为
  /// `文本宽度 + 屏宽`。若实测发现周期不符，用该字段微调。
  final double titleRepeatSpacingExtra;

  /// 大标题层（PanoTitleLayer）相对顶部的偏移（WP8: margin.top = −75）。
  final double titleLayerTop;

  /// 大标题文本相对标题层的偏移（WP8: 标题 Root margin.top = 41）。
  ///
  /// 两者是不同布局节点的属性，不能简单相加当作字形的屏幕 top：
  /// 还叠加 UIX 文本 BoundsType、基线、Page 视口与系统托盘。
  final double titleTextTop;

  /// 大标题区域高度（像素）。
  final double titleAreaHeight;

  /// 大标题区域向右溢出的距离（像素，会被转为负数 right 值）。
  final double titleOverflowRight;

  /// 大标题文本左边距（WP8: 标题层与标题 Root 的 margin.left 均为 0）。
  ///
  /// 因此大标题是贴左边缘排版的（首个字形可能被屏幕左缘裁掉）。
  final double titleTextLeftMargin;

  // ── Pane 布局 ────────────────────────────────────────────────────────────────
  /// Pane 内容顶部偏移（WP8: PanoramaVScrollContentMargins.top = 198）。
  ///
  /// 对应 custom VScroll Pane 的内容容器 margin；通用 Header 用的
  /// PanoramaHeaderMargins / HeaderModelMargins 是另外的节点，People 不适用。
  final double paneTopPadding;

  /// Pane 标题字号（WP8: PanoramaGroupHeaderFontSize = 50，SemiLight）。
  ///
  /// People 的 Pane 标题实际是各 app 自己放在内容里的 Label，
  /// 可能覆盖该字号；`PanoramaGroupHeaderLineSpacing = 19` 的单位尚未核对，
  /// 因此这里不映射成 Flutter 行高。
  final double paneHeaderFontSize;

  // ── 归位动画 ──────────────────────────────────────────────────────────────────
  /// 归位动画曲线，为 null 时使用默认弹簧物理（[ScrollSpringSimulation]）。
  ///
  /// WP8: 内容、标题、背景三条归位动画均为 800 ms / Log(300)。
  final Curve? snapCurve;

  /// 归位动画时长，仅在 [snapCurve] 不为 null 时生效。
  final Duration snapDuration;

  // ── Pane 标题（Pane Header）视差 ──────────────────────────────────────────────
  /// Pane 尚未越过锁定位置时，额外偏移 = 距离 × 该系数。
  ///
  /// WP8 公式为 `(L − p) / 1.18`（L 为左侧锁定偏移），即 1 / 1.18。
  final double paneHeaderForwardRate;

  /// Pane 已越过锁定位置时，额外偏移 = 距离 × 该系数（WP8: 0.4）。
  final double paneHeaderBackwardRate;

  /// 惯性被手指打断时 Pane 标题跟随手指的速率（Flutter 侧行为，无 WP8 对应值）。
  final double paneHeaderInterruptRate;

  // ── 手势 ─────────────────────────────────────────────────────────────────────
  /// 低于此速度（px/s）视为主动停止；停在宽 Pane 内部时不再吸附。
  final double stoppedVelocityThreshold;

  /// 高于此速度（px/s）视为 Flick。
  ///
  /// WP8 的真实阈值由原生 Flicker 手势识别器决定，尚未还原，此值仅为本库近似。
  final double flickVelocityThreshold;

  const PanoramaConfig({
    this.leftLockAlignmentOffset = 24 * 0.8,
    this.rightLockAlignmentOffset = 48 * 0.8,
    this.contentSpacing = 24 * 0.8,
    this.rightEdgeBleedIn = 24 * 0.8,
    this.defaultPaneMaxWidth = 408 * 0.8,
    this.headerRightParallaxMargin = 30 * 0.8,
    this.titleTextWidth = 500 * 0.8,
    this.backgroundLayerWidth = 1000 * 0.8,
    this.titleParallaxInitialFactor = 5.5,
    this.backgroundParallaxInitialFactor = 9.5,
    this.rotationDuration = const Duration(milliseconds: 500),
    this.translationDuration = const Duration(milliseconds: 1000),
    this.rotationStartDegrees = -120,
    this.backgroundEntryTranslate = 1200 * 0.8,
    this.titleEntryTranslate = 2000 * 0.8,
    this.contentEntryTranslate = 1500 * 0.8,
    this.rotationCenterXPercent = -0.5,
    this.rotationCurve = MetroCurves.panoramaForwardIn,
    this.titleRepeatSpacingExtra = 0.0,
    this.titleLayerTop = -75 * 0.8,
    this.titleTextTop = 41 * 0.8,
    this.titleAreaHeight = 150.0,
    this.titleOverflowRight = 2000.0,
    this.titleTextLeftMargin = 0.0,
    this.paneTopPadding = 198 * 0.8,
    this.paneHeaderFontSize = 50 * 0.8,
    this.snapCurve = const UixLog(300),
    this.snapDuration = const Duration(milliseconds: 800),
    this.paneHeaderForwardRate = 1 / 1.18,
    this.paneHeaderBackwardRate = 0.4,
    this.paneHeaderInterruptRate = 0.7,
    this.stoppedVelocityThreshold = 200.0,
    this.flickVelocityThreshold = 200.0,
  });
}

class MetroPanoramaItem {
  /// Pane 标题（Pane Header），随 Pane 一起移动。
  final Widget title;

  /// Pane 内容。
  final Widget child;

  /// Pane 内容宽度（WP8 Pane MaxWidth）。<= 0 表示使用
  /// [PanoramaConfig.defaultPaneMaxWidth] 与屏宽推算出的默认宽度。
  final double width;

  MetroPanoramaItem({required this.title, required this.child, this.width = 0});
}

typedef TargetCallback = void Function(double target);

/// 把「当前滚动位置 + 抬手速度」解析为吸附目标。
///
/// 返回 `null` 表示保持在当前位置、不播放归位动画。
typedef PanoramaSnapResolver = double? Function(double pixels, double velocity);

/// 使用 Flutter [Curve] 驱动的滚动吸附动画模拟器。
/// 相比 [ScrollSpringSimulation]，它允许完全自定义缓动曲线与持续时间。
class _CurvedScrollSimulation extends Simulation {
  final double _start;
  final double _end;
  final double _durationSeconds;
  final Curve _curve;

  _CurvedScrollSimulation({
    required double start,
    required double end,
    required Duration duration,
    required Curve curve,
    super.tolerance,
  }) : _start = start,
       _end = end,
       _durationSeconds =
           duration.inMicroseconds / Duration.microsecondsPerSecond,
       _curve = curve;

  @override
  double x(double time) {
    final double t = (time / _durationSeconds).clamp(0.0, 1.0);
    return _start + (_end - _start) * _curve.transform(t);
  }

  @override
  double dx(double time) {
    if (isDone(time)) return 0.0;
    // 数值微分估算速度
    const double dt = 0.001;
    return (x(time + dt) - x(time)) / dt;
  }

  @override
  bool isDone(double time) {
    return time >= _durationSeconds ||
        (x(time) - _end).abs() < tolerance.distance;
  }
}

class PanoramaScrollPhysics extends ScrollPhysics {
  /// 是否循环滚动。
  final bool isInfinite;

  /// 由 Panorama 状态提供的吸附目标解析器，见 [PanoramaSnapResolver]。
  final PanoramaSnapResolver? resolveTarget;

  /// 归位动画开始前回调，用于记录归位起点。
  final TargetCallback? onTargetCalculated;

  /// 归位动画曲线，为 null 时退回到 [ScrollSpringSimulation]。
  final Curve? snapCurve;

  /// 归位动画时长，仅在 [snapCurve] 不为 null 时生效。
  final Duration snapDuration;

  const PanoramaScrollPhysics({
    required this.isInfinite,
    this.resolveTarget,
    this.onTargetCalculated,
    this.snapCurve,
    this.snapDuration = const Duration(milliseconds: 800),
    super.parent,
  });

  @override
  PanoramaScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return PanoramaScrollPhysics(
      isInfinite: isInfinite,
      resolveTarget: resolveTarget,
      onTargetCalculated: onTargetCalculated,
      snapCurve: snapCurve,
      snapDuration: snapDuration,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final Tolerance tolerance = toleranceFor(position);

    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    final double pixels = position.pixels;
    double? target = resolveTarget?.call(pixels, velocity);
    if (target == null) return null;

    if (!isInfinite) {
      target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    }

    if ((target - pixels).abs() < tolerance.distance) return null;

    onTargetCalculated?.call(target);

    if (snapCurve != null) {
      return _CurvedScrollSimulation(
        start: pixels,
        end: target,
        duration: snapDuration,
        curve: snapCurve!,
        tolerance: tolerance,
      );
    }

    // 将 initial velocity 设为 0，防止由于抬手速度过大导致弹簧过冲（即到达下一页时的回弹现象）
    return ScrollSpringSimulation(
      spring,
      pixels,
      target,
      0.0,
      tolerance: tolerance,
    );
  }
}

/// Windows Phone Panorama。
///
/// 对应 WP8 的三条**平行滚动层**（各自独立的 ScrollModel，不是同一 PageView 的页面偏移）：
///
/// ```text
/// Stack
/// ├─ BackgroundScroller（可选，仅 background != null 时）
/// ├─ TitleScroller（大标题 + 循环副本）
/// └─ ContentScroller（Pane 列表）
///    └─ Pane
///       ├─ Pane 标题（WP8 中 People 由各 app 自己放在内容里的 Label）
///       └─ Pane 内容
/// ```
///
/// 布局常量取自 WP8 480×800 资源 ×0.8（见 [PanoramaConfig]）。
/// 以下仍需按真机校准，代码里保留为可配置项：
/// - 三条层的绘制 Z 序与裁剪：这里按 背景→标题→内容 叠放，并由外层裁剪；
///   UIX 的 children 添加顺序是 Content→Title→Background，但不是绘制顺序的证据。
/// - 大标题的屏幕 top：`PanoTitleLayer.margin.top = −75` 与标题文本 `margin.top = 41`
///   属于不同节点，叠加文本基线/BoundsType/系统托盘后才得到字形位置。
/// - 文字单位：`CharacterSpacing = −6`、`LineSpacing = 19` 未直接映射成 Flutter 度量。
/// - Pane 的实际宽度：408 是 MaxWidth 属性，People 的 custom Pane 还受父布局约束；
///   过滤模式会改宽度输入与 margin。
class MetroPanorama extends StatefulWidget {
  final Widget title;
  final Widget? background;
  final List<MetroPanoramaItem> items;
  final ValueChanged<int>? onPageChange;
  final PanoramaConfig? config;

  const MetroPanorama({
    super.key,
    required this.title,
    this.background,
    required this.items,
    this.onPageChange,
    this.config,
  });

  @override
  State<MetroPanorama> createState() => _MetroPanoramaState();
}

class _MetroPanoramaState extends State<MetroPanorama>
    with TickerProviderStateMixin {
  PanoramaConfig? _resolvedConfig;

  PanoramaConfig get _config =>
      _resolvedConfig ?? widget.config ?? const PanoramaConfig();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newConfig =
        widget.config ??
        Theme.of(context).extension<MetroPanoramaThemeData>()?.config ??
        const PanoramaConfig();
    if (_resolvedConfig != newConfig) {
      _resolvedConfig = newConfig;
      _paneHeaderSnapController.duration = newConfig.snapDuration;
      _rotationController.duration = newConfig.rotationDuration;
      _translationController.duration = newConfig.translationDuration;
      _rotationTween.begin = newConfig.rotationStartDegrees;
    }
  }

  static const double _pi = 3.1415926535897932;
  static const double _epsilon = 0.01;

  /// 锁定点识别容差：吸附动画允许 1px 级残差，不影响“落在哪一页”的判断。
  static const double _lockTolerance = 1.0;
  static double _degreesToRadians(double degrees) => degrees * _pi / 180;
  double get _rotationOriginX =>
      _config.rotationCenterXPercent * _viewportWidth;

  late AnimationController _rotationController;
  late AnimationController _translationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _translationAnimation;
  late final Tween<double> _rotationTween;
  late final Tween<double> _translationTween;

  late ScrollController _scrollController;

  final ValueNotifier<PanoramaParallax> _parallaxNotifier =
      ValueNotifier<PanoramaParallax>(const PanoramaParallax(0.0, 0.0));
  final ValueNotifier<Map<int, double>> _paneHeaderOffsetNotifier =
      ValueNotifier<Map<int, double>>({});
  final ValueNotifier<double> _translationNotifier = ValueNotifier<double>(1.0);

  bool _isDragging = false;
  bool _isBallistic = false;
  bool _isInterruptingBallistic = false;
  double? _dragStartPixels;

  /// 归位动画期间持有的计时器。
  /// 手指抬起 → 归位动画开始时启动，若在计时器超时前再次按下则视为"打断惯性"。
  Timer? _ballisticInterruptTimer;
  double _targetS = 0.0;
  double _releaseS = 0.0;
  double _releaseTitleOffset = 0.0;
  double _releaseBackgroundOffset = 0.0;
  Map<int, double> _releasePaneHeaderOffsets = {};

  /// 大标题 / 背景当前的滚动偏移（状态量，不直接由滚动位置推导）。
  ///
  /// WP8 中拖动是“按增量累计”，松手时才把目标设为所选 Pane 的锁定比例，
  /// 两者口径不同（拖动含 `ContentSpacing`，锁定比例只累加 Pane 的 MaxWidth），
  /// 因此松手后可能出现几个像素的反向修正。
  double _titleScrollOffset = 0.0;
  double _backgroundScrollOffset = 0.0;

  /// 本次归位要收敛到的目标偏移。
  double _targetTitleOffset = 0.0;
  double _targetBackgroundOffset = 0.0;

  /// Pane 标题归位补间动画控制器。
  late AnimationController _paneHeaderSnapController;
  Map<int, double> _paneHeaderSnapFrom = {};
  Map<int, double> _paneHeaderSnapTo = {};

  /// 背景层实测宽度，测量完成前回退到 WP8 资源常量。
  double? _measuredBackgroundLayerWidth;

  // ── 布局派生值（由 _recalculateLayout 统一维护）───────────────────────────────
  /// 视口宽度。
  double _viewportWidth = 0.0;

  /// 默认 Pane 宽度：
  /// `min(屏宽 − 左侧锁定 − 间距 − 右侧预露, PanoramaDefaultPaneMaxWidth)`。
  double _defaultPaneWidth = 0.0;

  /// 每个 Pane 占用的 item 宽度（Pane 内容宽 + 左侧锁定偏移）。
  List<double> _paneItemWidths = [];

  /// 每个 Pane 的内容宽度（= WP8 Pane MaxWidth）。
  List<double> _paneContentWidths = [];

  /// 每个 Pane 是否宽到需要内部滚动（同时启用 Pane 标题视差）。
  List<bool> _isWidePane = [];

  /// 全部锁定点：每个 Pane 的起始锁定点，宽 Pane 另加内部右锁定点。
  final List<double> _lockPoints = [];

  /// 仅每个 Pane 的起始锁定点（翻页落点）。
  final List<double> _paneStartLockPoints = [];

  /// 每个 Pane 标题的实测宽度。
  List<double> _paneHeaderWidths = [];

  /// 一轮内容的滚动长度。
  double _contentCycleLength = 0;

  /// 一轮内容的行程 T：`Σ Pane.MaxWidth + (Pane 数 − 1) × ContentSpacing`。
  ///
  /// 这是视差因子 `T / D` 的分母，也是拖动阶段标题移动量的基准。
  double _paneTravel = 0;

  /// 前 i 个 Pane 的 MaxWidth 累加（长度 = Pane 数 + 1）。
  ///
  /// 标题/背景的锁定比例只用它，**不包含** `ContentSpacing`。
  List<double> _cumulativePaneWidths = [0.0];

  /// 大标题文本的实测排版宽度，测量完成前回退到 config。
  double? _measuredTitleTextWidth;

  /// 大标题文本的排版宽度。
  double get _titleTextWidth =>
      _measuredTitleTextWidth ?? _config.titleTextWidth;

  /// 视差用的 `TitleWidth = max(文本排版宽度, 屏宽)`。
  double get _titleLayerWidth => math.max(_titleTextWidth, _viewportWidth);

  /// 大标题相邻副本的间距（即循环周期）。
  ///
  /// WP8 在标题文本的右 margin 上追加一个 ScreenWidth，因此相邻副本间距为
  /// `文本排版宽度 + 屏宽`（+ 可调余量）。两份副本始终按该周期摆放，
  /// 输入越过周期时由相邻代副本接替，等价于 `RepeatAllowDuplicates=true`
  /// 的视觉近似（不保证与 WP8 引擎的视觉对象复用完全一致）。
  double get _titleRepeatSpacing =>
      _titleTextWidth + _viewportWidth + _config.titleRepeatSpacingExtra;

  int _currentPaneIndex = 0;

  /// 根据视口宽度和 config 统一计算所有布局派生值。
  /// 仅当视口宽度或默认 Pane 宽度变化时才重新计算，并在非首次构建时把滚动位置校正到当前 Pane。
  void _recalculateLayout(double viewportWidth) {
    final double defaultPaneWidth = math.min(
      viewportWidth -
          _config.leftLockAlignmentOffset -
          _config.contentSpacing -
          _config.rightEdgeBleedIn,
      _config.defaultPaneMaxWidth,
    );
    final bool isFirstBuild = _contentCycleLength == 0;
    if (!isFirstBuild &&
        defaultPaneWidth == _defaultPaneWidth &&
        viewportWidth == _viewportWidth) {
      return;
    }

    if (_paneHeaderWidths.length != widget.items.length) {
      final List<double> next = List<double>.filled(widget.items.length, 0.0);
      for (int i = 0; i < _paneHeaderWidths.length && i < next.length; i++) {
        next[i] = _paneHeaderWidths[i];
      }
      _paneHeaderWidths = next;
    }

    _viewportWidth = viewportWidth;
    _defaultPaneWidth = defaultPaneWidth;

    _paneContentWidths = List<double>.generate(widget.items.length, (i) {
      final double configured = widget.items[i].width;
      return configured > 0 ? configured : defaultPaneWidth;
    });
    _paneItemWidths = List<double>.generate(
      widget.items.length,
      (i) => _paneContentWidths[i] + _config.leftLockAlignmentOffset,
    );
    _isWidePane = List<bool>.generate(
      widget.items.length,
      (i) => _paneInternalRange(i) > 0,
    );

    _lockPoints.clear();
    _paneStartLockPoints.clear();
    _cumulativePaneWidths = List<double>.filled(widget.items.length + 1, 0.0);
    double current = 0;
    double widthSum = 0;
    for (int i = 0; i < widget.items.length; i++) {
      _paneStartLockPoints.add(current);
      _lockPoints.add(current);
      final double internalRange = _paneInternalRange(i);
      if (internalRange > 0) _lockPoints.add(current + internalRange);
      current += _paneItemWidths[i];
      widthSum += _paneContentWidths[i];
      _cumulativePaneWidths[i + 1] = widthSum;
    }
    _contentCycleLength = current;
    _paneTravel =
        widthSum +
        math.max(0, widget.items.length - 1) * _config.contentSpacing;

    if (!isFirstBuild) {
      // 窗口变化：跳回当前 Pane 的起始锁定点
      final double newS =
          _paneStartLockPoints[_currentPaneIndex.clamp(
            0,
            _paneStartLockPoints.length - 1,
          )];
      _titleScrollOffset = _titleLockOffset(
        _currentPaneIndex.clamp(0, widget.items.length - 1),
        _contentCycleOf(newS),
      );
      _backgroundScrollOffset = _backgroundLockOffset(
        _currentPaneIndex.clamp(0, widget.items.length - 1),
        _contentCycleOf(newS),
      );
      _parallaxNotifier.value = PanoramaParallax(
        _titleScrollOffset,
        _backgroundScrollOffset,
      );
      _paneHeaderOffsetNotifier.value = {
        for (int i = 0; i < widget.items.length; i++)
          i: _paneHeaderOffsetForScroll(i, newS),
      };
      _isDragging = false;
      _isBallistic = false;
      _isInterruptingBallistic = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) _scrollController.jumpTo(newS);
      });
    }
  }

  /// 宽 Pane 的内部滚动范围：从起始锁定点到内部右锁定点的距离。
  ///
  /// 右锁定点让 Pane 内容右边缘对齐到 `屏宽 − 右侧锁定偏移`。
  double _paneInternalRange(int index) {
    final double rightLockedScrollExtent =
        _viewportWidth - _config.rightLockAlignmentOffset;
    final double extent = _paneItemWidths[index] - rightLockedScrollExtent;
    // 恰好等于锁定宽度时（默认 Pane）会留下浮点残差，按 0 处理
    return extent > _epsilon ? extent : 0.0;
  }

  double get _backgroundLayerWidth =>
      _measuredBackgroundLayerWidth ?? _config.backgroundLayerWidth;

  /// 把任意滚动位置归一化到 `[0, _contentCycleLength)`。
  double _wrapScroll(double scrollOffset) {
    if (_contentCycleLength <= 0) return 0.0;
    double local = scrollOffset % _contentCycleLength;
    if (local < 0) local += _contentCycleLength;
    return local;
  }

  /// 拖动时每 1px 内容位移对应的层位移。
  ///
  /// 视差因子为 `T / D`（`D = 层宽 − 4 × ⌊屏宽 / 5⌋`，T 为一轮内容行程），
  /// 所以拖动比例 = `D / T`。`D ≤ 0` 时 WP8 保留旧因子，这里回退到初值因子。
  double _parallaxRatio(double layerWidth, double initialFactor) {
    final double travel =
        layerWidth - (_viewportWidth / 5).floorToDouble() * 4.0;
    if (travel > 0 && _paneTravel > 0) return travel / _paneTravel;
    return initialFactor > 0 ? 1.0 / initialFactor : 0.0;
  }

  double get _titleParallaxRatio =>
      _parallaxRatio(_titleLayerWidth, _config.titleParallaxInitialFactor);

  double get _backgroundParallaxRatio => _parallaxRatio(
    _backgroundLayerWidth,
    _config.backgroundParallaxInitialFactor,
  );

  /// [scrollOffset] 所属的内容循环代数（WP8 内部页面索引可以越界，取模显示）。
  int _contentCycleOf(double scrollOffset) {
    if (_contentCycleLength <= 0) return 0;
    return (scrollOffset / _contentCycleLength).floor();
  }

  /// 大标题在某个 Pane 锁定点上的目标偏移。
  ///
  /// WP8 计算标题锁定比例时逐项累加 Pane 的 MaxWidth（**不含** `ContentSpacing`），
  /// 而拖动阶段按含间距的内容位移累计，因此松手时会出现 `间距 × D / T` 的修正。
  double _titleLockOffset(int paneIndex, int contentCycle) {
    final double base = -_cumulativePaneWidths[paneIndex] * _titleParallaxRatio;
    // 循环代数：每跨一轮内容，标题目标推进一个重复副本
    return base - contentCycle * _titleRepeatSpacing;
  }

  /// 背景在某个 Pane 锁定点上的目标偏移（与标题同一套规则）。
  double _backgroundLockOffset(int paneIndex, int contentCycle) {
    final double base =
        -_cumulativePaneWidths[paneIndex] * _backgroundParallaxRatio;
    return base - contentCycle * _backgroundLayerWidth;
  }

  /// 按滚动位置同步两层当前偏移（用于布局变化、标题宽度变化等重定位）。
  void _syncParallaxToScroll(double scrollOffset) {
    final int paneIndex = _paneIndexFromPosition(scrollOffset);
    final int contentCycle = _contentCycleOf(scrollOffset);
    _titleScrollOffset = _titleLockOffset(paneIndex, contentCycle);
    _backgroundScrollOffset = _backgroundLockOffset(paneIndex, contentCycle);
    _parallaxNotifier.value = PanoramaParallax(
      _titleScrollOffset,
      _backgroundScrollOffset,
    );
  }

  /// Pane 标题相对 Pane 内容的额外偏移（WP8 `CalculateHeaderPosition`）。
  ///
  /// 设 p 为 Pane 左边界、L 为左侧锁定偏移：
  /// - p > L（Pane 尚未滚到锁定位置）：偏移 = (p − L) × 0.4
  /// - p ≤ L（Pane 已滚过锁定位置）：偏移 = (L − p) / 1.18
  double _paneHeaderOffsetForScroll(int index, double scrollOffset) {
    if (!_isWidePane[index]) return 0.0;
    final double start = _paneStartLockPoints[index];
    double d = _wrapScroll(scrollOffset) - start;
    if (_contentCycleLength > 0) {
      if (d < -_contentCycleLength / 2) d += _contentCycleLength;
      if (d > _contentCycleLength / 2) d -= _contentCycleLength;
    }
    final double maxOffset = _maxPaneHeaderDisplacement(index);
    final double offset = d >= 0
        ? d * _config.paneHeaderForwardRate
        : -d * _config.paneHeaderBackwardRate;
    return offset.clamp(0.0, maxOffset);
  }

  /// Pane 标题的最大偏移：`内容宽 − 标题宽 − 右侧视差边距`。
  double _maxPaneHeaderDisplacement(int index) {
    final double headerWidth = index < _paneHeaderWidths.length
        ? _paneHeaderWidths[index]
        : 0.0;
    return math.max(
      0.0,
      _paneContentWidths[index] -
          headerWidth -
          _config.headerRightParallaxMargin,
    );
  }

  /// Pane 标题实测宽度变化时更新，并重算偏移以触发重绘。
  void _updatePaneHeaderWidth(int realIndex, double width) {
    if (realIndex < 0 || realIndex >= _paneHeaderWidths.length) return;
    if ((_paneHeaderWidths[realIndex] - width).abs() < 0.5) return;

    _paneHeaderWidths[realIndex] = width;
    if (!_scrollController.hasClients) return;

    final double s = _scrollController.position.pixels;
    _paneHeaderOffsetNotifier.value = {
      for (int i = 0; i < widget.items.length; i++)
        i: _paneHeaderOffsetForScroll(i, s),
    };
  }

  /// 大标题排版宽度变化时更新，并按新宽度重算三层视差。
  void _updateTitleTextWidth(double width) {
    if (width <= 0) return;
    if ((width - (_measuredTitleTextWidth ?? 0)).abs() < 0.5) return;

    setState(() => _measuredTitleTextWidth = width);
    if (!_scrollController.hasClients) return;

    _syncParallaxToScroll(_scrollController.position.pixels);
  }

  @override
  void initState() {
    super.initState();
    // Cache the initial config to avoid using Theme.of in initState
    final initialConfig = widget.config ?? const PanoramaConfig();
    _resolvedConfig = initialConfig;

    _scrollController = ScrollController(initialScrollOffset: 0.0);

    _paneHeaderSnapController = AnimationController(
      vsync: this,
      duration: initialConfig.snapDuration,
    );
    _paneHeaderSnapController.addListener(_onPaneHeaderSnapTick);

    _rotationController = AnimationController(
      vsync: this,
      duration: initialConfig.rotationDuration,
    );
    _translationController = AnimationController(
      vsync: this,
      duration: initialConfig.translationDuration,
    );

    _rotationTween = Tween<double>(
      begin: initialConfig.rotationStartDegrees,
      end: 0,
    );
    _rotationAnimation = _rotationTween.animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: _config.rotationCurve,
      ),
    );

    _translationTween = Tween<double>(begin: 1, end: 0);
    _translationAnimation = _translationTween.animate(
      CurvedAnimation(
        parent: _translationController,
        curve: MetroCurves.metroTranslateIn,
      ),
    );
    _translationAnimation.addListener(() {
      _translationNotifier.value = _translationAnimation.value;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 告诉可能存在的上级 Scaffold 我是个全景视图组件，不用播普通动画！
      const MetroPanoramaDetectNotification().dispatch(context);

      _rotationController.forward();
      _translationController.forward();
    });
  }

  /// 根据滚动位置推算所在 Pane 索引：找到最大的起始锁定点 <= [scrollOffset]。
  ///
  /// 吸附动画允许 1px 级的残差，且循环接缝处 -0.5px 会被折算到上一轮末尾，
  /// 因此这里对锁定点和接缝都放宽 [_lockTolerance]，避免把“第一页”认成“末页”。
  int _paneIndexFromPosition(double scrollOffset) {
    if (_paneStartLockPoints.isEmpty || widget.items.isEmpty) return 0;
    final double localS = _wrapScroll(scrollOffset);
    if (localS <= _lockTolerance ||
        _contentCycleLength - localS <= _lockTolerance) {
      return 0;
    }
    int result = 0;
    for (int i = 0; i < _paneStartLockPoints.length; i++) {
      if (_paneStartLockPoints[i] <= localS + _lockTolerance) result = i;
    }
    return result;
  }

  /// 当 Pane 索引变化时触发回调。
  void _firePageChangeIfNeeded(int newIndex) {
    if (newIndex != _currentPaneIndex) {
      _currentPaneIndex = newIndex;
      widget.onPageChange?.call(_currentPaneIndex);
    }
  }

  void _onPaneHeaderSnapTick() {
    final double raw = _paneHeaderSnapController.value;
    final double t = _config.snapCurve != null
        ? _config.snapCurve!.transform(raw)
        : raw;
    final Map<int, double> newMap = {};
    for (int i = 0; i < widget.items.length; i++) {
      final double from = _paneHeaderSnapFrom[i] ?? 0.0;
      final double to = _paneHeaderSnapTo[i] ?? 0.0;
      newMap[i] = from + t * (to - from);
    }
    _paneHeaderOffsetNotifier.value = newMap;
  }

  @override
  void dispose() {
    _ballisticInterruptTimer?.cancel();
    _paneHeaderSnapController.dispose();
    _rotationController.dispose();
    _translationController.dispose();
    _scrollController.dispose();
    _parallaxNotifier.dispose();
    _paneHeaderOffsetNotifier.dispose();
    _translationNotifier.dispose();
    super.dispose();
  }

  /// 取 [index] 这个 Pane 起始锁定点在 [pixels] 附近最近的副本。
  ///
  /// 循环滚动时同一个 Pane 会重复出现，吸附目标必须落在离手指最近的副本上。
  double _nearestPaneStart(int index, double pixels) {
    final double base = _paneStartLockPoints[index];
    if (_contentCycleLength <= 0) return base;
    final double cycles = ((pixels - base) / _contentCycleLength)
        .roundToDouble();
    return base + cycles * _contentCycleLength;
  }

  /// 滚动位置 [pixels] 下，起始于 [paneStart] 的 Pane 落在屏幕内的宽度。
  ///
  /// WP8 的定义：`max(0, min(right, 屏宽) − max(left, 0))`。
  double _visiblePaneWidth(double paneStart, int index, double pixels) {
    final double left = paneStart + _config.leftLockAlignmentOffset - pixels;
    final double right = left + _paneContentWidths[index];
    return math.max(0.0, math.min(right, _viewportWidth) - math.max(left, 0.0));
  }

  /// WP8 `LockOrTransitionPanes` / `Flicker.Invoked`：把抬手位置解析为一个锁定点。
  ///
  /// - Flick：按速度方向翻到相邻 Pane；宽 Pane 先把当前 Pane 锁到另一侧。
  /// - 普通拖动：比较前一个、当前、下一个 Pane 的可见宽度，
  ///   相邻 Pane 更宽则切过去，否则吸附当前 Pane 的边缘。
  ///
  /// 首尾按相邻处理（内部索引可以越界，显示时取模），所以从第一页往回拖
  /// 只会后退一页，不会倒放整轮内容。
  double? _resolveSnapTarget(double pixels, double velocity) {
    if (widget.items.isEmpty || _contentCycleLength <= 0) return 0.0;

    final int paneCount = widget.items.length;
    final double localS = _wrapScroll(pixels);

    // WP8 始终围绕手势开始时所在的 Pane 判断
    final int current = _paneIndexFromPosition(_dragStartPixels ?? pixels);
    final int prevIndex = (current - 1 + paneCount) % paneCount;
    final int nextIndex = (current + 1) % paneCount;
    // 当前 Pane 在手指附近的那个副本（循环时同一个 Pane 会重复出现）
    final double currentStart = _nearestPaneStart(current, pixels);

    final bool isFlick = velocity.abs() >= _config.flickVelocityThreshold;
    if (isFlick) {
      final bool forward = velocity > 0;
      if (_isWidePane[current]) {
        final double leftLock = currentStart;
        final double rightLock = leftLock + _paneInternalRange(current);
        // 宽 Pane：先把当前 Pane 锁到另一侧，再翻页
        if (forward && pixels < rightLock - _epsilon) return rightLock;
        if (!forward && pixels > leftLock + _epsilon) return leftLock;
      }
      if (paneCount <= 1) return currentStart;
      // 索引减小（倒退）进入宽 Pane 时右对齐，否则左对齐
      return forward
          ? _nearestPaneStart(nextIndex, pixels)
          : _nearestPaneStart(prevIndex, pixels) +
                _paneInternalRange(prevIndex);
    }

    // 低速停在宽 Pane 内部时保持原位
    if (velocity.abs() < _config.stoppedVelocityThreshold &&
        _isWidePane[current]) {
      final double leftLock = _paneStartLockPoints[current];
      final double rightLock = leftLock + _paneInternalRange(current);
      if (localS > leftLock + _epsilon && localS < rightLock - _epsilon) {
        return null;
      }
    }

    if (paneCount > 1) {
      final double currentVisible = _visiblePaneWidth(
        currentStart,
        current,
        pixels,
      );
      final double prevStart = _nearestPaneStart(prevIndex, pixels);
      if (_visiblePaneWidth(prevStart, prevIndex, pixels) >
          currentVisible + _epsilon) {
        // 索引减小：宽 Pane 右锁定，普通 Pane 退回左锁定
        return prevStart + _paneInternalRange(prevIndex);
      }
      final double nextStart = _nearestPaneStart(nextIndex, pixels);
      if (_visiblePaneWidth(nextStart, nextIndex, pixels) >
          currentVisible + _epsilon) {
        return nextStart;
      }
    }

    if (!_isWidePane[current]) return currentStart;
    final double rightLock = currentStart + _paneInternalRange(current);
    return pixels - currentStart <= rightLock - pixels
        ? currentStart
        : rightLock;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _recalculateLayout(constraints.maxWidth);

        return AnimatedBuilder(
          animation: Listenable.merge([
            _rotationAnimation,
            _translationAnimation,
          ]),
          builder: (context, child) {
            return Transform(
              transform: Matrix4.rotationY(
                _degreesToRadians(_rotationAnimation.value),
              ),
              origin: Offset(_rotationOriginX, 0),
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: constraints.maxHeight,
                alignment: Alignment.topLeft,
                child: child,
              ),
            );
          },
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: _buildPanoramaContent(constraints.maxHeight),
          ),
        );
      },
    );
  }

  Widget _buildPanoramaContent(double parentHeight) {
    // 无限循环仅在页面数 > 1 时启用
    bool isInfinite = widget.items.length > 1;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 大标题和背景
        Positioned.fill(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _parallaxNotifier,
              _translationNotifier,
            ]),
            builder: (context, _) {
              final data = _parallaxNotifier.value;
              final tv = _translationNotifier.value;

              double renderT =
                  (data.titleOffset % _titleRepeatSpacing) -
                  _titleRepeatSpacing;
              if (renderT <= -_titleRepeatSpacing) {
                renderT += _titleRepeatSpacing;
              }

              double renderB =
                  (data.backgroundOffset % _backgroundLayerWidth) -
                  _backgroundLayerWidth;
              if (renderB <= -_backgroundLayerWidth) {
                renderB += _backgroundLayerWidth;
              }

              final double bgEntryOffset =
                  tv * _config.backgroundEntryTranslate;
              final double titleEntryOffset = tv * _config.titleEntryTranslate;

              final topPadding = MediaQuery.of(context).padding.top;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (widget.background != null)
                    Positioned(
                      left: 0,
                      top: 0,
                      width: _backgroundLayerWidth * 2,
                      height: parentHeight,
                      child: Transform.translate(
                        offset: Offset(bgEntryOffset, 0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (int i = 0; i < 2; i++)
                              Positioned(
                                left: renderB + i * _backgroundLayerWidth,
                                top: 0,
                                width: i == 0 ? null : _backgroundLayerWidth,
                                height: parentHeight,
                                child: i == 0
                                    ? _MeasureSize(
                                        onChange: (size) {
                                          if (size.width <= 0) return;
                                          if ((size.width -
                                                      _backgroundLayerWidth)
                                                  .abs() <=
                                              0.5) {
                                            return;
                                          }
                                          setState(() {
                                            _measuredBackgroundLayerWidth =
                                                size.width;
                                          });
                                        },
                                        child: widget.background,
                                      )
                                    : widget.background ?? const SizedBox(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  // 大标题层（PanoTitleLayer）：top = −75，文本再相对它 +41
                  Positioned(
                    top: _config.titleLayerTop + topPadding,
                    left: 0,
                    height: _config.titleAreaHeight,
                    right: -_config.titleOverflowRight,
                    child: Transform.translate(
                      offset: Offset(titleEntryOffset, 0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (int i = 0; i < 2; i++)
                            Positioned(
                              left:
                                  renderT +
                                  i * _titleRepeatSpacing +
                                  _config.titleTextLeftMargin,
                              top: _config.titleTextTop,
                              // 不约束宽度：大标题按排版宽度整条显示，
                              // 实测值同时决定视差行程 D。
                              child: _MeasureSize(
                                onChange: (Size size) =>
                                    _updateTitleTextWidth(size.width),
                                child: DefaultTextStyle.merge(
                                  style: Theme.of(context)
                                      .extension<MetroTitleTextTheme>()
                                      ?.titleTextStyle,
                                  child: widget.title,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        // 内容区
        Positioned.fill(
          child: ValueListenableBuilder<double>(
            valueListenable: _translationNotifier,
            builder: (context, tv, child) => Transform.translate(
              offset: Offset(tv * _config.contentEntryTranslate, 0),
              child: child,
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollStartNotification) {
                  if (notification.dragDetails != null) {
                    _paneHeaderSnapController.stop();
                    _dragStartPixels = notification.metrics.pixels;
                    // 计时器仍在运行 → 在归位动画期间被手指打断
                    if (_ballisticInterruptTimer != null) {
                      debugPrint('Ballistic Interrupted');
                      _isInterruptingBallistic = true;
                      _ballisticInterruptTimer!.cancel();
                      _ballisticInterruptTimer = null;
                    }
                    _isDragging = true;
                    _isBallistic = false;
                  }
                } else if (notification is UserScrollNotification) {
                  if (notification.direction == ScrollDirection.idle) {
                    _isDragging = false;
                  } else {
                    if (_dragStartPixels == null) {
                      _dragStartPixels = notification.metrics.pixels;
                    }
                    if (_isBallistic) {
                      _isInterruptingBallistic = true;
                    }
                    _isDragging = true;
                    _isBallistic = false;
                  }
                } else if (notification is ScrollEndNotification) {
                  final bool wasBallistic = _isBallistic;
                  _isBallistic = false;
                  _isDragging = false;
                  _isInterruptingBallistic = false;
                  _dragStartPixels = null;
                  final double S = notification.metrics.pixels;
                  // 慢速停止（无归位动画）时：此处才触发页面变化通知
                  if (!wasBallistic) {
                    _firePageChangeIfNeeded(_paneIndexFromPosition(S));
                  }
                  // 大标题 / 背景：归位结束时落到目标偏移（下一次拖动从该值继续累计）
                  if (wasBallistic) {
                    _titleScrollOffset = _targetTitleOffset;
                    _backgroundScrollOffset = _targetBackgroundOffset;
                    _parallaxNotifier.value = PanoramaParallax(
                      _titleScrollOffset,
                      _backgroundScrollOffset,
                    );
                  }
                  // Pane 标题：补间到理想位置
                  _paneHeaderSnapFrom = Map.from(
                    _paneHeaderOffsetNotifier.value,
                  );
                  _paneHeaderSnapTo = {
                    for (int i = 0; i < widget.items.length; i++)
                      i: _paneHeaderOffsetForScroll(i, S),
                  };
                  _paneHeaderSnapController.forward(from: 0.0);
                } else if (notification is ScrollUpdateNotification) {
                  final double dx = notification.scrollDelta ?? 0.0;
                  if (_isDragging && !_isBallistic) {
                    // 大标题 / 背景：按拖动增量累计（含间距），与锁定目标口径不同
                    _titleScrollOffset -= dx * _titleParallaxRatio;
                    _backgroundScrollOffset -= dx * _backgroundParallaxRatio;
                    _parallaxNotifier.value = PanoramaParallax(
                      _titleScrollOffset,
                      _backgroundScrollOffset,
                    );

                    // Pane 标题
                    if (_isInterruptingBallistic) {
                      // 惯性中被手指干预 → 按固定速率跟随手指
                      final Map<int, double> newMap = Map.from(
                        _paneHeaderOffsetNotifier.value,
                      );
                      for (int i = 0; i < widget.items.length; i++) {
                        if (_isWidePane[i]) {
                          final double maxOffset = _maxPaneHeaderDisplacement(
                            i,
                          );
                          newMap[i] =
                              ((newMap[i] ?? 0.0) +
                                      dx * _config.paneHeaderInterruptRate)
                                  .clamp(0.0, maxOffset);
                        }
                      }
                      _paneHeaderOffsetNotifier.value = newMap;
                    } else {
                      // 直接计算 WP8 公式给出的理想位置
                      final Map<int, double> newMap = {};
                      for (int i = 0; i < widget.items.length; i++) {
                        newMap[i] = _paneHeaderOffsetForScroll(
                          i,
                          notification.metrics.pixels,
                        );
                      }
                      _paneHeaderOffsetNotifier.value = newMap;
                    }
                  } else if (_isBallistic) {
                    final double S = notification.metrics.pixels;
                    final double distance = _targetS - _releaseS;
                    final double p = distance.abs() > 0.001
                        ? (S - _releaseS) / distance
                        : 1.0;
                    // 松手目标由所选 Pane 的锁定比例单独计算，
                    // 目标可能在当前位置右侧（视觉上的“向右修正”）。
                    _titleScrollOffset =
                        _releaseTitleOffset +
                        p * (_targetTitleOffset - _releaseTitleOffset);
                    _backgroundScrollOffset =
                        _releaseBackgroundOffset +
                        p *
                            (_targetBackgroundOffset -
                                _releaseBackgroundOffset);
                    _parallaxNotifier.value = PanoramaParallax(
                      _titleScrollOffset,
                      _backgroundScrollOffset,
                    );

                    final Map<int, double> newMap = {};
                    for (int i = 0; i < widget.items.length; i++) {
                      if (_isWidePane[i]) {
                        final double releaseOffset =
                            _releasePaneHeaderOffsets[i] ??
                            _paneHeaderOffsetForScroll(i, _releaseS);
                        final double idealOffset = _paneHeaderOffsetForScroll(
                          i,
                          _targetS,
                        );
                        newMap[i] =
                            releaseOffset + p * (idealOffset - releaseOffset);
                      } else {
                        newMap[i] = 0.0;
                      }
                    }
                    _paneHeaderOffsetNotifier.value = newMap;
                  }
                }
                return false;
              },
              child: CustomScrollView(
                key: ValueKey(_defaultPaneWidth),
                clipBehavior: Clip.none,
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                scrollBehavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: const <PointerDeviceKind>{
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.unknown,
                  },
                ),
                center: const ValueKey('center_sliver'),
                physics: widget.items.length <= 1
                    ? const NeverScrollableScrollPhysics()
                    : PanoramaScrollPhysics(
                        isInfinite: isInfinite,
                        resolveTarget: _resolveSnapTarget,
                        snapCurve: _config.snapCurve,
                        snapDuration: _config.snapDuration,
                        onTargetCalculated: (target) {
                          _targetS = target;
                          _releaseS = _scrollController.position.pixels;
                          _releaseTitleOffset = _titleScrollOffset;
                          _releaseBackgroundOffset = _backgroundScrollOffset;
                          // 松手目标：所选 Pane 的标题/背景锁定比例
                          final int targetPane = _paneIndexFromPosition(target);
                          final int targetCycle = _contentCycleOf(target);
                          _targetTitleOffset = _titleLockOffset(
                            targetPane,
                            targetCycle,
                          );
                          _targetBackgroundOffset = _backgroundLockOffset(
                            targetPane,
                            targetCycle,
                          );
                          _releasePaneHeaderOffsets = Map.from(
                            _paneHeaderOffsetNotifier.value,
                          );
                          _isBallistic = true;
                          // 启动计时器：归位动画时长内若手指再次按下，视为打断惯性
                          _ballisticInterruptTimer?.cancel();
                          _ballisticInterruptTimer = Timer(
                            _config.snapDuration,
                            () => _ballisticInterruptTimer = null,
                          );
                          // 手指抬起时立即通知页面变化，无需等动画结束
                          _firePageChangeIfNeeded(
                            _paneIndexFromPosition(target),
                          );
                        },
                      ),
                slivers: [
                  if (isInfinite)
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        int realIndex =
                            (widget.items.length -
                                1 -
                                (index % widget.items.length)) %
                            widget.items.length;
                        return _buildItemWidget(
                          widget.items[realIndex],
                          realIndex,
                        );
                      }),
                    ),
                  SliverList(
                    key: const ValueKey('center_sliver'),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      int realIndex = isInfinite
                          ? index % widget.items.length
                          : index;
                      return _buildItemWidget(
                        widget.items[realIndex],
                        realIndex,
                      );
                    }, childCount: isInfinite ? null : widget.items.length),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 影子页面，在播放动画的时候默认显示在做左侧，只在页面数量>1的时候显示
        if (isInfinite)
          Positioned(
            top: 0,
            left: 0,
            width: _paneItemWidths[widget.items.length - 1],
            bottom: 0,
            child: IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: _translationNotifier,
                builder: (context, tv, child) => Transform.translate(
                  offset: Offset(
                    tv * _config.contentEntryTranslate -
                        _paneItemWidths[widget.items.length - 1],
                    0,
                  ),
                  child: child!,
                ),
                child: _buildItemWidget(
                  widget.items.last,
                  widget.items.length - 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemWidget(MetroPanoramaItem item, int realIndex) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.transparent,
      width: _paneItemWidths[realIndex],
      padding: EdgeInsets.only(
        left: _config.leftLockAlignmentOffset,
        top: _config.paneTopPadding + topPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<Map<int, double>>(
            valueListenable: _paneHeaderOffsetNotifier,
            builder: (context, dxMap, child) {
              final double dx = _isWidePane[realIndex]
                  ? dxMap[realIndex] ?? 0.0
                  : 0.0;
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: _MeasureSize(
              onChange: (size) => _updatePaneHeaderWidth(realIndex, size.width),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  fontWeight: FontWeight.w200,
                  fontSize: _config.paneHeaderFontSize,
                  //color: Colors.white,
                ),
                child: item.title,
              ),
            ),
          ),
          const SizedBox(height: 26 * 0.8),
          Expanded(child: item.child),
        ],
      ),
    );
  }
}
