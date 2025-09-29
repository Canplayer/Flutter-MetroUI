import 'package:flutter/material.dart';

class CustomSwitch extends StatefulWidget {
  /// 开关的值
  final bool value;
  
  /// 值改变时的回调
  final ValueChanged<bool>? onChanged;
  
  /// 激活状态的颜色（左侧颜色），为null时使用主题主色调
  final Color? activeColor;
  
  /// 非激活状态的颜色（右侧颜色）
  final Color inactiveColor;
  
  /// 滑块宽度
  final double thumbWidth;
  
  /// 滑块高度
  final double thumbHeight;
  
  /// 滑块颜色
  final Color? thumbColor;
  
  /// 背景外框宽度
  final double switchWidth;
  
  /// 背景外框高度
  final double switchHeight;
  
  /// 外框线条粗细
  final double borderWidth;
  
  /// 外框颜色
  final Color? borderColor;
  
  /// 背景内部纯色距离边框的padding
  final double innerPadding;
  
  /// 滑块和背景左右间隙的宽度
  final double gap;

  const CustomSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveColor = Colors.grey,
    this.thumbWidth = 16.0,
    this.thumbHeight = 30.0,
    this.thumbColor,
    this.switchWidth = 72.0,
    this.switchHeight = 27.0,
    this.borderWidth = 2.5,
    this.borderColor,
    this.innerPadding = 3.0,
    this.gap = 3.0,
  });

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CustomSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onChanged != null) {
      widget.onChanged!(!widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 检查控件是否可交互
    final isInteractive = widget.onChanged != null;
    
    return GestureDetector(
      onTap: isInteractive ? _handleTap : null,
      onPanUpdate: isInteractive ? (details) {
        // 计算拖动位置
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final progress = (localPosition.dx - widget.thumbWidth / 2) / (widget.switchWidth - widget.thumbWidth);
        final clampedProgress = progress.clamp(0.0, 1.0);
        
        _controller.value = clampedProgress;
      } : null,
      onPanEnd: isInteractive ? (details) {
        // 根据当前位置决定最终状态
        final shouldBeOn = _controller.value > 0.5;
        
        // 先播放动画归位
        if (shouldBeOn) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
        
        // 然后通知状态变化
        if (widget.onChanged != null) {
          widget.onChanged!(shouldBeOn);
        }
      } : null,
      child: SizedBox(
        width: widget.switchWidth,
        height: widget.thumbHeight, // 使用滑块高度作为整个控件的高度
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _SwitchPainter(
                progress: _controller.value,
                activeColor: widget.activeColor ?? Theme.of(context).colorScheme.primary,
                inactiveColor: widget.inactiveColor,
                thumbWidth: widget.thumbWidth,
                thumbHeight: widget.thumbHeight,
                thumbColor: isInteractive ? Theme.of(context).colorScheme.onSurface : Colors.grey,
                switchWidth: widget.switchWidth,
                switchHeight: widget.switchHeight,
                borderWidth: widget.borderWidth,
                borderColor: isInteractive ? Theme.of(context).colorScheme.onSurface : Colors.grey,
                innerPadding: widget.innerPadding,
                gap: widget.gap,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SwitchPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final double thumbWidth;
  final double thumbHeight;
  final Color thumbColor;
  final double switchWidth;
  final double switchHeight;
  final double borderWidth;
  final Color borderColor;
  final double innerPadding;
  final double gap;

  _SwitchPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbWidth,
    required this.thumbHeight,
    required this.thumbColor,
    required this.switchWidth,
    required this.switchHeight,
    required this.borderWidth,
    required this.borderColor,
    required this.innerPadding,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 计算背景垂直居中位置
    final backgroundY = (thumbHeight - switchHeight) / 2;

    // 计算拖动块位置
    final thumbX = progress * (switchWidth - thumbWidth);
    final thumbLeftEdge = thumbX;
    final thumbRightEdge = thumbX + thumbWidth;

    // 绘制外框 - 使用矩形实现精确裁切
    final leftFrameEndX = (thumbLeftEdge - gap).clamp(0.0, switchWidth);
    final rightFrameStartX = (thumbRightEdge + gap).clamp(0.0, switchWidth);
    
    final framePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    // 绘制左侧边框（使用矩形）- 根据裁切点调整宽度
    if (leftFrameEndX > 0) {
      // 左边框 - 根据裁切点调整宽度，最大为borderWidth
      final leftBorderWidth = (leftFrameEndX < borderWidth) ? leftFrameEndX : borderWidth;
      canvas.drawRect(
        Rect.fromLTWH(0, backgroundY, leftBorderWidth, switchHeight),
        framePaint,
      );
      
      // 上边框 - 从左边到裁切点的矩形
      if (leftFrameEndX > borderWidth) {
        canvas.drawRect(
          Rect.fromLTWH(borderWidth, backgroundY, leftFrameEndX - borderWidth, borderWidth),
          framePaint,
        );
      }
      
      // 下边框 - 从左边到裁切点的矩形
      if (leftFrameEndX > borderWidth) {
        canvas.drawRect(
          Rect.fromLTWH(borderWidth, backgroundY + switchHeight - borderWidth, leftFrameEndX - borderWidth, borderWidth),
          framePaint,
        );
      }
    }

    // 绘制右侧边框（使用矩形）- 根据裁切点调整位置和宽度
    if (rightFrameStartX < switchWidth) {
      // 右边框 - 根据裁切点从右往左调整宽度和位置
      final rightBorderLeft = (rightFrameStartX > switchWidth - borderWidth) 
          ? rightFrameStartX 
          : switchWidth - borderWidth;
      final rightBorderWidth = switchWidth - rightBorderLeft;
      
      if (rightBorderWidth > 0) {
        canvas.drawRect(
          Rect.fromLTWH(rightBorderLeft, backgroundY, rightBorderWidth, switchHeight),
          framePaint,
        );
      }
      
      // 上边框 - 从裁切点到右边的矩形
      if (rightFrameStartX < switchWidth - borderWidth) {
        canvas.drawRect(
          Rect.fromLTWH(rightFrameStartX, backgroundY, switchWidth - borderWidth - rightFrameStartX, borderWidth),
          framePaint,
        );
      }
      
      // 下边框 - 从裁切点到右边的矩形
      if (rightFrameStartX < switchWidth - borderWidth) {
        canvas.drawRect(
          Rect.fromLTWH(rightFrameStartX, backgroundY + switchHeight - borderWidth, switchWidth - borderWidth - rightFrameStartX, borderWidth),
          framePaint,
        );
      }
    }

    // 计算内部区域
    final innerRect = Rect.fromLTWH(
      borderWidth + innerPadding,
      backgroundY + borderWidth + innerPadding,
      switchWidth - 2 * (borderWidth + innerPadding),
      switchHeight - 2 * (borderWidth + innerPadding),
    );

    // 绘制内部填充 - 左侧红色部分（在滑块左侧，留出间隙）
    final leftEndX = (thumbLeftEdge - gap).clamp(innerRect.left, innerRect.right);
    if (leftEndX > innerRect.left) {
      final leftRect = Rect.fromLTWH(
        innerRect.left,
        innerRect.top,
        leftEndX - innerRect.left,
        innerRect.height,
      );
      final leftPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(leftRect, leftPaint);
    }

    // 绘制内部填充 - 右侧灰色部分（在滑块右侧，留出间隙）
    final rightStartX = (thumbRightEdge + gap).clamp(innerRect.left, innerRect.right);
    if (rightStartX < innerRect.right) {
      final rightRect = Rect.fromLTWH(
        rightStartX,
        innerRect.top,
        innerRect.right - rightStartX,
        innerRect.height,
      );
      final rightPaint = Paint()
        ..color = inactiveColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(rightRect, rightPaint);
    }

    // 绘制拖动块 - 垂直居中
    final thumbRect = Rect.fromLTWH(
      thumbX,
      0, // 从顶部开始，因为整个控件高度现在就是滑块高度
      thumbWidth,
      thumbHeight,
    );
    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(thumbRect, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _SwitchPainter &&
        other.progress == progress &&
        other.activeColor == activeColor &&
        other.inactiveColor == inactiveColor &&
        other.thumbWidth == thumbWidth &&
        other.thumbHeight == thumbHeight &&
        other.thumbColor == thumbColor &&
        other.switchWidth == switchWidth &&
        other.switchHeight == switchHeight &&
        other.borderWidth == borderWidth &&
        other.borderColor == borderColor &&
        other.innerPadding == innerPadding &&
        other.gap == gap;
  }

  @override
  int get hashCode => Object.hash(
    progress, 
    activeColor, 
    inactiveColor,
    thumbWidth,
    thumbHeight,
    thumbColor,
    switchWidth,
    switchHeight,
    borderWidth,
    borderColor,
    innerPadding,
    gap,
  );
}