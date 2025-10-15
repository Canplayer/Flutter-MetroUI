import 'package:flutter/material.dart';

/// Metro 风格的 StackPanel 组件
///
/// 用于在页面顶部显示两个垂直排列的小部件，通常用于显示标题和主要内容。
/// 默认样式针对文本进行了优化：
/// - 上方文本：字体大小 20，正常字重
/// - 下方文本：字体大小 72，粗体字重
class StackPanel extends StatelessWidget {
  /// 创建一个 StackPanel
  ///
  /// [top] 和 [bottom] 参数通常传入 Text 小部件。
  const StackPanel({
    super.key,
    required this.top,
    required this.bottom,
  });

  /// 上方的小部件
  final Widget top;

  /// 下方的小部件
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 25,
        ),
        SizedBox(height: 13),
        Transform.translate(
          offset: const Offset(18, 0),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
            ),
            child: top,
          ),
        ),
        SizedBox(height: 8),
        Transform.translate(
          offset: const Offset(15, 0),
          child: DefaultTextStyle(
            maxLines: 1,
            style: TextStyle(
              fontSize: 57,
              //行间距
              height: 1,
              fontWeight: FontWeight.w300,
              overflow: TextOverflow.visible,
              fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
            ),
            child: bottom,
          ),
        ),
      ],
    );
  }
}
