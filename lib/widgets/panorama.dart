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
    this.subtitleInterruptSpeed = 0.1,
    this.subtitleFontSize = 66.0 * 0.8,
  });
}

class MetroPanoramaItem {
  final String title;
  final Widget child;
  final double width;

  MetroPanoramaItem({
    required this.title,
    required this.child,
    this.width = 0,
  });
}

typedef TargetCallback = void Function(double target);

class PanoramaScrollPhysics extends ScrollPhysics {
  final List<double> snapPoints;
  final double cycleLength;
  final bool isInfinite;
  final TargetCallback? onTargetCalculated;

  /// 仅包含每个 item 起始位置的吸附点（页间导航点）。
  /// 与 [snapPoints] 对比后可判断某个点是否属于长页面内部滚动范围。
  final List<double> pageSnapPoints;
  final double stoppedVelocityThreshold;
  final double snapVelocityScale;

  const PanoramaScrollPhysics({
    required this.snapPoints,
    required this.cycleLength,
    required this.isInfinite,
    required this.pageSnapPoints,
    this.stoppedVelocityThreshold = 200.0,
    this.snapVelocityScale = 0.2,
    this.onTargetCalculated,
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
      snapVelocityScale: snapVelocityScale,
      onTargetCalculated: onTargetCalculated,
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
    double target = pixels + (velocity * snapVelocityScale);

    double bestSnap = pixels;
    double minDiff = double.infinity;

    if (isInfinite) {
      int cycle = (target / cycleLength).floor();
      for (int i = cycle - 1; i <= cycle + 1; i++) {
        for (double sp in snapPoints) {
          double absSp = i * cycleLength + sp;
          double diff = (absSp - target).abs();
          if (diff < minDiff) {
            minDiff = diff;
            bestSnap = absSp;
          }
        }
      }
    } else {
      for (double sp in snapPoints) {
        double diff = (sp - target).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestSnap = sp;
        }
      }
    }

    if (!isInfinite) {
      if (bestSnap < position.minScrollExtent) {
        bestSnap = position.minScrollExtent;
      }
      if (bestSnap > position.maxScrollExtent) {
        bestSnap = position.maxScrollExtent;
      }
    }

    if ((bestSnap - pixels).abs() < tolerance.distance) {
      return null;
    }

    if (velocity.abs() < stoppedVelocityThreshold && cycleLength > 0) {
      double localPixels = pixels;
      if (isInfinite) {
        localPixels = pixels % cycleLength;
        if (localPixels < 0) localPixels += cycleLength;
      }
      if (_isWithinLongItemRange(localPixels)) {
        return null;
      }
    }

    if (onTargetCalculated != null) {
      onTargetCalculated!(bestSnap);
    }

    return ScrollSpringSimulation(
      spring,
      pixels,
      bestSnap,
      velocity,
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
  double _targetS = 0.0;
  double _releaseS = 0.0;
  double _releaseT = 0.0;
  double _releaseB = 0.0;
  Map<int, double> _releaseItemDx = {};

  double get _titleContainerWidth => widget.config.titleContainerWidth;
  double get _bgPatternWidth => widget.config.bgPatternWidth;
  double _titleSpacing = 1500.0;

  // ── 布局派生值（由 _recalculateLayout 统一维护）───────────────────────────────
  /// 普通页面的标准宽度 = parentWidth - nextPagePeekSize。
  /// 页面宽度 >= 此值即可填满可视区（留出 peek 露出区）。
  double _pageWidth = 350.0;
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
  double _cycleLength = 0;
  int _currentPageIndex = 0;
  /// 上一次执行布局计算时的参数指纹，用于判断是否需要重新计算。
  int _layoutFingerprint = 0;

  /// 窗口大小变化后需要校正到的滚动位置，在下一帧应用。
  double? _pendingScrollTarget;

  /// 计算布局指纹：parentWidth + nextPagePeekSize + item 数量 + item 原始宽度。
  /// 任何参数变化都会导致指纹变化从而触发重新计算。
  int _computeFingerprint(double parentWidth) {
    int hash = parentWidth.hashCode ^ widget.config.nextPagePeekSize.hashCode;
    for (int i = 0; i < widget.items.length; i++) {
      hash = hash ^ widget.items[i].width.hashCode ^ i.hashCode;
    }
    return hash;
  }

  /// 根据 parentWidth 和 config 统一计算所有布局派生值。
  void _recalculateLayout(double parentWidth) {
    final int fp = _computeFingerprint(parentWidth);
    if (fp == _layoutFingerprint) return;

    // ── 捕获旧布局下最近的吸附点索引 ─────────────────────────────────────────
    int? oldSnapIdx;
    int oldCycle = 0;
    final bool isResize =
        _layoutFingerprint != 0 && _scrollController.hasClients && _cycleLength > 0;

    if (isResize) {
      final double S = _scrollController.position.pixels;
      final bool infinite = widget.items.length > 2;
      double localS = S;
      if (infinite) {
        oldCycle = (S / _cycleLength).floor();
        localS = S - oldCycle * _cycleLength;
      }
      double minDist = double.infinity;
      for (int i = 0; i < _snapPoints.length; i++) {
        final double dist = (localS - _snapPoints[i]).abs();
        if (dist < minDist) {
          minDist = dist;
          oldSnapIdx = i;
        }
      }
    }

    // ── 执行重新计算 ────────────────────────────────────────────────────────
    _layoutFingerprint = fp;

    _pageWidth = parentWidth - widget.config.nextPagePeekSize;

    // 计算每个 item 的实际宽度和宽页面标记
    _itemWidths = List<double>.generate(widget.items.length, (i) {
      final double raw = widget.items[i].width;
      return raw > _pageWidth ? raw : _pageWidth;
    });
    _isWideItem = List<bool>.generate(widget.items.length, (i) {
      return widget.items[i].width > _pageWidth;
    });

    // 计算吸附点和有效页面数
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
        _effectivePageCount += 1;
      }
      current += _itemWidths[i];
    }
    _cycleLength = current;

    // ── 计算新布局下等价的滚动位置 ──────────────────────────────────────────
    if (oldSnapIdx != null && oldSnapIdx < _snapPoints.length) {
      final bool infinite = widget.items.length > 2;
      _pendingScrollTarget = infinite
          ? oldCycle * _cycleLength + _snapPoints[oldSnapIdx]
          : _snapPoints[oldSnapIdx];
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController(initialScrollOffset: 0.0);
    _scrollController.addListener(_checkPageChange);

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

  void _checkPageChange() {
    if (_cycleLength == 0 ||
        !_scrollController.hasClients ||
        widget.items.isEmpty) {
      return;
    }
    double S = _scrollController.position.pixels;
    int cycle = (S / _cycleLength).floor();
    double localS = S - cycle * _cycleLength;

    int closestIndex = 0;
    double minDiff = double.infinity;
    double start = 0;
    for (int i = 0; i < widget.items.length; i++) {
      double diff = (localS - start).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
      start += _itemWidths[i];
    }

    if (closestIndex != _currentPageIndex) {
      _currentPageIndex = closestIndex;
      if (widget.onPageChange != null) {
        widget.onPageChange!(_currentPageIndex);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkPageChange);
    _rotationController.dispose();
    _translationController.dispose();
    _scrollController.dispose();
    _parallaxNotifier.dispose();
    _itemDxNotifier.dispose();
    _translationNotifier.dispose();
    super.dispose();
  }

  double _getIdealT(double S, double parentWidth) {
    if (_cycleLength == 0) return 0.0;
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

  double _getIdealItemDx(int realIndex, double S) {
    double ew = _itemWidths[realIndex];
    if (!_isWideItem[realIndex]) return 0.0;
    double pageStart = 0;
    for (int i = 0; i < realIndex; i++) {
      pageStart += _itemWidths[i];
    }
    double cycleS = _cycleLength > 0 ? S % _cycleLength : 0;
    if (cycleS < 0) cycleS += _cycleLength;
    double d = cycleS - pageStart;
    if (_cycleLength > 0) {
      if (d < -_cycleLength / 2) d += _cycleLength;
      if (d > _cycleLength / 2) d -= _cycleLength;
    }
    // 规则1：d>=0 时，小标题偏移 = 页面滚动距离 × subtitleForwardSpeed
    // 规则2：d<0  时，小标题偏移 = |d| × subtitleBackwardSpeed（更慢的分离速率）
    double titleDx = d >= 0
        ? d * widget.config.subtitleForwardSpeed
        : (-d) * widget.config.subtitleBackwardSpeed;
    double maxDx = ew - _pageWidth;
    if (maxDx < 0) maxDx = 0;
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

        // ── 窗口大小变化后校正滚动位置与视差偏移 ──────────────────────────
        if (_pendingScrollTarget != null) {
          final double newS = _pendingScrollTarget!;
          final double pw = constraints.maxWidth;
          _pendingScrollTarget = null;

          // 立即校正视差，避免标题和背景闪烁
          _parallaxNotifier.value = ParallaxData(
            _getIdealT(newS, pw),
            _getIdealB(newS, pw),
          );
          final Map<int, double> newDx = {};
          for (int i = 0; i < widget.items.length; i++) {
            newDx[i] = _getIdealItemDx(i, newS);
          }
          _itemDxNotifier.value = newDx;

          // 清除拖拽 / 惯性状态
          _isDragging = false;
          _isBallistic = false;
          _isInterruptingBallistic = false;

          // 下一帧校正内容滚动位置
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(newS);
            }
          });
        }

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
    bool isInfinite = widget.items.length > 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
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
                    if (_isBallistic) {
                      _isInterruptingBallistic = true;
                    }
                    _isDragging = true;
                    _isBallistic = false;
                  }
                } else if (notification is UserScrollNotification) {
                  if (notification.direction == ScrollDirection.idle) {
                    _isDragging = false;
                  } else {
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
                  double S = notification.metrics.pixels;
                  // 大标题：仅在惯性滑动归位时才重置位置
                  if (wasBallistic) {
                    _parallaxNotifier.value = ParallaxData(
                      _getIdealT(S, parentWidth),
                      _getIdealB(S, parentWidth),
                    );
                  }
                  // 小标题：始终重置到规则 1/2 的理想位置
                  Map<int, double> newMap = {};
                  for (int i = 0; i < widget.items.length; i++) {
                    newMap[i] = _getIdealItemDx(i, S);
                  }
                  _itemDxNotifier.value = newMap;
                } else if (notification is ScrollUpdateNotification) {
                  double dx = notification.scrollDelta ?? 0.0;
                  if (_isDragging && !_isBallistic) {
                    // 大标题 & 背景视差
                    // 速率 = (内容宽度 - Panorama宽度) / Panorama宽度 / 有效页面数 * 倍率
                    double titleSpeed = (_titleContainerWidth - parentWidth) /
                        parentWidth /
                        _effectivePageCount *
                        widget.config.bigTitleDragSpeedDivisor;
                    double bgSpeed = (_bgPatternWidth - parentWidth) /
                        parentWidth /
                        _effectivePageCount *
                        widget.config.bgDragSpeedDivisor;
                    double newT =
                        _parallaxNotifier.value.tOffset - dx * titleSpeed;
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
                key: ValueKey(_layoutFingerprint),
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
                physics: PanoramaScrollPhysics(
                  snapPoints: _snapPoints,
                  cycleLength: _cycleLength,
                  isInfinite: isInfinite,
                  pageSnapPoints: _pageSnapPoints,
                  stoppedVelocityThreshold:
                      widget.config.stoppedVelocityThreshold,
                  snapVelocityScale: widget.config.snapVelocityScale,
                  onTargetCalculated: (target) {
                    _targetS = target;
                    _releaseS = _scrollController.position.pixels;
                    _releaseT = _parallaxNotifier.value.tOffset;
                    _releaseB = _parallaxNotifier.value.bOffset;
                    _releaseItemDx = Map.from(_itemDxNotifier.value);
                    _isBallistic = true;
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
        if (widget.items.isNotEmpty)
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
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontWeight: FontWeight.w200,
                fontSize: widget.config.subtitleFontSize,
                color: Colors.white,
              ),
              child: Text(item.title),
            ),
          ),
          const SizedBox(height: 26 * 0.8),
          Expanded(child: item.child),
        ],
      ),
    );
  }
}
