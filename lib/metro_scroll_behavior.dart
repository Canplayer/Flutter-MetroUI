import 'dart:async';

import 'package:flutter/material.dart';

/// 超滚动状态管理器
///
/// 使用静态 ValueNotifier 在不同组件间共享超滚动状态
class OverscrollStateManager {
  // 使用 Map 存储多个滚动视图的状态，key 为唯一标识
  static final Map<int, ValueNotifier<double>> _notifiers = {};

  /// 获取或创建指定 ID 的状态通知器
  static ValueNotifier<double> getNotifier(int id) {
    return _notifiers.putIfAbsent(id, () => ValueNotifier<double>(0.0));
  }

  /// 移除指定 ID 的状态通知器
  static void removeNotifier(int id) {
    _notifiers[id]?.dispose();
    _notifiers.remove(id);
  }

  /// 获取当前超滚动量
  static double getOverscrollAmount(int id) {
    return _notifiers[id]?.value ?? 0.0;
  }

  /// 设置超滚动量
  static void setOverscrollAmount(int id, double amount) {
    getNotifier(id).value = amount;
  }
}

/// 自定义滚动行为
///
/// 功能：
/// 1. 自定义滚动条样式：2单位宽，距离边缘1单位
/// 2. 超距离滑动时的缩放效果
class MetroScrollBehavior extends ScrollBehavior {
  const MetroScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return RawScrollbar(
      controller: details.controller,
      thumbColor: Colors.grey.withOpacity(0.5),
      thickness: 2.0,
      radius: const Radius.circular(0), // 矩形滚动条
      padding: const EdgeInsets.all(1.0), // 距离边缘1单位
      child: child,
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // 使用自定义的超距离滑动指示器
    // 从 details.clipBehavior 获取滚动组件设置的裁切行为
    return MetroOverscrollIndicator(
      axisDirection: details.direction,
      clipBehavior: details.clipBehavior ?? Clip.hardEdge, // 使用滚动组件的 clipBehavior
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // 使用自定义的滚动物理效果，使用默认 ID 0
    return const MetroBouncingScrollPhysics(scrollViewId: 0);
  }
}

/// 自定义滚动物理效果
///
/// 当页面overScroll时，反向拉动不允许继续滚动
class MetroBouncingScrollPhysics extends BouncingScrollPhysics {
  const MetroBouncingScrollPhysics({super.parent, this.scrollViewId = 0});

  final int scrollViewId;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // 如果在滚动范围内，使用父类的默认行为
    if (!position.outOfRange) {
      return super.applyPhysicsToUserOffset(position, offset);
    }

    final double overscrollPastStart =
        (position.minScrollExtent - position.pixels).clamp(0.0, double.infinity);
    final double overscrollPastEnd =
        (position.pixels - position.maxScrollExtent).clamp(0.0, double.infinity);
    final double maxOverscroll = 100.0;

    // 检查是否超出顶部边界（向下拉，超出顶部）
    if (overscrollPastStart > 0) {
      // offset > 0 表示继续向下拉（远离边界），需要限制
      if (offset > 0) {
        // 如果已经超出最大值，阻止继续向外拉
        if (overscrollPastStart >= maxOverscroll) {
          return 0;
        }
        // 限制下一次滑动的距离，防止超出最大值
        final double allowedOffset = (maxOverscroll - overscrollPastStart).clamp(0, double.infinity);
        if (offset > allowedOffset) {
          return allowedOffset;
        }
      }
      // offset < 0 表示向上拉（回到边界内），允许无阻力滑动
      return offset;
    }
    // 检查是否超出底部边界（向上拉，超出底部）
    else if (overscrollPastEnd > 0) {
      // offset < 0 表示继续向上拉（远离边界），需要限制
      if (offset < 0) {
        // 如果已经超出最大值，阻止继续向外拉
        if (overscrollPastEnd >= maxOverscroll) {
          return 0;
        }
        // 限制下一次滑动的距离，防止超出最大值
        final double allowedOffset = (maxOverscroll - overscrollPastEnd).clamp(0, double.infinity);
        if (offset.abs() > allowedOffset) {
          return -allowedOffset;
        }
      }
      // offset > 0 表示向下拉（回到边界内），允许无阻力滑动
      return offset;
    }

    // 如果超出滚动范围但未达到100像素，直接返回用户的偏移量，不施加任何摩擦力
    return offset;
  }
}

/// 自定义超距离滑动指示器
///
/// 当滑动超过内容边界时，以容器顶部向上320单位为原点进行纵向缩放
class MetroOverscrollIndicator extends StatefulWidget {
  const MetroOverscrollIndicator({
    super.key,
    required this.child,
    required this.axisDirection,
    this.clipBehavior = Clip.none, // 默认不裁切
  });

  final Widget child;
  final AxisDirection axisDirection;
  final Clip clipBehavior; // 裁切行为

  @override
  State<MetroOverscrollIndicator> createState() =>
      _MetroOverscrollIndicatorState();
}

class _MetroOverscrollIndicatorState extends State<MetroOverscrollIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _overscrollAmount = 0.0;
  final int _scrollViewId = 0; // 滚动视图 ID，用于状态管理
  Timer? _debugTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.addListener(() {
      // 动画过程中，更新 overscroll 值
      setState(() {
        _overscrollAmount *= (1.0 - _controller.value);
        // 同步到状态管理器
        OverscrollStateManager.setOverscrollAmount(
            _scrollViewId, _overscrollAmount);
      });
    });
  }

  @override
  void dispose() {
    _debugTimer?.cancel();
    _controller.dispose();
    OverscrollStateManager.removeNotifier(_scrollViewId);
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // 滚动更新 - 从 ScrollMetrics 获取超滚动信息
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      
      // 计算当前的超滚动量
      double currentOverscroll = 0.0;
      
      if (metrics.pixels < metrics.minScrollExtent) {
        // 超出顶部边界
        currentOverscroll = metrics.pixels - metrics.minScrollExtent;
      } else if (metrics.pixels > metrics.maxScrollExtent) {
        // 超出底部边界
        currentOverscroll = metrics.pixels - metrics.maxScrollExtent;
      }
      
      // 更新超滚动状态
      if (currentOverscroll != _overscrollAmount) {
        setState(() {
          _overscrollAmount = currentOverscroll;
          OverscrollStateManager.setOverscrollAmount(_scrollViewId, _overscrollAmount);
        });
        
        // 如果正在超滚动，停止回弹动画
        if (currentOverscroll != 0.0 && _controller.isAnimating) {
          _controller.stop();
        }
        // 如果从超滚动恢复到正常，开始回弹动画
        else if (currentOverscroll == 0.0 && _overscrollAmount != 0.0) {
          _controller.forward(from: 0.0);
        }
      }
    }
    // 滚动结束 - 触发回弹动画
    else if (notification is ScrollEndNotification) {
      if (_overscrollAmount != 0.0 && !_controller.isAnimating) {
        _controller.forward(from: 0.0);
      }
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ClipRect(
        clipBehavior: widget.clipBehavior,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 计算缩放效果
            final scaleValue = _calculateScale();
            final alignment = _calculateAlignment(constraints);

            return Transform.scale(
              scaleY: scaleValue,
              alignment: alignment,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }

  /// 计算缩放值
  ///
  /// 根据超距离滑动的距离计算缩放比例
  double _calculateScale() {
    // 缩放因子：超距离越大，缩放越明显
    // 使用非线性函数使效果更自然
    final scaleFactor = (_overscrollAmount.abs() / 1000).clamp(0.0, 0.3);

    // 向上滑动（overscroll为负）或向下滑动时都变扁
    return 1.0 - scaleFactor;
  }

  /// 计算变换的对齐点
  ///
  /// 向上滑动：以容器顶部向上320单位为原点
  /// 向下滑动：以容器底部向下320单位为原点
  Alignment _calculateAlignment(BoxConstraints constraints) {
    final height = constraints.maxHeight;

    if (height == 0 || height.isInfinite) {
      return Alignment.topCenter;
    }

    // 向下滑动（overscroll为正）
    if (_overscrollAmount > 0) {
      // 320单位向上 = 顶部 - 320
      // 将这个点转换为 Alignment 坐标系
      // Alignment.y: -1.0 是顶部, 1.0 是底部
      // y = -1.0 - (320 / (height / 2))
      final alignmentY = -1.0 - (0.0 / (height / 2));
      return Alignment(0.0, alignmentY);
    }
    // 向上滑动（overscroll为负）
    else if (_overscrollAmount < 0) {
      // 320单位向下 = 底部 + 320
      // y = 1.0 + (320 / (height / 2))
      final alignmentY = 1.0 + (0.0 / (height / 2));
      return Alignment(0.0, alignmentY);
    }
    // 没有超滚动
    else {
      return Alignment.center;
    }
  }
}
