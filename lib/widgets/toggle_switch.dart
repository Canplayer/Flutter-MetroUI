import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:metro_ui/uix_metrics.dart';

class _UixLog150 extends Curve {
  const _UixLog150();
  @override
  double transformInternal(double t) => (1 - math.pow(150, -t)) / (1 - 1 / 150);
}

class ToggleSwitchBase extends StatefulWidget {
  /// 开关的值
  final bool value;

  /// 值改变时的回调
  final ValueChanged<bool>? onChanged;

  /// 激活状态的颜色（左侧颜色），为null时使用主题主色调
  final Color? activeColor;

  /// 非激活状态的颜色（右侧颜色）
  final Color inactiveColor;

  /// 滑块宽度：`Constants.ToggleSwitchThumbSize.Width` = 20
  final double thumbWidth;

  /// 滑块高度：`Constants.ToggleSwitchThumbSize.Height` = 38
  final double thumbHeight;

  /// 滑块颜色
  final Color? thumbColor;

  /// 背景外框宽度：`Constants.ToggleSwitchSize.Width` = 97
  final double switchWidth;

  /// 背景外框高度：`Constants.ToggleSwitchSize.Height` = 34
  final double switchHeight;

  /// 外框线条粗细：`Constants.ToggleSwitchBorder` = 3
  final double borderWidth;

  /// 外框颜色
  final Color? borderColor;

  /// 背景内部纯色距离边框的padding：`Constants.ToggleSwitchInnerBorder` = 4
  final double innerPadding;

  /// 滑块和背景左右间隙的宽度：`ToggleSwitchInnerBorder / 2 + ToggleSwitchBorder` = 5
  final double gap;

  const ToggleSwitchBase({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveColor = Colors.transparent,
    this.thumbWidth = 20 * 0.8,
    this.thumbHeight = 38 * 0.8,
    this.thumbColor,
    this.switchWidth = 97 * 0.8,
    this.switchHeight = 34 * 0.8,
    this.borderWidth = 3 * 0.8,
    this.borderColor,
    this.innerPadding = 4 * 0.8,
    this.gap = 4 * 0.8,
  });

  @override
  State<ToggleSwitchBase> createState() => _ToggleSwitchBaseState();
}

class _ToggleSwitchBaseState extends State<ToggleSwitchBase>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double? _dragStart;
  bool _pointerCancelled = false;

  void _settle(bool value) {
    _controller.animateTo(
      value ? 1 : 0,
      duration: const Duration(milliseconds: 100),
      curve: const _UixLog150(),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ToggleSwitchBase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (_dragStart == null) _settle(widget.value);
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

    return Opacity(
      opacity: isInteractive ? 1.0 : 0.4,
      child: Semantics(
        toggled: widget.value,
        enabled: isInteractive,
        child: Listener(
          onPointerDown: (_) => _pointerCancelled = false,
          onPointerCancel: (_) => _pointerCancelled = true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTap: isInteractive ? _handleTap : null,
            onHorizontalDragStart: isInteractive
                ? (_) {
                    _controller.stop();
                    _dragStart = widget.value ? 1.0 : 0.0;
                  }
                : null,
            onHorizontalDragUpdate: isInteractive
                ? (details) {
                    final travel =
                        widget.switchWidth -
                        widget.thumbWidth -
                        2 * widget.innerPadding;
                    if (travel > 0) {
                      _controller.value =
                          (_controller.value + details.delta.dx / travel).clamp(
                            0.0,
                            1.0,
                          );
                    }
                  }
                : null,
            onHorizontalDragEnd: isInteractive
                ? (_) {
                    if (_pointerCancelled) {
                      _dragStart = null;
                      _settle(widget.value);
                      return;
                    }
                    final start = _dragStart ?? (widget.value ? 1.0 : 0.0);
                    final changed =
                        (_controller.value - start).abs() > 0.000001;
                    final target = changed ? !widget.value : widget.value;
                    _dragStart = null;
                    _settle(target);
                    if (changed) widget.onChanged?.call(target);
                  }
                : null,
            onHorizontalDragCancel: isInteractive
                ? () {
                    _dragStart = null;
                    _settle(widget.value);
                  }
                : null,
            child: SizedBox(
              width: 136 * uixScale,
              height: 92 * uixScale,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  19 * uixScale,
                  16 * uixScale,
                  16 * uixScale,
                  24 * uixScale,
                ),
                child: Center(
                  child: SizedBox(
                    width: widget.switchWidth + widget.innerPadding,
                    height:
                        widget.thumbHeight +
                        2 * widget.innerPadding, // 使用滑块高度作为整个控件的高度
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _SwitchPainter(
                            progress: _controller.value,
                            activeColor: !isInteractive
                                ? Theme.of(context).colorScheme.onSurface
                                : widget.activeColor ??
                                      Theme.of(context).colorScheme.primary,
                            inactiveColor: widget.inactiveColor,
                            thumbWidth: widget.thumbWidth,
                            thumbHeight: widget.thumbHeight,
                            thumbColor:
                                widget.thumbColor ??
                                Theme.of(context).colorScheme.onSurface,
                            switchWidth: widget.switchWidth,
                            switchHeight: widget.switchHeight,
                            borderWidth: widget.borderWidth,
                            borderColor:
                                widget.borderColor ??
                                (Theme.of(context).brightness ==
                                        Brightness.light
                                    ? const Color(0xDE000000)
                                    : Colors.white),
                            innerPadding: widget.innerPadding,
                            gap: widget.gap,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
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
    final frameWidth = switchWidth - 2 * innerPadding;
    canvas.save();
    canvas.translate(innerPadding, 0);
    final backgroundY = (thumbHeight - switchHeight) / 2 + innerPadding;

    // 计算拖动块位置
    final thumbX = progress * (frameWidth - thumbWidth);
    final thumbLeftEdge = thumbX;
    final thumbRightEdge = thumbX + thumbWidth;

    // 绘制外框 - 使用矩形实现精确裁切
    final leftFrameEndX = (thumbLeftEdge - gap).clamp(0.0, frameWidth);
    final rightFrameStartX = (thumbRightEdge + gap).clamp(0.0, frameWidth);

    final framePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    // 绘制左侧边框（使用矩形）- 根据裁切点调整宽度
    if (leftFrameEndX > 0) {
      // 左边框 - 根据裁切点调整宽度，最大为borderWidth
      final leftBorderWidth = (leftFrameEndX < borderWidth)
          ? leftFrameEndX
          : borderWidth;
      canvas.drawRect(
        Rect.fromLTWH(0, backgroundY, leftBorderWidth, switchHeight),
        framePaint,
      );

      // 上边框 - 从左边到裁切点的矩形
      if (leftFrameEndX > borderWidth) {
        canvas.drawRect(
          Rect.fromLTWH(
            borderWidth,
            backgroundY,
            leftFrameEndX - borderWidth,
            borderWidth,
          ),
          framePaint,
        );
      }

      // 下边框 - 从左边到裁切点的矩形
      if (leftFrameEndX > borderWidth) {
        canvas.drawRect(
          Rect.fromLTWH(
            borderWidth,
            backgroundY + switchHeight - borderWidth,
            leftFrameEndX - borderWidth,
            borderWidth,
          ),
          framePaint,
        );
      }
    }

    // 绘制右侧边框（使用矩形）- 根据裁切点调整位置和宽度
    if (rightFrameStartX < frameWidth) {
      // 右边框 - 根据裁切点从右往左调整宽度和位置
      final rightBorderLeft = (rightFrameStartX > frameWidth - borderWidth)
          ? rightFrameStartX
          : frameWidth - borderWidth;
      final rightBorderWidth = frameWidth - rightBorderLeft;

      if (rightBorderWidth > 0) {
        canvas.drawRect(
          Rect.fromLTWH(
            rightBorderLeft,
            backgroundY,
            rightBorderWidth,
            switchHeight,
          ),
          framePaint,
        );
      }

      // 上边框 - 从裁切点到右边的矩形
      if (rightFrameStartX < frameWidth - borderWidth) {
        canvas.drawRect(
          Rect.fromLTWH(
            rightFrameStartX,
            backgroundY,
            frameWidth - borderWidth - rightFrameStartX,
            borderWidth,
          ),
          framePaint,
        );
      }

      // 下边框 - 从裁切点到右边的矩形
      if (rightFrameStartX < frameWidth - borderWidth) {
        canvas.drawRect(
          Rect.fromLTWH(
            rightFrameStartX,
            backgroundY + switchHeight - borderWidth,
            frameWidth - borderWidth - rightFrameStartX,
            borderWidth,
          ),
          framePaint,
        );
      }
    }

    // 计算内部区域
    final innerRect = Rect.fromLTWH(
      borderWidth + innerPadding,
      backgroundY + borderWidth + innerPadding,
      frameWidth - 2 * (borderWidth + innerPadding),
      switchHeight - 2 * (borderWidth + innerPadding),
    );

    // 绘制内部填充 - 左侧红色部分（在滑块左侧，留出间隙）
    final leftEndX = (thumbLeftEdge - gap).clamp(
      innerRect.left,
      innerRect.right,
    );
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
    final rightStartX = (thumbRightEdge + gap).clamp(
      innerRect.left,
      innerRect.right,
    );
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
      innerPadding,
      thumbWidth,
      thumbHeight,
    );
    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(thumbRect, thumbPaint);
    canvas.restore();
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

/// UIX ToggleSwitch: label + status + right-hand ToggleSwitchBase + description.
/// Fonts inherit the app family; weights follow the package pubspec mapping.
class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label = '',
    this.description = '',
    this.onLabel = 'On',
    this.offLabel = 'Off',
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label, description, onLabel, offLabel;
  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    final enabled = onChanged != null;
    final mid = foreground.withValues(alpha: enabled ? .6 : .2);
    final high = foreground.withValues(alpha: enabled ? 1 : .2);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: uixFontSize(15),
                        fontWeight: FontWeight.w400,
                        color: mid,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 18 * uixScale,
                        bottom: 36 * uixScale,
                      ),
                      child: Text(
                        value ? onLabel : offLabel,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: uixFontSize(24),
                          fontWeight: FontWeight.w300,
                          color: high,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(24 * uixScale, 0),
                child: ToggleSwitchBase(value: value, onChanged: onChanged),
              ),
            ],
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 40 * uixScale),
              child: Text(
                description,
                softWrap: true,
                style: TextStyle(
                  fontSize: uixFontSize(15),
                  fontWeight: FontWeight.w400,
                  color: mid,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
