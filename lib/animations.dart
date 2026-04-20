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
        translationCurve: MetroCurves.normalPageRotateIn);
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
  static const KeyframeInterpolatedCurve panoramaRotateIn_8 =
      KeyframeInterpolatedCurve(
    // { x: 0.0, y: -86.8978 },{ x: 0.960937, y: -79.6849 },{ x: 1.89453, y: -72.937 },{ x: 2.83203, y: -66.6736 },
    // { x: 3.76953, y: -61.0616 },{ x: 4.70508, y: -55.6501 },{ x: 5.64062, y: -50.7396 },{ x: 6.57617, y: -46.1298 },
    // { x: 7.51172, y: -41.9208 },{ x: 8.44922, y: -37.9123 },{ x: 9.38477, y: -34.2044 },{ x: 10.3223, y: -30.9324 },
    // { x: 11.2969, y: -27.5903 },{ x: 12.2324, y: -24.6841 },{ x: 13.0937, y: -22.0117 },{ x: 14.1035, y: -19.5732 },
    // { x: 14.9668, y: -17.5355 },{ x: 15.9766, y: -15.1638 },{ x: 16.9121, y: -13.1595 },{ x: 18.7871, y: -9.55179 },
    // { x: 19.6445, y: -8.19969 },{ x: 20.584, y: -6.51256 },{ x: 21.5937, y: -5.14239 },{ x: 22.5293, y: -3.93982 },
    // { x: 23.3906, y: -2.63729 },{ x: 24.3262, y: -1.46809 },{ x: 25.2988, y: -0.483097 },{ x: 26, y: 0 }
    [
      Offset(0.000000, 0.000000),
      Offset(0.036959, 0.083004),
      Offset(0.072867, 0.160658),
      Offset(0.108924, 0.232735),
      Offset(0.144982, 0.297317),
      Offset(0.180965, 0.359591),
      Offset(0.216947, 0.416100),
      Offset(0.252930, 0.469149),
      Offset(0.288912, 0.517585),
      Offset(0.324970, 0.563714),
      Offset(0.360953, 0.606384),
      Offset(0.397012, 0.644037),
      Offset(0.434496, 0.682497),
      Offset(0.470477, 0.715941),
      Offset(0.503604, 0.746694),
      Offset(0.542442, 0.774756),
      Offset(0.575646, 0.798205),
      Offset(0.614485, 0.825498),
      Offset(0.650465, 0.848563),
      Offset(0.722581, 0.890080),
      Offset(0.755558, 0.905640),
      Offset(0.791692, 0.925055),
      Offset(0.830527, 0.940823),
      Offset(0.866512, 0.954661),
      Offset(0.899638, 0.969651),
      Offset(0.935623, 0.983106),
      Offset(0.973031, 0.994441),
      Offset(1.000000, 1.000000),
    ],
  );

  /// 贝塞尔曲线近似版本panorama页面进入时候的旋转的动画曲线
  static const Cubic panoramaRotateIn2_8 = Cubic(0.096, 0.197, 0.31, 0.810);

  /// 一个用于panorama页面进入时候的内容物平移的动画曲线
  //static const Cubic panoramaTranslateIn = Cubic(0.197, 0.893, 0.41, 0.99);
  static const KeyframeInterpolatedCurve panoramaTranslateIn =
      KeyframeInterpolatedCurve(
    // { x: 0, y: 1340 },
    // { x: 1, y: 1234.7 },
    // { x: 2.443, y: 1125.91 },
    // { x: 3.443, y: 1051.31 },
    // { x: 4.443, y: 980.536 },
    // { x: 5.443, y: 920.238 },
    // { x: 6.443, y: 867.093 },
    // { x: 7.443, y: 817.545 },
    // { x: 8.443, y: 768.67 },
    // { x: 9.443, y: 725.109 },
    // { x: 10.443, y: 685.568 },
    // { x: 11.0, y: 665.596 },
    // { x: 12.0, y: 631.626 },
    // { x: 13.0, y: 596.672 },
    // { x: 14.0, y: 570.387 },
    // { x: 15.0, y: 544.673 },
    // { x: 16.0, y: 520.958 },
    // { x: 17.0, y: 498.813 },
    // { x: 18.0, y: 479.395 },
    // { x: 19.0, y: 460.65 },
    // { x: 20.0, y: 443.68 },
    // { x: 21.0, y: 427.998 },
    // { x: 22.0, y: 413.392 },
    // { x: 23.0, y: 400.229 },
    // { x: 24.0, y: 387.855 },
    // { x: 25.0, y: 376.886 },
    // { x: 26.0, y: 366.083 },
    // { x: 27.0, y: 356.351 },
    // { x: 28.0, y: 347.33 },
    // { x: 29.0, y: 338.727 },
    // { x: 30.0, y: 331.657 },
    // { x: 31.0, y: 324.282 },
    // { x: 32.0, y: 317.773 },
    // { x: 33.0, y: 311.733 },
    // { x: 34.0, y: 306.102 },
    // { x: 35.0, y: 301.595 },
    // { x: 36.0, y: 296.158 },
    // { x: 37.0, y: 291.83 },
    // { x: 38.0, y: 287.778 },
    // { x: 41.0, y: 275.939 },
    // { x: 43.0, y: 270.274 },
    // { x: 44.0, y: 268.061 },
    // { x: 46.0, y: 264.345 },
    // { x: 47.0, y: 262.373 },
    // { x: 49.0, y: 259.232 },
    // { x: 50.0, y: 257.837 },
    // { x: 51.0, y: 256.442 },
    // { x: 54.0, y: 252.831 },
    // { x: 55.0, y: 252.176 },
    // { x: 56.0, y: 251.428 },
    // { x: 57.0, y: 250.847 },
    // { x: 59.0, y: 250 }
    [
      Offset(0.000000, 0.000000),
      Offset(0.016942, 0.095873),
      Offset(0.042356, 0.194563),
      Offset(0.059298, 0.270989),
      Offset(0.071310, 0.312358),
      Offset(0.093521, 0.388718),
      Offset(0.110464, 0.439922),
      Offset(0.126440, 0.483617),
      Offset(0.143382, 0.527594),
      Offset(0.156021, 0.557121),
      Offset(0.177267, 0.602477),
      Offset(0.189906, 0.627218),
      Offset(0.203714, 0.652792),
      Offset(0.220656, 0.682681),
      Offset(0.240733, 0.712850),
      Offset(0.254541, 0.732275),
      Offset(0.271483, 0.755283),
      Offset(0.288425, 0.775790),
      Offset(0.304469, 0.794233),
      Offset(0.321412, 0.811663),
      Offset(0.338354, 0.827782),
      Offset(0.355296, 0.842362),
      Offset(0.372238, 0.856282),
      Offset(0.390079, 0.869204),
      Offset(0.407021, 0.880708),
      Offset(0.423963, 0.891248),
      Offset(0.440905, 0.900609),
      Offset(0.460982, 0.910943),
      Offset(0.474790, 0.917509),
      Offset(0.491732, 0.925098),
      Offset(0.508674, 0.931847),
      Offset(0.525617, 0.938202),
      Offset(0.542559, 0.944073),
      Offset(0.559501, 0.949496),
      Offset(0.579578, 0.954529),
      Offset(0.593386, 0.958489),
      Offset(0.610328, 0.963008),
      Offset(0.627270, 0.966878),
      Offset(0.644213, 0.970041),
      Offset(0.695039, 0.978601),
      Offset(0.728924, 0.983366),
      Offset(0.745866, 0.985435),
      Offset(0.779751, 0.989209),
      Offset(0.796693, 0.990731),
      Offset(0.830577, 0.993361),
      Offset(0.847520, 0.994679),
      Offset(0.864462, 0.996080),
      Offset(0.901481, 0.998228),
      Offset(0.915289, 0.998776),
      Offset(0.935365, 0.999824),
      Offset(1.000000, 1.000000),
    ],
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
