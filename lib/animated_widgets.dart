import 'package:flutter/material.dart';

/// 围绕屏幕左侧轴旋转的动画组件
///
/// 这个组件会自动计算子组件相对于屏幕左侧的位置，
/// 并围绕屏幕最左侧的虚拟轴进行 Y 轴旋转动画
class LeftEdgeRotateAnimation extends StatefulWidget {
  /// 要应用动画的子组件
  final Widget child;

  /// 旋转角度（弧度制）
  /// 0 表示不旋转，π/2 表示旋转90度
  final double rotation;

  const LeftEdgeRotateAnimation({
    super.key,
    required this.child,
    required this.rotation,
  });

  @override
  State<LeftEdgeRotateAnimation> createState() =>
      _LeftEdgeRotateAnimationState();
}

class _LeftEdgeRotateAnimationState extends State<LeftEdgeRotateAnimation> {
  final GlobalKey _childKey = GlobalKey();
  final GlobalKey _wrapperKey = GlobalKey(); // 新增一个包装器的 Key
  double _edgeOffset = 0.0;

  @override
  void initState() {
    super.initState();
    // 在首帧渲染后计算位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateEdgeOffset();
    });
  }

  @override
  void didUpdateWidget(LeftEdgeRotateAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 使用 addPostFrameCallback 确保在当前帧布局完成后再计算，避免 RenderBox not laid out 错误
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _calculateEdgeOffset();
      }
    });
  }

  /// 计算组件相对于屏幕左侧的偏移量
  void _calculateEdgeOffset() {
    final context = _wrapperKey.currentContext;
    if (context == null) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;

    if (renderBox == null || !renderBox.hasSize) return;

    // 获取未经变换的位置
    final position = renderBox.localToGlobal(Offset.zero);

    if (_edgeOffset != position.dx) {
      setState(() {
        _edgeOffset = position.dx;
      });
    }
  }
    double _getPivotX() {
    return -50 * 0.8;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _wrapperKey, // 添加到外层容器
      child: Transform(
        origin: Offset(-_edgeOffset + _getPivotX(), 0),
        transform: Matrix4.identity()..rotateY(widget.rotation),
        child: Container(
          key: _childKey,
          child: widget.child,
        ),
      ),
    );
  }
}
