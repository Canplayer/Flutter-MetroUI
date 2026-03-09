import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/metro_theme_extensions.dart';
import 'package:metro_ui/page_scaffold.dart';

class ParallaxData {
  final double tOffset;
  final double bOffset;
  const ParallaxData(this.tOffset, this.bOffset);
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
      BuildContext context, _MeasureSizeRenderObject renderObject) {
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

/// 全景组件的全部动画与布局参数，修改默认值即可调整视觉效果。
class PanoramaConfig {
  // ── 滚动物理 ─────────────────────────────────────────────────────────────────
  /// 低于此速度（px/s）视为主动停止，长页面内不触发吸附。
  final double stoppedVelocityThreshold;

  /// 抬手速度乘以此系数预测 snap 目标位置（越大飞得越远）。
  final double snapVelocityScale;

  // ── 进场动画 ─────────────────────────────────────────────────────────────────
  /// 3D 旋转入场动画时长。
  final Duration rotationDuration;

  /// 平移入场动画时长。
  final Duration translationDuration;

  /// 旋转入场的起始角度（度，负值=向右倾倒）。
  final double rotationStartDegrees;

  /// 背景进场时的最大平移距离（像素，tv 从 1→0）。
  final double bgEntryTranslate;

  /// 大标题进场时的最大平移距离（像素）。
  final double titleEntryTranslate;

  /// 内容区进场时的最大平移距离（像素）。
  final double contentEntryTranslate;

  // ── 3D 透视旋转 ───────────────────────────────────────────────────────────────
  /// 透视旋转的 X 轴原点（像素，负值=在组件左侧）。
  final double pivotX;

  // ── 布局 ─────────────────────────────────────────────────────────────────────
  /// 大标题容器宽度（像素）。
  final double titleContainerWidth;

  /// 大标题循环间距的额外余量（像素，加在 titleContainerWidth + parentWidth 之后）。
  final double titleSpacingExtra;

  /// 背景图案单元宽度（像素）。
  final double bgPatternWidth;

  /// 大标题区域相对顶部偏移（像素，负值=向上溢出）。
  final double titleAreaTop;

  /// 大标题区域高度（像素）。
  final double titleAreaHeight;

  /// 大标题区域向右溢出的距离（像素，会被转为负数 right 值）。
  final double titleOverflowRight;

  /// 大标题在 Stack 内的左边距（像素）。
  final double titleLeftMargin;

  /// 每个 item 容器内边距-左（像素）。
  final double itemPaddingLeft;

  /// 每个 item 容器内边距-上（像素）。
  final double itemPaddingTop;

  /// 第二页露出的大小（像素），宽页面阈值 = parentWidth - nextPagePeekSize。
  final double nextPagePeekSize;

  // ── 归位动画 ──────────────────────────────────────────────────────────────────
  /// 归位动画曲线，为 null 时使用默认弹簧物理（[ScrollSpringSimulation]）。
  final Curve? snapCurve;

  /// 归位动画时长，仅在 [snapCurve] 不为 null 时生效。
  final Duration snapDuration;

  // ── 视差拖拽速率 ──────────────────────────────────────────────────────────────
  /// 手指拖拽时大标题视差速率倍数（越大移动越快）。
  final double bigTitleDragSpeedDivisor;

  /// 手指拖拽时背景视差速率倍数（越大移动越快）。
  final double bgDragSpeedDivisor;

  // ── 长页面小标题行为 ───────────────────────────────────────────────────────────
  /// 规则 1：page 向右滚动时小标题偏移的速度倍率（>1 比 page 快）。
  final double subtitleForwardSpeed;

  /// 规则 2：page 切入飞入速率。
  final double subtitleBackwardSpeed;

  /// 规则 3：惯性被手指干预时小标题跟随手指的速度倍率。
  final double subtitleInterruptSpeed;

  // ── 字体 ─────────────────────────────────────────────────────────────────────
  /// 长页面小标题字号。
  final double subtitleFontSize;

  const PanoramaConfig({
    this.stoppedVelocityThreshold = 200.0,
    this.snapVelocityScale = 0.2,
    this.snapCurve,
    this.snapDuration = const Duration(milliseconds: 350),
    this.rotationDuration = const Duration(milliseconds: 500),
    this.translationDuration = const Duration(milliseconds: 1000),
    this.rotationStartDegrees = -86.5,
    this.bgEntryTranslate = 720.0,
    this.titleEntryTranslate = 1216.0,
    this.contentEntryTranslate = 960.0,
    this.pivotX = -200.0,
    this.titleContainerWidth = 500.0,
    this.titleSpacingExtra = 100.0,
    this.bgPatternWidth = 1000.0,
    this.titleAreaTop = -40 * 0.8,
    this.titleAreaHeight = 150.0,
    this.titleOverflowRight = 2000.0,
    this.titleLeftMargin = 13.0 * 0.8,
    this.itemPaddingLeft = 22 * 0.8,
    this.itemPaddingTop = 188 * 0.8,
    this.nextPagePeekSize = 47.0 * 0.8,
    this.bigTitleDragSpeedDivisor = 0.5,
    this.bgDragSpeedDivisor = 0.333,
    this.subtitleForwardSpeed = 0.8,
    this.subtitleBackwardSpeed = 0.5,
    this.subtitleInterruptSpeed = 0.7,
    this.subtitleFontSize = 66.0 * 0.8,
  });
}

class MetroPanoramaItem {
  final Widget title;
  final Widget child;
  final double width;

  MetroPanoramaItem({
    required this.title,
    required this.child,
    this.width = 0,
  });
}

typedef TargetCallback = void Function(double target);
typedef DoubleCallback = double? Function();

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
  })  : _start = start,
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
  final List<double> snapPoints;
  final double cycleLength;
  final bool isInfinite;
  final TargetCallback? onTargetCalculated;
  final DoubleCallback? getDragStartPixels;

  /// 归位动画曲线，为 null 时退回到 [ScrollSpringSimulation]。
  final Curve? snapCurve;

  /// 归位动画时长，仅在 [snapCurve] 不为 null 时生效。
  final Duration snapDuration;

  /// 仅包含每个 item 起始位置的吸附点（页间导航点）。
  /// 与 [snapPoints] 对比后可判断某个点是否属于长页面内部滚动范围。
  final List<double> pageSnapPoints;
  final double stoppedVelocityThreshold;

  const PanoramaScrollPhysics({
    required this.snapPoints,
    required this.cycleLength,
    required this.isInfinite,
    required this.pageSnapPoints,
    this.stoppedVelocityThreshold = 200.0,
    this.onTargetCalculated,
    this.getDragStartPixels,
    this.snapCurve,
    this.snapDuration = const Duration(milliseconds: 350),
    super.parent,
  });

  @override
  PanoramaScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return PanoramaScrollPhysics(
      snapPoints: snapPoints,
      cycleLength: cycleLength,
      isInfinite: isInfinite,
      pageSnapPoints: pageSnapPoints,
      stoppedVelocityThreshold: stoppedVelocityThreshold,
      onTargetCalculated: onTargetCalculated,
      getDragStartPixels: getDragStartPixels,
      snapCurve: snapCurve,
      snapDuration: snapDuration,
      parent: buildParent(ancestor),
    );
  }

  /// 判断 [localPixels]（已归一化到 [0, cycleLength) 的坐标）是否处于
  /// 某个长页面的内部滚动范围内（即介于页面起始 snap 与页面内部 snap 之间）。
  bool _isWithinLongItemRange(double localPixels) {
    // 找到 <= localPixels 的最大页面起始 snap
    double lowerPageSnap = double.negativeInfinity;
    for (final double sp in pageSnapPoints) {
      if (sp <= localPixels && sp > lowerPageSnap) {
        lowerPageSnap = sp;
      }
    }
    if (lowerPageSnap == double.negativeInfinity) return false;

    // 找到紧跟 lowerPageSnap 之后的第一个 snap 点
    double nextSnap = double.infinity;
    for (final double sp in snapPoints) {
      if (sp > lowerPageSnap && sp < nextSnap) {
        nextSnap = sp;
      }
    }
    if (nextSnap == double.infinity) return false;

    // 若该 snap 点不是页面起始 snap，说明它是长页面内部的结束 snap
    bool nextIsPageSnap = false;
    for (final double ps in pageSnapPoints) {
      if ((ps - nextSnap).abs() < 0.01) {
        nextIsPageSnap = true;
        break;
      }
    }

    return !nextIsPageSnap &&
        localPixels > lowerPageSnap &&
        localPixels < nextSnap;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = toleranceFor(position);

    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    double pixels = position.pixels;
    double startPixels = pixels;
    if (getDragStartPixels != null && getDragStartPixels!() != null) {
      startPixels = getDragStartPixels!()!;
    }

    List<double> validSnaps = [];
    if (cycleLength > 0) {
      double range = (pixels - startPixels).abs() + cycleLength * 2;
      double center = startPixels;
      if (isInfinite) {
        int minCycle = ((center - range) / cycleLength).floor() - 1;
        int maxCycle = ((center + range) / cycleLength).ceil() + 1;
        for (int i = minCycle; i <= maxCycle; i++) {
          for (double sp in snapPoints) {
            validSnaps.add(i * cycleLength + sp);
          }
        }
        validSnaps.sort();
      } else {
        validSnaps.addAll(snapPoints);
        validSnaps.sort();
      }
    } else {
      validSnaps = [0.0];
    }

    double startSnap = startPixels;
    if (validSnaps.isNotEmpty) {
      double minDiff = double.infinity;
      for (double p in validSnaps) {
        double d = (p - startPixels).abs();
        if (d < minDiff) {
          minDiff = d;
          startSnap = p;
        }
      }
    }

    double nextSnap = startSnap;
    for (double p in validSnaps) {
      if (p > startSnap + 1.0) {
        nextSnap = p;
        break;
      }
    }

    double prevSnap = startSnap;
    for (int i = validSnaps.length - 1; i >= 0; i--) {
      if (validSnaps[i] < startSnap - 1.0) {
        prevSnap = validSnaps[i];
        break;
      }
    }

    double targetSnap;
    if (velocity > stoppedVelocityThreshold) {
      targetSnap = nextSnap;
    } else if (velocity < -stoppedVelocityThreshold) {
      targetSnap = prevSnap;
    } else {
      targetSnap = pixels;
      if (validSnaps.isNotEmpty) {
        double minDiff = double.infinity;
        for (double p in validSnaps) {
          double d = (p - pixels).abs();
          if (d < minDiff) {
            minDiff = d;
            targetSnap = p;
          }
        }
      }
    }

    if (targetSnap > nextSnap) targetSnap = nextSnap;
    if (targetSnap < prevSnap) targetSnap = prevSnap;

    if (!isInfinite) {
      if (targetSnap < position.minScrollExtent) {
        targetSnap = position.minScrollExtent;
      }
      if (targetSnap > position.maxScrollExtent) {
        targetSnap = position.maxScrollExtent;
      }
    }

    if (velocity.abs() < stoppedVelocityThreshold && cycleLength > 0) {
      if (pixels >= prevSnap - 1.0 && pixels <= nextSnap + 1.0) {
        double localPixels = pixels;
        if (isInfinite) {
          localPixels = pixels % cycleLength;
          if (localPixels < 0) localPixels += cycleLength;
        }
        if (_isWithinLongItemRange(localPixels)) {
          return null;
        }
      }
    }

    if ((targetSnap - pixels).abs() < tolerance.distance) {
      return null;
    }

    if (onTargetCalculated != null) {
      onTargetCalculated!(targetSnap);
    }

    if (snapCurve != null) {
      return _CurvedScrollSimulation(
        start: pixels,
        end: targetSnap,
        duration: snapDuration,
        curve: snapCurve!,
        tolerance: tolerance,
      );
    }

    // 将 initial velocity 设为 0，防止由于抬手速度过大导致弹簧过冲（即到达下一页时的回弹现象）
    return ScrollSpringSimulation(
      spring,
      pixels,
      targetSnap,
      0.0,
      tolerance: tolerance,
    );
  }
}

class MetroPanorama extends StatefulWidget {
  final Widget title;
  final Widget background;
  final List<MetroPanoramaItem> items;
  final ValueChanged<int>? onPageChange;
  final PanoramaConfig config;

  const MetroPanorama({
    super.key,
    required this.title,
    required this.background,
    required this.items,
    this.onPageChange,
    this.config = const PanoramaConfig(),
  });

  @override
  State<MetroPanorama> createState() => _MetroPanoramaState();
}

class _MetroPanoramaState extends State<MetroPanorama>
    with TickerProviderStateMixin {
  static const double _pi = 3.1415926535897932;
  static double _degreesToRadians(double degrees) => degrees * _pi / 180;
  double get _pivot => widget.config.pivotX;

  late AnimationController _rotationController;
  late AnimationController _translationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _translationAnimation;

  late ScrollController _scrollController;

  final ValueNotifier<ParallaxData> _parallaxNotifier =
      ValueNotifier<ParallaxData>(const ParallaxData(0.0, 0.0));
  final ValueNotifier<Map<int, double>> _itemDxNotifier =
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
  double _releaseT = 0.0;
  double _releaseB = 0.0;
  Map<int, double> _releaseItemDx = {};

  /// 小标题归位补间动画控制器。
  late AnimationController _subtitleSnapController;
  Map<int, double> _subtitleSnapFrom = {};
  Map<int, double> _subtitleSnapTo = {};

  double get _titleContainerWidth => widget.config.titleContainerWidth;
  double get _bgPatternWidth => widget.config.bgPatternWidth;
  double _titleSpacing = 1500.0;

  // ── 布局派生值（由 _recalculateLayout 统一维护）───────────────────────────────
  /// 普通页面的标准宽度 = parentWidth - nextPagePeekSize。
  /// 页面宽度 >= 此值即可填满可视区（留出 peek 露出区）。
  double _pageWidth = 0.0;

  /// 有效页面数：宽页面（首尾都可归位）算 2，普通页面算 1。
  int _effectivePageCount = 0;

  /// 每个 item 的实际渲染宽度（已钳制最小为 _pageWidth）。
  List<double> _itemWidths = [];

  /// 每个 item 是否为宽页面。
  List<bool> _isWideItem = [];

  /// 吸附点（包括宽页面的内部吸附点）。
  final List<double> _snapPoints = [];

  /// 仅页面起始位置的吸附点。
  final List<double> _pageSnapPoints = [];
  List<double> _titleWidths = [];
  double _cycleLength = 0;
  int _currentPageIndex = 0;

  /// 根据 parentWidth 和 config 统一计算所有布局派生值。
  /// 仅当 pageWidth 发生变化时才重新计算，并在非首次构建时将滚动位置校正到当前页。
  void _recalculateLayout(double parentWidth) {
    final double newPageWidth = parentWidth - widget.config.nextPagePeekSize;
    final bool isFirstBuild = _cycleLength == 0;
    if (!isFirstBuild && newPageWidth == _pageWidth) return;

    if (_titleWidths.length != widget.items.length) {
      final List<double> next = List<double>.filled(widget.items.length, 0.0);
      for (int i = 0; i < _titleWidths.length && i < next.length; i++) {
        next[i] = _titleWidths[i];
      }
      _titleWidths = next;
    }

    _pageWidth = newPageWidth;
    _itemWidths = List<double>.generate(widget.items.length, (i) {
      final double raw = widget.items[i].width;
      return raw > _pageWidth ? raw : _pageWidth;
    });
    _isWideItem = List<bool>.generate(
        widget.items.length, (i) => widget.items[i].width > _pageWidth);

    _snapPoints.clear();
    _pageSnapPoints.clear();
    _effectivePageCount = 0;
    double current = 0;
    for (int i = 0; i < widget.items.length; i++) {
      _snapPoints.add(current);
      _pageSnapPoints.add(current);
      if (_isWideItem[i]) {
        _snapPoints.add(current + _itemWidths[i] - _pageWidth);
        _effectivePageCount += 2;
      } else {
        _effectivePageCount++;
      }
      current += _itemWidths[i];
    }
    _cycleLength = current;

    if (!isFirstBuild) {
      // 窗口变化：跳回当前页起始吸附点
      final double newS = _pageSnapPoints[
          _currentPageIndex.clamp(0, _pageSnapPoints.length - 1)];
      _parallaxNotifier.value = ParallaxData(
          _getIdealT(newS, parentWidth), _getIdealB(newS, parentWidth));
      _itemDxNotifier.value = {
        for (int i = 0; i < widget.items.length; i++)
          i: _getIdealItemDx(i, newS)
      };
      _isDragging = false;
      _isBallistic = false;
      _isInterruptingBallistic = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) _scrollController.jumpTo(newS);
      });
    }
  }

  // 当宽页面小标题的实际宽度发生变化时调用，更新 _titleWidths 并重置小标题偏移以触发重绘。
  void _updateTitleWidth(int realIndex, double width) {
    if (realIndex < 0 || realIndex >= _titleWidths.length) return;
    if ((_titleWidths[realIndex] - width).abs() < 0.5) return;

    _titleWidths[realIndex] = width;
    if (!_scrollController.hasClients) return;

    final double s = _scrollController.position.pixels;
    _itemDxNotifier.value = {
      for (int i = 0; i < widget.items.length; i++) i: _getIdealItemDx(i, s)
    };
  }

  // 计算宽页面小标题的最大偏移（即右边界对齐时的偏移），以便在 _getIdealItemDx 中钳制小标题偏移。
  double _getMaxTitleDx(int realIndex) {
    final double fallback =
        (_itemWidths[realIndex] - _pageWidth).clamp(0.0, double.infinity);
    final double titleWidth =
        realIndex < _titleWidths.length ? _titleWidths[realIndex] : 0.0;
    if (titleWidth <= 0) return fallback;

    return (_itemWidths[realIndex] - widget.config.itemPaddingLeft - titleWidth)
        .clamp(0.0, double.infinity);
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController(initialScrollOffset: 0.0);

    _subtitleSnapController = AnimationController(
      vsync: this,
      duration: widget.config.snapDuration,
    );
    _subtitleSnapController.addListener(_onSubtitleSnapTick);

    _rotationController = AnimationController(
      vsync: this,
      duration: widget.config.rotationDuration,
    );
    _translationController = AnimationController(
      vsync: this,
      duration: widget.config.translationDuration,
    );

    _rotationAnimation =
        Tween<double>(begin: widget.config.rotationStartDegrees, end: 0)
            .animate(CurvedAnimation(
      parent: _rotationController,
      curve: MetroCurves.panoramaRotateIn,
    ));

    _translationAnimation =
        Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(
      parent: _translationController,
      curve: MetroCurves.panoramaTranslateIn,
    ));
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

  /// 根据绝对滚动位置 [S] 推算所在页面索引。
  /// 使用 _pageSnapPoints（页面起始点）：找到最大的 pageSnapPoint <= localS。
  int _pageIndexFromPosition(double S) {
    if (_pageSnapPoints.isEmpty || widget.items.isEmpty) return 0;
    double localS = _cycleLength > 0 ? S % _cycleLength : S;
    if (localS < 0) localS += _cycleLength;
    int result = 0;
    for (int i = 0; i < _pageSnapPoints.length; i++) {
      if (_pageSnapPoints[i] <= localS + 0.5) result = i;
    }
    return result;
  }

  // 当页面索引发生变化时触发回调。
  void _firePageChangeIfNeeded(int newIndex) {
    if (newIndex != _currentPageIndex) {
      _currentPageIndex = newIndex;
      widget.onPageChange?.call(_currentPageIndex);
    }
  }

  void _onSubtitleSnapTick() {
    final double raw = _subtitleSnapController.value;
    final double t = widget.config.snapCurve != null
        ? widget.config.snapCurve!.transform(raw)
        : raw;
    Map<int, double> newMap = {};
    for (int i = 0; i < widget.items.length; i++) {
      double from = _subtitleSnapFrom[i] ?? 0.0;
      double to = _subtitleSnapTo[i] ?? 0.0;
      newMap[i] = from + t * (to - from);
    }
    _itemDxNotifier.value = newMap;
  }

  @override
  void dispose() {
    _ballisticInterruptTimer?.cancel();
    _subtitleSnapController.dispose();
    _rotationController.dispose();
    _translationController.dispose();
    _scrollController.dispose();
    _parallaxNotifier.dispose();
    _itemDxNotifier.dispose();
    _translationNotifier.dispose();
    super.dispose();
  }

  // 获取大标题的理想偏移位置
  double _getIdealT(double S, double parentWidth) {
    if (_cycleLength == 0 || _titleContainerWidth <= parentWidth) return 0.0;
    int cycle = (S / _cycleLength).floor();
    double localS = S - cycle * _cycleLength;
    double sLast = _snapPoints.isEmpty ? 0 : _snapPoints.last;

    double targetWidth = _titleContainerWidth;
    double tLoc;
    if (localS <= sLast && sLast > 0) {
      tLoc = -(targetWidth - parentWidth) * (localS / sLast);
    } else if (sLast > 0) {
      double p = (localS - sLast) / (_cycleLength - sLast);
      double tStart = -(targetWidth - parentWidth);
      double tEnd = -_titleSpacing;
      tLoc = tStart + p * (tEnd - tStart);
    } else {
      tLoc = 0;
    }
    return tLoc - cycle * _titleSpacing;
  }

  // 获取背景的理想偏移位置
  double _getIdealB(double S, double parentWidth) {
    if (_cycleLength == 0) return 0.0;
    int cycle = (S / _cycleLength).floor();
    double localS = S - cycle * _cycleLength;
    double sLast = _snapPoints.isEmpty ? 0 : _snapPoints.last;

    double bLoc;
    if (localS <= sLast && sLast > 0) {
      bLoc = -(_bgPatternWidth - parentWidth) * (localS / sLast);
    } else if (sLast > 0) {
      double p = (localS - sLast) / (_cycleLength - sLast);
      double bStart = -(_bgPatternWidth - parentWidth);
      double bEnd = -_bgPatternWidth;
      bLoc = bStart + p * (bEnd - bStart);
    } else {
      bLoc = 0;
    }
    return bLoc - cycle * _bgPatternWidth;
  }

  // 获取小标题的理想偏移位置
  double _getIdealItemDx(int realIndex, double S) {
    if (!_isWideItem[realIndex]) return 0.0;
    // _pageSnapPoints[realIndex] 即为该 item 的起始偏移，无需循环累加
    final double pageStart = _pageSnapPoints[realIndex];
    final double maxDx = _getMaxTitleDx(realIndex);
    double cycleS = _cycleLength > 0 ? S % _cycleLength : 0;
    if (cycleS < 0) cycleS += _cycleLength;
    double d = cycleS - pageStart;
    if (_cycleLength > 0) {
      if (d < -_cycleLength / 2) d += _cycleLength;
      if (d > _cycleLength / 2) d -= _cycleLength;
    }
    // 规则1：d>=0 时，小标题偏移 = d × subtitleForwardSpeed，封顶 maxDx（右边界对齐）
    //        speed=1 时偏移量与滚动量完全一致，小标题看起来固定在原位。
    // 规则2：d<0  时，小标题偏移 = |d| × subtitleBackwardSpeed（更慢的分离速率）
    final double titleDx = d >= 0
        ? (d * widget.config.subtitleForwardSpeed).clamp(0.0, maxDx)
        : (-d) * widget.config.subtitleBackwardSpeed;
    return titleDx.clamp(0.0, maxDx);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _recalculateLayout(constraints.maxWidth);
        _titleSpacing = _titleContainerWidth +
            constraints.maxWidth +
            widget.config.titleSpacingExtra;

        return AnimatedBuilder(
          animation:
              Listenable.merge([_rotationAnimation, _translationAnimation]),
          builder: (context, child) {
            return Transform(
              transform: Matrix4.rotationY(
                  _degreesToRadians(_rotationAnimation.value)),
              origin: Offset(_pivot, 0),
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
            child: _buildPanoramaContent(
                constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }

  Widget _buildPanoramaContent(double parentWidth, double parentHeight) {
    // 无限循环仅在页面数 > 1 时启用
    bool isInfinite = widget.items.length > 1;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 大标题和背景
        Positioned.fill(
          child: AnimatedBuilder(
            animation:
                Listenable.merge([_parallaxNotifier, _translationNotifier]),
            builder: (context, _) {
              final data = _parallaxNotifier.value;
              final tv = _translationNotifier.value;

              double renderT = (data.tOffset % _titleSpacing) - _titleSpacing;
              if (renderT <= -_titleSpacing) renderT += _titleSpacing;

              double renderB =
                  (data.bOffset % _bgPatternWidth) - _bgPatternWidth;
              if (renderB <= -_bgPatternWidth) renderB += _bgPatternWidth;

              final double bgEntryOffset = tv * widget.config.bgEntryTranslate;
              final double titleEntryOffset =
                  tv * widget.config.titleEntryTranslate;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: _bgPatternWidth * 4,
                    height: parentHeight,
                    child: Transform.translate(
                      offset: Offset(bgEntryOffset, 0),
                      child: Stack(clipBehavior: Clip.none, children: [
                        for (int i = 0; i < 4; i++)
                          Positioned(
                            left: renderB + i * _bgPatternWidth,
                            top: 0,
                            width: _bgPatternWidth,
                            height: parentHeight,
                            child: widget.background,
                          ),
                      ]),
                    ),
                  ),
                  Positioned(
                    top: widget.config.titleAreaTop,
                    left: 0,
                    height: widget.config.titleAreaHeight,
                    right: -widget.config.titleOverflowRight,
                    child: Transform.translate(
                      offset: Offset(titleEntryOffset, 0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (int i = 0; i < 2; i++)
                            Positioned(
                              left: renderT +
                                  i * _titleSpacing +
                                  widget.config.titleLeftMargin,
                              top: 0,
                              child: SizedBox(
                                width: _titleContainerWidth,
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
              offset: Offset(tv * widget.config.contentEntryTranslate, 0),
              child: child,
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollStartNotification) {
                  if (notification.dragDetails != null) {
                    _subtitleSnapController.stop();
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
                  bool wasBallistic = _isBallistic;
                  _isBallistic = false;
                  _isDragging = false;
                  _isInterruptingBallistic = false;
                  _dragStartPixels = null;
                  double S = notification.metrics.pixels;
                  // 慢速停止（无归位动画）时：此处才触发页面变化通知
                  if (!wasBallistic) {
                    _firePageChangeIfNeeded(_pageIndexFromPosition(S));
                  }
                  // 大标题：仅在惯性滑动归位时才重置位置
                  if (wasBallistic) {
                    _parallaxNotifier.value = ParallaxData(
                      _getIdealT(S, parentWidth),
                      _getIdealB(S, parentWidth),
                    );
                  }
                  // 小标题：使用补间动画归位到规则 1/2 的理想位置
                  _subtitleSnapFrom = Map.from(_itemDxNotifier.value);
                  _subtitleSnapTo = {
                    for (int i = 0; i < widget.items.length; i++)
                      i: _getIdealItemDx(i, S)
                  };
                  _subtitleSnapController.forward(from: 0.0);
                } else if (notification is ScrollUpdateNotification) {
                  double dx = notification.scrollDelta ?? 0.0;
                  if (_isDragging && !_isBallistic) {
                    // 大标题 & 背景视差
                    // 速率 = (内容宽度 - Panorama宽度) / Panorama宽度 / 有效页面数 * 倍率
                    final bool titleScrollable =
                        _titleContainerWidth > parentWidth;
                    double bgSpeed = (_bgPatternWidth - parentWidth) /
                        parentWidth /
                        _effectivePageCount *
                        widget.config.bgDragSpeedDivisor;
                    double newT = titleScrollable
                        ? _parallaxNotifier.value.tOffset -
                            dx *
                                (_titleContainerWidth - parentWidth) /
                                parentWidth /
                                _effectivePageCount *
                                widget.config.bigTitleDragSpeedDivisor
                        : 0.0;
                    double newB =
                        _parallaxNotifier.value.bOffset - dx * bgSpeed;
                    _parallaxNotifier.value = ParallaxData(newT, newB);

                    // 小标题
                    if (_isInterruptingBallistic) {
                      // 规则3：惯性中被手指干预 → 0.1 倍速跟随手指
                      Map<int, double> newMap = Map.from(_itemDxNotifier.value);
                      for (int i = 0; i < widget.items.length; i++) {
                        if (_isWideItem[i]) {
                          double maxDx = _itemWidths[i] - _pageWidth;
                          newMap[i] = ((newMap[i] ?? 0.0) +
                                  dx * widget.config.subtitleInterruptSpeed)
                              .clamp(0.0, maxDx);
                        }
                      }
                      _itemDxNotifier.value = newMap;
                    } else {
                      // 规则 1&2：直接计算理想位置
                      Map<int, double> newMap = {};
                      for (int i = 0; i < widget.items.length; i++) {
                        newMap[i] =
                            _getIdealItemDx(i, notification.metrics.pixels);
                      }
                      _itemDxNotifier.value = newMap;
                    }
                  } else if (_isBallistic) {
                    double S = notification.metrics.pixels;
                    double distance = _targetS - _releaseS;
                    double p = distance.abs() > 0.001
                        ? (S - _releaseS) / distance
                        : 1.0;
                    double idealT = _getIdealT(_targetS, parentWidth);
                    double idealB = _getIdealB(_targetS, parentWidth);

                    _parallaxNotifier.value = ParallaxData(
                      _releaseT + p * (idealT - _releaseT),
                      _releaseB + p * (idealB - _releaseB),
                    );

                    Map<int, double> newMap = {};
                    for (int i = 0; i < widget.items.length; i++) {
                      if (_isWideItem[i]) {
                        double rDx =
                            _releaseItemDx[i] ?? _getIdealItemDx(i, _releaseS);
                        double iDx = _getIdealItemDx(i, _targetS);
                        newMap[i] = rDx + p * (iDx - rDx);
                      } else {
                        newMap[i] = 0.0;
                      }
                    }
                    _itemDxNotifier.value = newMap;
                  }
                }
                return false;
              },
              child: CustomScrollView(
                key: ValueKey(_pageWidth),
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
                        snapPoints: _snapPoints,
                        cycleLength: _cycleLength,
                        isInfinite: isInfinite,
                        pageSnapPoints: _pageSnapPoints,
                        stoppedVelocityThreshold:
                            widget.config.stoppedVelocityThreshold,
                        snapCurve: widget.config.snapCurve,
                        snapDuration: widget.config.snapDuration,
                        getDragStartPixels: () => _dragStartPixels,
                        onTargetCalculated: (target) {
                          _targetS = target;
                          _releaseS = _scrollController.position.pixels;
                          _releaseT = _parallaxNotifier.value.tOffset;
                          _releaseB = _parallaxNotifier.value.bOffset;
                          _releaseItemDx = Map.from(_itemDxNotifier.value);
                          _isBallistic = true;
                          // 启动计时器：归位动画时长内若手指再次按下，视为打断惯性
                          _ballisticInterruptTimer?.cancel();
                          _ballisticInterruptTimer = Timer(
                            widget.config.snapDuration,
                            () => _ballisticInterruptTimer = null,
                          );
                          // 手指抬起时立即通知页面变化，无需等动画结束
                          _firePageChangeIfNeeded(
                              _pageIndexFromPosition(target));
                        },
                      ),
                slivers: [
                  if (isInfinite)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          int realIndex = (widget.items.length -
                                  1 -
                                  (index % widget.items.length)) %
                              widget.items.length;
                          return _buildItemWidget(
                              widget.items[realIndex], realIndex);
                        },
                      ),
                    ),
                  SliverList(
                    key: const ValueKey('center_sliver'),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        int realIndex =
                            isInfinite ? index % widget.items.length : index;
                        return _buildItemWidget(
                            widget.items[realIndex], realIndex);
                      },
                      childCount: isInfinite ? null : widget.items.length,
                    ),
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
            width: _itemWidths[widget.items.length - 1],
            bottom: 0,
            child: IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: _translationNotifier,
                builder: (context, tv, child) => Transform.translate(
                  offset: Offset(
                      tv * widget.config.contentEntryTranslate -
                          _itemWidths[widget.items.length - 1],
                      0),
                  child: child!,
                ),
                child: _buildItemWidget(
                    widget.items.last, widget.items.length - 1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemWidget(MetroPanoramaItem item, int realIndex) {
    final double ew = _itemWidths[realIndex];
    return Container(
      color: Colors.transparent,
      width: ew,
      padding: EdgeInsets.only(
          left: widget.config.itemPaddingLeft,
          top: widget.config.itemPaddingTop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<Map<int, double>>(
            valueListenable: _itemDxNotifier,
            builder: (context, dxMap, child) {
              double dx = 0.0;
              if (_isWideItem[realIndex]) {
                dx = dxMap[realIndex] ?? 0.0;
              }
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: _MeasureSize(
              onChange: (size) => _updateTitleWidth(realIndex, size.width),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  fontWeight: FontWeight.w200,
                  fontSize: widget.config.subtitleFontSize,
                  color: Colors.white,
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
