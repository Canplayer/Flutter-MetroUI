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

  late final AnimationController _rotationController;
  late final AnimationController _translationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _translationAnimation;
  MetroAnimationType _currentAnimationType = MetroAnimationType.didPush;

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
    _rotationAnimation = Tween<double>(begin: -3.1415926, end: -3.1415926 * 0.5).animate(_rotationController);
    _translationAnimation = Tween<double>(begin: -100, end: -100).animate(_translationController);
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
    print('didPush animation start');
    _setupAnimation(
      rotationBegin: -3.1415926 * 0.5,
      rotationEnd: 0,
      translationBegin: 1,
      translationEnd: 0,
      rotationDuration: const Duration(milliseconds: 450),
      translationDuration: const Duration(milliseconds: 850),
      rotationCurve: Curves.easeOut,
      translationCurve: Curves.easeOutCirc,
    );
    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();
  }

  /// didPop动画：从0度旋转到-90度（页面退出）
  Future<void> didPop() async {
    _setupAnimation(
      rotationBegin: 0,
      rotationEnd: -3.1415926 * 0.5,
      translationBegin: 0,
      translationEnd: 1,
      rotationDuration: const Duration(milliseconds: 200),
      translationDuration: const Duration(milliseconds: 200),
      rotationCurve: Curves.easeOut,
      translationCurve: Curves.easeOutCirc,
    );
    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();
  }

  /// didPushNext动画：从0度旋转到90度（下一页进入）
  Future<void> didPushNext() async {
    _setupAnimation(
      rotationBegin: 0,
      rotationEnd: 3.1415926 * 0.5,
      translationBegin: 0,
      translationEnd: 1,
      rotationDuration: const Duration(milliseconds: 200),
      translationDuration: const Duration(milliseconds: 200),
      rotationCurve: Curves.easeOut,
      translationCurve: Curves.easeInCirc,
    );
    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();
  }

  /// didPopNext动画：从90度旋转到0度（下一页退出）
  Future<void> didPopNext() async {
    _setupAnimation(
      rotationBegin: 3.1415926 * 0.5,
      rotationEnd: 0,
      translationBegin: 1,
      translationEnd: 0,
      rotationDuration: const Duration(milliseconds: 450),
      translationDuration: const Duration(milliseconds: 850),
      rotationCurve: Curves.easeOut,
      translationCurve: Curves.easeInCirc,
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
    switch (_currentAnimationType) {
      case MetroAnimationType.didPush:
      case MetroAnimationType.didPop:
        // 左侧进入/退出，pivot点在左侧
        return -_pivot;
      case MetroAnimationType.didPushNext:
      case MetroAnimationType.didPopNext:
        // 右侧进入/退出，pivot点在右侧
        return _pivot;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _translationController.dispose();
    super.dispose();
  }
}
