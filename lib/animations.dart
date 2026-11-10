import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Metro风格页面动画状态枚举
enum MetroAnimationType {
  didPush, // 进入动画（-90° → 0°）
  didPop, // 退出动画（0° → -90°）
  didPushNext, // 下一页进入动画（0° → 90°）
  didPopNext, // 下一页退出动画（90° → 0°）
}

class MetroAnimatedPage extends StatefulWidget {
  final Widget child;

  const MetroAnimatedPage({
    required this.child,
    super.key,
  });

  @override
  MetroAnimatedPageState createState() => MetroAnimatedPageState();
}

class MetroAnimatedPageState extends State<MetroAnimatedPage>
    with TickerProviderStateMixin {
  // 翻转动画原点距离
  double _pivot = 0;
  static const double _pivotMax = 320; // magic number常量化

  // 角度转弧度的常量
  static const double _degreesToRadians = 3.1415926535897932 / 180.0;

  // 将角度转换为弧度
  static double _toRadians(double degrees) => degrees * _degreesToRadians;

  late final AnimationController _rotationController;
  late final AnimationController _translationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _translationAnimation;
  final MetroAnimationType _currentAnimationType = MetroAnimationType.didPush;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0),
    );
    _translationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0),
    );
    // 初始化为静止状态，防止LateInitializationError
    _rotationAnimation =
        Tween<double>(begin: _toRadians(-180), end: _toRadians(-180))
            .animate(_rotationController);
    _translationAnimation =
        Tween<double>(begin: -100, end: -100).animate(_translationController);
    //新页面会调用这个方法，也就是说如果传入的widget默认行为将会直接播放push动画
    // didPush();
  }

  /// 设置旋转动画的角度范围
  // void _setupRotationAnimation(double begin, double end) {
  //   _rotationAnimation = Tween<double>(
  //     begin: begin,
  //     end: end,
  //   ).animate(CurvedAnimation(
  //     parent: _rotationController,
  //     curve: Curves.easeOut,
  //   ));
  // }

  /// didPush动画：从-90度旋转到0度（页面进入）
  Future<void> didPush() async {
    _setupAnimation(
      rotationBegin: _toRadians(-80),
      rotationEnd: _toRadians(0),
      translationBegin: 0,
      translationEnd: 0,
      rotationDuration: const Duration(milliseconds: 350),
      translationDuration: const Duration(milliseconds: 350),
      rotationCurve: MetroCurves.forwardIn,
      translationCurve: MetroCurves.forwardIn,
    );
    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();
  }

  /// didPushNext动画：从0度旋转到90度（下一页进入）
  Future<void> didPushNext() async {
    _setupAnimation(
      rotationBegin: _toRadians(0),
      rotationEnd: _toRadians(50),
      translationBegin: 0,
      translationEnd: 0,
      rotationDuration: const Duration(milliseconds: 167),
      translationDuration: const Duration(milliseconds: 167),
      rotationCurve: MetroCurves.forwardOut,
      translationCurve: MetroCurves.forwardOut,
    );
    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();
  }

  /// didPopNext动画：从90度旋转到0度（下一页退出）
  Future<void> didPopNext() async {
    _setupAnimation(
        rotationBegin: _toRadians(50),
        rotationEnd: _toRadians(0),
        translationBegin: 0,
        translationEnd: 0,
        rotationDuration: const Duration(milliseconds: 350),
        translationDuration: const Duration(milliseconds: 350),
        rotationCurve: MetroCurves.backwardIn,
        translationCurve: MetroCurves.backwardIn);
    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();
  }

  /// didPop动画：从0度旋转到-90度（页面退出）
  Future<void> didPop() async {
    _setupAnimation(
      rotationBegin: _toRadians(0),
      rotationEnd: _toRadians(-80),
      translationBegin: 0,
      translationEnd: 0,
      rotationDuration: const Duration(milliseconds: 167),
      translationDuration: const Duration(milliseconds: 167),
      rotationCurve: MetroCurves.backwardOut,
      translationCurve: MetroCurves.backwardOut,
    );
    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();
  }

  /// 动画参数统一设置
  void _setupAnimation({
    required double rotationBegin,
    required double rotationEnd,
    required double translationBegin,
    required double translationEnd,
    required Duration rotationDuration,
    required Duration translationDuration,
    required Curve rotationCurve,
    required Curve translationCurve,
  }) {
    _rotationController.duration = rotationDuration;
    _translationController.duration = translationDuration;
    _rotationAnimation = Tween<double>(
      begin: rotationBegin,
      end: rotationEnd,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: rotationCurve,
    ));
    _translationAnimation = Tween<double>(
      begin: translationBegin,
      end: translationEnd,
    ).animate(CurvedAnimation(
      parent: _translationController,
      curve: translationCurve,
    ))
      ..addListener(() {
        setState(() {
          _pivot = _translationAnimation.value * _pivotMax;
        });
      });
  }

  /// 播放当前动画类型的动画
  Future<void> play() async {
    switch (_currentAnimationType) {
      case MetroAnimationType.didPush:
        await didPush();
        break;
      case MetroAnimationType.didPop:
        await didPop();
        break;
      case MetroAnimationType.didPushNext:
        await didPushNext();
        break;
      case MetroAnimationType.didPopNext:
        await didPopNext();
        break;
    }
  }

  /// 重置动画
  void reset() {
    _rotationController.reset();
    _translationController.reset();
  }

  Future<void> didFinish() async {
    _setupAnimation(
      rotationBegin: _toRadians(0),
      rotationEnd: _toRadians(0),
      translationBegin: 0,
      translationEnd: 0,
      rotationDuration: const Duration(milliseconds: 1),
      translationDuration: const Duration(milliseconds: 1),
      rotationCurve: Curves.easeOut,
      translationCurve: Curves.easeOutCirc,
    );
    _rotationController.reset();
    _translationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _translationAnimation]),
      builder: (context, child) {
        double pivotX = _getPivotX();
        return Transform(
          transform: Matrix4.rotationY(_rotationAnimation.value),
          origin: Offset(pivotX, 0),
          child: widget.child,
        );
      },
    );
  }

  /// 根据动画类型获取pivot点的X坐标
  double _getPivotX() {
    return -50 * 0.8;
    // switch (_currentAnimationType) {
    //   case MetroAnimationType.didPush:
    //   case MetroAnimationType.didPop:
    //     // 左侧进入/退出，pivot点在左侧
    //     return -_pivot;
    //   case MetroAnimationType.didPushNext:
    //   case MetroAnimationType.didPopNext:
    //     // 右侧进入/退出，pivot点在右侧
    //     return _pivot;
    // }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _translationController.dispose();
    super.dispose();
  }
}

abstract final class MetroCurves {
  /// 一个用于panorama页面进入时候的旋转的动画曲线
  static const UixLog panoramaForwardIn = UixLog(10);

  

  /// 一个用于panorama页面进入时候的内容物平移的动画曲线
  //static const Cubic panoramaTranslateIn = Cubic(0.197, 0.893, 0.41, 0.99);
  static const UixLog metroTranslateIn = UixLog(150);

  /// 前进时，旧页面消失的动画曲线
  static const UixLog forwardIn = UixLog(150);

  /// 前进时，新页面出现的动画曲线
  static const UixExp forwardOut = UixExp(150);

  /// 返回时，旧页面重新出现的动画曲线
  static const UixLog backwardIn = UixLog(150);

  /// 返回时，当前页面消失
  static const UixExp backwardOut = UixExp(150);

  /// UIX `SCurve(10.0)`，ListPicker 展开等使用的 S 形缓动
  static const UixSCurve sCurve = UixSCurve(10);

  /// AppBar弹出时的动画曲线
  /// { x: 0, y: 72 },
  /// { x: 1, y: 49 },
  /// { x: 2, y: 32 },
  /// { x: 3, y: 23 },
  /// { x: 4, y: 16 },
  /// { x: 5, y: 11 },
  /// { x: 6, y: 7 },
  /// { x: 7, y: 5 },
  /// { x: 8, y: 3 },
  /// { x: 9, y: 2 },
  /// { x: 12, y: 0 }
  static const Cubic appBarTranslateIn = Cubic(
    0.106, // a (P1.x)
    0.301, // b (P1.y)
    0.090, // c (P2.x)
    0.993, // d (P2.y)
  );

  /// AppBar按钮弹出时的动画曲线
  ///     { x: 0, y: 50 },
  ///     { x: 1, y: 33 },
  ///     { x: 2, y: 19 },
  ///     { x: 3, y: 9 },
  ///     { x: 4, y: 2 },
  ///     { x: 5, y: -3 },
  ///     { x: 6, y: -6 },
  ///     { x: 7, y: -9 },
  ///     { x: 8, y: -10 },
  ///     { x: 11, y: -9 },
  ///     { x: 13, y: -8 },
  ///     { x: 18, y: -3 },
  ///     { x: 21, y: -1 },
  ///     { x: 23, y: 0 }
  static const KeyframeInterpolatedCurve appBarButtonTranslateIn =
      KeyframeInterpolatedCurve(
    [
        Offset(0.000000, 0.000000),
        Offset(0.043478, 0.340000),
        Offset(0.086957, 0.620000),
        Offset(0.130435, 0.820000),
        Offset(0.173913, 0.960000),
        Offset(0.217391, 1.060000),
        Offset(0.260870, 1.120000),
        Offset(0.304348, 1.180000),
        Offset(0.347826, 1.200000),
        Offset(0.478261, 1.180000),
        Offset(0.565217, 1.160000),
        Offset(0.782609, 1.060000),
        Offset(0.913043, 1.020000),
        Offset(1.000000, 1.000000),
    ],
  );
}

class KeyframeInterpolatedCurve extends Curve {
  /// 关键帧数据点列表
  /// 每个 Offset 的 dx 表示时间（0-1），dy 表示值（0-1）
  /// 必须按时间升序排列
  final List<Offset> keyframes;

  const KeyframeInterpolatedCurve(this.keyframes);

  @override
  double transformInternal(double t) {
    if (keyframes.isEmpty) return 0.0;
    // 边界情况处理
    if (t <= 0.0) return keyframes.first.dy;
    if (t >= 1.0) return keyframes.last.dy;

    // 找到t所在的区间
    for (int i = 0; i < keyframes.length - 1; i++) {
      final Offset current = keyframes[i];
      final Offset next = keyframes[i + 1];

      if (t >= current.dx && t <= next.dx) {
        // 在当前区间内进行线性插值
        final double segmentProgress =
            (t - current.dx) / (next.dx - current.dx);
        return current.dy + (next.dy - current.dy) * segmentProgress;
      }
    }

    // 如果没有找到合适的区间，返回最后一个值
    return keyframes.last.dy;
  }
}

/// 对数函数曲线，参数越大，起始阶段越快、末尾阶段越平缓。
class UixLog extends Curve {
  const UixLog(this.base) : assert(base > 1.0);

  final double base;

  @override
  double transformInternal(double t) {
    return (1.0 - math.pow(base, -t).toDouble()) /
        (1.0 - 1.0 / base);
  }
}

/// 指数函数曲线，参数越大，起始阶段越平缓、末尾阶段越快。
class UixExp extends Curve {
  const UixExp(this.base) : assert(base > 1.0);

  final double base;

  @override
  double transformInternal(double t) {
    return (math.pow(base, t).toDouble() - 1.0) /
    (base - 1.0);
  }
}

/// UIX `SCurve(w)`：前后两半各自是一次指数/对数缓动，在中点 0.5 处相接。
///
/// 来源 `UIXRender.dll` VA `0x10026202`（x87 代码）：
/// - `t < 0.5`  → `0.5 * F(2t, w)`
/// - `t >= 0.5` → `0.5 * F(2t - 1, 1/w) + 0.5`
///
/// 其中 `F(x, b) = (b^x - 1) / (b - 1)`，与 [UixExp]/[UixLog] 同一个归一化幂
/// 函数（`0x10026193`）。首尾斜率为 0、中点最陡，且关于中心对称。
class UixSCurve extends Curve {
  const UixSCurve(this.base) : assert(base > 1.0);

  final double base;

  @override
  double transformInternal(double t) {
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    if (t < 0.5) return 0.5 * UixExp(base).transformInternal(2 * t);
    return 0.5 + 0.5 * UixLog(base).transformInternal(2 * t - 1);
  }
}

/// 辅助类：用于从原始数据点创建关键帧
class KeyframeBuilder {
  /// 从原始数据点创建归一化的关键帧
  ///
  /// [points]: 原始数据点列表，每个点的 dx 是时间，dy 是值
  /// [maxTime]: 最大时间值（用于归一化时间）
  /// [maxValue]: 最大值（用于归一化数值）
  /// [reversed]: 是否反转 y 值（如果原始数据是从大到小）
  static List<Offset> normalize({
    required List<Offset> points,
    double? maxTime,
    double? maxValue,
    bool reversed = false,
  }) {
    if (points.isEmpty) return [];

    // 自动计算最大值
    final double actualMaxTime =
        maxTime ?? points.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final double actualMaxValue =
        maxValue ?? points.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

    return points.map((point) {
      final double normalizedX = point.dx / actualMaxTime;
      final double normalizedY = reversed
          ? 1.0 - (point.dy / actualMaxValue)
          : point.dy / actualMaxValue;
      return Offset(normalizedX, normalizedY);
    }).toList();
  }

  /// 从简单的数值列表创建关键帧
  ///
  /// [values]: 数值列表
  /// [maxValue]: 最大值（用于归一化）
  /// [reversed]: 是否反转值
  static List<Offset> fromValues({
    required List<double> values,
    double? maxValue,
    bool reversed = false,
  }) {
    if (values.isEmpty) return [];

    final double actualMaxValue =
        maxValue ?? values.reduce((a, b) => a > b ? a : b);
    final int count = values.length;

    return List.generate(count, (index) {
      final double normalizedX = index / (count - 1);
      final double normalizedY = reversed
          ? 1.0 - (values[index] / actualMaxValue)
          : values[index] / actualMaxValue;
      return Offset(normalizedX, normalizedY);
    });
  }
}
