// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum _MetroPageSlot {
  body, //主体
  statusBar, //状态栏
}

/// 管理后代 [MetroPageScaffold] 的 [SnackBar] 和 [MetroBanner]。
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=lytQi-slT5Y}
///
/// 该类提供了在屏幕底部和顶部显示 snack bars 和 material banners 的 API。
///
/// 要显示这些通知，请通过 [MetroPageMessenger.of] 获取当前 [BuildContext] 的 [MetroPageMessengerState]，
/// 然后使用 [MetroPageMessengerState.showSnackBar] 或 [MetroPageMessengerState.showMetroBanner] 函数。
///
/// 当 [MetroPageMessenger] 有嵌套的 [MetroPageScaffold] 后代时，MetroPageMessenger 只会将通知显示给子树中根 Scaffold。
/// 为了在内部嵌套的 Scaffold 中显示通知，请在嵌套级别之间实例化一个新的 MetroPageMessenger 以设置新的作用域。
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=lytQi-slT5Y}
///
/// 另请参阅:
///
///  * [SnackBar]，它是一个临时通知，通常使用 [MetroPageMessengerState.showSnackBar] 方法显示在应用程序的底部。
///  * [Metroanner]，它是一个临时通知，通常使用 [MetroPageMessengerState.showMetroBanner] 方法显示在应用程序的顶部。
///  * [debugCheckHasMetroPageMessenger]，它断言给定的上下文有一个 [MetroPageMessenger] 祖先。
///  * Cookbook: [显示 SnackBar](https://docs.flutter.dev/cookbook/design/snackbars)
class MetroPageMessenger extends StatefulWidget {
  /// Creates a widget that manages [SnackBar]s for [MetroPageScaffold] descendants.
  const MetroPageMessenger({
    super.key,
    required this.child,
  });

  /// 这个小部件在树中的下面。
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// 获取最近的 [MetroPageMessenger] 实例的状态。
  ///
  /// {@tool dartpad}
  /// [MetroPageMessenger.of] 函数的典型用法是在响应用户手势或应用程序状态变化时调用。
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold_messenger.of.0.dart 中的代码 **
  /// {@end-tool}
  ///
  /// 一种不太优雅但更快捷的解决方案是为 [MetroPageMessenger] 分配一个 [GlobalKey]，
  /// 然后使用 `key.currentState` 属性来获取 [MetroPageMessengerState]，而不是使用
  /// [MetroPageMessenger.of] 函数。[MaterialApp.scaffoldMessengerKey] 指的是默认提供的根
  /// MetroPageMessenger。
  ///
  /// {@tool dartpad}
  /// 有时 [SnackBar] 是由无法轻易访问有效 [BuildContext] 的代码生成的。一个这样的例子是
  /// 当你在 `build` 函数之外的方法中显示一个 SnackBar 时。在这些情况下，你可以为
  /// [MetroPageMessenger] 分配一个 [GlobalKey]。这个示例展示了如何使用一个 key 来获取
  /// [MaterialApp] 提供的 [MetroPageMessengerState]。
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold_messenger.of.1.dart 中的代码 **
  /// {@end-tool}
  ///
  /// 如果范围内没有 [MetroPageMessenger]，则在调试模式下会断言，并在发布模式下抛出异常。
  ///
  /// 另请参阅:
  ///
  ///  * [maybeOf]，这是一个类似的函数，但如果没有 [MetroPageMessenger] 祖先，它将返回 null 而不是抛出异常。
  ///  * [debugCheckHasMetroPageMessenger]，它断言给定的上下文有一个 [MetroPageMessenger] 祖先。
  static MetroPageMessengerState of(BuildContext context) {
    //assert(debugCheckHasMetroPageMessenger(context));

    final _MetroPageMessengerScope scope =
        context.dependOnInheritedWidgetOfExactType<_MetroPageMessengerScope>()!;
    return scope._scaffoldMessengerState;
  }

  /// 从给定上下文中最近的此类实例中获取状态，如果有的话。
  ///
  /// 如果在给定上下文中未找到 [MetroPageMessenger]，将返回 null。
  ///
  /// 另请参见:
  ///
  ///  * [of]，这是一个类似的函数，不同之处在于如果在给定上下文中未找到 [MetroPageMessenger]，它将抛出异常。
  static MetroPageMessengerState? maybeOf(BuildContext context) {
    final _MetroPageMessengerScope? scope =
        context.dependOnInheritedWidgetOfExactType<_MetroPageMessengerScope>();
    return scope?._scaffoldMessengerState;
  }

  @override
  MetroPageMessengerState createState() => MetroPageMessengerState();
}

/// [MetroPageMessenger] 的状态。
///
/// [MetroPageMessengerState] 对象可用于为每个注册的 [MetroPageScaffold] 显示 [SnackBar] 或 [MetroBanner]，
/// 这些 [MetroPageScaffold] 是关联的 [MetroPageMessenger] 的后代。
/// Scaffolds 将注册以从其最近的 MetroPageMessenger 祖先接收 [SnackBar] 和 [MetroBanner]。
///
/// 通常通过 [MetroPageMessenger.of] 获取。
class MetroPageMessengerState extends State<MetroPageMessenger>
    with TickerProviderStateMixin {
  final LinkedHashSet<MetroPageScaffoldState> _scaffolds =
      LinkedHashSet<MetroPageScaffoldState>();

  bool? _accessibleNavigation;

  @override
  void didChangeDependencies() {
    final bool accessibleNavigation =
        MediaQuery.accessibleNavigationOf(context);
    // 如果我们从无障碍导航过渡到非无障碍导航
    // 并且有一个 SnackBar 本应超时但已经
    // 完成了它的计时器，则关闭该 SnackBar。如果计时器尚未完成
    // 让它正常超时。
    // if ((_accessibleNavigation ?? false) &&
    //     !accessibleNavigation) {
    //   hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
    // }
    _accessibleNavigation = accessibleNavigation;
    super.didChangeDependencies();
  }

  void _register(MetroPageScaffoldState page) {
    _scaffolds.add(page);

    if (_isRoot(page)) {
      // if (_snackBars.isNotEmpty) {
      //   scaffold._updateSnackBar();
      // }

      // if (_metroBanners.isNotEmpty) {
      //   scaffold._updateMetroBanner();
      // }
    }
  }

  void _unregister(MetroPageScaffoldState scaffold) {
    final bool removed = _scaffolds.remove(scaffold);
    // ScaffoldStates应该只被移除一次。
    assert(removed);
  }

  // void _updateScaffolds() {
  //   for (final MetroPageState scaffold in _scaffolds) {
  //     if (_isRoot(scaffold)) {
  //       // scaffold._updateSnackBar();
  //       // scaffold._updateMetroBanner();
  //     }
  //   }
  // }

  // 嵌套的 Scaffold 由 MetroPageMessenger 处理，仅在嵌套集的根 Scaffold 中显示 MetroBanner 或 SnackBar。
  bool _isRoot(MetroPageScaffoldState scaffold) {
    final MetroPageScaffoldState? parent =
        scaffold.context.findAncestorStateOfType<MetroPageScaffoldState>();
    return parent == null || !_scaffolds.contains(parent);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    _accessibleNavigation = MediaQuery.accessibleNavigationOf(context);

    return _MetroPageMessengerScope(
      scaffoldMessengerState: this,
      child: widget.child,
    );
  }

  // @override
  // void dispose() {
  //   super.dispose();
  // }
}

class _MetroPageMessengerScope extends InheritedWidget {
  const _MetroPageMessengerScope({
    required super.child,
    required MetroPageMessengerState scaffoldMessengerState,
  }) : _scaffoldMessengerState = scaffoldMessengerState;

  final MetroPageMessengerState _scaffoldMessengerState;

  @override
  bool updateShouldNotify(_MetroPageMessengerScope old) =>
      _scaffoldMessengerState != old._scaffoldMessengerState;
}

/// [MetroPageScaffold] 布局完所有内容后的空间信息。
///
/// 想了解 [MetroPageScaffold] 完成布局后的详细几何信息，可以看看 [MetroPageGeometry]。
@immutable
class MetroPagePrelayoutGeometry {
  /// 抽象常量构造函数。这个构造函数允许子类提供常量构造函数，以便在常量表达式中使用。
  const MetroPagePrelayoutGeometry({
    required this.contentBottom,
    required this.contentTop,
    required this.minInsets,
    required this.minViewPadding,
    required this.scaffoldSize,
    required this.textDirection,
  });

  /// 从 Scaffold 原点到 [MetroPageScaffold.body] 底部的垂直距离。
  ///
  /// 这在设计将 [FloatingActionButton] 放置在屏幕底部的 [FloatingActionButtonLocation] 中很有用，
  /// 同时将其保持在 [BottomSheet]、[MetroPageScaffold.bottomNavigationBar] 或键盘之上。
  ///
  /// [MetroPageScaffold.body] 已根据 [minInsets] 进行布局，这意味着 [FloatingActionButtonLocation]
  /// 在将 [FloatingActionButton] 对齐到 [contentBottom] 时，无需考虑 [minInsets] 的 [EdgeInsets.bottom]。
  final double contentBottom;

  /// 从 [MetroPageScaffold] 原点到 [MetroPageScaffold.body] 顶部的垂直距离。
  ///
  /// 这在设计将 [FloatingActionButton] 放置在屏幕顶部的 [FloatingActionButtonLocation] 中很有用，
  /// 同时将其保持在 [MetroPageScaffold.appBar] 之下。
  ///
  /// [MetroPageScaffold.body] 已根据 [minInsets] 进行布局，这意味着 [FloatingActionButtonLocation]
  /// 在将 [FloatingActionButton] 对齐到 [contentTop] 时，无需考虑 [minInsets] 的 [EdgeInsets.top]。
  final double contentTop;

  /// 为了使 [FloatingActionButton] 保持可见，所需的最小内边距。
  ///
  /// 这个值是通过在 [MetroPageScaffold] 的 [BuildContext] 中调用 [MediaQueryData.padding] 得到的，
  /// 用于给 [FloatingActionButton] 添加内边距，以避免系统状态栏或键盘等元素。
  ///
  /// 如果 [MetroPageScaffold.resizeToAvoidBottomInset] 设置为 false，
  /// [minInsets] 的 [EdgeInsets.bottom] 将为 0.0。
  final EdgeInsets minInsets;

  /// 为了让交互元素位于安全、无遮挡的空间内，所需的最小内边距。
  ///
  /// 当 [MetroPageScaffold.resizeToAvoidBottomInset] 为 false 或 [MediaQueryData.viewInsets] > 0.0 时，
  /// 这个值反映了 [MetroPageScaffold] 的 [BuildContext] 的 [MediaQueryData.viewPadding]。
  /// 这有助于区分屏幕上不同类型的遮挡，例如软件键盘和设备的物理刘海。
  final EdgeInsets minViewPadding;

  /// 整个 [MetroPageScaffold] 的尺寸。
  ///
  /// 如果 [MetroPageScaffold] 内容的尺寸由于像 [MetroPageScaffold.resizeToAvoidBottomInset] 或键盘弹出等因素而被修改，
  /// 则 [scaffoldSize] 不会反映这些更改。
  ///
  /// 这意味着，设计用于根据键盘弹出等事件重新定位 [FloatingActionButton] 的 [FloatingActionButtonLocation]
  /// 应该使用 [minInsets] 确保 [FloatingActionButton] 有足够的内边距以保持可见。
  ///
  /// 有关应用适当内边距的更多信息，请参见 [minInsets] 和 [MediaQueryData.padding]。
  final Size scaffoldSize;

  /// [MetroPageScaffold] 的 [BuildContext] 的文字方向。
  final TextDirection textDirection;
}

// 用于将 Scaffold 的 bottomNavigationBar 和 persistentFooterButtons 的高度传递给构建 Scaffold body 的 LayoutBuilder。
//
// Scaffold 期望将 _BodyBoxConstraints 传递给 _BodyBuilder 小部件的 LayoutBuilder，详见 _ScaffoldLayout.performLayout()。
// BoxConstraints 的方法，如 copyWith()，在这里没有被重写，因为我们预计 _BodyBoxConstraintsObject 会未经修改地传递给 LayoutBuilder。
// 如果将来有变化，_BodyBuilder 会进行断言。
class _BodyBoxConstraints extends BoxConstraints {
  const _BodyBoxConstraints({
    super.maxWidth,
    super.maxHeight,
    required this.bottomWidgetsHeight,
  }) : assert(bottomWidgetsHeight >= 0);

  final double bottomWidgetsHeight;

  // RenderObject.layout() 只有当新的布局约束和当前的不一样时，才会停止调用 performLayout 方法。
  // 如果底部部件的高度改变了，即使约束的最小值和最大值没变，我们还是想让 performLayout 执行。
  @override
  bool operator ==(Object other) {
    if (super != other) {
      return false;
    }
    return other is _BodyBoxConstraints &&
        other.bottomWidgetsHeight == bottomWidgetsHeight;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, bottomWidgetsHeight);
}

// 当 Scaffold 的 extendBody 为 true 时，使用 MediaQuery 包裹 scaffold 的 body，
// 其 padding 会考虑 bottomNavigationBar 和/或 persistentFooterButtons 的高度。
//
// 底部组件的高度通过 _BodyBoxConstraints 参数传递。
// constraints 参数在 _ScaffoldLayout.performLayout() 中构建。
class _BodyBuilder extends StatelessWidget {
  const _BodyBuilder({
    required this.body,
  });

  final Widget body;

  @override
  Widget build(BuildContext context) {
    // if (!extendBody) {
    //   return body;
    // }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final _BodyBoxConstraints bodyConstraints =
            constraints as _BodyBoxConstraints;
        final MediaQueryData metrics = MediaQuery.of(context);

        final double bottom = math.max(
            metrics.padding.bottom, bodyConstraints.bottomWidgetsHeight);

        final double top = metrics.padding.top;

        return MediaQuery(
          data: metrics.copyWith(
            padding: metrics.padding.copyWith(
              top: top,
              bottom: bottom,
            ),
          ),
          child: body,
        );
      },
    );
  }
}

class _MetroPageLayout extends MultiChildLayoutDelegate {
  _MetroPageLayout({
    required this.minInsets,
    required this.minViewPadding,
    required this.textDirection,
    required this.extendBody,
  });

  final bool extendBody;
  final EdgeInsets minInsets;
  final EdgeInsets minViewPadding;
  final TextDirection textDirection;

  @override
  void performLayout(Size size) {
    final BoxConstraints looseConstraints = BoxConstraints.loose(size);

    // 这部分布局的效果与将应用栏和主体放在一列并使主体可伸缩相同。不同之处在于，在这种情况下，应用栏出现在主体之后，因此应用栏的阴影绘制在主体的顶部。

    final BoxConstraints fullWidthConstraints =
        looseConstraints.tighten(width: size.width);
    final double bottom = size.height;
    double contentTop = 0.0;
    double bottomWidgetsHeight = 0.0;

    // 设置内容底部，考虑底部组件或键盘等系统UI的高度中较大的值。
    final double contentBottom =
        math.max(0.0, bottom - math.max(minInsets.bottom, bottomWidgetsHeight));

    if (hasChild(_MetroPageSlot.body)) {
      double bodyMaxHeight = math.max(0.0, contentBottom - contentTop);

      if (extendBody) {
        bodyMaxHeight += bottomWidgetsHeight;
        bodyMaxHeight = clampDouble(
            bodyMaxHeight, 0.0, looseConstraints.maxHeight - contentTop);
        assert(bodyMaxHeight <=
            math.max(0.0, looseConstraints.maxHeight - contentTop));
      }

      final BoxConstraints bodyConstraints = _BodyBoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: bodyMaxHeight,
        bottomWidgetsHeight: extendBody ? bottomWidgetsHeight : 0.0,
      );
      layoutChild(_MetroPageSlot.body, bodyConstraints);
      positionChild(_MetroPageSlot.body, Offset(0.0, contentTop));
    }

    if (hasChild(_MetroPageSlot.statusBar)) {
      layoutChild(_MetroPageSlot.statusBar,
          fullWidthConstraints.tighten(height: minInsets.top));
      positionChild(_MetroPageSlot.statusBar, Offset.zero);
    }

    // geometryNotifier._updateWith(
    //   //bottomNavigationBarTop: bottomNavigationBarTop,
    // );
  }

  @override
  bool shouldRelayout(_MetroPageLayout oldDelegate) {
    return oldDelegate.minInsets != minInsets ||
        oldDelegate.minViewPadding != minViewPadding ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.extendBody != extendBody;
  }
}

/// 处理 [FloatingActionButton] 的缩放和旋转动画。
///
/// 目前，[FloatingActionButton] 有两种类型的动画：
///
/// * 进场/退场动画，当 [FloatingActionButton] 被添加、更新或移除时，此小部件会触发这些动画。
/// * 运动动画，当其 [FloatingActionButtonLocation] 被更新时，[MetroPageScaffold] 会触发这些动画。
class _FloatingActionButtonTransition extends StatefulWidget {
  const _FloatingActionButtonTransition({
    required this.child,
    required this.fabMoveAnimation,
    required this.fabMotionAnimator,
    required this.currentController,
  });

  final Widget? child;
  final Animation<double> fabMoveAnimation;
  final FloatingActionButtonAnimator fabMotionAnimator;

  /// Controls the current child widget.child as it exits.
  final AnimationController currentController;

  @override
  _FloatingActionButtonTransitionState createState() =>
      _FloatingActionButtonTransitionState();
}

class _FloatingActionButtonTransitionState
    extends State<_FloatingActionButtonTransition>
    with TickerProviderStateMixin {
  // The animations applied to the Floating Action Button when it is entering or exiting.
  // Controls the previous widget.child as it exits.
  late AnimationController _previousController;
  CurvedAnimation? _previousExitScaleAnimation;
  CurvedAnimation? _previousExitRotationCurvedAnimation;
  CurvedAnimation? _currentEntranceScaleAnimation;
  late Animation<double> _previousScaleAnimation;
  late TrainHoppingAnimation _previousRotationAnimation;
  // The animations to run, considering the widget's fabMoveAnimation and the current/previous entrance/exit animations.
  late Animation<double> _currentScaleAnimation;
  late Animation<double> _extendedCurrentScaleAnimation;
  late TrainHoppingAnimation _currentRotationAnimation;
  Widget? _previousChild;

  @override
  void initState() {
    super.initState();

    _previousController = AnimationController(
      duration: kFloatingActionButtonSegue,
      vsync: this,
    )..addStatusListener(_handlePreviousAnimationStatusChanged);
    _updateAnimations();

    if (widget.child != null) {
      // If we start out with a child, have the child appear fully visible instead
      // of animating in.
      widget.currentController.value = 1.0;
    } else {
      // If we start without a child we update the geometry object with a
      // floating action button scale of 0, as it is not showing on the screen.
      _updateGeometryScale(0.0);
    }
  }

  @override
  void dispose() {
    _previousController.dispose();
    _previousExitScaleAnimation?.dispose();
    _previousExitRotationCurvedAnimation?.dispose();
    _currentEntranceScaleAnimation?.dispose();
    _disposeAnimations();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FloatingActionButtonTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fabMotionAnimator != widget.fabMotionAnimator ||
        oldWidget.fabMoveAnimation != widget.fabMoveAnimation) {
      _disposeAnimations();
      // Get the right scale and rotation animations to use for this widget.
      _updateAnimations();
    }
    final bool oldChildIsNull = oldWidget.child == null;
    final bool newChildIsNull = widget.child == null;
    if (oldChildIsNull == newChildIsNull &&
        oldWidget.child?.key == widget.child?.key) {
      return;
    }
    if (_previousController.isDismissed) {
      final double currentValue = widget.currentController.value;
      if (currentValue == 0.0 || oldWidget.child == null) {
        // The current child hasn't started its entrance animation yet. We can
        // just skip directly to the new child's entrance.
        _previousChild = null;
        if (widget.child != null) {
          widget.currentController.forward();
        }
      } else {
        // Otherwise, we need to copy the state from the current controller to
        // the previous controller and run an exit animation for the previous
        // widget before running the entrance animation for the new child.
        _previousChild = oldWidget.child;
        _previousController
          ..value = currentValue
          ..reverse();
        widget.currentController.value = 0.0;
      }
    }
  }

  static final Animatable<double> _entranceTurnTween = Tween<double>(
    begin: 1.0 - kFloatingActionButtonTurnInterval,
    end: 1.0,
  ).chain(CurveTween(curve: Curves.easeIn));

  void _disposeAnimations() {
    _previousRotationAnimation.dispose();
    _currentRotationAnimation.dispose();
  }

  void _updateAnimations() {
    _previousExitScaleAnimation?.dispose();
    // Get the animations for exit and entrance.
    _previousExitScaleAnimation = CurvedAnimation(
      parent: _previousController,
      curve: Curves.easeIn,
    );
    _previousExitRotationCurvedAnimation?.dispose();
    _previousExitRotationCurvedAnimation = CurvedAnimation(
      parent: _previousController,
      curve: Curves.easeIn,
    );

    final Animation<double> previousExitRotationAnimation =
        Tween<double>(begin: 1.0, end: 1.0)
            .animate(_previousExitRotationCurvedAnimation!);

    _currentEntranceScaleAnimation?.dispose();
    _currentEntranceScaleAnimation = CurvedAnimation(
      parent: widget.currentController,
      curve: Curves.easeIn,
    );
    final Animation<double> currentEntranceRotationAnimation =
        widget.currentController.drive(_entranceTurnTween);

    // Get the animations for when the FAB is moving.
    final Animation<double> moveScaleAnimation = widget.fabMotionAnimator
        .getScaleAnimation(parent: widget.fabMoveAnimation);
    final Animation<double> moveRotationAnimation = widget.fabMotionAnimator
        .getRotationAnimation(parent: widget.fabMoveAnimation);

    // Aggregate the animations.
    if (widget.fabMotionAnimator == FloatingActionButtonAnimator.noAnimation) {
      _previousScaleAnimation = moveScaleAnimation;
      _currentScaleAnimation = moveScaleAnimation;
      _previousRotationAnimation =
          TrainHoppingAnimation(moveRotationAnimation, null);
      _currentRotationAnimation =
          TrainHoppingAnimation(moveRotationAnimation, null);
    } else {
      _previousScaleAnimation = AnimationMin<double>(
          moveScaleAnimation, _previousExitScaleAnimation!);
      _currentScaleAnimation = AnimationMin<double>(
          moveScaleAnimation, _currentEntranceScaleAnimation!);
      _previousRotationAnimation = TrainHoppingAnimation(
          previousExitRotationAnimation, moveRotationAnimation);
      _currentRotationAnimation = TrainHoppingAnimation(
          currentEntranceRotationAnimation, moveRotationAnimation);
    }

    _extendedCurrentScaleAnimation = _currentScaleAnimation
        .drive(CurveTween(curve: const Interval(0.0, 0.1)));
    _currentScaleAnimation.addListener(_onProgressChanged);
    _previousScaleAnimation.addListener(_onProgressChanged);
  }

  void _handlePreviousAnimationStatusChanged(AnimationStatus status) {
    setState(() {
      if (widget.child != null && status.isDismissed) {
        assert(widget.currentController.isDismissed);
        widget.currentController.forward();
      }
    });
  }

  bool _isExtendedFloatingActionButton(Widget? widget) {
    return widget is FloatingActionButton && widget.isExtended;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: <Widget>[
        if (!_previousController.isDismissed)
          if (_isExtendedFloatingActionButton(_previousChild))
            FadeTransition(
              opacity: _previousScaleAnimation,
              child: _previousChild,
            )
          else
            ScaleTransition(
              scale: _previousScaleAnimation,
              child: RotationTransition(
                turns: _previousRotationAnimation,
                child: _previousChild,
              ),
            ),
        if (_isExtendedFloatingActionButton(widget.child))
          ScaleTransition(
            scale: _extendedCurrentScaleAnimation,
            child: FadeTransition(
              opacity: _currentScaleAnimation,
              child: widget.child,
            ),
          )
        else
          ScaleTransition(
            scale: _currentScaleAnimation,
            child: RotationTransition(
              turns: _currentRotationAnimation,
              child: widget.child,
            ),
          ),
      ],
    );
  }

  void _onProgressChanged() {
    _updateGeometryScale(
        math.max(_previousScaleAnimation.value, _currentScaleAnimation.value));
  }

  void _updateGeometryScale(double scale) {
    // widget.geometryNotifier._updateWith(
    //     //floatingActionButtonScale: scale,
    //     );
  }
}

/// 实现基本的 Material Design 视觉布局结构。
///
/// 注：Windows Phone的底部菜单和这个逻辑不一样所以需要进行移除改造
///
/// 此类提供显示抽屉和底部工作表的 API。
///
/// 若要显示一个持久性的底部工作表，请通过 [MetroPageScaffold.of] 获取当前 [BuildContext] 的
/// [MetroPageScaffoldState]，并使用 [MetroPageScaffoldState.showBottomSheet] 函数。
///
/// {@tool dartpad}
/// 此示例显示一个带有 [body] 和 [FloatingActionButton] 的 [MetroPageScaffold]。
/// [body] 是一个放置在 [Center] 中的 [Text]，用于将文本居中在 [MetroPageScaffold] 内。
/// [FloatingActionButton] 连接到一个递增计数器的回调。
///
/// ** 参见示例代码 examples/api/lib/material/scaffold/scaffold.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// 此示例显示一个带有蓝灰色 [backgroundColor]、[body]
/// 和 [FloatingActionButton] 的 [MetroPageScaffold]。 [body] 是一个放置在 [Center] 中的
/// [Text]，用于将文本居中在 [MetroPageScaffold] 内。 [FloatingActionButton]
/// 连接到一个递增计数器的回调。
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/material/scaffold_background_color.png)
///
/// ** 参见示例代码 examples/api/lib/material/scaffold/scaffold.1.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// 此示例显示一个带有 [AppBar]、[BottomAppBar] 和
/// [FloatingActionButton] 的 [MetroPageScaffold]。 [body] 是一个放置在 [Center] 中的 [Text]，
/// 用于将文本居中在 [MetroPageScaffold] 内。 [FloatingActionButton] 使用
/// [FloatingActionButtonLocation.centerDocked] 在 [BottomAppBar] 中居中和停靠。
/// [FloatingActionButton] 连接到一个递增计数器的回调。
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/material/scaffold_bottom_app_bar.png)
///
/// ** 参见示例代码 examples/api/lib/material/scaffold/scaffold.2.dart **
/// {@end-tool}
///
/// ## Scaffold 布局、键盘和显示 "缺口"
///
/// Scaffold 会扩展以填满可用空间。通常这意味着它将占据整个窗口或设备屏幕。
/// 当设备的键盘出现时，Scaffold 的祖先 [MediaQuery]
/// 小部件的 [MediaQueryData.viewInsets] 会变化，Scaffold 将会
/// 被重建。默认情况下，Scaffold 的 [body] 会调整大小以为键盘腾出空间。
/// 要防止调整大小，请将 [resizeToAvoidBottomInset] 设置为 false。
/// 无论哪种情况，如果在可滚动容器内，焦点小部件将会滚动到可见区域。
///
/// [MediaQueryData.padding] 值定义了可能
/// 不完全可见的区域，如 iPhone X 的显示 "缺口"。Scaffold 的 [body]
/// 不会被此 padding 值缩进，尽管 [appBar] 或 [bottomNavigationBar] 通常会
/// 让 body 避开 padding。可以在 Scaffold 的 body 中使用 [SafeArea]
/// 小部件以避开诸如显示缺口等区域。
///
/// ## 带有可拖动滚动底部工作表的浮动操作按钮
///
/// 如果 [MetroPageScaffold.bottomSheet] 是一个 [DraggableScrollableSheet]，
/// [MetroPageScaffold.floatingActionButton] 被设置，并且底部工作表被拖动以
/// 覆盖 Scaffold 高度的大于 70%，则会并行发生两件事情：
///
///   * Scaffold 开始显示遮罩层（见 [MetroPageScaffoldState.showBodyScrim]），
///   * [MetroPageScaffold.floatingActionButton] 通过带有 [Curves.easeIn] 的动画缩放并在​///     底部工作表覆盖整个 Scaffold 时消失。
///
/// 当底部工作表被拖到底部覆盖 Scaffold 的高度小于 70% 时，遮罩层
/// ​/// 消失，[MetroPageScaffold.floatingActionButton] 动画回到其正常大小。
///
/// ## 故障排除
///
/// ### 嵌套 Scaffold
///
/// Scaffold 设计为 Material 应用的顶层容器。
/// 这意味着在 Material 应用的每个路由中添加 Scaffold
/// 将为应用提供 Material 的基本视觉布局结构。
///
/// 通常不需要嵌套 Scaffold。例如，在一个选项卡 UI 中，
/// 如果 [bottomNavigationBar] 是一个 [TabBar]
/// 并且 body 是一个 [TabBarView]，你可能会想让每个选项卡视图
/// 成为有不同标题的 Scaffold。然而，更好的做法
/// 是在 [TabController] 上添加一个监听器来更新
/// AppBar
///
/// {@tool snippet}
/// 向应用的选项卡控制器添加一个监听器，以便每当选择一个新的选项卡时，
/// 重置 [AppBar] 的标题。
///
/// ```dart
/// TabController(vsync: tickerProvider, length: tabCount)..addListener(() {
///   if (!tabController.indexIsChanging) {
///     setState(() {
///       // 使用新的 AppBar 标题重建封闭的 scaffold
///       appBarTitle = 'Tab ${tabController.index}';
///     });
///   }
/// })
/// ```
/// {@end-tool}
///
/// 尽管有些用例，比如展示嵌入式 Flutter 内容的演示应用，嵌套 Scaffold 是合适的，
/// 但最好避免嵌套 Scaffold。
///
/// 另请参见：
///
///  * [AppBar]，通常在应用程序顶部显示的水平栏，使用 [appBar] 属性。
///  * [MetroPageScaffoldState]，与此小部件关联的状态。
///  * <https://material.io/design/layout/responsive-layout-grid.html>
///  * 教程：[为屏幕添加抽屉](https://docs.flutter.dev/cookbook/design/drawer)
class MetroPageScaffold extends StatefulWidget {
  /// 创建 Material Design 小部件的视觉脚手架。
  const MetroPageScaffold({
    super.key,
    this.body,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.restorationId,
  });

  /// Scaffold 的主要内容。
  ///
  /// 显示在 [appBar] 下面，位于环境 [MediaQuery] 的 [MediaQueryData.viewInsets] 底部之上，
  /// 并且在 [floatingActionButton] 和 [drawer] 后面。如果 [resizeToAvoidBottomInset] 为 false，
  /// 则当屏幕键盘出现时，主体不会调整大小，即不会被 `viewInsets.bottom` 缩进。
  ///
  /// Scaffold 主体中的小部件位于应用栏和 Scaffold 底部之间的可用空间的左上角。
  /// 要将此小部件居中显示，请考虑将其放在 [Center] 小部件中，并将其作为主体。
  /// 要扩展此小部件，请考虑将其放在 [SizedBox.expand] 中。
  ///
  /// 如果你有一列小部件，通常应该适合屏幕，但可能会溢出并在这种情况下需要滚动，
  /// 请考虑使用 [ListView] 作为 Scaffold 的主体。这也是你的主体是可滚动列表的一个好选择。
  final Widget? body;

  /// [Material] 小部件的颜色，它在整个 Scaffold 下方。
  ///
  /// 默认情况下使用主题的 [ThemeData.scaffoldBackgroundColor]。
  final Color? backgroundColor;

  /// 如果为 true，[body] 和 scaffold 的浮动小部件应调整大小以避免屏幕键盘，
  /// 其高度由环境 [MediaQuery] 的 [MediaQueryData.viewInsets] `bottom` 属性定义。
  ///
  /// 例如，如果在 scaffold 上方显示了屏幕键盘，body 可以调整大小以避免与键盘重叠，
  /// 这可以防止 body 内的小部件被键盘遮挡。
  ///
  /// 默认为 true。
  final bool? resizeToAvoidBottomInset;

  /// 是否将此 scaffold 显示在屏幕顶部。
  ///
  /// 如果为 true，则 [appBar] 的高度将增加屏幕状态栏的高度，即 [MediaQuery] 的顶部填充。
  ///
  /// 此属性的默认值与 [AppBar.primary] 的默认值一样，为 true。
  final bool primary;

  /// 用于保存和恢复 [MetroPageScaffold] 状态的恢复 ID。
  ///
  /// 如果它非空，scaffold 将持久化并恢复 [drawer] 和 [endDrawer] 的打开或关闭状态。
  ///
  /// 此小部件的状态保存在从周围 [RestorationScope] 声明的 [RestorationBucket] 中，
  /// 使用提供的恢复 ID。
  ///
  /// 另请参见:
  ///
  ///  * [RestorationManager]，它解释了 Flutter 中状态恢复的工作原理。
  final String? restorationId;

  /// 从最接近的此类实例中查找 [MetroPageScaffoldState]。
  ///
  /// 如果没有此类实例包含给定的上下文，在调试模式下会导致断言，在发布模式下会抛出异常。
  ///
  /// 此方法可能会很耗时（它会遍历元素树）。
  ///
  /// {@tool dartpad}
  /// [MetroPageScaffold.of] 函数的典型用法是在 [MetroPageScaffold] 子小部件的 `build` 方法中调用它。
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold.of.0.dart 中的代码 **
  /// {@end-tool}
  ///
  /// {@tool dartpad}
  /// 当 [MetroPageScaffold] 实际上是在同一个 `build` 函数中创建时，`build` 函数的 `context` 参数不能用于查找 [MetroPageScaffold]（因为它在返回的小部件树中位于小部件的“上方”）。在这种情况下，可以使用以下技术与 [Builder] 提供一个新的作用域，其中包含“在”[MetroPageScaffold] 下的 [BuildContext]：
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold.of.1.dart 中的代码 **
  /// {@end-tool}
  ///
  /// 更有效的解决方案是将你的构建函数拆分为几个小部件。这会引入一个新的上下文，你可以从中获取 [MetroPageScaffold]。在这种解决方案中，你会有一个外部小部件来创建由新内部小部件实例填充的 [MetroPageScaffold]，然后在这些内部小部件中使用 [MetroPageScaffold.of]。
  ///
  /// 一个不太优雅但更快捷的解决方案是为 [MetroPageScaffold] 分配一个 [GlobalKey]，然后使用 `key.currentState` 属性来获取 [MetroPageScaffoldState]，而不是使用 [MetroPageScaffold.of] 函数。
  ///
  /// 如果范围内没有 [MetroPageScaffold]，则会抛出异常。要在没有 [MetroPageScaffold] 时返回 null，请使用 [maybeOf]。
  static MetroPageScaffoldState of(BuildContext context) {
    final MetroPageScaffoldState? result =
        context.findAncestorStateOfType<MetroPageScaffoldState>();
    if (result != null) {
      return result;
    }
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(
        'Scaffold.of() called with a context that does not contain a Scaffold.',
      ),
      ErrorDescription(
        'No Scaffold ancestor could be found starting from the context that was passed to Scaffold.of(). '
        'This usually happens when the context provided is from the same StatefulWidget as that '
        'whose build function actually creates the Scaffold widget being sought.',
      ),
      ErrorHint(
        'There are several ways to avoid this problem. The simplest is to use a Builder to get a '
        'context that is "under" the Scaffold. For an example of this, please see the '
        'documentation for Scaffold.of():\n'
        '  https://api.flutter.dev/flutter/material/Scaffold/of.html',
      ),
      ErrorHint(
        'A more efficient solution is to split your build function into several widgets. This '
        'introduces a new context from which you can obtain the Scaffold. In this solution, '
        'you would have an outer widget that creates the Scaffold populated by instances of '
        'your new inner widgets, and then in these inner widgets you would use Scaffold.of().\n'
        'A less elegant but more expedient solution is assign a GlobalKey to the Scaffold, '
        'then use the key.currentState property to obtain the ScaffoldState rather than '
        'using the Scaffold.of() function.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// 从最接近的此类实例中查找 [MetroPageScaffoldState]。
  ///
  /// 如果没有此类实例包含给定的上下文，将返回 null。
  /// 要抛出异常，请使用 [of] 而不是此函数。
  ///
  /// 此方法可能会很耗时（它会遍历元素树）。
  ///
  /// 另请参见:
  ///
  ///  * [of]，这是一个类似的函数，但如果没有实例包含给定的上下文，它会抛出异常。其文档中还包括一些示例代码。
  static MetroPageScaffoldState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<MetroPageScaffoldState>();
  }

  @override
  MetroPageScaffoldState createState() => MetroPageScaffoldState();
}

/// [MetroPageScaffold] 的状态。
///
/// 可以显示 [BottomSheet]。使用 [MetroPageScaffold.of] 从当前的 [BuildContext] 中获取 [MetroPageScaffoldState]。
class MetroPageScaffoldState extends State<MetroPageScaffold>
    with TickerProviderStateMixin, RestorationMixin {
  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // registerForRestoration(_drawerOpened, 'drawer_open');
    // registerForRestoration(_endDrawerOpened, 'end_drawer_open');
  }

  final GlobalKey _bodyKey = GlobalKey();

  // Used for both the snackbar and material banner APIs
  MetroPageMessengerState? _metroPageMessenger;

  // // SNACKBAR API
  // MetroPageFeatureController<SnackBar, SnackBarClosedReason>?
  //     _messengerSnackBar;
  //
  // // This is used to update the _messengerSnackBar by the MetroPageMessenger.
  // void _updateSnackBar() {
  //   final MetroPageFeatureController<SnackBar, SnackBarClosedReason>?
  //       messengerSnackBar = _metroPageMessenger!._snackBars.isNotEmpty
  //           ? _metroPageMessenger!._snackBars.first
  //           : null;
  //
  //   if (_messengerSnackBar != messengerSnackBar) {
  //     setState(() {
  //       _messengerSnackBar = messengerSnackBar;
  //     });
  //   }
  // }
  //
  // // MATERIAL BANNER API
  //
  // // The _messengerMetroBanner represents the current MetroBanner being managed by
  // // the MetroPageMessenger, instead of the Scaffold.
  // MetroPageFeatureController<MetroBanner, MetroBannerClosedReason>?
  //     _messengerMetroBanner;
  //
  // // This is used to update the _messengerMetroBanner by the MetroPageMessenger.
  // void _updateMetroBanner() {
  //   final MetroPageFeatureController<MetroBanner,
  //           MetroBannerClosedReason>? messengerMetroBanner =
  //       _metroPageMessenger!._metroBanners.isNotEmpty
  //           ? _metroPageMessenger!._metroBanners.first
  //           : null;
  //
  //   if (_messengerMetroBanner != messengerMetroBanner) {
  //     setState(() {
  //       _messengerMetroBanner = messengerMetroBanner;
  //     });
  //   }
  // }

  // iOS 特性 - 状态栏点击，返回手势

  // 在 iOS 上，点击状态栏会将应用的主要可滚动内容滚动到顶部。
  // 我们通过查找主要滚动控制器并在点击时将其滚动到顶部来实现这一点。
  void _handleStatusBarTap() {
    final ScrollController? primaryScrollController =
        PrimaryScrollController.maybeOf(context);
    if (primaryScrollController != null && primaryScrollController.hasClients) {
      primaryScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCirc,
      );
    }
  }

  // 内部方法

  //late _ScaffoldGeometryNotifier _geometryNotifier;

  bool get _resizeToAvoidBottomInset {
    return widget.resizeToAvoidBottomInset ?? true;
  }

  @override
  void initState() {
    super.initState();
    // _geometryNotifier =
    //     _ScaffoldGeometryNotifier(const MetroPageGeometry(), context);
  }

  @override
  void didChangeDependencies() {
    // Using maybeOf is valid here since both the Scaffold and MetroPageMessenger
    // are currently available for managing SnackBars.
    final MetroPageMessengerState? currentMetroPageMessenger =
        MetroPageMessenger.maybeOf(context);
    // If our MetroPageMessenger has changed, unregister with the old one first.
    if (_metroPageMessenger != null &&
        (currentMetroPageMessenger == null ||
            _metroPageMessenger != currentMetroPageMessenger)) {
      _metroPageMessenger?._unregister(this);
    }
    // Register with the current MetroPageMessenger, if there is one.
    _metroPageMessenger = currentMetroPageMessenger;
    _metroPageMessenger?._register(this);

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    //_geometryNotifier.dispose();
    _metroPageMessenger?._unregister(this);
    super.dispose();
  }

  void _addIfNonNull(
    List<LayoutId> children,
    Widget? child,
    Object childId, {
    required bool removeLeftPadding,
    required bool removeTopPadding,
    required bool removeRightPadding,
    required bool removeBottomPadding,
    bool removeBottomInset = false,
    bool maintainBottomViewPadding = false,
  }) {
    MediaQueryData data = MediaQuery.of(context).removePadding(
      removeLeft: removeLeftPadding,
      removeTop: removeTopPadding,
      removeRight: removeRightPadding,
      removeBottom: removeBottomPadding,
    );
    if (removeBottomInset) {
      data = data.removeViewInsets(removeBottom: true);
    }

    if (maintainBottomViewPadding && data.viewInsets.bottom != 0.0) {
      data = data.copyWith(
        padding: data.padding.copyWith(bottom: data.viewPadding.bottom),
      );
    }

    if (child != null) {
      children.add(
        LayoutId(
          id: childId,
          child: MediaQuery(data: data, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasDirectionality(context));
    final ThemeData themeData = Theme.of(context);
    final TextDirection textDirection = Directionality.of(context);

    final List<LayoutId> children = <LayoutId>[];
    _addIfNonNull(
      children,
      widget.body == null
          ? null
          : _BodyBuilder(
              body: KeyedSubtree(key: _bodyKey, child: widget.body!),
            ),
      _MetroPageSlot.body,
      removeLeftPadding: false,
      removeTopPadding: true,
      removeRightPadding: false,
      removeBottomPadding: false,
      removeBottomInset: _resizeToAvoidBottomInset,
    );

    switch (themeData.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        _addIfNonNull(
          children,
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleStatusBarTap,
            // iOS accessibility automatically adds scroll-to-top to the clock in the status bar
            excludeFromSemantics: true,
          ),
          _MetroPageSlot.statusBar,
          removeLeftPadding: false,
          removeTopPadding: true,
          removeRightPadding: false,
          removeBottomPadding: true,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        break;
    }

    // The minimum insets for contents of the Scaffold to keep visible.
    final EdgeInsets minInsets = MediaQuery.paddingOf(context).copyWith(
      bottom: _resizeToAvoidBottomInset
          ? MediaQuery.viewInsetsOf(context).bottom
          : 0.0,
    );

    // The minimum viewPadding for interactive elements positioned by the
    // Scaffold to keep within safe interactive areas.
    final EdgeInsets minViewPadding =
        MediaQuery.viewPaddingOf(context).copyWith(
      bottom: _resizeToAvoidBottomInset &&
              MediaQuery.viewInsetsOf(context).bottom != 0.0
          ? 0.0
          : null,
    );

    // extendBody locked when keyboard is open
    final bool extendBody = minInsets.bottom <= 0;

    return ScrollNotificationObserver(
      child: Material(
        color: widget.backgroundColor ?? themeData.scaffoldBackgroundColor,

        child: CustomMultiChildLayout(
          delegate: _MetroPageLayout(
            extendBody: extendBody,
            minInsets: minInsets,
            minViewPadding: minViewPadding,
            //geometryNotifier: _geometryNotifier,
            textDirection: textDirection,
            //snackBarWidth: snackBarWidth,
          ),
          children: children,
        ),
      ),
    );
  }
}

/// 控制 [MetroPageScaffold] 功能的接口。
///
/// 通常从 [MetroPageMessengerState.showSnackBar] 或 [MetroPageScaffoldState.showBottomSheet] 获取。
class MetroPageFeatureController<T extends Widget, U> {
  const MetroPageFeatureController._(
      this._widget, this._completer, this.close, this.setState);
  final T _widget;
  final Completer<U> _completer;

  /// 当此对象控制的功能不再可见时完成。
  Future<U> get closed => _completer.future;

  /// 从 scaffold 中移除功能（例如，底部工作表、snack bar 或 material banner）。
  final VoidCallback close;

  /// 标记功能（例如，底部工作表或 snack bar）需要重建。
  final StateSetter? setState;
}
