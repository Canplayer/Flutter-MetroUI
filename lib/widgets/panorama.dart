import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/page_scaffold.dart';

class ParallaxData {
  final double tOffset;
  final double bOffset;
  const ParallaxData(this.tOffset, this.bOffset);
}

class MetroPanoramaItem {
  final String title;
  final Widget child;
  final double width;

  MetroPanoramaItem({
    required this.title,
    required this.child,
    double width = 0,
  }) : width = width < 350.0 ? 350.0 : width;
}

typedef TargetCallback = void Function(double target);

class PanoramaScrollPhysics extends ScrollPhysics {
  final List<double> snapPoints;
  final double cycleLength;
  final bool isInfinite;
  final TargetCallback? onTargetCalculated;

  const PanoramaScrollPhysics({
    required this.snapPoints,
    required this.cycleLength,
    required this.isInfinite,
    this.onTargetCalculated,
    super.parent,
  });

  @override
  PanoramaScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return PanoramaScrollPhysics(
      snapPoints: snapPoints,
      cycleLength: cycleLength,
      isInfinite: isInfinite,
      onTargetCalculated: onTargetCalculated,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = toleranceFor(position);

    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    double pixels = position.pixels;
    double target = pixels + (velocity * 0.2);

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

  const MetroPanorama({
    super.key,
    required this.title,
    required this.background,
    required this.items,
    this.onPageChange,
  });

  @override
  State<MetroPanorama> createState() => _MetroPanoramaState();
}

class _MetroPanoramaState extends State<MetroPanorama>
    with TickerProviderStateMixin {
  static const double _pi = 3.1415926535897932;
  static double _degreesToRadians(double degrees) => degrees * _pi / 180;
  final double _pivot = -250 * 0.8;

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
  double _targetS = 0.0;
  double _releaseS = 0.0;
  double _releaseT = 0.0;
  double _releaseB = 0.0;
  Map<int, double> _releaseItemDx = {};

  static const double _titleContainerWidth = 500.0;
  double _titleSpacing = 1500.0;
  final double _bgPatternWidth = 1000.0;

  final List<double> _snapPoints = [];
  double _cycleLength = 0;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    double current = 0;
    for (var item in widget.items) {
      _snapPoints.add(current);
      if (item.width > 350) {
        _snapPoints.add(current + item.width - 350);
      }
      current += item.width;
    }
    _cycleLength = current;

    _scrollController = ScrollController(initialScrollOffset: 0.0);
    _scrollController.addListener(_checkPageChange);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _translationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _rotationAnimation =
        Tween<double>(begin: -86.5, end: 0).animate(CurvedAnimation(
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
      start += widget.items[i].width;
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
    if (widget.items[realIndex].width <= 350) return 0.0;
    double start = 0;
    for (int i = 0; i < realIndex; i++) {
      start += widget.items[i].width;
    }
    double cycleS = _cycleLength > 0 ? S % _cycleLength : 0;
    double diff = cycleS - start;
    if (_cycleLength > 0) {
      if (diff < -_cycleLength / 2) diff += _cycleLength;
      if (diff > _cycleLength / 2) diff -= _cycleLength;
    }
    double maxDx = widget.items[realIndex].width - 350;
    if (diff < 0) return 0.0;
    if (diff > maxDx) return maxDx;
    return diff;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _titleSpacing = _titleContainerWidth + constraints.maxWidth + 100.0;

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

              final double bgEntryOffset = tv * 900 * 0.8;
              final double titleEntryOffset = tv * 1520 * 0.8;

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
                    top: -30,
                    left: 0,
                    height: 150,
                    right: -2000,
                    child: Transform.translate(
                      offset: Offset(titleEntryOffset, 0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (int i = 0; i < 2; i++)
                            Positioned(
                              left: renderT + i * _titleSpacing + 20,
                              top: 0,
                              child: SizedBox(
                                width: _titleContainerWidth,
                                child: DefaultTextStyle.merge(
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w200,
                                    fontSize: 120,
                                    color: Colors.white,
                                  ),
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
              offset: Offset(tv * 1200 * 0.8, 0),
              child: child,
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollStartNotification) {
                  if (notification.dragDetails != null) {
                    _isDragging = true;
                    _isBallistic = false;
                  }
                } else if (notification is UserScrollNotification) {
                  if (notification.direction == ScrollDirection.idle) {
                    _isDragging = false;
                  } else {
                    _isDragging = true;
                    _isBallistic = false;
                  }
                } else if (notification is ScrollEndNotification) {
                  _isBallistic = false;
                  _isDragging = false;
                  double S = notification.metrics.pixels;
                  _parallaxNotifier.value = ParallaxData(
                    _getIdealT(S, parentWidth),
                    _getIdealB(S, parentWidth),
                  );
                  Map<int, double> newMap = {};
                  for (int i = 0; i < widget.items.length; i++) {
                    newMap[i] = _getIdealItemDx(i, S);
                  }
                  _itemDxNotifier.value = newMap;
                } else if (notification is ScrollUpdateNotification) {
                  double dx = notification.scrollDelta ?? 0.0;
                  if (_isDragging && !_isBallistic) {
                    double newT = _parallaxNotifier.value.tOffset - dx / 4.0;
                    double newB = _parallaxNotifier.value.bOffset - dx / 3.0;
                    _parallaxNotifier.value = ParallaxData(newT, newB);

                    Map<int, double> newMap = Map.from(_itemDxNotifier.value);
                    for (int i = 0; i < widget.items.length; i++) {
                      if (widget.items[i].width > 350) {
                        newMap[i] = (newMap[i] ??
                                _getIdealItemDx(
                                    i, notification.metrics.pixels)) +
                            dx * 0.5;
                      }
                    }
                    _itemDxNotifier.value = newMap;
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
                      if (widget.items[i].width > 350) {
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
                clipBehavior: Clip.none,
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                center: const ValueKey('center_sliver'),
                physics: PanoramaScrollPhysics(
                  snapPoints: _snapPoints,
                  cycleLength: _cycleLength,
                  isInfinite: isInfinite,
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
            width: widget.items.last.width,
            bottom: 0,
            child: IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: _translationNotifier,
                builder: (context, tv, child) => Transform.translate(
                  offset: Offset(tv * 1200 * 0.8 - widget.items.last.width, 0),
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
    return Container(
      color: Colors.transparent,
      width: item.width,
      padding: const EdgeInsets.only(left: 20, top: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<Map<int, double>>(
            valueListenable: _itemDxNotifier,
            builder: (context, dxMap, child) {
              double dx = 0.0;
              if (item.width > 350) {
                dx = dxMap[realIndex] ?? 0.0;
              }
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                fontWeight: FontWeight.w200,
                fontSize: 50,
                color: Colors.white,
              ),
              child: Text(item.title),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: item.child),
        ],
      ),
    );
  }
}
