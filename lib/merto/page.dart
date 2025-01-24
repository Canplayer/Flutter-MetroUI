// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
//import 'package:flutter/material.dart';

/// 一个使用想学习模仿Windows Phone换页行为的路由。因为修改于MaterialPageRoute，
/// 所以部分行为可能与MaterialPageRoute一致，但是做了很多删改。
///
/// {@macro flutter.material.materialRouteTransitionMixin}
///
/// 默认情况下，当一个模态路由被另一个替换时，前一个路由仍然保留在内存中。
/// 如果不需要保留所有资源，请将 [maintainState] 设置为 false。
///
/// 如果 `barrierDismissible` 为 true，则按下键盘上的退出键将导致当前路由以 null 作为值被弹出。
///
/// 类型 `T` 指定路由的返回类型，可以在通过 [Navigator.pop] 从堆栈中弹出路由时提供可选的 `result` 参数。
///
/// 另请参见:
///
///  * [MetroRouteTransitionMixin]，它为此路由提供了材质过渡效果。
///  * [MetroPage]，它是此类的 [Page]。

class MetroPageRoute<T> extends PageRoute<T> with MetroRouteTransitionMixin<T> {
  /// Construct a MetroPageRoute whose contents are defined by [builder].
  MetroPageRoute({
    required this.builder,
    super.settings,
    this.maintainState = true,
    super.allowSnapshotting = true,
    super.barrierDismissible = false,
  }) {
    assert(opaque);
  }

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  final bool maintainState;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

/// 一个为 [PageRoute] 提供平台自适应过渡效果的 mixin。
///
/// {@template flutter.material.materialRouteTransitionMixin}
/// 对于 Android，页面的进入过渡效果是放大并淡入，而退出页面则是缩小并淡出。
/// 退出过渡效果类似，但顺序相反。
///
/// 对于 iOS，页面从右侧滑入并以相反方式退出。当另一个页面进入覆盖时，页面还会以视差效果向左移动。
/// （在从右到左的阅读方向环境中，这些方向是相反的。）
/// {@endtemplate}
///
/// 另请参见:
///
///  * [PageTransitionsTheme]，它定义了 [MetroRouteTransitionMixin.buildTransitions] 使用的默认页面过渡效果。
///  * [ZoomPageTransitionsBuilder]，它是 [PageTransitionsTheme] 使用的默认页面过渡效果。

mixin MetroRouteTransitionMixin<T> on PageRoute<T> {
  /// Builds the primary contents of the route.
  @protected
  Widget buildContent(BuildContext context);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 0);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // 如果下一个路由是全屏对话框，则不执行退出动画。
    return (nextRoute is MetroRouteTransitionMixin &&
        !nextRoute.fullscreenDialog);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget result = buildContent(context);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: result,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // 这里的动画行为还是直接切吧，如果尝试使用任何的动画行为，可能第一帧会删一下我也不知道什么原因反正这样写硬切才是我发现的最佳方案。
    return child;
  }
}

/// 一个创建材质风格 [PageRoute] 的页面。
///
/// {@macro flutter.material.materialRouteTransitionMixin}
///
/// 默认情况下，当创建的路由被另一个替换时，前一个路由仍然保留在内存中。
/// 如果不需要保留所有资源，请将 [maintainState] 设置为 false。
///
///
/// 类型 `T` 指定路由的返回类型，可以在通过 [Navigator.transitionDelegate] 从堆栈中弹出路由时提供可选的 `result` 参数，
/// 通过在 [TransitionDelegate.resolve] 中提供给 [RouteTransitionRecord.markForPop]。
///
/// 另请参见:
///
///  * [MetroPageRoute]，它是此类的 [PageRoute] 版本
class MetroPage<T> extends Page<T> {
  /// Creates a material page.
  const MetroPage({
    required this.child,
    this.maintainState = true,
    this.allowSnapshotting = true,
    super.key,
    super.canPop,
    super.onPopInvoked,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  /// {@macro flutter.widgets.TransitionRoute.allowSnapshotting}
  final bool allowSnapshotting;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedMetroPageRoute<T>(
        page: this, allowSnapshotting: allowSnapshotting);
  }
}

// 基于页面的 MetroPageRoute 版本。
//
// 此路由使用页面的构建器来构建其内容。这确保了内容在页面更新后是最新的。
class _PageBasedMetroPageRoute<T> extends PageRoute<T>
    with MetroRouteTransitionMixin<T> {
  _PageBasedMetroPageRoute({
    required MetroPage<T> page,
    super.allowSnapshotting,
  }) : super(settings: page) {
    assert(opaque);
  }

  MetroPage<T> get _page => settings as MetroPage<T>;

  @override
  bool didPop(T? result) {
    // 在这里插入需要的逻辑
    print('Pop event from _PageBasedMetroPageRoute');
    return super.didPop(result);
  }

  @override
  Widget buildContent(BuildContext context) {
    return _page.child;
  }

  @override
  bool get maintainState => _page.maintainState;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}
