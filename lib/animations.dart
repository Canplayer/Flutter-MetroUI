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
  //翻转动画原点距离。windows phone翻页动画不是单纯的绕y轴旋转，而是有一个平移的过程。这个数值在7/8.0/8.1系统中并不一致，此处按照8.0系统来做
  late double _pivot;

  //旋转动画控制器
  late AnimationController _rotationController;
  //平移动画控制器
  late AnimationController _translationController;
  //旋转动画
  late Animation<double> _rotationAnimation;
  //平移动画
  late Animation<double> _translationAnimation;
  // 当前动画类型
  MetroAnimationType _currentAnimationType = MetroAnimationType.didPush;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _translationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 3.1415 * 0.5,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));
    _translationAnimation = Tween<double>(
      begin: 0,
      end: -1,
    ).animate(CurvedAnimation(
      parent: _translationController,
      curve: Curves.easeInCirc,
    ))
      ..addListener(() {
        setState(() {
          //_pivot的数值由320到0
          _pivot = _translationAnimation.value * 320;
        });
      });

    didPush();
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
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _translationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _rotationAnimation = Tween<double>(
      begin: -3.1415 * 0.5,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));
    _translationAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _translationController,
      curve: Curves.easeOutCirc,
    ))
      ..addListener(() {
        setState(() {
          //_pivot的数值由320到0
          _pivot = _translationAnimation.value * 320;
        });
      });

    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();
  }

  /// didPop动画：从0度旋转到-90度（页面退出）
  Future<void> didPop() async {
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _translationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: -3.1415 * 0.5,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));
    _translationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _translationController,
      curve: Curves.easeOutCirc,
    ))
      ..addListener(() {
        setState(() {
          //_pivot的数值由320到0
          _pivot = _translationAnimation.value * 320;
        });
      });

    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();
  }

  /// didPushNext动画：从0度旋转到90度（下一页进入）
  Future<void> didPushNext() async {
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _translationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 3.1415 * 0.5,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));
    _translationAnimation = Tween<double>(
      begin: 0,
      end: -1,
    ).animate(CurvedAnimation(
      parent: _translationController,
      curve: Curves.easeInCirc,
    ))
      ..addListener(() {
        setState(() {
          //_pivot的数值由320到0
          _pivot = _translationAnimation.value * 320;
        });
      });

    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();

    



  }

  /// didPopNext动画：从90度旋转到0度（下一页退出）
  Future<void> didPopNext() async {
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _translationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _rotationAnimation = Tween<double>(
      begin: 3.1415 * 0.5,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));
    _translationAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _translationController,
      curve: Curves.easeInCirc,
    ))
      ..addListener(() {
        setState(() {
          //_pivot的数值由320到0
          _pivot = _translationAnimation.value * 320;
        });
      });

    _rotationController.reset();
    _translationController.reset();
    _rotationController.forward();
    await _translationController.forward();



    // _currentAnimationType = MetroAnimationType.didPopNext;
    // _setupRotationAnimation(3.1415 * 0.5, 0); // 90° → 0°
    // _rotationController.reset();
    // _translationController.reset();
    // _rotationController.forward();
    // await _translationController.forward();
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
      animation: _rotationAnimation,
      builder: (context, child) {
        // 根据动画类型调整pivot点
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
