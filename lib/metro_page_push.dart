import 'package:flutter/material.dart';
import 'package:metro_ui/page_scaffold.dart';

// 假设 MetroPageScaffold 和 MetroPageScaffoldState 都在您的项目中定义

bool _alwaysFalseRoutePredicate(Route<dynamic> _) => false;

Future<void> _runPrePushAnimation(
  BuildContext context, {
  Duration prePushDelay = Duration.zero,
  dynamic? dataToPass,
  GlobalKey<MetroPageScaffoldState>? scaffoldKey,
}) async {
  MetroPageScaffoldState? currentScaffoldState;
  // 尝试获取当前页面的 MetroPageScaffoldState
  // 1) 优先用显式传入的 GlobalKey
  if (scaffoldKey != null) {
    currentScaffoldState = scaffoldKey.currentState;
  }

  // 2) 否则尝试常规查找（如果 context 合适）
  currentScaffoldState ??= MetroPageScaffold.maybeOf(context);

  // 如果当前页面有 MetroPageScaffold 并且设置了 onDidPushNext 回调
  if (currentScaffoldState != null) {
    if (currentScaffoldState.widget.onDidPushNext != null) {
      // 调用当前页面的 onDidPushNext 回调，并等待其完成
      await currentScaffoldState.widget.onDidPushNext!(dataToPass);
    } else {
      // 播放默认动画
      await currentScaffoldState.playDefaultPushNextAnimation();
    }
  } else {
    // 可选：日志或降级策略
    debugPrint(
        'MetroPageScaffold state not found; performing navigation without page animation.');
  }

  // 在执行实际页面跳转之前，可以添加一个额外的固定延迟
  if (prePushDelay > Duration.zero) {
    await Future<void>.delayed(prePushDelay);
  }
}

/// 自定义页面跳转函数，在跳转前执行当前页面的预设动画或延迟。
///
/// [context]：当前页面的 BuildContext。
/// [route]：要跳转到的新页面路由。
/// [prePushDelay]：可选的固定延迟，在 onDidPushNext 完成后，Navigator.push 之前执行。
Future<T?> metroPagePush<T extends Object?>(
  BuildContext context,
  Route<T> route, {
  Duration prePushDelay = Duration.zero,
  dynamic? dataToPass,
  GlobalKey<MetroPageScaffoldState>? scaffoldKey,
}) async {
  await _runPrePushAnimation(
    context,
    prePushDelay: prePushDelay,
    dataToPass: dataToPass,
    scaffoldKey: scaffoldKey,
  );

  // 执行实际的页面跳转
  if (context.mounted) {
    return Navigator.of(context).push<T>(route);
  }
  return null;
}

Future<T?> metroPagePushReplacement<T extends Object?, TO extends Object?>(
  BuildContext context,
  Route<T> route, {
  Duration prePushDelay = Duration.zero,
  dynamic? dataToPass,
  GlobalKey<MetroPageScaffoldState>? scaffoldKey,
}) async {
  await _runPrePushAnimation(
    context,
    prePushDelay: prePushDelay,
    dataToPass: dataToPass,
    scaffoldKey: scaffoldKey,
  );

  // 执行实际的页面跳转
  if (context.mounted) {
    return Navigator.of(context).pushReplacement<T, TO>(route);
  }
  return null;
}

Future<T?> metroPagePushAndRemoveUntil<T extends Object?>(
  BuildContext context,
  Route<T> route, {
  Duration prePushDelay = Duration.zero,
  dynamic? dataToPass,
  GlobalKey<MetroPageScaffoldState>? scaffoldKey,
  RoutePredicate predicate = _alwaysFalseRoutePredicate,
}) async {
  await _runPrePushAnimation(
    context,
    prePushDelay: prePushDelay,
    dataToPass: dataToPass,
    scaffoldKey: scaffoldKey,
  );

  if (context.mounted) {
    return Navigator.of(context).pushAndRemoveUntil<T>(route, predicate);
  }
  return null;
}
