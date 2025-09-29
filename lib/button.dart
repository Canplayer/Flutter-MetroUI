import 'package:flutter/material.dart';
import 'package:metro_ui/tile.dart';

//Windows Phone 核心风格的按钮设计组件

class MetroButton extends StatefulWidget {
  /// 传入子组件
  final Widget? child;
  
  /// 按下后发生的事件
  final Function()? onTap;
  
  /// 边框内边距
  final EdgeInsetsGeometry padding;
  
  /// 边框颜色，为null时使用主题主色调
  final Color? borderColor;
  
  /// 文字颜色，为null时使用主题主色调
  final Color? textColor;
  
  /// 边框宽度
  final double borderWidth;

  const MetroButton({
    super.key, 
    this.child, 
    this.onTap,
    this.padding = const EdgeInsets.all(4.6),
    this.borderColor,
    this.textColor,
    this.borderWidth = 2.5,
  });

  @override
  MetroButtoState createState() => MetroButtoState();
}

class MetroButtoState extends State<MetroButton> {
  @override
  Widget build(BuildContext context) {
    // 获取主题颜色作为默认值
    final primaryColor = Theme.of(context).colorScheme.onSurface;
    final effectiveBorderColor = widget.borderColor ?? primaryColor;
    final effectiveTextColor = widget.textColor ?? primaryColor;
    
    return Tile(
      onTap: widget.onTap,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          border: Border.all(
            color: effectiveBorderColor,
            width: widget.borderWidth,
          ),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 19.5,
            color: effectiveTextColor,
          ), 
          child: widget.child!,
        ),
      ),
    );
  }
}
