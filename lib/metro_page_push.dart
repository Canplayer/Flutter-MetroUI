import 'package:flutter/material.dart';
import 'package:metro_ui/page_scaffold.dart';

// 假设 MetroPageScaffold 和 MetroPageScaffoldState 都在您的项目中定义

/// 自定义页面跳转函数，在跳转前执行当前页面的预设动画或延迟。
///
/// [context]：当前页面的 BuildContext。
/// [route]：要跳转到的新页面路由。
/// [prePushDelay]：可选的固定延迟，在 onDidPushNext 完成后，Navigator.push 之前执行。
Future<T?> metroPagePush<T extends Object?>(
  BuildContext context,
  Route<T> route, {
  Duration prePushDelay = Duration.zero,
}) async {
  // 尝试获取当前页面的 MetroPageScaffoldState
  final MetroPageScaffoldState? currentScaffoldState = MetroPageScaffold.maybeOf(context);

  // 如果当前页面有 MetroPageScaffold 并且设置了 onDidPushNext 回调
  if (currentScaffoldState != null && currentScaffoldState.widget.onDidPushNext != null) {
    // 调用当前页面的 onDidPushNext 回调，并等待其完成
    // 在这里，您可以启动一个预设动画，并在动画完成后返回Future
    await currentScaffoldState.widget.onDidPushNext!();
  }

  // 在执行实际页面跳转之前，可以添加一个额外的固定延迟
  if (prePushDelay > Duration.zero) {
    await Future<void>.delayed(prePushDelay);
  }

  // 执行实际的页面跳转
  return Navigator.of(context).push<T>(route);
}