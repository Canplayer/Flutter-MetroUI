// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

// Examples can assume:
// late TabController tabController;
// void setState(VoidCallback fn) { }
// late String appBarTitle;
// late int tabCount;
// late TickerProvider tickerProvider;

enum _ScaffoldSlot {
  body,
  bodyScrim,
  snackBar,
  materialBanner,
  persistentFooter,
  bottomNavigationBar,
  statusBar,
}

/// 管理后代 [MetroPage] 的 [SnackBar] 和 [MaterialBanner]。
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=lytQi-slT5Y}
///
/// 该类提供了在屏幕底部和顶部显示 snack bars 和 material banners 的 API。
///
/// 要显示这些通知，请通过 [MetroPageMessenger.of] 获取当前 [BuildContext] 的 [MetroPageMessengerState]，
/// 然后使用 [MetroPageMessengerState.showSnackBar] 或 [MetroPageMessengerState.showMaterialBanner] 函数。
///
/// 当 [MetroPageMessenger] 有嵌套的 [MetroPage] 后代时，ScaffoldMessenger 只会将通知显示给子树中根 Scaffold。
/// 为了在内部嵌套的 Scaffold 中显示通知，请在嵌套级别之间实例化一个新的 ScaffoldMessenger 以设置新的作用域。
///
/// {@tool dartpad}
/// 下面是一个在用户按下按钮时显示 [SnackBar] 的示例。
///
/// ** 请参阅 examples/api/lib/material/scaffold/scaffold_messenger.0.dart 中的代码 **
/// {@end-tool}
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=lytQi-slT5Y}
///
/// 另请参阅:
///
///  * [SnackBar]，它是一个临时通知，通常使用 [MetroPageMessengerState.showSnackBar] 方法显示在应用程序的底部。
///  * [MaterialBanner]，它是一个临时通知，通常使用 [MetroPageMessengerState.showMaterialBanner] 方法显示在应用程序的顶部。
///  * [debugCheckHasScaffoldMessenger]，它断言给定的上下文有一个 [MetroPageMessenger] 祖先。
///  * Cookbook: [显示 SnackBar](https://docs.flutter.dev/cookbook/design/snackbars)
class MetroPageMessenger extends StatefulWidget {
  /// Creates a widget that manages [SnackBar]s for [MetroPage] descendants.
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
  /// ScaffoldMessenger。
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
  ///  * [debugCheckHasScaffoldMessenger]，它断言给定的上下文有一个 [MetroPageMessenger] 祖先。
  static MetroPageMessengerState of(BuildContext context) {
    assert(debugCheckHasScaffoldMessenger(context));

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
/// [MetroPageMessengerState] 对象可用于为每个注册的 [MetroPage] 显示 [SnackBar] 或 [MaterialBanner]，
/// 这些 [MetroPage] 是关联的 [MetroPageMessenger] 的后代。
/// Scaffolds 将注册以从其最近的 ScaffoldMessenger 祖先接收 [SnackBar] 和 [MaterialBanner]。
///
/// 通常通过 [MetroPageMessenger.of] 获取。
class MetroPageMessengerState extends State<MetroPageMessenger>
    with TickerProviderStateMixin {
  final LinkedHashSet<MetroPageState> _scaffolds =
      LinkedHashSet<MetroPageState>();
  final Queue<
      MetroPageFeatureController<MaterialBanner,
          MaterialBannerClosedReason>> _materialBanners = Queue<
      MetroPageFeatureController<MaterialBanner, MaterialBannerClosedReason>>();
  AnimationController? _materialBannerController;
  final Queue<MetroPageFeatureController<SnackBar, SnackBarClosedReason>>
      _snackBars =
      Queue<MetroPageFeatureController<SnackBar, SnackBarClosedReason>>();
  AnimationController? _snackBarController;
  Timer? _snackBarTimer;
  bool? _accessibleNavigation;

  @override
  void didChangeDependencies() {
    final bool accessibleNavigation =
        MediaQuery.accessibleNavigationOf(context);
    // 如果我们从无障碍导航过渡到非无障碍导航
    // 并且有一个 SnackBar 本应超时但已经
    // 完成了它的计时器，则关闭该 SnackBar。如果计时器尚未完成
    // 让它正常超时。
    if ((_accessibleNavigation ?? false) &&
        !accessibleNavigation &&
        _snackBarTimer != null &&
        !_snackBarTimer!.isActive) {
      hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
    }
    _accessibleNavigation = accessibleNavigation;
    super.didChangeDependencies();
  }

  void _register(MetroPageState scaffold) {
    _scaffolds.add(scaffold);

    if (_isRoot(scaffold)) {
      if (_snackBars.isNotEmpty) {
        scaffold._updateSnackBar();
      }

      if (_materialBanners.isNotEmpty) {
        scaffold._updateMaterialBanner();
      }
    }
  }

  void _unregister(MetroPageState scaffold) {
    final bool removed = _scaffolds.remove(scaffold);
    // ScaffoldStates应该只被移除一次。
    assert(removed);
  }

  void _updateScaffolds() {
    for (final MetroPageState scaffold in _scaffolds) {
      if (_isRoot(scaffold)) {
        scaffold._updateSnackBar();
        scaffold._updateMaterialBanner();
      }
    }
  }

  // 嵌套的 Scaffold 由 ScaffoldMessenger 处理，仅在嵌套集的根 Scaffold 中显示 MaterialBanner 或 SnackBar。
  bool _isRoot(MetroPageState scaffold) {
    final MetroPageState? parent =
        scaffold.context.findAncestorStateOfType<MetroPageState>();
    return parent == null || !_scaffolds.contains(parent);
  }

  // SNACKBAR API

  /// 显示一个 [SnackBar]，涉及所有已注册的 [MetroPage]。Scaffold 会从其最近的 [MetroPageMessenger] 祖先接收 SnackBar。
  /// 如果有多个已注册的 Scaffold，SnackBar 会在所有这些 Scaffold 上同步显示。
  ///
  /// 一个 Scaffold 一次只能显示一个 SnackBar。如果在另一个 SnackBar 尚未关闭时调用此函数，
  /// 提供的 SnackBar 会被添加到队列中，并在前一个 SnackBar 关闭后显示。
  ///
  /// 要控制 [SnackBar] 保持可见的时间，请使用 [SnackBar.duration]。
  ///
  /// 要使用退出动画移除 [SnackBar]，请使用 [hideCurrentSnackBar] 或在返回的
  /// [MetroPageFeatureController] 上调用 [MetroPageFeatureController.close]。
  /// 要突然移除一个 [SnackBar]（没有动画），请使用 [removeCurrentSnackBar]。
  ///
  /// 请参阅 [MetroPageMessenger.of] 了解如何获取当前 [MetroPageMessengerState]。
  ///
  /// {@tool dartpad}
  /// 这是一个在用户按下按钮时显示 [SnackBar] 的示例。
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold_messenger_state.show_snack_bar.0.dart 中的代码 **
  /// {@end-tool}
  ///
  /// ## floating SnackBars 的相对定位
  ///
  /// 行为设置为 [SnackBarBehavior.floating] 的 [SnackBar] 会位于通过 [MetroPage.floatingActionButton]、
  /// [MetroPage.persistentFooterButtons] 和 [MetroPage.bottomNavigationBar] 提供的 widgets 之上。
  /// 如果这些 widgets 中的部分或全部占用了足够的空间，以至于 SnackBar 无法在它们上方可见，将会抛出错误。
  /// 在这种情况下，请考虑限制这些 widgets 的大小以为 SnackBar 留出可见空间。
  ///
  /// {@tool dartpad}
  /// 这是一个展示如何使用 [showSnackBar] 显示 [SnackBar] 的示例。
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold_messenger_state.show_snack_bar.0.dart 中的代码 **
  /// {@end-tool}
  ///
  /// {@tool dartpad}
  /// 这是一个展示 floating 的 [SnackBar] 如何显示在 [MetroPage.floatingActionButton] 上方的示例。
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold_messenger_state.show_snack_bar.1.dart 中的代码 **
  /// {@end-tool}
  ///
  /// 如果在 [snackBarAnimationStyle] 参数中提供了 [AnimationStyle.duration]，它将用于覆盖 SnackBar 显示动画的持续时间。
  /// 否则，默认持续时间为 250 毫秒。
  ///
  /// 如果在 [snackBarAnimationStyle] 参数中提供了 [AnimationStyle.reverseDuration]，它将用于覆盖 SnackBar 隐藏动画的持续时间。
  /// 否则，默认持续时间为 250 毫秒。
  ///
  /// 要禁用 SnackBar 动画，请使用 [AnimationStyle.noAnimation]。
  ///
  /// {@tool dartpad}
  /// 这个示例展示了如何使用 [AnimationStyle] 在 [MetroPageMessengerState.showSnackBar] 中覆盖 [SnackBar] 的显示和隐藏动画持续时间。
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold_messenger_state.show_snack_bar.2.dart 中的代码 **
  /// {@end-tool}
  MetroPageFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
      SnackBar snackBar,
      {AnimationStyle? snackBarAnimationStyle}) {
    assert(
      _scaffolds.isNotEmpty,
      'ScaffoldMessenger.showSnackBar was called, but there are currently no '
      'descendant Scaffolds to present to.',
    );
    _didUpdateAnimationStyle(snackBarAnimationStyle);
    _snackBarController ??= SnackBar.createAnimationController(
      duration: snackBarAnimationStyle?.duration,
      reverseDuration: snackBarAnimationStyle?.reverseDuration,
      vsync: this,
    )..addStatusListener(_handleSnackBarStatusChanged);
    if (_snackBars.isEmpty) {
      assert(_snackBarController!.isDismissed);
      _snackBarController!.forward();
    }
    late MetroPageFeatureController<SnackBar, SnackBarClosedReason> controller;
    controller = MetroPageFeatureController<SnackBar, SnackBarClosedReason>._(
      // 我们提供备用键，以便如果连续出现的 SnackBar 结构相同，
      // Material Ink飞溅和高亮效果不会从一个保留到下一个。
      snackBar.withAnimation(_snackBarController!, fallbackKey: UniqueKey()),
      Completer<SnackBarClosedReason>(),
      () {
        assert(_snackBars.first == controller);
        hideCurrentSnackBar();
      },
      null, // SnackBar doesn't use a builder function so setState() wouldn't rebuild it
    );
    try {
      setState(() {
        _snackBars.addLast(controller);
      });
      _updateScaffolds();
    } catch (exception) {
      assert(() {
        if (exception is FlutterError) {
          final String summary = exception.diagnostics.first.toDescription();
          if (summary ==
              'setState() or markNeedsBuild() called during build.') {
            final List<DiagnosticsNode> information = <DiagnosticsNode>[
              ErrorSummary(
                  'The showSnackBar() method cannot be called during build.'),
              ErrorDescription(
                'The showSnackBar() method was called during build, which is '
                'prohibited as showing snack bars requires updating state. Updating '
                'state is not possible during build.',
              ),
              ErrorHint(
                'Instead of calling showSnackBar() during build, call it directly '
                'in your on tap (and related) callbacks. If you need to immediately '
                'show a snack bar, make the call in initState() or '
                'didChangeDependencies() instead. Otherwise, you can also schedule a '
                'post-frame callback using SchedulerBinding.addPostFrameCallback to '
                'show the snack bar after the current frame.',
              ),
              context.describeOwnershipChain(
                'The ownership chain for the particular ScaffoldMessenger is',
              ),
            ];
            throw FlutterError.fromParts(information);
          }
        }
        return true;
      }());
      rethrow;
    }

    return controller;
  }

  void _didUpdateAnimationStyle(AnimationStyle? snackBarAnimationStyle) {
    if (snackBarAnimationStyle != null) {
      if (_snackBarController?.duration != snackBarAnimationStyle.duration ||
          _snackBarController?.reverseDuration !=
              snackBarAnimationStyle.reverseDuration) {
        _snackBarController?.dispose();
        _snackBarController = null;
      }
    }
  }

  void _handleSnackBarStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        assert(_snackBars.isNotEmpty);
        setState(() {
          _snackBars.removeFirst();
        });
        _updateScaffolds();
        if (_snackBars.isNotEmpty) {
          _snackBarController!.forward();
        }
      case AnimationStatus.completed:
        setState(() {
          assert(_snackBarTimer == null);
          // build will create a new timer if necessary to dismiss the snackBar.
        });
        _updateScaffolds();
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        break;
    }
  }

  /// 立即从已注册的 [MetroPage] 中移除当前的 [SnackBar]（如果有）。
  ///
  /// 移除的 snack bar 不会运行其正常的退出动画。如果有任何排队的 snack bars，
  /// 它们会立即开始进入动画。
  void removeCurrentSnackBar(
      {SnackBarClosedReason reason = SnackBarClosedReason.remove}) {
    if (_snackBars.isEmpty) {
      return;
    }
    final Completer<SnackBarClosedReason> completer =
        _snackBars.first._completer;
    if (!completer.isCompleted) {
      completer.complete(reason);
    }
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    // 这将触发动画的状态回调。
    _snackBarController!.value = 0.0;
  }

  /// 移除当前的 [SnackBar]，通过运行其正常的退出动画。
  ///
  /// 动画完成后，调用关闭的 completer。
  void hideCurrentSnackBar(
      {SnackBarClosedReason reason = SnackBarClosedReason.hide}) {
    if (_snackBars.isEmpty || _snackBarController!.isDismissed) {
      return;
    }
    final Completer<SnackBarClosedReason> completer =
        _snackBars.first._completer;
    if (_accessibleNavigation!) {
      _snackBarController!.value = 0.0;
      completer.complete(reason);
    } else {
      _snackBarController!.reverse().then<void>((void value) {
        assert(mounted);
        if (!completer.isCompleted) {
          completer.complete(reason);
        }
      });
    }
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
  }

  /// 清除队列中所有当前的 snackBars，并对当前的 snackBar 运行正常的退出动画。
  void clearSnackBars() {
    if (_snackBars.isEmpty || _snackBarController!.isDismissed) {
      return;
    }
    final MetroPageFeatureController<SnackBar, SnackBarClosedReason>
        currentSnackbar = _snackBars.first;
    _snackBars.clear();
    _snackBars.add(currentSnackbar);
    hideCurrentSnackBar();
  }

  // MATERIAL BANNER API

  //TODO：移除。这在Windows Phone上没有对应组件

  /// 在所有已注册的 [MetroPage] 上显示一个 [MaterialBanner]。Scaffold 会注册以接收来自其最近的 [MetroPageMessenger] 祖先的 material banner。
  /// 如果有多个注册的 Scaffold，material banner 将同时在所有这些 Scaffold 上显示。
  ///
  /// 一个 Scaffold 一次最多只能显示一个 material banner。如果在另一个 material banner 已经可见时调用此函数，
  /// 提供的 material banner 将被添加到队列中，并在之前的 material banner 关闭后显示。
  ///
  /// 要通过退出动画移除 [MaterialBanner]，请使用 [hideCurrentMaterialBanner] 或在返回的
  /// [MetroPageFeatureController] 上调用 [MetroPageFeatureController.close]。
  /// 要突然移除一个 [MaterialBanner]（没有动画），请使用 [removeCurrentMaterialBanner]。
  ///
  /// 有关如何获取 [MetroPageMessengerState] 的信息，请参见 [MetroPageMessenger.of]。
  ///
  /// {@tool dartpad}
  /// 这是一个在用户按下按钮时显示 [MaterialBanner] 的示例。
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold_messenger_state.show_material_banner.0.dart 中的代码 **
  /// {@end-tool}
  MetroPageFeatureController<MaterialBanner, MaterialBannerClosedReason>
      showMaterialBanner(MaterialBanner materialBanner) {
    assert(
      _scaffolds.isNotEmpty,
      'ScaffoldMessenger.showMaterialBanner was called, but there are currently no '
      'descendant Scaffolds to present to.',
    );
    _materialBannerController ??=
        MaterialBanner.createAnimationController(vsync: this)
          ..addStatusListener(_handleMaterialBannerStatusChanged);
    if (_materialBanners.isEmpty) {
      assert(_materialBannerController!.isDismissed);
      _materialBannerController!.forward();
    }
    late MetroPageFeatureController<MaterialBanner, MaterialBannerClosedReason>
        controller;
    controller = MetroPageFeatureController<MaterialBanner,
        MaterialBannerClosedReason>._(
      // 我们提供一个备用键，以防连续的Material Banner在结构上相匹配，
      // 这样Material的Ink飞溅和高亮效果就不会从一个保留到下一个。
      materialBanner.withAnimation(_materialBannerController!,
          fallbackKey: UniqueKey()),
      Completer<MaterialBannerClosedReason>(),
      () {
        assert(_materialBanners.first == controller);
        hideCurrentMaterialBanner();
      },
      null, // MaterialBanner doesn't use a builder function so setState() wouldn't rebuild it
    );
    setState(() {
      _materialBanners.addLast(controller);
    });
    _updateScaffolds();
    return controller;
  }

  void _handleMaterialBannerStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        assert(_materialBanners.isNotEmpty);
        setState(() {
          _materialBanners.removeFirst();
        });
        _updateScaffolds();
        if (_materialBanners.isNotEmpty) {
          _materialBannerController!.forward();
        }
      case AnimationStatus.completed:
        _updateScaffolds();
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        break;
    }
  }

  /// 立即从已注册的 [MetroPage] 中移除当前的 [MaterialBanner]（如果有）。
  ///
  /// 被移除的 material banner 不会执行其正常的退出动画。如果有任何排队的 material banners，
  /// 它们会立即开始进入动画。
  void removeCurrentMaterialBanner(
      {MaterialBannerClosedReason reason = MaterialBannerClosedReason.remove}) {
    if (_materialBanners.isEmpty) {
      return;
    }
    final Completer<MaterialBannerClosedReason> completer =
        _materialBanners.first._completer;
    if (!completer.isCompleted) {
      completer.complete(reason);
    }

    // This will trigger the animation's status callback.
    _materialBannerController!.value = 0.0;
  }

  /// Removes the current [MaterialBanner] by running its normal exit animation.
  ///
  /// The closed completer is called after the animation is complete.
  void hideCurrentMaterialBanner(
      {MaterialBannerClosedReason reason = MaterialBannerClosedReason.hide}) {
    if (_materialBanners.isEmpty || _materialBannerController!.isDismissed) {
      return;
    }
    final Completer<MaterialBannerClosedReason> completer =
        _materialBanners.first._completer;
    if (_accessibleNavigation!) {
      _materialBannerController!.value = 0.0;
      completer.complete(reason);
    } else {
      _materialBannerController!.reverse().then<void>((void value) {
        assert(mounted);
        if (!completer.isCompleted) {
          completer.complete(reason);
        }
      });
    }
  }

  /// Removes all the [MaterialBanner]s currently in queue by clearing the queue
  /// and running normal exit animation on the current [MaterialBanner].
  void clearMaterialBanners() {
    if (_materialBanners.isEmpty || _materialBannerController!.isDismissed) {
      return;
    }
    final MetroPageFeatureController<MaterialBanner, MaterialBannerClosedReason>
        currentMaterialBanner = _materialBanners.first;
    _materialBanners.clear();
    _materialBanners.add(currentMaterialBanner);
    hideCurrentMaterialBanner();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    _accessibleNavigation = MediaQuery.accessibleNavigationOf(context);

    if (_snackBars.isNotEmpty) {
      final ModalRoute<dynamic>? route = ModalRoute.of(context);
      if (route == null || route.isCurrent) {
        if (_snackBarController!.isCompleted && _snackBarTimer == null) {
          final SnackBar snackBar = _snackBars.first._widget;
          _snackBarTimer = Timer(snackBar.duration, () {
            assert(_snackBarController!.isForwardOrCompleted);
            // Look up MediaQuery again in case the setting changed.
            if (snackBar.action != null &&
                MediaQuery.accessibleNavigationOf(context)) {
              return;
            }
            hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
          });
        }
      }
    }

    return _MetroPageMessengerScope(
      scaffoldMessengerState: this,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _materialBannerController?.dispose();
    _snackBarController?.dispose();
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    super.dispose();
  }
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

/// [MetroPage] 布局完所有内容后的空间信息，不包括 [FloatingActionButton]。
///
/// [MetroPage] 把这个预布局的空间信息传给它的
/// [FloatingActionButtonLocation]，后者会生成一个 [Offset]，
/// [MetroPage] 会用这个偏移量来摆放 [FloatingActionButton]。
///
/// 想了解 [MetroPage] 完成布局后的详细几何信息，可以看看 [MetroPageGeometry]。
@immutable
class MetroPagePrelayoutGeometry {
  /// 抽象常量构造函数。这个构造函数允许子类提供常量构造函数，以便在常量表达式中使用。
  const MetroPagePrelayoutGeometry({
    required this.bottomSheetSize,
    required this.contentBottom,
    required this.contentTop,
    required this.floatingActionButtonSize,
    required this.minInsets,
    required this.minViewPadding,
    required this.scaffoldSize,
    required this.snackBarSize,
    required this.materialBannerSize,
    required this.textDirection,
  });

  /// [MetroPage.floatingActionButton] 的尺寸。
  ///
  /// 如果 [MetroPage.floatingActionButton] 为 null，则为 [Size.zero]。
  final Size floatingActionButtonSize;

  /// [MetroPage] 的 [BottomSheet] 尺寸。
  ///
  /// 如果 [MetroPage] 当前未显示 [BottomSheet]，则为 [Size.zero]。
  final Size bottomSheetSize;

  /// 从 Scaffold 原点到 [MetroPage.body] 底部的垂直距离。
  ///
  /// 这在设计将 [FloatingActionButton] 放置在屏幕底部的 [FloatingActionButtonLocation] 中很有用，
  /// 同时将其保持在 [BottomSheet]、[MetroPage.bottomNavigationBar] 或键盘之上。
  ///
  /// [MetroPage.body] 已根据 [minInsets] 进行布局，这意味着 [FloatingActionButtonLocation]
  /// 在将 [FloatingActionButton] 对齐到 [contentBottom] 时，无需考虑 [minInsets] 的 [EdgeInsets.bottom]。
  final double contentBottom;

  /// 从 [MetroPage] 原点到 [MetroPage.body] 顶部的垂直距离。
  ///
  /// 这在设计将 [FloatingActionButton] 放置在屏幕顶部的 [FloatingActionButtonLocation] 中很有用，
  /// 同时将其保持在 [MetroPage.appBar] 之下。
  ///
  /// [MetroPage.body] 已根据 [minInsets] 进行布局，这意味着 [FloatingActionButtonLocation]
  /// 在将 [FloatingActionButton] 对齐到 [contentTop] 时，无需考虑 [minInsets] 的 [EdgeInsets.top]。
  final double contentTop;

  /// 为了使 [FloatingActionButton] 保持可见，所需的最小内边距。
  ///
  /// 这个值是通过在 [MetroPage] 的 [BuildContext] 中调用 [MediaQueryData.padding] 得到的，
  /// 用于给 [FloatingActionButton] 添加内边距，以避免系统状态栏或键盘等元素。
  ///
  /// 如果 [MetroPage.resizeToAvoidBottomInset] 设置为 false，
  /// [minInsets] 的 [EdgeInsets.bottom] 将为 0.0。
  final EdgeInsets minInsets;

  /// 为了让交互元素位于安全、无遮挡的空间内，所需的最小内边距。
  ///
  /// 当 [MetroPage.resizeToAvoidBottomInset] 为 false 或 [MediaQueryData.viewInsets] > 0.0 时，
  /// 这个值反映了 [MetroPage] 的 [BuildContext] 的 [MediaQueryData.viewPadding]。
  /// 这有助于区分屏幕上不同类型的遮挡，例如软件键盘和设备的物理刘海。
  final EdgeInsets minViewPadding;

  /// 整个 [MetroPage] 的尺寸。
  ///
  /// 如果 [MetroPage] 内容的尺寸由于像 [MetroPage.resizeToAvoidBottomInset] 或键盘弹出等因素而被修改，
  /// 则 [scaffoldSize] 不会反映这些更改。
  ///
  /// 这意味着，设计用于根据键盘弹出等事件重新定位 [FloatingActionButton] 的 [FloatingActionButtonLocation]
  /// 应该使用 [minInsets] 确保 [FloatingActionButton] 有足够的内边距以保持可见。
  ///
  /// 有关应用适当内边距的更多信息，请参见 [minInsets] 和 [MediaQueryData.padding]。
  final Size scaffoldSize;

  /// [MetroPage] 的 [SnackBar] 尺寸。
  ///
  /// 如果 [MetroPage] 没有显示 [SnackBar]，则为 [Size.zero]。
  final Size snackBarSize;

  /// [MetroPage] 的 [MaterialBanner] 尺寸。
  ///
  /// 如果 [MetroPage] 没有显示 [MaterialBanner]，则为 [Size.zero]。
  final Size materialBannerSize;

  /// [MetroPage] 的 [BuildContext] 的文字方向。
  final TextDirection textDirection;
}

/// 在布局完成后，为 [MetroPage] 组件提供几何信息。
///
/// 要获取给定 [BuildContext] 的 Scaffold 几何的 [ValueNotifier]，请使用 [MetroPage.geometryOf]。
///
/// ScaffoldGeometry 仅在绘制阶段可用，因为它的值是在动画和布局阶段计算的，然后进行绘制。
///
/// 例如， [BottomAppBar] 使用 [MetroPageGeometry] 在 [FloatingActionButton] 周围绘制一个缺口。
///
/// 有关在布局 [FloatingActionButton] 时使用的 [MetroPage] 几何信息，请参见 [MetroPagePrelayoutGeometry]。
@immutable
class MetroPageGeometry {
  /// 创建一个描述 [MetroPage] 几何的对象。
  const MetroPageGeometry({
    this.bottomNavigationBarTop,
    this.floatingActionButtonArea,
  });

  /// 从 [MetroPage] 顶部边缘到 [MetroPage.bottomNavigationBar] 所在矩形顶部的距离。
  ///
  /// 如果 [MetroPage.bottomNavigationBar] 为 null，则此值为 null。
  final double? bottomNavigationBarTop;

  /// [MetroPage.floatingActionButton] 的边界矩形。
  ///
  /// 当没有显示浮动操作按钮时，此值为 null。
  final Rect? floatingActionButtonArea;

  MetroPageGeometry _scaleFloatingActionButton(double scaleFactor) {
    if (scaleFactor == 1.0) {
      return this;
    }

    if (scaleFactor == 0.0) {
      return MetroPageGeometry(
        bottomNavigationBarTop: bottomNavigationBarTop,
      );
    }

    final Rect scaledButton = Rect.lerp(
      floatingActionButtonArea!.center & Size.zero,
      floatingActionButtonArea,
      scaleFactor,
    )!;
    return copyWith(floatingActionButtonArea: scaledButton);
  }

  /// 创建此 [MetroPageGeometry] 的副本，并用新的值替换给定的字段。
  MetroPageGeometry copyWith({
    double? bottomNavigationBarTop,
    Rect? floatingActionButtonArea,
  }) {
    return MetroPageGeometry(
      bottomNavigationBarTop:
          bottomNavigationBarTop ?? this.bottomNavigationBarTop,
      floatingActionButtonArea:
          floatingActionButtonArea ?? this.floatingActionButtonArea,
    );
  }
}

class _ScaffoldGeometryNotifier extends ChangeNotifier
    implements ValueListenable<MetroPageGeometry> {
  _ScaffoldGeometryNotifier(this.geometry, this.context);

  final BuildContext context;
  double? floatingActionButtonScale;
  MetroPageGeometry geometry;

  @override
  MetroPageGeometry get value {
    assert(() {
      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject == null || !renderObject.owner!.debugDoingPaint) {
        throw FlutterError(
          'Scaffold.geometryOf() must only be accessed during the paint phase.\n'
          'The ScaffoldGeometry is only available during the paint phase, because '
          'its value is computed during the animation and layout phases prior to painting.',
        );
      }
      return true;
    }());
    return geometry._scaleFloatingActionButton(floatingActionButtonScale!);
  }

  void _updateWith({
    double? bottomNavigationBarTop,
  }) {
    this.floatingActionButtonScale =
        floatingActionButtonScale ?? this.floatingActionButtonScale;
    geometry = geometry.copyWith(
      bottomNavigationBarTop: bottomNavigationBarTop,
    );
    notifyListeners();
  }
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
    required this.appBarHeight,
    required this.materialBannerHeight,
  })  : assert(bottomWidgetsHeight >= 0),
        assert(appBarHeight >= 0),
        assert(materialBannerHeight >= 0);

  final double bottomWidgetsHeight;
  final double appBarHeight;
  final double materialBannerHeight;

  // RenderObject.layout() 只有当新的布局约束和当前的不一样时，才会停止调用 performLayout 方法。
  // 如果底部部件的高度改变了，即使约束的最小值和最大值没变，我们还是想让 performLayout 执行。
  @override
  bool operator ==(Object other) {
    if (super != other) {
      return false;
    }
    return other is _BodyBoxConstraints &&
        other.materialBannerHeight == materialBannerHeight &&
        other.bottomWidgetsHeight == bottomWidgetsHeight &&
        other.appBarHeight == appBarHeight;
  }

  @override
  int get hashCode => Object.hash(
      super.hashCode, materialBannerHeight, bottomWidgetsHeight, appBarHeight);
}

// 当 Scaffold 的 extendBody 为 true 时，使用 MediaQuery 包裹 scaffold 的 body，
// 其 padding 会考虑 bottomNavigationBar 和/或 persistentFooterButtons 的高度。
//
// 底部组件的高度通过 _BodyBoxConstraints 参数传递。
// constraints 参数在 _ScaffoldLayout.performLayout() 中构建。
class _BodyBuilder extends StatelessWidget {
  const _BodyBuilder({
    required this.extendBody,
    required this.extendBodyBehindAppBar,
    required this.body,
  });

  final Widget body;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    if (!extendBody && !extendBodyBehindAppBar) {
      return body;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final _BodyBoxConstraints bodyConstraints =
            constraints as _BodyBoxConstraints;
        final MediaQueryData metrics = MediaQuery.of(context);

        final double bottom = extendBody
            ? math.max(
                metrics.padding.bottom, bodyConstraints.bottomWidgetsHeight)
            : metrics.padding.bottom;

        final double top = extendBodyBehindAppBar
            ? math.max(
                metrics.padding.top,
                bodyConstraints.appBarHeight +
                    bodyConstraints.materialBannerHeight)
            : metrics.padding.top;

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
    required this.geometryNotifier,
    required this.isSnackBarFloating,
    required this.snackBarWidth,
    required this.extendBody,
    required this.extendBodyBehindAppBar,
    required this.extendBodyBehindMaterialBanner,
  });

  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final EdgeInsets minInsets;
  final EdgeInsets minViewPadding;
  final TextDirection textDirection;
  final _ScaffoldGeometryNotifier geometryNotifier;

  final bool isSnackBarFloating;
  final double? snackBarWidth;

  final bool extendBodyBehindMaterialBanner;

  @override
  void performLayout(Size size) {
    final BoxConstraints looseConstraints = BoxConstraints.loose(size);

    // 这部分布局的效果与将应用栏和主体放在一列并使主体可伸缩相同。不同之处在于，在这种情况下，应用栏出现在主体之后，因此应用栏的阴影绘制在主体的顶部。

    final BoxConstraints fullWidthConstraints =
        looseConstraints.tighten(width: size.width);
    final double bottom = size.height;
    double contentTop = 0.0;
    double bottomWidgetsHeight = 0.0;
    double appBarHeight = 0.0;

    double? bottomNavigationBarTop;
    if (hasChild(_ScaffoldSlot.bottomNavigationBar)) {
      final double bottomNavigationBarHeight =
          layoutChild(_ScaffoldSlot.bottomNavigationBar, fullWidthConstraints)
              .height;
      bottomWidgetsHeight += bottomNavigationBarHeight;
      bottomNavigationBarTop = math.max(0.0, bottom - bottomWidgetsHeight);
      positionChild(_ScaffoldSlot.bottomNavigationBar,
          Offset(0.0, bottomNavigationBarTop));
    }

    if (hasChild(_ScaffoldSlot.persistentFooter)) {
      final BoxConstraints footerConstraints = BoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: math.max(0.0, bottom - bottomWidgetsHeight - contentTop),
      );
      final double persistentFooterHeight =
          layoutChild(_ScaffoldSlot.persistentFooter, footerConstraints).height;
      bottomWidgetsHeight += persistentFooterHeight;
      positionChild(_ScaffoldSlot.persistentFooter,
          Offset(0.0, math.max(0.0, bottom - bottomWidgetsHeight)));
    }

    Size materialBannerSize = Size.zero;
    if (hasChild(_ScaffoldSlot.materialBanner)) {
      materialBannerSize =
          layoutChild(_ScaffoldSlot.materialBanner, fullWidthConstraints);
      positionChild(_ScaffoldSlot.materialBanner, Offset(0.0, appBarHeight));

      // Push content down only if elevation is 0.
      if (!extendBodyBehindMaterialBanner) {
        contentTop += materialBannerSize.height;
      }
    }

    // 设置内容底部，考虑底部组件或键盘等系统UI的高度中较大的值。
    final double contentBottom =
        math.max(0.0, bottom - math.max(minInsets.bottom, bottomWidgetsHeight));

    if (hasChild(_ScaffoldSlot.body)) {
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
        materialBannerHeight: materialBannerSize.height,
        bottomWidgetsHeight: extendBody ? bottomWidgetsHeight : 0.0,
        appBarHeight: appBarHeight,
      );
      layoutChild(_ScaffoldSlot.body, bodyConstraints);
      positionChild(_ScaffoldSlot.body, Offset(0.0, contentTop));
    }

    // BottomSheet 和 SnackBar 都固定在父组件底部，
    // 它们的宽度与父组件相同，并且有各自的高度。
    // 唯一的区别是 SnackBar 出现在 BottomNavigationBar 的上方，
    // 而 BottomSheet 堆叠在它的上面。
    //
    // 如果三个元素同时存在，那么 FAB 的中心要么跨越 BottomSheet 的顶部边缘，
    // 要么 FAB 的底部比 SnackBar 高出 kFloatingActionButtonMargin，
    // 取决于哪种方式使 FAB 离父组件底部更远。
    // 如果只有 FAB 有非零高度，那么它会从父组件的右边和底部边缘内缩
    // kFloatingActionButtonMargin。

    Size bottomSheetSize = Size.zero;
    Size snackBarSize = Size.zero;
    if (hasChild(_ScaffoldSlot.bodyScrim)) {
      final BoxConstraints bottomSheetScrimConstraints = BoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: contentBottom,
      );
      layoutChild(_ScaffoldSlot.bodyScrim, bottomSheetScrimConstraints);
      positionChild(_ScaffoldSlot.bodyScrim, Offset.zero);
    }

    // 如果行为固定，提前设置 SnackBar 的大小，以正确放置 FAB。
    if (hasChild(_ScaffoldSlot.snackBar) && !isSnackBarFloating) {
      snackBarSize = layoutChild(_ScaffoldSlot.snackBar, fullWidthConstraints);
    }

    if (hasChild(_ScaffoldSlot.snackBar)) {
      final bool hasCustomWidth =
          snackBarWidth != null && snackBarWidth! < size.width;
      if (snackBarSize == Size.zero) {
        snackBarSize = layoutChild(
          _ScaffoldSlot.snackBar,
          hasCustomWidth ? looseConstraints : fullWidthConstraints,
        );
      }

      final double snackBarYOffsetBase;
      // SnackBarBehavior.fixed 会自动应用 SafeArea。
      // SnackBarBehavior.floating 不会，因为如果有 FloatingActionButton（见上面的条件），
      // 其定位会受到影响。如果没有 FAB，请确保在 SnackBar 浮动时考虑安全空间。
      final double safeYOffsetBase = size.height - minViewPadding.bottom;
      snackBarYOffsetBase = isSnackBarFloating
          ? math.min(contentBottom, safeYOffsetBase)
          : contentBottom;

      final double xOffset =
          hasCustomWidth ? (size.width - snackBarWidth!) / 2 : 0.0;
      positionChild(_ScaffoldSlot.snackBar,
          Offset(xOffset, snackBarYOffsetBase - snackBarSize.height));

      assert(() {
        // 判断一个悬浮的 SnackBar 是否被抬得太高。
        //
        // 为了提升开发者体验，这个断言放在 positionChild 调用之后。
        // 如果我们提前断言，SnackBar 会因为默认位置是 (0,0) 而被显示，
        // 这会让用户混淆错误信息，认为 SnackBar 显示在屏幕外。
        if (isSnackBarFloating) {
          final bool snackBarVisible =
              (snackBarYOffsetBase - snackBarSize.height) >= 0;
          if (!snackBarVisible) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('Floating SnackBar presented off screen.'),
              ErrorDescription(
                  'A SnackBar with behavior property set to SnackBarBehavior.floating is fully '
                  'or partially off screen because some or all the widgets provided to '
                  'Scaffold.floatingActionButton, Scaffold.persistentFooterButtons and '
                  'Scaffold.bottomNavigationBar take up too much vertical space.\n'),
              ErrorHint(
                'Consider constraining the size of these widgets to allow room for the SnackBar to be visible.',
              ),
            ]);
          }
        }
        return true;
      }());
    }

    if (hasChild(_ScaffoldSlot.statusBar)) {
      layoutChild(_ScaffoldSlot.statusBar,
          fullWidthConstraints.tighten(height: minInsets.top));
      positionChild(_ScaffoldSlot.statusBar, Offset.zero);
    }

    geometryNotifier._updateWith(
      bottomNavigationBarTop: bottomNavigationBarTop,
    );
  }

  @override
  bool shouldRelayout(_MetroPageLayout oldDelegate) {
    return oldDelegate.minInsets != minInsets ||
        oldDelegate.minViewPadding != minViewPadding ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.extendBody != extendBody ||
        oldDelegate.extendBodyBehindAppBar != extendBodyBehindAppBar;
  }
}

/// 处理 [FloatingActionButton] 的缩放和旋转动画。
///
/// 目前，[FloatingActionButton] 有两种类型的动画：
///
/// * 进场/退场动画，当 [FloatingActionButton] 被添加、更新或移除时，此小部件会触发这些动画。
/// * 运动动画，当其 [FloatingActionButtonLocation] 被更新时，[MetroPage] 会触发这些动画。
class _FloatingActionButtonTransition extends StatefulWidget {
  const _FloatingActionButtonTransition({
    required this.child,
    required this.fabMoveAnimation,
    required this.fabMotionAnimator,
    required this.geometryNotifier,
    required this.currentController,
  });

  final Widget? child;
  final Animation<double> fabMoveAnimation;
  final FloatingActionButtonAnimator fabMotionAnimator;
  final _ScaffoldGeometryNotifier geometryNotifier;

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
    widget.geometryNotifier._updateWith(
        //floatingActionButtonScale: scale,
        );
  }
}

/// 实现基本的 Material Design 视觉布局结构。
///
/// 注：Windows Phone的底部菜单和这个逻辑不一样所以需要进行移除改造
///
/// 此类提供显示抽屉和底部工作表的 API。
///
/// 若要显示一个持久性的底部工作表，请通过 [MetroPage.of] 获取当前 [BuildContext] 的
/// [MetroPageState]，并使用 [MetroPageState.showBottomSheet] 函数。
///
/// {@tool dartpad}
/// 此示例显示一个带有 [body] 和 [FloatingActionButton] 的 [MetroPage]。
/// [body] 是一个放置在 [Center] 中的 [Text]，用于将文本居中在 [MetroPage] 内。
/// [FloatingActionButton] 连接到一个递增计数器的回调。
///
/// ** 参见示例代码 examples/api/lib/material/scaffold/scaffold.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// 此示例显示一个带有蓝灰色 [backgroundColor]、[body]
/// 和 [FloatingActionButton] 的 [MetroPage]。 [body] 是一个放置在 [Center] 中的
/// [Text]，用于将文本居中在 [MetroPage] 内。 [FloatingActionButton]
/// 连接到一个递增计数器的回调。
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/material/scaffold_background_color.png)
///
/// ** 参见示例代码 examples/api/lib/material/scaffold/scaffold.1.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// 此示例显示一个带有 [AppBar]、[BottomAppBar] 和
/// [FloatingActionButton] 的 [MetroPage]。 [body] 是一个放置在 [Center] 中的 [Text]，
/// 用于将文本居中在 [MetroPage] 内。 [FloatingActionButton] 使用
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
/// 如果 [MetroPage.bottomSheet] 是一个 [DraggableScrollableSheet]，
/// [MetroPage.floatingActionButton] 被设置，并且底部工作表被拖动以
/// 覆盖 Scaffold 高度的大于 70%，则会并行发生两件事情：
///
///   * Scaffold 开始显示遮罩层（见 [MetroPageState.showBodyScrim]），
///   * [MetroPage.floatingActionButton] 通过带有 [Curves.easeIn] 的动画缩放并在​///     底部工作表覆盖整个 Scaffold 时消失。
///
/// 当底部工作表被拖到底部覆盖 Scaffold 的高度小于 70% 时，遮罩层
/// ​/// 消失，[MetroPage.floatingActionButton] 动画回到其正常大小。
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
///  * [BottomAppBar]，通常在应用程序底部显示的水平栏，使用 [bottomNavigationBar] 属性。
///  * [FloatingActionButton]，通常在应用程序的右下角显示的圆形按钮，使用 [floatingActionButton] 属性。
///  * [Drawer]，通常显示在主体左侧的垂直面板（在手机上通常隐藏），使用 [drawer] 属性。
///  * [BottomNavigationBar]，通常沿应用程序底部显示的水平按钮数组，使用 [bottomNavigationBar] 属性。
///  * [BottomSheet]，通常在应用程序底部附近显示的覆盖层。底部工作表可以是持久性的，此时使用 [MetroPageState.showBottomSheet] 方法显示，或者是模态的，此时使用 [showModalBottomSheet] 函数显示。
///  * [SnackBar]，一种轻量级的消息，带有可选操作，短暂显示在屏幕底部。使用 [MetroPageMessengerState.showSnackBar] 方法显示 Snack Bar。
///  * [2]，在屏幕顶部、应用栏下方显示一个重要且简明的信息。使用 [MetroPageMessengerState.showMaterialBanner] 方法显示 Material Banner。
///  * [MetroPageState]，与此小部件关联的状态。
///  * <https://material.io/design/layout/responsive-layout-grid.html>
///  * 教程：[为屏幕添加抽屉](https://docs.flutter.dev/cookbook/design/drawer)
class MetroPage extends StatefulWidget {
  /// 创建 Material Design 小部件的视觉脚手架。
  const MetroPage({
    super.key,
    this.body,
    this.persistentFooterButtons,
    this.persistentFooterAlignment = AlignmentDirectional.centerEnd,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
  });

  /// 如果为 true，并且指定了 [bottomNavigationBar] 或 [persistentFooterButtons]，
  /// 则 [body] 将延伸至 Scaffold 的底部，
  /// 而不仅仅延伸至 [bottomNavigationBar] 或 [persistentFooterButtons] 的顶部。
  ///
  /// 如果为 true，将在 scaffold 的 [body] 之上添加一个 [MediaQuery] 小部件，
  /// 其底部填充与 [bottomNavigationBar] 的高度相匹配。
  ///
  /// 当 [bottomNavigationBar] 具有非矩形形状时，此属性通常很有用，
  /// 如 [CircularNotchedRectangle]，它在导航栏的顶部边缘添加了一个适合 [FloatingActionButton] 的凹口。
  /// 在这种情况下，指定 `extendBody: true` 可确保 Scaffold 的 body 能通过底部导航栏的凹口可见。
  ///
  /// 另请参见：
  ///
  ///  * [extendBodyBehindAppBar]，它将 body 的高度延伸到 Scaffold 的顶部。
  final bool extendBody;

  /// 如果为 true，并且指定了 [appBar]，则 [body] 的高度将延伸至包括应用栏的高度，
  /// 并且 body 的顶部与应用栏的顶部对齐。
  ///
  /// 如果应用栏的 [AppBar.backgroundColor] 不是完全不透明的，这将非常有用。
  ///
  /// 此属性默认值为 false。
  ///
  /// 另请参见:
  ///
  ///  * [extendBody]，它将 body 的高度延伸到 scaffold 的底部。
  final bool extendBodyBehindAppBar;

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

  /// 一组显示在脚手架底部的按钮。
  ///
  /// 通常这是一个 [TextButton] 小部件列表。这些按钮是持久可见的，即使脚手架的 [body] 滚动也是如此。
  ///
  /// 这些小部件将被包裹在一个 [OverflowBar] 中。
  ///
  /// [persistentFooterButtons] 渲染在 [bottomNavigationBar] 之上，但在 [body] 之下。
  final List<Widget>? persistentFooterButtons;

  /// The alignment of the [persistentFooterButtons] inside the [OverflowBar].
  ///
  /// Defaults to [AlignmentDirectional.centerEnd].
  final AlignmentDirectional persistentFooterAlignment;

  /// [Material] 小部件的颜色，它在整个 Scaffold 下方。
  ///
  /// 默认情况下使用主题的 [ThemeData.scaffoldBackgroundColor]。
  final Color? backgroundColor;

  /// 在脚手架底部显示的底部导航栏。
  ///
  /// Snack bars 从底部导航栏下方滑出，而底部工作表则堆叠在顶部。
  ///
  /// [bottomNavigationBar] 渲染在 [persistentFooterButtons] 和 [body] 之下。
  final Widget? bottomNavigationBar;

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

  /// {@macro flutter.material.DrawerController.dragStartBehavior}
  final DragStartBehavior drawerDragStartBehavior;

  /// 在此宽度范围内进行水平滑动将打开抽屉。
  ///
  /// 默认情况下，使用的值是 20.0 加上 `MediaQuery.paddingOf(context)` 的边距，
  /// 该边距对应于周围的 [TextDirection]。这确保了凹口设备的拖动区域不会被遮挡。
  /// 例如，如果 `TextDirection.of(context)` 设置为 [TextDirection.ltr]，
  /// 则会将 20.0 加到 `MediaQuery.paddingOf(context).left` 上。
  final double? drawerEdgeDragWidth;

  /// Determines if the [MetroPage.drawer] can be opened with a drag
  /// gesture on mobile.
  ///
  /// On desktop platforms, the drawer is not draggable.
  ///
  /// By default, the drag gesture is enabled on mobile.
  final bool drawerEnableOpenDragGesture;

  /// Determines if the [MetroPage.endDrawer] can be opened with a
  /// gesture on mobile.
  ///
  /// On desktop platforms, the drawer is not draggable.
  ///
  /// By default, the drag gesture is enabled on mobile.
  final bool endDrawerEnableOpenDragGesture;

  /// 用于保存和恢复 [MetroPage] 状态的恢复 ID。
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

  /// 从最接近的此类实例中查找 [MetroPageState]。
  ///
  /// 如果没有此类实例包含给定的上下文，在调试模式下会导致断言，在发布模式下会抛出异常。
  ///
  /// 此方法可能会很耗时（它会遍历元素树）。
  ///
  /// {@tool dartpad}
  /// [MetroPage.of] 函数的典型用法是在 [MetroPage] 子小部件的 `build` 方法中调用它。
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold.of.0.dart 中的代码 **
  /// {@end-tool}
  ///
  /// {@tool dartpad}
  /// 当 [MetroPage] 实际上是在同一个 `build` 函数中创建时，`build` 函数的 `context` 参数不能用于查找 [MetroPage]（因为它在返回的小部件树中位于小部件的“上方”）。在这种情况下，可以使用以下技术与 [Builder] 提供一个新的作用域，其中包含“在”[MetroPage] 下的 [BuildContext]：
  ///
  /// ** 请参阅 examples/api/lib/material/scaffold/scaffold.of.1.dart 中的代码 **
  /// {@end-tool}
  ///
  /// 更有效的解决方案是将你的构建函数拆分为几个小部件。这会引入一个新的上下文，你可以从中获取 [MetroPage]。在这种解决方案中，你会有一个外部小部件来创建由新内部小部件实例填充的 [MetroPage]，然后在这些内部小部件中使用 [MetroPage.of]。
  ///
  /// 一个不太优雅但更快捷的解决方案是为 [MetroPage] 分配一个 [GlobalKey]，然后使用 `key.currentState` 属性来获取 [MetroPageState]，而不是使用 [MetroPage.of] 函数。
  ///
  /// 如果范围内没有 [MetroPage]，则会抛出异常。要在没有 [MetroPage] 时返回 null，请使用 [maybeOf]。
  static MetroPageState of(BuildContext context) {
    final MetroPageState? result =
        context.findAncestorStateOfType<MetroPageState>();
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

  /// 从最接近的此类实例中查找 [MetroPageState]。
  ///
  /// 如果没有此类实例包含给定的上下文，将返回 null。
  /// 要抛出异常，请使用 [of] 而不是此函数。
  ///
  /// 此方法可能会很耗时（它会遍历元素树）。
  ///
  /// 另请参见:
  ///
  ///  * [of]，这是一个类似的函数，但如果没有实例包含给定的上下文，它会抛出异常。其文档中还包括一些示例代码。
  static MetroPageState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<MetroPageState>();
  }


  @override
  MetroPageState createState() => MetroPageState();
}

/// [MetroPage] 的状态。
///
/// 可以显示 [BottomSheet]。使用 [MetroPage.of] 从当前的 [BuildContext] 中获取 [MetroPageState]。
class MetroPageState extends State<MetroPage>
    with TickerProviderStateMixin, RestorationMixin {
  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // registerForRestoration(_drawerOpened, 'drawer_open');
    // registerForRestoration(_endDrawerOpened, 'end_drawer_open');
  }

  // DRAWER API

  final GlobalKey _bodyKey = GlobalKey();

  // Used for both the snackbar and material banner APIs
  MetroPageMessengerState? _scaffoldMessenger;

  // SNACKBAR API
  MetroPageFeatureController<SnackBar, SnackBarClosedReason>?
      _messengerSnackBar;

  // This is used to update the _messengerSnackBar by the ScaffoldMessenger.
  void _updateSnackBar() {
    final MetroPageFeatureController<SnackBar, SnackBarClosedReason>?
        messengerSnackBar = _scaffoldMessenger!._snackBars.isNotEmpty
            ? _scaffoldMessenger!._snackBars.first
            : null;

    if (_messengerSnackBar != messengerSnackBar) {
      setState(() {
        _messengerSnackBar = messengerSnackBar;
      });
    }
  }

  // MATERIAL BANNER API

  // The _messengerMaterialBanner represents the current MaterialBanner being managed by
  // the ScaffoldMessenger, instead of the Scaffold.
  MetroPageFeatureController<MaterialBanner, MaterialBannerClosedReason>?
      _messengerMaterialBanner;

  // This is used to update the _messengerMaterialBanner by the ScaffoldMessenger.
  void _updateMaterialBanner() {
    final MetroPageFeatureController<MaterialBanner,
            MaterialBannerClosedReason>? messengerMaterialBanner =
        _scaffoldMessenger!._materialBanners.isNotEmpty
            ? _scaffoldMessenger!._materialBanners.first
            : null;

    if (_messengerMaterialBanner != messengerMaterialBanner) {
      setState(() {
        _messengerMaterialBanner = messengerMaterialBanner;
      });
    }
  }
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

  late _ScaffoldGeometryNotifier _geometryNotifier;

  bool get _resizeToAvoidBottomInset {
    return widget.resizeToAvoidBottomInset ?? true;
  }

  @override
  void initState() {
    super.initState();
    _geometryNotifier =
        _ScaffoldGeometryNotifier(const MetroPageGeometry(), context);
  }

  @override
  void didChangeDependencies() {
    // Using maybeOf is valid here since both the Scaffold and ScaffoldMessenger
    // are currently available for managing SnackBars.
    final MetroPageMessengerState? currentScaffoldMessenger =
        MetroPageMessenger.maybeOf(context);
    // If our ScaffoldMessenger has changed, unregister with the old one first.
    if (_scaffoldMessenger != null &&
        (currentScaffoldMessenger == null ||
            _scaffoldMessenger != currentScaffoldMessenger)) {
      _scaffoldMessenger?._unregister(this);
    }
    // Register with the current ScaffoldMessenger, if there is one.
    _scaffoldMessenger = currentScaffoldMessenger;
    _scaffoldMessenger?._register(this);

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _geometryNotifier.dispose();
    _scaffoldMessenger?._unregister(this);
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

  bool _showBodyScrim = false;
  Color _bodyScrimColor = Colors.black;

  /// Whether to show a [ModalBarrier] over the body of the scaffold.
  void showBodyScrim(bool value, double opacity) {
    if (_showBodyScrim == value && _bodyScrimColor.opacity == opacity) {
      return;
    }
    setState(() {
      _showBodyScrim = value;
      _bodyScrimColor = Colors.black.withOpacity(opacity);
    });
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
              extendBody: widget.extendBody,
              extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
              body: KeyedSubtree(key: _bodyKey, child: widget.body!),
            ),
      _ScaffoldSlot.body,
      removeLeftPadding: false,
      removeTopPadding: true,
      removeRightPadding: false,
      removeBottomPadding: widget.bottomNavigationBar != null ||
          widget.persistentFooterButtons != null,
      removeBottomInset: _resizeToAvoidBottomInset,
    );
    if (_showBodyScrim) {
      _addIfNonNull(
        children,
        ModalBarrier(
          dismissible: false,
          color: _bodyScrimColor,
        ),
        _ScaffoldSlot.bodyScrim,
        removeLeftPadding: true,
        removeTopPadding: true,
        removeRightPadding: true,
        removeBottomPadding: true,
      );
    }

    bool isSnackBarFloating = false;
    double? snackBarWidth;

    // SnackBar set by ScaffoldMessenger
    if (_messengerSnackBar != null) {
      final SnackBarBehavior snackBarBehavior =
          _messengerSnackBar?._widget.behavior ??
              themeData.snackBarTheme.behavior ??
              SnackBarBehavior.fixed;
      isSnackBarFloating = snackBarBehavior == SnackBarBehavior.floating;
      snackBarWidth =
          _messengerSnackBar?._widget.width ?? themeData.snackBarTheme.width;

      _addIfNonNull(
        children,
        _messengerSnackBar?._widget,
        _ScaffoldSlot.snackBar,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: widget.bottomNavigationBar != null ||
            widget.persistentFooterButtons != null,
        maintainBottomViewPadding: !_resizeToAvoidBottomInset,
      );
    }

    bool extendBodyBehindMaterialBanner = false;
    // MaterialBanner set by ScaffoldMessenger
    if (_messengerMaterialBanner != null) {
      final MaterialBannerThemeData bannerTheme =
          MaterialBannerTheme.of(context);
      final double elevation = _messengerMaterialBanner?._widget.elevation ??
          bannerTheme.elevation ??
          0.0;
      extendBodyBehindMaterialBanner = elevation != 0.0;

      _addIfNonNull(
        children,
        _messengerMaterialBanner?._widget,
        _ScaffoldSlot.materialBanner,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: true,
        maintainBottomViewPadding: !_resizeToAvoidBottomInset,
      );
    }

    if (widget.persistentFooterButtons != null) {
      _addIfNonNull(
        children,
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: Divider.createBorderSide(context, width: 1.0),
            ),
          ),
          child: SafeArea(
            top: false,
            child: IntrinsicHeight(
              child: Container(
                alignment: widget.persistentFooterAlignment,
                padding: const EdgeInsets.all(8),
                child: OverflowBar(
                  spacing: 8,
                  overflowAlignment: OverflowBarAlignment.end,
                  children: widget.persistentFooterButtons!,
                ),
              ),
            ),
          ),
        ),
        _ScaffoldSlot.persistentFooter,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: widget.bottomNavigationBar != null,
        maintainBottomViewPadding: !_resizeToAvoidBottomInset,
      );
    }

    if (widget.bottomNavigationBar != null) {
      _addIfNonNull(
        children,
        widget.bottomNavigationBar,
        _ScaffoldSlot.bottomNavigationBar,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: false,
        maintainBottomViewPadding: !_resizeToAvoidBottomInset,
      );
    }

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
          _ScaffoldSlot.statusBar,
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
    final bool extendBody = minInsets.bottom <= 0 && widget.extendBody;

    return ScrollNotificationObserver(
      child: Material(
        color: widget.backgroundColor ?? themeData.scaffoldBackgroundColor,
        child: CustomMultiChildLayout(
          delegate: _MetroPageLayout(
            extendBody: extendBody,
            extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
            minInsets: minInsets,
            minViewPadding: minViewPadding,
            geometryNotifier: _geometryNotifier,
            textDirection: textDirection,
            isSnackBarFloating: isSnackBarFloating,
            extendBodyBehindMaterialBanner: extendBodyBehindMaterialBanner,
            snackBarWidth: snackBarWidth,
          ),
          children: children,
        ),
      ),
    );
  }
}

/// 控制 [MetroPage] 功能的接口。
///
/// 通常从 [MetroPageMessengerState.showSnackBar] 或 [MetroPageState.showBottomSheet] 获取。
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