import 'package:flutter/material.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/widgets/tile.dart';
import 'package:metro_ui/widgets/uix_text.dart';
import 'package:metro_ui/metro_theme_extensions.dart';

//Windows Phone 核心风格的按钮设计组件

class MetroButton extends StatefulWidget {
  /// 传入子组件
  final Widget? child;

  /// 按下后发生的事件
  final Function()? onTap;

  /// 边框内边距：`Constants.ButtonPadding` = 15,0,15,0
  final EdgeInsetsGeometry padding;

  /// 外边距：`Constants.ButtonMargins` = 0,12,0,12
  final EdgeInsetsGeometry margin;

  /// 边框颜色，为null时使用主题主色调
  final Color? borderColor;

  /// 文字颜色，为null时使用主题主色调
  final Color? textColor;

  /// 边框宽度：`Backgrounds.MediumBorder` 位图环厚 3px，另加 1px AA 边
  final double borderWidth;

  const MetroButton({
    super.key,
    this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 15 * 0.8),
    this.margin = const EdgeInsets.symmetric(vertical: 12 * 0.8),
    this.borderColor,
    this.textColor,
    this.borderWidth = 3 * 0.8,
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
    final normalBorderColor =
        widget.borderColor ?? themeData?.normalBorderColor ?? primaryColor;
    final pressedBgColor =
        themeData?.pressedBackgroundColor ??
        Theme.of(context).colorScheme.primary;
    final pressedTextColor =
        widget.textColor ?? themeData?.pressedTextColor ?? Colors.white;
    // MediumBorderDisabled 位图不透明度 102/255，TextLowColor 为前景的低对比变体。
    const disabledAlpha = 102 / 255;
    final disabledBorderColor =
        themeData?.disabledBorderColor ??
        primaryColor.withValues(alpha: disabledAlpha);
    final disabledTextColor =
        themeData?.disabledTextColor ??
        primaryColor.withValues(alpha: disabledAlpha);
    final normalTextColor = widget.textColor ?? primaryColor;

    final isDisabled = widget.onTap == null;

    final currentBorderColor = isDisabled
        ? disabledBorderColor
        : normalBorderColor;
    final currentBgColor = _isTouch ? pressedBgColor : null;
    final currentTextColor = isDisabled
        ? disabledTextColor
        : (_isTouch ? pressedTextColor : normalTextColor);

    return Tile(
      onTap: widget.onTap,
      onTouch: isDisabled
          ? null
          : (isTouch) {
              setState(() {
                _isTouch = isTouch;
              });
            },
      child: Container(
        margin: widget.margin,
        padding: widget.padding,
        constraints: const BoxConstraints(
          minWidth: 136 * 0.8,
          minHeight: 48 * 0.8,
        ),
        decoration: BoxDecoration(
          color: currentBgColor,
          border: Border.all(
            color: currentBorderColor,
            width: widget.borderWidth,
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: uixFontSize(17),
            fontWeight: FontWeight.w600,
            color: currentTextColor,
            // UIX line boxes are 1 em; Material's 1.43 would inflate the box.
            height: uixLineHeight,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: UixOpticalText(
              fontSize: uixFontSize(17),
              child: widget.child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
