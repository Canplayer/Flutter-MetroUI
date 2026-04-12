import 'package:flutter/material.dart';
import 'package:metro_ui/widgets/tile.dart';
import 'package:metro_ui/metro_theme_extensions.dart';

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
  bool _isTouch = false;
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context).extension<MetroButtonThemeData>();
    final primaryColor = Theme.of(context).colorScheme.onSurface;
    
    // Defaults from theme extension or fallback
    final normalBorderColor = widget.borderColor ?? themeData?.normalBorderColor ?? primaryColor;
    final pressedBgColor = themeData?.pressedBackgroundColor ?? Theme.of(context).colorScheme.primary;
    final pressedTextColor = widget.textColor ?? themeData?.pressedTextColor ?? Colors.white;
    final disabledBorderColor = themeData?.disabledBorderColor ?? primaryColor.withValues(alpha: 0.5);
    final disabledTextColor = themeData?.disabledTextColor ?? primaryColor.withValues(alpha: 0.5);
    final normalTextColor = widget.textColor ?? primaryColor;

    final isDisabled = widget.onTap == null;

    final currentBorderColor = isDisabled ? disabledBorderColor : normalBorderColor;
    final currentBgColor = _isTouch ? pressedBgColor : null;
    final currentTextColor = isDisabled 
        ? disabledTextColor 
        : (_isTouch ? pressedTextColor : normalTextColor);

    return Tile(
      onTap: widget.onTap,
      onTouch: isDisabled ? null : (isTouch) {
        setState(() {
          _isTouch = isTouch;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: currentBgColor,
          border: Border.all(
            color: currentBorderColor,
            width: widget.borderWidth,
          ),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 19.5,
            color: currentTextColor,
          ),
          child: widget.child!,
        ),
      ),
    );
  }
}
