import 'package:flutter/material.dart';
import 'package:metro_ui/animations.dart';

/// Metro 风格的点状加载指示器
/// 
/// 多个圆点从左向右匀速移动的动画效果
class MetroSpinner extends StatefulWidget {
  /// 圆点的大小（半径）
  final double dotSize;
  
  /// 圆点之间的间距
  final double spacing;
  
  /// 圆点的颜色
  final Color? color;
  
  /// 动画持续时间
  final Duration duration;
  
  /// 圆点的数量
  final int dotCount;

  const MetroSpinner({
    super.key,
    this.dotSize = 2.0,
    this.spacing = 10.0,
    this.color,
    this.duration = const Duration(milliseconds: 3000),
    this.dotCount = 5,
  });

  @override
  State<MetroSpinner> createState() => _MetroSpinnerState();
}

class _MetroSpinnerState extends State<MetroSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(); // 无限循环

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear, // 匀速移动
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    
    return SizedBox(
      height: widget.dotSize * 2, // 纵向大小为点的直径
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _MetroSpinnerPainter(
              progress: _animation.value,
              dotSize: widget.dotSize,
              spacing: widget.spacing,
              color: color,
              dotCount: widget.dotCount,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

/// Spinner 的绘制器
class _MetroSpinnerPainter extends CustomPainter {
  final double progress;
  final double dotSize;
  final double spacing;
  final Color color;
  final int dotCount;

  _MetroSpinnerPainter({
    required this.progress,
    required this.dotSize,
    required this.spacing,
    required this.color,
    required this.dotCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double containerWidth = size.width;
    
    // 计算所有点的总宽度（包括间距）
    final double totalDotsWidth = (dotCount * dotSize * 2) + ((dotCount - 1) * spacing);
    
    // 起始位置：从屏幕左侧外面开始（-dotSize 让第一个点完全在左侧外）
    final double startX = -dotSize;
    
    // 结束位置：所有点都移到右侧（容器宽度 - 总宽度）
    final double endX = containerWidth - totalDotsWidth;
    
    // 当前偏移量：从 startX 到 endX 的线性插值（基础移动）
    final double currentOffset = startX + (endX - startX) * progress;

    // 飞入飞出的距离
    final double flyDistance = containerWidth / 3;
    
    // 每个点之间的时间间隔（占总动画时长的比例）
    final double intervalPerDot = (1.0 / 3.0) / dotCount;

    // 绘制圆点
    for (int i = 0; i < dotCount; i++) {
      // 计算每个点的基础 x 位置
      final double baseX = currentOffset + i * (dotSize * 2 + spacing);
      
      // 计算飞入飞出的额外偏移
      double flyOffset = 0.0;
      
      // 飞入阶段：前 1/3 时间
      // 最右侧的点（i = dotCount - 1）最先飞入
      final int flyInIndex = dotCount - 1 - i; // 反转索引，最右侧的点先飞入
      final double flyInStartProgress = flyInIndex * intervalPerDot;
      final double flyInEndProgress = flyInStartProgress + intervalPerDot;
      
      // 判断点是否应该显示
      bool shouldShow = true;
      
      if (progress < flyInStartProgress) {
        // 飞入动画还未开始，不显示这个点
        shouldShow = false;
      } else if (progress >= flyInStartProgress && progress < 1.0 / 3.0) {
        // 在飞入阶段
        if (progress <= flyInEndProgress) {
          // 当前点正在飞入
          final double flyInProgress = (progress - flyInStartProgress) / intervalPerDot;
          // 使用 Metro 动画曲线：从 -flyDistance 到 0
          final double curvedProgress = MetroCurves.normalPageRotateIn.transform(flyInProgress);
          flyOffset = -flyDistance * (1.0 - curvedProgress);
        }
        // 否则，飞入已完成，flyOffset = 0
      }
      
      // 如果点不应该显示，跳过绘制
      if (!shouldShow) {
        continue;
      }
      
      // 飞出阶段：最后 1/3 时间（从 2/3 开始）
      // 最右侧的点（i = dotCount - 1）最先飞出
      final int flyOutIndex = dotCount - 1 - i; // 反转索引，最右侧的点先飞出
      final double flyOutStartProgress = 2.0 / 3.0 + flyOutIndex * intervalPerDot;
      final double flyOutEndProgress = flyOutStartProgress + intervalPerDot;
      
      if (progress >= flyOutStartProgress) {
        // 在飞出阶段
        if (progress <= flyOutEndProgress) {
          // 当前点正在飞出
          final double flyOutProgress = (progress - flyOutStartProgress) / intervalPerDot;
          // 使用 Metro 动画曲线：从 0 到 +flyDistance（向右加速）
          final double curvedProgress = MetroCurves.normalPageRotateOut.transform(flyOutProgress);
          flyOffset = flyDistance * curvedProgress;
        } else {
          // 飞出已完成
          flyOffset = flyDistance;
        }
      }
      
      // 最终的 x 位置 = 基础位置 + 飞入飞出偏移
      final double x = baseX + flyOffset;
      
      // 只绘制在屏幕可见范围内的点（优化性能）
      if (x + dotSize >= 0 && x - dotSize <= containerWidth) {
        canvas.drawCircle(
          Offset(x, size.height / 2), // y 坐标在中间
          dotSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MetroSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.dotSize != dotSize ||
        oldDelegate.spacing != spacing ||
        oldDelegate.color != color ||
        oldDelegate.dotCount != dotCount;
  }
}
