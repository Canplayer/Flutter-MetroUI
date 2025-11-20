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
    _rotationAnimation = Tween<double>(begin: _toRadians(-180), end: _toRadians(-90))
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
      rotationBegin: _toRadians(-63.5),
      rotationEnd: _toRadians(0),
      translationBegin: 0,
      translationEnd: 0,
      rotationDuration: const Duration(milliseconds: 350),
      translationDuration: const Duration(milliseconds: 350),
      rotationCurve: MetroCurves.normalPageRotateIn,
      translationCurve: MetroCurves.normalPageRotateIn,
    );
    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();
  }

  /// didPop动画：从0度旋转到-90度（页面退出）
  Future<void> didPop() async {
    _setupAnimation(
      rotationBegin: _toRadians(0),
      rotationEnd: _toRadians(-62.5),
      translationBegin: 0,
      translationEnd: 0,
      rotationDuration: const Duration(milliseconds: 150),
      translationDuration: const Duration(milliseconds: 150),
      rotationCurve: MetroCurves.normalPageRotateOut,
      translationCurve: MetroCurves.normalPageRotateOut,
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
      rotationEnd: _toRadians(40.5),
      translationBegin: 0,
      translationEnd: 0,
      rotationDuration: const Duration(milliseconds: 200),
      translationDuration: const Duration(milliseconds: 200),
      rotationCurve: MetroCurves.normalPageRotateOut,
      translationCurve: MetroCurves.normalPageRotateOut,
    );
    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();
  }

  /// didPopNext动画：从90度旋转到0度（下一页退出）
  Future<void> didPopNext() async {
    _setupAnimation(
      rotationBegin: _toRadians(40.5),
      rotationEnd: _toRadians(0),
      translationBegin: 0,
      translationEnd: 0,
      rotationDuration: const Duration(milliseconds: 250),
      translationDuration: const Duration(milliseconds: 250),
      rotationCurve: MetroCurves.normalPageRotateIn,
      translationCurve: MetroCurves.normalPageRotateIn
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
  /// 一个三点立方动画曲线，起始缓慢，随后加速，最后再次缓慢结束。
  /// 这个曲线可以被看作是 [easeInOutCubic] 的更陡峭版本。
  ///
  /// 当选择一个初始和结束位置都在视口内的小部件动画曲线时，这个曲线会带来更强调的缓动效果。
  ///
  /// 与 [MetroCurves.easeInOutCubic] 相比，这个曲线略微更陡峭。
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_cubic_emphasized.mp4}
  static const ThreePointCubic easeInOutCubicEmphasized = ThreePointCubic(
    Offset(0.05, 0),
    Offset(0.133333, 0.06),
    Offset(0.166666, 0.4),
    Offset(0.208333, 0.82),
    Offset(0.25, 1),
  );

  /// 一个用于panorama页面进入时候的旋转的动画曲线
  //static const Cubic panoramaRotateIn = Cubic(0.1, 0.31, 0.395, 0.89);
  static final KeyframeInterpolatedCurve panoramaRotateIn = KeyframeInterpolatedCurve(
    KeyframeBuilder.normalize(
      points: const [
        Offset(1, 95), Offset(2, 86.4), Offset(3, 79.2), Offset(4, 72.5),
        Offset(5, 66.2), Offset(6, 60.6), Offset(7, 55.2), Offset(8, 50.3),
        Offset(9, 45.7), Offset(10, 41.5), Offset(11, 37.5), Offset(12, 33.8),
        Offset(13, 30.4), Offset(14, 27.2), Offset(15, 24.3), Offset(16, 21.8),
        Offset(17, 19.2), Offset(18, 17), Offset(19, 14.8), Offset(20, 12.8),
        Offset(22, 9.2), Offset(23, 7.7), Offset(24, 6.3), Offset(25, 4.8),
        Offset(26, 3.6), Offset(27, 1.3), Offset(28, 0.3), Offset(29, 0), Offset(30, 0),
      ],
      maxTime: 30,
      maxValue: 95,
      reversed: true, // 因为原始数据是从95到0，需要反转成0到1
    ),
  );

  /// 一个用于panorama页面进入时候的内容物平移的动画曲线
  //static const Cubic panoramaTranslateIn = Cubic(0.197, 0.893, 0.41, 0.99);
  static final KeyframeInterpolatedCurve panoramaTranslateIn = KeyframeInterpolatedCurve(
    KeyframeBuilder.normalize(
      points: const [
        Offset(1, 1000), Offset(2, 923.3), Offset(3, 859.7), Offset(4, 790.2),
        Offset(5, 728.7), Offset(6, 677), Offset(7, 623.1), Offset(8, 575.6),
        Offset(9, 532.6), Offset(10, 492.2), Offset(11, 452.8), Offset(12, 417.2),
        Offset(13,385.9), Offset(14, 354.7), Offset(15, 327.7), Offset(16, 302.9),
        Offset(17, 279.2), Offset(18, 257.3), Offset(19, 237.2), Offset(21, 200.8),
        Offset(22, 185.6), Offset(24, 157.6), Offset(25, 144.5), Offset(26, 133.7),
        Offset(27, 112.1), Offset(28, 103.5), Offset(29, 94.9), Offset(30, 87.3),
        Offset(32, 73.3), Offset(33, 66.8), Offset(34, 61.6), Offset(37, 47.6),
        Offset(40, 35.6), Offset(46, 19.4), Offset(51, 10.8), Offset(56, 4.3), Offset(60, 0)
      ],
      maxTime: 60,
      maxValue: 1000,
      reversed: true, // 因为原始数据是从1000到0，需要反转成0到1
    ),
  );

  /// 普通页面退出旋转的动画曲线
  static const Cubic normalPageRotateOut = Cubic(0.6, 0.1, 0.81, 0.0);

  /// 普通页面进入旋转的动画曲线
  static const Cubic normalPageRotateIn = Cubic(0.2, 0.6, 0.21, 1);
}


class KeyframeInterpolatedCurve extends Curve {
  /// 关键帧数据点列表
  /// 每个 Offset 的 dx 表示时间（0-1），dy 表示值（0-1）
  /// 必须按时间升序排列
  final List<Offset> keyframes;

  const KeyframeInterpolatedCurve(this.keyframes)
      : assert(keyframes.length >= 2, 'At least 2 keyframes are required');

  @override
  double transformInternal(double t) {
    // 边界情况处理
    if (t <= 0.0) return keyframes.first.dy;
    if (t >= 1.0) return keyframes.last.dy;

    // 找到t所在的区间
    for (int i = 0; i < keyframes.length - 1; i++) {
      final Offset current = keyframes[i];
      final Offset next = keyframes[i + 1];

      if (t >= current.dx && t <= next.dx) {
        // 在当前区间内进行线性插值
        final double segmentProgress = (t - current.dx) / (next.dx - current.dx);
        return current.dy + (next.dy - current.dy) * segmentProgress;
      }
    }

    // 如果没有找到合适的区间，返回最后一个值
    return keyframes.last.dy;
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
    final double actualMaxTime = maxTime ?? 
        points.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final double actualMaxValue = maxValue ?? 
        points.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

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

    final double actualMaxValue = maxValue ?? 
        values.reduce((a, b) => a > b ? a : b);
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
