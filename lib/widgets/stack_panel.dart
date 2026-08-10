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
    this.top,
    this.bottom,
  });

  /// 上方的小部件
  final Widget? top;

  /// 下方的小部件
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Container(
        //   height: 25,
        // ),
        const SafeArea(
          minimum: EdgeInsets.only(top: 47 * 0.8),
          child: SizedBox(),
        ),
        //const SizedBox(height: 13),
        Transform.translate(
          offset: const Offset(22 * 0.8, 0),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 22 * 0.8,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight(400),
              letterSpacing: 0.6,
            ),
            child: top ?? const SizedBox.shrink(),
          ),
        ),
        if (bottom != null) ...[
          Transform.translate(
            offset: const Offset(17.5 * 0.8, 3.5 * 0.8),
            child: DefaultTextStyle.merge(
              maxLines: 1,
              style: TextStyle(
                fontSize: 57,
                //行间距
                height: 1,
                fontWeight: const FontWeight(350),
                overflow: TextOverflow.visible,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                letterSpacing: 0.3,
              ),
              child: bottom ?? const SizedBox.shrink(),
            ),
          ),
          SizedBox(
            height: 44 * 0.8,
          ),
        ],
      ],
    );
  }
}
